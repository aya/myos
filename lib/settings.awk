# settings.awk: compile .settings files into sh functions.
#
# Input: the files given on the command line. Output: sh text to eval.
# A line is `NAME ?= expr` (default), `NAME := expr` (forced by the stack),
# `NAME += expr` (appended), `export A B...`, a comment or blank. A `\` at the
# end of a line continues it.
#
# An expression is text holding:
#   ${NAME}            the value of NAME (through myos_var: lazy, memoised)
#   ${NAME:-fallback}  with a fallback expression
#   ${space} ${comma} ${dollar}   the characters a call argument can not hold
#   @fn(a,b,...)       a function of lib/fn.sh (fn_<name>, - read as _),
#                      arguments split on commas, nesting allowed
#   !fn(a,b,...)       a function that runs a subprocess (fx_<name>)
#   $$                 a literal $
# The compiler emits straight-line sh: every reference and call is computed
# into a temporary before the value is assembled, so the runtime never
# parses anything.
#
# Emitted for NAME:  set_NAME() { ...; R="..."; }
#                    MYOS_SET_KIND_NAME=default|forced  MYOS_SET_ORIGIN_NAME=file:line
#                    MYOS_SET_ADDS_NAME="set_NAME__a1 ..." (for +=)
#                    MYOS_SET_NAMES=" NAME ..."  MYOS_SET_EXPORT=" A B ..."

function shq(s) { # quote for the inside of a double-quoted sh string
  gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\$/, "\\$", s); gsub(/`/, "\\`", s)
  return s
}
function tmp() { NT++; return "_t_" CUR "_" NT }
function fail(msg) { printf "%s:%d: %s\n", FILE, LINE, msg > "/dev/stderr"; ERR=1 }

# parse an expression from S starting at P, up to a top-level stop char (one
# of STOP) or the end; returns the sh fragment; P is left on the stop char
function parse(STOP,   out, c, name, fb, t, args, n, i, fn, arg, cnt) {
  out = ""
  while (P <= length(S)) {
    c = substr(S, P, 1)
    if (index(STOP, c) > 0 && c != "") return out
    if (c == "$" && substr(S, P+1, 1) == "$") { out = out "\\$"; P += 2; continue }
    if (c == "$" && substr(S, P+1, 1) == "{") {
      P += 2; name = ""
      while (P <= length(S) && substr(S, P, 1) ~ /[A-Za-z0-9_]/) { name = name substr(S, P, 1); P++ }
      if (name == "space") { out = out " " } else if (name == "comma") { out = out "," } else if (name == "dollar") { out = out "\\$" }
      else if (name == "") { fail("empty ${} reference") }
      else {
        t = tmp(); STM = STM "  myos_var " name "; " t "=$R\n"
        if (substr(S, P, 2) == ":-") { P += 2; fb = parse("}"); out = out "${" t ":-" fb "}" }
        else out = out "${" t "}"
      }
      if (substr(S, P, 1) != "}") fail("missing } after ${" name); P++
      continue
    }
    if ((c == "@" || c == "!") && substr(S, P+1, 1) ~ /[A-Za-z]/) {
      fn = ""; P++
      while (P <= length(S) && substr(S, P, 1) ~ /[A-Za-z0-9_-]/) { fn = fn substr(S, P, 1); P++ }
      if (substr(S, P, 1) != "(") { out = out c shq(fn); continue }
      P++; n = 0; args = ""
      while (1) {
        arg = parse(",)"); n++; args = args " \"" arg "\""
        if (substr(S, P, 1) == ",") { P++; continue }
        if (substr(S, P, 1) == ")") { P++; break }
        fail("missing ) in call of " fn); break
      }
      gsub(/-/, "_", fn)
      t = tmp(); STM = STM "  " (c == "@" ? "fn_" : "fx_") fn args "; " t "=$R\n"
      out = out "${" t "}"
      continue
    }
    if (c == "(") { P++; out = out "(" parse(")") ")"; P++; continue }
    out = out shq(c); P++
  }
  return out
}

function flush(   frag, id, i, n) {
  if (CUR == "") return
  NT = 0; STM = ""; S = EXPR; P = 1
  frag = parse("")
  if (OP == "+=") {
    ADDN[CUR]++; id = "set_" CUR "__a" ADDN[CUR]
    ADDS[CUR] = ADDS[CUR] " " id
    printf "%s() {\n%s  R=\"%s\"\n}\n", id, STM, frag
  } else {
    printf "set_%s() {\n%s  R=\"%s\"\n}\n", CUR, STM, frag
    printf "MYOS_SET_KIND_%s=%s\nMYOS_SET_ORIGIN_%s=%s:%d\n", CUR, (OP == ":=" ? "forced" : "default"), CUR, FILE, LINE
    if (!SEEN[CUR]) { SEEN[CUR] = 1; NAMES = NAMES " " CUR }
  }
  CUR = ""
}

function handle(line,   i, name, op, rest, w) {
  if (line ~ /^[ \t]*(#|$)/) return
  if (line ~ /^[ \t]*export[ \t]/) {
    sub(/^[ \t]*export[ \t]+/, "", line); gsub(/[ \t]+/, " ", line); EXPORT = EXPORT " " line; return
  }
  # NAME op expr: the operator is the first of ?= := += = after the name
  name = line; sub(/[ \t]*[?:+]?=.*$/, "", name)
  if (name !~ /^[A-Za-z_][A-Za-z0-9_]*$/) { fail("not a setting: " line); return }
  rest = substr(line, length(name) + 1); sub(/^[ \t]*/, "", rest)
  op = substr(rest, 1, 2)
  if (op == "?=" || op == ":=" || op == "+=") rest = substr(rest, 3)
  else if (substr(rest, 1, 1) == "=") { op = "?="; rest = substr(rest, 2) }
  else { fail("no assignment in: " line); return }
  sub(/^[ \t]*/, "", rest); sub(/[ \t]*$/, "", rest)
  CUR = name; OP = op; EXPR = rest
  flush()
}

FNR == 1 { FILE = FILENAME; PENDING = "" }
{
  LINE = FNR
  line = $0
  if (PENDING != "") { sub(/^[ \t]*/, "", line); line = PENDING line; PENDING = "" }
  if (line ~ /\\$/) { sub(/\\$/, "", line); PENDING = line " "; next }
  handle(line)
}
END {
  if (PENDING != "") handle(PENDING)
  printf "MYOS_SET_NAMES=\"%s \"\nMYOS_SET_EXPORT=\"%s \"\n", NAMES, EXPORT
  for (n in ADDS) printf "MYOS_SET_ADDS_%s=\"%s\"\n", n, ADDS[n]
  if (ERR) exit 1
}
