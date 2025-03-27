## django_emqx/utils.py

import json
import secrets

from rest_framework_simplejwt.tokens import AccessToken

try:
    from firebase_admin import messaging
    from firebase_admin.messaging import Notification, Message as FCMMessage
    firebase_installed = True
except ImportError:
    firebase_installed = False


def generate_backend_mqtt_token():
    """
    Generate a JWT token for the communication between Django backend 
    and EMQX server.

    The token includes a username "backend" and ACL rules allowing
    both subscription and publication to all topics.

    Returns:
        str: The generated JWT token as a string.
    """
    token = AccessToken()
    token["username"] = "backend"
    token["acl"] = [
        {
            "permission": "allow",
            "action": "subscribe",
            "topic": "#"
        },
        {
            "permission": "allow",
            "action": "publish",
            "topic": "#"
        }
    ]
    return str(token)

def generate_mqtt_token(user):
    """
    Generate a JWT token for a specific user for MQTT communication.

    The token includes the user's ID as the username and ACL rules
    allowing subscription to topics under "user/{user.id}/#" and
    denying publication to all topics.

    Args:
        user (User): The user object for whom the token is generated.

    Returns:
        str: The generated JWT token as a string.
    """
    # Create a new JWT token
    token = AccessToken.for_user(user)

    # Set MQTT-specific claims
    token["username"] = str(user.id)  # EMQX uses this for client identification
    token["acl"] = [
        {
            "permission": "allow",
            "action": "subscribe",
            "topic": f"user/{user.id}/#"
        },
        {
            "permission": "deny",
            "action": "publish",
            "topic": "#"
        }
    ]
    return str(token)

def send_mqtt_message(mqtt_client, recipient, msg_id, title, body):
    """
    Publish a message via MQTT to a specific user's topic.

    Args:
        mqtt_client: The MQTT client instance used for publishing.
        recipient (User): The recipient user object.
        msg_id (str): The unique message ID.
        title (str): The title of the message.
        body (str): The body content of the message.
    """
    """Publish message via MQTT."""
    payload = json.dumps({"msg_id": msg_id, "title": title, "body": body})
    user_topic = f"user/{recipient.id}/"
    mqtt_client.publish(user_topic, payload)
    
    print(f"✅ MQTT notification sent: {payload}")

def send_firebase_notification(token, title, body):
    """
    Send a notification message via Firebase Cloud Messaging (FCM).

    Args:
        token (str): The recipient's FCM device token.
        title (str): The title of the notification.
        body (str): The body content of the notification.

    Returns:
        str: The response from the Firebase messaging service.

    Raises:
        ImportError: If the Firebase Admin SDK is not installed.
    """
    if not firebase_installed:
        raise ImportError("firebase_admin is not installed. Install it to use Firebase messaging.")

    message = FCMMessage(
        token=token,
        notification=Notification(
            title=title,
            body=body,
        )
    )
    response = messaging.send(message)
    print(f"✅ Firebase notification sent: {response}")
    return response

def send_firebase_data_message(token, msg_id, title, body):
    """
    Send a data message via Firebase Cloud Messaging (FCM).

    Args:
        token (str): The recipient's FCM device token.
        msg_id (str): The unique message ID.
        title (str): The title of the message.
        body (str): The body content of the message.

    Returns:
        str: The response from the Firebase messaging service.

    Raises:
        ImportError: If the Firebase Admin SDK is not installed.
    """
    if not firebase_installed:
        raise ImportError("firebase_admin is not installed. Install it to use Firebase messaging.")

    message = FCMMessage(
        token=token,
        data={
            "msg_id": str(msg_id),
            "title": title,
            "body": body,
        },
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            headers={"apns-priority": "10"},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True)
            ),
        ),        
    )
    response = messaging.send(message)
    print(f"✅ Firebase data message sent: {response}")
    return response

def generate_django_secret_key():
    """
    Generate a secure Django SECRET_KEY.

    The key is a 50-character random string consisting of letters,
    digits, and special characters.

    Returns:
        str: The generated SECRET_KEY.
    """
    return "".join(secrets.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)") for _ in range(50))

def generate_signing_key():
    """
    Generate a secure random key for JWT signing and EMQX cookie.

    The key is a 256-bit hex string.

    Returns:
        str: The generated signing key.
    """
    return secrets.token_hex(32)  # 32-byte (256-bit) hex key
