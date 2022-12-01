BITS 64
GLOBAL _start


; takes a number in rdi
print_number:
    mov rbp, rsp ; save the stack pointer
    mov r10, rsp ; keep the stack pointer to calculate the size later

    mov rax, rdi

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

; returns in rax
; returns -1 on failure/eof
; might change rax, rdi, rsi, rdx
read_char:   
    mov rax, 0       ; read
    mov rdi, r15     ; input.txt
    mov rsi, rsp     ; we store the result on the stack
    sub rsi, 8       
    mov rdx, 1       ; we only read a single byte. This is incredibly inefficient, I know
    syscall

    cmp rax, 0
    je .failed

    mov rax, [rsp-8]
    ret

    .failed:
    mov rax, -1 ; failure (probably EOF) is indicated by returning -1
    ret

_start:
    ; open the input file and save the resulting file descriptor to r15
    mov rax, 2 ; open
    mov rdi, input_file_path
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r15, rax

    mov r11, 0 ; r11 ^= has hit eof

    mov r14, 0 ; r14 ^= maximum sum
    .max_loop:
    
    mov r13, 0 ; r13 ^= current sum
    .sum_loop:

    mov r12, 0

    call read_char
    mov rbx, 1
    mov r11, 0      ; r11 is callee saved, but this is fine, since read_char is the only call that might mutate it.
    cmp rax, -1     ; check if we hit eof, which also ends our final sum
    cmove r11, rbx  ; we just need to make sure to update it after every read_char call
    je .sum_loop_done
    cmp rax, 10 ; check if we hit a double newline (end of a sum)
    je .sum_loop_done
    jmp .char_is_okay

    .number_loop:
    call read_char

    mov rbx, 1
    mov r11, 0
    cmp rax, -1 ; check if we failed to read
    cmove r11, rbx
    je .sum_loop_done
    cmp rax, 10 ; check if we hit a newline. if we did, the current number is done.
    je .number_loop_done

    .char_is_okay:
    ; assumption: the character (in rax) is a valid digit
    sub rax, 48     ; convert the digit to an integer
    
    mov rcx, rax    ; back up the digit in rcx, since we need rax for multiplication

    mov rax, r12    ; why is x86 like this?
    mov rbx, 10
    mul rbx         ; shift the current number over by one digit (in base 10)
    mov r12, rax

    add r12, rcx    ; add our digit (now in rcx) to the current number

    jmp .number_loop
    .number_loop_done:

    add r13, r12

    jmp .sum_loop
    .sum_loop_done:

    cmp r13, r14    ; check if we exceeded the previous max
    cmovg r14, r13  ; update it accordingly if we did

    cmp r11, 1      ; exit on eof
    je .max_loop_done

    jmp .max_loop
    .max_loop_done:

    mov rdi, r14
    call print_number

    mov rax, 60     ; exit
    mov rdi, 0
    syscall


section .data:
    input_file_path: db "input.txt", 0

