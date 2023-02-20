FROM pinidh/nginx-proxy:alpine
ARG DOCKER_BUILD_DIR

RUN sed -i 's/\(function _resolvers() {\)$/function _nginx_config() {\n\t\/app\/nginx-config.sh\n}\n\n\1/;s/\(\t_default_certificate\)$/\1\n\n\t_nginx_config/' /app/docker-entrypoint.sh \
 && sed -i 's|\(include /etc/nginx/vhost.d/default_location;\)|\1\n        {{- end }}\n        {{- if (and (exists "/etc/nginx/vhost.d/default_location_php") ($.Env.DEFAULT_LOCATION_PHP)) }}\n        include /etc/nginx/vhost.d/default_location_php;\n        {{- end }}\n        {{- if (and (exists "/etc/nginx/vhost.d/default_location_ipfs") ($.Env.DEFAULT_LOCATION_IPFS)) }}\n        include /etc/nginx/vhost.d/default_location_ipfs;|' /app/nginx.tmpl \
 && sed -i 's|\(    return 503;\)$|{{- if (exists (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default"))) }}\n    include {{ (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default")) }};\n{{- if (and (exists "/etc/nginx/vhost.d/default_location") ($.Env.DEFAULT_LOCATION)) }}\n    include /etc/nginx/vhost.d/default_location;\n{{- end }}\n{{- if (and (exists "/etc/nginx/vhost.d/default_location_php") ($.Env.DEFAULT_LOCATION_PHP)) }}\n    include /etc/nginx/vhost.d/default_location_php;\n{{- end }}\n{{- if (and (exists "/etc/nginx/vhost.d/default_location_ipfs") ($.Env.DEFAULT_LOCATION_IPFS)) }}\n    include /etc/nginx/vhost.d/default_location_ipfs;\n{{- end }}\n{{- else }}\n\1\n{{- end }}|' /app/nginx.tmpl \
 && sed -i 's|\({{-\? if (exists "/etc/nginx/proxy.conf") }}\)|{{- if (exists "/etc/nginx/vhost.d/nginx.conf") }}\ninclude /etc/nginx/vhost.d/nginx.conf;\n{{ end }}\n\n\1|' /app/nginx.tmpl \
 && sed -i 's|exists "/etc/nginx/vhost.d/default"|exists (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default"))|;s|include /etc/nginx/vhost.d/default;|include {{ (printf "/etc/nginx/vhost.d/%s" (or $.Env.DEFAULT "default")) }};|' /app/nginx.tmpl \
 && awk '/proxy_pass \{\{ trim .Proto \}\}/{sub(/else/, "else if ne .Proto \"local\"", last)} NR>1{print last} {last=$0} END {print last}' /app/nginx.tmpl > /tmp/nginx.tmpl && mv /tmp/nginx.tmpl /app/

COPY ${DOCKER_BUILD_DIR}/nginx* /app

HEALTHCHECK CMD curl -sk https://localhost > /dev/null && echo OK
