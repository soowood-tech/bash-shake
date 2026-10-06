#!/usr/bin/env bash
# ==============================================================================
#  BASH SNAKE - Classic Snake Game written in pure Bash
# ==============================================================================

# Terminal dimensions for the game board
WIDTH=40
HEIGHT=20

# Colors (ANSI escape codes)
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BORDER="\033[38;5;39m"    # Cyan
C_HEAD="\033[38;5;46m"      # Bright green
C_BODY="\033[38;5;34m"      # Forest green
C_FOOD="\033[38;5;196m"     # Bright red
C_SCORE="\033[38;5;220m"    # Gold
C_MSG="\033[38;5;213m"      # Pink
C_DIM="\033[2m"

# Symbols
CHAR_HEAD="◉"
CHAR_BODY="○"
CHAR_FOOD="★"
CHAR_BORDER_H="─"
CHAR_BORDER_V="│"
CHAR_CORNER_TL="┌"
CHAR_CORNER_TR="┐"
CHAR_CORNER_BL="└"
CHAR_CORNER_BR="┘"

# Score file
SCORE_FILE="$HOME/.bash_snake_highscore"
HIGHSCORE=0
if [[ -f "$SCORE_FILE" ]]; then
    HIGHSCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo 0)
fi

# Cleanup and restore terminal on exit
cleanup() {
    tput cnorm      # Show cursor
    stty echo       # Restore echo
    tput rmcup      # Restore screen
    printf "${C_RESET}\n"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Setup terminal
stty -echo
tput smcup          # Use alternate buffer
tput civis          # Hide cursor

# Game state
init_game() {
    score=0
    speed=0.10
    paused=0
    game_over=0

    # Start position: center
    local start_x=$((WIDTH / 2))
    local start_y=$((HEIGHT / 2))

    snake_x=($start_x $((start_x - 1)) $((start_x - 2)))
    snake_y=($start_y $start_y $start_y)
    snake_len=3

    # Initial direction: right
    dir_x=1
    dir_y=0

    spawn_food
    draw_board
}

spawn_food() {
    local valid=0
    while [[ $valid -eq 0 ]]; do
        food_x=$((RANDOM % (WIDTH - 2) + 1))
        food_y=$((RANDOM % (HEIGHT - 2) + 1))
        valid=1
        for ((i=0; i<snake_len; i++)); do
            if [[ ${snake_x[i]} -eq $food_x && ${snake_y[i]} -eq $food_y ]]; then
                valid=0
                break
            fi
        done
    done
}

# Move cursor helper
move_to() {
    tput cup "$2" "$1"
}

draw_board() {
    clear
    # Top border
    move_to 0 0
    printf "${C_BORDER}${CHAR_CORNER_TL}"
    for ((x=1; x<WIDTH-1; x++)); do printf "${CHAR_BORDER_H}"; done
    printf "${CHAR_CORNER_TR}${C_RESET}"

    # Side borders
    for ((y=1; y<HEIGHT-1; y++)); do
        move_to 0 $y
        printf "${C_BORDER}${CHAR_BORDER_V}${C_RESET}"
        move_to $((WIDTH - 1)) $y
        printf "${C_BORDER}${CHAR_BORDER_V}${C_RESET}"
    done

    # Bottom border
    move_to 0 $((HEIGHT - 1))
    printf "${C_BORDER}${CHAR_CORNER_BL}"
    for ((x=1; x<WIDTH-1; x++)); do printf "${CHAR_BORDER_H}"; done
    printf "${CHAR_CORNER_BR}${C_RESET}"

    # Draw stats and controls info
    move_to 0 $HEIGHT
    printf " ${C_SCORE}Score: ${C_BOLD}%d${C_RESET} | ${C_SCORE}Record: ${C_BOLD}%d${C_RESET} | Controls: ${C_DIM}WASD / Arrows / Q: Quit / Space: Pause${C_RESET}\n" "$score" "$HIGHSCORE"
}

render_game() {
    # Render food
    move_to "$food_x" "$food_y"
    printf "${C_FOOD}${CHAR_FOOD}${C_RESET}"

    # Render body
    for ((i=1; i<snake_len; i++)); do
        move_to "${snake_x[i]}" "${snake_y[i]}"
        printf "${C_BODY}${CHAR_BODY}${C_RESET}"
    done

    # Render head
    move_to "${snake_x[0]}" "${snake_y[0]}"
    printf "${C_HEAD}${CHAR_HEAD}${C_RESET}"
}

read_input() {
    local key=""
    # Non-blocking read
    read -rsn1 -t "$speed" key

    if [[ "$key" == $'\e' ]]; then
        # Read the rest of escape sequence if any
        read -rsn2 -t 0.001 extra
        key+="$extra"
    fi

    case "$key" in
        # Up
        [wWцЦ]|$'\e[A')
            if [[ $dir_y -ne 1 ]]; then dir_x=0; dir_y=-1; fi ;;
        # Down
        [sSыЫ]|$'\e[B')
            if [[ $dir_y -ne -1 ]]; then dir_x=0; dir_y=1; fi ;;
        # Left
        [aAфФ]|$'\e[D')
            if [[ $dir_x -ne 1 ]]; then dir_x=-1; dir_y=0; fi ;;
        # Right
        [dDвВ]|$'\e[C')
            if [[ $dir_x -ne -1 ]]; then dir_x=1; dir_y=0; fi ;;
        # Pause
        " "|[pPзЗ])
            paused=$((1 - paused))
            if [[ $paused -eq 1 ]]; then
                move_to $((WIDTH / 2 - 4)) $((HEIGHT / 2))
                printf "${C_MSG}${C_BOLD}[ PAUSED ]${C_RESET}"
            else
                draw_board
            fi
            ;;
        # Quit
        [qQйЙ])
            cleanup ;;
    esac
}

