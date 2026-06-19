#!/usr/bin/env sh
set -eu

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-deepseek"
SKIP_KEY_PROMPT="${SKIP_KEY_PROMPT:-0}"

mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

cat > "$INSTALL_DIR/cld" <<'EOF'
#!/usr/bin/env sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-deepseek"
ENV_FILE="$CONFIG_DIR/env"

if ! command -v claude >/dev/null 2>&1; then
  cat >&2 <<'MESSAGE'
Claude Code CLI was not found on PATH.

Install it first:
  npm install -g @anthropic-ai/claude-code
MESSAGE
  exit 1
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  cat >&2 <<'MESSAGE'
DeepSeek API key was not found.

Set it with:
  cld-key
MESSAGE
  exit 1
fi

ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash" \
ANTHROPIC_MODEL="deepseek-v4-pro[1m]" \
exec claude "$@"
EOF

cat > "$INSTALL_DIR/cld-pro" <<'EOF'
#!/usr/bin/env sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-deepseek"
ENV_FILE="$CONFIG_DIR/env"

if ! command -v claude >/dev/null 2>&1; then
  cat >&2 <<'MESSAGE'
Claude Code CLI was not found on PATH.

Install it first:
  npm install -g @anthropic-ai/claude-code
MESSAGE
  exit 1
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  cat >&2 <<'MESSAGE'
DeepSeek API key was not found.

Set it with:
  cld-key
MESSAGE
  exit 1
fi

ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash" \
ANTHROPIC_MODEL="deepseek-v4-pro[1m]" \
exec claude "$@"
EOF

cat > "$INSTALL_DIR/cld-flash" <<'EOF'
#!/usr/bin/env sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-deepseek"
ENV_FILE="$CONFIG_DIR/env"

if ! command -v claude >/dev/null 2>&1; then
  cat >&2 <<'MESSAGE'
Claude Code CLI was not found on PATH.

Install it first:
  npm install -g @anthropic-ai/claude-code
MESSAGE
  exit 1
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  cat >&2 <<'MESSAGE'
DeepSeek API key was not found.

Set it with:
  cld-key
MESSAGE
  exit 1
fi

ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash" \
ANTHROPIC_MODEL="deepseek-v4-flash" \
exec claude "$@"
EOF

cat > "$INSTALL_DIR/cld-key" <<'EOF'
#!/usr/bin/env sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-deepseek"
ENV_FILE="$CONFIG_DIR/env"

printf "DeepSeek API key: "
stty -echo 2>/dev/null || true
IFS= read -r api_key
stty echo 2>/dev/null || true
printf "\n"

if [ -z "$api_key" ]; then
  echo "DeepSeek API key cannot be empty." >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR"
umask 077
escaped_key=$(printf "%s" "$api_key" | sed "s/'/'\\\\''/g")
printf "DEEPSEEK_API_KEY='%s'\n" "$escaped_key" > "$ENV_FILE"
chmod 600 "$ENV_FILE" 2>/dev/null || true

echo "DeepSeek API key saved to $ENV_FILE."
EOF

chmod +x "$INSTALL_DIR/cld" "$INSTALL_DIR/cld-pro" "$INSTALL_DIR/cld-flash" "$INSTALL_DIR/cld-key"
# No claude-deepseek symlink — use cld, cld-pro, or cld-flash instead

if [ "$SKIP_KEY_PROMPT" != "1" ]; then
  "$INSTALL_DIR/cld-key"
fi

echo
echo "ClaudeDeepSeek installed."
echo

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo "$INSTALL_DIR is not on your PATH."
    echo
    echo "Add this line to your shell profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    ;;
esac

echo "Open a new terminal, then run:"
echo "  cld         DeepSeek Pro (main) + Flash (subagents)"
echo "  cld-pro     same, explicit"
echo "  cld-flash   DeepSeek Flash (all)"
echo
echo "You can update your DeepSeek API key later with:"
echo "  cld-key"
