; Macros
%macro exit 1
	mov rax, 60		; 'Exit' syscall
	mov rdi, %1		; exit code
	syscall
%endmacro

%macro print_newline 0
	; Store registers
	push rax
	push rdi
	push rsi
	push rdx

	; Print the char
	mov rax, 1					; WRITE syscall
	mov rdi, 1					; STDOUT
	mov rsi, newline_char		; The char to print
	mov rdx, 1					; Set length to 1
	syscall

	; Restore registers
	pop rdx
	pop rsi
	pop rdi
	pop rax
%endmacro

SYS_WRITE equ 1
FILE_STDOUT equ 1
MIN_ARG_COUNT equ 3

section .data
	arg_count_error db "Usage: ./caesar-cipher [rotation amount] [text]", 0xA, 0
	newline_char db 0xA

section .bss
	print_buffer resb 1		; Buffer for printing singular characters

section .text
	global _start

_start:
	; Make sure the user specified 2 arguments
	mov rax, [rsp]			; Get the argument count
	cmp rax, MIN_ARG_COUNT	; Check the argument count
	jne _print_usage		; If the arg count doesn't match, print usage and quit

	mov rax, [rsp+16]		; Get the shift amount string pointer to rax
	call _str_to_int		; Convert the shift string into a number
	mov r9, rax				; Copy the shift amount to r9

	mov r8, [rsp+24]		; Get the target string pointer to r8
	call _shift_chars		; Shift the characters with the caesar cipher algorithm

	;call _print				; Print the result string that should be in rax at this point

	print_newline

	exit 0

; Prints the program usage and quits with exit code 1
_print_usage:
	lea rax, arg_count_error
	call _print
	exit 1

; Get the length of a null-terminated string.
; The string will go MIA so push it to the stack before calling this
; input: pointer to the string in rax
; output: string length in rax
_strlen:
	xor rbx, rbx	; Count the string length into rbx

	_strlen_loop:
		inc rax			; Move to the next char
		inc rbx			; Increment the char counter
		mov cl, [rax]	; Move the current char to cl
		cmp cl, 0		; Check if we are at the end of the string
		jnz _strlen_loop

	mov rax, rbx	; Move the string length to rax
	ret

; Print a string
; input: pointer to the string in rax
; output: string printed to stdout
_print:
	; Store the string for later
	push rax

	; Get the string length to rdx
	call _strlen
	mov rdx, rax

	; Print the string
	mov rax, SYS_WRITE
	mov rdi, FILE_STDOUT
	pop rsi
	syscall
	ret

; Print a singular character from the print_buffer
; input: pointer to the char in rax
; output: char printed to stdout
_print_char:
	mov rsi, rax
	mov rax, SYS_WRITE
	mov rdi, FILE_STDOUT
	mov rdx, 1
	syscall
	ret


; Convert a string to integer value
; input: pointer to string in rax
; output: integer in rax
_str_to_int:
	push rax		; Store the string for later use
	call _strlen	; Get the string length
	mov r8, rax		; Store the string length to r8

	pop rbx			; Pop the string to rbx
	xor rax, rax	; Set rax to zero

	mov r9, 10		; Use 10 as a multiplier to shift numbers to left
	_str_to_int_loop:
		; Add the current char to rax
		xor rcx, rcx
		add cl, [rbx]
		add rax, rcx
		sub rax, '0'	; Convert the ASCII digit into a number

		dec r8
		cmp r8, 1		; Check if the loop should be over
		jne _str_to_int_ret

		mul r9					; Multiply the number with 10 to shift the digits to the left
		inc rbx					; Move to the next char
		jmp _str_to_int_loop	; Loop

	_str_to_int_ret:
		ret

; Shift letters by a given amount
; input: pointer to the string in r8 and shift amount in r9b
; output: the result string will be stored to rax
_shift_chars:
	; Store the string pointer to the stack
	push r8

	; Get the string length
	mov rax, r8
	call _strlen
	mov r10, rax

	xor rcx, rcx		; Use rcx as the loop interator

	_shift_chars_loop:
		call _shift_lowercase	; Shift lowercase chars, if any
		;call _shift_uppercase	; Shift uppercase chars, if any

		; Store the registers
		push rcx

		; Print the character
		xor rax, rax
		mov al, r8b
		call _print_char

		; Restore the registers
		pop rcx

		inc rcx					; Increment the loop iterator
		inc r8					; Move to the next character

		cmp rcx, r10			; Check if we are at the end of the string
		jne _shift_chars_loop	; Loop around

	pop rax				; Restore the string pointer

	ret

_return_true:
	mov rax, 1
	ret

_return_false:
	mov rax, 0
	ret

; Shift lowercase letters
; returns 1 if a shift happened
_shift_lowercase:
	; Check if the char is < 'a'
	cmp byte [r8], 'a'
	jl _return_false

	; Check if the char is > 'z'
	cmp byte [r8], 'z'
	jg _return_false

	xor r11, r11
	mov r11b, r8b
	add r11, r9
	add r8b, r11b		; Shift the character

	jmp _return_true	; The char was shifted, so return true


; Shift uppercase letters
; returns 1 if a shift happened
_shift_uppercase:
	; Check if the char is < 'A'
	cmp byte [r8], 'A'
	jl _return_false

	; Check if the char is > 'Z'
	cmp byte [r8], 'Z'
	jg _return_false


	jmp _return_true	; The char was shifted, so return true