update_state() {
    if [[ $paused -eq 1 ]]; then
        return
    fi

    # Calculate new head
    local new_x=$((snake_x[0] + dir_x))
    local new_y=$((snake_y[0] + dir_y))

    # Check wall collision
    if [[ $new_x -le 0 || $new_x -ge $((WIDTH - 1)) || $new_y -le 0 || $new_y -ge $((HEIGHT - 1)) ]]; then
        game_over=1
        return
    fi

    # Check self collision
    for ((i=0; i<snake_len; i++)); do
        if [[ ${snake_x[i]} -eq $new_x && ${snake_y[i]} -eq $new_y ]]; then
            game_over=1
            return
        fi
    done

    # Check food eaten
    if [[ $new_x -eq $food_x && $new_y -eq $food_y ]]; then
        score=$((score + 10))
        snake_len=$((snake_len + 1))
        # Increase speed slightly every 50 points
        if (( score % 50 == 0 )) && (( $(echo "$speed > 0.04" | bc -l 2>/dev/null || echo 0) )); then
            speed=$(awk "BEGIN {print $speed - 0.008}")
        fi
        spawn_food
    else
        # Clear tail on screen
        local tail_x=${snake_x[snake_len-1]}
        local tail_y=${snake_y[snake_len-1]}
        move_to "$tail_x" "$tail_y"
        printf " "
    fi

    # Shift snake body
    for ((i=snake_len-1; i>0; i--)); do
        snake_x[i]=${snake_x[i-1]}
        snake_y[i]=${snake_y[i-1]}
    done

    snake_x[0]=$new_x
    snake_y[0]=$new_y

    # Update score label
    move_to 8 $HEIGHT
    printf "${C_SCORE}${C_BOLD}%d${C_RESET}" "$score"
}

# Main loop
main() {
    # Check minimum terminal size
    local cols=$(tput cols)
    local lines=$(tput lines)
    if [[ $cols -lt $WIDTH || $lines -lt $((HEIGHT + 2)) ]]; then
        echo "Terminal too small! Please resize to at least ${WIDTH}x$((HEIGHT + 2))."
        exit 1
    fi

    while true; do
        init_game
        while [[ $game_over -eq 0 ]]; do
            render_game
            read_input
            update_state
        done

        # Handle highscore
        if [[ $score -gt $HIGHSCORE ]]; then
            HIGHSCORE=$score
            echo "$HIGHSCORE" > "$SCORE_FILE"
        fi

        # Game Over Screen
        move_to $((WIDTH / 2 - 6)) $((HEIGHT / 2 - 1))
        printf "${C_FOOD}${C_BOLD}╔════════════╗${C_RESET}"
        move_to $((WIDTH / 2 - 6)) $((HEIGHT / 2))
        printf "${C_FOOD}${C_BOLD}║ GAME OVER! ║${C_RESET}"
        move_to $((WIDTH / 2 - 6)) $((HEIGHT / 2 + 1))
        printf "${C_FOOD}${C_BOLD}╚════════════╝${C_RESET}"

        move_to $((WIDTH / 2 - 11)) $((HEIGHT / 2 + 3))
        printf "${C_SCORE}Press [R] to Restart, [Q] to Quit${C_RESET}"

        while true; do
            read -rsn1 key
            case "$key" in
                [rRкК]) break ;;
                [qQйЙ]) cleanup ;;
            esac
        done
    done
}

main
