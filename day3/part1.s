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

    mov r14, 0 ; r14 stores the total number of items
    
    ; initialize the occurence table for the first half
    

    call read_char
    cmp rax, -1
    je .done    ; exit on eof
    jmp .store_character

.read_loop:
    call read_char
    cmp rax, 10
    je .read_done
    cmp rax, -1
    je .read_done
.store_character:
    mov BYTE [item_buffer + r14], al
    inc r14
    jmp .read_loop

.read_done:
    mov r12, r14 ; r12 ^= size of the left half
    shr r12, 1   ; r12 = r14 // 2

    mov r11, 0

.populate_table_loop:
    xor rax, rax
    mov al, [item_buffer + r11]
    sub rax, 65 ; This maps 'A' to 0, ..., 'z' to '57'

    mov [last_seen_table + rax*8], r13

    inc r11
    cmp r11, r12
    jl .populate_table_loop

.find_duplicate_loop:
    ; This uses r12 as the index now, since r12 already points at the first element of the second half
    xor rax, rax
    mov al, [item_buffer + r12]
    sub rax, 65 ; Same mapping as above

    cmp [last_seen_table + rax*8], r13
    je .found

    inc r12
    jmp .find_duplicate_loop

.found:
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

    jmp .loop
.done:

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

    last_seen_table: times 58 dq 0

    total_priority: dq 0
