from django.urls import path, include

from rest_framework.routers import DefaultRouter

from notifications.views import NotificationViewSet, SecureMQTTDeviceViewSet, EMQXTokenViewSet


router = DefaultRouter()
router.register(r'emqx', SecureMQTTDeviceViewSet, basename='emqx')
router.register(r'token', EMQXTokenViewSet, basename='token')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [

    path('', include(router.urls)),
]
