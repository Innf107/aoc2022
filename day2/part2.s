BITS 64
GLOBAL _start

; I accidentally overwrote part 1 so, uh, this is all there is now.

; takes a number in rax
print_number:
    mov rbp, rsp ; save the stack pointer
    mov r10, rsp ; keep the stack pointer to calculate the size later

    push BYTE 10

.tostring_loop:
    ; rax, rdx = divmod(rdi, 10)
    xor rdx, rdx ; clear rdx because we're trying to divide
    mov rbx, 10  ; for some reason div cannot take a number directly
    div rbx

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
    cmp r15, [buffer_size]
    jl .skip_refill

    ; refill
    mov rax, 0                  ; read
    mov rdi, [fd]
                     ; input.txt
    mov rsi, buffer
    mov rdx, [buffer_capacity]
    syscall

    cmp rax, 0
    je .eof

    mov [buffer_size], rax

    mov r15, 0

.skip_refill:    
    mov rbx, buffer
    add rbx, r15

    xor rax, rax
    mov al, [rbx]   ; we do this, so that we only read a single byte

    inc r15

    ret
.eof:
    mov rax, -1
    ret


_start:
    mov r15, [buffer_capacity] ; This is set to buffer_capacity initially so that it is refilled
                               ; immediately and we don't read any garbage data.

    ; open the input file and save the resulting file descriptor to 'f'
    mov rax, 2 ; open
    mov rdi, input_file_path
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [fd], rax

    mov r12, 0 ; r12 ^= total score
.loop:
    call read_char
    mov r13, rax ; r13 ^= opponent shape
    sub r13, 65  ; this is 0 for A, 1 for B, 2 for C

    call read_char ; discard one space
    
    call read_char
    sub rax, 88 ; this is 0 for loss, 1 for draw, 2 for win
    mov rbx, rax

    mov rcx, 3
    mul rcx
    add r12, rax ; add the score of the result of the game
    
    ; possible moves
    ;   0 1 2
    ; 1 3 1 2
    ; 2 1 2 3
    ; 3 2 3 1
    mov rcx, [lookup_table + rbx*8]
    add r12, [rcx + r13*8]


    call read_char ; skip the final newline and check for EOF
    cmp rax, -1
    jne .loop

    mov rax, r12
    call print_number

    mov rax, 60
    mov rdi, 0
    syscall 

section .data
    input_file_path: db "input.txt", 0
    fd: dq 0

    buffer: times 4096 db 0
    buffer_size: dq 4096
    buffer_capacity: dq 4096

    losing_row: dq 3, 1, 2
    drawing_row: dq 1, 2, 3
    winning_row: dq 2, 3, 1
    lookup_table: dq losing_row, drawing_row, winning_row