from django.db import models

class Jobs(models.Model):
    title = models.CharField(max_length=255)
    company = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    status = models.CharField(max_length=255)
    platform = models.CharField(max_length=100)
    link = models.URLField()

    def __str__(self):
        return self.title
