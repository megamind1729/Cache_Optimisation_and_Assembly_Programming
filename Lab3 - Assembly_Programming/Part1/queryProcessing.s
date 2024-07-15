.data
    newline: .asciiz "\n"
    space: .asciiz " "

.text
.globl main

main:
# Taking input n (number of elements in array) and storing in $s0 
input_n:
    li $v0, 5
    syscall
    move $s0, $v0           # $s0 = n

    # Allocating memory for n elements (4*n bytes)
    mul $a0, $s0, 4
    li $v0, 9
    syscall
    move $s2, $v0           # $s2 = base address of array 

    mul $a0, $s0, 4
    li $v0, 9
    syscall
    move $s3, $v0           # $s3 = base address of copy of array

# Inputs the n elements of the array
input_n_elements:
    li $t0, 0               # Loop index
    move $t1, $s2           # Address where we want to store the input  
    input_element_loop:
        li $v0, 5
        syscall
        sw $v0, 0($t1)
        addi $t1, $t1, 4
        addi $t0, $t0, 1
        bne $t0, $s0, input_element_loop
    
    move $a0, $s2           # $a0 = base address of array 
    li $a1, 0               # $a1 = 0 (left index)
    move $a3, $s0
    addi $a3, $a3, -1       # $a3 = n-1 (right index)
    jal mergesort

# Takes input q (number of queries) and storing in $s1
input_q:
    li $v0, 5
    syscall
    move $s1, $v0                # $s1 = q
    
    # Allocate memory for q outputs 
    mul $a0, $s1, 4
    li $v0, 9
    syscall
    move $s4, $v0

# Inputs the q queries, 
input_q_elements_and_store_results:
    li $t0, 0               # Loop index
    move $t1, $s4           # Address where we want to store the input  
    input_query_loop:
        li $v0, 5
        syscall
        move $a3, $v0
        
        move $a0, $s2
        li $a1, 0
        addi $a2, $s0, -1
        jal binary_search
        
        sw $v0, 0($t1)
        addi $t1, $t1, 4
        addi $t0, $t0, 1
        bne $t0, $s1, input_query_loop
        
    # Printing the output array
    move $a0, $s4
    move $a1, $s1
    jal print_array
    j exit_program
    
# Prints the array with elements on different lines
# $a0 - base address, $a1 - length of array
print_array:
    li $t0, 0       # Initialize loop counter = 0
    move $t1, $a0   # Copy the base address of the array to $t1
    move $t2, $a0
    print_loop:
        lw $a0, 0($t1)  # Load the value from the array element
        li $v0, 1        # syscall code for printing an integer
        syscall

        li $v0, 4        # syscall code for printing a string
        la $a0, newline  # Load the newline string
        syscall

        addi $t1, $t1, 4  # Move to the next element in the array
        addi $t0, $t0, 1  # Increment loop counter
        bne $t0, $a1, print_loop  # Check loop condition

    move $a0, $t2 
    jr $ra

# Binary search (Searches for the query in the sorted array, -1 if not present, index of first occurrence if present)
# $a0 - base address, $a1 - left index, $a2 - right index, $a3 - x (element to be searched)
# Do not use $t0 and $t1 as temporary variables here.
binary_search:
    addi $sp, $sp, -8
    sw $a1, 0($sp)
    sw $a2, 4($sp)

    mul $t2, $a1, 4
    add $t2, $t2, $a0
    lw $t3, 0($t2)                  # $t3 = arr[left]
    bgt $t3, $a3, end1              # if (arr[left] > x) return -1;
    beq $t3, $a3, end2              # if (arr[left] == x) return 0;
    mul $t4, $a2, 4
    add $t4, $t4, $a0
    lw $t5, 0($t4)                  # $t5 = arr[right]
    blt $t5, $a3, end1              # if (arr[right] < x)  return -1;

    # Enters loop only if arr[left] < x and arr[right] >= x
    binary_search_loop:
        add $t6, $a1, $a2
        srl $t6, $t6, 1             # mid = (left + right)/2
        mul $t7, $t6, 4
        add $t7, $t7, $a0
        lw $t8, 0($t7)
        
        beq $t6, $a1, end_binary_search_loop 
        bge $t8, $a3, left_half
        blt $t8, $a3, right_half

    end_binary_search_loop:

    mul $t2, $a2, 4
    add $t2, $t2, $a0
    lw $t3, 0($t2)
    bne $t3, $a3, end1
    j end3

    left_half:
        move $a2, $t6
        j binary_search_loop
    right_half:
        move $a1, $t6
        j binary_search_loop
    end1:
        li $v0, -1
        j end_binsearch_function
    end2:
        li $v0, 0
        j end_binsearch_function
    end3:
        move $v0, $a2
        j end_binsearch_function

    end_binsearch_function:
        lw $a1, 0($sp)
        lw $a2, 4($sp)
        addi $sp, $sp, 8
        jr $ra

