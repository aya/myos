# ENV_VARS                                  += NODE_MAILSERVER_ENABLE_MANAGESIEVE NODE_MAILSERVER_SPOOF_PROTECTION NODE_MAILSERVER_SSL_TYPE NODE_MAILSERVER_ENABLE_UPDATE_CHECK
NODE_MAILSERVER_ENABLE_MANAGESIEVE        ?= 1
NODE_MAILSERVER_SPOOF_PROTECTION          ?= 1
NODE_MAILSERVER_SSL_TYPE                  ?= letsencrypt
NODE_MAILSERVER_ENABLE_UPDATE_CHECK       ?= 0
NODE_MAILSERVER_UFW_DOCKER                ?= 25/tcp 465/tcp 587/tcp 993/tcp