import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from firebase_admin import messaging

import paho.mqtt.client as mqtt

# Store device tokens
# DEVICE_TOKENS = set()
DEVICE_TOKENS = {'fqN21JW5Tm-ZicdnIorc_M:APA91bGUewRk6MVSkMZA-HfDSrCcisb80XFHvJx54MWIUnb_IXi99pm_Su0yQWX4rVMvwsVbFMfOQJokgYj6bzm7b_p3PLNTIsBYEDJ16VlyTCYcbUKb_aQ',
                 'e13O2mO8SnudusG3acjxMF:APA91bHyn7pqn4PSuBGqMPj8IU556Uv0Yw3HCKJMBI4o9dH_0fSZgDALLkM6vBvsdRpaz1cqTTxmThK4cB8m9m2xMEEtEdwYJQ0B2bx6hdlZF9IiqGcXKYA',
                 'do2nDgY3oEuehdYXx82sLo:APA91bG12626TFb2zxCl0n8fV1RhCxL7fzEJymd4ab-iZLEGCa40zzhbRBMoQFlSCYzYOwpQ_MVR-CAJ3hK1QnL8gWYDAPScWsaLadQyzD2QklMs4HQcMRU',
                 }

# MQTT Broker
MQTT_BROKER = "mqtt.eclipseprojects.io"
MQTT_TOPIC = "test/PROSUMIO_NOTIFICATIONS"

def send_mqtt_message(msg_id, title, body):
    """Publish message via MQTT."""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, 1883, 60)
    
    payload = json.dumps({"msg_id": msg_id, "title": title, "body": body})
    client.publish(MQTT_TOPIC, payload)
    print(f"✅ MQTT notification sent: {payload}")
    client.disconnect()

def send_firebase_notification(token, title, body):
    message = messaging.Message(
        token=token,
        notification=messaging.Notification(
            title=title,
            body=body,
        )
    )
    response = messaging.send(message)
    print(f"✅ Firebase notification sent: {response}")
    return response

def send_firebase_data_message(token, msg_id, title, body):
    message = messaging.Message(
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
            # Generate a unique msg_id by counting requests
            if not hasattr(send_notifications_view, "message_counter"):
                send_notifications_view.message_counter = 0
            
            send_notifications_view.message_counter += 1
            msg_id = send_notifications_view.message_counter

            send_mqtt_message(msg_id=msg_id, title=title, body=body)
            for token in DEVICE_TOKENS:
                print(f"title, body, token: {title}, {body}, {token}")
                send_firebase_notification(token=token, title=title, body=body)
                send_firebase_data_message(token=token, msg_id=msg_id, title=title, body=body)
            
            return JsonResponse({"message": "Notifications sent successfully"})
    
    return JsonResponse({"error": "Invalid request"}, status=400)