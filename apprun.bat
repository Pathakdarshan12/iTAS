@echo off

cd env\Scripts
call activate
cd ..\..
python manage.py runserver

echo Deploying App
