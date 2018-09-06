; load world from file
_load_world:
	pusha
	mov	eax, 5
	mov	ebx, world_file	
	mov	ecx, 0
	int	0x80
	
	mov	[fd_in], eax
	mov	eax, 3
	mov	ebx, [fd_in]
	mov	ecx, world
	mov	edx, 6000
	int	0x80

	mov	eax, 6
	mov	ebx, [fd_in]
	int	0x80
	popa
	ret

_load_device:
	pusha

	mov	eax, 5
	mov	ebx, deviceP_file
	mov	ecx, 0
	int	0x80

	mov	[fd_in], eax	
	mov	eax, 3
	mov	ebx, [fd_in]
	mov	ecx, device_path
	mov	edx, 256
	int	0x80

	mov	eax, 6
	mov	ebx, [fd_in]
	int	0x80

	mov	ecx, device_path
	mov	edx, 100
	call	_print_line

	; get rid of new line
	mov	esi, device_path
	mov	ecx, 256

.loop:
	cmp	[esi], byte 0xA
	jne	.next
	mov	[esi], byte 0
	jmp	.end

.next:
	inc	esi
	loop	.loop

.end:
	popa
	ret

_load_lvl:
	pusha

	mov	eax, 5
	mov	ebx, lvl
	mov	ecx, 0
	int	0x80
	
	mov	[fd_in], eax
	mov	eax, 3
	mov	ebx, [fd_in]
	mov	ecx, lvl_buff
	mov	edx, 2048
	int	0x80

	mov	eax, 6
	mov	ebx, [fd_in]
	int	0x80

	popa
	ret

_scroll_src:
	pusha

	mov	eax, 5
	mov	ebx, src0
	mov	ecx, 0
	int	0x80
	
	mov	[fd_in], eax
	mov	eax, 3
	mov	ebx, [fd_in]
	mov	ecx, buff
	mov	edx, 32768
	int	0x80

	mov	eax, 6
	mov	ebx, [fd_in]
	int	0x80

	; output src line by line	
	mov	edi, buff
.loop:
	mov	eax, 4
	mov	ebx, 1
	mov	ecx, edi
	mov	edx, 1
	int	0x80

	add	edi, 1
	
	cmp	[edi], byte 0
	je	.end

	cmp	[edi], byte 0xA
	je	.do_sleep

	jmp	.loop

.do_sleep:
	mov	eax, 0
	mov	ebx, 10000000
	call	_sleep
	loop	.loop

.end:
	mov	ecx, 10
.loop2:
	call	_new_line
	loop	.loop2

	popa
	ret

_load_start_screen:
	pusha

	mov	eax, 5
	mov	ebx, logo
	mov	ecx, 0
	int	0x80
	
	mov	[fd_in], eax
	mov	eax, 3
	mov	ebx, [fd_in]
	mov	ecx, screen
	mov	edx, 6000
	int	0x80

	mov	eax, 6
	mov	ebx, [fd_in]
	int	0x80
	
	mov	ecx, screen
	mov	edx, world_len
	call	_print_line

	mov	eax, 3
	mov	ebx, 0
	call	_sleep
	
	popa
	ret
