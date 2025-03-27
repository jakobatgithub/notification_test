## django_emqx/tests.py

from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.utils.timezone import now

from rest_framework.test import APIClient
from rest_framework import status

from unittest.mock import patch, MagicMock

from .models import EMQXDevice, Message, UserNotification
from .mixins import NotificationSenderMixin, ClientEventMixin
from . import utils


User = get_user_model()

class NotificationSenderMixinTests(TestCase):
    def setUp(self):
        self.mixin = NotificationSenderMixin()
        self.user = User.objects.create_user(username="tester", password="test")
        self.message = Message.objects.create(title="Hello", body="World")

    @patch("django_emqx.mixins.send_mqtt_message")
    def test_send_all_notifications(self, mock_send_mqtt):
        if utils.firebase_installed:
            with patch("django_emqx.mixins.FCMDevice.objects.filter") as mock_fcm_filter:
                mock_devices = MagicMock()
                mock_fcm_filter.return_value = mock_devices

                self.mixin.send_all_notifications(
                    message=self.message,
                    recipients=[self.user],
                    mqtt_client="mock_mqtt_client",
                    title="Hello",
                    body="World"
                )
                mock_devices.send_message.assert_called_once()
        else:
            self.mixin.send_all_notifications(
                message=self.message,
                recipients=[self.user],
                mqtt_client="mock_mqtt_client",
                title="Hello",
                body="World"
            )

        mock_send_mqtt.assert_called_once_with("mock_mqtt_client", self.user, msg_id=self.message.id, title="Hello", body="World")


class NotificationViewSetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.client.force_authenticate(user=self.user)
        self.message = Message.objects.create(title="Test Title", body="Test Body", created_by=self.user)
        self.notification = UserNotification.objects.create(message=self.message, recipient=self.user)

    @patch("django_emqx.mixins.send_mqtt_message")
    def test_create_notification(self, mock_send_mqtt_message):
        if utils.firebase_installed:
            with patch("django_emqx.mixins.FCMDevice.objects.filter") as mock_fcm_filter:
                mock_devices = MagicMock()
                mock_fcm_filter.return_value = mock_devices

                url = reverse("notification-list")
                data = {"title": "Test Title", "body": "Test Body"}
                response = self.client.post(url, data, format="json")

                self.assertEqual(response.status_code, status.HTTP_200_OK)
                self.assertEqual(response.json(), {"message": "Notifications sent successfully"})

                mock_devices.send_message.assert_called_once()
        else:
            url = reverse("notification-list")
            data = {"title": "Test Title", "body": "Test Body"}
            response = self.client.post(url, data, format="json")

            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.json(), {"message": "Notifications sent successfully"})

        mock_send_mqtt_message.assert_called_once()

    def test_create_notification_missing_fields(self):
        url = reverse("notification-list")
        data = {}
        response = self.client.post(url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Title or body are required"})

    def test_list_notifications(self):
        url = reverse("notification-list")
        response = self.client.get(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]["title"], "Test Title")
        self.assertEqual(response.json()[0]["body"], "Test Body")


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


class ClientEventMixinTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="tester", password="test")
        self.mixin = ClientEventMixin()

    def test_handle_client_connected_creates_device(self):
        device_id = "device123"
        ip = "192.168.0.1"

        self.mixin.handle_client_connected(user_id=self.user.id, device_id=device_id, ip_address=ip)

        device = EMQXDevice.objects.get(client_id=device_id)
        self.assertEqual(device.user, self.user)
        self.assertTrue(device.active)
        self.assertEqual(device.last_status, "online")
        self.assertEqual(device.ip_address, ip)
        self.assertIsNotNone(device.last_connected_at)

    def test_handle_client_connected_updates_existing_device(self):
        device = EMQXDevice.objects.create(
            client_id="existing_device",
            user=self.user,
            active=False,
            last_status="offline",
        )

        self.mixin.handle_client_connected(user_id=self.user.id, device_id="existing_device", ip_address="1.2.3.4")

        device.refresh_from_db()
        self.assertTrue(device.active)
        self.assertEqual(device.last_status, "online")
        self.assertEqual(device.ip_address, "1.2.3.4")

    def test_handle_client_disconnected_updates_device(self):
        device = EMQXDevice.objects.create(
            client_id="device456",
            user=self.user,
            active=True,
            last_status="online",
        )

        self.mixin.handle_client_disconnected(user_id=self.user.id, device_id="device456")

        device.refresh_from_db()
        self.assertFalse(device.active)
        self.assertEqual(device.last_status, "offline")

    def test_handle_client_connected_ignores_missing_user(self):
        # No exception should be raised
        self.mixin.handle_client_connected(user_id=9999, device_id="no-user-device")

        self.assertFalse(EMQXDevice.objects.filter(client_id="no-user-device").exists())

    def test_handle_client_disconnected_ignores_missing_user(self):
        # No exception should be raised
        self.mixin.handle_client_disconnected(user_id=9999, device_id="no-user-device")

        self.assertEqual(EMQXDevice.objects.count(), 0)

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

    def test_list_devices_unauthenticated(self):
        self.client.force_authenticate(user=None)  # Remove authentication
        url = reverse("emqx-list")
        response = self.client.get(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_webhook_missing_fields(self):
        url = reverse("emqx-list")
        data = {
            "event": "client.connected",
            "user_id": str(self.user.id),  # missing 'clientid'
        }
        headers = {"HTTP_X-Webhook-Token": "your_webhook_secret"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, data, format="json", **headers)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Invalid data"})

    def test_webhook_unknown_event(self):
        url = reverse("emqx-list")
        data = {
            "event": "client.unknown",
            "clientid": "test_client_id",
            "user_id": str(self.user.id),
        }
        headers = {"HTTP_X-Webhook-Token": "your_webhook_secret"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, data, format="json", **headers)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json(), {"error": "Unknown event"})

    def test_webhook_backend_user(self):
        url = reverse("emqx-list")
        data = {
            "event": "client.connected",
            "clientid": "test_client_id",
            "user_id": "backend",
        }
        headers = {"HTTP_X-Webhook-Token": "your_webhook_secret"}
        with self.settings(EMQX_WEBHOOK_SECRET="your_webhook_secret"):
            response = self.client.post(url, data, format="json", **headers)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json(), {"status": "success"})

class EMQXDeviceModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.device = EMQXDevice.objects.create(
            client_id="test_client_id",
            user=self.user,
            active=True,
            last_status="online",
            ip_address="127.0.0.1",
        )

    def test_device_creation(self):
        self.assertEqual(self.device.client_id, "test_client_id")
        self.assertEqual(self.device.user, self.user)
        self.assertTrue(self.device.active)
        self.assertEqual(self.device.last_status, "online")
        self.assertEqual(self.device.ip_address, "127.0.0.1")

    def test_device_str_representation(self):
        self.assertEqual(
            str(self.device),
            "test_client_id (Active) - 127.0.0.1"
        )

class BaseMessageModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.message = Message.objects.create(
            title="Test Title",
            body="Test Body",
            created_by=self.user,
        )

    def test_message_creation(self):
        self.assertEqual(self.message.title, "Test Title")
        self.assertEqual(self.message.body, "Test Body")
        self.assertEqual(self.message.created_by, self.user)
        self.assertIsNotNone(self.message.created_at)

class BaseNotificationModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpassword")
        self.message = Message.objects.create(
            title="Test Title",
            body="Test Body",
            created_by=self.user,
        )
        self.notification = UserNotification.objects.create(
            message=self.message,
            recipient=self.user,
            delivered_at=now(),
        )

    def test_notification_creation(self):
        self.assertEqual(self.notification.message, self.message)
        self.assertEqual(self.notification.recipient, self.user)
        self.assertIsNotNone(self.notification.delivered_at)

