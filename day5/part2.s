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

; returns the read stack element (0 for an empty element) in rbx and the next character (or -1 on eof) in rax
; returns -1 in rbx if the element has the shape ' 1 ' (i.e. if this is the first line *after* the definition)
read_stack_elem:
    call read_char
    cmp rax, 32 ; read_char =? ' '
    je .empty_stack_elem

    call read_char ; this is the character we are looking for
    mov rbx, rax

    call read_char ; we skip the closing ']'
    call read_char ; we promised to return the next character
    ret
.empty_stack_elem:
    call read_char
    cmp rax, 49 ; '1' => end of definitions
    je .definitions_done

    call read_char ;
    call read_char ; We read, but immediately return the next character
    mov rbx, 0
    ret
.definitions_done:
    call read_char
    call read_char
    mov rbx, -1
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


    mov r14, 0 ; r14 ^= maximum stack size (= number of lines in the stack input)

.read_stacks_loop:
    mov r13, 0 ; r13 ^= the index in the current line
.read_line_loop:
    call read_stack_elem
    cmp rbx, -1
    je .read_stacks_done

    mov [stack_memory + r13 + r14], bl

    add r13, 4096
    cmp rax, 10 ; '\n' => end of the current line
    jne .read_line_loop

    inc r14
    jmp .read_stacks_loop

.read_stacks_done:
    mov [max_stack_size], r14

; The stacks have been loaded in reverse order (top to bottom), so we need to reverse
; them now. We also determine the actual size of the stack, rather than merely the maximum
    mov r13, 0 ; r13 ^= current stack index
    mov r12, stack_memory ; r12 ^= current stack memory
.reverse_all_loop:

    mov r14, -1
    
    
.determine_offset_loop:
    inc r14
    cmp BYTE [r12 + r14], 0
    je .determine_offset_loop
    
    mov rax, [max_stack_size]
    sub rax, r14
    mov [stack_sizes + r13*8], rax

    mov rax, [max_stack_size] ; max
    dec rax
    mov rbx, r14              ; min

mov rsi, r12
add rsi, r14
.reverse_loop:
    xor rcx, rcx
    xor rdx, rdx
    mov cl, [r12 + rax]
    mov dl, [r12 + rbx]
    
    mov [r12 + rbx], cl ; swap(max, min)
    mov [r12 + rax], dl
    dec rax
    inc rbx
    cmp rax, rbx
    jg .reverse_loop

mov rbx, 0
.shift_loop:
    mov al, [rsi + rbx]
    mov [r12 + rbx], al

    inc rbx
    cmp rbx, [stack_sizes+8*r13]
    jl .shift_loop

    inc r13
    add r12, 4096
    cmp r13, STACK_COUNT
    jl .reverse_all_loop

    
.read_until_newline_loop:
    call read_char
    cmp rax, 10
    jne .read_until_newline_loop

call read_char ; there is another newline before the operations start


.operation_loop:
    call read_char
    cmp rax, -1
    je .operations_done
    call read_char
    call read_char
    call read_char
    call read_char ; skip 'move '

    call read_number
    mov r14, rbx ; r14 ^= amount to move
    
    call read_char
    call read_char
    call read_char
    call read_char
    call read_char ; skip 'from '
    
    call read_number
    mov r13, rbx ; r13 ^= from
    dec r13 ; fuck 1-indexing
    lea r11, [stack_sizes + r13*8] ; r11 (which is volatile!) contains a pointer to the size of the 'from' stack
    shl r13, 12 
    add r13, stack_memory; r13 contains the base address of the 'from' stack now
    push r11 ; save r11 on the stack, so it will not be mutated by these read_char calls

    call read_char
    call read_char
    call read_char ; skip 'to '

    call read_number ; We ignore the final character in rax (either \n or EOF), since an EOF 
                     ; will be repeated on the next iteration, so we can safely exit there without
                     ; having to do any bookkeeping here
    mov r12, rbx ; r13 ^= to
    dec r12 ; fuck 1-indexing
    lea r10, [stack_sizes + r12*8] ; r10 contains a pointer to the size of the 'to' stack now
    shl r12, 12
    add r12, stack_memory; r12 contains the base address of the 'to' stack now

    pop r11 ; restore r11 now that all read_char calls are over

    ; move 
    sub [r11], r14 ; adjust the size of the from-stack. We then copy $rbx excess values over to the to-stack
    
    mov rcx, [r11]
    add rcx, r13 ; This is the address of the first element to be copied now

    mov rdx, [r10]
    add rdx, r12 ; This is the address where the first element will be copied to

    add [r10], r14 ; adjust the size of the to-stack

.push_loop:
    dec r14
    mov al, [rcx + r14]
    mov [rdx + r14], al

    cmp r14, 0
    jg .push_loop

    jmp .operation_loop

.operations_done:
    
    mov rbx, 0
.collect_message_loop:
    mov rcx, [stack_sizes + rbx*8]
    dec rcx

    mov rdx, rbx
    shl rdx, 12
    add rdx, stack_memory
    mov al, [rdx + rcx]

    mov [message_buffer + rbx], al

    inc rbx
    cmp rbx, STACK_COUNT
    jl .collect_message_loop
    
    mov rax, 1
    mov rdi, 1
    mov rsi, message_buffer
    mov rdx, STACK_COUNT
    syscall

    mov rax, 60
    mov rdi, 0
    syscall 


section .data
    input_file_path: db "input.txt", 0
    fd: dq 0

    read_buffer: times 4096 db 0
    read_buffer_size: dq 4096
    read_buffer_capacity: dq 4096

    ; Statically allocate 9 stacks with 4096 bytes each
    ; stack_0 = stack_memory
    ; stack_1 = stack_memory + 4096
    ; ...
    ; stack_n = stack_memory + 4096*n
    stack_memory: times (4096 * 9) db 0
    stack_sizes: times 9 dq 0

    max_stack_size: dq 0

    message_buffer: times 9 db 0

    ; This is hardcoded to 9, since that is the size in my input.
    ; For a more robust implementation, this could allocate a significantly larger number of stacks (maybe 20?)
    ; and determine the actual number from the first line (r13 after _start.read_stacks_done)
    STACK_COUNT equ 9

