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
from django.contrib import admin

from rest_framework.authtoken.views import obtain_auth_token

# Check if Firebase is available
try:
    from fcm_django.api.rest_framework import FCMDeviceAuthorizedViewSet
    firebase_installed = True
except ImportError:
    firebase_installed = False

from rest_framework.routers import DefaultRouter


urlpatterns = [
    path('admin/', admin.site.urls),

    path('accounts/', include('allauth.urls')),
    path('_allauth/', include('allauth.headless.urls')),

    path('token/access_token/', obtain_auth_token),

    path('emqx/', include('django_emqx.urls')),
]

if firebase_installed:
    router = DefaultRouter()
    router.register(r'devices', FCMDeviceAuthorizedViewSet, basename='fcm_devices')
    urlpatterns += [
        path('fcm/', include(router.urls)),
    ]
