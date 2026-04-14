.global _start
.text

_start:
    # --- INITIALIZATION ---
    addi x8, x0, 4      # outer loop counter
    addi x3, x0, 0      # accumulator
    addi x1, x0, 3      # weight

outer_loop:
    addi x2, x0, 5      # sample (inner loop counter)
    
inner_loop:
    add x3, x3, x1      # y[n] += h
    addi x2, x2, -1     # decrement inner
    bne x2, x0, inner_loop 

    addi x8, x8, -1     # decrement outer
    bne x8, x0, outer_loop 

end: 
    jal x0, end         # infinite halt loop