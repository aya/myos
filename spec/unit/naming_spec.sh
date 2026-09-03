#shellcheck shell=sh
Include lib/str.sh
Include lib/core.sh
Include lib/naming.sh

Describe 'lib/naming.sh'
  Describe 'myos_scope'
    Parameters
      "host/fabio"          host
      "host"                host
      "User/User"           user
      "user/ipfs"           user
      "cluster/postgres-ha" cluster
      "postgres"            app
      "drone/drone"         app
      "./"                  app
    End
    It "scopes $1 as $2"
      When call myos_scope "$1"
      The output should equal "$2"
    End
    It 'honours an explicit MYOS_SCOPE'
      MYOS_SCOPE=host
      When call myos_scope postgres
      The output should equal host
    End
  End

  Describe 'myos_resu'
    It 'turns a mail address into a user.domain identity'
      When call myos_resu "aya@github.com"
      The output should equal "aya.github.com"
    End
    It 'folds + and _ into dots, like the make macro'
      When call myos_resu "aya+git@github.com"
      The output should equal "aya.git.github.com"
    End
    It 'falls back to USER without a mail address'
      USER=fallback
      When call myos_resu ""
      The output should equal "fallback"
    End
    It 'exposes the reversed identity and its path'
      When run source spec/unit/naming_resu_helper.sh
      The output should equal "com.github.aya com/github/aya"
    End
  End

  Describe 'myos_project_name'
    Describe 'app scope'
      It 'defaults to user-env-app'
        When call myos_project_name app aya master duniter
        The output should equal "aya-master-duniter"
      End
      It 'keeps user-app-env when asked to'
        MYOS_PROJECT_FORMAT=user-app-env
        When call myos_project_name app aya master duniter
        The output should equal "aya-duniter-master"
      End
      It 'normalizes the app name'
        When call myos_project_name app aya local "My-App.v2"
        The output should equal "aya-local-myappv2"
      End
      It 'appends the app path when there is one'
        When call myos_project_name app aya local app sub/dir
        The output should equal "aya-local-app-subdir"
      End
      It 'rejects an unknown format'
        MYOS_PROJECT_FORMAT=nope
        When run myos_project_name app aya local app
        The status should equal 2
        The stderr should include "unknown MYOS_PROJECT_FORMAT"
      End
    End

    Describe 'other scopes'
      It 'names a host stack after the machine'
        HOSTNAME=sonic
        When call myos_project_name host aya master fabio
        The output should equal "sonic"
      End
      It 'prefers an explicit HOST_COMPOSE_PROJECT_NAME'
        HOST_COMPOSE_PROJECT_NAME=axiomstudio
        When call myos_project_name host aya master fabio
        The output should equal "axiomstudio"
      End
      It 'names a user stack after the user identity'
        MAIL=aya@github.com
        When call myos_project_name user aya master User
        The output should equal "aya-github-com"
      End
      It 'names a cluster stack after the stack itself'
        When call myos_project_name cluster aya master postgres-ha
        The output should equal "postgresha"
      End
      It 'always honours DOCKER_COMPOSE_PROJECT_NAME'
        DOCKER_COMPOSE_PROJECT_NAME=explicit
        When call myos_project_name app aya master duniter
        The output should equal "explicit"
      End
    End
  End

  Describe 'networks'
    It 'prefixes the default network so it is attached first'
      When call myos_network_default "aya-master-duniter"
      The output should equal "_aya-master-duniter"
    End
    It 'derives the private network from user and env'
      When call myos_network_private aya master
      The output should equal "aya-master"
    End
    It 'derives the public network from the hostname'
      When call myos_network_public sonic
      The output should equal "sonic"
    End
  End

  Describe 'myos_service_name'
    It 'replaces underscores with dashes'
      When call myos_service_name "aya_master_app"
      The output should equal "aya-master-app"
    End
  End
End
