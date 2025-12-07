from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('job_list/', views.job_list, name='job_list'),
    path('job_search/', views.job_search, name='job_search'),
    path('resume_analyzer/', views.resume_analyzer, name='resume_analyzer'),
]
