#!/bin/bash

# Icons
icon_home="󰋜"
icon_dev="󰲋"
icon_download="󰇚"
icon_config="󰒓"
icon_new="󰝒"
icon_window="󰖯"
icon_session="󰆦"
icon_kill="󰅖"
icon_kill_window="󰅗"

# Get active sessions
active_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

# Path mapping
declare -A paths
paths["Inicio"]="$HOME"
paths["Dev"]="$HOME/Dev"
paths["Descargas"]="$HOME/Descargas"
paths["Config"]="$HOME/.config"

# FZF colors
fzf_colors="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
fzf_colors+=" --color=fg:#cdd6f4,header:#94e2d5,info:#cba6f7,pointer:#f5e0dc"
fzf_colors+=" --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
fzf_colors+=" --color=border:#89b4fa"

# Build list with icons
list=""
list+="$icon_home  Inicio\n"
list+="$icon_dev  Dev\n"
list+="$icon_download  Descargas\n"
list+="$icon_config  Config\n"
list+="──────────────────────\n"
list+="$icon_new  Nueva sesión\n"
list+="$icon_window  Nueva ventana\n"
list+="$icon_kill  Eliminar sesión\n"
list+="$icon_kill_window  Eliminar ventana\n"
list+="──────────────────────\n"

# Add active sessions
for session in $active_sessions; do
    list+="$icon_session  $session\n"
done

# Remove trailing newline
list=${list%\\n}

selected=$(echo -e "$list" | fzf \
    --no-sort \
    --no-info \
    --layout reverse \
    --border rounded \
    --header "  Tmux Sessions" \
    --prompt "   " \
    --pointer "▶" \
    --margin 0 \
    --padding 1 \
    $fzf_colors
)

[[ -z "$selected" ]] && exit 0

# Extract name (remove icon)
name=$(echo "$selected" | sed 's/^[^ ]* *//')

# Handle separators (re-run script if selected)
if [[ "$name" == "─────────────────────" ]] || [[ -z "$name" ]]; then
    exec "$0"
fi

# Handle new session
if [[ "$name" == "Nueva sesión" ]]; then
    tput cnorm
    printf "\033[?25h"
    echo -n "Nombre: "
    read session_name
    [[ -z "$session_name" ]] && exit 0
    tmux new-session -ds "$session_name"
    tmux switch-client -t "$session_name"
    exit 0
fi

# Handle new window
if [[ "$name" == "Nueva ventana" ]]; then
    tput cnorm
    printf "\033[?25h"
    echo -n "Nombre: "
    read window_name
    if [[ -z "$window_name" ]]; then
        tmux new-window
    else
        tmux new-window -n "$window_name"
    fi
    exit 0
fi

# Handle kill session
if [[ "$name" == "Eliminar sesión" ]]; then
    while true; do
        active_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
        kill_list=""
        for session in $active_sessions; do
            kill_list+="$icon_session  $session\n"
        done
        
        to_kill=$(echo -e "$kill_list" | sed '/^$/d' | fzf \
            --no-sort \
            --layout reverse \
            --border rounded \
            --header "  Eliminar Sesión (ESC para salir)" \
            --prompt "   " \
            --pointer "▶" \
            --margin 0 \
            --padding 1 \
            $fzf_colors
        )
        
        [[ -z "$to_kill" ]] && exit 0
        session_to_kill=$(echo "$to_kill" | sed 's/^[^ ]* *//')
        current_session=$(tmux display-message -p '#{session_name}')
        
        # If killing current session, switch to another first
        if [[ "$session_to_kill" == "$current_session" ]]; then
            other_session=$(tmux list-sessions -F "#{session_name}" | grep -v "^${session_to_kill}$" | head -1)
            if [[ -n "$other_session" ]]; then
                tmux switch-client -t "$other_session"
            fi
        fi
        
        tmux kill-session -t "$session_to_kill"
    done
fi

# Handle kill window
if [[ "$name" == "Eliminar ventana" ]]; then
    while true; do
        current_session=$(tmux display-message -p '#{session_name}')
        windows=$(tmux list-windows -t "$current_session" -F "#{window_index}: #{window_name}" 2>/dev/null)
        
        kill_list=""
        while IFS= read -r win; do
            kill_list+="$icon_window  $win\n"
        done <<< "$windows"
        
        to_kill=$(echo -e "$kill_list" | sed '/^$/d' | fzf \
            --no-sort \
            --layout reverse \
            --border rounded \
            --header "  Eliminar Ventana (ESC para salir)" \
            --prompt "   " \
            --pointer "▶" \
            --margin 0 \
            --padding 1 \
            $fzf_colors
        )
        
        [[ -z "$to_kill" ]] && exit 0
        window_index=$(echo "$to_kill" | sed 's/^[^ ]* *//' | cut -d: -f1)
        tmux kill-window -t "$current_session:$window_index"
    done
fi

# Check if it's an active session (listed in active_sessions)
for session in $active_sessions; do
    if [[ "$name" == "$session" ]]; then
        tmux switch-client -t "$session"
        exit 0
    fi
done

path="${paths[$name]}"

[[ -z "$path" ]] && exit 0

# Session name
session=$(echo "$name" | tr . _)

# Create or switch to session
if ! tmux has-session -t="$session" 2>/dev/null; then
    tmux new-session -ds "$session" -c "$path"
fi

tmux switch-client -t "$session"
tmux send-keys -t "$session" "cd '$path'" Enter
