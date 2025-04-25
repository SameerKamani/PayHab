# PayHab

A cross-platform Flutter application with a Flask backend for managing student loans and payments. PayHab helps students track and manage loans with different vendors.

<p align="center">
  <img src="assests/payhab_logo.jpeg" alt="PayHab Logo" width="350">
</p>

## 📱 Features

- 🔐 **User Authentication**: Secure login, registration and password recovery
- 📊 **Dashboard**: View your recent transactions and loan status
- 💰 **Loan Management**: Add and clear loans with different vendors
- 📱 **Cross-Platform**: Works on Android, iOS, and Web platforms
- 🔔 **Notifications**: Timely reminders about pending loans

## 🛠️ Tech Stack

### Frontend (Flutter)
- Flutter SDK
- Firebase Authentication
- Cloud Firestore
- Flutter Local Notifications

### Backend (Flask)
- Flask
- Firebase Admin SDK
- Flask-Limiter for rate limiting
- Firebase Authentication
- Cloud Firestore

## 📦 Dependencies

### Flutter App Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.14.0
  firebase_auth: ^4.6.3
  cloud_firestore: ^4.8.1
  flutter_local_notifications: ^14.1.1
  http: ^1.1.0
  shared_preferences: ^2.2.0
  intl: ^0.18.1
  provider: ^6.0.5
```

### Backend Dependencies
```
flask==2.0.1
firebase-admin==6.1.0
requests==2.28.1
flask-limiter==3.3.1
```

## 🚀 Setup and Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Python](https://www.python.org/downloads/) 3.8 or higher
- [Firebase](https://firebase.google.com/) account

### Flutter App Setup

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/payhab.git
   cd payhab
   ```

2. Install Flutter dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

### Backend Setup

1. Navigate to the backend directory
   ```bash
   cd payhab/lib
   ```

2. Create a virtual environment (recommended)
   ```bash
   python -m venv venv
   # On Windows
   venv\Scripts\activate
   # On macOS/Linux
   source venv/bin/activate
   ```

3. Install Python dependencies
   ```bash
   pip install -r requirements.txt
   ```

4. Place your Firebase service account key in the lib directory
   - Rename it to `payhab-firebase-adminsdk-fbsvc-b843c3734b.json` or update the path in app.py

5. Run the Flask server
   ```bash
   python app.py
   ```
   The server will start on http://localhost:5000

## 🔄 API Endpoints

### Authentication
- `POST /register`: Register a new user
- `POST /login`: Log in an existing user
- `POST /forgot-password`: Send password reset email
- `POST /verify-token`: Verify authentication token
- `POST /send-verification`: Send email verification

### User Data
- `GET /user/<user_id>`: Get user information

### Transactions
- `GET /transactions/recent/<user_id>`: Get recent transactions

### Loans
- `POST /loans/add`: Add a new loan
- `POST /loans/clear`: Clear an existing loan
- `GET /loans/get`: Get loan information for a specific vendor

## 🛡️ Security Features

- Rate limiting to prevent brute force attacks
- Account lockout after multiple failed login attempts
- Secure token verification
- Firebase Authentication integration

## 📷 Screenshots

| Login Screen | Dashboard | Vendor Detail |
|:------------:|:---------:|:-------------:|
| ![Login](https://via.placeholder.com/250x500?text=Login) | ![Dashboard](https://via.placeholder.com/250x500?text=Dashboard) | ![Vendor](https://via.placeholder.com/250x500?text=Vendor+Detail) |

## 📋 Project Structure

```
payhab/
│
├── lib/                    # Core project files
│   ├── app.py              # Flask backend server
│   ├── main.dart           # Flutter app entry point
│   ├── login_screen.dart   # Authentication UI
│   ├── signup_screen.dart  # Registration UI
│   ├── forgot_password_screen.dart # Password recovery
│   ├── main_dashboard_screen.dart  # Main dashboard
│   ├── vendor_detail_screen.dart   # Vendor detail page
│   ├── transaction_history_screen.dart # Transaction history
│   └── firebase_options.dart # Firebase configuration
│
├── assets/                 # App assets (images, fonts, etc.)
│
└── test/                   # Test files
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

For any inquiries, please reach out to [sameerkamani03@gmail.com](mailto:sameerkamani03@gmail.com)

---

Made with ❤️ by Dream Team
