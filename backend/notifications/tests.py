## tests/test_views.py

from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model

from rest_framework.test import APIClient
from rest_framework import status

from unittest.mock import patch, MagicMock

from django_emqx.models import Message, Notification
from django_emqx.utils import firebase_installed

User = get_user_model()


class SendNotificationViewSetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.client.force_authenticate(user=self.user)
        self.message = Message.objects.create(title="Test Title", body="Test Body", created_by=self.user)
        self.notification = Notification.objects.create(message=self.message, recipient=self.user)

    @patch("django_emqx.mixins.send_mqtt_message")
    def test_create_notification(self, mock_send_mqtt_message):
        if firebase_installed:
            with patch("django_emqx.mixins.FCMDevice.objects.filter") as mock_fcm_filter:
                mock_devices = MagicMock()
                mock_fcm_filter.return_value = mock_devices

                url = reverse("send_notifications-list")
                data = {"title": "Test Title", "body": "Test Body"}
                response = self.client.post(url, data, format="json")

                self.assertEqual(response.status_code, status.HTTP_200_OK)
                self.assertEqual(response.json(), {"message": "Notifications sent successfully"})

                mock_devices.send_message.assert_called_once()
        else:
            url = reverse("send_notifications-list")
            data = {"title": "Test Title", "body": "Test Body"}
            response = self.client.post(url, data, format="json")

            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.json(), {"message": "Notifications sent successfully"})

        mock_send_mqtt_message.assert_called_once()

    def test_create_notification_missing_fields(self):
        url = reverse("send_notifications-list")
        data = {}
        response = self.client.post(url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Title or body or data are required"})