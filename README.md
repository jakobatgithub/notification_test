# Notification Test Project

This project demonstrates the integration of the [django-emqx](https://github.com/jakobatgithub/django-emqx) app for Firebase Cloud Messaging (FCM) and MQTT to enable robust, real-time notification and messaging capabilities. The backend is developed using Django, while the frontend is built with Flutter, providing a cross-platform mobile application.

FCM is primarily used to deliver push notifications to the frontend when the application is inactive or running in the background. However, FCM has significant limitations when handling pure data messages or a combination of push notifications and data payloads, as its reliability varies across different device manufacturers and system configurations.

To overcome these limitations, MQTT is employed to ensure a reliable, bidirectional communication channel between the backend and the frontend. Unlike FCM, MQTT facilitates persistent connections and guarantees message delivery, making it ideal for sending arbitrary data in real-time. The MQTT implementation is powered by a self-hosted EMQX broker, allowing full control over message distribution, quality of service (QoS) levels, and connection management.

## Features

This project incorporates several security and efficiency measures to ensure seamless and secure communication between the backend and frontend.

- **Topic-based Access Control:**
    Each frontend user is restricted to a single dedicated MQTT topic for subscriptions, ensuring isolation between users. The backend, however, has the necessary permissions to publish messages to all topics, enabling efficient and controlled message distribution.

- **JWT-based Authentication & Authorization:**
    JSON Web Tokens (JWT) are used for authenticating MQTT clients at EMQX and to enforce access and control lists (ACLs). This ensures that each client has restricted access based on predefined permissions, preventing unauthorized subscriptions or publications. For JWT we use `rest_framework_simplejwt`.

- **Secure MQTT Communication with TLS:**
    To protect data transmission, the connection between the frontend and the EMQX broker is secured using Transport Layer Security (TLS). This encryption prevents eavesdropping and tampering, ensuring a confidential and secure communication channel.

- **Automated Device Registration via Secure Webhooks:**
    A webhook secured with JWT authentication is used to register MQTT devices with the backend.

- **Integration with Firebase Cloud Messaging (FCM):**
    Notifications are sent via Firebase if it is installed.

## Project Structure

- **test_notification_app/**: Contains the Flutter application code.
  - **lib/**: Main Dart code for the Flutter application.
  - **android/**: Android-specific configuration and code.
  - **ios/**: iOS-specific configuration and code.
  - **pubspec.yaml**: Flutter project configuration file.
- **backend/**: Contains the Django backend code.
  - **backend/**: Base project package.
    - **settings.py**: Django settings file.
    - **urls.py**: URL routing for the Django backend.
  - **django-emqx/**: Django app for authentication and authorization with the EMQX broker, see [django-emqx](https://github.com/jakobatgithub/django-emqx).
  - **notifications/**: Django app for handling notifications.
  - **Dockerfile**: Dockerfile for building the Django backend image.
  - **manage.py**: Django management script.
  - **requirements.txt**: Python dependencies for the Django backend.
- **emqx/**: Contains configuration files and certificates for EMQX.
  - **emxqx.conf**: Configuration file for the EMQX server.
  - **certs/**: Contains the certificates for TLS.
- **docker-compose.yml**: Docker Compose file for setting up the backend and MQTT broker.
- **README.md**: Project documentation and setup instructions.

## Setup Instructions

## TLS
For transport layer security you need provide certificates. For development it's useful to create your own Certificate Authority (CA) with [mkcert](https://github.com/FiloSottile/mkcert). Create a new local CA with `mkcert -install` and copy the public root CA certificate `rootCA.pem` (which is created in `mkcert -CAROOT`) to `backend/certs/` and `test_notification_app/assets/certs/`. Create the public/private EMQX server certificates with `mkcert emqx_host_name` and `emqx_host_name` the URL of the EMQX broker and copy both the certificate and key `.pem` files to `emqx/certs/`. For production it might be necessary to use certificates from a public CA as e.g. Let's encrypt.

### Prerequisites

- Flutter SDK
- Firebase account
- Docker and Docker Compose

### Flutter Application

1. **Clone the repository**:
    ```sh
    git clone <repository-url>
    cd notification_test/test_notification_app
    ```

2. **Install dependencies**:
    ```sh
    flutter pub get
    ```

3. **Configure Firebase**:
    - Follow the instructions to add Firebase to your Flutter app: [Firebase Setup](https://firebase.google.com/docs/flutter/setup)
    - Place the `google-services.json` file in `android/app` and `GoogleService-Info.plist` in `ios/Runner` the iOS Auth key in `ios`.

4. **Run the application**:
    ```sh
    flutter run
    ```

### Django Backend

1. **Navigate to the backend directory**:
    ```sh
    cd ../backend
    ```

2. **Create a virtual environment and activate it**:
    ```sh
    python -m venv venv
    source venv/bin/activate
    ```

3. **Install dependencies**:
    ```sh
    pip install -r requirements.txt
    ```

4. **Configure Firebase Admin SDK**:
    - Place the Firebase Admin SDK JSON file in the `backend` directory.
    - Update the path in `settings.py`:
      ```python
      cred = credentials.Certificate("backend/<your-firebase-adminsdk-json>.json")
      ```

5. **Apply database migrations**:
    ```sh
    python manage.py migrate
    ```

6. **Run the Django server**:
    ```sh
    python manage.py runserver
    ```

### Docker Setup

1. **Navigate to the project root directory**:
    ```sh
    cd /Users/jakob/notification_test
    ```

2. **Build and start the Docker containers**:
    ```sh
    docker-compose up --build
    ```

3. **Access the Django backend**:
    - The Django backend will be available at `http://localhost:8000`.

4. **Access the EMQX Dashboard**:
    - The EMQX Dashboard will be available at `http://localhost:18083`.

## Usage

### Sending Notifications

- Use the Flutter app to send a POST request to the backend to trigger notifications.
- The backend will send notifications via FCM and MQTT.

### Receiving Notifications

- The Flutter app will receive notifications and display the latest message along with recent messages.

## License

This project is licensed under the [MIT License](./LICENSE).  
Feel free to use, modify, and distribute — just keep the original license and credit.
