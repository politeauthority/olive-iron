#!/bin/sh -l
cd /app/hello-graylog
gunicorn app:app --bind 0.0.0.0:80
