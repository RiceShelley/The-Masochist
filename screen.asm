; Output line feed 
_new_line:
	pusha
	mov	eax, 4
	mov	ebx, 1
	mov	ecx, new_line
	mov	edx, 1
	int	0x80
	popa
	ret

; Clear screen
_clear_screen:
	pusha
	mov	ecx, 256
.loop:
	call	_new_line	
	loop	.loop
	
	popa
	ret

; Output String of n length
; n -> edx, addr of first char in ecx
_print_line:
	pusha
	mov	eax, 4
	mov	ebx, 1
	int	0x80
	popa
	ret

; copy n bytes n -> ecx | dest -> edi | src -> esi
_n_cpy:
	pusha	
.loop:
	movsb
	loop .loop

	popa
	ret

; n cmp -> compare strings | n-> ecx | str1 -> edi | str2 -> esi | returns 0 in eax if match
_n_cmp:
	pusha

.loop:
	mov	al, [esi]
	mov	bl, [edi]

	cmp	al, bl
	jne	.end

	inc	edi
	inc	esi

	loop	.loop

	popa
	mov	eax, 0
	ret

.end:
	popa
	mov	eax, 1
	ret

; render screen
_render:
	pusha

	mov	eax, [playerX]
	mov	eax, [playerY]

	; copy world into screen buffer 
	mov	edi, screen
	mov	esi, world
	mov	ecx, world_len
	call	_n_cpy

	; copy player into world 
	mov	edi, screen

	mov	eax, 0
	mov	edx, 0
	mov	al, [playerY]
	mov	dl, 120
	mul	dl

	add	edi, eax

	add	edi, [playerX]		

	mov	esi, player
	mov	ecx, player_len
.loop:
	movsb
	inc	esi
	inc	edi
	loop	.loop

	; Print screen
	mov	ecx, screen
	mov	edx, world_len
	call	_print_line

	popa
	ret	
