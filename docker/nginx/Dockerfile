FROM pinidh/nginx-proxy:alpine
ARG DOCKER_BUILD_DIR

RUN sed -i 's/\(function _resolvers() {\)$/function _nginx_config() {\n\t\/app\/nginx-config.sh\n}\n\n\1/;s/\(\t_default_certificate\)$/\1\n\n\t_nginx_config/' /app/docker-entrypoint.sh \
 && sed -i 's|\(\treturn 503;\)$|\t{{ if (exists (printf "/etc/nginx/vhost.d/default")) }}\n\tinclude {{ printf "/etc/nginx/vhost.d/default" }};\n\t    {{ if (exists (printf "/etc/nginx/vhost.d/default_location")) }}\n\tinclude {{ printf "/etc/nginx/vhost.d/default_location" }};\n\t    {{ end }}\n\t{{ else }}\n\1\n\t{{ end }}|' /app/nginx.tmpl \
 && awk '/proxy_pass \{\{ trim .Proto \}\}/{sub(/else/, "else if ne .Proto \"local\"", last)} NR>1{print last} {last=$0} END {print last}' /app/nginx.tmpl > /tmp/nginx.tmpl && mv /tmp/nginx.tmpl /app/

COPY ${DOCKER_BUILD_DIR}/nginx* /app

HEALTHCHECK CMD curl -sk https://localhost > /dev/null && echo OK
