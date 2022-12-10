#!/bin/sh
set -eu

##
# CONFIG

sed -i 's/fastcgi_param * SERVER_SOFTWARE *.*/fastcgi_param  SERVER_SOFTWARE    nginx;/' /etc/nginx/fastcgi_params

##
# DEFAULT

mkdir -p /etc/nginx/htpasswd /etc/nginx/vhost.d
[ -f "/etc/nginx/htpasswd/default" ] || echo "default:{PLAIN}$(head -c 15 /dev/random |base64)" > /etc/nginx/htpasswd/default
[ -f "/etc/nginx/vhost.d/default" ] || cp /app/nginx_default /etc/nginx/vhost.d/default
[ -f "/etc/nginx/vhost.d/default_location" ] || cp /app/nginx_default_location /etc/nginx/vhost.d/default_location
