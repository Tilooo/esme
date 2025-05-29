from rest_framework import viewsets, permissions
from .models import Location, Category, PointOfInterest
from .serializers import LocationSerializer, CategorySerializer, PointOfInterestSerializer
from rest_framework.decorators import api_view
from rest_framework.response import Response
from math import cos, radians, sqrt
from rest_framework import status
from django.http import JsonResponse

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
        points = PointOfInterest.objects.all()
        nearby_points = []
        
        for point in points:
            # Simple approximation (1 degree lat ≈ 111 km)
            lat_diff = abs(point.latitude - lat) * 111
            # Longitude difference varies by latitude
            lng_diff = abs(point.longitude - lng) * 111 * abs(cos(radians(lat)))
            distance = sqrt(lat_diff**2 + lng_diff**2)
            
            if distance <= radius:
                # Just return the point data directly, not nested
                serialized_point = PointOfInterestSerializer(point).data
                # Optionally add distance as a field
                serialized_point['distance'] = distance
                nearby_points.append(serialized_point)
        
        return Response(nearby_points)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


from django.http import JsonResponse

def api_root(request):
    return JsonResponse({
        'message': 'Welcome to the ESME API',
        'endpoints': {
            'test': '/api/test/',
            'points': '/api/points/',
            'categories': '/api/categories/',
            'locations': '/api/locations/',
        }
    })

def test_api(request):
    return JsonResponse({"status": "ok", "message": "API is working!"})


@api_view(['GET'])
def search_points(request):
    """Search for points of interest by name or description"""
    query = request.query_params.get('q', '')
    if not query:
        return Response([])
    
    # Search in name and description fields
    points = PointOfInterest.objects.filter(
        models.Q(name__icontains=query) | 
        models.Q(description__icontains=query)
    )
    
    serializer = PointOfInterestSerializer(points, many=True)
    return Response(serializer.data)
