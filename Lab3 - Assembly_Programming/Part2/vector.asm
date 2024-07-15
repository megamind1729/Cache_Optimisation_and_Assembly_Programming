extern realloc
extern free

section .text
global init_v
global delete_v
global resize_v
global get_element_v
global push_v
global pop_v
global size_v

init_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; Constructor. Arguments : pointer to the vector (rdi)
        ; Should initialize buff_size = 0, size = 0, ptr = NULL
        mov qword [rdi], 0    ; buff_size is initialised as 0
        mov qword [rdi + 8], 0   ; size of vector is initialised as 0
        mov qword [rdi + 16], 0  ; ptr is initialised as NULL(0)

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

delete_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; Destructor. Arguments : pointer to the vector (rdi)
        ; Should set buff_size = 0, size = 0
        ; Deallocate memory used by ptr using 'call free', and set ptr = NULL 
        mov qword [rdi], 0              ; Set buff_size = 0
        mov qword [rdi + 8], 0          ; Set size = 0
        push rdi        
        mov rdi, qword [rdi + 16]
        call free                       ; Freeing space allocated for storing elements
        pop rdi
        mov qword [rdi + 16], 0         ; Set ptr = NULL

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

resize_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; Resizes memory allocated to vector buffer (using 'call realloc')
        ; Arguments : pointer to vector (rdi), new buffer size (rsi)
        mov qword [rdi], rsi
        push rdi
        push rsi
        mov rdi, qword [rdi + 16]       ; rdi is set to ptr (base address of initial array)
        shl rsi, 3                      ; rsi is set to number of bytes required (rsi*8) 
        call realloc                    ; rax is the base address of resized array.
        pop rsi
        pop rdi
        mov qword [rdi + 16], rax       ; ptr is set to new base address.

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

get_element_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; Arguments: pointer to vector (rdi), index (rsi)
        ; Return value: pointer to (i+1)th element
        mov r15, qword [rdi + 16]
        lea rax, qword [r15 + rsi*8]

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

push_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; vector.pushback(element)
        ; Arguments: pointer to vector (rdi), element to be inserted (rsi)
        ; If buffer is full, resize using 'call resize_v' with new buffer size 2*s+1
        mov r8, qword [rdi]
        cmp r8, qword [rdi + 8]
        jne insert_element

        buffer_full:
                push rsi
                mov rsi, qword [rdi]
                shl rsi, 1
                add rsi, 1
                call resize_v
                pop rsi
        
        insert_element:
                mov r15, [rdi + 16]
                mov r14, qword [rdi + 8]
                mov qword [r15 + r14*8], rsi
                add qword [rdi + 8], 1

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

pop_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE

        ; Argument : pointer to vector. Return value (rax) : last element
        ; Decrease size by 1. No need to reduce buff_size
        add qword [rdi + 8], -1
        mov r15, qword [rdi + 16]
        mov r14, qword [rdi + 8] 
        mov rax, qword [r15 + r14*8]

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

size_v:
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15
        ; ENTER YOUR CODE HERE, DO NOT MODIFY EXTERNAL CODE
        ; Argument : pointer to vector (rdi). Return value (rax) : size of vector.
        mov rax, qword [rdi + 8]

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret