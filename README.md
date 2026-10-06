# 🐍 Bash Snake

> A clean, lightweight, and responsive classic Snake game written entirely in **pure Bash** with zero external dependencies.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## ✨ Features

- ⚡ **Zero dependencies:** Works out-of-the-box on any POSIX terminal with Bash 4+.
- 🎮 **Dual Controls:** Supports both `WASD` and **Arrow Keys** (plus Russian keyboard layout `ЦФЫВ`).
- 🎨 **Modern ANSI visuals:** Clean UTF-8 symbols, colored snake, and styled borders.
- 🏆 **High Score persistence:** Automatically saves and tracks your best score in `~/.bash_snake_highscore`.
- ⏸️ **Pause & Restart:** Instant pause/resume without resetting game state.
- 🚀 **Progressive Difficulty:** Game speed increases slightly as you score more points.

---

## 🕹️ Controls

| Action | Primary Key | Alternative / Arrows | Russian Layout |
| :--- | :---: | :---: | :---: |
| **Move Up** | `W` | `↑` | `Ц` |
| **Move Down** | `S` | `↓` | `Ы` |
| **Move Left** | `A` | `←` | `Ф` |
| **Move Right** | `D` | `→` | `В` |
| **Pause / Resume** | `Space` | `P` | `З` |
| **Restart (Game Over)** | `R` | - | `К` |
| **Quit Game** | `Q` | - | `Й` |

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/bash-snake.git
cd bash-snake
```

### 2. Run the game
```bash
./snake.sh
```

*(Optional) Install globally into your `~/.local/bin`*:
```bash
mkdir -p ~/.local/bin
ln -s "$(pwd)/snake.sh" ~/.local/bin/snake
```
Now you can simply run `snake` from any terminal window!

---

## 📋 Requirements

- Bash `4.0+`
- Terminal size of at least `40x22` characters
- UTF-8 font support (standard in Kitty, Alacritty, Foot, Konsole, etc.)

---

## 📄 License

This project is licensed under the MIT License - feel free to customize and share!
