@echo off

cd env\Scripts
call activate
cd ..\..
echo Deploying App
python manage.py runserver

