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

    ; read the first 14 characters
    mov rbx, 0
.initial_read_loop:
    call read_char
    mov [marker_buffer+rbx], al

    inc rbx
    cmp rbx, 14
    jl .initial_read_loop


    mov r14, 14 ; r14 ^= iteration

.main_loop:
    mov rbx, 0 ; rbx ^= outer
.check_marker_loop:
    mov rcx, rbx ; rcx ^= outer
.check_marker_inner_loop:
    inc rcx
    cmp rcx, 14
    jge .inner_done

    mov dl, [marker_buffer+rbx]
    cmp dl, [marker_buffer+rcx]
    je .not_marker

    jmp .check_marker_inner_loop
.inner_done:
    inc rbx
    cmp rbx, 14
    jl .check_marker_loop

; We found the marker!
    mov rax, r14
    call print_number

    mov rax, 60 ; exit
    mov rdi, 0
    syscall

.not_marker:

    mov rbx, 0
.shift_loop:
    mov al, [marker_buffer+rbx+1]
    mov [marker_buffer+rbx], al

    inc rbx
    cmp rbx, 13
    jl .shift_loop

    call read_char
    mov [marker_buffer+13], rax

    inc r14
    jmp .main_loop



section .data
    input_file_path: db "input.txt", 0
    fd: dq 0

    read_buffer: times 4096 db 0
    read_buffer_size: dq 4096
    read_buffer_capacity: dq 4096

    marker_buffer: times 14 db 0

