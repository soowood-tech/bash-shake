# 🐍 Bash Snake

> A clean, lightweight, and responsive classic Snake game with an **intelligent AI Auto-Play mode**, written in **pure Bash** with zero external dependencies.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## ✨ Features

- ⚡ **Zero dependencies:** Works out-of-the-box in any standard terminal (Bash 4+).
- 🤖 **AI Auto-Play Mode:** Press `Tab` or `T` anytime to watch the smart pathfinding bot play automatically!
- 🎨 **Adaptive Centered UI:** Automatically scales and centers within your terminal window (fits small screens down to 10 rows).
- 🎮 **Dual Controls:** Full support for `WASD`, **Arrow Keys**, and Russian keyboard layout (`ЦФЫВ`).
- ⏱️ **Adjustable Speed:** Smooth, comfortable default pace, with on-the-fly speed adjustments (`+` / `-`).
- 🏆 **High Score Persistence:** Automatically records and saves your highest score in `~/.bash_snake_highscore`.
- ⏸️ **Pause & Clean Screen:** Restores terminal state cleanly upon exit (`tput smcup/rmcup`).

---

## 🕹️ Controls

| Action | Primary Key | Alternative / Arrows | Russian Layout |
| :--- | :---: | :---: | :---: |
| **Move Up** | `W` | `↑` | `Ц` |
| **Move Down** | `S` | `↓` | `Ы` |
| **Move Left** | `A` | `←` | `Ф` |
| **Move Right** | `D` | `→` | `В` |
| **Toggle Auto-Play (AI)** | `Tab` | `T` / `B` | `Е` / `И` |
| **Adjust Speed** | `+` (faster) | `-` (slower) | `=` / `_` |
| **Pause / Resume** | `Space` | `P` | `З` |
| **Restart (Game Over)** | `R` | - | `К` |
| **Quit Game** | `Q` | - | `Й` |

---

## 🚀 Quick Start

### 1. Run directly
```bash
cd ~/bash-snake
./snake.sh
```

*(Optional) Symlink to your `~/.local/bin` to run from anywhere:*
```bash
mkdir -p ~/.local/bin
ln -sf "$(pwd)/snake.sh" ~/.local/bin/snake
```
Now simply type `snake` in any terminal!

---

## 📄 License

This project is licensed under the MIT License.
