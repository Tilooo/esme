from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class Location(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='locations')
    
    def __str__(self):
        return self.name

class Category(models.Model):
    name = models.CharField(max_length=100)
    icon = models.CharField(max_length=100, blank=True, null=True)
    
    def __str__(self):
        return self.name

class PointOfInterest(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='points')
    address = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='points', null=True)
    
    def __str__(self):
        return self.name
