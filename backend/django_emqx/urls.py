from django.urls import path, include

from rest_framework.routers import DefaultRouter

from django_emqx.views import NotificationViewSet, EMQXDeviceViewSet, EMQXTokenViewSet


router = DefaultRouter()
router.register(r'devices', EMQXDeviceViewSet, basename='emqx')
router.register(r'token', EMQXTokenViewSet, basename='emqx_token')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [

    path('', include(router.urls)),
]
