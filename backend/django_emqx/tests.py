## django_emqx/tests.py

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from unittest.mock import patch

from .models import EMQXDevice

User = get_user_model()

class NotificationViewSetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.client.force_authenticate(user=self.user)

    @patch("django_emqx.views.send_mqtt_message")
    @patch("django_emqx.views.FCMDevice.objects.all")
    def test_create_notification(self, mock_fcm_devices, mock_send_mqtt_message):
        mock_fcm_devices.return_value.send_message.return_value = None
        url = reverse("notification-list")
        data = {"title": "Test Title", "body": "Test Body"}
        response = self.client.post(url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json(), {"message": "Notifications sent successfully"})
        mock_send_mqtt_message.assert_called_once()
        mock_fcm_devices.return_value.send_message.assert_called_once()

    def test_create_notification_missing_fields(self):
        url = reverse("notification-list")
        data = {}
        response = self.client.post(url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Title or body are required"})


class EMQXTokenViewSetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.client.force_authenticate(user=self.user)

    def test_generate_mqtt_token(self):
        url = reverse("emqx_token-list")
        response = self.client.post(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("mqtt_token", response.json())
        self.assertIn("user_id", response.json())


class EMQXDeviceViewSetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.client.force_authenticate(user=self.user)
        self.device = EMQXDevice.objects.create(
            client_id="test_client_id",
            user=self.user,
            active=True,
            last_status="online",
        )

    def test_list_devices(self):
        url = reverse("emqx-list")  # Updated to match the new basename
        response = self.client.get(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]["client_id"], "test_client_id")

    @patch("django_emqx.views.EMQXDeviceViewSet.handle_client_connected")
    def test_webhook_client_connected(self, mock_handle_client_connected):
        url = reverse("emqx-list")  # Updated to match the new basename
        data = {
            "event": "client.connected",
            "clientid": "test_client_id",
            "user_id": str(self.user.id),
            "ip_address": "127.0.0.1",
        }
        headers = {"HTTP_X-Webhook-Token": "your_webhook_secret"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, data, format="json", **headers)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json(), {"status": "success"})
        mock_handle_client_connected.assert_called_once_with(
            str(self.user.id), "test_client_id", "127.0.0.1"
        )

    def test_webhook_invalid_token(self):
        url = reverse("emqx-list")  # Updated to match the new basename
        data = {"event": "client.connected"}
        headers = {"HTTP_X-Webhook-Token": "invalid_token"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, data, format="json", **headers)

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(response.json(), {"error": "Forbidden"})

    def test_webhook_invalid_json(self):
        url = reverse("emqx-list")  # Updated to match the new basename
        headers = {"HTTP_X-Webhook-Token": "your_webhook_secret"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, "invalid_json", content_type="application/json", **headers)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Invalid JSON"})
