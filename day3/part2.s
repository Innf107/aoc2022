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
    mov rbx, read_buffer
    add rbx, r15

    xor rax, rax
    mov al, [rbx]   ; we do this, so that we only read a single byte

    inc r15

    ret
.eof:
    mov rax, -1
    ret

; reads a line and uses it to populate the table at 'r12'
populate_table:
    mov r14, 0 ; r14 stores the total number of items in the line
    ; initialize the occurence table for the first half
    mov r11, 0
.populate_table_loop:
    call read_char
    cmp rax, 10
    je .populate_done

    sub rax, 65 ; This maps 'A' to 0, ..., 'z' to '57'

    mov [r12 + rax*8], r13
    inc r11
    jmp .populate_table_loop
.populate_done:
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

    mov r13, 0 ; r13 ^= the current iteration
.loop:
    inc r13
    mov r12, last_seen_table1
    call populate_table
    mov r12, last_seen_table2
    call populate_table

.find_duplicate_loop:
    call read_char
    sub rax, 65 ; Same mapping as above

    cmp [last_seen_table1 + rax*8], r13
    jne .find_duplicate_loop
    cmp [last_seen_table2 + rax*8], r13
    jne .find_duplicate_loop

    ; found char: rax + 65
    mov rbx, rax
    add rbx, 27 ; in case this is an uppercase character
    mov rcx, rax
    sub rcx, 31 ; in case this is a lowercase character

    cmp rax, 28
    cmovle rax, rbx ; uppercase
    cmovg rax, rcx  ; lowercase

    mov rdx, [total_priority]
    add rdx, rax
    mov [total_priority], rdx

.consume_rest_of_line:
    call read_char
    cmp rax, 10
    je .loop
    cmp rax, -1
    jne .consume_rest_of_line


    mov rax, [total_priority]
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

    item_buffer: times 4096 db 0 ; 4096 bytes has got to be enough for anyone right?

    last_seen_table1: times 58 dq 0
    last_seen_table2: times 58 dq 0

    total_priority: dq 0
