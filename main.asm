; include sceen output helper funtions
%include "screen.asm"
%include "loader.asm"

%define KEYB_LEN 24

global _main

extern _exit, _gets
extern Sleep, GetAsyncKeyState

section .data
	new_line:	db  0xA, 0
	input:		db '//dev/input/event3', 0
	logo:		db './start_screen', 0
	lvl:		db './lvl_map', 0
	src0:		db './src_code_blob', 0
	open_type:	db 'rw', 0
	world_file:	db './world_res', 0
	world_len:	equ 6000
	world_w:	db 120
	testb:		db '1234', 0
	player:		db '#####', 0
	target:		db '***', 0
	fmtStr:		db "Score: %d", 0xA, 0
	start_str:	db "Game Loader...", 0xA, "Type help for options.", 0xA, 0
	start_str_len:	equ $ - start_str
	help_d:		db "Controls: ", 0xA, "Paddle movement: w, e, r, u, i, o | try to hit the *'s", 0xA, "Type run to begin game", 0xA, "Type about for game info", 0xA, "Type exit to quit", 0xA, 0xA, 0
	help_d_len:	equ $ - help_d
	about_d:	db "The masochist is a timing based terminal game", 0xA, "written for linux in 32 bit asm", 0xA, 0xA, 0
	about_d_len:	equ $ - about_d
	end_p:		db "Press enter to restart game", 0xA, 0
	end_p_len:	equ $ - end_p
	prompt:		db "> ", 0
	run_game:	db "run", 0
	help_p:		db "help", 0
	about_p:	db "about", 0
	exit_p:		db "exit", 0
	loading_g	db "Loading game...", 0xA, 0
	loading_g_len	equ $ - loading_g
	; Keys usr can press to move paddle
	keys		db 0x57, 0x45, 0x52, 0x55, 0x49, 0x4f
	p_pos		db 4, 26, 47, 68, 89, 109

section .bss
	screen:		resb world_len
	world:		resb world_len
	buff:		resb 32768
	lvl_buff:	resb 2048
	playerX:	resb 8
	playerY:	resb 8
	score:		resb 8
	act_tar:	resb 4
	render_cyc:	resb 4
	spawn_cyc:	resb 4
	key_buf:	resb 512
	fd_in:		resb 8
	usr_in:		resb 128

; REMINDER the six registers used to store arugments of Linux kernal 
; sys calls are EBX, ECX, EDX, ESI, EDI, and EBP
; sys call refs on syscalls.kernelgrok.com
section .text

; start game at menu
_main:
	call	_clear_screen

	mov	ecx, start_str
	call	_print_line

	jmp	restart_end

restart:
	call	_clear_screen

	mov	ecx, end_p
	call	_print_line

	; get user input
	push usr_in
	call _gets
	add esp, 4

restart_end:

; run repeating menu dialog
.start_d:

	mov	eax, dword [score]
	cmp	eax, 0
	je	.pscore_end

.print_score:	
	mov	eax, [score]
	call	_print_score

	mov	[score], dword 0

.pscore_end:

	mov	ecx, prompt
	call _print_line

	; get user input
	push usr_in
	call _gets
	add esp, 4

	; see if user typed run
	mov	ecx, 3
	mov	esi, usr_in
	mov	edi, run_game
	call	_n_cmp

	cmp	eax, 0
	je	_start_game

	; if user types help
	mov	ecx, 4
	mov	esi, usr_in
	mov	edi, help_p
	call	_n_cmp

	cmp	eax, 0
	je	.help

	; if user types about
	mov	ecx, 5
	mov	esi, usr_in
	mov	edi, about_p
	call	_n_cmp

	cmp	eax, 0
	je	.about

	; if user types exit
	mov	ecx, 4
	mov	esi, usr_in
	mov	edi, exit_p
	call	_n_cmp

	cmp	eax, 0
	je	_sys_exit

	jmp	.start_d
.help:
	mov	ecx, help_d
	mov	edx, help_d_len
	call	_print_line
	jmp	.start_d

.about:
	mov	ecx, about_d
	mov	edx, about_d_len
	call	_print_line
	jmp	.start_d

