import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from firebase_admin import messaging

import paho.mqtt.client as mqtt

# Store device tokens
DEVICE_TOKENS = set()

# MQTT Broker
MQTT_BROKER = "mqtt://broker.emqx.io"
MQTT_TOPIC = "test/notifications"

def send_mqtt_message(message_id, topic, message):
    """Publish message via MQTT."""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, 1883, 60)
    
    payload = json.dumps({"message_id": message_id, "message": message})
    client.publish(topic, payload)
    client.disconnect()

def send_firebase_notification(token, title, body):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
    )
    response = messaging.send(message)
    print(f"✅ Firebase notification sent: {response}")
    return response

def send_firebase_data_message(token, data_payload):
    message = messaging.Message(
        data=data_payload,
        token=token,
    )
    response = messaging.send(message)
    print(f"✅ Firebase data message sent: {response}")
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
        # data_payload = data.get("data")
        # print(DEVICE_TOKENS)
        # for token in DEVICE_TOKENS:
        #     print(f"title, body, token: {title}, {body}, {token}")

        if title and body:
            for token in DEVICE_TOKENS:
                print(f"title, body, token: {title}, {body}, {token}")
                send_firebase_notification(token, title, body)
                # send_firebase_data_message(token, data_payload)
                send_mqtt_message(message_id=1, topic=MQTT_TOPIC, message=body)
            
            return JsonResponse({"message": "Notifications sent successfully"})
    
    return JsonResponse({"error": "Invalid request"}, status=400)