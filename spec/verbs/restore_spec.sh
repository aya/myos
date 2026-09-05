#shellcheck shell=sh
# restore: the volumes of a project replaced from a backup, with guards
Describe 'restore'
  setup() {
    sb=$(myos_sandbox lifecycle); export MYOS_DOCKER_LOG=$sb/docker.log
    bk=$sb/backup/tester-app-local/20260905-110000; mkdir -p "$bk"
    printf 'x' > "$bk/tester-app-local_data.tar.gz"
    printf '{"project": "tester-app-local", "volumes": [{"name": "tester-app-local_data"}]}\n' > "$bk/manifest.json"
  }
  cleanup() { rm -rf "$sb"; }
  BeforeEach setup
  AfterEach cleanup
  logged() { cat "$sb/docker.log"; }

  It 'needs --from'
    When call myos_run_live "$sb" restore app --yes
    The output should include 'restore needs --from'
    The output should include '[exit 2]'
  End
  It 'refuses a backup of another project'
    printf '{"project": "other", "volumes": []}\n' > "$bk/manifest.json"
    When call myos_run_live "$sb" restore app --from latest --yes
    The output should include 'backup of project other, not tester-app-local'
    The output should include '[exit 1]'
  End
  It 'needs --yes when not interactive'
    When call myos_run_live "$sb" restore app --from latest
    The output should include '--yes'
    The output should include '[exit 2]'
  End
  It 'takes a safety backup, stops, restores every volume, starts again'
    MOCK_VOLUMES="tester-app-local_data"
    When call myos_run_live "$sb" restore app --from latest --yes
    The output should include '[exit 0]'
    The result of function logged should include 'tar czf /b/tester-app-local_data.tar.gz'
    The result of function logged should include '-p tester-app-local down'
    The result of function logged should include 'tar xzf /b/tester-app-local_data.tar.gz -C /v'
    The result of function logged should include '-p tester-app-local up -d'
    The contents of file "$sb/wd/hook.log" should equal 'post-restore tester-app-local'
  End
  It 'creates a volume the project no longer has'
    MOCK_VOLUMES=""
    When call myos_run_live "$sb" restore app --from latest --yes --no-backup
    The result of function logged should include 'docker volume create tester-app-local_data'
    The result of function logged should not include 'tar czf'
  End
End
