#!/bin/bash
set -e

CCKIT_INSTALLER="https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh"

# Install packages using the detected package manager.
# NOTE: Package names are assumed to be the same across distros (e.g., "tmux").
# If a package has different names (e.g., libc-dev vs libc6-dev), add a mapping.
install_packages() {
    if type apt-get > /dev/null 2>&1; then
        apt-get update -y && apt-get install -y --no-install-recommends "$@" && rm -rf /var/lib/apt/lists/*
    elif type dnf > /dev/null 2>&1; then
        dnf install -y --refresh "$@"
    elif type yum > /dev/null 2>&1; then
        yum install -y "$@"
    elif type apk > /dev/null 2>&1; then
        apk add --no-cache "$@"
    fi
}

# Install tmux (used by Claude Code for session management)
install_packages tmux

# Resolve the remote (non-root) user
# (needed before writing tmux config and installing Claude Code)
USERNAME="${_REMOTE_USER:-"automatic"}"
if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "$CURRENT_USER" >/dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="root"
    fi
fi

if [ "$USERNAME" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/$USERNAME"
fi

# Write default tmux config for the target user
echo "set -g mouse on" > "$USER_HOME/.tmux.conf"
chown "$USERNAME:$USERNAME" "$USER_HOME/.tmux.conf"

echo "Installing Claude Code for user: $USERNAME"

# Install Claude Code via native binary installer
su - "$USERNAME" -c "curl -fsSL https://claude.ai/install.sh | bash"

# Optional: install cc-headless config (merge on top of Claude Code defaults)
if [ "${HEADLESS}" = "true" ]; then
    su - "$USERNAME" -c "curl -fsSL $CCKIT_INSTALLER | bash -s cc-headless --merge --yolo"
fi

# Optional: install cc-launcher
if [ "${LAUNCHER}" = "true" ]; then
    su - "$USERNAME" -c "curl -fsSL $CCKIT_INSTALLER | bash -s cc-launcher"
fi

# Move ~/.claude and ~/.claude.json into persistent volume, then symlink back
# The volume mount overlays /var/lib/claude at runtime for persistence
mkdir -p /var/lib/claude
if [ -d "$USER_HOME/.claude" ]; then
    cp -a "$USER_HOME/.claude/." /var/lib/claude/
    rm -rf "$USER_HOME/.claude"
fi
if [ -f "$USER_HOME/.claude.json" ]; then
    mv "$USER_HOME/.claude.json" /var/lib/claude/.claude.json
fi
chown -R "$USERNAME:$USERNAME" /var/lib/claude
ln -s /var/lib/claude "$USER_HOME/.claude"
ln -s /var/lib/claude/.claude.json "$USER_HOME/.claude.json"
