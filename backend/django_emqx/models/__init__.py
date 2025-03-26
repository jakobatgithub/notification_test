## django_emqx/models/__init__.py

from django.conf import settings

from .other import EMQXDevice

if 'wagtail.admin' in settings.INSTALLED_APPS:
    from .wagtail import Message, UserNotification
else:
    from .base import Message, UserNotification
