@echo off

if not "%1" == "--build" goto :skip_build

docker-compose build
shift

:skip_build

docker-compose run docker-makecert %*
