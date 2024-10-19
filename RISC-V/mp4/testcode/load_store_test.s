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

    add x2, x0, x0


    lw x10, good
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


    ######################################################## code from above is just this
    auipc	x1,0x0
    nop
    nop
    nop
    nop
    nop
    lw	x1,244(x1) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    auipc	x2,0x0
    nop
    nop
    nop
    nop
    nop
    lh	x2,236(x2) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    auipc	x3,0x0
    nop
    nop
    nop
    nop
    nop
    lhu	x3,228(x3) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    auipc	x4,0x0
    nop
    nop
    nop
    nop
    nop
    lb	x4,220(x4) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    auipc	x5,0x0
    nop
    nop
    nop
    nop
    nop
    lbu	x5,212(x5) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    auipc	x1,0x0
    nop
    nop
    nop
    nop
    nop
    addi	x1,x1,224 # 40000108 <test1>
    nop
    nop
    nop
    nop
    nop
    auipc	x10,0x0
    nop
    nop
    nop
    nop
    nop
    lw	x10,196(x10) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    sw	x10,0(x1)
    nop
    nop
    nop
    nop
    nop
    lw	x2,0(x1)
    nop
    nop
    nop
    nop
    nop
    add	x2,x0,x0
    nop
    nop
    nop
    nop
    nop
    lh	x2,0(x1)
    nop
    nop
    nop
    nop
    nop
    lh	x2,2(x1)
    nop
    nop
    nop
    nop
    nop
    add	x2,x0,x0
    nop
    nop
    nop
    nop
    nop
    lhu	x2,0(x1)
    nop
    nop
    nop
    nop
    nop
    lhu	x2,2(x1)
    nop
    nop
    nop
    nop
    nop
    add	x2,x0,x0
    nop
    nop
    nop
    nop
    nop
    lb	x2,0(x1)
    nop
    nop
    nop
    nop
    nop
    lb	x2,1(x1)
    nop
    nop
    nop
    nop
    nop
    lb	x2,2(x1)
    nop
    nop
    nop
    nop
    nop
    lb	x2,3(x1)
    nop
    nop
    nop
    nop
    nop
    add	x2,x0,x0
    nop
    nop
    nop
    nop
    nop
    lbu	x2,0(x1)
    nop
    nop
    nop
    nop
    nop
    lbu	x2,1(x1)
    nop
    nop
    nop
    nop
    nop
    lbu	x2,2(x1)
    nop
    nop
    nop
    nop
    nop
    lbu	x2,3(x1)
    nop
    nop
    nop
    nop
    nop
    add	x2,x0,x0
    nop
    nop
    nop
    nop
    nop
    auipc	x10,0x0
    nop
    nop
    nop
    nop
    nop
    lw	x10,124(x10) # 40000100 <good>
    nop
    nop
    nop
    nop
    nop
    sb	x10,0(x1)
    nop
    nop
    nop
    nop
    nop
    sb	x10,1(x1)
    nop
    nop
    nop
    nop
    sb	x10,2(x1)
    nop
    nop
    nop
    nop
    nop
    sb	x10,3(x1)
    nop
    nop
    nop
    nop
    nop
    auipc	x10,0x0
    nop
    nop
    nop
    nop
    nop
    lw	x10,88(x10) # 400000f4 <_text_vma_end>
    nop
    nop
    nop
    nop
    nop
    sh	x10,2(x1)
    nop
    nop
    nop
    nop
    sh	x10,0(x1)
    nop
    nop
    nop
    nop
    nop
    auipc	x10,0x0
    nop
    nop
    nop
    nop
    nop
    lw	x10,84(x10) # 40000100 <good>
    nop
    nop
    nop
    nop
    nop
    sw	x10,0(x1)
    nop
    nop
    nop
    nop
    nop
    lw	x11,0(x1)
########################################################
