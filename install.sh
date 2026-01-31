#!/bin/bash

# cc-kit installer
# Install cc-kit components without cloning the repository
#
# Usage:
#   ./install.sh <component> [options]
#   curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s <component> [options]

set -e

VERSION="1.0.0"
REPO_RAW_URL="https://raw.githubusercontent.com/Gnnng/cc-kit/main"

# ANSI color codes
if [[ -t 1 ]]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_RED='\033[31m'
    C_GREEN='\033[32m'
    C_YELLOW='\033[33m'
    C_BLUE='\033[34m'
    C_CYAN='\033[36m'
else
    C_RESET=''
    C_BOLD=''
    C_RED=''
    C_GREEN=''
    C_YELLOW=''
    C_BLUE=''
    C_CYAN=''
fi

# Print colored messages
info() {
    echo -e "${C_BLUE}==>${C_RESET} ${C_BOLD}$1${C_RESET}"
}

success() {
    echo -e "${C_GREEN}✓${C_RESET} $1"
}

warn() {
    echo -e "${C_YELLOW}⚠${C_RESET} $1"
}

error() {
    echo -e "${C_RED}✗${C_RESET} $1" >&2
}

# Detect if running locally (script exists in repo) or remotely (via curl)
detect_mode() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$script_dir/cc-launcher" ]] && [[ -d "$script_dir/cc-headless" ]]; then
        echo "local"
    else
        echo "remote"
    fi
}

# Get file content (local or remote)
get_file() {
    local path="$1"
    local mode="$2"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ "$mode" == "local" ]]; then
        cat "$script_dir/$path"
    else
        curl -fsSL "$REPO_RAW_URL/$path"
    fi
}

# Check if file exists locally
local_file_exists() {
    local path="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "$script_dir/$path" ]]
}

