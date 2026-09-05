// A prototype of the myos core in Go, just large enough to be benchmarked
// fairly against the other engines: stack path, group expansion, compose file
// resolution across every directory of the path, project name, and the
// dry-run compose command. Same rules as lib/stack.sh and lib/naming.sh.
//
// export delegates the shell hooks to ONE sh per stack directory, which is
// what a Go engine would do to keep the developer contract in shell.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

// stackPath: the directories stacks are looked up in, project first
func stackPath(workdir string) []string {
	home := env("HOME", "/nonexistent")
	root := env("MYOS_ROOT", ".")
	prefix := filepath.Dir(filepath.Dir(root))
	var out []string
	seen := map[string]bool{}
	for _, d := range []string{workdir, filepath.Join(workdir, ".."), filepath.Join(home, ".local/share"), filepath.Join(prefix, "share"), "/usr/local/share", "/usr/share"} {
		for _, c := range []string{filepath.Join(d, "stack"), filepath.Join(d, "myos/stack")} {
			if st, err := os.Stat(c); err == nil && st.IsDir() {
				if r, err := filepath.EvalSymlinks(c); err == nil {
					c = r
				}
				if !seen[c] {
					seen[c] = true
					out = append(out, c)
				}
			}
		}
	}
	return out
}

// groupValue: the list a lowercase group name expands to, from <g>.env,
// <g>/<g>.env or <g>/_stack.env along the path
func groupValue(path []string, name string) string {
	if strings.ContainsAny(name, "/:.") || strings.ToLower(name) != name {
		return ""
	}
	if v := os.Getenv(name); v != "" {
		return v
	}
	for _, d := range path {
		for _, f := range []string{filepath.Join(d, name+".env"), filepath.Join(d, name, name+".env"), filepath.Join(d, name, "_stack.env")} {
			b, err := os.ReadFile(f)
			if err != nil {
				continue
			}
			for _, line := range strings.Split(string(b), "\n") {
				if strings.HasPrefix(line, name+"=") {
					return strings.Trim(strings.TrimPrefix(line, name+"="), "\"")
				}
			}
		}
	}
	return ""
}

func expand(path []string, refs []string, depth int) []string {
	var out []string
	for _, r := range refs {
		if v := groupValue(path, r); v != "" && depth < 16 {
			out = append(out, expand(path, strings.Fields(v), depth+1)...)
		} else {
			out = append(out, r)
		}
	}
	return out
}

func stackName(ref string) string {
	r := strings.TrimSuffix(ref, "/")
	if i := strings.LastIndex(r, ":"); i >= 0 {
		r = r[:i]
	}
	return strings.TrimSuffix(filepath.Base(r), ".yml")
}

// stackDirs: every directory of the path holding the stack, least specific first
func stackDirs(path []string, ref string) []string {
	r := strings.TrimSuffix(ref, "/")
	if i := strings.LastIndex(r, ":"); i >= 0 {
		r = r[:i]
	}
	name := stackName(ref)
	var found []string
	for _, d := range path {
		var hit string
		if st, err := os.Stat(filepath.Join(d, r)); err == nil && st.IsDir() {
			hit = filepath.Join(d, r)
		} else if _, err := os.Stat(filepath.Join(d, r+".yml")); err == nil {
			hit = filepath.Dir(filepath.Join(d, r))
		} else if st, err := os.Stat(filepath.Join(d, name)); err == nil && st.IsDir() {
			hit = filepath.Join(d, name)
		}
		if hit != "" {
			found = append([]string{hit}, found...)
		}
	}
	return found
}

func exists(p string) bool { _, err := os.Stat(p); return err == nil }

// composeFiles: the files that exist, in the order the framework loads them
func composeFiles(dir string, names, suffixes []string, envName string) []string {
	var out []string
	for _, e := range []string{"yml", "yaml"} {
		for _, n := range names {
			for _, f := range []string{
				filepath.Join(dir, n+"."+e), filepath.Join(dir, n+"."+envName+"."+e),
				filepath.Join(dir, envName, n+"."+e), filepath.Join(dir, envName, n+"."+envName+"."+e)} {
				if exists(f) {
					out = append(out, f)
				}
			}
			for _, s := range suffixes {
				for _, f := range []string{filepath.Join(dir, n+"."+s+"."+e), filepath.Join(dir, n+"."+s+"."+envName+"."+e)} {
					if exists(f) {
						out = append(out, f)
					}
				}
			}
		}
	}
	return out
}

func scope(ref string) string {
	switch strings.SplitN(ref, "/", 2)[0] {
	case "host":
		return "host"
	case "User", "user":
		return "user"
	case "cluster":
		return "cluster"
	}
	return "app"
}

func projectName(sc, user, envName, app string) string {
	switch sc {
	case "host":
		return env("HOST_COMPOSE_PROJECT_NAME", env("HOSTNAME", "localhost"))
	case "user":
		return user
	case "cluster":
		return strings.ToLower(app)
	}
	n := strings.NewReplacer(".", "", "-", "", "_", "").Replace(strings.ToLower(app))
	if env("MYOS_PROJECT_FORMAT", "user-env-app") == "user-app-env" {
		return user + "-" + n + "-" + envName
	}
	return user + "-" + envName + "-" + n
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: myos-go <noop|up|export> [stack...]")
		os.Exit(2)
	}
	workdir := env("WORKDIR", ".")
	envName := env("ENV", "local")
	user := env("USER", "tester")
	path := stackPath(workdir)
	suffixes := []string{"app", "labels", "networks", "ssh", "volumes", "latest"}

	switch os.Args[1] {
	case "noop":
		return
	case "up":
		refs := expand(path, os.Args[2:], 0)
		byProject := map[string][]string{}
		var order []string
		for _, ref := range refs {
			app := stackName(ref)
			var files []string
			for _, d := range stackDirs(path, ref) {
				files = append(files, composeFiles(d, []string{"docker-compose", app}, suffixes, envName)...)
			}
			p := projectName(scope(ref), user, envName, app)
			if _, ok := byProject[p]; !ok {
				order = append(order, p)
			}
			byProject[p] = append(byProject[p], files...)
		}
		for _, p := range order {
			files := append(byProject[p], filepath.Join(env("MYOS_ROOT", "."), "share/compose/networks.yml"))
			var b strings.Builder
			b.WriteString("docker compose")
			for _, f := range files {
				b.WriteString(" -f " + f)
			}
			fmt.Printf("%s -p %s up -d\n", b.String(), p)
		}
	case "export":
		// one sh per stack directory evaluates its hooks and prints every value
		refs := expand(path, os.Args[2:], 0)
		seen := map[string]bool{}
		var dirs []string
		for _, ref := range refs {
			for _, d := range stackDirs(path, ref) {
				if !seen[d] {
					seen[d] = true
					dirs = append(dirs, d)
				}
			}
		}
		sort.Strings(dirs)
		root := env("MYOS_ROOT", ".")
		for _, d := range dirs {
			script := fmt.Sprintf(`for m in core str var tags naming stack config compose hooks; do . %s/lib/$m.sh; done
[ -f %s/_stack.sh ] || exit 0
myos_stack_hooks %s _
for v in $(sed -n 's/^myos_default_\([A-Za-z_][A-Za-z0-9_]*\)().*/\1/p' %s/_stack.sh | sort -u); do printf '%%s=%%s\n' "$v" "$(myos_var "$v")"; done`, root, d, d, d)
			cmd := exec.Command("sh", "-c", script)
			cmd.Env = os.Environ()
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
		}
	}
}
