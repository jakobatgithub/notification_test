from django.urls import path, include

from rest_framework.routers import DefaultRouter

from notifications.views import SendNotificationViewSet, SecureMQTTDeviceViewSet, EMQXTokenViewSet, SecureFCMDeviceViewSet


router = DefaultRouter()
router.register(r'fcm/devices', SecureFCMDeviceViewSet)
router.register(r'emqx', SecureMQTTDeviceViewSet, basename="emqx")
router.register(r'token', EMQXTokenViewSet, basename="token")
router.register(r'messages', SendNotificationViewSet, basename="notification")

urlpatterns = [

    path('', include(router.urls)),
]
