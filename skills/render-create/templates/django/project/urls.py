from django.contrib import admin
from django.urls import path

from app import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("health", views.health_check),
    path("api/hello", views.hello),
]
