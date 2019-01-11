#include <asm.h>
#include <regdef.h>
#include <ucas_cde.h>
//#include <cp0regdefs.h>

#define TEST_NUM 68

#define lab2_1  1
#define lab2_2  1
#define lab2_3  1
#define WAIT_C   10000

#define NORMAL_MODE_S  0xc001
#define SET_MODE_S     0x4000
#define CYCLE          25000000
#define KBT_SET        0x8        
#define KBT_HOUR       0x4
#define KBT_MIN        0x2
#define KBT_SEC        0x1

##s0, number
##s1, number adress 
##s2, exception use
##s3, score

	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
	j	locate
	nop

##avoid "j locate" not taken
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
    nop

##avoid cpu run error
.org 0x0ec
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
.org 0x100
test_finish:
    addiu t0, t0, 1
    li t1, 0xff
    LI (t2, UART_ADDR)
    sw t1, 0x0(t2)
    b test_finish
    nop
##avoid cpu run error
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
/*
 *  exception handle
 */
.org 0x380
1:  
    # -- Interrupt Off --
    mfc0  k0, CP0_STATUS   
    lui   t0, 0xffff 
    ori   t0, 0xfffe
    and   k0, k0, t0       # Set IE bit to 0
    mtc0  k0, CP0_STATUS
    nop     
    # -- Interrupt Off --
    addi  t0, zero, 4  
    mtc0  t0, CP0_COUNT 
    nop 
    # -- judge the type of Interrupt --
    mfc0  k1, CP0_CAUSE
    and   k1, k1, k0
    andi  t1, k1, 0x8000
    bne   t1, zero, time_irq
    nop
    andi  t1, k1, 0x4000
    bne   t1, zero, set_mode
    nop
    mfc0  k0, CP0_EPC
    jr    k0
    nop


handle_finish:
    mtc0   zero, CP0_COUNT
    nop
clk_return:
    mtc0   k0,   CP0_STATUS
    nop
    jr     ra
    nop

time_irq:
    # load the address of num confreg
    li     k1,   NUM_ADDR
    lw     k0,   0(k1)
    jal    convert
    nop
    nop
    sw     k0,   0(k1)
    # Reset
    li     k0,   CYCLE
    mtc0   k0,   CP0_COMPARE
    nop
    mtc0   zero, CP0_CAUSE
    nop
    mfc0   ra,   CP0_EPC
    li     k0,   NORMAL_MODE_S
    j      clk_return
    nop
    nop

set_mode:
    mtc0   zero, CP0_COUNT
    nop
    mtc0   zero, CP0_CAUSE
    nop
    li     k0,   CYCLE
    mtc0   k0,   CP0_COMPARE
    nop

# wait for set-key button to disappear
set_delay:
    mfc0   k0,   CP0_CAUSE
    andi   k0,   0x4000
    xori   k0,   0x4000
    beq    k0,   zero, set_delay
    nop
    nop
d1:
    li     t0, 5000000
d2:
    addi   t0, -1
    bne    t0, zero, d2
    nop
read:
    li     t1, BTN_KEY_ADDR
    lw     k0, 0(t1)
    beq    k0, zero, read      # if equal to 0, no button is touched
    nop
    li     t2, KBT_HOUR        # load the value of hour KBT 
    beq    k0, t2, h_1_jal     # if equal, then go to hour+1
    nop
    li     t2, KBT_MIN         # load the value of minite KBT
    beq    k0, t2, m_1_jal     # if equal, then go to minite+1
    nop
    li     t2, KBT_SEC         # load the value of second KBT
    beq    k0, t2, s_1_jal     # if equal, then go to second+1
    nop
    li     t2, KBT_SET         # load the kbt value of SET
    beq    k0, t2, c_to_normal # if equal again, go to wait set KBT disappear
    nop
    j      d1                  # Otherwise, keep reading
    nop

c_to_normal:
    li     t2, KBT_SET
    li     t1, BTN_KEY_ADDR
    lw     t1, 0(t1)
    beq    t1, t2, c_to_normal
    nop  
    li     k0,   CYCLE
    mtc0   k0,   CP0_COMPARE
    nop
    mtc0   zero, CP0_CAUSE
    nop
    mfc0   ra,   CP0_EPC
    li     k0,   NORMAL_MODE_S  
    j      handle_finish  
    nop

h_1_jal:
    jal    hour_1
    nop
    li     t0, NUM_ADDR
    sw     k0, 0(t0)
    j      d1
    nop
    
m_1_jal:
    jal    minute_1
    nop
    li     t0, NUM_ADDR
    sw     k0, 0(t0)
    j      d1
    nop

s_1_jal:
    jal    second_1
    nop
    li     t0, NUM_ADDR
    sw     k0, 0(t0)
    j      d1
    nop

convert:
    .set noreorder

    andi  t0, k0, 0x000f  # sec lo
    andi  t1, k0, 0x00f0  # sec hi
    srl   t1, t1, 0x4   
    andi  t2, k0, 0x0f00  # min lo
    srl   t2, t2, 0x8
    andi  t3, k0, 0xf000  # min hi
    srl   t3, t3, 0xc
    lui   t4, 0x000f
    and   t4, k0, t4      # hour lo
    srl   t4, t4, 0x10
    lui   t5, 0x00f0
    and   t5, k0, t5      # hour hi
    srl   t5, t5, 0x14
    
    li    t7, 0x9
    beq   t0, t7, seclo_co  
    addiu k0, k0, 0x1     # delay slot, sec+1
    j     ret_to_ra
    nop
    nop

