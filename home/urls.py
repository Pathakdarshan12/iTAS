from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('tables/', views.job_list, name='job_list'),
]
