BITS 64
GLOBAL _start

; takes a number in rax.
; might mutate rcx, rdx, rdi, rsi, r10, rbp
print_number:
    mov rbp, rsp ; save the stack pointer
    mov r10, rsp ; keep the stack pointer to calculate the size later

    push BYTE 10

.tostring_loop:
    ; rax, rdx = divmod(rdi, 10)
    xor rdx, rdx ; clear rdx because we're trying to divide
    mov rcx, 10  ; for some reason div cannot take a number directly
    div rcx

    add rdx, 48        ; convert digit to a char
    dec rsp
    mov BYTE [rsp], dl ; We need to do this dance to push a single byte

    cmp rax, 0
    jne .tostring_loop
    
    sub r10, rsp ; r10 now contains the size of the stack

    mov rax, 1      ; write
    mov rdi, 1      ; stdout
    mov rsi, rsp    ; the stack buffer
    mov rdx, r10    ; the size of the stack
    syscall

    mov rsp, rbp    ; restore the stack pointer
    ret

read_char:
    cmp r15, [read_buffer_size]
    jl .skip_refill

    ; refill
    mov rax, 0                  ; read
    mov rdi, [fd]
                     ; input.txt
    mov rsi, read_buffer
    mov rdx, [read_buffer_capacity]
    syscall

    cmp rax, 0
    je .eof

    mov [read_buffer_size], rax

    mov r15, 0

.skip_refill:    
    mov rcx, read_buffer
    add rcx, r15

    xor rax, rax
    mov al, [rcx]   ; we do this, so that we only read a single byte

    inc r15

    ret
.eof:
    mov rax, -1
    ret

_start:
    mov r15, [read_buffer_capacity] ; This is set to buffer_capacity initially so that it is refilled
                                    ; immediately and we don't read any garbage data.

    ; open the input file and save the resulting file descriptor to 'f'
    mov rax, 2 ; open
    mov rdi, input_file_path
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [fd], rax

    ; manually read the first 3 characters into r12, r13, r14
    call read_char
    mov r12, rax
    call read_char 
    mov r13, rax
    call read_char
    mov r14, rax

    mov rbx, 4
.read_loop:
    call read_char
    cmp rax, r14
    je .not_marker
    cmp rax, r13
    je .not_marker
    cmp rax, r12
    je .not_marker
    cmp r14, r13
    je .not_marker
    cmp r14, r12
    je .not_marker
    cmp r13, r12
    je .not_marker

    ; We found the marker!
    mov rax, rbx 
    call print_number

    mov rax, 60 ; exit
    mov rdi, 0
    syscall 

.not_marker:
    mov r12, r13
    mov r13, r14
    mov r14, rax

    inc rbx
    jmp .read_loop



section .data
    input_file_path: db "input.txt", 0
    fd: dq 0

    read_buffer: times 4096 db 0
    read_buffer_size: dq 4096
    read_buffer_capacity: dq 4096


