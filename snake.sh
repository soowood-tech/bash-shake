#!/usr/bin/env bash
# ==============================================================================
#  BASH SNAKE - Classic Snake Game with 2:1 Aspect Ratio & AI Auto-Play
# ==============================================================================

# ANSI Color Palette
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"

C_BORDER="\033[38;5;75m"      # Soft Sky Blue
C_TITLE="\033[38;5;153m"     # Light Blue
C_HEAD="\033[38;5;118m"      # Vibrant Lime Green
C_BODY="\033[38;5;40m"       # Solid Green
C_FOOD="\033[38;5;196m"      # Bright Apple Red
C_SCORE="\033[38;5;221m"     # Warm Gold
C_BOT_ON="\033[38;5;208m"    # Orange (AI Active)
C_BOT_OFF="\033[38;5;244m"   # Dim Gray
C_MSG="\033[38;5;213m"       # Soft Magenta

# Visual elements (Each grid cell is exactly 2 characters wide for 1:1 square ratio)
CELL_HEAD="██"
CELL_BODY="██"
CELL_FOOD="██"
CELL_EMPTY="  "

# Border parts
CHAR_H="═"
CHAR_V="║"
CHAR_TL="╔"
CHAR_TR="╗"
CHAR_BL="╚"
CHAR_BR="╝"

# Score storage
SCORE_FILE="$HOME/.bash_snake_highscore"
HIGHSCORE=0
if [[ -f "$SCORE_FILE" ]]; then
    HIGHSCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo 0)
fi

cleanup() {
    tput cnorm 2>/dev/null
    stty echo 2>/dev/null
    tput rmcup 2>/dev/null
    printf "${C_RESET}\n"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Calculate grid dimensions to fit perfectly
calc_dimensions() {
    local term_cols term_lines
    term_cols=$(tput cols 2>/dev/null || echo 80)
    term_lines=$(tput lines 2>/dev/null || echo 24)

    if (( term_cols < 30 || term_lines < 10 )); then
        echo "Terminal too small ($term_cols x $term_lines)! Please resize to at least 30x10."
        exit 1
    fi

    # Number of logical grid cells
    # Each cell is 2 chars wide on screen
    # E.g., GRID_W = 22 -> 44 screen columns (+ 2 for borders = 46)
    if (( term_cols >= 52 )); then
        GRID_W=24
    else
        GRID_W=$(( (term_cols - 4) / 2 ))
    fi

    # Vertical grid cells
    if (( term_lines > 20 )); then
        GRID_H=16
    else
        GRID_H=$(( term_lines - 4 ))
    fi

    SCREEN_WIDTH=$(( GRID_W * 2 + 2 ))
    SCREEN_HEIGHT=$(( GRID_H + 2 ))

    # Centering offsets
    OFFSET_X=$(( (term_cols - SCREEN_WIDTH) / 2 ))
    if (( OFFSET_X < 0 )); then OFFSET_X=0; fi
    OFFSET_Y=1
}

# Screen coordinates cursor move
move_cursor() {
    local scr_x=$(( $1 + OFFSET_X ))
    local scr_y=$(( $2 + OFFSET_Y ))
    tput cup "$scr_y" "$scr_x"
}

# Move to a logical grid cell (gx, gy)
move_grid() {
    local gx=$1
    local gy=$2
    # +1 for left border, each cell is 2 chars wide
    local scr_x=$(( gx * 2 + 1 ))
    # +1 for top border
    local scr_y=$(( gy + 1 ))
    move_cursor "$scr_x" "$scr_y"
}

draw_board() {
    clear

    # Top border with title
    move_cursor 0 0
    printf "${C_BORDER}${CHAR_TL}"
    local title=" 🐍 BASH SNAKE "
    local title_len=${#title}
    local border_inner=$(( SCREEN_WIDTH - 2 ))
    local side_len=$(( (border_inner - title_len) / 2 ))

    for ((x=0; x<side_len; x++)); do printf "${CHAR_H}"; done
    printf "${C_TITLE}${C_BOLD}%s${C_BORDER}" "$title"
    for ((x=0; x<border_inner - side_len - title_len; x++)); do printf "${CHAR_H}"; done
    printf "${CHAR_TR}${C_RESET}"

    # Side borders
    for ((y=1; y<=GRID_H; y++)); do
        move_cursor 0 $y
        printf "${C_BORDER}${CHAR_V}${C_RESET}"
        move_cursor $(( SCREEN_WIDTH - 1 )) $y
        printf "${C_BORDER}${CHAR_V}${C_RESET}"
    done

    # Bottom border
    move_cursor 0 $(( SCREEN_HEIGHT - 1 ))
    printf "${C_BORDER}${CHAR_BL}"
    for ((x=0; x<border_inner; x++)); do printf "${CHAR_H}"; done
    printf "${CHAR_BR}${C_RESET}"

    draw_ui
}

draw_ui() {
    # Status line
    move_cursor 0 $(( SCREEN_HEIGHT ))
    local mode_str="${C_BOT_OFF}[AUTO: OFF]${C_RESET}"
    if [[ $auto_mode -eq 1 ]]; then
        mode_str="${C_BOT_ON}${C_BOLD}[AUTO: ON]${C_RESET}"
    fi

    printf " ${C_SCORE}Score: ${C_BOLD}%-4d${C_RESET} │ ${C_SCORE}Record: ${C_BOLD}%-4d${C_RESET} │ %b" "$score" "$HIGHSCORE" "$mode_str"

    # Help footer
    move_cursor 0 $(( SCREEN_HEIGHT + 1 ))
    printf " ${C_DIM}WASD/Arrows | TAB: Auto | +/-: Speed | P: Pause | Q: Quit${C_RESET}"
}

spawn_food() {
    local valid=0
    while [[ $valid -eq 0 ]]; do
        food_x=$((RANDOM % GRID_W))
        food_y=$((RANDOM % GRID_H))
        valid=1
        for ((i=0; i<snake_len; i++)); do
            if [[ ${snake_x[i]} -eq $food_x && ${snake_y[i]} -eq $food_y ]]; then
                valid=0
                break
            fi
        done
    done
}

render_game() {
    # Render food
    move_grid "$food_x" "$food_y"
    printf "${C_FOOD}${CELL_FOOD}${C_RESET}"

    # Render body
    for ((i=1; i<snake_len; i++)); do
        move_grid "${snake_x[i]}" "${snake_y[i]}"
        printf "${C_BODY}${CELL_BODY}${C_RESET}"
    done

    # Render head
    move_grid "${snake_x[0]}" "${snake_y[0]}"
    printf "${C_HEAD}${CELL_HEAD}${C_RESET}"
}

# Smart pathfinding for Auto-Play mode
ai_choose_direction() {
    local head_x=${snake_x[0]}
    local head_y=${snake_y[0]}

    local dirs_dx=(0 0 -1 1)
    local dirs_dy=(-1 1 0 0)
    local best_dx=$dir_x
    local best_dy=$dir_y
    local best_dist=99999
    local found_safe=0

    for d in 0 1 2 3; do
        local test_dx=${dirs_dx[d]}
        local test_dy=${dirs_dy[d]}

        # Disallow reversing
        if [[ $test_dx -eq $(( -dir_x )) && $test_dy -eq $(( -dir_y )) && $snake_len -gt 1 ]]; then
            continue
        fi

        local nx=$((head_x + test_dx))
        local ny=$((head_y + test_dy))

        # Check bounds
        if [[ $nx -lt 0 || $nx -ge GRID_W || $ny -lt 0 || $ny -ge GRID_H ]]; then
            continue
        fi

        # Check snake body
        local hits=0
        for ((i=0; i<snake_len-1; i++)); do
            if [[ ${snake_x[i]} -eq $nx && ${snake_y[i]} -eq $ny ]]; then
                hits=1
                break
            fi
        done
        if [[ $hits -eq 1 ]]; then
            continue
        fi

        # 1-step lookahead for space
        local open_neighbors=0
        for ld in 0 1 2 3; do
            local lnx=$((nx + dirs_dx[ld]))
            local lny=$((ny + dirs_dy[ld]))
            if [[ $lnx -ge 0 && $lnx -lt GRID_W && $lny -ge 0 && $lny -lt GRID_H ]]; then
                local lhits=0
                for ((i=0; i<snake_len-2; i++)); do
                    if [[ ${snake_x[i]} -eq $lnx && ${snake_y[i]} -eq $lny ]]; then
                        lhits=1
                        break
                    fi
                done
                if [[ $lhits -eq 0 ]]; then
                    open_neighbors=$((open_neighbors + 1))
                fi
            fi
        done

        # Manhattan distance
        local dist_x=$((nx - food_x))
        if (( dist_x < 0 )); then dist_x=$(( -dist_x )); fi
        local dist_y=$((ny - food_y))
        if (( dist_y < 0 )); then dist_y=$(( -dist_y )); fi
        local dist=$((dist_x + dist_y))

        # Avoid dead ends
        if [[ $open_neighbors -eq 0 && $snake_len -gt 3 ]]; then
            dist=$((dist + 200))
        fi

        if [[ $dist -lt $best_dist ]]; then
            best_dist=$dist
            best_dx=$test_dx
            best_dy=$test_dy
            found_safe=1
        fi
    done

    if [[ $found_safe -eq 1 ]]; then
        dir_x=$best_dx
        dir_y=$best_dy
    fi
}

read_input() {
    local key=""
    local extra=""

    IFS= read -rsn1 -t "$speed" key

    if [[ "$key" == $'\e' ]]; then
        IFS= read -rsn2 -t 0.05 extra
        key+="$extra"
    fi

    case "$key" in
        # Up
        [wWцЦ]|$'\e[A'|$'\eOA')
            auto_mode=0
            if [[ $dir_y -ne 1 ]]; then dir_x=0; dir_y=-1; started=1; fi
            draw_ui ;;
        # Down
        [sSыЫ]|$'\e[B'|$'\eOB')
            auto_mode=0
            if [[ $dir_y -ne -1 ]]; then dir_x=0; dir_y=1; started=1; fi
            draw_ui ;;
        # Left
        [aAфФ]|$'\e[D'|$'\eOD')
            auto_mode=0
            if [[ $dir_x -ne 1 ]]; then dir_x=-1; dir_y=0; started=1; fi
            draw_ui ;;
        # Right
        [dDвВ]|$'\e[C'|$'\eOC')
            auto_mode=0
            if [[ $dir_x -ne -1 ]]; then dir_x=1; dir_y=0; started=1; fi
            draw_ui ;;
        # Toggle Auto-Play (TAB, T, or B)
        $'\t'|[tTеЕ]|[bBиИ])
            auto_mode=$((1 - auto_mode))
            started=1
            draw_ui
            ;;
        # Adjust Speed
        "+"|"=")
            speed=$(awk "BEGIN {s=$speed - 0.02; if (s < 0.05) s=0.05; print s}") ;;
        "-"|"_")
            speed=$(awk "BEGIN {s=$speed + 0.02; if (s > 0.35) s=0.35; print s}") ;;
        # Pause
        " "|[pPзЗ])
            if [[ $started -eq 1 ]]; then
                paused=$((1 - paused))
                if [[ $paused -eq 1 ]]; then
                    move_cursor $(( (SCREEN_WIDTH - 12) / 2 )) $(( SCREEN_HEIGHT / 2 ))
                    printf "${C_MSG}${C_BOLD}[ PAUSED ]${C_RESET}"
                else
                    draw_board
                fi
            fi
            ;;
        # Quit
        [qQйЙ])
            cleanup ;;
    esac
}

update_state() {
    if [[ $started -eq 0 || $paused -eq 1 ]]; then
        return
    fi

    if [[ $auto_mode -eq 1 ]]; then
        ai_choose_direction
    fi

    local new_x=$((snake_x[0] + dir_x))
    local new_y=$((snake_y[0] + dir_y))

    # Wall collision
    if [[ $new_x -lt 0 || $new_x -ge GRID_W || $new_y -lt 0 || $new_y -ge GRID_H ]]; then
        game_over=1
        return
    fi

    # Self collision
    for ((i=0; i<snake_len; i++)); do
        if [[ ${snake_x[i]} -eq $new_x && ${snake_y[i]} -eq $new_y ]]; then
            game_over=1
            return
        fi
    done

    # Food eaten
    if [[ $new_x -eq $food_x && $new_y -eq $food_y ]]; then
        score=$((score + 10))
        snake_len=$((snake_len + 1))
        spawn_food
        draw_ui
    else
        # Erase previous tail cell
        local tail_x=${snake_x[snake_len-1]}
        local tail_y=${snake_y[snake_len-1]}
        move_grid "$tail_x" "$tail_y"
        printf "${CELL_EMPTY}"
    fi

    # Advance body array
    for ((i=snake_len-1; i>0; i--)); do
        snake_x[i]=${snake_x[i-1]}
        snake_y[i]=${snake_y[i-1]}
    done

    snake_x[0]=$new_x
    snake_y[0]=$new_y
}

