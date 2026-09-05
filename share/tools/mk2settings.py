#!/usr/bin/env python3
"""mk2settings: convert the .mk of a stack (what the make engine read) into
the .settings and .env files of the new engine.

  mk2settings.py stack/host/fabio.mk ...   writes fabio.settings (+ fabio.env for groups)

Assignments become settings lines with the make expressions translated:
$(X) -> ${X}, $(call f,a,b) -> @f(a,b), builtins -> @name(...), $(shell) ->
!shell(...), $(call JWT,...) -> !jwt(...). ENV_VARS += names -> export names.
A lowercase assignment (a stack group) goes to the .env file. Targets and
recipes are not converted: they are listed in a comment, to be rewritten as
hooks (justfile or actions/<verb>)."""
import re, sys, os

BUILTINS = {"patsubst","subst","if","or","and","firstword","lastword","filter","filter-out",
            "strip","dir","notdir","addprefix","addsuffix","wordlist","words","sort"}
SPECIAL = {"space":"${space}", "comma":"${comma}", "dollar":"${dollar}", "empty":""}
notes = []

def split_args(s):
    """split on top-level commas (parentheses balanced)"""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(": depth += 1
        elif ch == ")": depth -= 1
        if ch == "," and depth == 0:
            out.append(cur); cur = ""
        else:
            cur += ch
    out.append(cur)
    return out

def find_close(s, i):
    """index of the ) matching the ( at s[i]"""
    depth = 0
    for j in range(i, len(s)):
        if s[j] == "(": depth += 1
        elif s[j] == ")":
            depth -= 1
            if depth == 0: return j
    raise ValueError("unbalanced parentheses in: " + s)

def translate(s):
    # the directory of the .mk itself: the engine gives the stack directory
    s = s.replace("$(dir $(lastword $(MAKEFILE_LIST)))", "${MYOS_STACK_DIR}/")
    out = ""; i = 0
    while i < len(s):
        ch = s[i]
        if ch == "$" and i + 1 < len(s):
            n = s[i+1]
            if n == "$":
                out += "$$"; i += 2; continue
            if n == "(" or n == "{":
                close = find_close(s, i+1) if n == "(" else s.index("}", i)
                inner = s[i+2:close]; i = close + 1
                out += translate_ref(inner); continue
        out += ch; i += 1
    return out

def translate_ref(inner):
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_.-]*)$", inner)
    if m:
        name = m.group(1)
        if name in SPECIAL: return SPECIAL[name]
        return "${" + name + "}"
    m = re.match(r"^([a-z-]+)\s(.*)$", inner, re.S)
    if not m:
        notes.append("unknown reference kept as text: $(" + inner + ")")
        return "$(" + inner + ")"
    fn, rest = m.group(1), m.group(2)
    if fn == "call":
        args = split_args(rest)
        name, args = args[0].strip(), args[1:]
        if name == "JWT":
            return "!jwt(" + ",".join(translate(a) for a in args) + ")"
        if name in ("make", "docker-compose-exec-sh", "docker-build", "docker-run"):
            notes.append("recipe macro in a value, kept as text: $(call " + rest + ")")
            return "$(call " + rest + ")"
        return "@" + name + "(" + ",".join(translate(a) for a in args) + ")"
    if fn == "shell":
        return "!shell(" + translate(rest) + ")"
    if fn == "foreach":
        var, lst, body = split_args(rest)[:3]
        var = var.strip()
        body = translate(body).replace("${" + var + "}", "%")
        return "@patsubst(%," + body + "," + translate(lst) + ")"
    if fn in BUILTINS:
        return "@" + fn + "(" + ",".join(translate(a) for a in split_args(rest)) + ")"
    notes.append("unknown function kept as text: $(" + inner + ")")
    return "$(" + inner + ")"

