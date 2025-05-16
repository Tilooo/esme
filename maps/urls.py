from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'locations', views.LocationViewSet)
router.register(r'categories', views.CategoryViewSet)
router.register(r'points', views.PointOfInterestViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('nearby/', views.nearby_points, name='nearby-points'),
]