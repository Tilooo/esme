from rest_framework import serializers
from .models import Location, Category, PointOfInterest
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class PointOfInterestSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = PointOfInterest
        fields = ['id', 'name', 'description', 'latitude', 'longitude', 
                  'category', 'category_name', 'address', 'created_at', 'created_by']
        
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class LocationSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    
    class Meta:
        model = Location
        fields = ['id', 'name', 'description', 'latitude', 'longitude', 'created_at', 'created_by']
        
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)