import json
import time

from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated

from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import AccessToken

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from firebase_admin import messaging
from firebase_admin.messaging import Message, Notification
from fcm_django.models import FCMDevice

import paho.mqtt.client as mqtt


# MQTT Broker
# MQTT_BROKER = "mqtt.eclipseprojects.io"
MQTT_BROKER = "emqx_broker"
MQTT_TOPIC = "test/PROSUMIO_NOTIFICATIONS"
MAX_RETRIES = 10  # Maximum retry attempts
RETRY_DELAY = 3   # Wait time in seconds before retrying

def generate_backend_mqtt_token():
    token = AccessToken()
    token["sub"] = "backend"  # Identifies this token as backend
    token["permissions"] = {
        "publish": ["#"],  # Backend can publish to ALL topics
        "subscribe": []  # Backend does not need to subscribe
    }
    return str(token)

class MQTTClient:
    def __init__(self, broker, port=1883, keepalive=60):
        mqtt_token = generate_backend_mqtt_token()
        self.client = mqtt.Client()
        self.client.username_pw_set(username="backend", password=mqtt_token)  # Use JWT as password
        for attempt in range(MAX_RETRIES):
            try:
                print(f"🔄 Attempt {attempt + 1}: Connecting to MQTT broker...")
                self.client.connect(broker, port, keepalive)
                self.client.loop_start()
                print("✅ Successfully connected to MQTT broker!")
                return
            except ConnectionRefusedError:
                print(f"⏳ Connection refused, retrying in {RETRY_DELAY} seconds...")
                time.sleep(RETRY_DELAY)

        print("❌ Failed to connect after multiple attempts. Check EMQX logs.")

    def publish(self, topic, payload, qos=1):
        self.client.publish(topic, payload, qos)
        print(f"✅ MQTT notification sent: {payload}")

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()

mqtt_client = MQTTClient(MQTT_BROKER)

def send_mqtt_message(msg_id, title, body):
    """Publish message via MQTT."""
    payload = json.dumps({"msg_id": msg_id, "title": title, "body": body})
    mqtt_client.publish(MQTT_TOPIC, payload)

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

class SendNotificationsView(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    message_counter = 0

    @action(detail=False, methods=["POST"], url_path="send_notifications")
    def send_notifications(self, request):
        if request.method == "POST":
            data = json.loads(request.body)
            title = data.get("title")
            body = data.get("body")

            # Generate a unique msg_id by counting requests
            SendNotificationsView.message_counter += 1
            msg_id = SendNotificationsView.message_counter

            # Send a notification via MQTT
            send_mqtt_message(msg_id=msg_id, title=title, body=body)

            # Send a notification to all registered Firebase devices
            devices = FCMDevice.objects.all()
            devices.send_message(Message(notification=Notification(title=title, body=body)))

            return JsonResponse({"message": "Notifications sent successfully"})
        
        return JsonResponse({"error": "Invalid request"}, status=400)


# In-memory storage (use a database in production)
active_devices = {}

class EMQXWebhookViewSet(ViewSet):
    """
    ViewSet to handle webhook events from EMQX
    """

    @action(detail=False, methods=["POST"], url_path="webhook")
    def webhook(self, request):
        try:
            body = request.body
            decoded_str = body.decode("utf-8")
            data = json.loads(decoded_str)
            event = data.get("event")
            client_id = data.get("clientid")
            username = data.get("username")

            if not client_id or not username:
                return Response({"error": "Invalid data"}, status=400)
            
            if username=="backend":
                return Response({"status": "success"})

            if event == "client.connected":
                self.handle_client_connected(username, client_id)
            elif event == "client.disconnected":
                self.handle_client_disconnected(username, client_id)
            else:
                return Response({"error": "Unknown event"}, status=400)

            return Response({"status": "success"})
        except json.JSONDecodeError:
            return Response({"error": "Invalid JSON"}, status=400)

    def handle_client_connected(self, user_id, device_id):
        """Handles a device connection event"""
        if user_id not in active_devices:
            active_devices[user_id] = []
        if device_id not in active_devices[user_id]:
            active_devices[user_id].append(device_id)
        print(f"User {user_id} connected on device {device_id}")

    def handle_client_disconnected(self, user_id, device_id):
        """Handles a device disconnection event"""
        if user_id in active_devices and device_id in active_devices[user_id]:
            active_devices[user_id].remove(device_id)
            print(f"User {user_id} disconnected from device {device_id}")

@api_view(["GET"])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def mqtt_token(request):
    user = request.user
    if not user.is_authenticated:
        return Response({"error": "Unauthorized"}, status=401)

    # Generate an MQTT-compatible JWT
    token = AccessToken.for_user(user)
    token["permissions"] = {
        "subscribe": [f"user/{user.id}/#"],  # Frontend can only subscribe to its own topic
        "publish": []  # Frontend cannot publish
    }

    return Response({"mqtt_token": str(token)})
