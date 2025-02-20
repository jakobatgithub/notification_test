import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from firebase_admin import messaging

import paho.mqtt.client as mqtt

# Store device tokens
DEVICE_TOKENS = set()

MQTT_BROKER_URL = "mqtt://broker.emqx.io"  # Change if using a self-hosted broker
MQTT_TOPIC = "test/notifications"

client = mqtt.Client()
client.connect("broker.emqx.io", 1883, 60)

def publish_mqtt_message(message):
    client.publish(MQTT_TOPIC, message)
    
def send_notification_view(request):
    token = request.GET.get("token")  # Get the Firebase token from request
    title = "Test Notification"
    body = "This is a test message."

    if token:
        response = send_firebase_notification(token, title, body)
        return JsonResponse({"status": "success", "message_id": response})
    
    return JsonResponse({"status": "error", "message": "Token not provided"}, status=400)


def send_firebase_notification(token, title, body):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
    )
    response = messaging.send(message)
    return response


@csrf_exempt
def register_token_view(request):
    if request.method == "POST":
        data = json.loads(request.body)
        token = data.get("token")

        if token:
            DEVICE_TOKENS.add(token)  # Store token in a database instead of a set in production
            print(f"DEVICE_TOKENS: {DEVICE_TOKENS}")
            return JsonResponse({"message": "Token registered successfully", "token": token})
    
    return JsonResponse({"error": "Invalid request"}, status=400)