seclo_co:
    .set noreorder
    addi  k0, k0, -10     #set sec_lo to zero
    addiu t1, t1, 0x1     #sec_hi_temp+1
    li    t6, 0x6
    beq   t1, t6, sechi_co
    addiu k0, k0, 0x10    #delay slot, sechi+1
    j     ret_to_ra
    nop
    
sechi_co:
    .set noreorder
    addi  k0, k0, -96     #set sec_hi to zero   
    addiu t2, t2, 0x1     #min_lo_temp+1
    li    t7, 0xa
    beq   t2, t7, minlo_co
    addiu k0, k0, 0x100   #delay slot, min_lo+1
    j     ret_to_ra
    nop
    
minlo_co:
    .set noreorder
    addi  k0, k0, -2560   #set min_lo to zero
    addiu t3, t3, 0x1     #min_hi_temp+1
    beq   t3, t6, minhi_co
    addiu k0, k0, 0x1000  #delay slot, min_hi+1
    j     ret_to_ra
    nop
    
minhi_co:
    .set noreorder
    addi  k0, k0, -24576  #set min_hi to zero
    addiu t4, t4, 0x1     #hour_lo_temp+1
    lui   s0, 0x1
    beq   t4, t7, hourlo_co
    addu  k0, k0, s0      #delay slot, hour_lo+1,  9 to 10
    li    s1, 0x4
    li    s2, 0x2
    beq   t4, s1, hourhi_co  #hour_lo is 4
    nop
    j     ret_to_ra
    nop

hourlo_co:
    .set noreorder
    li    s3, -655360
    add   k0, k0, s3      #set hour_lo to zero
    lui   s4, 0x0010
    add   k0, k0, s4      #hour_hi+1
    j     ret_to_ra
    nop


hourhi_co:
    .set noreorder
    bne   s2, t5, ret_to_ra
    nop
    li    s0, -2359296
    add   k0, k0, s0      #set hour to zero
    j     ret_to_ra 
    nop
    nop
    
ret_to_ra:
    .set noreorder
    jr ra
    nop
    nop


hour_1:
    .set noreorder
    li    k1, NUM_ADDR
    lw    k0, 0(k1)
    lui   t4, 0x000f
    and   t4, k0, t4      #hour lo
    srl   t4, t4, 0x10
    lui   t5, 0x00f0
    and   t5, k0, t5      #hour hi
    srl   t5, t5, 0x14
    
    li    t2, 0xa
    li    t3, 0x4
    lui   s0, 0x1
    addiu t4, t4, 0x1
    beq   t4, t2, hourlo_co
    addu  k0, k0, s0         #delay slot, hour_lo+1,  9 to 10
    li    s1, 0x4
    li    s2, 0x2
    beq   t4, s1, hourhi_co  #hour_lo is 4
    nop
    j     ret_to_ra
    nop
    
    
minute_1:
    .set noreorder
    li    k1, NUM_ADDR
    lw    k0, 0(k1)
    andi  t2, k0, 0x0f00  #min lo
    srl   t2, t2, 0x8
    andi  t3, k0, 0xf000  #min hi
    srl   t3, t3, 0xc
    
    li    t6, 0x6
    li    t7, 0xa
    addiu t2, t2, 0x1
    beq   t2, t7, minlo
    addiu k0, k0, 0x100   #delay slot, min_lo+1
    j     ret_to_ra
    nop

minlo:
    .set noreorder
    addi  k0, k0, -2560   #set min_lo to zero
    addiu t3, t3, 0x1     #min_hi_temp+1
    beq   t3, t6, minhi
    addiu k0, k0, 0x1000  #delay slot, min_hi+1
    j     ret_to_ra
    nop
    
minhi:
    .set noreorder
    addi  k0, k0, -24576  #set min_hi to zero
    j     ret_to_ra
    nop
    
second_1:
    .set noreorder
    li    k1, NUM_ADDR
    lw    k0, 0(k1)
    andi  t0, k0, 0x000f  #sec lo
    andi  t1, k0, 0x00f0  #sec hi
    srl   t1, t1, 0x4   

    li    t6, 0x6
    li    t7, 0xa
    addiu t0, t0, 0x1
    beq   t0, t7, seclo
    addiu k0, k0, 0x1     #delay slot, seclo+1
    j     ret_to_ra
    nop
    
seclo:
    .set noreorder
    addi  k0, k0, -10     #set sec_lo to zero
    addiu t1, t1, 0x1     #sec_hi_temp+1
    beq   t1, t6, sechi
    addiu k0, k0, 0x10    #delay slot, sechi+1
    j     ret_to_ra
    nop
    
sechi:
    .set noreorder
    addi  k0, k0, -96     #set sec_hi to zero   
    j     ret_to_ra
    nop

locate:
	.set noreorder
	nop
l111:	
    nop
    beq  zero, zero, l111
    nop
    nop
