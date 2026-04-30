# syntax=docker/dockerfile:1.7

FROM cgr.dev/chainguard/nginx:latest

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 8080

USER 101
