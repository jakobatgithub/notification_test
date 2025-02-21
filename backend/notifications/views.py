import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from firebase_admin import messaging

import paho.mqtt.client as mqtt

# Store device tokens
DEVICE_TOKENS = set()

# MQTT Broker
MQTT_BROKER = "mqtt.eclipseprojects.io"
MQTT_TOPIC = "test/PROSUMIO_NOTIFICATIONS"

def send_mqtt_message(message_id, title, body):
    """Publish message via MQTT."""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, 1883, 60)
    
    payload = json.dumps({"message_id": message_id, "title": title, "body": body})
    client.publish(MQTT_TOPIC, payload)
    print(f"✅ MQTT notification sent: {payload}")
    client.disconnect()

def send_firebase_message(token, message_id, title, body):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
        data={
            "message_id": str(message_id),
        }
    )
    response = messaging.send(message)
    print(f"✅ Firebase notification sent: {response}")
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

@csrf_exempt
def send_notifications_view(request):
    if request.method == "POST":
        data = json.loads(request.body)
        title = data.get("title")
        body = data.get("body")

        if title and body:
            # Generate a unique message_id by counting requests
            if not hasattr(send_notifications_view, "message_counter"):
                send_notifications_view.message_counter = 0
            send_notifications_view.message_counter += 1
            message_id = send_notifications_view.message_counter

            send_mqtt_message(message_id=message_id, title=title, body=body)
            for token in DEVICE_TOKENS:
                print(f"title, body, token: {title}, {body}, {token}")
                send_firebase_message(token=token, message_id=message_id, title=title, body=body)
            
            return JsonResponse({"message": "Notifications sent successfully"})
    
    return JsonResponse({"error": "Invalid request"}, status=400)