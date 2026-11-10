#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO='BeyondHarnessLab/longway-sandbox-dev'
readonly REF="${LWDEV_REF:-main}"
readonly INSTALL_DIR="${LWDEV_INSTALL_DIR:-$HOME/.local/share/lwdev}"
readonly BIN_DIR="${LWDEV_BIN_DIR:-$HOME/.local/bin}"

fail() { printf 'lwdev install: error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "${1} is required; install it and run this script again"; }

[ -n "${HOME:-}" ] || fail 'HOME is not set'
[ "$(id -u)" -ne 0 ] || fail 'do not run as root; install for your user instead'
need bash
need git
need gh
need node
need pnpm

node -e 'const [major, minor] = process.versions.node.split(".").map(Number); if (major < 24 || (major === 24 && minor < 15)) process.exit(1)' \
  || fail "Node 24.15 or newer is required (found $(node --version))"
case "$(pnpm --version)" in
  12.*) ;;
  *) fail "pnpm 12 is required (found $(pnpm --version))" ;;
esac

gh auth status >/dev/null 2>&1 || fail 'GitHub login is required; run: gh auth login'
gh repo view "$REPO" >/dev/null 2>&1 || fail "your GitHub account cannot read $REPO"

if [ -e "$INSTALL_DIR" ]; then
  [ -d "$INSTALL_DIR/.git" ] || fail "$INSTALL_DIR exists but is not the lwdev checkout"
  remote=$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)
  case "$remote" in
    https://github.com/$REPO.git|https://github.com/$REPO) ;;
    *) fail "$INSTALL_DIR is a different repository" ;;
  esac
  [ -z "$(git -C "$INSTALL_DIR" status --porcelain)" ] || fail "$INSTALL_DIR has local changes; refusing to overwrite them"
  branch=$(git -C "$INSTALL_DIR" symbolic-ref --short -q HEAD || true)
  [ "$branch" = "$REF" ] || fail "$INSTALL_DIR is on $branch, not $REF; refusing to switch it"
  git -C "$INSTALL_DIR" fetch --quiet origin "$REF" || fail "could not fetch $REPO:$REF"
  git -C "$INSTALL_DIR" merge --ff-only --quiet "origin/$REF" || fail "could not fast-forward $INSTALL_DIR"
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  tmp=$(mktemp -d "${INSTALL_DIR}.install.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT
  gh repo clone "$REPO" "$tmp" -- --branch "$REF" --single-branch --depth 1 >/dev/null \
    || fail "could not clone $REPO:$REF"
  mv "$tmp" "$INSTALL_DIR"
  trap - EXIT
fi

pnpm --dir "$INSTALL_DIR" install --frozen-lockfile
mkdir -p "$BIN_DIR"
launcher="$BIN_DIR/lwdev"
if [ -e "$launcher" ] && ! grep -qF '# lwdev launcher' "$launcher"; then
  fail "$launcher exists and is not lwdev's launcher"
fi
escaped=${INSTALL_DIR//\'/\'\\\'\'}
cat > "$launcher" <<EOF
#!/bin/sh
# lwdev launcher
exec node '$escaped/bin/lwdev.mjs' "\$@"
EOF
chmod 755 "$launcher"

printf '\nInstalled lwdev in %s\n' "$INSTALL_DIR"
printf 'Launcher: %s\n' "$launcher"
case ":${PATH:-}:" in *:"$BIN_DIR":*) ;;
  *) printf 'Add %s to PATH, then open a new shell.\n' "$BIN_DIR" ;;
esac
printf '\nNext:\n  lwdev init\n  lwdev doctor\n'
