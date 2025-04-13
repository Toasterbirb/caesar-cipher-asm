; Macros
%macro exit 1
	mov rax, 60		; 'Exit' syscall
	mov rdi, %1		; exit code
	syscall
%endmacro

%macro print 2
	mov rsi, %1
	mov rdx, %2
	mov rax, 1
	mov rdi, 1
	syscall
%endmacro

section .data
	arg_count_error db "usage: ./caesar-cipher [rotation amount] [text]", 0xa, 0
	arg_count_error_len equ $-arg_count_error
	rot_amount_error db "only values between -26 and 26 are allowed for the rotation amount", 0xa
	rot_amount_error_len equ $-rot_amount_error
	newline_char db 0xa

section .bss
	rotation_amount_ptr resq 1
	text_ptr resq 1

section .text
	global _start
	extern atoi

MIN_ARG_COUNT equ 3

_start:
	; check arg count
	cmp qword [rsp], MIN_ARG_COUNT
	jne print_usage_and_exit

	; get pointers to the rotation amount and the text
	mov rax, [rsp+16]
	mov [rotation_amount_ptr], rax

	mov rax, [rsp+24]
	mov [text_ptr], rax

	; convert the rotation amount string into a number
	mov rdi, [rotation_amount_ptr]
	call stoi

	; check if we are within the bounds of allowed rotation amounts
	cmp rax, -26
	jl print_rot_amount_error_and_exit

	cmp rax, 26
	jg print_rot_amount_error_and_exit

	; do the character shifting
	mov rdi, [text_ptr]
	mov rsi, rax
	call encode

	; print the result
	mov rdi, [text_ptr]
	call strlen
	print [text_ptr], rax
	print newline_char, 1

	exit 0

print_usage_and_exit:
	print arg_count_error, arg_count_error_len
	exit 1

print_rot_amount_error_and_exit:
	print rot_amount_error, rot_amount_error_len
	exit 1

; figure out the length of a null terminated string
; usage: [char* str]
; return: int
strlen:
	xor rcx, rcx
	.loop:
		mov al, [rdi+rcx]
		test al, al
		jz .ret
		inc rcx
		jmp .loop

.ret:
	mov rax, rcx
	ret

; convert a string into an integer
; usage: [char* number]
; return: int
stoi:
	push rbp
	mov rbp, rsp
	sub rsp, 1

	; set this byte to 1 if the number is negative
	mov byte [rbp-1], 0

	call strlen
	mov r8, rax
	xor rax, rax
	xor r10, r10

	mov r9, 10

	; check if the first character is a '-'
	; if yes, the number is a negative number and we also shouldn't
	; try to interpret the character as a number
	mov r10b, [rdi]
	cmp r10b, '-'
	je .reg_negative_num

	.loop:
		mov r10b, [rdi]
		sub r10, '0'
		add rax, r10

		dec r8
		cmp r8, 0

		jz .loop_end

		mul r9

		inc rdi
		jmp .loop

	.reg_negative_num:
		mov byte [rbp-1], 1
		inc rdi
		dec r8
		jmp .loop ; start looping

	.loop_end:
		; handle negative numbers
		cmp byte [rbp-1], 0
		je .ret
		neg rax

	.ret:
		mov rsp, rbp
		pop rbp
		ret

; run the caesar cipher on a block of null terminated text
; usage: [char* str, int shift_amount]
; return: void
encode:
	xor rax, rax
	xor rcx, rcx

	.loop:
		; stop when we come across a null byte
		mov al, [rdi+rcx]
		test al, al
		jz .ret

		; skip anything that is before 'A' and after 'z'
		cmp al, 'A'
		jl .loop_continue

		cmp al, 'z'
		jg .loop_continue

		; skip chars between 'Z' and 'a'
		cmp al, 'Z'
		setg bl
		cmp al,  'a'
		setl bh
		xor bl, bh
		jz .loop_continue

		; set rbx to 1 if the character is lowercase, otherwise set it to 0 (uppercase)
		xor rbx, rbx
		cmp al, 'a'
		setge bl

		; shift the character
		add al, sil

		; handle wrapping
		test bl, bl
		jnz .lowercase_wrap

		.uppercase_wrap:
			; overflow
			mov rdx, rax
			sub rdx, 'Z' - 'A' + 1
			cmp rax, 'Z'
			cmovg rax, rdx

			; underflow
			mov rdx, rax
			add rdx, 'Z' - 'A' + 1
			cmp rax, 'A'
			cmovl rax, rdx

			jmp .loop_continue

		.lowercase_wrap:
			; overflow
			mov rdx, rax
			sub rdx, 'z' - 'a' + 1
			cmp rax, 'z'
			cmovg rax, rdx

			; underflow
			mov rdx, rax
			add rdx, 'z' - 'a' + 1
			cmp rax, 'a'
			cmovl rax, rdx

			jmp .loop_continue

		.loop_continue:
			mov [rdi+rcx], al
			inc rcx
			jmp .loop

	.ret:
		ret
