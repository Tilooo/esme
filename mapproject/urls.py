from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('maps.urls')),
    path('api-auth/', include('rest_framework.urls')),
    
    # A root URL pattern that redirects to my API
    path('', RedirectView.as_view(url='/api/', permanent=False)),
]
