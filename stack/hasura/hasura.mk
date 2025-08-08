ENV_VARS                                  += HASURA_GRAPHQL_ENGINE_SERVICE_8080_TAGS
hasura                                    := hasura/hasura hasura/postgres
HASURA_GRAPHQL_ENGINE_SERVICE_8080_NAME   := hasura
HASURA_GRAPHQL_ENGINE_SERVICE_8080_TAGS   := $(call tagprefix,hasura_graphql_engine,8080)