init_game() {
    calc_dimensions
    score=0
    # Balanced default speed
    speed=0.14
    paused=0
    game_over=0
    started=0
    auto_mode=0

    local start_x=$((GRID_W / 2))
    local start_y=$((GRID_H / 2))

    snake_x=($start_x $((start_x - 1)) $((start_x - 2)))
    snake_y=($start_y $start_y $start_y)
    snake_len=3

    dir_x=1
    dir_y=0

    spawn_food
    draw_board

    # Start hint
    move_cursor $(( (SCREEN_WIDTH - 24) / 2 )) $(( SCREEN_HEIGHT / 2 - 1 ))
    printf "${C_TITLE}${C_BOLD}Press WASD or TAB (Auto)${C_RESET}"
}

main() {
    tput smcup 2>/dev/null
    tput civis 2>/dev/null
    stty -echo 2>/dev/null

    while true; do
        init_game
        while [[ $game_over -eq 0 ]]; do
            render_game
            read_input
            update_state

            # Clear hint once game starts
            if [[ $started -eq 1 && $snake_len -eq 3 && $score -eq 0 ]]; then
                move_cursor $(( (SCREEN_WIDTH - 24) / 2 )) $(( SCREEN_HEIGHT / 2 - 1 ))
                printf "                        "
            fi
        done

        # Update high score
        if [[ $score -gt $HIGHSCORE ]]; then
            HIGHSCORE=$score
            echo "$HIGHSCORE" > "$SCORE_FILE"
        fi

        # Game Over Screen
        local box_x=$(( (SCREEN_WIDTH - 16) / 2 ))
        local box_y=$(( SCREEN_HEIGHT / 2 - 1 ))

        move_cursor $box_x $box_y
        printf "${C_FOOD}${C_BOLD}╔══════════════╗${C_RESET}"
        move_cursor $box_x $((box_y + 1))
        printf "${C_FOOD}${C_BOLD}║  GAME OVER!  ║${C_RESET}"
        move_cursor $box_x $((box_y + 2))
        printf "${C_FOOD}${C_BOLD}╚══════════════╝${C_RESET}"

        move_cursor $(( (SCREEN_WIDTH - 30) / 2 )) $((box_y + 4))
        printf "${C_SCORE}Press [R] to Retry, [Q] to Quit${C_RESET}"

        while true; do
            IFS= read -rsn1 key
            case "$key" in
                [rRкК]) break ;;
                [qQйЙ]) cleanup ;;
            esac
        done
    done
}

main
