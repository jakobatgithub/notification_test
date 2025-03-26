import json
import secrets

from django.contrib.auth import get_user_model

from rest_framework_simplejwt.tokens import AccessToken

from firebase_admin import messaging
from firebase_admin.messaging import Message, Notification


def generate_backend_mqtt_token():
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

def send_mqtt_message(mqtt_client, msg_id, title, body):
    """Publish message via MQTT."""
    payload = json.dumps({"msg_id": msg_id, "title": title, "body": body})
    users = get_user_model().objects.all()
    for user in users:
        user_topic = f"user/{user.id}/"
        mqtt_client.publish(user_topic, payload)
    
    print(f"✅ MQTT notification sent: {payload}")

def send_firebase_notification(token, title, body):
    message = Message(
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
    message = Message(
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
    """Generate a secure Django SECRET_KEY (50-character random string)."""
    return "".join(secrets.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)") for _ in range(50))

def generate_signing_key():
    """Generate a secure random key for JWT signing and random EMQX cookie (256-bit hex string)."""
    return secrets.token_hex(32)  # 32-byte (256-bit) hex key
