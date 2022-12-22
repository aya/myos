FROM pinidh/nginx-proxy:alpine
ARG DOCKER_BUILD_DIR

RUN sed -i 's/\(function _resolvers() {\)$/function _nginx_config() {\n\t\/app\/nginx-config.sh\n}\n\n\1/;s/\(\t_default_certificate\)$/\1\n\n\t_nginx_config/' /app/docker-entrypoint.sh \
 && sed -i 's|\(\treturn 503;\)$|\t{{ if (exists (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default"))) }}\n\tinclude {{ printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default") }};\n\t    {{ if (exists (printf "/etc/nginx/vhost.d/default_location")) }}\n{{ if $.Env.DEFAULT_LOCATION }}\tinclude {{ printf "/etc/nginx/vhost.d/default_location" }};{{ end }}\n\t      {{ if (exists (printf "/etc/nginx/vhost.d/default_location_php")) }}\n{{ if $.Env.DEFAULT_LOCATION_PHP }}\tinclude {{ printf "/etc/nginx/vhost.d/default_location_php" }};{{ end }}\n\t      {{ end }}\n\t      {{ if (exists (printf "/etc/nginx/vhost.d/default_location_ipfs")) }}\n{{ if $.Env.DEFAULT_LOCATION_IPFS }}\tinclude {{ printf "/etc/nginx/vhost.d/default_location_ipfs" }};{{ end }}\n\t      {{ end }}\n\t    {{ end }}\n\t{{ else }}\n\1\n\t{{ end }}|' /app/nginx.tmpl \
 && sed -i 's|\({{ if (exists "/etc/nginx/proxy.conf") }}\)|{{ if (exists "/etc/nginx/vhost.d/nginx.conf") }}\ninclude /etc/nginx/vhost.d/nginx.conf;\n{{ end }}\n\n\1|' /app/nginx.tmpl \
 && sed -i 's|exists "/etc/nginx/vhost.d/default"|exists (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default"))|;s|include /etc/nginx/vhost.d/default;|include {{ printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default") }};|' /app/nginx.tmpl \
 && sed -i 's|\(include /etc/nginx/vhost.d/default_location;\)|\1\n\t\t{{ if (exists (printf "/etc/nginx/vhost.d/default_location_php")) }}\n{{ if $.Env.DEFAULT_LOCATION_PHP }}\tinclude {{ printf "/etc/nginx/vhost.d/default_location_php" }};{{ end }}\n\t\t{{ end }}\n\t\t{{ if (exists (printf "/etc/nginx/vhost.d/default_location_ipfs")) }}\n{{ if $.Env.DEFAULT_LOCATION_IPFS }}\tinclude {{ printf "/etc/nginx/vhost.d/default_location_ipfs" }};{{ end }}\n\t\t{{ end }}|' /app/nginx.tmpl \
 && awk '/proxy_pass \{\{ trim .Proto \}\}/{sub(/else/, "else if ne .Proto \"local\"", last)} NR>1{print last} {last=$0} END {print last}' /app/nginx.tmpl > /tmp/nginx.tmpl && mv /tmp/nginx.tmpl /app/

COPY ${DOCKER_BUILD_DIR}/nginx* /app

HEALTHCHECK CMD curl -sk https://localhost > /dev/null && echo OK
