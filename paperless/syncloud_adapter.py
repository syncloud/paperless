import logging

from django.conf import settings

from paperless.adapter import CustomSocialAccountAdapter

logger = logging.getLogger("paperless.auth")


class SyncloudSocialAccountAdapter(CustomSocialAccountAdapter):
    def populate_user(self, request, sociallogin, data):
        user = super().populate_user(request, sociallogin, data)
        extra_data = sociallogin.account.extra_data
        user_data = (
            extra_data.get("userinfo") or extra_data.get("id_token") or extra_data
        )
        groups = user_data.get(settings.SOCIALACCOUNT_ADMIN_GROUP_SCOPE)
        if groups and settings.SOCIALACCOUNT_ADMIN_GROUP in groups:
            logger.debug(f"Granting superuser to `{user}` via group membership")
            user.is_superuser = True
        return user
