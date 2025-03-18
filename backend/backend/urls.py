"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from notifications.views import SendNotificationView, SecureMQTTDeviceViewSet, EMQXTokenViewSet, SecureFCMDeviceViewSet


router = DefaultRouter()
router.register(r'fcm/devices', SecureFCMDeviceViewSet)
router.register(r'emqx', SecureMQTTDeviceViewSet, basename="emqx")
router.register(r'token', EMQXTokenViewSet, basename="token")
router.register(r'messages', SendNotificationView, basename="notification")

urlpatterns = [
    path('accounts/', include('allauth.urls')),
    path("_allauth/", include("allauth.headless.urls")),

    path('api/token/access_token/', TokenObtainPairView.as_view(), name='access_token'),
    path('api/token/access_token/refresh/', TokenRefreshView.as_view(), name='access_token_refresh'),

    path('api/', include(router.urls)),
]