def convert(path):
    global notes
    notes = []
    lines = open(path).read().split("\n")
    # join continuations
    logical, pend = [], None
    for ln in lines:
        if pend is not None:
            ln = pend + " " + ln.strip(); pend = None
        if ln.endswith("\\"):
            pend = ln[:-1].rstrip(); continue
        logical.append(ln)
    if pend is not None: logical.append(pend)
    settings, envs, targets, seen = [], [], [], {}
    in_recipe = False; cond = 0
    for ln in logical:
        if ln.startswith("\t"):
            in_recipe = True; continue
        in_recipe = False
        if not ln.strip():
            settings.append(""); continue
        if ln.lstrip().startswith("#"):
            settings.append(ln.strip()); continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_.-]*)\s*([?:+]?=)\s*(.*)$", ln)
        if m and cond:
            settings.append("# (in a conditional) " + " ".join(ln.split())); continue
        if m:
            name, op, expr = m.groups()
            if name == "MAKECMDARGS" or name == "CONTEXT" or name.endswith("_MAKECMDARGS"):
                continue
            if name == "ENV_VARS":
                settings.append("export " + " ".join(expr.split())); continue
            if not re.match(r"^[A-Z][A-Z0-9_]*$", name):
                # a group: lowercase, or a name with . or - (not a setting)
                if re.match(r"^[A-Za-z][a-z0-9_-]*$", name) and not re.search(r"\$", expr):
                    envs.append(name + "=" + " ".join(expr.split()))
                else:
                    notes.append("dropped: " + ln.strip())
                continue
            value = translate(expr)
            if name in seen and op == ":=" and "${" + name + "}" in value:
                # a redefinition from the previous value: keep the previous one under another name
                prev = name + "__prev"
                settings[seen[name]] = settings[seen[name]].replace(name, prev, 1)
                value = value.replace("${" + name + "}", "${" + prev + "}")
            elif name in seen:
                notes.append("redefined: " + name)
            if op == "+=": op_out = "+="
            elif op == ":=": op_out = "?=" if "!shell" in value and "__prev" not in value else ":="
            else: op_out = "?="
            seen[name] = len(settings)
            settings.append("%-40s %s %s" % (name, op_out, value) if value else "%-40s %s" % (name, op_out))
            continue
        if re.match(r"^(ifeq|ifneq|ifdef|ifndef)\b", ln):
            cond += 1; notes.append("conditional block to rewrite by hand: " + ln.strip()); continue
        if re.match(r"^else\b", ln) and cond: continue
        if re.match(r"^endif\b", ln) and cond:
            cond -= 1; continue
        if re.match(r"^\.PHONY", ln) or re.match(r"^(include|-include|define|endef)\b", ln):
            continue
        m = re.match(r"^([^\s:=]+(?:\s+[^\s:=]+)*)\s*:(?!=)", ln)
        if m:
            targets.append(m.group(1)); continue
        notes.append("not converted: " + ln.strip())
    out = settings
    d, base = os.path.split(path[:-3])
    parent = os.path.basename(d)
    if base == parent or not d.endswith("/stack") and base == parent:
        target, mode = os.path.join(d, "_stack"), "a"      # the settings of the directory (User.mk, drone.mk, host.mk)
    elif os.path.isdir(os.path.join(d, base)):
        target, mode = os.path.join(d, base, "_stack"), "a" # exporter.mk -> exporter/_stack.settings
    elif os.path.exists(os.path.join(d, base + ".yml")):
        target, mode = os.path.join(d, base), "w"           # fabio.mk -> fabio.settings
    elif "." in base and os.path.exists(os.path.join(d, base.replace(".", "/") + ".yml")):
        target, mode = os.path.join(d, base.replace(".", "/")), "w"  # apache.php5.mk -> apache/php5.settings
    else:
        target, mode = os.path.join(d, "_stack"), "a"       # oss.mk, woodpecker.mk, logs.mk
    if d.endswith("/stack") and base != "_stack":
        target, mode = os.path.join(d, "_stack"), "a"       # stack/default.mk -> stack/_stack.settings
    base = target
    if targets or notes:
        out = ["# converted from " + os.path.basename(path)] + out
        if targets:
            out += ["", "# targets of the .mk, to rewrite as hooks: " + " ".join(sorted(set(targets)))]
        for n in notes:
            out += ["# note: " + n]
    text = "\n".join(out).rstrip("\n") + "\n"
    if any(l and not l.startswith("#") for l in out):
        open(base + ".settings", mode).write(("\n" if mode == "a" and os.path.exists(base + ".settings") else "") + text)
    if envs:
        open(base + ".env", "a").write("\n".join(envs) + "\n")
    return len(settings), len(envs), len(targets), len(notes)

if __name__ == "__main__":
    for p in sys.argv[1:]:
        s, e, t, n = convert(p)
        print("%s: %d settings, %d groups, %d targets dropped, %d notes" % (p, s, e, t, n))