# Exiting program
exit_program:
    li $v0, 10
    syscall

# Mergesorts the array
# $a0 - base address, $a1 - left index, $a3 - right index
# We do not have to store $a0 in stack since it is not changed in recursive calls of mergesort.
mergesort:
    addi $sp, $sp, -16       # Allocating memory in stack (Size 12 for now)
    sw $ra, 0($sp)
    sw $a1, 4($sp)
    sw $a3, 8($sp)

    # Base case: if length of array <= 1, end mergesort.
    bge $a1, $a3, mergesort_end

    # Calculating middle index and storing in $a2
    add $a2, $a1, $a3
    srl $a2, $a2, 1
    sw $a2, 12($sp)

    # Recursive call for left half array
    move $a3, $a2
    jal mergesort
    lw $a3, 8($sp)                  
    lw $a2, 12($sp)

    # Recursive call for right half array
    move $a1, $a2
    addi $a1, $a1, 1 
    jal mergesort
    lw $a1, 4($sp)
    lw $a2, 12($sp)
    
    # Merges the two sorted arrays
    jal merge_arrays

mergesort_end:
    lw $ra, 0($sp)
    lw $a1, 4($sp) 
    lw $a3, 8($sp)
    lw $a2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

# Merges two sorted arrays
# $a0 - base address, $a1 - left index, $a2 - middle index, $a3 - right index
merge_arrays:
    addi $sp, $sp, -16       # Allocating memory in stack (Size 12 for now)
    sw $a1, 0($sp)
    sw $a2, 4($sp)
    sw $a3, 8($sp)
    sw $ra, 12($sp)
    
    mul $t1, $a1, 4
    add $t0, $t1, $a0       # $t0 - address of arr[left]
    add $t1, $t1, $s3       # $t1 - address of arrcopy[left] = leftarr[0]
    mul $t2, $a2, 4
    add $t2, $t2, $s3
    addi $t2, $t2, 4        # $t2 - address of arrcopy[mid+1] = rightarr[0]
    move $t7, $t2           # $t7 - same as $t2 (for comparing with $t1 after traversing through left half)
    mul $t3, $a3, 4
    add $t3, $t3, $s3
    addi $t3, $t3, 4        # $t3 - address of arrcopy[right+1]      
    move $t4, $a1           # $t4 - loop index which goes from $a1 to $a3
    addi $t5, $a3, 1

    # Copying into auxiliary array with base address $s2
    copy_loop:
        lw $t6, 0($t0)
        sw $t6, 0($t1)        
        addi $t0, $t0, 4
        addi $t1, $t1, 4
        addi $t4, $t4, 1
        bne $t4, $t5, copy_loop

    # Merging
    mul $t1, $a1, 4
    add $t0, $t1, $a0       # $t0 = address of arr[left]
    add $t1, $t1, $s3       # $t1 = address of arrcopy[left]
    mul $t4, $a3, 4
    add $t4, $t4, $a0
    addi $t4, $t4, 4        # $t4 = address of arr[right+1]

    merge_loop:
        bge $t0, $t4, end_merge_arrays
        beq $t1, $t7, copy_right
        beq $t2, $t3, copy_left
        lw $t5, 0($t1)
        lw $t6, 0($t2)
        ble $t5, $t6, copy_left
        bgt $t5, $t6, copy_right 

    copy_left:
        lw $t5, 0($t1)
        sw $t5, 0($t0)
        addi $t0, $t0, 4
        addi $t1, $t1, 4
        j merge_loop

    copy_right:
        lw $t6, 0($t2)
        sw $t6, 0($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, 4
        j merge_loop

    end_merge_arrays:
        lw $a1, 0($sp)
        lw $a2, 4($sp) 
        lw $a3, 8($sp)
        lw $ra, 12($sp)
        addi $sp, $sp, 16
        jr $ra

# Important note for recursive functions:  
# Make sure that all the argument registers have same value after the function executes.
# Temporary registers (eg: $s0 = n, $s1 = q) also, if they are being used again. 