#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model display name (fallback to model id if display_name not available)
model=$(echo "$input" | jq -r '.model.display_name // .model.id')

# Extract session ID
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Extract current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
original_dir="$current_dir"  # Store for color generation

# Extract context usage (if available)
# Use used_percentage as source of truth (includes system, tools, MCP, messages)
context_max=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
context_percent=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Autocompact buffer is fixed at 45k tokens
AUTOCOMPACT_BUFFER=45000

# Calculate used tokens from percentage (more accurate than total_input_tokens)
if [ -n "$context_percent" ] && [ -n "$context_max" ]; then
    # Remove decimal, calculate used from percentage
    percent_int=${context_percent%.*}
    context_used=$((context_max * percent_int / 100))
    # Calculate buffer percentage
    buffer_percent=$((AUTOCOMPACT_BUFFER * 100 / context_max))
else
    context_used=""
    buffer_percent=0
fi

# Extract session line changes (if available)
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

# Get git branch and status (use full path for cd command)
cd "$current_dir" 2>/dev/null || exit 1

# Shorten directory path by replacing home directory with ~ (for display only)
if [[ "$current_dir" == "$HOME"* ]]; then
    current_dir="~${current_dir#$HOME}"
fi

# Get current branch name
branch=$(git branch --show-current 2>/dev/null || echo "")

# Git info collection (only if in a git repo with a branch)
if [ -n "$branch" ]; then
    # Check for dirty status
    git_status=$(git status --porcelain 2>/dev/null)
    if [ -n "$git_status" ]; then
        dirty_indicator="*"
    else
        dirty_indicator=""
    fi

    # Get ahead/behind counts
    upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if [ -n "$upstream" ]; then
        ahead=$(git rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "0")
        behind=$(git rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo "0")
    else
        ahead=0
        behind=0
    fi

fi

# Define color codes
BOLD_CYAN='\033[1;36m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
DIM='\033[2m'
RESET='\033[0m'

# Modern palette of 11 vibrant colors using 256-color mode for compatibility
# Prime count for better hash distribution; avoids purple/orange/green/red (used elsewhere)
DIR_COLORS=(
    30    # Teal
    168   # Pink
    33    # Blue
    173   # Coral
    132   # Mauve
    37    # Cyan
    136   # Gold
    25    # Navy
    96    # Plum
    24    # Deep Blue
    133   # Orchid
)

# Generate deterministic background color from path
# Maps path hash to one of 8 curated colors (256-color mode)
path_to_bg_color() {
    local path="$1"
    local hash
    hash=$(printf '%s' "$path" | cksum | cut -d' ' -f1)
    local index=$((hash % ${#DIR_COLORS[@]}))
    printf '\033[48;5;%sm' "${DIR_COLORS[$index]}"
}

# ===== BUILD OUTPUT =====
output=""

# Add context bar first (left side)
bar_width=12
if [ -n "$context_used" ] && [ -n "$context_max" ] && [ -n "$context_percent" ]; then
    percent=${context_percent%.*}  # Remove decimal part
    # Format numbers with k suffix
    if [ "$context_used" -ge 1000 ]; then
        used_fmt="$((context_used / 1000))k"
    else
        used_fmt="$context_used"
    fi
    if [ "$context_max" -ge 1000 ]; then
        max_fmt="$((context_max / 1000))k"
    else
        max_fmt="$context_max"
    fi

    # Build progress bar with overlaid text
    filled=$((percent * bar_width / 100))
    text="${used_fmt}/${max_fmt}"
    text_len=${#text}

    # Pad text to bar width, right-aligned with 1-char gap on right
    text="${text} "  # Add 1-char padding on right
    text_len=${#text}
    pad_left=$(( bar_width - text_len ))
    padded_text=$(printf "%${pad_left}s%s" "" "$text")

    # Background and text colors based on usage level (Purple gradient)
    if [ "$percent" -gt 80 ]; then
        BG_FILLED='\033[48;2;75;0;130m'    # Indigo
        FG_FILLED='\033[97m'               # White text
    elif [ "$percent" -gt 50 ]; then
        BG_FILLED='\033[48;2;138;43;226m'  # Blue violet
        FG_FILLED='\033[97m'               # White text
    else
        BG_FILLED='\033[48;2;147;112;219m' # Medium purple
        FG_FILLED='\033[97m'               # White text
    fi
    # Buffer zone color (darker gray/muted)
    BG_BUFFER='\033[48;2;60;60;70m'   # Dark slate gray for buffer
    FG_BUFFER='\033[37m'              # Light gray text
    # Free space color
    BG_FREE='\033[100m'               # Bright black (gray) background
    FG_FREE='\033[97m'                # White text on gray

    # Calculate positions: used | buffer | free
    # Buffer starts where free space would normally start (100% - buffer%)
    buffer_start=$((bar_width * (100 - buffer_percent) / 100))

    # Build bar character by character
    bar=""
    for ((i=0; i<bar_width; i++)); do
        char="${padded_text:$i:1}"
        if [ $i -lt $filled ]; then
            # Used portion (purple gradient)
            bar="${bar}${BG_FILLED}${FG_FILLED}${char}"
        elif [ $i -ge $buffer_start ]; then
            # Buffer portion (dark gray)
            bar="${bar}${BG_BUFFER}${FG_BUFFER}${char}"
        else
            # Free portion (light gray)
            bar="${bar}${BG_FREE}${FG_FREE}${char}"
        fi
    done
    bar="${bar}${RESET}"
    output="$bar "
fi

# Add model name with color based on model tier
model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
if [[ "$model_lower" == *"opus"* ]]; then
    # Opus: Crail brand color (strongest)
    BG_MODEL='\033[48;2;193;95;60m'
    FG_MODEL='\033[30m\033[1m'  # Black text
elif [[ "$model_lower" == *"sonnet"* ]]; then
    # Sonnet: lighter
    BG_MODEL='\033[48;2;210;130;100m'
    FG_MODEL='\033[30m\033[1m'  # Black text
elif [[ "$model_lower" == *"haiku"* ]]; then
    # Haiku: lightest
    BG_MODEL='\033[48;2;225;170;145m'
    FG_MODEL='\033[30m\033[1m'  # Black text
else
    # Non-Anthropic: dark green
    BG_MODEL='\033[48;2;50;100;70m'
    FG_MODEL='\033[97m\033[1m'  # White text
fi
output="$output${BG_MODEL}${FG_MODEL} $model ${RESET}"

# Add directory with deterministic background color
DIR_BG=$(path_to_bg_color "$original_dir")
DIR_FG='\033[97m'  # White text
output="$output ${DIR_BG}${DIR_FG} $current_dir ${RESET}"

# Add git info
if [ -n "$branch" ]; then
    # Branch with dirty indicator
    if [ -n "$dirty_indicator" ]; then
        output="$output ${GREEN}$branch${RED}$dirty_indicator${RESET}"
    else
        output="$output ${GREEN}$branch${RESET}"
    fi

    # Ahead/behind
    if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        sync_info=""
        [ "$ahead" -gt 0 ] && sync_info="${GREEN}↑${ahead}${RESET}"
        [ "$behind" -gt 0 ] && sync_info="${sync_info}${RED}↓${behind}${RESET}"
        output="$output $sync_info"
    fi

    # Get line changes (insertions/deletions) - quick shortstat
    diff_stat=$(git diff --shortstat 2>/dev/null)
    if [ -n "$diff_stat" ]; then
        insertions=$(echo "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
        deletions=$(echo "$diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
        [ -z "$insertions" ] && insertions=0
        [ -z "$deletions" ] && deletions=0
    else
        insertions=0
        deletions=0
    fi

    # Show git line changes
    if [ "$insertions" -gt 0 ] || [ "$deletions" -gt 0 ]; then
        changes=""
        [ "$insertions" -gt 0 ] && changes="${GREEN}+${insertions}${RESET}"
        [ "$deletions" -gt 0 ] && changes="${changes}${RED}-${deletions}${RESET}"
        output="$output $changes"
    fi
else
    # No git repo - use session line changes from Claude Code
    if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
        changes=""
        [ -n "$lines_added" ] && [ "$lines_added" != "0" ] && changes="${GREEN}+${lines_added}${RESET}"
        [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && changes="${changes}${RED}-${lines_removed}${RESET}"
        [ -n "$changes" ] && output="$output $changes"
    fi
fi

# Add session ID at the end (very dim gray)
if [ -n "$session_id" ]; then
    VERY_DIM='\033[38;2;70;70;70m'  # Dark gray text
    output="$output ${VERY_DIM}${session_id}${RESET}"
fi

echo -e "$output"
