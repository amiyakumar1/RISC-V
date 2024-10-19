addi x1, x0, 23
nop
nop
nop
nop
nop
addi x2, x1, 15
nop
nop
nop
nop
nop
andi x3, x2, 38
nop
nop
nop
nop
nop
andi x3, x2, 37
nop
nop
nop
nop
nop
auipc x2, 2
nop
nop
nop
nop
nop
auipc x2, 14
nop
nop
nop
nop
nop
lui x3, 3456
nop
nop
nop
nop
nop
ori x2, x1, 16
nop
nop
nop
nop
nop
slli x2, x1, 4
nop
nop
nop
nop
nop
slti x1, x2, 4
nop
nop
nop
nop
nop
srli x2, x1, 8
nop
nop
nop
nop
nop
sltiu x1, x2, 6
nop
nop
nop
nop
nop
srai x3, x2, 5
nop
nop
nop
nop
nop
xori x4, x2, 46
nop
nop
nop
nop
nop
add x2, x4, 31
nop
nop
nop
nop
nop



// xor test
and x5, x0, x0
nop
nop
nop
nop
nop
and x6, x0, x0
nop
nop
nop
nop
nop
and x7, x0, x0
nop
nop
nop
nop
nop

addi x5, x0, 31
nop
nop
nop
nop
nop
slli x5, x5, 3
nop
nop
nop
nop
nop

addi x6, x0, 7
nop
nop
nop
nop
nop
slli x5, x5, 20
nop
nop
nop
nop
nop
xor x7, x6, x5
nop
nop
nop
nop
nop
xor x7, x7, x5
nop
nop
nop
nop
nop

//sub test
sub x7, x7, x6
nop
nop
nop
nop
nop

sub x7, x5, x6
nop
nop
nop
nop
nop

addi x7, x0, 3
nop
nop
nop
nop
nop
sll  x7, x7, 31
nop
nop
nop
nop
nop
sll  x7, x7, 1
nop
nop
nop
nop
nop
srl  x7, x7, 31
nop
nop
nop
nop
nop
srl  x7, x7, 2
nop
nop
nop
nop
nop

addi x7, x0, 3
nop
nop
nop
nop
nop
sll  x7, x7, 31
nop
nop
nop
nop
nop
sra  x7, x7, 5
nop
nop
nop
nop
nop
sra, x7, x7, 30
nop
nop
nop
nop
nop
addi x5, x0, 3
nop
nop
nop
nop
nop
sll  x5, x5, 31
nop
nop
nop
nop
nop
addi x6, x0, 1
nop
nop
nop
nop
nop

sltu x7, x5, x6
nop
nop
nop
nop
nop

slt  x7, x5, x6
nop
nop
nop
nop
nop


addi x5, x0, 21
nop
nop
nop
nop
nop

addi x6, x0, 7
nop
nop
nop
nop
nop

or   x7, x5, x6
nop
nop
nop
nop
nop

and x7, x5, x6
nop
nop
nop
nop
nop

add x7, x5, x5
nop
nop
nop
nop
nop