# Install cc-launcher
install_cc_launcher() {
    local mode="$1"
    local force="$2"
    local dry_run="$3"
    local install_dir="$HOME/.local/bin"
    local install_path="$install_dir/cc-launcher"

    info "Installing cc-launcher..."

    if [[ "$dry_run" == "true" ]]; then
        echo "Would create directory: $install_dir"
        echo "Would install: $install_path"
        echo "Would make executable: $install_path"
        if [[ -f "$install_path" ]]; then
            warn "Note: $install_path already exists (would need --force to overwrite)"
        fi
        return 0
    fi

    # Check if already exists
    if [[ -f "$install_path" ]] && [[ "$force" != "true" ]]; then
        error "File already exists: $install_path"
        echo "  Use --force to overwrite"
        return 1
    fi

    # Create directory if needed
    if [[ ! -d "$install_dir" ]]; then
        mkdir -p "$install_dir"
        success "Created directory: $install_dir"
    fi

    # Download/copy file
    if [[ "$mode" == "local" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cp "$script_dir/cc-launcher" "$install_path"
    else
        curl -fsSL "$REPO_RAW_URL/cc-launcher" -o "$install_path"
    fi
    success "Installed: $install_path"

    # Make executable
    chmod +x "$install_path"
    success "Made executable"

    # Check PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        warn "$install_dir is not in your PATH"
        echo ""
        echo "  Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi

    # Verify installation
    if command -v cc-launcher &>/dev/null || [[ -x "$install_path" ]]; then
        success "Installation complete!"
        echo ""
        echo -e "  Run ${C_CYAN}cc-launcher --help${C_RESET} for usage"
    fi
}

# Install cc-headless
install_cc_headless() {
    local mode="$1"
    local force="$2"
    local dry_run="$3"
    local claude_dir="$HOME/.claude"
    local files_to_install=(
        "cc-headless/.claude.json:$HOME/.claude.json"
        "cc-headless/.claude/settings.json:$claude_dir/settings.json"
        "cc-headless/.claude/statusline.sh:$claude_dir/statusline.sh"
    )

    info "Installing cc-headless configuration..."

    if [[ "$dry_run" == "true" ]]; then
        echo "Would create directory: $claude_dir"
        for file_mapping in "${files_to_install[@]}"; do
            local src="${file_mapping%%:*}"
            local dest="${file_mapping#*:}"
            echo "Would install: $src -> $dest"
            if [[ -f "$dest" ]]; then
                warn "Note: $dest already exists (would need --force to overwrite)"
            fi
        done
        return 0
    fi

    # Check for existing files
    local existing_files=()
    for file_mapping in "${files_to_install[@]}"; do
        local dest="${file_mapping#*:}"
        if [[ -f "$dest" ]]; then
            existing_files+=("$dest")
        fi
    done

    if [[ ${#existing_files[@]} -gt 0 ]] && [[ "$force" != "true" ]]; then
        error "The following files already exist:"
        for f in "${existing_files[@]}"; do
            echo "  - $f"
        done
        echo ""
        echo "  Use --force to overwrite"
        return 1
    fi

    # Create .claude directory if needed
    if [[ ! -d "$claude_dir" ]]; then
        mkdir -p "$claude_dir"
        success "Created directory: $claude_dir"
    fi

    # Install each file
    for file_mapping in "${files_to_install[@]}"; do
        local src="${file_mapping%%:*}"
        local dest="${file_mapping#*:}"

        get_file "$src" "$mode" > "$dest"
        success "Installed: $dest"
    done

    success "Installation complete!"
    echo ""
    echo "  Set your API key:"
    echo ""
    echo "    export ANTHROPIC_API_KEY=\"sk-ant-...\""
    echo ""
    echo -e "  See ${C_CYAN}~/.claude.json${C_RESET} to customize settings"
}

# Show help
show_help() {
    cat << EOF
${C_BOLD}cc-kit installer${C_RESET} v${VERSION}

${C_BOLD}USAGE:${C_RESET}
    ./install.sh <component> [options]
    curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s <component> [options]

${C_BOLD}COMPONENTS:${C_RESET}
    ${C_CYAN}cc-launcher${C_RESET}    Multi-provider launcher for Claude Code
                   Installs to: ~/.local/bin/cc-launcher

    ${C_CYAN}cc-headless${C_RESET}    Configuration for headless/API-only mode
                   Installs to: ~/.claude.json, ~/.claude/

${C_BOLD}OPTIONS:${C_RESET}
    -f, --force    Overwrite existing files
    --dry-run      Show what would be installed without making changes
    -h, --help     Show this help message

${C_BOLD}EXAMPLES:${C_RESET}
    # Install cc-launcher (remote)
    curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-launcher

    # Install cc-headless with force overwrite
    curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-headless -f

    # Local install after cloning
    ./install.sh cc-launcher
    ./install.sh cc-headless --force

    # Preview installation
    ./install.sh cc-launcher --dry-run

EOF
}

# Main
main() {
    local component=""
    local force="false"
    local dry_run="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            -*)
                error "Unknown option: $1"
                echo "Run with --help for usage"
                exit 1
                ;;
            *)
                if [[ -z "$component" ]]; then
                    component="$1"
                else
                    error "Too many arguments"
                    echo "Run with --help for usage"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Show help if no component specified
    if [[ -z "$component" ]]; then
        show_help
        exit 0
    fi

    # Detect execution mode
    local mode
    mode=$(detect_mode)

    if [[ "$dry_run" == "true" ]]; then
        info "Dry run mode - no changes will be made"
        echo "Detected mode: $mode"
        echo ""
    fi

    # Install component
    case "$component" in
        cc-launcher|launcher)
            install_cc_launcher "$mode" "$force" "$dry_run"
            ;;
        cc-headless|headless)
            install_cc_headless "$mode" "$force" "$dry_run"
            ;;
        *)
            error "Unknown component: $component"
            echo ""
            echo "Available components: cc-launcher, cc-headless"
            echo "Run with --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
