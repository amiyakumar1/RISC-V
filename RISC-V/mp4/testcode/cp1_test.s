test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    addi    x1, x0, -1
    addi    x3, x0, 100
    srli    x1, x1, 1
    div     x4, x1, x3
    rem     x4, x1, x3
    divu    x4, x1, x3
    remu    x4, x1, x3

    addi    x1, x0, -1
    addi    x3, x0, 100
    srli    x1, x1, 1
    rem     x4, x1, x3
    divu    x4, x1, x3
    remu    x4, x1, x3

    addi    x1, x0, 1
    addi    x2, x0, 2
    addi    x3, x0, 3
    addi    x4, x0, 4
    addi    x12, x0, 12

    div     x5, x12, x4

    addi    x1, x0, -1
    addi    x2, x0, 30
    addi    x3, x0, 100
    mul    x4, x1, x2
    mulh   x4, x2, x3
    mulhu  x4, x2, x1
    mulhsu x4, x4, x3
    mul    x4, x3, x1
    mul    x4, x2, x3
    div    x4, x1, x2
    divu   x4, x2, x3
    rem    x4, x2, x1
    remu   x4, x4, x3
    div    x4, x3, x1
    div    x4, x2, x3

    addi    x1, x0, -1
    addi    x2, x0, 30
    addi    x3, x0, 100
    div     x4, x1, x0
    div     x4, x0, x1
    div     x4, x2, x0
    div     x4, x0, x2
    div     x4, x3, x0
    div     x4, x0, x3

    divu     x4, x1, x0
    divu     x4, x0, x1
    divu     x4, x2, x0
    divu     x4, x0, x2
    divu     x4, x3, x0
    divu     x4, x0, x3

    rem     x4, x1, x0
    rem     x4, x0, x1
    rem     x4, x2, x0
    rem     x4, x0, x2
    rem     x4, x3, x0
    rem     x4, x0, x3

    remu     x4, x1, x0
    remu     x4, x0, x1
    remu     x4, x2, x0
    remu     x4, x0, x2
    remu     x4, x3, x0
    remu     x4, x0, x3

    srli    x1, x1, 1
    div     x4, x1, x3
    rem     x4, x1, x3
    divu    x4, x1, x3
    remu    x4, x1, x3

    div     x4, x3, x1
    rem     x4, x3, x1
    divu    x4, x3, x1
    remu    x4, x3, x1

    addi    x30, x0, 1
    div     x4, x1, x1
    div     x4, x1, x30
    divu     x4, x1, x1
    divu     x4, x1, x30
    rem     x4, x1, x1
    rem     x4, x1, x30
    remu     x4, x1, x1
    remu     x4, x1, x30

    auipc	x6,0x4
    addi	x6,x6,868 # 40004364 <_data_vma_end>
    auipc	x7,0x5
    addi	x7,x7,-1224 # 40004b40 <_bss_vma_end>

initbss_loop:
    sw	    x0,0(x6)
    addi	x6,x6,4
    bltu	x6,x7,initbss_loop

load_store_test:
    lw x1, bad
    lh x2, bad
    lhu x3, bad
    lb x4, bad
    lbu x5, bad

    la x1, test1
    lw x10, bad
    sw x10, 0(x1)

    lw x2, 0(x1)

    add x2, x0, x0
    
    lh x2, 0(x1)
    lh x2, 2(x1)

    add x2, x0, x0

    lhu x2, 0(x1)
    lhu x2, 2(x1)

    add x2, x0, x0

    lb x2, 0(x1)
    lb x2, 1(x1)
    lb x2, 2(x1)
    lb x2, 3(x1)

    add x2, x0, x0

    lbu x2, 0(x1)
    lbu x2, 1(x1)
    lbu x2, 2(x1)
    lbu x2, 3(x1)

    add x2, x0, 10

    j next

next:
    lw	x10, good     
    sb x10, 0(x1)
    sb x10, 1(x1)
    sb x10, 2(x1)
    sb x10, 3(x1)

    lw x10, bad
    sh x10, 2(x1)
    sh x10, 0(x1)

    lw x10, good
     
    sw x10, 0(x1)

    lw x11, 0(x1)
     
other_instructions_test:
    addi x1, x0, 23
    addi x2, x1, 15
    andi x3, x2, 38
    andi x3, x2, 37
    auipc x2, 2
    auipc x2, 14
    lui x3, 3456
    ori x2, x1, 16
    slli x2, x1, 4
    slti x1, x2, 4
    srli x2, x1, 8
    sltiu x1, x2, 6
    srai x3, x2, 5
    xori x4, x2, 46
    add x2, x4, 31
    # xor test
    and x5, x0, x0
    and x6, x0, x0
    and x7, x0, x0
    addi x5, x0, 31
    slli x5, x5, 3
    addi x6, x0, 7
    slli x5, x5, 20
    xor x7, x6, x5
    xor x7, x7, x5
    # sub test
    sub x7, x7, x6
    sub x7, x5, x6
    addi x7, x0, 3
    sll  x7, x7, 31
    sll  x7, x7, 1
    srl  x7, x7, 31
    srl  x7, x7, 2
    addi x7, x0, 3
    sll  x7, x7, 31
    sra  x7, x7, 5
    sra x7, x7, 30
    addi x5, x0, 3
    sll  x5, x5, 31
    addi x6, x0, 1
    sltu x7, x5, x6
    slt  x7, x5, x6
    addi x5, x0, 21
    addi x6, x0, 7
    or   x7, x5, x6
    and x7, x5, x6
    add x7, x5, x5

extra_test:
    addi x0, x0, 0
    addi x0, x1, 5
    addi x1, x0, 5
    addi x2, x1, 5
    add  x2, x1, x2
    add  x3, x2, x1
    add  x4, x3, x1
    add  x4, x4, x4

    xori x0, x0, 0
    xori x0, x1, 5
    xori x1, x0, 5
    xori x2, x1, 5
    xor  x2, x1, x2
    xor  x3, x2, x1
    xor  x4, x3, x1
    xor  x4, x4, x4

    ori x0, x0, 0
    ori x0, x1, 5
    ori x1, x0, 5
    ori x2, x1, 5
    or  x2, x1, x2
    or  x3, x2, x1
    or  x4, x3, x1
    or  x4, x4, x4

    slli x0, x0, 0
    slli x0, x1, 5
    slli x1, x0, 5
    slli x2, x1, 5
    sll  x2, x1, x2
    sll  x3, x2, x1
    sll  x4, x3, x1
    sll  x4, x4, x4

    j jumping_test

jumping_test:
jump_1:
    call call_target
    j jump_4
jump_2:
    call call_target
    j jump_3
jump_3:
    call call_target
    j jump_5
jump_4:
    call call_target
    j jump_2
jump_5:
    call call_target
    j jump_6
jump_6:
    call call_target
    j jump_7
jump_7:
    call call_target
    j jump_8
jump_8:
    call call_target
    j jump_9
jump_9:
    call call_target
    call call_target
    call call_target
    call call_target
    call call_target
    call call_target
    call call_target

pre_halt:
    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.    

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

call_target:
    addi x29, x0, 10
    jalr x0, x1, 0

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
test:       .word 0xffffffff
test1:      .word 0xabcd1234

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
