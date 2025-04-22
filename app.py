import os
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, auth, firestore
import requests
#from google.cloud import firestore
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import time

# For production, do not use emulator settings (commented out)
# os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"

# Initialize Firebase Admin SDK with your service account key.
cred = credentials.Certificate("Enter Your Own key here")
firebase_admin.initialize_app(cred)

db = firestore.client()
app = Flask(__name__)

# Initialize Flask-Limiter: do not pass app to the constructor.
limiter = Limiter(key_func=get_remote_address)
limiter.init_app(app)

# Simple in-memory store for failed login attempts: {email: (attempt_count, lockout_until)}
failed_attempts = {}
LOCKOUT_THRESHOLD = 5  # number of allowed failed attempts
LOCKOUT_DURATION = 300  # lockout duration in seconds (e.g., 5 minutes)

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    name = data.get('name')
    student_id = data.get('studentId')
    email = data.get('email')
    password = data.get('password')
    if not all([name, student_id, email, password]):
        return jsonify({"error": "Missing fields in request"}), 400
    try:
        # Create user in Firebase Authentication.
        user_record = auth.create_user(
            email=email,
            password=password,
            display_name=name
        )
        # Save additional data in Firestore under the 'users' collection.
        db.collection('users').document(user_record.uid).set({
            'name': name,
            'studentId': student_id,
            'email': email,
            "forceLogout": False
        })
        return jsonify({"message": "User created successfully."}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# Apply rate limiting: e.g., max 5 login attempts per minute per IP.
@app.route('/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    # Check if the account is locked due to too many failed attempts.
    current_time = time.time()
    if email in failed_attempts:
        count, lockout_until = failed_attempts[email]
        if lockout_until and current_time < lockout_until:
            return jsonify({"error": "Account locked due to multiple failed attempts. Please try again later."}), 429

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    API_KEY = "AIzaSyBkaz899vAxD50axFQQpDDOP5eoL4CoBTQ"
    sign_in_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    r = requests.post(sign_in_url, json=payload)
    if r.status_code == 200:
        # Reset failed attempts on successful login.
        if email in failed_attempts:
            del failed_attempts[email]
        result = r.json()
        user_id = result.get("localId")
        return jsonify({
            "message": "Login successful",
            "idToken": result.get("idToken"),
            "refreshToken": result.get("refreshToken"),
            "userId": user_id
        }), 200
    else:
        # Increment failed attempts.
        count, lockout_until = failed_attempts.get(email, (0, None))
        count += 1
        if count >= LOCKOUT_THRESHOLD:
            lockout_until = time.time() + LOCKOUT_DURATION
        failed_attempts[email] = (count, lockout_until)
        error_message = r.json().get("error", {}).get("message", "Login failed")
        return jsonify({"error": error_message}), 400

@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.json
    email = data.get('email')
    if not email:
        return jsonify({"error": "Email is required"}), 400
    API_KEY = "AIzaSyBkaz899vAxD50axFQQpDDOP5eoL4CoBTQ"
    reset_url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={API_KEY}"
    payload = {
        "requestType": "PASSWORD_RESET",
        "email": email
    }
    r = requests.post(reset_url, json=payload)
    if r.status_code == 200:
        try:
            user_record = auth.get_user_by_email(email)
            db.collection('users').document(user_record.uid).update({
                "forceLogout": True
            })
        except Exception as e:
            print("Error updating user document for forceLogout:", e)
        return jsonify({"message": "Password reset email sent successfully"}), 200
    else:
        error_message = r.json().get("error", {}).get("message", "Password reset failed")
        return jsonify({"error": error_message}), 400

@app.route('/verify-token', methods=['POST'])
def verify_token():
    data = request.json
    id_token = data.get("idToken")
    if not id_token:
        return jsonify({"error": "ID token is required"}), 400
    try:
        auth.verify_id_token(id_token)
        return jsonify({"message": "Token is valid"}), 200
    except Exception as e:
        return jsonify({"error": "Token invalid"}), 401

@app.route('/user/<user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            return jsonify({"data": user_doc.to_dict()}), 200
        else:
            return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 400


#-------------------------------|
# Dashboard recent transactions |
#-------------------------------|
@app.route('/transactions/recent/<user_id>', methods=['GET'])
def get_recent_transactions(user_id):
    try:
        print(f"Attempting to fetch transactions for user ID: {user_id}")  # Debug log
        
        # First verify if user exists
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists:
            print(f"User not found in database: {user_id}")  # Debug log
            return jsonify({"error": "User not found"}), 404

        # Get transactions with proper ordering and limiting
        transactions_ref = db.collection('users').document(user_id).collection('transactions')
        transactions = transactions_ref.order_by('timestamp', direction=firestore.Query.DESCENDING).limit(10).stream()

        transaction_list = []
        for txn in transactions:
            txn_data = txn.to_dict()
            txn_data["id"] = txn.id
            # Convert Firestore timestamp to ISO format if it exists
            if 'timestamp' in txn_data:
                txn_data['timestamp'] = txn_data['timestamp'].isoformat()
            transaction_list.append(txn_data)

        print(f"Found {len(transaction_list)} transactions for user {user_id}")  # Debug log
        return jsonify({"transactions": transaction_list}), 200

    except Exception as e:
        print(f"Error fetching transactions: {str(e)}")
        return jsonify({"error": str(e)}), 400


# ----------------------------
# Vendor Loan Endpoints
# ----------------------------
#from google.cloud import firestore

@app.route('/loans/add', methods=['POST'])
def add_loan():
    data = request.json
    user_id = data.get("userId")
    vendor = data.get("vendor")
    amount = data.get("amount")

    if not all([user_id, vendor, amount is not None]):
        return jsonify({"error": "Missing fields in request"}), 400

    try:
        doc_ref = db.collection('users').document(user_id).collection('loans').document(vendor)
        doc = doc_ref.get()

        if doc.exists:
            current_amount = doc.to_dict().get("amount", 0)
            new_amount = current_amount + amount
        else:
            new_amount = amount

        # Save updated loan
        doc_ref.set({"amount": new_amount}, merge=True)

        # ✅ Log transaction
        db.collection('users').document(user_id).collection('transactions').add({
            "type": "loan_add",
            "vendor": vendor,
            "amount": amount,
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        return jsonify({"message": "Loan added successfully", "newAmount": new_amount}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/loans/clear', methods=['POST'])
def clear_loan():
    data = request.json
    user_id = data.get("userId")
    vendor = data.get("vendor")
    amount = data.get("amount")

    if not all([user_id, vendor, amount is not None]):
        return jsonify({"error": "Missing fields in request"}), 400

    try:
        doc_ref = db.collection('users').document(user_id).collection('loans').document(vendor)
        doc = doc_ref.get()

        if doc.exists:
            current_amount = doc.to_dict().get("amount", 0)
            new_amount = current_amount - amount
            if new_amount < 0:
                new_amount = 0
        else:
            new_amount = 0

        # Update loan amount
        doc_ref.set({"amount": new_amount}, merge=True)

        # ✅ Log transaction
        db.collection('users').document(user_id).collection('transactions').add({
            "type": "loan_clear",
            "vendor": vendor,
            "amount": amount,
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        return jsonify({"message": "Loan cleared successfully", "newAmount": new_amount}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400
    
@app.route('/loans/get', methods=['GET'])
def get_loan():
    user_id = request.args.get("userId")
    vendor = request.args.get("vendor")
    if not user_id or not vendor:
        return jsonify({"error": "Missing userId or vendor"}), 400
    try:
        doc_ref = db.collection('users').document(user_id).collection('loans').document(vendor)
        doc = doc_ref.get()
        if doc.exists:
            return jsonify({"amount": doc.to_dict().get("amount", 0)}), 200
        else:
            return jsonify({"amount": 0}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/send-verification', methods=['POST'])
def send_verification():
    data = request.json
    id_token = data.get('idToken')
    if not id_token:
        return jsonify({"error": "ID token is required"}), 400

    API_KEY = "Enter Your Own key here"
    verify_url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={API_KEY}"
    payload = {
        "requestType": "VERIFY_EMAIL",
        "idToken": id_token
    }
    r = requests.post(verify_url, json=payload)
    if r.status_code == 200:
        return jsonify({"message": "Verification email sent successfully"}), 200
    else:
        error_message = r.json().get("error", {}).get("message", "Verification email sending failed")
        return jsonify({"error": error_message}), 400

if __name__ == '__main__':
    app.run(debug=True)
