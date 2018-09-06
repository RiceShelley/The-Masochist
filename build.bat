@echo off
del game.exe
nasm -fwin32 main.asm -o game.obj
GoLink /entry _main /files /console game.obj kernel32.dll user32.dll msvcrt.dll /mix /fo game.exe
del game.obj