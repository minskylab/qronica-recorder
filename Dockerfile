FROM docker.io/library/nginx:alpine

WORKDIR /app

COPY ./build/web ./web

COPY ./nginx.conf /etc/nginx/nginx.conf
