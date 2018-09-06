; load world from file
extern _fopen, _fclose, _fgets, _strlen

_scroll_src:
	pushad

	;fopen()
	push open_type
	push src0
	call _fopen
	add esp, 8

	;If error opening file, bail
	cmp eax, 0
	je  .end

	;fd_in = ret
	mov	[fd_in], eax

.loop:
	;fgets()
	mov eax, [fd_in]
	push eax
	push 32768
	push buff
	call _fgets
	add esp, 12

	;If error reading the file, bail
	cmp eax, 0
	je  .end

	; output src line by line	
	mov ecx, buff
	call _print_line

	jmp .do_sleep

.do_sleep:
	mov	eax, 10
	call	_sleep
	loop	.loop

.end:
	mov	ecx, 10
.loop2:
	call	_new_line
	loop	.loop2

	;fclose()
	mov eax, [fd_in]
	push eax
	call _fclose
	add esp, 4

	popad
	ret

;Load a file into a variable
;arg1: filename
;arg2: output variable
;arg3: output variable size
_load_file:
	;Establish stack frame
	push ebp
	mov ebp, esp
	pushad

	push open_type
	push dword [ebp + 8]
	call _fopen
	add esp, 8
	mov	[fd_in], eax
	;No error checking.
	;If we can't load something here we have bigger problems

	mov ebx, 0 ;loop count
.loadline: ;Load a line into the buffer until we've read arg3 characters
	;fgets()
	mov eax, dword [ebp + 16]
	sub eax, ebx ;eax = var_size - read
	mov ecx, dword [ebp + 12]
	add ecx, ebx ;add to target pointer so we append to current output
	push dword [fd_in]
	push eax
	push ecx
	call _fgets
	add esp, 12

	cmp eax, 0	;eof: done loading
	je .doneloading

	;ebx += strlen(screen)
	push eax
	call _strlen
	add esp, 4
	add ebx, eax

	jmp .loadline

.doneloading:
	;fclose()
	mov eax, [fd_in]
	push eax
	call _fclose
	add esp, 4

	;Restore stack frame
	popad
	mov esp, ebp
	pop ebp

	ret