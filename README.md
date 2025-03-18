# Notification Test Project

This project showcases the seamless integration of Firebase Cloud Messaging (FCM) and MQTT to enable robust, real-time notification and messaging capabilities. The backend is developed using Django, while the frontend is built with Flutter, providing a cross-platform mobile application.

FCM is primarily used to deliver push notifications to the frontend when the application is inactive or running in the background. However, FCM has significant limitations when handling pure data messages or a combination of push notifications and data payloads, as its reliability varies across different device manufacturers and system configurations.

To overcome these limitations, MQTT is employed to ensure a reliable, bidirectional communication channel between the backend and the frontend. Unlike FCM, MQTT facilitates persistent connections and guarantees message delivery, making it ideal for sending arbitrary data in real-time. The MQTT implementation is powered by a self-hosted EMQX broker, allowing full control over message distribution, quality of service (QoS) levels, and connection management.

## Features

This project incorporates several security and efficiency measures to ensure seamless and secure communication between the backend and frontend.

- **JWT-based Authentication & Authorization:**
    JSON Web Tokens (JWT) are used for authentication and to enforce access control lists (ACLs) in MQTT. This ensures that each client has restricted access based on predefined permissions, preventing unauthorized subscriptions or publications.

- **Secure MQTT Communication with TLS:**
    To protect data transmission, the connection between the frontend and the EMQX broker is secured using Transport Layer Security (TLS). This encryption prevents eavesdropping and tampering, ensuring a confidential and secure communication channel.

- **Topic-based Access Control:**
    Each frontend user is restricted to a single dedicated MQTT topic for subscriptions, ensuring isolation between users. The backend, however, has the necessary permissions to publish messages to all topics, enabling efficient and controlled message distribution.

- **Automated Device Registration via Secure Webhooks:**
    A webhook secured with JWT authentication is used to register MQTT devices with the backend.

- **FCM Device Registration via `fcm-django`:**
    Firebase devices are registered securely using a dedicated `FCMDeviceViewSet` provided by the `fcm-django` package.

## Project Structure

- **test_notification_app**: Flutter application for receiving notifications.
- **backend**: Django backend for sending notifications.
- **docker-compose.yml**: Docker Compose file for setting up the backend and MQTT broker.
- **backend/Dockerfile**: Dockerfile for the Django backend.

## Setup Instructions

### Prerequisites

- Flutter SDK
- Firebase account
- Docker and Docker Compose
- MQTT Broker (e.g., EMQX)

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
    - Place the `google-services.json` file in `android/app` and `GoogleService-Info.plist` in `ios/Runner`.

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
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
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

5. **Run the Django server**:
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

## Secrets

The following secrets are required for the project:

- **Firebase Admin SDK JSON file**: Required for the Django backend to authenticate with Firebase.
- **google-services.json**: Required for the Android part of the Flutter application to configure Firebase.
- **GoogleService-Info.plist**: Required for the iOS part of the Flutter application to configure Firebase.
- **EMQX_WEBHOOK_SECRET_TOKEN**: Generate it within the Python shell `python manage.py shell`
    ``` 
    from notifications.utils import generate_static_jwt
    print(generate_static_jwt())
    ```
    and use this string as `token` in the environment variable `EMQX_WEBHOOK_SECRET_TOKEN="Bearer token"`

### Generating Keys

You can generate the necessary keys using the utility functions provided in the `backend/notifications/utils.py` file.

1. **Generate Django SECRET_KEY**:
    ```sh
    python manage.py shell
    from notifications.utils import generate_django_secret_key
    print(generate_django_secret_key())
    ```

2. **Generate JWT Signing Key**:
    ```sh
    python manage.py shell
    from notifications.utils import generate_signing_key
    print(generate_signing_key())
    ```

3. **Generate Static JWT for EMQX**:
    ```sh
    python manage.py shell
    from notifications.utils import generate_static_jwt
    print(generate_static_jwt())
    ```

Use the generated keys in your environment variables or configuration files as needed.

## Usage

### Sending Notifications

- Use the Flutter app to send a POST request to the backend to trigger notifications.
- The backend will send notifications via FCM and MQTT.

### Receiving Notifications

- The Flutter app will receive notifications and display the latest message along with recent messages.

## Troubleshooting

### Common Issues

- **Firebase Authentication Errors**: Ensure that the Firebase Admin SDK JSON file is correctly placed and the path is correctly set in `settings.py`.
- **Docker Build Failures**: Verify that Docker and Docker Compose are correctly installed and that the Dockerfile and docker-compose.yml are correctly configured.
- **MQTT Connection Issues**: Ensure that the MQTT broker is running and accessible.

### Logs and Debugging

- **Flutter Application Logs**: Use `flutter logs` to view logs from the Flutter application.
- **Django Backend Logs**: Check the console output where the Django server is running for any errors or logs.
- **Docker Logs**: Use `docker-compose logs` to view logs from the Docker containers.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License.