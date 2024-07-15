extern init_v
extern pop_v
extern push_v
extern size_v
extern get_element_v
extern resize_v
extern delete_v

section .text
global init_h
global delete_h
global size_h
global insert_h
global get_max
global pop_max
global heapify
global heapsort

init_h:
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

        ; Constructor. Arguments : pointer to the heap (rdi)
        ; Should initialize the vector using 'call init_v'
        call init_v

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

delete_h:
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

        ; Destructor. Arguments : pointer to the heap (rdi)
        ; Deallocate the memory for vector using 'call delete_v' 
        call delete_v

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


size_h:
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

        ; Argument : pointer to heap (rdi). Return value: size of heap(rax).
        ; Return the size of heap/vector using 'call size_v'
        call size_v

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


insert_h:
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

        ; heap.insert(element)
        ; Arguments: pointer to vector (rdi), element to be inserted (rsi)
        ; Insert element to vector using 'call push_v'
        ; Go up the heap to fix the heap
        call size_v
        mov r15, rax            ; r15 - Size of vector before resizing
        call push_v             ; Pushes element rsi into vector, and increments size
        
        mov rsi, r15
        call get_element_v
        mov r13, rax            ; r13 - pointer to element at index r15
        mov r11, qword [r13]    ; r11 - element at index r15

        insert_loop:        
                cmp r15, 0
                je exit_insert_loop 

                push rdi
                mov rdi, r15  
                call parent
                pop rdi
                mov r14, rax            ; r14 - Index of parent of r15

                mov rsi, r14
                call get_element_v
                mov r12, rax            ; r12 - pointer to element at index r14 (parent)
                mov r10, qword [r12]

                cmp r11, r10
                jle exit_insert_loop           ; Exit loop if v[parent(r15)] >= v[r15]
                
                mov r15, r14            ; Swapping [r13], [r12]
                mov qword [r13], r10    ; And updating r15, r13
                mov r13, r12
                mov qword [r12], r11
                jmp insert_loop 

        parent:
                mov rax, rdi
                add rax, -1
                shr rax, 1
                ret 

        exit_insert_loop:
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

get_max:
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

        ; Arguments: pointer to heap (rdi). Return value : maximum element of heap (rax)
        ; Get pointer to 1st element of vector using 'call get_element_v' taking second argument as 1
        ; Then, return the value referenced by that pointer
        mov rsi, 0              ; rsi = 0 (first element of heap)
        call get_element_v
        mov rax, qword [rax]

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

pop_max:
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

        ; Argument : pointer to heap (rdi). Return value: maximum element of heap (rax)
        ; Swap the elements of first and last element of vector, and 'call pop_v'
        ; Then, DSA-heapify on first element
        
        call size_v 
        mov r13, rax                    ; r13 - size of heap
        
        mov rsi, 0 
        call get_element_v
        mov r8, rax                     ; r8 - pointer to v[0]

        mov rsi, r13
        add rsi, -1 
        call get_element_v
        mov r9, rax                     ; r9 - pointer to v[sz-1]

        mov r10, qword [r8]
        mov r11, qword [r9]
        mov qword [r8], r11
        mov qword [r9], r10

        call pop_v                      ; rax is set to v[sz-1] = max_element
        mov rsi, 0
        call DSA_heapify                ; DSA_heapify(0) makes it into a heap again 
        jmp exit_pop_max_loop

        ; Arguments : pointer to heap (rdi), index to heapify (rsi)
        ; If (2i+1)>sz, return. Else if (2i+2)>sz, right_not_present. Else, both present.
        DSA_heapify:
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
                push rsi

                call size_v
                mov r13, rax            ; r13 = size of heap

                mov r15, rsi            ; r15 = index = i (say)
                mov rdx, rsi            ; rdx = index = i

                call get_element_v        
                mov r14, rax            ; r14 = pointer to r15 element
                mov rbx, rax            ; rbx = pointer to maximum element (initialised to r15)
                mov r8, qword [r14]     ; r8 = v[i]
                

        heapify_loop:           ; r15 = i, rbx = r14 = pointer to v[i], r8 = v[i]

                mov r11, r15
                shl r11, 1
                add r11, 1              ; r11 = left = 2*i+1
                mov r12, r11
                add r12, 1              ; r12 = right = 2*i+2

                cmp r11, r13            ; If left = 2*i+1 >= sz, return;
                jge exit_DSA_heapify

        left_present:                   ; Else, check v[i] >= v[left]
                mov rsi, r11            
                call get_element_v

                mov r9, rax             ; r9 = pointer to left child
                mov r10, qword [r9]     ; r10 = v[left]
                
                cmp qword [rbx], r10             
                jge after_left_comparison       ; If v[i] >= v[left], rbx does not change. 
                mov rbx, r9                     ; Else, rbx = r9 (pointer to v[left])
                mov rdx, r11

        after_left_comparison:
                cmp r12, r13            ; If right = 2*i+2 >= sz, return;
                jge after_both_comparisons

        right_present:
                mov rsi, r12
                call get_element_v
                mov r9, rax             ; r9 = pointer to right child
                mov r10, qword [r9]           ; r10 = v[right]

                cmp qword [rbx], r10
                jge after_both_comparisons      ; If v[rbx] >= v[left], rbx does not change.
                mov rbx, r9                     ; Else, rbx = r9 (pointer to v[right])
                mov rdx, r12

        after_both_comparisons:
                cmp rbx, r14
                je exit_DSA_heapify

                mov rcx, qword [rbx]
                mov qword [rbx], r8
                mov qword [r14], rcx

                ; Updating r15, rbx, r14, r8 for the next iteration of loop
                mov r15, rdx 
                mov r14, rbx
                jmp heapify_loop

        exit_DSA_heapify:
                pop rsi
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
                pop rax
                mov rsp, rbp
                pop rbp
                ret

        exit_pop_max_loop:
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

heapify:
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

        ; DSA_BUILD_HEAP function. Argument : pointer to vector (rdi)
        ; Call DSA-Heapify on all the elements starting from index [last/2]
        call size_v
        mov r8, rax
        cmp r8, 0
        je exit_build_heap_loop
        sar r8, 1

        build_heap_loop:
                cmp r8, 0 
                jl exit_build_heap_loop
                mov rsi, r8
                call DSA_heapify
                add r8, -1
                jmp build_heap_loop

        exit_build_heap_loop:

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

heapsort:
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

        ; Argument : pointer to vector (rdi)
        ; BUILD_HEAP on array first. ('call heapify')
        ; DELETE_MAX on vector n times where n is initial number of elements.
        ; Increase size to original size, to get a sorted heap/vector
        call size_v
        mov r8, rax             ; r8 - stores size of vector
        mov r9, rax             ; r9 - loop counter (initialised to sz)
        call heapify            ; BUILD_HEAP from vector

        heapsort_loop:
                cmp r9, 1
                jl exit_heapsort_loop
                call pop_max
                add r9, -1
                jmp heapsort_loop

        exit_heapsort_loop:
                mov qword [rdi+8], r8         ; Resets the size of the vector to intial size (r8)

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