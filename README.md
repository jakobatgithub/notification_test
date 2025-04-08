# Notification Test Project

This project showcases the integration of the [`django-emqx`](https://github.com/jakobatgithub/django-emqx) app to enable real-time messaging using Firebase Cloud Messaging (FCM) and MQTT. The backend is built with Django and the cross-platform frontend with Flutter.

FCM handles push notifications when the app is inactive or in the background but has reliability issues with data messages across devices. To address this, MQTT provides a persistent, bidirectional communication channel for reliable, real-time data delivery. A self-hosted EMQX broker powers MQTT, offering full control over message delivery, QoS, and connections.

We distinguish between **notifications** and **data messages**:
- **Notifications** consist of a title and a body but no data payload. They are used to inform the user.
- **Data messages** consist of a data payload in the form of a JSON dictionary, with no title and body. They are used to trigger changes in the frontend and are not shown to the user.


## 🚀 Usage

### 🔔 Sending Notifications

Use the Flutter app to send a POST request to the backend to trigger notifications. The Django backend sends notifications via FCM and MQTT to each registered device.

- **FCM messages** are displayed if the app is in the background or closed.
- **MQTT messages** are received when the app is open.
- All retained MQTT messages are delivered upon app launch — ensuring none are lost.
- FCM messages are not delivered when the app is open.

### 👥 Display Connected Users

Below the received messages, a list of users is shown with a `connected` flag.

- When a device connects to the EMQX broker, EMQX calls a Django webhook.
- This triggers a signal that sends a data message to all connected devices.
- Each device then updates the corresponding user's connection status.


## ⚙️ Setup Instructions

### 📋 Prerequisites

Before getting started, ensure the following tools are installed and configured:

- **Docker** – For running the backend services  
- **Android Studio** – With the Android Virtual Device (AVD) Manager enabled  
- **Emulators**:
  - **Linux/Windows**: 3 running Android emulators
  - **macOS**:
    - **Xcode** – Required for iOS support
    - 2 running Android emulators
    - 1 running iOS simulator

### 🔧 Running the Project (No Firebase, No TLS)

You can try the project out of the box without Firebase or TLS enabled:

1. **Clone the repository**:
   ```bash
   git clone git@github.com:jakobatgithub/notification_test.git
   cd notification_test
   ```

2. **Start the backend in Docker**:
   ```bash
   docker compose up --build
   ```

3. **Install and launch the frontend apps without Firebase**:  
   Use the helper script to install and start the app on your emulators:
   ```bash
   cd /frontend/no_firebase_app 
   ./start_app_on_devices.sh <android_count> <ios_count>
   ```
   Replace `<android_count>` and `<ios_count>` with the number of Android and iOS emulators you have running.

   Alternatively, you can use the provided **VS Code launch configurations**.

4. **Uninstall the app from all emulators**:  
   To clean up, run:
   ```bash
   ./frontend/uninstall_from_devices.sh
   ```

> 💡 Tip: Make sure all specified emulators are already running before executing the scripts.

### 🔥 Configure Firebase

To enable Firebase integration across the backend and frontend, ensure all required configuration files are correctly placed and referenced. Firebase provides services like Authentication, Cloud Messaging, Firestore, and more—so setting it up properly is crucial.

#### Backend

- Uncomment the relevant Firebase-related sections in:
  - `./backend/backend/settings.py`
  - `./backend/requirements.txt`
- Download the Firebase Admin SDK JSON credentials from your Firebase Console (`Project Settings > Service Accounts > Generate new private key`) and place it in the `./backend/backend/` directory.
- Update the credentials path in `settings.py`:
  ```python
  cred = credentials.Certificate("backend/<your-firebase-adminsdk-json>.json")
  ```
- This enables server-side communication with Firebase services like Authentication, Firestore, and Cloud Messaging (FCM).

#### Frontend

- Follow the [official Firebase Flutter setup guide](https://firebase.google.com/docs/flutter/setup) to connect your app to Firebase.
- Add the Android config file `google-services.json` to:
  - `./frontend/firebase_app/android/app`
- Add the iOS config file `GoogleService-Info.plist` to:
  - `./frontend/firebase_app/ios/Runner`
- Add your iOS Auth Key (used for Apple Sign-In and push notifications) to:
  - `./frontend/firebase_app/ios`
- Use the FlutterFire CLI to configure your app:
  ```bash
  flutterfire configure
  ```
  This will generate a `firebase_options.dart` file. Place it in:
  - `./frontend/firebase_app/lib`
- To run the app, use the launch script:
  ```bash
  cd ./frontend/firebase_app
  ./start_app_on_devices.sh <android_count> <ios_count>
  ```
  Alternatively, launch via VS Code using the predefined configurations.

> ✅ Tip: Double-check that all required Firebase services (e.g., Authentication, Firestore, FCM) are enabled in the Firebase console and that you've added all relevant Firebase SDKs to your project dependencies.


# ⚙️ Configure EMQX and Django

To enable real device support (instead of emulators), update the following URLs:

- `BASE_URL` in `./backend/backend/settings.py`
- `baseURL` in `./test_notification_app/lib/constants.dart`
- `mqttBroker` in `./test_notification_app/lib/constants.dart`

## 🔑 Using Custom Secrets

To override default secrets, create a `.env` file in the project root with the following content:

```env
EMQX_AUTHENTICATION__1__SECRET=<secret_key_1>
EMQX_WEBHOOK_SECRET=<secret_key_2>
EMQX_NODE_COOKIE=<secret_key_3>
```

## 📊 EMQX Dashboard

- URL: `http://localhost:18083/`
- Default username: `admin`
- Default password: `public`

---

## 📝 Generate EMQX Config

To generate an `emqx.conf` file based on your Django settings (e.g., `EMQX_TLS_ENABLED = True`), run:

```bash
python manage.py generate_emqx_config
```

---

## 🔐 TLS Setup

To secure communication between the EMQX broker and clients:

### 1. Create a Local Certificate Authority (CA)

Use [`mkcert`](https://github.com/FiloSottile/mkcert):

```bash
mkcert -install
```

- Copy the generated `rootCA.pem` from `mkcert -CAROOT` to `./certs/`

### 2. Generate EMQX Server Certificates

```bash
mkcert emqx-broker django-backend localhost 127.0.0.1 10.0.2.2 BASE_URL
```

- Copy the generated `.pem` files to `./certs/`
- Update filenames (e.g., `emqx-broker+4.pem` and `emqx-broker+4-key.pem`) in:
  - `./emqx/emqx.conf`
  - `./nginx/nginx.conf`

### 3. Enable TLS in Configuration

- Uncomment relevant TLS sections in:
  - `./backend/backend/settings.py`
  - `./frontend/shared/constants.dart`
- In `./emqx/emqx.conf`, set:
  ```conf
  listeners.ssl.default.enable = true
  ```
- Uncomment the HTTPS-related blocks in `./nginx/nginx.conf`

### 🔒 Production Tip

For production deployments, use certificates from a trusted CA such as Let's Encrypt.

## ✨ Features

This project includes robust security and efficiency measures:

- **🔒 Topic-based Access Control**: Each frontend user is isolated to their own MQTT topic.
- **🔑 JWT Authentication & Authorization**: Managed using `rest_framework_simplejwt` and enforced via EMQX ACLs.
- **🔐 TLS Encryption**: Both MQTT and backend communications are secured using TLS.
- **📩 Secure Webhooks**: JWT-secured webhooks handle device registration.
- **📲 Firebase Cloud Messaging Integration**: Fallback to FCM if installed.
- **🧩 Flutter Providers**: Centralized `Device` and `Message` lists are managed using providers, enabling updates in one part of the app to be automatically propagated throughout the UI.


## 🗂️ Project Structure

```text
backend/
├── backend/              # Django project settings and URLs
│   ├── settings.py       # settings for Django backend
│   └── urls.py           
├── django-emqx/          # EMQX Django app
├── notifications/        # Django app for notification management
├── Dockerfile
├── manage.py
├── requirements.txt
certs/                      # folder for certificates
emqx/
├── emqx.conf               # EMQX config
nginx/
├── nginx.conf              # nginx config
frontend/
├── no_firebase_app         # Flutter frontend without Firebase support
│   ├── lib/                # Flutter app code
│   │   └── main.dart       # The Flutter app starts here
│   ├── android/            # Android-specific setup
│   ├── ios/                # iOS-specific setup
│   └── pubspec.yaml        # Flutter project config
├── firebase_app            # Flutter frontend with Firebase support
├── shared
│   ├── lib/                # Flutter app code
│   │   ├── models/         # Defines Device and Message model
│   │   ├── providers/      # Providers for lists of messages and devices
│   │   ├── screens/        # Some UI elements
│   │   ├── widgets/        # Some more UI elements
│   │   ├── services/       # Authentication and initialization of Firebase and MQTT Clients
│   │   └── constants.dart  # Defines EMQX broker URL, enableTLS, etc.
docker-compose.yml          # Docker setup
README.md                   # Project documentation
```

## 🐞 Known issues

`SIMPLE_JWT` settings necessary for `django-emqx` interfere with other settings for `rest_framework_simplejwt` if you use this package for something else than `django-emqx`.

## 📌 Notes on EMQX Configuration

EMQX is a powerful, feature-rich MQTT broker with extensive configuration options including clustering, rate limiting, bridges, advanced authentication, and more.

This project **only demonstrates a small subset** of what EMQX can do. Please consult the [EMQX documentation](https://www.emqx.io/docs) for further customization and advanced usage.


## 📄 License

This project is licensed under the [MIT License](./LICENSE).  
Feel free to use, modify, and distribute — just keep the original license and credit.
