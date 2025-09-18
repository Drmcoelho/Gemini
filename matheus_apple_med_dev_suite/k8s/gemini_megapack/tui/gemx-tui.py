#!/usr/bin/env python3
# tui/gemx-tui.py — TUI simples (curses)
import curses, subprocess, os, sys, textwrap

CMDS = [
  ("Menu do gemx.sh", ["./gemx.sh","menu"]),
  ("FZF Others", ["./gemx.sh","fzf","others"]),
  ("FZF Automations", ["./gemx.sh","fzf","auto"]),
  ("FZF History", ["./gemx.sh","fzf","hist"]),
  ("Stats", ["./gemx-stats.sh"]),
  ("Logs (FZF)", ["./gemx-logs.sh"]),
]

def run_cmd(cmd):
  subprocess.call(cmd)

def main(stdscr):
  curses.curs_set(0)
  idx = 0
  while True:
    stdscr.clear()
    stdscr.addstr(0,2,"Gemini Megapack — TUI", curses.A_BOLD)
    for i,(label,cmd) in enumerate(CMDS):
      mode = curses.A_REVERSE if i==idx else curses.A_NORMAL
      stdscr.addstr(2+i, 4, f"{i+1}. {label}", mode)
    stdscr.addstr(10, 2, "↑/↓ para navegar, Enter para executar, q para sair")
    c = stdscr.getch()
    if c in (ord('q'),27): break
    elif c in (curses.KEY_UP, ord('k')): idx = (idx-1) % len(CMDS)
    elif c in (curses.KEY_DOWN, ord('j')): idx = (idx+1) % len(CMDS)
    elif c in (curses.KEY_ENTER, 10, 13): 
      stdscr.clear(); stdscr.refresh()
      curses.endwin()
      run_cmd(CMDS[idx][1])
      stdscr = curses.initscr()
      curses.noecho(); curses.cbreak(); stdscr.keypad(True)
  curses.endwin()

if __name__ == "__main__":
  curses.wrapper(main)
