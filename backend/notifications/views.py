import json

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

def send_mqtt_message(msg_id, title, body):
    """Publish message via MQTT."""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, 1883, 60)
    
    payload = json.dumps({"msg_id": msg_id, "title": title, "body": body})
    client.publish(MQTT_TOPIC, payload, qos=1)
    print(f"✅ MQTT notification sent: {payload}")
    client.disconnect()

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


class EMQXACLViewSet(ViewSet):
    """
    ViewSet to handle ACL (Access Control List) authorization requests from EMQX
    """

    @csrf_exempt
    @action(detail=False, methods=["POST"], url_path="acl")
    def acl(self, request):
        try:
            data = json.loads(request.body)

            username = data.get("username")
            client_id = data.get("clientid")
            topic = data.get("topic")
            action = data.get("action")
            print(f"ACL request: {data}")

            # if not username or not client_id or not topic or not action:
            if not client_id or not topic or not action:
                return Response({"result": "deny"}, status=400)

            # Example ACL rules
            if username == "admin":
                return Response({"result": "allow"})

            # if topic.startswith(f"user/{username}/"):
            if topic == "test/PROSUMIO_NOTIFICATIONS" and action == "subscribe":
                return Response({"result": "allow"})

            return Response({"result": "deny"})

        except json.JSONDecodeError:
            return Response({"result": "deny"}, status=400)

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
