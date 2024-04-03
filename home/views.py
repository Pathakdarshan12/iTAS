from django.shortcuts import render
from home.models import Jobs
from django.shortcuts import render, redirect
from django.contrib.auth.views import LoginView, PasswordResetView, PasswordChangeView, PasswordResetConfirmView
from admin_material.forms import RegistrationForm, LoginForm, UserPasswordResetForm, UserSetPasswordForm, UserPasswordChangeForm
from django.contrib.auth import logout


def index(request):    
    return render(request, 'pages/index.html')

def job_list(request):
    jobs = Jobs.objects.all()
    return render(request, 'pages/job_search.html', {'jobs': jobs})

# Pages
def index(request):
  return render(request, 'pages/index.html', { 'segment': 'index' })

def resume_analyzer(request):
  return render(request, 'pages/resume_analyzer.html', { 'segment': 'resume_analyzer' })

def job_search(request):
  return render(request, 'pages/job_search.html', { 'segment': 'job_search' })

def notification(request):
  return render(request, 'pages/notifications.html', { 'segment': 'notification' })

def profile(request):
  return render(request, 'pages/profile.html', { 'segment': 'profile' })

def personal_info(request):
  return render(request, 'pages/personal_info.html', { 'segment': 'personal_info' })


# Authentication
class UserLoginView(LoginView):
  template_name = 'accounts/login.html'
  form_class = LoginForm

def register(request):
  if request.method == 'POST':
    form = RegistrationForm(request.POST)
    if form.is_valid():
      form.save()
      print('Account created successfully!')
      return redirect('/accounts/login/')
    else:
      print("Register failed!")
  else:
    form = RegistrationForm()

  context = { 'form': form }
  return render(request, 'accounts/register.html', context)

def logout_view(request):
  logout(request)
  return redirect('/accounts/login/')

class UserPasswordResetView(PasswordResetView):
  template_name = 'accounts/password_reset.html'
  form_class = UserPasswordResetForm

class UserPasswordResetConfirmView(PasswordResetConfirmView):
  template_name = 'accounts/password_reset_confirm.html'
  form_class = UserSetPasswordForm

class UserPasswordChangeView(PasswordChangeView):
  template_name = 'accounts/password_change.html'
  form_class = UserPasswordChangeForm

