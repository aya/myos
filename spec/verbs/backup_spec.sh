#shellcheck shell=sh
# backup: the volumes of a project archived into a dated directory with a manifest
Describe 'backup'
  setup() { sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log; }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup
  logged() { cat "$sb/docker.log"; }
  dir() { printf '%s' "$sb/backup/tester-app-local/20260905-120000"; }
  perms() { stat -f %Lp "$(dir)/.env" 2>/dev/null || stat -c %a "$(dir)/.env"; }

  It 'archives every volume of the project into a dated directory'
    MOCK_VOLUMES="tester-app-local_data tester-app-local_db"
    When call myos_run_live "$sb" backup app
    The output should include 'backup app volume ok'
    The output should include '[exit 0]'
    The result of function logged should include 'docker volume ls --filter label=com.docker.compose.project=tester-app-local --format {{.Name}}'
    The result of function logged should include 'tar czf /b/tester-app-local_data.tar.gz -C /v .'
    The file "$(dir)/tester-app-local_data.tar.gz" should be exist
    The file "$(dir)/tester-app-local_db.tar.gz" should be exist
  End
  It 'writes a manifest naming the project and the volumes'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" backup app
    The file "$(dir)/manifest.json" should be exist
    The contents of file "$(dir)/manifest.json" should include '"project": "tester-app-local"'
    The contents of file "$(dir)/manifest.json" should include '"name": "tester-app-local_data"'
    The contents of file "$(dir)/manifest.json" should include '"sha256":'
  End
  It 'runs the pre-backup hook of the stack before archiving'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" backup app
    The contents of file "$(dir)/hook.log" should equal "pre-backup tester-app-local $(dir)"
    The result of function logged should include 'tar czf'
  End
  It 'copies the .env of the project, readable by the owner only'
    MOCK_VOLUMES="tester-app-local_data"
    printf 'APP_DB_PASSWORD=x\n' > "$sb/wd/.env"
    When call myos_run_live "$sb" backup app
    The file "$(dir)/.env" should be exist
    The result of function perms should equal 600
  End
  It 'pauses the project around the archive under --pause'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" backup app --pause
    The result of function logged should include 'compose --ansi=auto -f'
    The result of function logged should include '-p tester-app-local pause'
    The result of function logged should include '-p tester-app-local unpause'
  End
  It 'ends with a JSON summary naming the artifact under --json'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" backup app --json
    The output should include '"verb":"backup"'
    The output should include "\"artifacts\":[\"@TMP@/backup/tester-app-local/20260905-120000\"]"
  End
End
