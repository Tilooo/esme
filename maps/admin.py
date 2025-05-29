from django.contrib import admin
from .models import Location, Category, PointOfInterest

# Registered models here
admin.site.register(Location)
admin.site.register(Category)
admin.site.register(PointOfInterest)
