BITS 64
GLOBAL _start

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

; Returns the number in rbx(!) and the next non-digit character (or -1 on eof) in rax
read_number:
    mov rbx, 0

.read_num_loop:
    call read_char
    cmp rax, 48 ; 48 ^= '0'
    jl .end_of_num
    cmp rax, 57 ; 57 ^= '9'
    jg .end_of_num

    mov rcx, rax ; save the character because we need rax for multiplication
    sub rcx, 48 ; convert the character to its digit value
    
    mov rax, rbx
    mov rdx, 10
    mul rdx
    mov rbx, rax

    add rbx, rcx

    jmp .read_num_loop

.end_of_num:
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

.loop:
    call read_number
    mov r14, rbx    ; start1
    call read_number
    mov r12, rbx    ; end1
    call read_number
    mov r13, rbx    ; start2
    call read_number
    mov r11, rbx    ; end2 ; using r11 (which is not callee-saved!) here should be fine, 
                           ; since we're not going to call a syscall again until we're done with it
    ; we should not mutate 'rax' now, since we need it for the exit condition

    cmp r14, r13
    je .increment ; If both are equal, one necessarily has to contain the other

    jg .start_after
; start1 <= start2. Either 2 is contained in 1 or the two are irrelevant
    cmp r12, r11 ; end1 >= end2?
    jl .iter_done
    jmp .increment


; start1 > start2. This means either 1 is contained in 2 or the two are irrelevant to us
.start_after:
    cmp r12, r11 ; end1 <= end2?
    jg .iter_done

.increment:
    inc QWORD [count]

.iter_done:
    cmp rax, -1
    jne .loop

    mov rax, [count]
    call print_number

    mov rax, 60
    mov rdi, 0
    syscall 


section .data
    input_file_path: db "input.txt", 0
    fd: dq 0

    read_buffer: times 4096 db 0
    read_buffer_size: dq 4096
    read_buffer_capacity: dq 4096

    count: dq 0
