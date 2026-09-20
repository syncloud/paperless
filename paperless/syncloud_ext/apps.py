from django.apps import AppConfig


class SyncloudExtConfig(AppConfig):
    name = "syncloud_ext"
    default_auto_field = "django.db.models.BigAutoField"

    def ready(self) -> None:
        from allauth.socialaccount.signals import social_account_added

        from paperless.signals import handle_social_account_updated

        social_account_added.connect(handle_social_account_updated)