; Start game
_start_game:
	
	mov	[act_tar], byte 0

	mov	ecx, loading_g
	mov	edx, loading_g_len
	call	_print_line

	; a tastfull pause to build suspense 
	mov	eax, 1000
	call	_sleep

	; scroll source code
	call	_scroll_src

	mov	[playerX], byte 4
	mov	[playerY], byte 45

	; ---	load resources
	; Load logo
	push world_len
	push screen
	push logo
	call _load_file
	add esp, 12
	mov ecx, screen
	call _print_line
	mov eax, 3000
	call _sleep ;tasteful sleep

	; Load world
	push world_len
	push world
	push world_file
	call _load_file
	add esp, 12

	; Load level
	push 2048
	push lvl_buff
	push lvl
	call _load_file
	add esp, 12

	jmp	_game_loop

;eax: key to be read
_read_input:	
	push eax
	call GetAsyncKeyState
	
	test eax, 80000000h ;Tests to see if msb is set (key is down)
	jz .notequal
	mov eax, 1

.notequal:
	ret


; MAIN GAME LOOP
_game_loop:

	mov	eax, 5
	call	_sleep

	mov	eax, [render_cyc]
	add	[render_cyc], dword 1

	cmp	eax, 10
	jne	.do_keys

	; Clear and render console game screen
.render:
	mov	[render_cyc], byte 0
	call	_new_line
	mov	ecx, 7

.clear_loop:
	call	_new_line
	loop	.clear_loop

	mov	eax, [score]
	call	_print_score

	mov	eax, [spawn_cyc]
	add	[spawn_cyc], dword 1

	cmp	eax, 5
	jne	.spawn_end

.spawn:
	; spawn tagets

	mov	[spawn_cyc], byte 0

	; get number 0 - 6 from lvl file
	mov	esi, lvl_buff
	add	esi, [act_tar]
	mov	eax, 0
	mov	al, byte [esi]
	sub	al, '0'

	cmp	al, 6
	je	.rest

	cmp	al, 9
	je	restart

	; associate that number 0 - 6 with its corresponding collum 
	mov	esi, p_pos
	add	esi, eax
	mov	eax, 0
	mov	al, byte [esi]
	inc	eax

	; write target into world
	mov	edi, world
	mov	esi, target
	add	edi, 120
	add	edi, eax
	movsb

.rest:
	; increment active target
	add	[act_tar], byte 1

.spawn_end:

	call	_update_targets

	call	_render

.do_keys:
	; Apply controls

	; if ESC down exit game
	mov eax, 0x1b
	call _read_input
	cmp	eax, 1
	je	_sys_exit			
	
	mov eax, 0
	mov al, byte [keys]
	call _read_input
	cmp	eax, 1
	je	.key0

	mov eax, 0
	mov al, byte [keys + 1]
	call _read_input
	cmp	eax, 1
	je	.key1

	mov eax, 0
	mov al, byte [keys + 2]
	call _read_input
	cmp	eax, 1
	je	.key2

	mov eax, 0
	mov al, byte [keys + 3]
	call _read_input
	cmp	eax, 1
	je	.key3

	mov eax, 0
	mov al, byte [keys + 4]
	call _read_input
	cmp	eax, 1
	je	.key4

	mov eax, 0
	mov al, byte [keys + 5]
	call _read_input
	cmp	eax, 1
	je	.key5

	jmp	.end_key_eval

.key0:
	mov	al, byte [p_pos]
	mov	[playerX], al
	jmp	.end_key_eval

.key1:
	mov	al, byte [p_pos + 1]
	mov	[playerX], al
	jmp	.end_key_eval

.key2:
	mov	al, byte [p_pos + 2]
	mov	[playerX], al
	jmp	.end_key_eval

.key3:
	mov	al, byte [p_pos + 3]
	mov	[playerX], al
	jmp	.end_key_eval

.key4:
	mov	al, byte [p_pos + 4]
	mov	[playerX], al
	jmp	.end_key_eval

.key5:
	mov	al, byte [p_pos + 5]
	mov	[playerX], al
	jmp	.end_key_eval

.end_key_eval:

	; Loop
	jmp	_game_loop

; put sec in eax, and usec in ebx	
_sleep:
	pusha

	push eax
	call Sleep

	popa
	ret

_sys_exit:
	push 0
	call _exit