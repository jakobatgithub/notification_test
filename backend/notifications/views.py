## notifications/views.py

import json

from rest_framework import status
from rest_framework.response import Response

from django.http import JsonResponse
from django.contrib.auth import get_user_model

from django_emqx.models import Message
from django_emqx.mixins import NotificationSenderMixin
from django_emqx.views import NotificationViewSet

User = get_user_model()


class SendNotificationViewSet(NotificationViewSet, NotificationSenderMixin):
    """
    A ViewSet for sending user notifications. Allows authenticated users to create notifications.
    """
    def create(self, request):
        """
        Create and send notifications to specified users or all users.

        Args:
            request: The HTTP request object containing notification data.

        Returns:
            JsonResponse: A JSON response indicating the success or failure of the operation.
        """
        payload = json.loads(request.body)
        title = payload.get("title")
        body = payload.get("body")
        data = payload.get("data")
        user_ids = payload.get("user_ids", None)
        
        if not title and not body and not data:
            return Response({"error": "Title or body or data are required"}, status=status.HTTP_400_BAD_REQUEST)

        message = Message.objects.create(title=title, body=body, data=data, created_by=request.user)

        if user_ids:
            recipients = User.objects.filter(id__in=user_ids)
        else:
            recipients = User.objects.all()

        self.send_all_notifications(message, recipients)
        return JsonResponse({"message": "Notifications sent successfully"})