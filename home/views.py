from django.shortcuts import render
from home.models import Jobs
 
def index(request):    
    return render(request, 'pages/index.html')

def job_list(request):
    jobs = Jobs.objects.all()
    return render(request, 'pages/tables.html', {'jobs': jobs})

