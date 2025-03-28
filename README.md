# Notification Test Project

This project showcases the seamless integration of Firebase Cloud Messaging (FCM) and MQTT to enable robust, real-time notification and messaging capabilities. The backend is developed using Django, while the frontend is built with Flutter, providing a cross-platform mobile application.

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
  - **django_emqx/**: Django app for handling notifications.
    - **migrations/**: Database migrations for the notifications app.
    - **models/**: Contains the data models for `EMQXDevice`, `Message`, and `UserNotification`. If Wagtail is installed, the models use Wagtail-specific features for enhanced functionality.
    - **serializer.py**: Serilizers for the `EMQXDevice` and `UserNotification` models.
    - **utils.py**: Utility functions for generating keys and sending notifications.
    - **views.py**: Django views for handling HTTP requests.
    - **mqtt.py**: Provides `MQTTClient` which connects the backend to the EMQX server.
    - **tests.py**: Contains unit tests for views and models.
  - **Dockerfile**: Dockerfile for building the Django backend image.
  - **manage.py**: Django management script.
  - **requirements.txt**: Python dependencies for the Django backend.
  - **settings.py**: Django settings file.
  - **urls.py**: URL routing for the Django backend.
- **emqx/**: Contains configuration files and certificates for EMQX.
  - **emxqx.conf**: Configuration file for the EMQX server.
  - **certs/**: Contains the certificates for TLS.
- **docker-compose.yml**: Docker Compose file for setting up the backend and MQTT broker.
- **README.md**: Project documentation and setup instructions.

## Setup Instructions

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

<!-- ## Secrets

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

Use the generated keys in your environment variables or configuration files as needed. -->

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

## License

This project is licensed under the [MIT License](./LICENSE).  
Feel free to use, modify, and distribute — just keep the original license and credit.
