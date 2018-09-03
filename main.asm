; include sceen output helper funtions
%include "screen.asm"
%include "loader.asm"

%define KEYB_LEN 24

extern printf

section .data
	new_line:	db  0xA
	input:		db '//dev/input/event3', 0
	logo:		db './start_screen', 0
	src0:		db './src_code_blob', 0
	world_file:	db './world_res', 0
	world_len:	equ 6000
	world_w:	db 120
	testb:		db '1234', 0
	timeval:	
		t_sec 	dd 0
		t_usec 	dd 0
	player:		db '####', 0
	player_len:	equ 3
	fmtStr:		db "printf: value - %d", 0xA, 0
	start_str:	db "Game Loader...", 0xA, "type help for options.", 0xA, 0
	start_str_len:	equ $ - start_str
	prompt:		db "> ", 0
	run_game:	db "run", 0
	loading_g	db "Loading game...", 0xA, 0
	loading_g_len	equ $ - loading_g

section .bss
	screen:		resb world_len
	world:		resb world_len
	buff:		resb 32768
	playerX:	resb 8
	playerY:	resb 8
	key_buf:	resb 512
	fd_in:		resb 8
	key_in:		resb 8
	key:		resb 8
	usr_in:		resb 128

; REMINDER the six registers used to store arugments of Linux kernal 
; sys calls are EBX, ECX, EDX, ESI, EDI, and EBP
; sys call refs on syscalls.kernelgrok.com
section .text
	global main

; start game at menu
main:
	jmp	_start_game

	call	_clear_screen

	mov	ecx, start_str
	mov	edx, start_str_len
	call	_print_line

; run repeating menu dialog
.start_d:
	mov	eax, 4
	mov	ebx, 1
	mov	ecx, prompt
	mov	edx, 2
	int	0x80

	; get user input

	mov	eax, 3
	mov	ebx, 0
	mov	ecx, usr_in
	mov	edx, 128	
	int	0x80

	; see if user typed run
	mov	ecx, 3
	mov	esi, usr_in
	mov	edi, run_game
	call	_n_cmp

	cmp	eax, 0
	je	_start_game

	jmp	.start_d

; Start game
_start_game:

	mov	ecx, loading_g
	mov	edx, loading_g_len
	call	_print_line

	; a tastfull pause to build suspense 
	mov	eax, 1
	mov	ebx, 0
	call	_sleep

	; scroll source code
	call	_scroll_src

	mov	[playerX], byte 4
	mov	[playerY], byte 45

	; load resources 
	call	_load_start_screen
	call	_load_world

	jmp	_game_loop

; put dd in eax
_print_f:
	pusha

	push	ebp
	mov	ebp, esp
	
	push	eax
	push	dword fmtStr
	call	printf
	add	esp, 12
	mov	eax, 0

	popa
	ret

_read_input:
	
	pusha
	mov	eax, 5
	mov	ebx, input
	mov	ecx, 0
	int	0x80

	mov	[key_in], eax
	
	mov	eax, 3
	mov	ebx, [key_in]
	mov	ecx, key_buf
	mov 	edx, 32
	int	0x80

	mov	eax, 6
	mov	ebx, [key_in]
	int	0x80

	mov	eax, 0
	mov	ax, word [key_buf + 26]
	mov	[key], ax
	
	popa
	ret


; MAIN GAME LOOP
_game_loop:

	mov	eax, 0
	mov	ebx, 300
	call	_sleep

	call	_new_line

	; Clear and render console game screen
	mov	ecx, 10
.clear_loop:
	call	_new_line
	loop	.clear_loop

	; print out player x / y
	mov	eax, [playerX]
	call	_print_f
	mov	eax, [playerY]
	call	_print_f

	call	_render

	; read user input from /dev/input/event
	call	_read_input

	; put key code into eax
	mov	eax, 0
	mov	ax, [key]

	; Apply controls

	; if ESC down exit game
	cmp	eax, 1
	je	_sys_exit			

	; if player move right
	cmp	eax, 106
	je	.move_right

	cmp	eax, 105
	je	.move_left

	cmp	eax, 103
	je	.move_up

	cmp	eax, 108
	je	.move_down

	jmp	.end_key_eval

.move_right:
	add	[playerX], byte 1
	jmp	.end_key_eval

.move_left:
	sub	[playerX], byte 1
	jmp	.end_key_eval

.move_up:
	sub	[playerY], byte 1
	jmp	.end_key_eval

.move_down:
	add	[playerY], byte 1
	jmp	.end_key_eval
	
.end_key_eval:

	; Loop
	jmp	_game_loop

; put sec in eax, and usec in ebx	
_sleep:
	pusha
	mov	dword [t_sec], eax
	mov	dword [t_usec], ebx
	mov	eax, 162
	mov	ebx, timeval
	mov	ecx, 0
	int	0x80
	popa
	ret

_sys_exit:
	mov	eax, 1
	mov	ebx, 0
	int	0x80
