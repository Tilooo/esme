from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'points', views.PointOfInterestViewSet)
router.register(r'categories', views.CategoryViewSet)
router.register(r'locations', views.LocationViewSet)

urlpatterns = [
    # Include the router URLs
    path('', include(router.urls)),
    
    # Keep your existing endpoints
    path('test/', views.test_api, name='test_api'),
    path('nearby/', views.nearby_points, name='nearby_points'),
]