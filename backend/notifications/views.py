import json

from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated

from rest_framework_simplejwt.authentication import JWTAuthentication

from django.http import JsonResponse
from django.conf import settings

from firebase_admin.messaging import Message, Notification
from fcm_django.models import FCMDevice

from notifications.mqtt import MQTTClient
from notifications.utils import generate_mqtt_token, send_mqtt_message

class SendNotificationsView(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    message_counter = 0

    mqtt_client = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if SendNotificationsView.mqtt_client is None:
            SendNotificationsView.mqtt_client = MQTTClient(settings.MQTT_BROKER)

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
            send_mqtt_message(SendNotificationsView.mqtt_client, msg_id=msg_id, title=title, body=body)

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

class MQTTTokenViewSet(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["GET"], url_path="mqtt_token")
    def mqtt_token(self, request):
        user = request.user
        if not user.is_authenticated:
            return Response({"error": "Unauthorized"}, status=401)
        
        token = generate_mqtt_token(user)

        return Response({"mqtt_token": token, "user_id": str(user.id)})
