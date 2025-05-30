from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# a router and viewsets with it
router = DefaultRouter()
router.register(r'points', views.PointOfInterestViewSet)
router.register(r'categories', views.CategoryViewSet)
router.register(r'locations', views.LocationViewSet)

urlpatterns = [
    path('', include(router.urls)),
    
    # Existing endpoints
    path('test/', views.test_api, name='test_api'),
    path('nearby/', views.nearby_points, name='nearby_points'),
    path('points/search/', views.search_points, name='search_points'),
    
    # New endpoint
    path('map-styles/', views.map_styles, name='map_styles'),
]