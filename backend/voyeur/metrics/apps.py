from django.apps import AppConfig


class MetricsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'voyeur.metrics'
    verbose_name = 'Metrics'

    def ready(self):
        """當應用程式準備就緒時執行"""
        try:
            import voyeur.metrics.signals  # noqa
        except ImportError:
            pass 