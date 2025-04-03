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

### 🛠️ Configure EMQX and Django

Set the following URLs:
- `BASE_URL` in `./backend/backend/settings.py`
- `baseURL` in `./test_notification_app/lib/constants.dart`
- `mqttBroker` in `./test_notification_app/lib/constants.dart`
- add the file `./.env` with 
```text
EMQX_AUTHENTICATION__1__SECRET=<secret_key_1>
EMQX_WEBHOOK_SECRET=<secret_key_2>
```

### 🔥 Configure Firebase

#### Frontend
- Follow [Firebase Setup](https://firebase.google.com/docs/flutter/setup).
- Add `google-services.json` to `android/app`.
- Add `GoogleService-Info.plist` and iOS Auth key to `ios/Runner`.
- Generate `firebase_options.dart` via FlutterFire CLI and place it in `lib`.

#### Backend
- Place the Firebase Admin SDK JSON in the `backend` directory.
- Update the path in `settings.py`:
```python
cred = credentials.Certificate("backend/<your-firebase-adminsdk-json>.json")
```

### 🔐 TLS

For secure communication:

- Use [mkcert](https://github.com/FiloSottile/mkcert) to create your own local CA:
  - `mkcert -install`
  - Copy `rootCA.pem` to `./certs/`
  - Generate EMQX server certificates: `mkcert emqx-broker django-backend localhost 127.0.0.1 BASE_URL`
  - Copy the generated `.pem` files to `./certs/`
  - Adjust the certificate file names `emqx-broker+4.pem` and `emqx-broker+4-key.pem` in `./emqx/emqx.conf` and `./nginx/nginx.conf` if necessary
- For production, use certificates from a public CA like Let's Encrypt.
- Switching off TLS requires changes in `emqx.conf`. You can generate an `emqx.conf` from your settings (with e.g. `EMQX_TLS_ENABLED = False`) with the management command `python manage.py generate_emqx_config`.


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
test_notification_app/
├── lib/                  # Flutter app code
    ├── models/           # Defines Device and Message model
    ├── providers/        # Providers for lists of messages and devices
    ├── screens/          # Some UI elements
    ├── widgets/          # Some more UI elements
    └── services/         # Authentication and initialization of Firebase and MQTT Clients
├── android/              # Android-specific setup
├── ios/                  # iOS-specific setup
├── pubspec.yaml          # Flutter project config

backend/
├── backend/              # Django project settings and URLs
│   ├── settings.py
│   └── urls.py
├── django-emqx/          # EMQX Django app
├── notifications/        # Django app for notification management
├── Dockerfile
├── manage.py
└── requirements.txt

emqx/
└── emqx.conf             # EMQX config

docker-compose.yml        # Docker setup
README.md                 # Project documentation
```

## 🐞 Known issues

`SIMPLE_JWT` settings necessary for `django-emqx` interfere with other settings for `rest_framework_simplejwt` if you use this package for something else than `django-emqx`.


## 📌 Notes on EMQX Configuration

EMQX is a powerful, feature-rich MQTT broker with extensive configuration options including clustering, rate limiting, bridges, advanced authentication, and more.

This project **only demonstrates a small subset** of what EMQX can do. Please consult the [EMQX documentation](https://www.emqx.io/docs) for further customization and advanced usage.


## 📄 License

This project is licensed under the [MIT License](./LICENSE).  
Feel free to use, modify, and distribute — just keep the original license and credit.
