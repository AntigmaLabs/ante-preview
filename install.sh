#!/usr/bin/env bash
set -euo pipefail

# Installer for Ante preview releases.
#
# Today the release repo is private, so downloads require authentication.
# This script supports:
#   - GitHub CLI: `gh` (uses your existing gh auth context)
#   - Token:      `ANTE_TOKEN`, `GITHUB_TOKEN`, or `GH_TOKEN`
#
# When the repo becomes public, the same script continues to work without auth.

usage() {
  cat <<'EOF'
Usage:
  scripts/install.sh [tag]

Examples:
  scripts/install.sh             # install latest
  scripts/install.sh v0.1.3      # install specific tag
  scripts/install.sh 0.1.3       # same (auto-prefixes "v")

Environment overrides:
  ANTE_REPO        GitHub repo in owner/name form (default: AntigmaLabs/ante-preview)
  ANTE_INSTALL_DIR Install directory (default: /usr/local/bin if writable, else ~/.local/bin)
  ANTE_TOKEN       GitHub token (fallbacks: GITHUB_TOKEN, GH_TOKEN)
  ANTE_NO_GH       If set, skip using gh even if installed

Notes:
  - If the repo is private and you don't have `gh` auth, set ANTE_TOKEN (or GITHUB_TOKEN).
  - Ensure the token has access to the repo (e.g. fine-grained token with read access).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

repo="${ANTE_REPO:-AntigmaLabs/ante-preview}"
owner="${repo%%/*}"
name="${repo#*/}"

want_tag="${1:-latest}"
if [[ "$want_tag" != "latest" && "$want_tag" != v* ]]; then
  want_tag="v${want_tag}"
fi

os="$(uname -s)"
arch="$(uname -m)"

platform=""
case "$os" in
  Darwin)
    case "$arch" in
      arm64) platform="darwin-arm64" ;;
      *) ;;
    esac
    ;;
  Linux)
    case "$arch" in
      x86_64 | amd64) platform="linux-x86_64-musl" ;;
      *) ;;
    esac
    ;;
esac

if [[ -z "$platform" ]]; then
  echo "ERROR: unsupported platform: os=$os arch=$arch" >&2
  echo "Supported: darwin/arm64, linux/x86_64" >&2
  exit 1
fi

default_install_dir="/usr/local/bin"
if [[ -n "${ANTE_INSTALL_DIR:-}" ]]; then
  install_dir="$ANTE_INSTALL_DIR"
elif [[ -d "$default_install_dir" && -w "$default_install_dir" ]]; then
  install_dir="$default_install_dir"
else
  install_dir="${HOME}/.local/bin"
fi

token="${ANTE_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: missing required command: $1" >&2
    exit 1
  fi
}

need_cmd tar
need_cmd uname

download_with_gh() {
  [[ -n "${ANTE_NO_GH:-}" ]] && return 1
  command -v gh >/dev/null 2>&1 || return 1

  local tag="$want_tag"
  if [[ "$tag" == "latest" ]]; then
    tag="$(gh release view --repo "$repo" --json tagName --jq '.tagName')"
  fi

  local asset="ante-${tag}-${platform}.tar.gz"
  gh release download "$tag" --repo "$repo" --pattern "$asset" --dir "$tmp" >/dev/null
  printf '%s\n' "$tmp/$asset"
}

download_with_api() {
  need_cmd curl
  need_cmd python3

  local api="https://api.github.com/repos/${owner}/${name}"
  local headers=(
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
  )
  if [[ -n "$token" ]]; then
    headers+=(-H "Authorization: Bearer ${token}")
  fi

  local release_url
  if [[ "$want_tag" == "latest" ]]; then
    release_url="${api}/releases/latest"
  else
    release_url="${api}/releases/tags/${want_tag}"
  fi

  local meta
  meta="$(curl -fsSL "${headers[@]}" "$release_url")"

  local tag asset_name asset_id asset_url
  IFS=$'\t' read -r tag asset_name asset_id asset_url < <(
    python3 - "$platform" <<'PY'
import json, sys

platform = sys.argv[1]
data = json.load(sys.stdin)
tag = data.get("tag_name") or ""

assets = data.get("assets") or []
chosen = None
for a in assets:
    name = a.get("name") or ""
    if name.endswith(f"-{platform}.tar.gz") and name.startswith("ante-"):
        chosen = a
        break

if not chosen:
    sys.stderr.write(f"ERROR: no release asset found for platform={platform}\n")
    sys.exit(2)

print("\t".join([
    tag,
    chosen.get("name") or "",
    str(chosen.get("id") or ""),
    chosen.get("browser_download_url") or "",
]))
PY
  <<<"$meta"
  )

  if [[ -z "$tag" || -z "$asset_name" ]]; then
    echo "ERROR: failed to resolve release metadata" >&2
    exit 1
  fi

  local out="$tmp/$asset_name"
  if [[ -n "$token" && -n "$asset_id" ]]; then
    # Private-safe path: authenticated download through the assets API.
    curl -fL \
      -H "Authorization: Bearer ${token}" \
      -H "Accept: application/octet-stream" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api}/releases/assets/${asset_id}" \
      -o "$out" >/dev/null
  else
    # Public path: direct download URL.
    if [[ -z "$asset_url" ]]; then
      echo "ERROR: missing browser_download_url (need a token for private repos)" >&2
      exit 1
    fi
    curl -fL "$asset_url" -o "$out" >/dev/null
  fi

  printf '%s\n' "$out"
}

tarball=""
if tarball="$(download_with_gh 2>/dev/null)"; then
  :
else
  tarball="$(download_with_api)"
fi

tar -xzf "$tarball" -C "$tmp"
if [[ ! -f "$tmp/ante" ]]; then
  echo "ERROR: unexpected tarball contents (missing 'ante' binary)" >&2
  exit 1
fi
chmod +x "$tmp/ante"

mkdir_cmd=(mkdir -p "$install_dir")
install_cmd=(install -m 0755 "$tmp/ante" "$install_dir/ante")

if [[ -w "$install_dir" || (! -e "$install_dir" && -w "$(dirname "$install_dir")") ]]; then
  "${mkdir_cmd[@]}"
  "${install_cmd[@]}"
else
  if command -v sudo >/dev/null 2>&1; then
    sudo "${mkdir_cmd[@]}"
    sudo "${install_cmd[@]}"
  else
    echo "ERROR: cannot write to $install_dir (no sudo available)" >&2
    exit 1
  fi
fi

echo "Installed ante to ${install_dir}/ante"
echo "Verify: ante --help"
