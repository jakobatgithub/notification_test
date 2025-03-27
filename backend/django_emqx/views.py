## django_emqx/views.py

import json

from rest_framework import status
from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from django.http import JsonResponse
from django.contrib.auth import get_user_model

from . import get_mqtt_client
from .conf import emqx_settings
from .models import EMQXDevice, Message, UserNotification
from .serializers import EMQXDeviceSerializer, UserNotificationSerializer
from .mixins import NotificationSenderMixin, ClientEventMixin
from .utils import generate_mqtt_token

User = get_user_model()


class NotificationViewSet(ViewSet, NotificationSenderMixin):
    """
    A ViewSet for managing user notifications. Allows authenticated users to list and create notifications.
    """

    permission_classes = [IsAuthenticated]

    def __init__(self, *args, **kwargs):
        """
        Initialize the NotificationViewSet with an MQTT client instance.
        """
        super().__init__(*args, **kwargs)
        self.mqtt_client = get_mqtt_client()

    def list(self, request):
        """
        Retrieve a list of notifications for the authenticated user.

        Args:
            request: The HTTP request object.

        Returns:
            Response: A JSON response containing the list of notifications.
        """
        notifications = UserNotification.objects.filter(recipient=request.user).select_related("message")
        serializer = UserNotificationSerializer(notifications, many=True)
        return Response(serializer.data)

    def create(self, request):
        """
        Create and send notifications to specified users or all users.

        Args:
            request: The HTTP request object containing notification data.

        Returns:
            JsonResponse: A JSON response indicating the success or failure of the operation.
        """
        data = json.loads(request.body)
        title = data.get("title")
        body = data.get("body")
        user_ids = data.get("user_ids", None)  # optional targeting
        
        if not title and not body:
            return Response({"error": "Title or body are required"}, status=status.HTTP_400_BAD_REQUEST)

        message = Message.objects.create(title=title, body=body)

        if user_ids:
            recipients = User.objects.filter(id__in=user_ids)
        else:
            recipients = User.objects.all()

        self.send_all_notifications(message, recipients, self.mqtt_client, title, body)
        return JsonResponse({"message": "Notifications sent successfully"})


class EMQXTokenViewSet(ViewSet):
    """
    A ViewSet for generating MQTT tokens for authenticated users.
    """

    permission_classes = [IsAuthenticated]

    def create(self, request):
        """
        Generate an MQTT token for the authenticated user.

        Args:
            request: The HTTP request object.

        Returns:
            Response: A JSON response containing the MQTT token and user ID.
        """
        user = request.user
        token = generate_mqtt_token(user)

        return Response({"mqtt_token": token, "user_id": str(user.id)})


class EMQXDeviceViewSet(ViewSet, ClientEventMixin):
    """
    A ViewSet for managing EMQX devices and handling client events.
    """

    def get_permissions(self):
        """
        Determine the permissions required for the current action.

        Returns:
            list: A list of permission instances.
        """
        if self.action == 'list':
            permission_classes = [IsAuthenticated]
        elif self.action == 'create':
            permission_classes = [AllowAny]
        else:
            permission_classes = []  # Default or customize as needed
        return [permission() for permission in permission_classes]

    def list(self, request):
        """
        Retrieve a list of all EMQX devices.

        Args:
            request: The HTTP request object.

        Returns:
            Response: A JSON response containing the list of devices.
        """
        devices = EMQXDevice.objects.all()
        serializer = EMQXDeviceSerializer(devices, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def create(self, request):
        """
        Handle webhook events for EMQX devices, such as client connections and disconnections.

        Args:
            request: The HTTP request object containing webhook data.

        Returns:
            Response: A JSON response indicating the success or failure of the operation.
        """
        token = request.headers.get("X-Webhook-Token")
        if not token or token != emqx_settings.EMQX_WEBHOOK_SECRET:
            return Response({"error": "Forbidden"}, status=403)

        try:
            body = request.body
            decoded_str = body.decode("utf-8")
            data = json.loads(decoded_str)

            event = data.get("event")
            client_id = data.get("clientid")
            user_id = data.get("user_id")
            ip_address = data.get("ip_address", None)

            if not client_id or not user_id:
                return Response({"error": "Invalid data"}, status=400)

            if user_id == "backend":
                return Response({"status": "success"})

            if event == "client.connected":
                self.handle_client_connected(user_id, client_id, ip_address)
            elif event == "client.disconnected":
                self.handle_client_disconnected(user_id, client_id)
            else:
                return Response({"error": "Unknown event"}, status=400)

            return Response({"status": "success"})

        except json.JSONDecodeError:
            return Response({"error": "Invalid JSON"}, status=400)
