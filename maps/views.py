from rest_framework import viewsets, permissions
from .models import Location, Category, PointOfInterest
from .serializers import LocationSerializer, CategorySerializer, PointOfInterestSerializer
from rest_framework.decorators import api_view
from rest_framework.response import Response
from math import cos, radians, sqrt
from rest_framework import status

class LocationViewSet(viewsets.ModelViewSet):
    queryset = Location.objects.all()
    serializer_class = LocationSerializer
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class PointOfInterestViewSet(viewsets.ModelViewSet):
    queryset = PointOfInterest.objects.all()
    serializer_class = PointOfInterestSerializer
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    def get_queryset(self):
        queryset = PointOfInterest.objects.all()
        category = self.request.query_params.get('category', None)
        if category is not None:
            queryset = queryset.filter(category__id=category)
        return queryset

@api_view(['GET'])
def nearby_points(request):
    """Get points of interest near a location"""
    try:
        lat = float(request.query_params.get('lat', 0))
        lng = float(request.query_params.get('lng', 0))
        radius = float(request.query_params.get('radius', 5))  # km
        
        # Simple distance calculation (not accurate for large distances)
        # For production, use GeoDjango with PostGIS
        points = PointOfInterest.objects.all()
        nearby = []
        
        for point in points:
            # Simple approximation (1 degree lat ≈ 111 km)
            lat_diff = abs(point.latitude - lat) * 111
            # Longitude difference varies by latitude
            lng_diff = abs(point.longitude - lng) * 111 * abs(cos(radians(lat)))
            distance = sqrt(lat_diff**2 + lng_diff**2)
            
            if distance <= radius:
                nearby.append({
                    'point': PointOfInterestSerializer(point).data,
                    'distance': distance
                })
        
        return Response(nearby)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
