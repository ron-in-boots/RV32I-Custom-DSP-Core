.global _start
.text

_start:
    # --- INITIALIZATION ---
    addi x8, x0, 4      # x8 = 4 (Loop counter: N=4 taps)
    addi x3, x0, 0      # x3 = 0 (Accumulator: y[n])
    addi x1, x0, 3      # x1 = 3 (Weight: h)
    addi x2, x0, 5      # x2 = 5 (Sample: x)

loop:
    # CUSTOM INSTRUCTION: mac x3, x1, x2
    # Standard GCC doesn't know 'mac', so we inject the exact R-type machine code.
    # Funct7: 0000010, rs2: 00010, rs1: 00001, funct3: 000, rd: 00011, opcode: 0110011
    .word 0x042081b3

    addi x8, x8, -1     # Decrement loop counter
    bne x8, x0, loop    # If counter != 0, repeat loop

end: 
    jal x0, end         # Infinite halt loop