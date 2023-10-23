
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ae70713          	addi	a4,a4,-1874 # 80008900 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	dcc78793          	addi	a5,a5,-564 # 80005e30 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc68f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3bc080e7          	jalr	956(ra) # 800024e8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8b450513          	addi	a0,a0,-1868 # 80010a40 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8a448493          	addi	s1,s1,-1884 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	93290913          	addi	s2,s2,-1742 # 80010ad8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	166080e7          	jalr	358(ra) # 80002332 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	ea4080e7          	jalr	-348(ra) # 8000207e <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	27c080e7          	jalr	636(ra) # 80002492 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	81650513          	addi	a0,a0,-2026 # 80010a40 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	80050513          	addi	a0,a0,-2048 # 80010a40 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	86f72023          	sw	a5,-1952(a4) # 80010ad8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	76e50513          	addi	a0,a0,1902 # 80010a40 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	246080e7          	jalr	582(ra) # 8000253e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	74050513          	addi	a0,a0,1856 # 80010a40 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	71c70713          	addi	a4,a4,1820 # 80010a40 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	6f278793          	addi	a5,a5,1778 # 80010a40 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	75c7a783          	lw	a5,1884(a5) # 80010ad8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6b070713          	addi	a4,a4,1712 # 80010a40 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6a048493          	addi	s1,s1,1696 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	66470713          	addi	a4,a4,1636 # 80010a40 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6ef72723          	sw	a5,1774(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	62878793          	addi	a5,a5,1576 # 80010a40 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6ac7a023          	sw	a2,1696(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	69450513          	addi	a0,a0,1684 # 80010ad8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c96080e7          	jalr	-874(ra) # 800020e2 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5da50513          	addi	a0,a0,1498 # 80010a40 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	b5a78793          	addi	a5,a5,-1190 # 80020fd8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5a07a823          	sw	zero,1456(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	32f72e23          	sw	a5,828(a4) # 800088c0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	540dad83          	lw	s11,1344(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4ea50513          	addi	a0,a0,1258 # 80010ae8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	38650513          	addi	a0,a0,902 # 80010ae8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	36a48493          	addi	s1,s1,874 # 80010ae8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	32a50513          	addi	a0,a0,810 # 80010b08 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0b67a783          	lw	a5,182(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	08273703          	ld	a4,130(a4) # 800088c8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0827b783          	ld	a5,130(a5) # 800088d0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	298a0a13          	addi	s4,s4,664 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	05048493          	addi	s1,s1,80 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	05098993          	addi	s3,s3,80 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	83c080e7          	jalr	-1988(ra) # 800020e2 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	22650513          	addi	a0,a0,550 # 80010b08 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fce7a783          	lw	a5,-50(a5) # 800088c0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fd47b783          	ld	a5,-44(a5) # 800088d0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fc473703          	ld	a4,-60(a4) # 800088c8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	1f8a0a13          	addi	s4,s4,504 # 80010b08 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fb048493          	addi	s1,s1,-80 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fb090913          	addi	s2,s2,-80 # 800088d0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	74e080e7          	jalr	1870(ra) # 8000207e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1c248493          	addi	s1,s1,450 # 80010b08 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f6f73b23          	sd	a5,-138(a4) # 800088d0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	13848493          	addi	s1,s1,312 # 80010b08 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	75e78793          	addi	a5,a5,1886 # 80022170 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	10e90913          	addi	s2,s2,270 # 80010b40 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	07250513          	addi	a0,a0,114 # 80010b40 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	68e50513          	addi	a0,a0,1678 # 80022170 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	03c48493          	addi	s1,s1,60 # 80010b40 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	02450513          	addi	a0,a0,36 # 80010b40 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	ff850513          	addi	a0,a0,-8 # 80010b40 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a3470713          	addi	a4,a4,-1484 # 800088d8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	94e080e7          	jalr	-1714(ra) # 80002828 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	f8e080e7          	jalr	-114(ra) # 80005e70 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fe2080e7          	jalr	-30(ra) # 80001ecc <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	8ae080e7          	jalr	-1874(ra) # 80002800 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	8ce080e7          	jalr	-1842(ra) # 80002828 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	ef8080e7          	jalr	-264(ra) # 80005e5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f06080e7          	jalr	-250(ra) # 80005e70 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	09c080e7          	jalr	156(ra) # 8000300e <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	740080e7          	jalr	1856(ra) # 800036ba <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	6de080e7          	jalr	1758(ra) # 80004660 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	fee080e7          	jalr	-18(ra) # 80005f78 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d20080e7          	jalr	-736(ra) # 80001cb2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	92f72c23          	sw	a5,-1736(a4) # 800088d8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	92c7b783          	ld	a5,-1748(a5) # 800088e0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	66a7b823          	sd	a0,1648(a5) # 800088e0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	72a48493          	addi	s1,s1,1834 # 80010f90 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	510a0a13          	addi	s4,s4,1296 # 80016d90 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	17848493          	addi	s1,s1,376
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	25e50513          	addi	a0,a0,606 # 80010b60 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	25e50513          	addi	a0,a0,606 # 80010b78 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	66648493          	addi	s1,s1,1638 # 80010f90 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	44498993          	addi	s3,s3,1092 # 80016d90 <tickslock>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	17848493          	addi	s1,s1,376
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1da50513          	addi	a0,a0,474 # 80010b90 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	18270713          	addi	a4,a4,386 # 80010b60 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e3a7a783          	lw	a5,-454(a5) # 80008850 <first.1688>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	e20080e7          	jalr	-480(ra) # 80002840 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a023          	sw	zero,-480(a5) # 80008850 <first.1688>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c00080e7          	jalr	-1024(ra) # 8000363a <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	11090913          	addi	s2,s2,272 # 80010b60 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	df278793          	addi	a5,a5,-526 # 80008854 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3b448493          	addi	s1,s1,948 # 80010f90 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	1ac90913          	addi	s2,s2,428 # 80016d90 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c04:	17848493          	addi	s1,s1,376
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a09d                	j	80001c74 <allocproc+0xa4>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	cd21                	beqz	a0,80001c82 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c3a:	c125                	beqz	a0,80001c9a <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c60:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c64:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c68:	00007797          	auipc	a5,0x7
    80001c6c:	c887a783          	lw	a5,-888(a5) # 800088f0 <ticks>
    80001c70:	16f4a623          	sw	a5,364(s1)
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    freeproc(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	ef4080e7          	jalr	-268(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	010080e7          	jalr	16(ra) # 80000c9e <release>
    return 0;
    80001c96:	84ca                	mv	s1,s2
    80001c98:	bff1                	j	80001c74 <allocproc+0xa4>
    freeproc(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	edc080e7          	jalr	-292(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff8080e7          	jalr	-8(ra) # 80000c9e <release>
    return 0;
    80001cae:	84ca                	mv	s1,s2
    80001cb0:	b7d1                	j	80001c74 <allocproc+0xa4>

0000000080001cb2 <userinit>:
{
    80001cb2:	1101                	addi	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	f14080e7          	jalr	-236(ra) # 80001bd0 <allocproc>
    80001cc4:	84aa                	mv	s1,a0
  initproc = p;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	c2a7b123          	sd	a0,-990(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cce:	03400613          	li	a2,52
    80001cd2:	00007597          	auipc	a1,0x7
    80001cd6:	b8e58593          	addi	a1,a1,-1138 # 80008860 <initcode>
    80001cda:	6928                	ld	a0,80(a0)
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	696080e7          	jalr	1686(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001ce4:	6785                	lui	a5,0x1
    80001ce6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce8:	6cb8                	ld	a4,88(s1)
    80001cea:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cee:	6cb8                	ld	a4,88(s1)
    80001cf0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf2:	4641                	li	a2,16
    80001cf4:	00006597          	auipc	a1,0x6
    80001cf8:	50c58593          	addi	a1,a1,1292 # 80008200 <digits+0x1c0>
    80001cfc:	15848513          	addi	a0,s1,344
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	138080e7          	jalr	312(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	50850513          	addi	a0,a0,1288 # 80008210 <digits+0x1d0>
    80001d10:	00002097          	auipc	ra,0x2
    80001d14:	34c080e7          	jalr	844(ra) # 8000405c <namei>
    80001d18:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1c:	478d                	li	a5,3
    80001d1e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f7c080e7          	jalr	-132(ra) # 80000c9e <release>
}
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <growproc>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	c84080e7          	jalr	-892(ra) # 800019c6 <myproc>
    80001d4a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4c:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d4e:	01204c63          	bgtz	s2,80001d66 <growproc+0x32>
  else if (n < 0)
    80001d52:	02094663          	bltz	s2,80001d7e <growproc+0x4a>
  p->sz = sz;
    80001d56:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d58:	4501                	li	a0,0
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d66:	4691                	li	a3,4
    80001d68:	00b90633          	add	a2,s2,a1
    80001d6c:	6928                	ld	a0,80(a0)
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	6be080e7          	jalr	1726(ra) # 8000142c <uvmalloc>
    80001d76:	85aa                	mv	a1,a0
    80001d78:	fd79                	bnez	a0,80001d56 <growproc+0x22>
      return -1;
    80001d7a:	557d                	li	a0,-1
    80001d7c:	bff9                	j	80001d5a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7e:	00b90633          	add	a2,s2,a1
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	660080e7          	jalr	1632(ra) # 800013e4 <uvmdealloc>
    80001d8c:	85aa                	mv	a1,a0
    80001d8e:	b7e1                	j	80001d56 <growproc+0x22>

0000000080001d90 <fork>:
{
    80001d90:	7179                	addi	sp,sp,-48
    80001d92:	f406                	sd	ra,40(sp)
    80001d94:	f022                	sd	s0,32(sp)
    80001d96:	ec26                	sd	s1,24(sp)
    80001d98:	e84a                	sd	s2,16(sp)
    80001d9a:	e44e                	sd	s3,8(sp)
    80001d9c:	e052                	sd	s4,0(sp)
    80001d9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	c26080e7          	jalr	-986(ra) # 800019c6 <myproc>
    80001da8:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	e26080e7          	jalr	-474(ra) # 80001bd0 <allocproc>
    80001db2:	10050b63          	beqz	a0,80001ec8 <fork+0x138>
    80001db6:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db8:	04893603          	ld	a2,72(s2)
    80001dbc:	692c                	ld	a1,80(a0)
    80001dbe:	05093503          	ld	a0,80(s2)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	7be080e7          	jalr	1982(ra) # 80001580 <uvmcopy>
    80001dca:	04054663          	bltz	a0,80001e16 <fork+0x86>
  np->sz = p->sz;
    80001dce:	04893783          	ld	a5,72(s2)
    80001dd2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd6:	05893683          	ld	a3,88(s2)
    80001dda:	87b6                	mv	a5,a3
    80001ddc:	0589b703          	ld	a4,88(s3)
    80001de0:	12068693          	addi	a3,a3,288
    80001de4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de8:	6788                	ld	a0,8(a5)
    80001dea:	6b8c                	ld	a1,16(a5)
    80001dec:	6f90                	ld	a2,24(a5)
    80001dee:	01073023          	sd	a6,0(a4)
    80001df2:	e708                	sd	a0,8(a4)
    80001df4:	eb0c                	sd	a1,16(a4)
    80001df6:	ef10                	sd	a2,24(a4)
    80001df8:	02078793          	addi	a5,a5,32
    80001dfc:	02070713          	addi	a4,a4,32
    80001e00:	fed792e3          	bne	a5,a3,80001de4 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e04:	0589b783          	ld	a5,88(s3)
    80001e08:	0607b823          	sd	zero,112(a5)
    80001e0c:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e10:	15000a13          	li	s4,336
    80001e14:	a03d                	j	80001e42 <fork+0xb2>
    freeproc(np);
    80001e16:	854e                	mv	a0,s3
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	d60080e7          	jalr	-672(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e20:	854e                	mv	a0,s3
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e7c080e7          	jalr	-388(ra) # 80000c9e <release>
    return -1;
    80001e2a:	5a7d                	li	s4,-1
    80001e2c:	a069                	j	80001eb6 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2e:	00003097          	auipc	ra,0x3
    80001e32:	8c4080e7          	jalr	-1852(ra) # 800046f2 <filedup>
    80001e36:	009987b3          	add	a5,s3,s1
    80001e3a:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e3c:	04a1                	addi	s1,s1,8
    80001e3e:	01448763          	beq	s1,s4,80001e4c <fork+0xbc>
    if (p->ofile[i])
    80001e42:	009907b3          	add	a5,s2,s1
    80001e46:	6388                	ld	a0,0(a5)
    80001e48:	f17d                	bnez	a0,80001e2e <fork+0x9e>
    80001e4a:	bfcd                	j	80001e3c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4c:	15093503          	ld	a0,336(s2)
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	a28080e7          	jalr	-1496(ra) # 80003878 <idup>
    80001e58:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5c:	4641                	li	a2,16
    80001e5e:	15890593          	addi	a1,s2,344
    80001e62:	15898513          	addi	a0,s3,344
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	fd2080e7          	jalr	-46(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e6e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e72:	854e                	mv	a0,s3
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e2a080e7          	jalr	-470(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e7c:	0000f497          	auipc	s1,0xf
    80001e80:	cfc48493          	addi	s1,s1,-772 # 80010b78 <wait_lock>
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d64080e7          	jalr	-668(ra) # 80000bea <acquire>
  np->parent = p;
    80001e8e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e0a080e7          	jalr	-502(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e9c:	854e                	mv	a0,s3
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d4c080e7          	jalr	-692(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ea6:	478d                	li	a5,3
    80001ea8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eac:	854e                	mv	a0,s3
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	df0080e7          	jalr	-528(ra) # 80000c9e <release>
}
    80001eb6:	8552                	mv	a0,s4
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	5a7d                	li	s4,-1
    80001eca:	b7f5                	j	80001eb6 <fork+0x126>

0000000080001ecc <scheduler>:
{
    80001ecc:	7139                	addi	sp,sp,-64
    80001ece:	fc06                	sd	ra,56(sp)
    80001ed0:	f822                	sd	s0,48(sp)
    80001ed2:	f426                	sd	s1,40(sp)
    80001ed4:	f04a                	sd	s2,32(sp)
    80001ed6:	ec4e                	sd	s3,24(sp)
    80001ed8:	e852                	sd	s4,16(sp)
    80001eda:	e456                	sd	s5,8(sp)
    80001edc:	e05a                	sd	s6,0(sp)
    80001ede:	0080                	addi	s0,sp,64
    80001ee0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee4:	00779a93          	slli	s5,a5,0x7
    80001ee8:	0000f717          	auipc	a4,0xf
    80001eec:	c7870713          	addi	a4,a4,-904 # 80010b60 <pid_lock>
    80001ef0:	9756                	add	a4,a4,s5
    80001ef2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	ca270713          	addi	a4,a4,-862 # 80010b98 <cpus+0x8>
    80001efe:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f00:	498d                	li	s3,3
        p->state = RUNNING;
    80001f02:	4b11                	li	s6,4
        c->proc = p;
    80001f04:	079e                	slli	a5,a5,0x7
    80001f06:	0000fa17          	auipc	s4,0xf
    80001f0a:	c5aa0a13          	addi	s4,s4,-934 # 80010b60 <pid_lock>
    80001f0e:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f10:	00015917          	auipc	s2,0x15
    80001f14:	e8090913          	addi	s2,s2,-384 # 80016d90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f20:	10079073          	csrw	sstatus,a5
    80001f24:	0000f497          	auipc	s1,0xf
    80001f28:	06c48493          	addi	s1,s1,108 # 80010f90 <proc>
    80001f2c:	a03d                	j	80001f5a <scheduler+0x8e>
        p->state = RUNNING;
    80001f2e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f32:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f36:	06048593          	addi	a1,s1,96
    80001f3a:	8556                	mv	a0,s5
    80001f3c:	00001097          	auipc	ra,0x1
    80001f40:	85a080e7          	jalr	-1958(ra) # 80002796 <swtch>
        c->proc = 0;
    80001f44:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d54080e7          	jalr	-684(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f52:	17848493          	addi	s1,s1,376
    80001f56:	fd2481e3          	beq	s1,s2,80001f18 <scheduler+0x4c>
      acquire(&p->lock);
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	c8e080e7          	jalr	-882(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE)
    80001f64:	4c9c                	lw	a5,24(s1)
    80001f66:	ff3791e3          	bne	a5,s3,80001f48 <scheduler+0x7c>
    80001f6a:	b7d1                	j	80001f2e <scheduler+0x62>

0000000080001f6c <sched>:
{
    80001f6c:	7179                	addi	sp,sp,-48
    80001f6e:	f406                	sd	ra,40(sp)
    80001f70:	f022                	sd	s0,32(sp)
    80001f72:	ec26                	sd	s1,24(sp)
    80001f74:	e84a                	sd	s2,16(sp)
    80001f76:	e44e                	sd	s3,8(sp)
    80001f78:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	a4c080e7          	jalr	-1460(ra) # 800019c6 <myproc>
    80001f82:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	bec080e7          	jalr	-1044(ra) # 80000b70 <holding>
    80001f8c:	c93d                	beqz	a0,80002002 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f90:	2781                	sext.w	a5,a5
    80001f92:	079e                	slli	a5,a5,0x7
    80001f94:	0000f717          	auipc	a4,0xf
    80001f98:	bcc70713          	addi	a4,a4,-1076 # 80010b60 <pid_lock>
    80001f9c:	97ba                	add	a5,a5,a4
    80001f9e:	0a87a703          	lw	a4,168(a5)
    80001fa2:	4785                	li	a5,1
    80001fa4:	06f71763          	bne	a4,a5,80002012 <sched+0xa6>
  if (p->state == RUNNING)
    80001fa8:	4c98                	lw	a4,24(s1)
    80001faa:	4791                	li	a5,4
    80001fac:	06f70b63          	beq	a4,a5,80002022 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb4:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fb6:	efb5                	bnez	a5,80002032 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fba:	0000f917          	auipc	s2,0xf
    80001fbe:	ba690913          	addi	s2,s2,-1114 # 80010b60 <pid_lock>
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	97ca                	add	a5,a5,s2
    80001fc8:	0ac7a983          	lw	s3,172(a5)
    80001fcc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	0000f597          	auipc	a1,0xf
    80001fd6:	bc658593          	addi	a1,a1,-1082 # 80010b98 <cpus+0x8>
    80001fda:	95be                	add	a1,a1,a5
    80001fdc:	06048513          	addi	a0,s1,96
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	7b6080e7          	jalr	1974(ra) # 80002796 <swtch>
    80001fe8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fea:	2781                	sext.w	a5,a5
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	97ca                	add	a5,a5,s2
    80001ff0:	0b37a623          	sw	s3,172(a5)
}
    80001ff4:	70a2                	ld	ra,40(sp)
    80001ff6:	7402                	ld	s0,32(sp)
    80001ff8:	64e2                	ld	s1,24(sp)
    80001ffa:	6942                	ld	s2,16(sp)
    80001ffc:	69a2                	ld	s3,8(sp)
    80001ffe:	6145                	addi	sp,sp,48
    80002000:	8082                	ret
    panic("sched p->lock");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	21650513          	addi	a0,a0,534 # 80008218 <digits+0x1d8>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	53a080e7          	jalr	1338(ra) # 80000544 <panic>
    panic("sched locks");
    80002012:	00006517          	auipc	a0,0x6
    80002016:	21650513          	addi	a0,a0,534 # 80008228 <digits+0x1e8>
    8000201a:	ffffe097          	auipc	ra,0xffffe
    8000201e:	52a080e7          	jalr	1322(ra) # 80000544 <panic>
    panic("sched running");
    80002022:	00006517          	auipc	a0,0x6
    80002026:	21650513          	addi	a0,a0,534 # 80008238 <digits+0x1f8>
    8000202a:	ffffe097          	auipc	ra,0xffffe
    8000202e:	51a080e7          	jalr	1306(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	21650513          	addi	a0,a0,534 # 80008248 <digits+0x208>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	50a080e7          	jalr	1290(ra) # 80000544 <panic>

0000000080002042 <yield>:
{
    80002042:	1101                	addi	sp,sp,-32
    80002044:	ec06                	sd	ra,24(sp)
    80002046:	e822                	sd	s0,16(sp)
    80002048:	e426                	sd	s1,8(sp)
    8000204a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	97a080e7          	jalr	-1670(ra) # 800019c6 <myproc>
    80002054:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b94080e7          	jalr	-1132(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000205e:	478d                	li	a5,3
    80002060:	cc9c                	sw	a5,24(s1)
  sched();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	f0a080e7          	jalr	-246(ra) # 80001f6c <sched>
  release(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c32080e7          	jalr	-974(ra) # 80000c9e <release>
}
    80002074:	60e2                	ld	ra,24(sp)
    80002076:	6442                	ld	s0,16(sp)
    80002078:	64a2                	ld	s1,8(sp)
    8000207a:	6105                	addi	sp,sp,32
    8000207c:	8082                	ret

000000008000207e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000207e:	7179                	addi	sp,sp,-48
    80002080:	f406                	sd	ra,40(sp)
    80002082:	f022                	sd	s0,32(sp)
    80002084:	ec26                	sd	s1,24(sp)
    80002086:	e84a                	sd	s2,16(sp)
    80002088:	e44e                	sd	s3,8(sp)
    8000208a:	1800                	addi	s0,sp,48
    8000208c:	89aa                	mv	s3,a0
    8000208e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	936080e7          	jalr	-1738(ra) # 800019c6 <myproc>
    80002098:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	b50080e7          	jalr	-1200(ra) # 80000bea <acquire>
  release(lk);
    800020a2:	854a                	mv	a0,s2
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	bfa080e7          	jalr	-1030(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020ac:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b0:	4789                	li	a5,2
    800020b2:	cc9c                	sw	a5,24(s1)

  sched();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	eb8080e7          	jalr	-328(ra) # 80001f6c <sched>

  // Tidy up.
  p->chan = 0;
    800020bc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c0:	8526                	mv	a0,s1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bdc080e7          	jalr	-1060(ra) # 80000c9e <release>
  acquire(lk);
    800020ca:	854a                	mv	a0,s2
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b1e080e7          	jalr	-1250(ra) # 80000bea <acquire>
}
    800020d4:	70a2                	ld	ra,40(sp)
    800020d6:	7402                	ld	s0,32(sp)
    800020d8:	64e2                	ld	s1,24(sp)
    800020da:	6942                	ld	s2,16(sp)
    800020dc:	69a2                	ld	s3,8(sp)
    800020de:	6145                	addi	sp,sp,48
    800020e0:	8082                	ret

00000000800020e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020e2:	7139                	addi	sp,sp,-64
    800020e4:	fc06                	sd	ra,56(sp)
    800020e6:	f822                	sd	s0,48(sp)
    800020e8:	f426                	sd	s1,40(sp)
    800020ea:	f04a                	sd	s2,32(sp)
    800020ec:	ec4e                	sd	s3,24(sp)
    800020ee:	e852                	sd	s4,16(sp)
    800020f0:	e456                	sd	s5,8(sp)
    800020f2:	0080                	addi	s0,sp,64
    800020f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020f6:	0000f497          	auipc	s1,0xf
    800020fa:	e9a48493          	addi	s1,s1,-358 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020fe:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002100:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002102:	00015917          	auipc	s2,0x15
    80002106:	c8e90913          	addi	s2,s2,-882 # 80016d90 <tickslock>
    8000210a:	a821                	j	80002122 <wakeup+0x40>
        p->state = RUNNABLE;
    8000210c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b8c080e7          	jalr	-1140(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000211a:	17848493          	addi	s1,s1,376
    8000211e:	03248463          	beq	s1,s2,80002146 <wakeup+0x64>
    if (p != myproc())
    80002122:	00000097          	auipc	ra,0x0
    80002126:	8a4080e7          	jalr	-1884(ra) # 800019c6 <myproc>
    8000212a:	fea488e3          	beq	s1,a0,8000211a <wakeup+0x38>
      acquire(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	aba080e7          	jalr	-1350(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002138:	4c9c                	lw	a5,24(s1)
    8000213a:	fd379be3          	bne	a5,s3,80002110 <wakeup+0x2e>
    8000213e:	709c                	ld	a5,32(s1)
    80002140:	fd4798e3          	bne	a5,s4,80002110 <wakeup+0x2e>
    80002144:	b7e1                	j	8000210c <wakeup+0x2a>
    }
  }
}
    80002146:	70e2                	ld	ra,56(sp)
    80002148:	7442                	ld	s0,48(sp)
    8000214a:	74a2                	ld	s1,40(sp)
    8000214c:	7902                	ld	s2,32(sp)
    8000214e:	69e2                	ld	s3,24(sp)
    80002150:	6a42                	ld	s4,16(sp)
    80002152:	6aa2                	ld	s5,8(sp)
    80002154:	6121                	addi	sp,sp,64
    80002156:	8082                	ret

0000000080002158 <reparent>:
{
    80002158:	7179                	addi	sp,sp,-48
    8000215a:	f406                	sd	ra,40(sp)
    8000215c:	f022                	sd	s0,32(sp)
    8000215e:	ec26                	sd	s1,24(sp)
    80002160:	e84a                	sd	s2,16(sp)
    80002162:	e44e                	sd	s3,8(sp)
    80002164:	e052                	sd	s4,0(sp)
    80002166:	1800                	addi	s0,sp,48
    80002168:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000216a:	0000f497          	auipc	s1,0xf
    8000216e:	e2648493          	addi	s1,s1,-474 # 80010f90 <proc>
      pp->parent = initproc;
    80002172:	00006a17          	auipc	s4,0x6
    80002176:	776a0a13          	addi	s4,s4,1910 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000217a:	00015997          	auipc	s3,0x15
    8000217e:	c1698993          	addi	s3,s3,-1002 # 80016d90 <tickslock>
    80002182:	a029                	j	8000218c <reparent+0x34>
    80002184:	17848493          	addi	s1,s1,376
    80002188:	01348d63          	beq	s1,s3,800021a2 <reparent+0x4a>
    if (pp->parent == p)
    8000218c:	7c9c                	ld	a5,56(s1)
    8000218e:	ff279be3          	bne	a5,s2,80002184 <reparent+0x2c>
      pp->parent = initproc;
    80002192:	000a3503          	ld	a0,0(s4)
    80002196:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	f4a080e7          	jalr	-182(ra) # 800020e2 <wakeup>
    800021a0:	b7d5                	j	80002184 <reparent+0x2c>
}
    800021a2:	70a2                	ld	ra,40(sp)
    800021a4:	7402                	ld	s0,32(sp)
    800021a6:	64e2                	ld	s1,24(sp)
    800021a8:	6942                	ld	s2,16(sp)
    800021aa:	69a2                	ld	s3,8(sp)
    800021ac:	6a02                	ld	s4,0(sp)
    800021ae:	6145                	addi	sp,sp,48
    800021b0:	8082                	ret

00000000800021b2 <exit>:
{
    800021b2:	7179                	addi	sp,sp,-48
    800021b4:	f406                	sd	ra,40(sp)
    800021b6:	f022                	sd	s0,32(sp)
    800021b8:	ec26                	sd	s1,24(sp)
    800021ba:	e84a                	sd	s2,16(sp)
    800021bc:	e44e                	sd	s3,8(sp)
    800021be:	e052                	sd	s4,0(sp)
    800021c0:	1800                	addi	s0,sp,48
    800021c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800021cc:	89aa                	mv	s3,a0
  if (p == initproc)
    800021ce:	00006797          	auipc	a5,0x6
    800021d2:	71a7b783          	ld	a5,1818(a5) # 800088e8 <initproc>
    800021d6:	0d050493          	addi	s1,a0,208
    800021da:	15050913          	addi	s2,a0,336
    800021de:	02a79363          	bne	a5,a0,80002204 <exit+0x52>
    panic("init exiting");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	07e50513          	addi	a0,a0,126 # 80008260 <digits+0x220>
    800021ea:	ffffe097          	auipc	ra,0xffffe
    800021ee:	35a080e7          	jalr	858(ra) # 80000544 <panic>
      fileclose(f);
    800021f2:	00002097          	auipc	ra,0x2
    800021f6:	552080e7          	jalr	1362(ra) # 80004744 <fileclose>
      p->ofile[fd] = 0;
    800021fa:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021fe:	04a1                	addi	s1,s1,8
    80002200:	01248563          	beq	s1,s2,8000220a <exit+0x58>
    if (p->ofile[fd])
    80002204:	6088                	ld	a0,0(s1)
    80002206:	f575                	bnez	a0,800021f2 <exit+0x40>
    80002208:	bfdd                	j	800021fe <exit+0x4c>
  begin_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	06e080e7          	jalr	110(ra) # 80004278 <begin_op>
  iput(p->cwd);
    80002212:	1509b503          	ld	a0,336(s3)
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	85a080e7          	jalr	-1958(ra) # 80003a70 <iput>
  end_op();
    8000221e:	00002097          	auipc	ra,0x2
    80002222:	0da080e7          	jalr	218(ra) # 800042f8 <end_op>
  p->cwd = 0;
    80002226:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000222a:	0000f497          	auipc	s1,0xf
    8000222e:	94e48493          	addi	s1,s1,-1714 # 80010b78 <wait_lock>
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	9b6080e7          	jalr	-1610(ra) # 80000bea <acquire>
  reparent(p);
    8000223c:	854e                	mv	a0,s3
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	f1a080e7          	jalr	-230(ra) # 80002158 <reparent>
  wakeup(p->parent);
    80002246:	0389b503          	ld	a0,56(s3)
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	e98080e7          	jalr	-360(ra) # 800020e2 <wakeup>
  acquire(&p->lock);
    80002252:	854e                	mv	a0,s3
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	996080e7          	jalr	-1642(ra) # 80000bea <acquire>
  p->xstate = status;
    8000225c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002260:	4795                	li	a5,5
    80002262:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002266:	00006797          	auipc	a5,0x6
    8000226a:	68a7a783          	lw	a5,1674(a5) # 800088f0 <ticks>
    8000226e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a2a080e7          	jalr	-1494(ra) # 80000c9e <release>
  sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	cf0080e7          	jalr	-784(ra) # 80001f6c <sched>
  panic("zombie exit");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	fec50513          	addi	a0,a0,-20 # 80008270 <digits+0x230>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2b8080e7          	jalr	696(ra) # 80000544 <panic>

0000000080002294 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	1800                	addi	s0,sp,48
    800022a2:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022a4:	0000f497          	auipc	s1,0xf
    800022a8:	cec48493          	addi	s1,s1,-788 # 80010f90 <proc>
    800022ac:	00015997          	auipc	s3,0x15
    800022b0:	ae498993          	addi	s3,s3,-1308 # 80016d90 <tickslock>
  {
    acquire(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	934080e7          	jalr	-1740(ra) # 80000bea <acquire>
    if (p->pid == pid)
    800022be:	589c                	lw	a5,48(s1)
    800022c0:	01278d63          	beq	a5,s2,800022da <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d8080e7          	jalr	-1576(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022ce:	17848493          	addi	s1,s1,376
    800022d2:	ff3491e3          	bne	s1,s3,800022b4 <kill+0x20>
  }
  return -1;
    800022d6:	557d                	li	a0,-1
    800022d8:	a829                	j	800022f2 <kill+0x5e>
      p->killed = 1;
    800022da:	4785                	li	a5,1
    800022dc:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022de:	4c98                	lw	a4,24(s1)
    800022e0:	4789                	li	a5,2
    800022e2:	00f70f63          	beq	a4,a5,80002300 <kill+0x6c>
      release(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9b6080e7          	jalr	-1610(ra) # 80000c9e <release>
      return 0;
    800022f0:	4501                	li	a0,0
}
    800022f2:	70a2                	ld	ra,40(sp)
    800022f4:	7402                	ld	s0,32(sp)
    800022f6:	64e2                	ld	s1,24(sp)
    800022f8:	6942                	ld	s2,16(sp)
    800022fa:	69a2                	ld	s3,8(sp)
    800022fc:	6145                	addi	sp,sp,48
    800022fe:	8082                	ret
        p->state = RUNNABLE;
    80002300:	478d                	li	a5,3
    80002302:	cc9c                	sw	a5,24(s1)
    80002304:	b7cd                	j	800022e6 <kill+0x52>

0000000080002306 <setkilled>:

void setkilled(struct proc *p)
{
    80002306:	1101                	addi	sp,sp,-32
    80002308:	ec06                	sd	ra,24(sp)
    8000230a:	e822                	sd	s0,16(sp)
    8000230c:	e426                	sd	s1,8(sp)
    8000230e:	1000                	addi	s0,sp,32
    80002310:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8d8080e7          	jalr	-1832(ra) # 80000bea <acquire>
  p->killed = 1;
    8000231a:	4785                	li	a5,1
    8000231c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	97e080e7          	jalr	-1666(ra) # 80000c9e <release>
}
    80002328:	60e2                	ld	ra,24(sp)
    8000232a:	6442                	ld	s0,16(sp)
    8000232c:	64a2                	ld	s1,8(sp)
    8000232e:	6105                	addi	sp,sp,32
    80002330:	8082                	ret

0000000080002332 <killed>:

int killed(struct proc *p)
{
    80002332:	1101                	addi	sp,sp,-32
    80002334:	ec06                	sd	ra,24(sp)
    80002336:	e822                	sd	s0,16(sp)
    80002338:	e426                	sd	s1,8(sp)
    8000233a:	e04a                	sd	s2,0(sp)
    8000233c:	1000                	addi	s0,sp,32
    8000233e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8aa080e7          	jalr	-1878(ra) # 80000bea <acquire>
  k = p->killed;
    80002348:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	950080e7          	jalr	-1712(ra) # 80000c9e <release>
  return k;
}
    80002356:	854a                	mv	a0,s2
    80002358:	60e2                	ld	ra,24(sp)
    8000235a:	6442                	ld	s0,16(sp)
    8000235c:	64a2                	ld	s1,8(sp)
    8000235e:	6902                	ld	s2,0(sp)
    80002360:	6105                	addi	sp,sp,32
    80002362:	8082                	ret

0000000080002364 <wait>:
{
    80002364:	715d                	addi	sp,sp,-80
    80002366:	e486                	sd	ra,72(sp)
    80002368:	e0a2                	sd	s0,64(sp)
    8000236a:	fc26                	sd	s1,56(sp)
    8000236c:	f84a                	sd	s2,48(sp)
    8000236e:	f44e                	sd	s3,40(sp)
    80002370:	f052                	sd	s4,32(sp)
    80002372:	ec56                	sd	s5,24(sp)
    80002374:	e85a                	sd	s6,16(sp)
    80002376:	e45e                	sd	s7,8(sp)
    80002378:	e062                	sd	s8,0(sp)
    8000237a:	0880                	addi	s0,sp,80
    8000237c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	648080e7          	jalr	1608(ra) # 800019c6 <myproc>
    80002386:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002388:	0000e517          	auipc	a0,0xe
    8000238c:	7f050513          	addi	a0,a0,2032 # 80010b78 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	85a080e7          	jalr	-1958(ra) # 80000bea <acquire>
    havekids = 0;
    80002398:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000239a:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239c:	00015997          	auipc	s3,0x15
    800023a0:	9f498993          	addi	s3,s3,-1548 # 80016d90 <tickslock>
        havekids = 1;
    800023a4:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023a6:	0000ec17          	auipc	s8,0xe
    800023aa:	7d2c0c13          	addi	s8,s8,2002 # 80010b78 <wait_lock>
    havekids = 0;
    800023ae:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b0:	0000f497          	auipc	s1,0xf
    800023b4:	be048493          	addi	s1,s1,-1056 # 80010f90 <proc>
    800023b8:	a0bd                	j	80002426 <wait+0xc2>
          pid = pp->pid;
    800023ba:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023be:	000b0e63          	beqz	s6,800023da <wait+0x76>
    800023c2:	4691                	li	a3,4
    800023c4:	02c48613          	addi	a2,s1,44
    800023c8:	85da                	mv	a1,s6
    800023ca:	05093503          	ld	a0,80(s2)
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	2b6080e7          	jalr	694(ra) # 80001684 <copyout>
    800023d6:	02054563          	bltz	a0,80002400 <wait+0x9c>
          freeproc(pp);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	79c080e7          	jalr	1948(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8b8080e7          	jalr	-1864(ra) # 80000c9e <release>
          release(&wait_lock);
    800023ee:	0000e517          	auipc	a0,0xe
    800023f2:	78a50513          	addi	a0,a0,1930 # 80010b78 <wait_lock>
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a8080e7          	jalr	-1880(ra) # 80000c9e <release>
          return pid;
    800023fe:	a0b5                	j	8000246a <wait+0x106>
            release(&pp->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	89c080e7          	jalr	-1892(ra) # 80000c9e <release>
            release(&wait_lock);
    8000240a:	0000e517          	auipc	a0,0xe
    8000240e:	76e50513          	addi	a0,a0,1902 # 80010b78 <wait_lock>
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	88c080e7          	jalr	-1908(ra) # 80000c9e <release>
            return -1;
    8000241a:	59fd                	li	s3,-1
    8000241c:	a0b9                	j	8000246a <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241e:	17848493          	addi	s1,s1,376
    80002422:	03348463          	beq	s1,s3,8000244a <wait+0xe6>
      if (pp->parent == p)
    80002426:	7c9c                	ld	a5,56(s1)
    80002428:	ff279be3          	bne	a5,s2,8000241e <wait+0xba>
        acquire(&pp->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7bc080e7          	jalr	1980(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    80002436:	4c9c                	lw	a5,24(s1)
    80002438:	f94781e3          	beq	a5,s4,800023ba <wait+0x56>
        release(&pp->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	860080e7          	jalr	-1952(ra) # 80000c9e <release>
        havekids = 1;
    80002446:	8756                	mv	a4,s5
    80002448:	bfd9                	j	8000241e <wait+0xba>
    if (!havekids || killed(p))
    8000244a:	c719                	beqz	a4,80002458 <wait+0xf4>
    8000244c:	854a                	mv	a0,s2
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	ee4080e7          	jalr	-284(ra) # 80002332 <killed>
    80002456:	c51d                	beqz	a0,80002484 <wait+0x120>
      release(&wait_lock);
    80002458:	0000e517          	auipc	a0,0xe
    8000245c:	72050513          	addi	a0,a0,1824 # 80010b78 <wait_lock>
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	83e080e7          	jalr	-1986(ra) # 80000c9e <release>
      return -1;
    80002468:	59fd                	li	s3,-1
}
    8000246a:	854e                	mv	a0,s3
    8000246c:	60a6                	ld	ra,72(sp)
    8000246e:	6406                	ld	s0,64(sp)
    80002470:	74e2                	ld	s1,56(sp)
    80002472:	7942                	ld	s2,48(sp)
    80002474:	79a2                	ld	s3,40(sp)
    80002476:	7a02                	ld	s4,32(sp)
    80002478:	6ae2                	ld	s5,24(sp)
    8000247a:	6b42                	ld	s6,16(sp)
    8000247c:	6ba2                	ld	s7,8(sp)
    8000247e:	6c02                	ld	s8,0(sp)
    80002480:	6161                	addi	sp,sp,80
    80002482:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002484:	85e2                	mv	a1,s8
    80002486:	854a                	mv	a0,s2
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	bf6080e7          	jalr	-1034(ra) # 8000207e <sleep>
    havekids = 0;
    80002490:	bf39                	j	800023ae <wait+0x4a>

0000000080002492 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	84aa                	mv	s1,a0
    800024a4:	892e                	mv	s2,a1
    800024a6:	89b2                	mv	s3,a2
    800024a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	51c080e7          	jalr	1308(ra) # 800019c6 <myproc>
  if (user_dst)
    800024b2:	c08d                	beqz	s1,800024d4 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024b4:	86d2                	mv	a3,s4
    800024b6:	864e                	mv	a2,s3
    800024b8:	85ca                	mv	a1,s2
    800024ba:	6928                	ld	a0,80(a0)
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	1c8080e7          	jalr	456(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c4:	70a2                	ld	ra,40(sp)
    800024c6:	7402                	ld	s0,32(sp)
    800024c8:	64e2                	ld	s1,24(sp)
    800024ca:	6942                	ld	s2,16(sp)
    800024cc:	69a2                	ld	s3,8(sp)
    800024ce:	6a02                	ld	s4,0(sp)
    800024d0:	6145                	addi	sp,sp,48
    800024d2:	8082                	ret
    memmove((char *)dst, src, len);
    800024d4:	000a061b          	sext.w	a2,s4
    800024d8:	85ce                	mv	a1,s3
    800024da:	854a                	mv	a0,s2
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	86a080e7          	jalr	-1942(ra) # 80000d46 <memmove>
    return 0;
    800024e4:	8526                	mv	a0,s1
    800024e6:	bff9                	j	800024c4 <either_copyout+0x32>

00000000800024e8 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e8:	7179                	addi	sp,sp,-48
    800024ea:	f406                	sd	ra,40(sp)
    800024ec:	f022                	sd	s0,32(sp)
    800024ee:	ec26                	sd	s1,24(sp)
    800024f0:	e84a                	sd	s2,16(sp)
    800024f2:	e44e                	sd	s3,8(sp)
    800024f4:	e052                	sd	s4,0(sp)
    800024f6:	1800                	addi	s0,sp,48
    800024f8:	892a                	mv	s2,a0
    800024fa:	84ae                	mv	s1,a1
    800024fc:	89b2                	mv	s3,a2
    800024fe:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	4c6080e7          	jalr	1222(ra) # 800019c6 <myproc>
  if (user_src)
    80002508:	c08d                	beqz	s1,8000252a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000250a:	86d2                	mv	a3,s4
    8000250c:	864e                	mv	a2,s3
    8000250e:	85ca                	mv	a1,s2
    80002510:	6928                	ld	a0,80(a0)
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	1fe080e7          	jalr	510(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000251a:	70a2                	ld	ra,40(sp)
    8000251c:	7402                	ld	s0,32(sp)
    8000251e:	64e2                	ld	s1,24(sp)
    80002520:	6942                	ld	s2,16(sp)
    80002522:	69a2                	ld	s3,8(sp)
    80002524:	6a02                	ld	s4,0(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
    memmove(dst, (char *)src, len);
    8000252a:	000a061b          	sext.w	a2,s4
    8000252e:	85ce                	mv	a1,s3
    80002530:	854a                	mv	a0,s2
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	814080e7          	jalr	-2028(ra) # 80000d46 <memmove>
    return 0;
    8000253a:	8526                	mv	a0,s1
    8000253c:	bff9                	j	8000251a <either_copyin+0x32>

000000008000253e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000253e:	715d                	addi	sp,sp,-80
    80002540:	e486                	sd	ra,72(sp)
    80002542:	e0a2                	sd	s0,64(sp)
    80002544:	fc26                	sd	s1,56(sp)
    80002546:	f84a                	sd	s2,48(sp)
    80002548:	f44e                	sd	s3,40(sp)
    8000254a:	f052                	sd	s4,32(sp)
    8000254c:	ec56                	sd	s5,24(sp)
    8000254e:	e85a                	sd	s6,16(sp)
    80002550:	e45e                	sd	s7,8(sp)
    80002552:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002554:	00006517          	auipc	a0,0x6
    80002558:	b7450513          	addi	a0,a0,-1164 # 800080c8 <digits+0x88>
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	032080e7          	jalr	50(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002564:	0000f497          	auipc	s1,0xf
    80002568:	b8448493          	addi	s1,s1,-1148 # 800110e8 <proc+0x158>
    8000256c:	00015917          	auipc	s2,0x15
    80002570:	97c90913          	addi	s2,s2,-1668 # 80016ee8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002574:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002576:	00006997          	auipc	s3,0x6
    8000257a:	d0a98993          	addi	s3,s3,-758 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000257e:	00006a97          	auipc	s5,0x6
    80002582:	d0aa8a93          	addi	s5,s5,-758 # 80008288 <digits+0x248>
    printf("\n");
    80002586:	00006a17          	auipc	s4,0x6
    8000258a:	b42a0a13          	addi	s4,s4,-1214 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	00006b97          	auipc	s7,0x6
    80002592:	d3ab8b93          	addi	s7,s7,-710 # 800082c8 <states.1732>
    80002596:	a00d                	j	800025b8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002598:	ed86a583          	lw	a1,-296(a3)
    8000259c:	8556                	mv	a0,s5
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	ff0080e7          	jalr	-16(ra) # 8000058e <printf>
    printf("\n");
    800025a6:	8552                	mv	a0,s4
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fe6080e7          	jalr	-26(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025b0:	17848493          	addi	s1,s1,376
    800025b4:	03248163          	beq	s1,s2,800025d6 <procdump+0x98>
    if (p->state == UNUSED)
    800025b8:	86a6                	mv	a3,s1
    800025ba:	ec04a783          	lw	a5,-320(s1)
    800025be:	dbed                	beqz	a5,800025b0 <procdump+0x72>
      state = "???";
    800025c0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c2:	fcfb6be3          	bltu	s6,a5,80002598 <procdump+0x5a>
    800025c6:	1782                	slli	a5,a5,0x20
    800025c8:	9381                	srli	a5,a5,0x20
    800025ca:	078e                	slli	a5,a5,0x3
    800025cc:	97de                	add	a5,a5,s7
    800025ce:	6390                	ld	a2,0(a5)
    800025d0:	f661                	bnez	a2,80002598 <procdump+0x5a>
      state = "???";
    800025d2:	864e                	mv	a2,s3
    800025d4:	b7d1                	j	80002598 <procdump+0x5a>
  }
}
    800025d6:	60a6                	ld	ra,72(sp)
    800025d8:	6406                	ld	s0,64(sp)
    800025da:	74e2                	ld	s1,56(sp)
    800025dc:	7942                	ld	s2,48(sp)
    800025de:	79a2                	ld	s3,40(sp)
    800025e0:	7a02                	ld	s4,32(sp)
    800025e2:	6ae2                	ld	s5,24(sp)
    800025e4:	6b42                	ld	s6,16(sp)
    800025e6:	6ba2                	ld	s7,8(sp)
    800025e8:	6161                	addi	sp,sp,80
    800025ea:	8082                	ret

00000000800025ec <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025ec:	711d                	addi	sp,sp,-96
    800025ee:	ec86                	sd	ra,88(sp)
    800025f0:	e8a2                	sd	s0,80(sp)
    800025f2:	e4a6                	sd	s1,72(sp)
    800025f4:	e0ca                	sd	s2,64(sp)
    800025f6:	fc4e                	sd	s3,56(sp)
    800025f8:	f852                	sd	s4,48(sp)
    800025fa:	f456                	sd	s5,40(sp)
    800025fc:	f05a                	sd	s6,32(sp)
    800025fe:	ec5e                	sd	s7,24(sp)
    80002600:	e862                	sd	s8,16(sp)
    80002602:	e466                	sd	s9,8(sp)
    80002604:	e06a                	sd	s10,0(sp)
    80002606:	1080                	addi	s0,sp,96
    80002608:	8b2a                	mv	s6,a0
    8000260a:	8bae                	mv	s7,a1
    8000260c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	3b8080e7          	jalr	952(ra) # 800019c6 <myproc>
    80002616:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002618:	0000e517          	auipc	a0,0xe
    8000261c:	56050513          	addi	a0,a0,1376 # 80010b78 <wait_lock>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	5ca080e7          	jalr	1482(ra) # 80000bea <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002628:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000262a:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000262c:	00014997          	auipc	s3,0x14
    80002630:	76498993          	addi	s3,s3,1892 # 80016d90 <tickslock>
        havekids = 1;
    80002634:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002636:	0000ed17          	auipc	s10,0xe
    8000263a:	542d0d13          	addi	s10,s10,1346 # 80010b78 <wait_lock>
    havekids = 0;
    8000263e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002640:	0000f497          	auipc	s1,0xf
    80002644:	95048493          	addi	s1,s1,-1712 # 80010f90 <proc>
    80002648:	a059                	j	800026ce <waitx+0xe2>
          pid = np->pid;
    8000264a:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000264e:	1684a703          	lw	a4,360(s1)
    80002652:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002656:	16c4a783          	lw	a5,364(s1)
    8000265a:	9f3d                	addw	a4,a4,a5
    8000265c:	1704a783          	lw	a5,368(s1)
    80002660:	9f99                	subw	a5,a5,a4
    80002662:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002666:	000b0e63          	beqz	s6,80002682 <waitx+0x96>
    8000266a:	4691                	li	a3,4
    8000266c:	02c48613          	addi	a2,s1,44
    80002670:	85da                	mv	a1,s6
    80002672:	05093503          	ld	a0,80(s2)
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	00e080e7          	jalr	14(ra) # 80001684 <copyout>
    8000267e:	02054563          	bltz	a0,800026a8 <waitx+0xbc>
          freeproc(np);
    80002682:	8526                	mv	a0,s1
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	4f4080e7          	jalr	1268(ra) # 80001b78 <freeproc>
          release(&np->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	610080e7          	jalr	1552(ra) # 80000c9e <release>
          release(&wait_lock);
    80002696:	0000e517          	auipc	a0,0xe
    8000269a:	4e250513          	addi	a0,a0,1250 # 80010b78 <wait_lock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	600080e7          	jalr	1536(ra) # 80000c9e <release>
          return pid;
    800026a6:	a09d                	j	8000270c <waitx+0x120>
            release(&np->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	5f4080e7          	jalr	1524(ra) # 80000c9e <release>
            release(&wait_lock);
    800026b2:	0000e517          	auipc	a0,0xe
    800026b6:	4c650513          	addi	a0,a0,1222 # 80010b78 <wait_lock>
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	5e4080e7          	jalr	1508(ra) # 80000c9e <release>
            return -1;
    800026c2:	59fd                	li	s3,-1
    800026c4:	a0a1                	j	8000270c <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026c6:	17848493          	addi	s1,s1,376
    800026ca:	03348463          	beq	s1,s3,800026f2 <waitx+0x106>
      if (np->parent == p)
    800026ce:	7c9c                	ld	a5,56(s1)
    800026d0:	ff279be3          	bne	a5,s2,800026c6 <waitx+0xda>
        acquire(&np->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	514080e7          	jalr	1300(ra) # 80000bea <acquire>
        if (np->state == ZOMBIE)
    800026de:	4c9c                	lw	a5,24(s1)
    800026e0:	f74785e3          	beq	a5,s4,8000264a <waitx+0x5e>
        release(&np->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5b8080e7          	jalr	1464(ra) # 80000c9e <release>
        havekids = 1;
    800026ee:	8756                	mv	a4,s5
    800026f0:	bfd9                	j	800026c6 <waitx+0xda>
    if (!havekids || p->killed)
    800026f2:	c701                	beqz	a4,800026fa <waitx+0x10e>
    800026f4:	02892783          	lw	a5,40(s2)
    800026f8:	cb8d                	beqz	a5,8000272a <waitx+0x13e>
      release(&wait_lock);
    800026fa:	0000e517          	auipc	a0,0xe
    800026fe:	47e50513          	addi	a0,a0,1150 # 80010b78 <wait_lock>
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	59c080e7          	jalr	1436(ra) # 80000c9e <release>
      return -1;
    8000270a:	59fd                	li	s3,-1
  }
}
    8000270c:	854e                	mv	a0,s3
    8000270e:	60e6                	ld	ra,88(sp)
    80002710:	6446                	ld	s0,80(sp)
    80002712:	64a6                	ld	s1,72(sp)
    80002714:	6906                	ld	s2,64(sp)
    80002716:	79e2                	ld	s3,56(sp)
    80002718:	7a42                	ld	s4,48(sp)
    8000271a:	7aa2                	ld	s5,40(sp)
    8000271c:	7b02                	ld	s6,32(sp)
    8000271e:	6be2                	ld	s7,24(sp)
    80002720:	6c42                	ld	s8,16(sp)
    80002722:	6ca2                	ld	s9,8(sp)
    80002724:	6d02                	ld	s10,0(sp)
    80002726:	6125                	addi	sp,sp,96
    80002728:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000272a:	85ea                	mv	a1,s10
    8000272c:	854a                	mv	a0,s2
    8000272e:	00000097          	auipc	ra,0x0
    80002732:	950080e7          	jalr	-1712(ra) # 8000207e <sleep>
    havekids = 0;
    80002736:	b721                	j	8000263e <waitx+0x52>

0000000080002738 <update_time>:

void update_time()
{
    80002738:	7179                	addi	sp,sp,-48
    8000273a:	f406                	sd	ra,40(sp)
    8000273c:	f022                	sd	s0,32(sp)
    8000273e:	ec26                	sd	s1,24(sp)
    80002740:	e84a                	sd	s2,16(sp)
    80002742:	e44e                	sd	s3,8(sp)
    80002744:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002746:	0000f497          	auipc	s1,0xf
    8000274a:	84a48493          	addi	s1,s1,-1974 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000274e:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002750:	00014917          	auipc	s2,0x14
    80002754:	64090913          	addi	s2,s2,1600 # 80016d90 <tickslock>
    80002758:	a811                	j	8000276c <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	542080e7          	jalr	1346(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002764:	17848493          	addi	s1,s1,376
    80002768:	03248063          	beq	s1,s2,80002788 <update_time+0x50>
    acquire(&p->lock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	47c080e7          	jalr	1148(ra) # 80000bea <acquire>
    if (p->state == RUNNING)
    80002776:	4c9c                	lw	a5,24(s1)
    80002778:	ff3791e3          	bne	a5,s3,8000275a <update_time+0x22>
      p->rtime++;
    8000277c:	1684a783          	lw	a5,360(s1)
    80002780:	2785                	addiw	a5,a5,1
    80002782:	16f4a423          	sw	a5,360(s1)
    80002786:	bfd1                	j	8000275a <update_time+0x22>
  }
    80002788:	70a2                	ld	ra,40(sp)
    8000278a:	7402                	ld	s0,32(sp)
    8000278c:	64e2                	ld	s1,24(sp)
    8000278e:	6942                	ld	s2,16(sp)
    80002790:	69a2                	ld	s3,8(sp)
    80002792:	6145                	addi	sp,sp,48
    80002794:	8082                	ret

0000000080002796 <swtch>:
    80002796:	00153023          	sd	ra,0(a0)
    8000279a:	00253423          	sd	sp,8(a0)
    8000279e:	e900                	sd	s0,16(a0)
    800027a0:	ed04                	sd	s1,24(a0)
    800027a2:	03253023          	sd	s2,32(a0)
    800027a6:	03353423          	sd	s3,40(a0)
    800027aa:	03453823          	sd	s4,48(a0)
    800027ae:	03553c23          	sd	s5,56(a0)
    800027b2:	05653023          	sd	s6,64(a0)
    800027b6:	05753423          	sd	s7,72(a0)
    800027ba:	05853823          	sd	s8,80(a0)
    800027be:	05953c23          	sd	s9,88(a0)
    800027c2:	07a53023          	sd	s10,96(a0)
    800027c6:	07b53423          	sd	s11,104(a0)
    800027ca:	0005b083          	ld	ra,0(a1)
    800027ce:	0085b103          	ld	sp,8(a1)
    800027d2:	6980                	ld	s0,16(a1)
    800027d4:	6d84                	ld	s1,24(a1)
    800027d6:	0205b903          	ld	s2,32(a1)
    800027da:	0285b983          	ld	s3,40(a1)
    800027de:	0305ba03          	ld	s4,48(a1)
    800027e2:	0385ba83          	ld	s5,56(a1)
    800027e6:	0405bb03          	ld	s6,64(a1)
    800027ea:	0485bb83          	ld	s7,72(a1)
    800027ee:	0505bc03          	ld	s8,80(a1)
    800027f2:	0585bc83          	ld	s9,88(a1)
    800027f6:	0605bd03          	ld	s10,96(a1)
    800027fa:	0685bd83          	ld	s11,104(a1)
    800027fe:	8082                	ret

0000000080002800 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002800:	1141                	addi	sp,sp,-16
    80002802:	e406                	sd	ra,8(sp)
    80002804:	e022                	sd	s0,0(sp)
    80002806:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002808:	00006597          	auipc	a1,0x6
    8000280c:	af058593          	addi	a1,a1,-1296 # 800082f8 <states.1732+0x30>
    80002810:	00014517          	auipc	a0,0x14
    80002814:	58050513          	addi	a0,a0,1408 # 80016d90 <tickslock>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	342080e7          	jalr	834(ra) # 80000b5a <initlock>
}
    80002820:	60a2                	ld	ra,8(sp)
    80002822:	6402                	ld	s0,0(sp)
    80002824:	0141                	addi	sp,sp,16
    80002826:	8082                	ret

0000000080002828 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002828:	1141                	addi	sp,sp,-16
    8000282a:	e422                	sd	s0,8(sp)
    8000282c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282e:	00003797          	auipc	a5,0x3
    80002832:	57278793          	addi	a5,a5,1394 # 80005da0 <kernelvec>
    80002836:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000283a:	6422                	ld	s0,8(sp)
    8000283c:	0141                	addi	sp,sp,16
    8000283e:	8082                	ret

0000000080002840 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002840:	1141                	addi	sp,sp,-16
    80002842:	e406                	sd	ra,8(sp)
    80002844:	e022                	sd	s0,0(sp)
    80002846:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	17e080e7          	jalr	382(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002850:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002854:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002856:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000285a:	00004617          	auipc	a2,0x4
    8000285e:	7a660613          	addi	a2,a2,1958 # 80007000 <_trampoline>
    80002862:	00004697          	auipc	a3,0x4
    80002866:	79e68693          	addi	a3,a3,1950 # 80007000 <_trampoline>
    8000286a:	8e91                	sub	a3,a3,a2
    8000286c:	040007b7          	lui	a5,0x4000
    80002870:	17fd                	addi	a5,a5,-1
    80002872:	07b2                	slli	a5,a5,0xc
    80002874:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002876:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000287a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000287c:	180026f3          	csrr	a3,satp
    80002880:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002882:	6d38                	ld	a4,88(a0)
    80002884:	6134                	ld	a3,64(a0)
    80002886:	6585                	lui	a1,0x1
    80002888:	96ae                	add	a3,a3,a1
    8000288a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000288c:	6d38                	ld	a4,88(a0)
    8000288e:	00000697          	auipc	a3,0x0
    80002892:	13e68693          	addi	a3,a3,318 # 800029cc <usertrap>
    80002896:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002898:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000289a:	8692                	mv	a3,tp
    8000289c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028a2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028aa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ae:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b0:	6f18                	ld	a4,24(a4)
    800028b2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b6:	6928                	ld	a0,80(a0)
    800028b8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028ba:	00004717          	auipc	a4,0x4
    800028be:	7e270713          	addi	a4,a4,2018 # 8000709c <userret>
    800028c2:	8f11                	sub	a4,a4,a2
    800028c4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028c6:	577d                	li	a4,-1
    800028c8:	177e                	slli	a4,a4,0x3f
    800028ca:	8d59                	or	a0,a0,a4
    800028cc:	9782                	jalr	a5
}
    800028ce:	60a2                	ld	ra,8(sp)
    800028d0:	6402                	ld	s0,0(sp)
    800028d2:	0141                	addi	sp,sp,16
    800028d4:	8082                	ret

00000000800028d6 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028d6:	1101                	addi	sp,sp,-32
    800028d8:	ec06                	sd	ra,24(sp)
    800028da:	e822                	sd	s0,16(sp)
    800028dc:	e426                	sd	s1,8(sp)
    800028de:	e04a                	sd	s2,0(sp)
    800028e0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e2:	00014917          	auipc	s2,0x14
    800028e6:	4ae90913          	addi	s2,s2,1198 # 80016d90 <tickslock>
    800028ea:	854a                	mv	a0,s2
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	2fe080e7          	jalr	766(ra) # 80000bea <acquire>
  ticks++;
    800028f4:	00006497          	auipc	s1,0x6
    800028f8:	ffc48493          	addi	s1,s1,-4 # 800088f0 <ticks>
    800028fc:	409c                	lw	a5,0(s1)
    800028fe:	2785                	addiw	a5,a5,1
    80002900:	c09c                	sw	a5,0(s1)
  update_time();
    80002902:	00000097          	auipc	ra,0x0
    80002906:	e36080e7          	jalr	-458(ra) # 80002738 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000290a:	8526                	mv	a0,s1
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	7d6080e7          	jalr	2006(ra) # 800020e2 <wakeup>
  release(&tickslock);
    80002914:	854a                	mv	a0,s2
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	388080e7          	jalr	904(ra) # 80000c9e <release>
}
    8000291e:	60e2                	ld	ra,24(sp)
    80002920:	6442                	ld	s0,16(sp)
    80002922:	64a2                	ld	s1,8(sp)
    80002924:	6902                	ld	s2,0(sp)
    80002926:	6105                	addi	sp,sp,32
    80002928:	8082                	ret

000000008000292a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    8000292a:	1101                	addi	sp,sp,-32
    8000292c:	ec06                	sd	ra,24(sp)
    8000292e:	e822                	sd	s0,16(sp)
    80002930:	e426                	sd	s1,8(sp)
    80002932:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002934:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002938:	00074d63          	bltz	a4,80002952 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    8000293c:	57fd                	li	a5,-1
    8000293e:	17fe                	slli	a5,a5,0x3f
    80002940:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002942:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002944:	06f70363          	beq	a4,a5,800029aa <devintr+0x80>
  }
}
    80002948:	60e2                	ld	ra,24(sp)
    8000294a:	6442                	ld	s0,16(sp)
    8000294c:	64a2                	ld	s1,8(sp)
    8000294e:	6105                	addi	sp,sp,32
    80002950:	8082                	ret
      (scause & 0xff) == 9)
    80002952:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002956:	46a5                	li	a3,9
    80002958:	fed792e3          	bne	a5,a3,8000293c <devintr+0x12>
    int irq = plic_claim();
    8000295c:	00003097          	auipc	ra,0x3
    80002960:	54c080e7          	jalr	1356(ra) # 80005ea8 <plic_claim>
    80002964:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002966:	47a9                	li	a5,10
    80002968:	02f50763          	beq	a0,a5,80002996 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    8000296c:	4785                	li	a5,1
    8000296e:	02f50963          	beq	a0,a5,800029a0 <devintr+0x76>
    return 1;
    80002972:	4505                	li	a0,1
    else if (irq)
    80002974:	d8f1                	beqz	s1,80002948 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002976:	85a6                	mv	a1,s1
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	98850513          	addi	a0,a0,-1656 # 80008300 <states.1732+0x38>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c0e080e7          	jalr	-1010(ra) # 8000058e <printf>
      plic_complete(irq);
    80002988:	8526                	mv	a0,s1
    8000298a:	00003097          	auipc	ra,0x3
    8000298e:	542080e7          	jalr	1346(ra) # 80005ecc <plic_complete>
    return 1;
    80002992:	4505                	li	a0,1
    80002994:	bf55                	j	80002948 <devintr+0x1e>
      uartintr();
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	018080e7          	jalr	24(ra) # 800009ae <uartintr>
    8000299e:	b7ed                	j	80002988 <devintr+0x5e>
      virtio_disk_intr();
    800029a0:	00004097          	auipc	ra,0x4
    800029a4:	a56080e7          	jalr	-1450(ra) # 800063f6 <virtio_disk_intr>
    800029a8:	b7c5                	j	80002988 <devintr+0x5e>
    if (cpuid() == 0)
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	ff0080e7          	jalr	-16(ra) # 8000199a <cpuid>
    800029b2:	c901                	beqz	a0,800029c2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029b4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029b8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ba:	14479073          	csrw	sip,a5
    return 2;
    800029be:	4509                	li	a0,2
    800029c0:	b761                	j	80002948 <devintr+0x1e>
      clockintr();
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	f14080e7          	jalr	-236(ra) # 800028d6 <clockintr>
    800029ca:	b7ed                	j	800029b4 <devintr+0x8a>

00000000800029cc <usertrap>:
{
    800029cc:	1101                	addi	sp,sp,-32
    800029ce:	ec06                	sd	ra,24(sp)
    800029d0:	e822                	sd	s0,16(sp)
    800029d2:	e426                	sd	s1,8(sp)
    800029d4:	e04a                	sd	s2,0(sp)
    800029d6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d8:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029dc:	1007f793          	andi	a5,a5,256
    800029e0:	e3b1                	bnez	a5,80002a24 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e2:	00003797          	auipc	a5,0x3
    800029e6:	3be78793          	addi	a5,a5,958 # 80005da0 <kernelvec>
    800029ea:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	fd8080e7          	jalr	-40(ra) # 800019c6 <myproc>
    800029f6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029f8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fa:	14102773          	csrr	a4,sepc
    800029fe:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a00:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a04:	47a1                	li	a5,8
    80002a06:	02f70763          	beq	a4,a5,80002a34 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	f20080e7          	jalr	-224(ra) # 8000292a <devintr>
    80002a12:	892a                	mv	s2,a0
    80002a14:	c151                	beqz	a0,80002a98 <usertrap+0xcc>
  if (killed(p))
    80002a16:	8526                	mv	a0,s1
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	91a080e7          	jalr	-1766(ra) # 80002332 <killed>
    80002a20:	c929                	beqz	a0,80002a72 <usertrap+0xa6>
    80002a22:	a099                	j	80002a68 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a24:	00006517          	auipc	a0,0x6
    80002a28:	8fc50513          	addi	a0,a0,-1796 # 80008320 <states.1732+0x58>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	b18080e7          	jalr	-1256(ra) # 80000544 <panic>
    if (killed(p))
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	8fe080e7          	jalr	-1794(ra) # 80002332 <killed>
    80002a3c:	e921                	bnez	a0,80002a8c <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a3e:	6cb8                	ld	a4,88(s1)
    80002a40:	6f1c                	ld	a5,24(a4)
    80002a42:	0791                	addi	a5,a5,4
    80002a44:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a4a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a4e:	10079073          	csrw	sstatus,a5
    syscall();
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	2d4080e7          	jalr	724(ra) # 80002d26 <syscall>
  if (killed(p))
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	8d6080e7          	jalr	-1834(ra) # 80002332 <killed>
    80002a64:	c911                	beqz	a0,80002a78 <usertrap+0xac>
    80002a66:	4901                	li	s2,0
    exit(-1);
    80002a68:	557d                	li	a0,-1
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	748080e7          	jalr	1864(ra) # 800021b2 <exit>
  if (which_dev == 2)
    80002a72:	4789                	li	a5,2
    80002a74:	04f90f63          	beq	s2,a5,80002ad2 <usertrap+0x106>
  usertrapret();
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	dc8080e7          	jalr	-568(ra) # 80002840 <usertrapret>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6902                	ld	s2,0(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
      exit(-1);
    80002a8c:	557d                	li	a0,-1
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	724080e7          	jalr	1828(ra) # 800021b2 <exit>
    80002a96:	b765                	j	80002a3e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a9c:	5890                	lw	a2,48(s1)
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	8a250513          	addi	a0,a0,-1886 # 80008340 <states.1732+0x78>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ae8080e7          	jalr	-1304(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	8ba50513          	addi	a0,a0,-1862 # 80008370 <states.1732+0xa8>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	ad0080e7          	jalr	-1328(ra) # 8000058e <printf>
    setkilled(p);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	83e080e7          	jalr	-1986(ra) # 80002306 <setkilled>
    80002ad0:	b769                	j	80002a5a <usertrap+0x8e>
    yield();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	570080e7          	jalr	1392(ra) # 80002042 <yield>
    80002ada:	bf79                	j	80002a78 <usertrap+0xac>

0000000080002adc <kerneltrap>:
{
    80002adc:	7179                	addi	sp,sp,-48
    80002ade:	f406                	sd	ra,40(sp)
    80002ae0:	f022                	sd	s0,32(sp)
    80002ae2:	ec26                	sd	s1,24(sp)
    80002ae4:	e84a                	sd	s2,16(sp)
    80002ae6:	e44e                	sd	s3,8(sp)
    80002ae8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aea:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aee:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af2:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002af6:	1004f793          	andi	a5,s1,256
    80002afa:	cb85                	beqz	a5,80002b2a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b00:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b02:	ef85                	bnez	a5,80002b3a <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	e26080e7          	jalr	-474(ra) # 8000292a <devintr>
    80002b0c:	cd1d                	beqz	a0,80002b4a <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b0e:	4789                	li	a5,2
    80002b10:	06f50a63          	beq	a0,a5,80002b84 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b14:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b18:	10049073          	csrw	sstatus,s1
}
    80002b1c:	70a2                	ld	ra,40(sp)
    80002b1e:	7402                	ld	s0,32(sp)
    80002b20:	64e2                	ld	s1,24(sp)
    80002b22:	6942                	ld	s2,16(sp)
    80002b24:	69a2                	ld	s3,8(sp)
    80002b26:	6145                	addi	sp,sp,48
    80002b28:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	86650513          	addi	a0,a0,-1946 # 80008390 <states.1732+0xc8>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a12080e7          	jalr	-1518(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	87e50513          	addi	a0,a0,-1922 # 800083b8 <states.1732+0xf0>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a02080e7          	jalr	-1534(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002b4a:	85ce                	mv	a1,s3
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	88c50513          	addi	a0,a0,-1908 # 800083d8 <states.1732+0x110>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	a3a080e7          	jalr	-1478(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b60:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	88450513          	addi	a0,a0,-1916 # 800083e8 <states.1732+0x120>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a22080e7          	jalr	-1502(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	88c50513          	addi	a0,a0,-1908 # 80008400 <states.1732+0x138>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	9c8080e7          	jalr	-1592(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	e42080e7          	jalr	-446(ra) # 800019c6 <myproc>
    80002b8c:	d541                	beqz	a0,80002b14 <kerneltrap+0x38>
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	e38080e7          	jalr	-456(ra) # 800019c6 <myproc>
    80002b96:	4d18                	lw	a4,24(a0)
    80002b98:	4791                	li	a5,4
    80002b9a:	f6f71de3          	bne	a4,a5,80002b14 <kerneltrap+0x38>
    yield();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	4a4080e7          	jalr	1188(ra) # 80002042 <yield>
    80002ba6:	b7bd                	j	80002b14 <kerneltrap+0x38>

0000000080002ba8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ba8:	1101                	addi	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	e426                	sd	s1,8(sp)
    80002bb0:	1000                	addi	s0,sp,32
    80002bb2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	e12080e7          	jalr	-494(ra) # 800019c6 <myproc>
  switch (n) {
    80002bbc:	4795                	li	a5,5
    80002bbe:	0497e163          	bltu	a5,s1,80002c00 <argraw+0x58>
    80002bc2:	048a                	slli	s1,s1,0x2
    80002bc4:	00006717          	auipc	a4,0x6
    80002bc8:	87470713          	addi	a4,a4,-1932 # 80008438 <states.1732+0x170>
    80002bcc:	94ba                	add	s1,s1,a4
    80002bce:	409c                	lw	a5,0(s1)
    80002bd0:	97ba                	add	a5,a5,a4
    80002bd2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bd4:	6d3c                	ld	a5,88(a0)
    80002bd6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret
    return p->trapframe->a1;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	7fa8                	ld	a0,120(a5)
    80002be6:	bfcd                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a2;
    80002be8:	6d3c                	ld	a5,88(a0)
    80002bea:	63c8                	ld	a0,128(a5)
    80002bec:	b7f5                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a3;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	67c8                	ld	a0,136(a5)
    80002bf2:	b7dd                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a4;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	6bc8                	ld	a0,144(a5)
    80002bf8:	b7c5                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a5;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	6fc8                	ld	a0,152(a5)
    80002bfe:	bfe9                	j	80002bd8 <argraw+0x30>
  panic("argraw");
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	81050513          	addi	a0,a0,-2032 # 80008410 <states.1732+0x148>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	93c080e7          	jalr	-1732(ra) # 80000544 <panic>

0000000080002c10 <fetchaddr>:
{
    80002c10:	1101                	addi	sp,sp,-32
    80002c12:	ec06                	sd	ra,24(sp)
    80002c14:	e822                	sd	s0,16(sp)
    80002c16:	e426                	sd	s1,8(sp)
    80002c18:	e04a                	sd	s2,0(sp)
    80002c1a:	1000                	addi	s0,sp,32
    80002c1c:	84aa                	mv	s1,a0
    80002c1e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	da6080e7          	jalr	-602(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c28:	653c                	ld	a5,72(a0)
    80002c2a:	02f4f863          	bgeu	s1,a5,80002c5a <fetchaddr+0x4a>
    80002c2e:	00848713          	addi	a4,s1,8
    80002c32:	02e7e663          	bltu	a5,a4,80002c5e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c36:	46a1                	li	a3,8
    80002c38:	8626                	mv	a2,s1
    80002c3a:	85ca                	mv	a1,s2
    80002c3c:	6928                	ld	a0,80(a0)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	ad2080e7          	jalr	-1326(ra) # 80001710 <copyin>
    80002c46:	00a03533          	snez	a0,a0
    80002c4a:	40a00533          	neg	a0,a0
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret
    return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bfcd                	j	80002c4e <fetchaddr+0x3e>
    80002c5e:	557d                	li	a0,-1
    80002c60:	b7fd                	j	80002c4e <fetchaddr+0x3e>

0000000080002c62 <fetchstr>:
{
    80002c62:	7179                	addi	sp,sp,-48
    80002c64:	f406                	sd	ra,40(sp)
    80002c66:	f022                	sd	s0,32(sp)
    80002c68:	ec26                	sd	s1,24(sp)
    80002c6a:	e84a                	sd	s2,16(sp)
    80002c6c:	e44e                	sd	s3,8(sp)
    80002c6e:	1800                	addi	s0,sp,48
    80002c70:	892a                	mv	s2,a0
    80002c72:	84ae                	mv	s1,a1
    80002c74:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	d50080e7          	jalr	-688(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c7e:	86ce                	mv	a3,s3
    80002c80:	864a                	mv	a2,s2
    80002c82:	85a6                	mv	a1,s1
    80002c84:	6928                	ld	a0,80(a0)
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	b16080e7          	jalr	-1258(ra) # 8000179c <copyinstr>
    80002c8e:	00054e63          	bltz	a0,80002caa <fetchstr+0x48>
  return strlen(buf);
    80002c92:	8526                	mv	a0,s1
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	1d6080e7          	jalr	470(ra) # 80000e6a <strlen>
}
    80002c9c:	70a2                	ld	ra,40(sp)
    80002c9e:	7402                	ld	s0,32(sp)
    80002ca0:	64e2                	ld	s1,24(sp)
    80002ca2:	6942                	ld	s2,16(sp)
    80002ca4:	69a2                	ld	s3,8(sp)
    80002ca6:	6145                	addi	sp,sp,48
    80002ca8:	8082                	ret
    return -1;
    80002caa:	557d                	li	a0,-1
    80002cac:	bfc5                	j	80002c9c <fetchstr+0x3a>

0000000080002cae <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	1000                	addi	s0,sp,32
    80002cb8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	eee080e7          	jalr	-274(ra) # 80002ba8 <argraw>
    80002cc2:	c088                	sw	a0,0(s1)
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cce:	1101                	addi	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	e426                	sd	s1,8(sp)
    80002cd6:	1000                	addi	s0,sp,32
    80002cd8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	ece080e7          	jalr	-306(ra) # 80002ba8 <argraw>
    80002ce2:	e088                	sd	a0,0(s1)
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	64a2                	ld	s1,8(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cee:	7179                	addi	sp,sp,-48
    80002cf0:	f406                	sd	ra,40(sp)
    80002cf2:	f022                	sd	s0,32(sp)
    80002cf4:	ec26                	sd	s1,24(sp)
    80002cf6:	e84a                	sd	s2,16(sp)
    80002cf8:	1800                	addi	s0,sp,48
    80002cfa:	84ae                	mv	s1,a1
    80002cfc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cfe:	fd840593          	addi	a1,s0,-40
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	fcc080e7          	jalr	-52(ra) # 80002cce <argaddr>
  return fetchstr(addr, buf, max);
    80002d0a:	864a                	mv	a2,s2
    80002d0c:	85a6                	mv	a1,s1
    80002d0e:	fd843503          	ld	a0,-40(s0)
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f50080e7          	jalr	-176(ra) # 80002c62 <fetchstr>
}
    80002d1a:	70a2                	ld	ra,40(sp)
    80002d1c:	7402                	ld	s0,32(sp)
    80002d1e:	64e2                	ld	s1,24(sp)
    80002d20:	6942                	ld	s2,16(sp)
    80002d22:	6145                	addi	sp,sp,48
    80002d24:	8082                	ret

0000000080002d26 <syscall>:
[SYS_getreadcount] sys_getreadcount,
};

void
syscall(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c94080e7          	jalr	-876(ra) # 800019c6 <myproc>
    80002d3a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d3c:	05853903          	ld	s2,88(a0)
    80002d40:	0a893783          	ld	a5,168(s2)
    80002d44:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d48:	37fd                	addiw	a5,a5,-1
    80002d4a:	4759                	li	a4,22
    80002d4c:	00f76f63          	bltu	a4,a5,80002d6a <syscall+0x44>
    80002d50:	00369713          	slli	a4,a3,0x3
    80002d54:	00005797          	auipc	a5,0x5
    80002d58:	6fc78793          	addi	a5,a5,1788 # 80008450 <syscalls>
    80002d5c:	97ba                	add	a5,a5,a4
    80002d5e:	639c                	ld	a5,0(a5)
    80002d60:	c789                	beqz	a5,80002d6a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d62:	9782                	jalr	a5
    80002d64:	06a93823          	sd	a0,112(s2)
    80002d68:	a839                	j	80002d86 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d6a:	15848613          	addi	a2,s1,344
    80002d6e:	588c                	lw	a1,48(s1)
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	6a850513          	addi	a0,a0,1704 # 80008418 <states.1732+0x150>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	816080e7          	jalr	-2026(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d80:	6cbc                	ld	a5,88(s1)
    80002d82:	577d                	li	a4,-1
    80002d84:	fbb8                	sd	a4,112(a5)
  }
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	64a2                	ld	s1,8(sp)
    80002d8c:	6902                	ld	s2,0(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret

0000000080002d92 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d9a:	fec40593          	addi	a1,s0,-20
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	f0e080e7          	jalr	-242(ra) # 80002cae <argint>
  exit(n);
    80002da8:	fec42503          	lw	a0,-20(s0)
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	406080e7          	jalr	1030(ra) # 800021b2 <exit>
  return 0; // not reached
}
    80002db4:	4501                	li	a0,0
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	6105                	addi	sp,sp,32
    80002dbc:	8082                	ret

0000000080002dbe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dbe:	1141                	addi	sp,sp,-16
    80002dc0:	e406                	sd	ra,8(sp)
    80002dc2:	e022                	sd	s0,0(sp)
    80002dc4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	c00080e7          	jalr	-1024(ra) # 800019c6 <myproc>
}
    80002dce:	5908                	lw	a0,48(a0)
    80002dd0:	60a2                	ld	ra,8(sp)
    80002dd2:	6402                	ld	s0,0(sp)
    80002dd4:	0141                	addi	sp,sp,16
    80002dd6:	8082                	ret

0000000080002dd8 <sys_fork>:

uint64
sys_fork(void)
{
    80002dd8:	1141                	addi	sp,sp,-16
    80002dda:	e406                	sd	ra,8(sp)
    80002ddc:	e022                	sd	s0,0(sp)
    80002dde:	0800                	addi	s0,sp,16
  return fork();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	fb0080e7          	jalr	-80(ra) # 80001d90 <fork>
}
    80002de8:	60a2                	ld	ra,8(sp)
    80002dea:	6402                	ld	s0,0(sp)
    80002dec:	0141                	addi	sp,sp,16
    80002dee:	8082                	ret

0000000080002df0 <sys_wait>:

uint64
sys_wait(void)
{
    80002df0:	1101                	addi	sp,sp,-32
    80002df2:	ec06                	sd	ra,24(sp)
    80002df4:	e822                	sd	s0,16(sp)
    80002df6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002df8:	fe840593          	addi	a1,s0,-24
    80002dfc:	4501                	li	a0,0
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	ed0080e7          	jalr	-304(ra) # 80002cce <argaddr>
  return wait(p);
    80002e06:	fe843503          	ld	a0,-24(s0)
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	55a080e7          	jalr	1370(ra) # 80002364 <wait>
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e1a:	7179                	addi	sp,sp,-48
    80002e1c:	f406                	sd	ra,40(sp)
    80002e1e:	f022                	sd	s0,32(sp)
    80002e20:	ec26                	sd	s1,24(sp)
    80002e22:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e24:	fdc40593          	addi	a1,s0,-36
    80002e28:	4501                	li	a0,0
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	e84080e7          	jalr	-380(ra) # 80002cae <argint>
  addr = myproc()->sz;
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	b94080e7          	jalr	-1132(ra) # 800019c6 <myproc>
    80002e3a:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e3c:	fdc42503          	lw	a0,-36(s0)
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	ef4080e7          	jalr	-268(ra) # 80001d34 <growproc>
    80002e48:	00054863          	bltz	a0,80002e58 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e4c:	8526                	mv	a0,s1
    80002e4e:	70a2                	ld	ra,40(sp)
    80002e50:	7402                	ld	s0,32(sp)
    80002e52:	64e2                	ld	s1,24(sp)
    80002e54:	6145                	addi	sp,sp,48
    80002e56:	8082                	ret
    return -1;
    80002e58:	54fd                	li	s1,-1
    80002e5a:	bfcd                	j	80002e4c <sys_sbrk+0x32>

0000000080002e5c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e5c:	7139                	addi	sp,sp,-64
    80002e5e:	fc06                	sd	ra,56(sp)
    80002e60:	f822                	sd	s0,48(sp)
    80002e62:	f426                	sd	s1,40(sp)
    80002e64:	f04a                	sd	s2,32(sp)
    80002e66:	ec4e                	sd	s3,24(sp)
    80002e68:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e6a:	fcc40593          	addi	a1,s0,-52
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	e3e080e7          	jalr	-450(ra) # 80002cae <argint>
  acquire(&tickslock);
    80002e78:	00014517          	auipc	a0,0x14
    80002e7c:	f1850513          	addi	a0,a0,-232 # 80016d90 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	d6a080e7          	jalr	-662(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e88:	00006917          	auipc	s2,0x6
    80002e8c:	a6892903          	lw	s2,-1432(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80002e90:	fcc42783          	lw	a5,-52(s0)
    80002e94:	cf9d                	beqz	a5,80002ed2 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e96:	00014997          	auipc	s3,0x14
    80002e9a:	efa98993          	addi	s3,s3,-262 # 80016d90 <tickslock>
    80002e9e:	00006497          	auipc	s1,0x6
    80002ea2:	a5248493          	addi	s1,s1,-1454 # 800088f0 <ticks>
    if (killed(myproc()))
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b20080e7          	jalr	-1248(ra) # 800019c6 <myproc>
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	484080e7          	jalr	1156(ra) # 80002332 <killed>
    80002eb6:	ed15                	bnez	a0,80002ef2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002eb8:	85ce                	mv	a1,s3
    80002eba:	8526                	mv	a0,s1
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	1c2080e7          	jalr	450(ra) # 8000207e <sleep>
  while (ticks - ticks0 < n)
    80002ec4:	409c                	lw	a5,0(s1)
    80002ec6:	412787bb          	subw	a5,a5,s2
    80002eca:	fcc42703          	lw	a4,-52(s0)
    80002ece:	fce7ece3          	bltu	a5,a4,80002ea6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ed2:	00014517          	auipc	a0,0x14
    80002ed6:	ebe50513          	addi	a0,a0,-322 # 80016d90 <tickslock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	dc4080e7          	jalr	-572(ra) # 80000c9e <release>
  return 0;
    80002ee2:	4501                	li	a0,0
}
    80002ee4:	70e2                	ld	ra,56(sp)
    80002ee6:	7442                	ld	s0,48(sp)
    80002ee8:	74a2                	ld	s1,40(sp)
    80002eea:	7902                	ld	s2,32(sp)
    80002eec:	69e2                	ld	s3,24(sp)
    80002eee:	6121                	addi	sp,sp,64
    80002ef0:	8082                	ret
      release(&tickslock);
    80002ef2:	00014517          	auipc	a0,0x14
    80002ef6:	e9e50513          	addi	a0,a0,-354 # 80016d90 <tickslock>
    80002efa:	ffffe097          	auipc	ra,0xffffe
    80002efe:	da4080e7          	jalr	-604(ra) # 80000c9e <release>
      return -1;
    80002f02:	557d                	li	a0,-1
    80002f04:	b7c5                	j	80002ee4 <sys_sleep+0x88>

0000000080002f06 <sys_kill>:

uint64
sys_kill(void)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f0e:	fec40593          	addi	a1,s0,-20
    80002f12:	4501                	li	a0,0
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	d9a080e7          	jalr	-614(ra) # 80002cae <argint>
  return kill(pid);
    80002f1c:	fec42503          	lw	a0,-20(s0)
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	374080e7          	jalr	884(ra) # 80002294 <kill>
}
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	6105                	addi	sp,sp,32
    80002f2e:	8082                	ret

0000000080002f30 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f3a:	00014517          	auipc	a0,0x14
    80002f3e:	e5650513          	addi	a0,a0,-426 # 80016d90 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	ca8080e7          	jalr	-856(ra) # 80000bea <acquire>
  xticks = ticks;
    80002f4a:	00006497          	auipc	s1,0x6
    80002f4e:	9a64a483          	lw	s1,-1626(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002f52:	00014517          	auipc	a0,0x14
    80002f56:	e3e50513          	addi	a0,a0,-450 # 80016d90 <tickslock>
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	d44080e7          	jalr	-700(ra) # 80000c9e <release>
  return xticks;
}
    80002f62:	02049513          	slli	a0,s1,0x20
    80002f66:	9101                	srli	a0,a0,0x20
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	64a2                	ld	s1,8(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002f72:	7139                	addi	sp,sp,-64
    80002f74:	fc06                	sd	ra,56(sp)
    80002f76:	f822                	sd	s0,48(sp)
    80002f78:	f426                	sd	s1,40(sp)
    80002f7a:	f04a                	sd	s2,32(sp)
    80002f7c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002f7e:	fd840593          	addi	a1,s0,-40
    80002f82:	4501                	li	a0,0
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	d4a080e7          	jalr	-694(ra) # 80002cce <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002f8c:	fd040593          	addi	a1,s0,-48
    80002f90:	4505                	li	a0,1
    80002f92:	00000097          	auipc	ra,0x0
    80002f96:	d3c080e7          	jalr	-708(ra) # 80002cce <argaddr>
  argaddr(2, &addr2);
    80002f9a:	fc840593          	addi	a1,s0,-56
    80002f9e:	4509                	li	a0,2
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	d2e080e7          	jalr	-722(ra) # 80002cce <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80002fa8:	fc040613          	addi	a2,s0,-64
    80002fac:	fc440593          	addi	a1,s0,-60
    80002fb0:	fd843503          	ld	a0,-40(s0)
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	638080e7          	jalr	1592(ra) # 800025ec <waitx>
    80002fbc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	a08080e7          	jalr	-1528(ra) # 800019c6 <myproc>
    80002fc6:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fc8:	4691                	li	a3,4
    80002fca:	fc440613          	addi	a2,s0,-60
    80002fce:	fd043583          	ld	a1,-48(s0)
    80002fd2:	6928                	ld	a0,80(a0)
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	6b0080e7          	jalr	1712(ra) # 80001684 <copyout>
    return -1;
    80002fdc:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fde:	00054f63          	bltz	a0,80002ffc <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80002fe2:	4691                	li	a3,4
    80002fe4:	fc040613          	addi	a2,s0,-64
    80002fe8:	fc843583          	ld	a1,-56(s0)
    80002fec:	68a8                	ld	a0,80(s1)
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	696080e7          	jalr	1686(ra) # 80001684 <copyout>
    80002ff6:	00054a63          	bltz	a0,8000300a <sys_waitx+0x98>
    return -1;
  return ret;
    80002ffa:	87ca                	mv	a5,s2
    80002ffc:	853e                	mv	a0,a5
    80002ffe:	70e2                	ld	ra,56(sp)
    80003000:	7442                	ld	s0,48(sp)
    80003002:	74a2                	ld	s1,40(sp)
    80003004:	7902                	ld	s2,32(sp)
    80003006:	6121                	addi	sp,sp,64
    80003008:	8082                	ret
    return -1;
    8000300a:	57fd                	li	a5,-1
    8000300c:	bfc5                	j	80002ffc <sys_waitx+0x8a>

000000008000300e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000300e:	7179                	addi	sp,sp,-48
    80003010:	f406                	sd	ra,40(sp)
    80003012:	f022                	sd	s0,32(sp)
    80003014:	ec26                	sd	s1,24(sp)
    80003016:	e84a                	sd	s2,16(sp)
    80003018:	e44e                	sd	s3,8(sp)
    8000301a:	e052                	sd	s4,0(sp)
    8000301c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000301e:	00005597          	auipc	a1,0x5
    80003022:	4f258593          	addi	a1,a1,1266 # 80008510 <syscalls+0xc0>
    80003026:	00014517          	auipc	a0,0x14
    8000302a:	d8250513          	addi	a0,a0,-638 # 80016da8 <bcache>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	b2c080e7          	jalr	-1236(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003036:	0001c797          	auipc	a5,0x1c
    8000303a:	d7278793          	addi	a5,a5,-654 # 8001eda8 <bcache+0x8000>
    8000303e:	0001c717          	auipc	a4,0x1c
    80003042:	fd270713          	addi	a4,a4,-46 # 8001f010 <bcache+0x8268>
    80003046:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000304a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304e:	00014497          	auipc	s1,0x14
    80003052:	d7248493          	addi	s1,s1,-654 # 80016dc0 <bcache+0x18>
    b->next = bcache.head.next;
    80003056:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003058:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000305a:	00005a17          	auipc	s4,0x5
    8000305e:	4bea0a13          	addi	s4,s4,1214 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003062:	2b893783          	ld	a5,696(s2)
    80003066:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003068:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000306c:	85d2                	mv	a1,s4
    8000306e:	01048513          	addi	a0,s1,16
    80003072:	00001097          	auipc	ra,0x1
    80003076:	4c4080e7          	jalr	1220(ra) # 80004536 <initsleeplock>
    bcache.head.next->prev = b;
    8000307a:	2b893783          	ld	a5,696(s2)
    8000307e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003080:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003084:	45848493          	addi	s1,s1,1112
    80003088:	fd349de3          	bne	s1,s3,80003062 <binit+0x54>
  }
}
    8000308c:	70a2                	ld	ra,40(sp)
    8000308e:	7402                	ld	s0,32(sp)
    80003090:	64e2                	ld	s1,24(sp)
    80003092:	6942                	ld	s2,16(sp)
    80003094:	69a2                	ld	s3,8(sp)
    80003096:	6a02                	ld	s4,0(sp)
    80003098:	6145                	addi	sp,sp,48
    8000309a:	8082                	ret

000000008000309c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000309c:	7179                	addi	sp,sp,-48
    8000309e:	f406                	sd	ra,40(sp)
    800030a0:	f022                	sd	s0,32(sp)
    800030a2:	ec26                	sd	s1,24(sp)
    800030a4:	e84a                	sd	s2,16(sp)
    800030a6:	e44e                	sd	s3,8(sp)
    800030a8:	1800                	addi	s0,sp,48
    800030aa:	89aa                	mv	s3,a0
    800030ac:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	cfa50513          	addi	a0,a0,-774 # 80016da8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	b34080e7          	jalr	-1228(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030be:	0001c497          	auipc	s1,0x1c
    800030c2:	fa24b483          	ld	s1,-94(s1) # 8001f060 <bcache+0x82b8>
    800030c6:	0001c797          	auipc	a5,0x1c
    800030ca:	f4a78793          	addi	a5,a5,-182 # 8001f010 <bcache+0x8268>
    800030ce:	02f48f63          	beq	s1,a5,8000310c <bread+0x70>
    800030d2:	873e                	mv	a4,a5
    800030d4:	a021                	j	800030dc <bread+0x40>
    800030d6:	68a4                	ld	s1,80(s1)
    800030d8:	02e48a63          	beq	s1,a4,8000310c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030dc:	449c                	lw	a5,8(s1)
    800030de:	ff379ce3          	bne	a5,s3,800030d6 <bread+0x3a>
    800030e2:	44dc                	lw	a5,12(s1)
    800030e4:	ff2799e3          	bne	a5,s2,800030d6 <bread+0x3a>
      b->refcnt++;
    800030e8:	40bc                	lw	a5,64(s1)
    800030ea:	2785                	addiw	a5,a5,1
    800030ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	cba50513          	addi	a0,a0,-838 # 80016da8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	ba8080e7          	jalr	-1112(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030fe:	01048513          	addi	a0,s1,16
    80003102:	00001097          	auipc	ra,0x1
    80003106:	46e080e7          	jalr	1134(ra) # 80004570 <acquiresleep>
      return b;
    8000310a:	a8b9                	j	80003168 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310c:	0001c497          	auipc	s1,0x1c
    80003110:	f4c4b483          	ld	s1,-180(s1) # 8001f058 <bcache+0x82b0>
    80003114:	0001c797          	auipc	a5,0x1c
    80003118:	efc78793          	addi	a5,a5,-260 # 8001f010 <bcache+0x8268>
    8000311c:	00f48863          	beq	s1,a5,8000312c <bread+0x90>
    80003120:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	cf81                	beqz	a5,8000313c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003126:	64a4                	ld	s1,72(s1)
    80003128:	fee49de3          	bne	s1,a4,80003122 <bread+0x86>
  panic("bget: no buffers");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	3f450513          	addi	a0,a0,1012 # 80008520 <syscalls+0xd0>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	410080e7          	jalr	1040(ra) # 80000544 <panic>
      b->dev = dev;
    8000313c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003140:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003144:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003148:	4785                	li	a5,1
    8000314a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	c5c50513          	addi	a0,a0,-932 # 80016da8 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	b4a080e7          	jalr	-1206(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000315c:	01048513          	addi	a0,s1,16
    80003160:	00001097          	auipc	ra,0x1
    80003164:	410080e7          	jalr	1040(ra) # 80004570 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003168:	409c                	lw	a5,0(s1)
    8000316a:	cb89                	beqz	a5,8000317c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000316c:	8526                	mv	a0,s1
    8000316e:	70a2                	ld	ra,40(sp)
    80003170:	7402                	ld	s0,32(sp)
    80003172:	64e2                	ld	s1,24(sp)
    80003174:	6942                	ld	s2,16(sp)
    80003176:	69a2                	ld	s3,8(sp)
    80003178:	6145                	addi	sp,sp,48
    8000317a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000317c:	4581                	li	a1,0
    8000317e:	8526                	mv	a0,s1
    80003180:	00003097          	auipc	ra,0x3
    80003184:	fe8080e7          	jalr	-24(ra) # 80006168 <virtio_disk_rw>
    b->valid = 1;
    80003188:	4785                	li	a5,1
    8000318a:	c09c                	sw	a5,0(s1)
  return b;
    8000318c:	b7c5                	j	8000316c <bread+0xd0>

000000008000318e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000318e:	1101                	addi	sp,sp,-32
    80003190:	ec06                	sd	ra,24(sp)
    80003192:	e822                	sd	s0,16(sp)
    80003194:	e426                	sd	s1,8(sp)
    80003196:	1000                	addi	s0,sp,32
    80003198:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000319a:	0541                	addi	a0,a0,16
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	46e080e7          	jalr	1134(ra) # 8000460a <holdingsleep>
    800031a4:	cd01                	beqz	a0,800031bc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031a6:	4585                	li	a1,1
    800031a8:	8526                	mv	a0,s1
    800031aa:	00003097          	auipc	ra,0x3
    800031ae:	fbe080e7          	jalr	-66(ra) # 80006168 <virtio_disk_rw>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret
    panic("bwrite");
    800031bc:	00005517          	auipc	a0,0x5
    800031c0:	37c50513          	addi	a0,a0,892 # 80008538 <syscalls+0xe8>
    800031c4:	ffffd097          	auipc	ra,0xffffd
    800031c8:	380080e7          	jalr	896(ra) # 80000544 <panic>

00000000800031cc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031cc:	1101                	addi	sp,sp,-32
    800031ce:	ec06                	sd	ra,24(sp)
    800031d0:	e822                	sd	s0,16(sp)
    800031d2:	e426                	sd	s1,8(sp)
    800031d4:	e04a                	sd	s2,0(sp)
    800031d6:	1000                	addi	s0,sp,32
    800031d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031da:	01050913          	addi	s2,a0,16
    800031de:	854a                	mv	a0,s2
    800031e0:	00001097          	auipc	ra,0x1
    800031e4:	42a080e7          	jalr	1066(ra) # 8000460a <holdingsleep>
    800031e8:	c92d                	beqz	a0,8000325a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031ea:	854a                	mv	a0,s2
    800031ec:	00001097          	auipc	ra,0x1
    800031f0:	3da080e7          	jalr	986(ra) # 800045c6 <releasesleep>

  acquire(&bcache.lock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	bb450513          	addi	a0,a0,-1100 # 80016da8 <bcache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	9ee080e7          	jalr	-1554(ra) # 80000bea <acquire>
  b->refcnt--;
    80003204:	40bc                	lw	a5,64(s1)
    80003206:	37fd                	addiw	a5,a5,-1
    80003208:	0007871b          	sext.w	a4,a5
    8000320c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000320e:	eb05                	bnez	a4,8000323e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003210:	68bc                	ld	a5,80(s1)
    80003212:	64b8                	ld	a4,72(s1)
    80003214:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003216:	64bc                	ld	a5,72(s1)
    80003218:	68b8                	ld	a4,80(s1)
    8000321a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000321c:	0001c797          	auipc	a5,0x1c
    80003220:	b8c78793          	addi	a5,a5,-1140 # 8001eda8 <bcache+0x8000>
    80003224:	2b87b703          	ld	a4,696(a5)
    80003228:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000322a:	0001c717          	auipc	a4,0x1c
    8000322e:	de670713          	addi	a4,a4,-538 # 8001f010 <bcache+0x8268>
    80003232:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003234:	2b87b703          	ld	a4,696(a5)
    80003238:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000323a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000323e:	00014517          	auipc	a0,0x14
    80003242:	b6a50513          	addi	a0,a0,-1174 # 80016da8 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	a58080e7          	jalr	-1448(ra) # 80000c9e <release>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6902                	ld	s2,0(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret
    panic("brelse");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	2e650513          	addi	a0,a0,742 # 80008540 <syscalls+0xf0>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2e2080e7          	jalr	738(ra) # 80000544 <panic>

000000008000326a <bpin>:

void
bpin(struct buf *b) {
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	e426                	sd	s1,8(sp)
    80003272:	1000                	addi	s0,sp,32
    80003274:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	b3250513          	addi	a0,a0,-1230 # 80016da8 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	96c080e7          	jalr	-1684(ra) # 80000bea <acquire>
  b->refcnt++;
    80003286:	40bc                	lw	a5,64(s1)
    80003288:	2785                	addiw	a5,a5,1
    8000328a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000328c:	00014517          	auipc	a0,0x14
    80003290:	b1c50513          	addi	a0,a0,-1252 # 80016da8 <bcache>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	a0a080e7          	jalr	-1526(ra) # 80000c9e <release>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret

00000000800032a6 <bunpin>:

void
bunpin(struct buf *b) {
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	1000                	addi	s0,sp,32
    800032b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	af650513          	addi	a0,a0,-1290 # 80016da8 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	930080e7          	jalr	-1744(ra) # 80000bea <acquire>
  b->refcnt--;
    800032c2:	40bc                	lw	a5,64(s1)
    800032c4:	37fd                	addiw	a5,a5,-1
    800032c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c8:	00014517          	auipc	a0,0x14
    800032cc:	ae050513          	addi	a0,a0,-1312 # 80016da8 <bcache>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	9ce080e7          	jalr	-1586(ra) # 80000c9e <release>
}
    800032d8:	60e2                	ld	ra,24(sp)
    800032da:	6442                	ld	s0,16(sp)
    800032dc:	64a2                	ld	s1,8(sp)
    800032de:	6105                	addi	sp,sp,32
    800032e0:	8082                	ret

00000000800032e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032e2:	1101                	addi	sp,sp,-32
    800032e4:	ec06                	sd	ra,24(sp)
    800032e6:	e822                	sd	s0,16(sp)
    800032e8:	e426                	sd	s1,8(sp)
    800032ea:	e04a                	sd	s2,0(sp)
    800032ec:	1000                	addi	s0,sp,32
    800032ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032f0:	00d5d59b          	srliw	a1,a1,0xd
    800032f4:	0001c797          	auipc	a5,0x1c
    800032f8:	1907a783          	lw	a5,400(a5) # 8001f484 <sb+0x1c>
    800032fc:	9dbd                	addw	a1,a1,a5
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	d9e080e7          	jalr	-610(ra) # 8000309c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003306:	0074f713          	andi	a4,s1,7
    8000330a:	4785                	li	a5,1
    8000330c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003310:	14ce                	slli	s1,s1,0x33
    80003312:	90d9                	srli	s1,s1,0x36
    80003314:	00950733          	add	a4,a0,s1
    80003318:	05874703          	lbu	a4,88(a4)
    8000331c:	00e7f6b3          	and	a3,a5,a4
    80003320:	c69d                	beqz	a3,8000334e <bfree+0x6c>
    80003322:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003324:	94aa                	add	s1,s1,a0
    80003326:	fff7c793          	not	a5,a5
    8000332a:	8ff9                	and	a5,a5,a4
    8000332c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003330:	00001097          	auipc	ra,0x1
    80003334:	120080e7          	jalr	288(ra) # 80004450 <log_write>
  brelse(bp);
    80003338:	854a                	mv	a0,s2
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e92080e7          	jalr	-366(ra) # 800031cc <brelse>
}
    80003342:	60e2                	ld	ra,24(sp)
    80003344:	6442                	ld	s0,16(sp)
    80003346:	64a2                	ld	s1,8(sp)
    80003348:	6902                	ld	s2,0(sp)
    8000334a:	6105                	addi	sp,sp,32
    8000334c:	8082                	ret
    panic("freeing free block");
    8000334e:	00005517          	auipc	a0,0x5
    80003352:	1fa50513          	addi	a0,a0,506 # 80008548 <syscalls+0xf8>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	1ee080e7          	jalr	494(ra) # 80000544 <panic>

000000008000335e <balloc>:
{
    8000335e:	711d                	addi	sp,sp,-96
    80003360:	ec86                	sd	ra,88(sp)
    80003362:	e8a2                	sd	s0,80(sp)
    80003364:	e4a6                	sd	s1,72(sp)
    80003366:	e0ca                	sd	s2,64(sp)
    80003368:	fc4e                	sd	s3,56(sp)
    8000336a:	f852                	sd	s4,48(sp)
    8000336c:	f456                	sd	s5,40(sp)
    8000336e:	f05a                	sd	s6,32(sp)
    80003370:	ec5e                	sd	s7,24(sp)
    80003372:	e862                	sd	s8,16(sp)
    80003374:	e466                	sd	s9,8(sp)
    80003376:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003378:	0001c797          	auipc	a5,0x1c
    8000337c:	0f47a783          	lw	a5,244(a5) # 8001f46c <sb+0x4>
    80003380:	10078163          	beqz	a5,80003482 <balloc+0x124>
    80003384:	8baa                	mv	s7,a0
    80003386:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003388:	0001cb17          	auipc	s6,0x1c
    8000338c:	0e0b0b13          	addi	s6,s6,224 # 8001f468 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003392:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003394:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003396:	6c89                	lui	s9,0x2
    80003398:	a061                	j	80003420 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000339a:	974a                	add	a4,a4,s2
    8000339c:	8fd5                	or	a5,a5,a3
    8000339e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033a2:	854a                	mv	a0,s2
    800033a4:	00001097          	auipc	ra,0x1
    800033a8:	0ac080e7          	jalr	172(ra) # 80004450 <log_write>
        brelse(bp);
    800033ac:	854a                	mv	a0,s2
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e1e080e7          	jalr	-482(ra) # 800031cc <brelse>
  bp = bread(dev, bno);
    800033b6:	85a6                	mv	a1,s1
    800033b8:	855e                	mv	a0,s7
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	ce2080e7          	jalr	-798(ra) # 8000309c <bread>
    800033c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c4:	40000613          	li	a2,1024
    800033c8:	4581                	li	a1,0
    800033ca:	05850513          	addi	a0,a0,88
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	918080e7          	jalr	-1768(ra) # 80000ce6 <memset>
  log_write(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	078080e7          	jalr	120(ra) # 80004450 <log_write>
  brelse(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	dea080e7          	jalr	-534(ra) # 800031cc <brelse>
}
    800033ea:	8526                	mv	a0,s1
    800033ec:	60e6                	ld	ra,88(sp)
    800033ee:	6446                	ld	s0,80(sp)
    800033f0:	64a6                	ld	s1,72(sp)
    800033f2:	6906                	ld	s2,64(sp)
    800033f4:	79e2                	ld	s3,56(sp)
    800033f6:	7a42                	ld	s4,48(sp)
    800033f8:	7aa2                	ld	s5,40(sp)
    800033fa:	7b02                	ld	s6,32(sp)
    800033fc:	6be2                	ld	s7,24(sp)
    800033fe:	6c42                	ld	s8,16(sp)
    80003400:	6ca2                	ld	s9,8(sp)
    80003402:	6125                	addi	sp,sp,96
    80003404:	8082                	ret
    brelse(bp);
    80003406:	854a                	mv	a0,s2
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	dc4080e7          	jalr	-572(ra) # 800031cc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003410:	015c87bb          	addw	a5,s9,s5
    80003414:	00078a9b          	sext.w	s5,a5
    80003418:	004b2703          	lw	a4,4(s6)
    8000341c:	06eaf363          	bgeu	s5,a4,80003482 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003420:	41fad79b          	sraiw	a5,s5,0x1f
    80003424:	0137d79b          	srliw	a5,a5,0x13
    80003428:	015787bb          	addw	a5,a5,s5
    8000342c:	40d7d79b          	sraiw	a5,a5,0xd
    80003430:	01cb2583          	lw	a1,28(s6)
    80003434:	9dbd                	addw	a1,a1,a5
    80003436:	855e                	mv	a0,s7
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	c64080e7          	jalr	-924(ra) # 8000309c <bread>
    80003440:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003442:	004b2503          	lw	a0,4(s6)
    80003446:	000a849b          	sext.w	s1,s5
    8000344a:	8662                	mv	a2,s8
    8000344c:	faa4fde3          	bgeu	s1,a0,80003406 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003450:	41f6579b          	sraiw	a5,a2,0x1f
    80003454:	01d7d69b          	srliw	a3,a5,0x1d
    80003458:	00c6873b          	addw	a4,a3,a2
    8000345c:	00777793          	andi	a5,a4,7
    80003460:	9f95                	subw	a5,a5,a3
    80003462:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003466:	4037571b          	sraiw	a4,a4,0x3
    8000346a:	00e906b3          	add	a3,s2,a4
    8000346e:	0586c683          	lbu	a3,88(a3)
    80003472:	00d7f5b3          	and	a1,a5,a3
    80003476:	d195                	beqz	a1,8000339a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003478:	2605                	addiw	a2,a2,1
    8000347a:	2485                	addiw	s1,s1,1
    8000347c:	fd4618e3          	bne	a2,s4,8000344c <balloc+0xee>
    80003480:	b759                	j	80003406 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003482:	00005517          	auipc	a0,0x5
    80003486:	0de50513          	addi	a0,a0,222 # 80008560 <syscalls+0x110>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	104080e7          	jalr	260(ra) # 8000058e <printf>
  return 0;
    80003492:	4481                	li	s1,0
    80003494:	bf99                	j	800033ea <balloc+0x8c>

0000000080003496 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	e052                	sd	s4,0(sp)
    800034a4:	1800                	addi	s0,sp,48
    800034a6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034a8:	47ad                	li	a5,11
    800034aa:	02b7e763          	bltu	a5,a1,800034d8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034ae:	02059493          	slli	s1,a1,0x20
    800034b2:	9081                	srli	s1,s1,0x20
    800034b4:	048a                	slli	s1,s1,0x2
    800034b6:	94aa                	add	s1,s1,a0
    800034b8:	0504a903          	lw	s2,80(s1)
    800034bc:	06091e63          	bnez	s2,80003538 <bmap+0xa2>
      addr = balloc(ip->dev);
    800034c0:	4108                	lw	a0,0(a0)
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	e9c080e7          	jalr	-356(ra) # 8000335e <balloc>
    800034ca:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034ce:	06090563          	beqz	s2,80003538 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034d2:	0524a823          	sw	s2,80(s1)
    800034d6:	a08d                	j	80003538 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034d8:	ff45849b          	addiw	s1,a1,-12
    800034dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e0:	0ff00793          	li	a5,255
    800034e4:	08e7e563          	bltu	a5,a4,8000356e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034e8:	08052903          	lw	s2,128(a0)
    800034ec:	00091d63          	bnez	s2,80003506 <bmap+0x70>
      addr = balloc(ip->dev);
    800034f0:	4108                	lw	a0,0(a0)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e6c080e7          	jalr	-404(ra) # 8000335e <balloc>
    800034fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034fe:	02090d63          	beqz	s2,80003538 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003502:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003506:	85ca                	mv	a1,s2
    80003508:	0009a503          	lw	a0,0(s3)
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	b90080e7          	jalr	-1136(ra) # 8000309c <bread>
    80003514:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003516:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000351a:	02049593          	slli	a1,s1,0x20
    8000351e:	9181                	srli	a1,a1,0x20
    80003520:	058a                	slli	a1,a1,0x2
    80003522:	00b784b3          	add	s1,a5,a1
    80003526:	0004a903          	lw	s2,0(s1)
    8000352a:	02090063          	beqz	s2,8000354a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000352e:	8552                	mv	a0,s4
    80003530:	00000097          	auipc	ra,0x0
    80003534:	c9c080e7          	jalr	-868(ra) # 800031cc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003538:	854a                	mv	a0,s2
    8000353a:	70a2                	ld	ra,40(sp)
    8000353c:	7402                	ld	s0,32(sp)
    8000353e:	64e2                	ld	s1,24(sp)
    80003540:	6942                	ld	s2,16(sp)
    80003542:	69a2                	ld	s3,8(sp)
    80003544:	6a02                	ld	s4,0(sp)
    80003546:	6145                	addi	sp,sp,48
    80003548:	8082                	ret
      addr = balloc(ip->dev);
    8000354a:	0009a503          	lw	a0,0(s3)
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	e10080e7          	jalr	-496(ra) # 8000335e <balloc>
    80003556:	0005091b          	sext.w	s2,a0
      if(addr){
    8000355a:	fc090ae3          	beqz	s2,8000352e <bmap+0x98>
        a[bn] = addr;
    8000355e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003562:	8552                	mv	a0,s4
    80003564:	00001097          	auipc	ra,0x1
    80003568:	eec080e7          	jalr	-276(ra) # 80004450 <log_write>
    8000356c:	b7c9                	j	8000352e <bmap+0x98>
  panic("bmap: out of range");
    8000356e:	00005517          	auipc	a0,0x5
    80003572:	00a50513          	addi	a0,a0,10 # 80008578 <syscalls+0x128>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	fce080e7          	jalr	-50(ra) # 80000544 <panic>

000000008000357e <iget>:
{
    8000357e:	7179                	addi	sp,sp,-48
    80003580:	f406                	sd	ra,40(sp)
    80003582:	f022                	sd	s0,32(sp)
    80003584:	ec26                	sd	s1,24(sp)
    80003586:	e84a                	sd	s2,16(sp)
    80003588:	e44e                	sd	s3,8(sp)
    8000358a:	e052                	sd	s4,0(sp)
    8000358c:	1800                	addi	s0,sp,48
    8000358e:	89aa                	mv	s3,a0
    80003590:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003592:	0001c517          	auipc	a0,0x1c
    80003596:	ef650513          	addi	a0,a0,-266 # 8001f488 <itable>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	650080e7          	jalr	1616(ra) # 80000bea <acquire>
  empty = 0;
    800035a2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035a4:	0001c497          	auipc	s1,0x1c
    800035a8:	efc48493          	addi	s1,s1,-260 # 8001f4a0 <itable+0x18>
    800035ac:	0001e697          	auipc	a3,0x1e
    800035b0:	98468693          	addi	a3,a3,-1660 # 80020f30 <log>
    800035b4:	a039                	j	800035c2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b6:	02090b63          	beqz	s2,800035ec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ba:	08848493          	addi	s1,s1,136
    800035be:	02d48a63          	beq	s1,a3,800035f2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035c2:	449c                	lw	a5,8(s1)
    800035c4:	fef059e3          	blez	a5,800035b6 <iget+0x38>
    800035c8:	4098                	lw	a4,0(s1)
    800035ca:	ff3716e3          	bne	a4,s3,800035b6 <iget+0x38>
    800035ce:	40d8                	lw	a4,4(s1)
    800035d0:	ff4713e3          	bne	a4,s4,800035b6 <iget+0x38>
      ip->ref++;
    800035d4:	2785                	addiw	a5,a5,1
    800035d6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035d8:	0001c517          	auipc	a0,0x1c
    800035dc:	eb050513          	addi	a0,a0,-336 # 8001f488 <itable>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	6be080e7          	jalr	1726(ra) # 80000c9e <release>
      return ip;
    800035e8:	8926                	mv	s2,s1
    800035ea:	a03d                	j	80003618 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ec:	f7f9                	bnez	a5,800035ba <iget+0x3c>
    800035ee:	8926                	mv	s2,s1
    800035f0:	b7e9                	j	800035ba <iget+0x3c>
  if(empty == 0)
    800035f2:	02090c63          	beqz	s2,8000362a <iget+0xac>
  ip->dev = dev;
    800035f6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035fa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035fe:	4785                	li	a5,1
    80003600:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003604:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003608:	0001c517          	auipc	a0,0x1c
    8000360c:	e8050513          	addi	a0,a0,-384 # 8001f488 <itable>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	68e080e7          	jalr	1678(ra) # 80000c9e <release>
}
    80003618:	854a                	mv	a0,s2
    8000361a:	70a2                	ld	ra,40(sp)
    8000361c:	7402                	ld	s0,32(sp)
    8000361e:	64e2                	ld	s1,24(sp)
    80003620:	6942                	ld	s2,16(sp)
    80003622:	69a2                	ld	s3,8(sp)
    80003624:	6a02                	ld	s4,0(sp)
    80003626:	6145                	addi	sp,sp,48
    80003628:	8082                	ret
    panic("iget: no inodes");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	f6650513          	addi	a0,a0,-154 # 80008590 <syscalls+0x140>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f12080e7          	jalr	-238(ra) # 80000544 <panic>

000000008000363a <fsinit>:
fsinit(int dev) {
    8000363a:	7179                	addi	sp,sp,-48
    8000363c:	f406                	sd	ra,40(sp)
    8000363e:	f022                	sd	s0,32(sp)
    80003640:	ec26                	sd	s1,24(sp)
    80003642:	e84a                	sd	s2,16(sp)
    80003644:	e44e                	sd	s3,8(sp)
    80003646:	1800                	addi	s0,sp,48
    80003648:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000364a:	4585                	li	a1,1
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	a50080e7          	jalr	-1456(ra) # 8000309c <bread>
    80003654:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003656:	0001c997          	auipc	s3,0x1c
    8000365a:	e1298993          	addi	s3,s3,-494 # 8001f468 <sb>
    8000365e:	02000613          	li	a2,32
    80003662:	05850593          	addi	a1,a0,88
    80003666:	854e                	mv	a0,s3
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	6de080e7          	jalr	1758(ra) # 80000d46 <memmove>
  brelse(bp);
    80003670:	8526                	mv	a0,s1
    80003672:	00000097          	auipc	ra,0x0
    80003676:	b5a080e7          	jalr	-1190(ra) # 800031cc <brelse>
  if(sb.magic != FSMAGIC)
    8000367a:	0009a703          	lw	a4,0(s3)
    8000367e:	102037b7          	lui	a5,0x10203
    80003682:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003686:	02f71263          	bne	a4,a5,800036aa <fsinit+0x70>
  initlog(dev, &sb);
    8000368a:	0001c597          	auipc	a1,0x1c
    8000368e:	dde58593          	addi	a1,a1,-546 # 8001f468 <sb>
    80003692:	854a                	mv	a0,s2
    80003694:	00001097          	auipc	ra,0x1
    80003698:	b40080e7          	jalr	-1216(ra) # 800041d4 <initlog>
}
    8000369c:	70a2                	ld	ra,40(sp)
    8000369e:	7402                	ld	s0,32(sp)
    800036a0:	64e2                	ld	s1,24(sp)
    800036a2:	6942                	ld	s2,16(sp)
    800036a4:	69a2                	ld	s3,8(sp)
    800036a6:	6145                	addi	sp,sp,48
    800036a8:	8082                	ret
    panic("invalid file system");
    800036aa:	00005517          	auipc	a0,0x5
    800036ae:	ef650513          	addi	a0,a0,-266 # 800085a0 <syscalls+0x150>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	e92080e7          	jalr	-366(ra) # 80000544 <panic>

00000000800036ba <iinit>:
{
    800036ba:	7179                	addi	sp,sp,-48
    800036bc:	f406                	sd	ra,40(sp)
    800036be:	f022                	sd	s0,32(sp)
    800036c0:	ec26                	sd	s1,24(sp)
    800036c2:	e84a                	sd	s2,16(sp)
    800036c4:	e44e                	sd	s3,8(sp)
    800036c6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036c8:	00005597          	auipc	a1,0x5
    800036cc:	ef058593          	addi	a1,a1,-272 # 800085b8 <syscalls+0x168>
    800036d0:	0001c517          	auipc	a0,0x1c
    800036d4:	db850513          	addi	a0,a0,-584 # 8001f488 <itable>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	482080e7          	jalr	1154(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800036e0:	0001c497          	auipc	s1,0x1c
    800036e4:	dd048493          	addi	s1,s1,-560 # 8001f4b0 <itable+0x28>
    800036e8:	0001e997          	auipc	s3,0x1e
    800036ec:	85898993          	addi	s3,s3,-1960 # 80020f40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036f0:	00005917          	auipc	s2,0x5
    800036f4:	ed090913          	addi	s2,s2,-304 # 800085c0 <syscalls+0x170>
    800036f8:	85ca                	mv	a1,s2
    800036fa:	8526                	mv	a0,s1
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	e3a080e7          	jalr	-454(ra) # 80004536 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003704:	08848493          	addi	s1,s1,136
    80003708:	ff3498e3          	bne	s1,s3,800036f8 <iinit+0x3e>
}
    8000370c:	70a2                	ld	ra,40(sp)
    8000370e:	7402                	ld	s0,32(sp)
    80003710:	64e2                	ld	s1,24(sp)
    80003712:	6942                	ld	s2,16(sp)
    80003714:	69a2                	ld	s3,8(sp)
    80003716:	6145                	addi	sp,sp,48
    80003718:	8082                	ret

000000008000371a <ialloc>:
{
    8000371a:	715d                	addi	sp,sp,-80
    8000371c:	e486                	sd	ra,72(sp)
    8000371e:	e0a2                	sd	s0,64(sp)
    80003720:	fc26                	sd	s1,56(sp)
    80003722:	f84a                	sd	s2,48(sp)
    80003724:	f44e                	sd	s3,40(sp)
    80003726:	f052                	sd	s4,32(sp)
    80003728:	ec56                	sd	s5,24(sp)
    8000372a:	e85a                	sd	s6,16(sp)
    8000372c:	e45e                	sd	s7,8(sp)
    8000372e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003730:	0001c717          	auipc	a4,0x1c
    80003734:	d4472703          	lw	a4,-700(a4) # 8001f474 <sb+0xc>
    80003738:	4785                	li	a5,1
    8000373a:	04e7fa63          	bgeu	a5,a4,8000378e <ialloc+0x74>
    8000373e:	8aaa                	mv	s5,a0
    80003740:	8bae                	mv	s7,a1
    80003742:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003744:	0001ca17          	auipc	s4,0x1c
    80003748:	d24a0a13          	addi	s4,s4,-732 # 8001f468 <sb>
    8000374c:	00048b1b          	sext.w	s6,s1
    80003750:	0044d593          	srli	a1,s1,0x4
    80003754:	018a2783          	lw	a5,24(s4)
    80003758:	9dbd                	addw	a1,a1,a5
    8000375a:	8556                	mv	a0,s5
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	940080e7          	jalr	-1728(ra) # 8000309c <bread>
    80003764:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003766:	05850993          	addi	s3,a0,88
    8000376a:	00f4f793          	andi	a5,s1,15
    8000376e:	079a                	slli	a5,a5,0x6
    80003770:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003772:	00099783          	lh	a5,0(s3)
    80003776:	c3a1                	beqz	a5,800037b6 <ialloc+0x9c>
    brelse(bp);
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	a54080e7          	jalr	-1452(ra) # 800031cc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003780:	0485                	addi	s1,s1,1
    80003782:	00ca2703          	lw	a4,12(s4)
    80003786:	0004879b          	sext.w	a5,s1
    8000378a:	fce7e1e3          	bltu	a5,a4,8000374c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000378e:	00005517          	auipc	a0,0x5
    80003792:	e3a50513          	addi	a0,a0,-454 # 800085c8 <syscalls+0x178>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	df8080e7          	jalr	-520(ra) # 8000058e <printf>
  return 0;
    8000379e:	4501                	li	a0,0
}
    800037a0:	60a6                	ld	ra,72(sp)
    800037a2:	6406                	ld	s0,64(sp)
    800037a4:	74e2                	ld	s1,56(sp)
    800037a6:	7942                	ld	s2,48(sp)
    800037a8:	79a2                	ld	s3,40(sp)
    800037aa:	7a02                	ld	s4,32(sp)
    800037ac:	6ae2                	ld	s5,24(sp)
    800037ae:	6b42                	ld	s6,16(sp)
    800037b0:	6ba2                	ld	s7,8(sp)
    800037b2:	6161                	addi	sp,sp,80
    800037b4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037b6:	04000613          	li	a2,64
    800037ba:	4581                	li	a1,0
    800037bc:	854e                	mv	a0,s3
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	528080e7          	jalr	1320(ra) # 80000ce6 <memset>
      dip->type = type;
    800037c6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ca:	854a                	mv	a0,s2
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	c84080e7          	jalr	-892(ra) # 80004450 <log_write>
      brelse(bp);
    800037d4:	854a                	mv	a0,s2
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	9f6080e7          	jalr	-1546(ra) # 800031cc <brelse>
      return iget(dev, inum);
    800037de:	85da                	mv	a1,s6
    800037e0:	8556                	mv	a0,s5
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	d9c080e7          	jalr	-612(ra) # 8000357e <iget>
    800037ea:	bf5d                	j	800037a0 <ialloc+0x86>

00000000800037ec <iupdate>:
{
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	e04a                	sd	s2,0(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fa:	415c                	lw	a5,4(a0)
    800037fc:	0047d79b          	srliw	a5,a5,0x4
    80003800:	0001c597          	auipc	a1,0x1c
    80003804:	c805a583          	lw	a1,-896(a1) # 8001f480 <sb+0x18>
    80003808:	9dbd                	addw	a1,a1,a5
    8000380a:	4108                	lw	a0,0(a0)
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	890080e7          	jalr	-1904(ra) # 8000309c <bread>
    80003814:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003816:	05850793          	addi	a5,a0,88
    8000381a:	40c8                	lw	a0,4(s1)
    8000381c:	893d                	andi	a0,a0,15
    8000381e:	051a                	slli	a0,a0,0x6
    80003820:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003822:	04449703          	lh	a4,68(s1)
    80003826:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000382a:	04649703          	lh	a4,70(s1)
    8000382e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003832:	04849703          	lh	a4,72(s1)
    80003836:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000383a:	04a49703          	lh	a4,74(s1)
    8000383e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003842:	44f8                	lw	a4,76(s1)
    80003844:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003846:	03400613          	li	a2,52
    8000384a:	05048593          	addi	a1,s1,80
    8000384e:	0531                	addi	a0,a0,12
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	4f6080e7          	jalr	1270(ra) # 80000d46 <memmove>
  log_write(bp);
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	bf6080e7          	jalr	-1034(ra) # 80004450 <log_write>
  brelse(bp);
    80003862:	854a                	mv	a0,s2
    80003864:	00000097          	auipc	ra,0x0
    80003868:	968080e7          	jalr	-1688(ra) # 800031cc <brelse>
}
    8000386c:	60e2                	ld	ra,24(sp)
    8000386e:	6442                	ld	s0,16(sp)
    80003870:	64a2                	ld	s1,8(sp)
    80003872:	6902                	ld	s2,0(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret

0000000080003878 <idup>:
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	1000                	addi	s0,sp,32
    80003882:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003884:	0001c517          	auipc	a0,0x1c
    80003888:	c0450513          	addi	a0,a0,-1020 # 8001f488 <itable>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	35e080e7          	jalr	862(ra) # 80000bea <acquire>
  ip->ref++;
    80003894:	449c                	lw	a5,8(s1)
    80003896:	2785                	addiw	a5,a5,1
    80003898:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000389a:	0001c517          	auipc	a0,0x1c
    8000389e:	bee50513          	addi	a0,a0,-1042 # 8001f488 <itable>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	3fc080e7          	jalr	1020(ra) # 80000c9e <release>
}
    800038aa:	8526                	mv	a0,s1
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret

00000000800038b6 <ilock>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038c2:	c115                	beqz	a0,800038e6 <ilock+0x30>
    800038c4:	84aa                	mv	s1,a0
    800038c6:	451c                	lw	a5,8(a0)
    800038c8:	00f05f63          	blez	a5,800038e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038cc:	0541                	addi	a0,a0,16
    800038ce:	00001097          	auipc	ra,0x1
    800038d2:	ca2080e7          	jalr	-862(ra) # 80004570 <acquiresleep>
  if(ip->valid == 0){
    800038d6:	40bc                	lw	a5,64(s1)
    800038d8:	cf99                	beqz	a5,800038f6 <ilock+0x40>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret
    panic("ilock");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	cfa50513          	addi	a0,a0,-774 # 800085e0 <syscalls+0x190>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c56080e7          	jalr	-938(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f6:	40dc                	lw	a5,4(s1)
    800038f8:	0047d79b          	srliw	a5,a5,0x4
    800038fc:	0001c597          	auipc	a1,0x1c
    80003900:	b845a583          	lw	a1,-1148(a1) # 8001f480 <sb+0x18>
    80003904:	9dbd                	addw	a1,a1,a5
    80003906:	4088                	lw	a0,0(s1)
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	794080e7          	jalr	1940(ra) # 8000309c <bread>
    80003910:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003912:	05850593          	addi	a1,a0,88
    80003916:	40dc                	lw	a5,4(s1)
    80003918:	8bbd                	andi	a5,a5,15
    8000391a:	079a                	slli	a5,a5,0x6
    8000391c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000391e:	00059783          	lh	a5,0(a1)
    80003922:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003926:	00259783          	lh	a5,2(a1)
    8000392a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000392e:	00459783          	lh	a5,4(a1)
    80003932:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003936:	00659783          	lh	a5,6(a1)
    8000393a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000393e:	459c                	lw	a5,8(a1)
    80003940:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003942:	03400613          	li	a2,52
    80003946:	05b1                	addi	a1,a1,12
    80003948:	05048513          	addi	a0,s1,80
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	3fa080e7          	jalr	1018(ra) # 80000d46 <memmove>
    brelse(bp);
    80003954:	854a                	mv	a0,s2
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	876080e7          	jalr	-1930(ra) # 800031cc <brelse>
    ip->valid = 1;
    8000395e:	4785                	li	a5,1
    80003960:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003962:	04449783          	lh	a5,68(s1)
    80003966:	fbb5                	bnez	a5,800038da <ilock+0x24>
      panic("ilock: no type");
    80003968:	00005517          	auipc	a0,0x5
    8000396c:	c8050513          	addi	a0,a0,-896 # 800085e8 <syscalls+0x198>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	bd4080e7          	jalr	-1068(ra) # 80000544 <panic>

0000000080003978 <iunlock>:
{
    80003978:	1101                	addi	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	e04a                	sd	s2,0(sp)
    80003982:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003984:	c905                	beqz	a0,800039b4 <iunlock+0x3c>
    80003986:	84aa                	mv	s1,a0
    80003988:	01050913          	addi	s2,a0,16
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	c7c080e7          	jalr	-900(ra) # 8000460a <holdingsleep>
    80003996:	cd19                	beqz	a0,800039b4 <iunlock+0x3c>
    80003998:	449c                	lw	a5,8(s1)
    8000399a:	00f05d63          	blez	a5,800039b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000399e:	854a                	mv	a0,s2
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	c26080e7          	jalr	-986(ra) # 800045c6 <releasesleep>
}
    800039a8:	60e2                	ld	ra,24(sp)
    800039aa:	6442                	ld	s0,16(sp)
    800039ac:	64a2                	ld	s1,8(sp)
    800039ae:	6902                	ld	s2,0(sp)
    800039b0:	6105                	addi	sp,sp,32
    800039b2:	8082                	ret
    panic("iunlock");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	c4450513          	addi	a0,a0,-956 # 800085f8 <syscalls+0x1a8>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b88080e7          	jalr	-1144(ra) # 80000544 <panic>

00000000800039c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039c4:	7179                	addi	sp,sp,-48
    800039c6:	f406                	sd	ra,40(sp)
    800039c8:	f022                	sd	s0,32(sp)
    800039ca:	ec26                	sd	s1,24(sp)
    800039cc:	e84a                	sd	s2,16(sp)
    800039ce:	e44e                	sd	s3,8(sp)
    800039d0:	e052                	sd	s4,0(sp)
    800039d2:	1800                	addi	s0,sp,48
    800039d4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039d6:	05050493          	addi	s1,a0,80
    800039da:	08050913          	addi	s2,a0,128
    800039de:	a021                	j	800039e6 <itrunc+0x22>
    800039e0:	0491                	addi	s1,s1,4
    800039e2:	01248d63          	beq	s1,s2,800039fc <itrunc+0x38>
    if(ip->addrs[i]){
    800039e6:	408c                	lw	a1,0(s1)
    800039e8:	dde5                	beqz	a1,800039e0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ea:	0009a503          	lw	a0,0(s3)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	8f4080e7          	jalr	-1804(ra) # 800032e2 <bfree>
      ip->addrs[i] = 0;
    800039f6:	0004a023          	sw	zero,0(s1)
    800039fa:	b7dd                	j	800039e0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039fc:	0809a583          	lw	a1,128(s3)
    80003a00:	e185                	bnez	a1,80003a20 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a02:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a06:	854e                	mv	a0,s3
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	de4080e7          	jalr	-540(ra) # 800037ec <iupdate>
}
    80003a10:	70a2                	ld	ra,40(sp)
    80003a12:	7402                	ld	s0,32(sp)
    80003a14:	64e2                	ld	s1,24(sp)
    80003a16:	6942                	ld	s2,16(sp)
    80003a18:	69a2                	ld	s3,8(sp)
    80003a1a:	6a02                	ld	s4,0(sp)
    80003a1c:	6145                	addi	sp,sp,48
    80003a1e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a20:	0009a503          	lw	a0,0(s3)
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	678080e7          	jalr	1656(ra) # 8000309c <bread>
    80003a2c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a2e:	05850493          	addi	s1,a0,88
    80003a32:	45850913          	addi	s2,a0,1112
    80003a36:	a811                	j	80003a4a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a38:	0009a503          	lw	a0,0(s3)
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	8a6080e7          	jalr	-1882(ra) # 800032e2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a44:	0491                	addi	s1,s1,4
    80003a46:	01248563          	beq	s1,s2,80003a50 <itrunc+0x8c>
      if(a[j])
    80003a4a:	408c                	lw	a1,0(s1)
    80003a4c:	dde5                	beqz	a1,80003a44 <itrunc+0x80>
    80003a4e:	b7ed                	j	80003a38 <itrunc+0x74>
    brelse(bp);
    80003a50:	8552                	mv	a0,s4
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	77a080e7          	jalr	1914(ra) # 800031cc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a5a:	0809a583          	lw	a1,128(s3)
    80003a5e:	0009a503          	lw	a0,0(s3)
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	880080e7          	jalr	-1920(ra) # 800032e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a6a:	0809a023          	sw	zero,128(s3)
    80003a6e:	bf51                	j	80003a02 <itrunc+0x3e>

0000000080003a70 <iput>:
{
    80003a70:	1101                	addi	sp,sp,-32
    80003a72:	ec06                	sd	ra,24(sp)
    80003a74:	e822                	sd	s0,16(sp)
    80003a76:	e426                	sd	s1,8(sp)
    80003a78:	e04a                	sd	s2,0(sp)
    80003a7a:	1000                	addi	s0,sp,32
    80003a7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a7e:	0001c517          	auipc	a0,0x1c
    80003a82:	a0a50513          	addi	a0,a0,-1526 # 8001f488 <itable>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	164080e7          	jalr	356(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a8e:	4498                	lw	a4,8(s1)
    80003a90:	4785                	li	a5,1
    80003a92:	02f70363          	beq	a4,a5,80003ab8 <iput+0x48>
  ip->ref--;
    80003a96:	449c                	lw	a5,8(s1)
    80003a98:	37fd                	addiw	a5,a5,-1
    80003a9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a9c:	0001c517          	auipc	a0,0x1c
    80003aa0:	9ec50513          	addi	a0,a0,-1556 # 8001f488 <itable>
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	1fa080e7          	jalr	506(ra) # 80000c9e <release>
}
    80003aac:	60e2                	ld	ra,24(sp)
    80003aae:	6442                	ld	s0,16(sp)
    80003ab0:	64a2                	ld	s1,8(sp)
    80003ab2:	6902                	ld	s2,0(sp)
    80003ab4:	6105                	addi	sp,sp,32
    80003ab6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab8:	40bc                	lw	a5,64(s1)
    80003aba:	dff1                	beqz	a5,80003a96 <iput+0x26>
    80003abc:	04a49783          	lh	a5,74(s1)
    80003ac0:	fbf9                	bnez	a5,80003a96 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ac2:	01048913          	addi	s2,s1,16
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	aa8080e7          	jalr	-1368(ra) # 80004570 <acquiresleep>
    release(&itable.lock);
    80003ad0:	0001c517          	auipc	a0,0x1c
    80003ad4:	9b850513          	addi	a0,a0,-1608 # 8001f488 <itable>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	1c6080e7          	jalr	454(ra) # 80000c9e <release>
    itrunc(ip);
    80003ae0:	8526                	mv	a0,s1
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	ee2080e7          	jalr	-286(ra) # 800039c4 <itrunc>
    ip->type = 0;
    80003aea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003aee:	8526                	mv	a0,s1
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	cfc080e7          	jalr	-772(ra) # 800037ec <iupdate>
    ip->valid = 0;
    80003af8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003afc:	854a                	mv	a0,s2
    80003afe:	00001097          	auipc	ra,0x1
    80003b02:	ac8080e7          	jalr	-1336(ra) # 800045c6 <releasesleep>
    acquire(&itable.lock);
    80003b06:	0001c517          	auipc	a0,0x1c
    80003b0a:	98250513          	addi	a0,a0,-1662 # 8001f488 <itable>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
    80003b16:	b741                	j	80003a96 <iput+0x26>

0000000080003b18 <iunlockput>:
{
    80003b18:	1101                	addi	sp,sp,-32
    80003b1a:	ec06                	sd	ra,24(sp)
    80003b1c:	e822                	sd	s0,16(sp)
    80003b1e:	e426                	sd	s1,8(sp)
    80003b20:	1000                	addi	s0,sp,32
    80003b22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	e54080e7          	jalr	-428(ra) # 80003978 <iunlock>
  iput(ip);
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	f42080e7          	jalr	-190(ra) # 80003a70 <iput>
}
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	64a2                	ld	s1,8(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret

0000000080003b40 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b40:	1141                	addi	sp,sp,-16
    80003b42:	e422                	sd	s0,8(sp)
    80003b44:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b46:	411c                	lw	a5,0(a0)
    80003b48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b4a:	415c                	lw	a5,4(a0)
    80003b4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b4e:	04451783          	lh	a5,68(a0)
    80003b52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b56:	04a51783          	lh	a5,74(a0)
    80003b5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b5e:	04c56783          	lwu	a5,76(a0)
    80003b62:	e99c                	sd	a5,16(a1)
}
    80003b64:	6422                	ld	s0,8(sp)
    80003b66:	0141                	addi	sp,sp,16
    80003b68:	8082                	ret

0000000080003b6a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6a:	457c                	lw	a5,76(a0)
    80003b6c:	0ed7e963          	bltu	a5,a3,80003c5e <readi+0xf4>
{
    80003b70:	7159                	addi	sp,sp,-112
    80003b72:	f486                	sd	ra,104(sp)
    80003b74:	f0a2                	sd	s0,96(sp)
    80003b76:	eca6                	sd	s1,88(sp)
    80003b78:	e8ca                	sd	s2,80(sp)
    80003b7a:	e4ce                	sd	s3,72(sp)
    80003b7c:	e0d2                	sd	s4,64(sp)
    80003b7e:	fc56                	sd	s5,56(sp)
    80003b80:	f85a                	sd	s6,48(sp)
    80003b82:	f45e                	sd	s7,40(sp)
    80003b84:	f062                	sd	s8,32(sp)
    80003b86:	ec66                	sd	s9,24(sp)
    80003b88:	e86a                	sd	s10,16(sp)
    80003b8a:	e46e                	sd	s11,8(sp)
    80003b8c:	1880                	addi	s0,sp,112
    80003b8e:	8b2a                	mv	s6,a0
    80003b90:	8bae                	mv	s7,a1
    80003b92:	8a32                	mv	s4,a2
    80003b94:	84b6                	mv	s1,a3
    80003b96:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b98:	9f35                	addw	a4,a4,a3
    return 0;
    80003b9a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b9c:	0ad76063          	bltu	a4,a3,80003c3c <readi+0xd2>
  if(off + n > ip->size)
    80003ba0:	00e7f463          	bgeu	a5,a4,80003ba8 <readi+0x3e>
    n = ip->size - off;
    80003ba4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba8:	0a0a8963          	beqz	s5,80003c5a <readi+0xf0>
    80003bac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bae:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bb2:	5c7d                	li	s8,-1
    80003bb4:	a82d                	j	80003bee <readi+0x84>
    80003bb6:	020d1d93          	slli	s11,s10,0x20
    80003bba:	020ddd93          	srli	s11,s11,0x20
    80003bbe:	05890613          	addi	a2,s2,88
    80003bc2:	86ee                	mv	a3,s11
    80003bc4:	963a                	add	a2,a2,a4
    80003bc6:	85d2                	mv	a1,s4
    80003bc8:	855e                	mv	a0,s7
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	8c8080e7          	jalr	-1848(ra) # 80002492 <either_copyout>
    80003bd2:	05850d63          	beq	a0,s8,80003c2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	5f4080e7          	jalr	1524(ra) # 800031cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be0:	013d09bb          	addw	s3,s10,s3
    80003be4:	009d04bb          	addw	s1,s10,s1
    80003be8:	9a6e                	add	s4,s4,s11
    80003bea:	0559f763          	bgeu	s3,s5,80003c38 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bee:	00a4d59b          	srliw	a1,s1,0xa
    80003bf2:	855a                	mv	a0,s6
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	8a2080e7          	jalr	-1886(ra) # 80003496 <bmap>
    80003bfc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c00:	cd85                	beqz	a1,80003c38 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c02:	000b2503          	lw	a0,0(s6)
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	496080e7          	jalr	1174(ra) # 8000309c <bread>
    80003c0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c10:	3ff4f713          	andi	a4,s1,1023
    80003c14:	40ec87bb          	subw	a5,s9,a4
    80003c18:	413a86bb          	subw	a3,s5,s3
    80003c1c:	8d3e                	mv	s10,a5
    80003c1e:	2781                	sext.w	a5,a5
    80003c20:	0006861b          	sext.w	a2,a3
    80003c24:	f8f679e3          	bgeu	a2,a5,80003bb6 <readi+0x4c>
    80003c28:	8d36                	mv	s10,a3
    80003c2a:	b771                	j	80003bb6 <readi+0x4c>
      brelse(bp);
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	59e080e7          	jalr	1438(ra) # 800031cc <brelse>
      tot = -1;
    80003c36:	59fd                	li	s3,-1
  }
  return tot;
    80003c38:	0009851b          	sext.w	a0,s3
}
    80003c3c:	70a6                	ld	ra,104(sp)
    80003c3e:	7406                	ld	s0,96(sp)
    80003c40:	64e6                	ld	s1,88(sp)
    80003c42:	6946                	ld	s2,80(sp)
    80003c44:	69a6                	ld	s3,72(sp)
    80003c46:	6a06                	ld	s4,64(sp)
    80003c48:	7ae2                	ld	s5,56(sp)
    80003c4a:	7b42                	ld	s6,48(sp)
    80003c4c:	7ba2                	ld	s7,40(sp)
    80003c4e:	7c02                	ld	s8,32(sp)
    80003c50:	6ce2                	ld	s9,24(sp)
    80003c52:	6d42                	ld	s10,16(sp)
    80003c54:	6da2                	ld	s11,8(sp)
    80003c56:	6165                	addi	sp,sp,112
    80003c58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5a:	89d6                	mv	s3,s5
    80003c5c:	bff1                	j	80003c38 <readi+0xce>
    return 0;
    80003c5e:	4501                	li	a0,0
}
    80003c60:	8082                	ret

0000000080003c62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c62:	457c                	lw	a5,76(a0)
    80003c64:	10d7e863          	bltu	a5,a3,80003d74 <writei+0x112>
{
    80003c68:	7159                	addi	sp,sp,-112
    80003c6a:	f486                	sd	ra,104(sp)
    80003c6c:	f0a2                	sd	s0,96(sp)
    80003c6e:	eca6                	sd	s1,88(sp)
    80003c70:	e8ca                	sd	s2,80(sp)
    80003c72:	e4ce                	sd	s3,72(sp)
    80003c74:	e0d2                	sd	s4,64(sp)
    80003c76:	fc56                	sd	s5,56(sp)
    80003c78:	f85a                	sd	s6,48(sp)
    80003c7a:	f45e                	sd	s7,40(sp)
    80003c7c:	f062                	sd	s8,32(sp)
    80003c7e:	ec66                	sd	s9,24(sp)
    80003c80:	e86a                	sd	s10,16(sp)
    80003c82:	e46e                	sd	s11,8(sp)
    80003c84:	1880                	addi	s0,sp,112
    80003c86:	8aaa                	mv	s5,a0
    80003c88:	8bae                	mv	s7,a1
    80003c8a:	8a32                	mv	s4,a2
    80003c8c:	8936                	mv	s2,a3
    80003c8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c90:	00e687bb          	addw	a5,a3,a4
    80003c94:	0ed7e263          	bltu	a5,a3,80003d78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c98:	00043737          	lui	a4,0x43
    80003c9c:	0ef76063          	bltu	a4,a5,80003d7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca0:	0c0b0863          	beqz	s6,80003d70 <writei+0x10e>
    80003ca4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003caa:	5c7d                	li	s8,-1
    80003cac:	a091                	j	80003cf0 <writei+0x8e>
    80003cae:	020d1d93          	slli	s11,s10,0x20
    80003cb2:	020ddd93          	srli	s11,s11,0x20
    80003cb6:	05848513          	addi	a0,s1,88
    80003cba:	86ee                	mv	a3,s11
    80003cbc:	8652                	mv	a2,s4
    80003cbe:	85de                	mv	a1,s7
    80003cc0:	953a                	add	a0,a0,a4
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	826080e7          	jalr	-2010(ra) # 800024e8 <either_copyin>
    80003cca:	07850263          	beq	a0,s8,80003d2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cce:	8526                	mv	a0,s1
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	780080e7          	jalr	1920(ra) # 80004450 <log_write>
    brelse(bp);
    80003cd8:	8526                	mv	a0,s1
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	4f2080e7          	jalr	1266(ra) # 800031cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce2:	013d09bb          	addw	s3,s10,s3
    80003ce6:	012d093b          	addw	s2,s10,s2
    80003cea:	9a6e                	add	s4,s4,s11
    80003cec:	0569f663          	bgeu	s3,s6,80003d38 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cf0:	00a9559b          	srliw	a1,s2,0xa
    80003cf4:	8556                	mv	a0,s5
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	7a0080e7          	jalr	1952(ra) # 80003496 <bmap>
    80003cfe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d02:	c99d                	beqz	a1,80003d38 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d04:	000aa503          	lw	a0,0(s5)
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	394080e7          	jalr	916(ra) # 8000309c <bread>
    80003d10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d12:	3ff97713          	andi	a4,s2,1023
    80003d16:	40ec87bb          	subw	a5,s9,a4
    80003d1a:	413b06bb          	subw	a3,s6,s3
    80003d1e:	8d3e                	mv	s10,a5
    80003d20:	2781                	sext.w	a5,a5
    80003d22:	0006861b          	sext.w	a2,a3
    80003d26:	f8f674e3          	bgeu	a2,a5,80003cae <writei+0x4c>
    80003d2a:	8d36                	mv	s10,a3
    80003d2c:	b749                	j	80003cae <writei+0x4c>
      brelse(bp);
    80003d2e:	8526                	mv	a0,s1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	49c080e7          	jalr	1180(ra) # 800031cc <brelse>
  }

  if(off > ip->size)
    80003d38:	04caa783          	lw	a5,76(s5)
    80003d3c:	0127f463          	bgeu	a5,s2,80003d44 <writei+0xe2>
    ip->size = off;
    80003d40:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d44:	8556                	mv	a0,s5
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	aa6080e7          	jalr	-1370(ra) # 800037ec <iupdate>

  return tot;
    80003d4e:	0009851b          	sext.w	a0,s3
}
    80003d52:	70a6                	ld	ra,104(sp)
    80003d54:	7406                	ld	s0,96(sp)
    80003d56:	64e6                	ld	s1,88(sp)
    80003d58:	6946                	ld	s2,80(sp)
    80003d5a:	69a6                	ld	s3,72(sp)
    80003d5c:	6a06                	ld	s4,64(sp)
    80003d5e:	7ae2                	ld	s5,56(sp)
    80003d60:	7b42                	ld	s6,48(sp)
    80003d62:	7ba2                	ld	s7,40(sp)
    80003d64:	7c02                	ld	s8,32(sp)
    80003d66:	6ce2                	ld	s9,24(sp)
    80003d68:	6d42                	ld	s10,16(sp)
    80003d6a:	6da2                	ld	s11,8(sp)
    80003d6c:	6165                	addi	sp,sp,112
    80003d6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d70:	89da                	mv	s3,s6
    80003d72:	bfc9                	j	80003d44 <writei+0xe2>
    return -1;
    80003d74:	557d                	li	a0,-1
}
    80003d76:	8082                	ret
    return -1;
    80003d78:	557d                	li	a0,-1
    80003d7a:	bfe1                	j	80003d52 <writei+0xf0>
    return -1;
    80003d7c:	557d                	li	a0,-1
    80003d7e:	bfd1                	j	80003d52 <writei+0xf0>

0000000080003d80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d80:	1141                	addi	sp,sp,-16
    80003d82:	e406                	sd	ra,8(sp)
    80003d84:	e022                	sd	s0,0(sp)
    80003d86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d88:	4639                	li	a2,14
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	034080e7          	jalr	52(ra) # 80000dbe <strncmp>
}
    80003d92:	60a2                	ld	ra,8(sp)
    80003d94:	6402                	ld	s0,0(sp)
    80003d96:	0141                	addi	sp,sp,16
    80003d98:	8082                	ret

0000000080003d9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d9a:	7139                	addi	sp,sp,-64
    80003d9c:	fc06                	sd	ra,56(sp)
    80003d9e:	f822                	sd	s0,48(sp)
    80003da0:	f426                	sd	s1,40(sp)
    80003da2:	f04a                	sd	s2,32(sp)
    80003da4:	ec4e                	sd	s3,24(sp)
    80003da6:	e852                	sd	s4,16(sp)
    80003da8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003daa:	04451703          	lh	a4,68(a0)
    80003dae:	4785                	li	a5,1
    80003db0:	00f71a63          	bne	a4,a5,80003dc4 <dirlookup+0x2a>
    80003db4:	892a                	mv	s2,a0
    80003db6:	89ae                	mv	s3,a1
    80003db8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dba:	457c                	lw	a5,76(a0)
    80003dbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc0:	e79d                	bnez	a5,80003dee <dirlookup+0x54>
    80003dc2:	a8a5                	j	80003e3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc4:	00005517          	auipc	a0,0x5
    80003dc8:	83c50513          	addi	a0,a0,-1988 # 80008600 <syscalls+0x1b0>
    80003dcc:	ffffc097          	auipc	ra,0xffffc
    80003dd0:	778080e7          	jalr	1912(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003dd4:	00005517          	auipc	a0,0x5
    80003dd8:	84450513          	addi	a0,a0,-1980 # 80008618 <syscalls+0x1c8>
    80003ddc:	ffffc097          	auipc	ra,0xffffc
    80003de0:	768080e7          	jalr	1896(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de4:	24c1                	addiw	s1,s1,16
    80003de6:	04c92783          	lw	a5,76(s2)
    80003dea:	04f4f763          	bgeu	s1,a5,80003e38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dee:	4741                	li	a4,16
    80003df0:	86a6                	mv	a3,s1
    80003df2:	fc040613          	addi	a2,s0,-64
    80003df6:	4581                	li	a1,0
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	d70080e7          	jalr	-656(ra) # 80003b6a <readi>
    80003e02:	47c1                	li	a5,16
    80003e04:	fcf518e3          	bne	a0,a5,80003dd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e08:	fc045783          	lhu	a5,-64(s0)
    80003e0c:	dfe1                	beqz	a5,80003de4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e0e:	fc240593          	addi	a1,s0,-62
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	f6c080e7          	jalr	-148(ra) # 80003d80 <namecmp>
    80003e1c:	f561                	bnez	a0,80003de4 <dirlookup+0x4a>
      if(poff)
    80003e1e:	000a0463          	beqz	s4,80003e26 <dirlookup+0x8c>
        *poff = off;
    80003e22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e26:	fc045583          	lhu	a1,-64(s0)
    80003e2a:	00092503          	lw	a0,0(s2)
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	750080e7          	jalr	1872(ra) # 8000357e <iget>
    80003e36:	a011                	j	80003e3a <dirlookup+0xa0>
  return 0;
    80003e38:	4501                	li	a0,0
}
    80003e3a:	70e2                	ld	ra,56(sp)
    80003e3c:	7442                	ld	s0,48(sp)
    80003e3e:	74a2                	ld	s1,40(sp)
    80003e40:	7902                	ld	s2,32(sp)
    80003e42:	69e2                	ld	s3,24(sp)
    80003e44:	6a42                	ld	s4,16(sp)
    80003e46:	6121                	addi	sp,sp,64
    80003e48:	8082                	ret

0000000080003e4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e4a:	711d                	addi	sp,sp,-96
    80003e4c:	ec86                	sd	ra,88(sp)
    80003e4e:	e8a2                	sd	s0,80(sp)
    80003e50:	e4a6                	sd	s1,72(sp)
    80003e52:	e0ca                	sd	s2,64(sp)
    80003e54:	fc4e                	sd	s3,56(sp)
    80003e56:	f852                	sd	s4,48(sp)
    80003e58:	f456                	sd	s5,40(sp)
    80003e5a:	f05a                	sd	s6,32(sp)
    80003e5c:	ec5e                	sd	s7,24(sp)
    80003e5e:	e862                	sd	s8,16(sp)
    80003e60:	e466                	sd	s9,8(sp)
    80003e62:	1080                	addi	s0,sp,96
    80003e64:	84aa                	mv	s1,a0
    80003e66:	8b2e                	mv	s6,a1
    80003e68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e6a:	00054703          	lbu	a4,0(a0)
    80003e6e:	02f00793          	li	a5,47
    80003e72:	02f70363          	beq	a4,a5,80003e98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e76:	ffffe097          	auipc	ra,0xffffe
    80003e7a:	b50080e7          	jalr	-1200(ra) # 800019c6 <myproc>
    80003e7e:	15053503          	ld	a0,336(a0)
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	9f6080e7          	jalr	-1546(ra) # 80003878 <idup>
    80003e8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e8c:	02f00913          	li	s2,47
  len = path - s;
    80003e90:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e92:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e94:	4c05                	li	s8,1
    80003e96:	a865                	j	80003f4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e98:	4585                	li	a1,1
    80003e9a:	4505                	li	a0,1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	6e2080e7          	jalr	1762(ra) # 8000357e <iget>
    80003ea4:	89aa                	mv	s3,a0
    80003ea6:	b7dd                	j	80003e8c <namex+0x42>
      iunlockput(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	c6e080e7          	jalr	-914(ra) # 80003b18 <iunlockput>
      return 0;
    80003eb2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	60e6                	ld	ra,88(sp)
    80003eb8:	6446                	ld	s0,80(sp)
    80003eba:	64a6                	ld	s1,72(sp)
    80003ebc:	6906                	ld	s2,64(sp)
    80003ebe:	79e2                	ld	s3,56(sp)
    80003ec0:	7a42                	ld	s4,48(sp)
    80003ec2:	7aa2                	ld	s5,40(sp)
    80003ec4:	7b02                	ld	s6,32(sp)
    80003ec6:	6be2                	ld	s7,24(sp)
    80003ec8:	6c42                	ld	s8,16(sp)
    80003eca:	6ca2                	ld	s9,8(sp)
    80003ecc:	6125                	addi	sp,sp,96
    80003ece:	8082                	ret
      iunlock(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	aa6080e7          	jalr	-1370(ra) # 80003978 <iunlock>
      return ip;
    80003eda:	bfe9                	j	80003eb4 <namex+0x6a>
      iunlockput(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	c3a080e7          	jalr	-966(ra) # 80003b18 <iunlockput>
      return 0;
    80003ee6:	89d2                	mv	s3,s4
    80003ee8:	b7f1                	j	80003eb4 <namex+0x6a>
  len = path - s;
    80003eea:	40b48633          	sub	a2,s1,a1
    80003eee:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ef2:	094cd463          	bge	s9,s4,80003f7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef6:	4639                	li	a2,14
    80003ef8:	8556                	mv	a0,s5
    80003efa:	ffffd097          	auipc	ra,0xffffd
    80003efe:	e4c080e7          	jalr	-436(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	01279763          	bne	a5,s2,80003f14 <namex+0xca>
    path++;
    80003f0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0c:	0004c783          	lbu	a5,0(s1)
    80003f10:	ff278de3          	beq	a5,s2,80003f0a <namex+0xc0>
    ilock(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	9a0080e7          	jalr	-1632(ra) # 800038b6 <ilock>
    if(ip->type != T_DIR){
    80003f1e:	04499783          	lh	a5,68(s3)
    80003f22:	f98793e3          	bne	a5,s8,80003ea8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f26:	000b0563          	beqz	s6,80003f30 <namex+0xe6>
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	d3cd                	beqz	a5,80003ed0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f30:	865e                	mv	a2,s7
    80003f32:	85d6                	mv	a1,s5
    80003f34:	854e                	mv	a0,s3
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	e64080e7          	jalr	-412(ra) # 80003d9a <dirlookup>
    80003f3e:	8a2a                	mv	s4,a0
    80003f40:	dd51                	beqz	a0,80003edc <namex+0x92>
    iunlockput(ip);
    80003f42:	854e                	mv	a0,s3
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	bd4080e7          	jalr	-1068(ra) # 80003b18 <iunlockput>
    ip = next;
    80003f4c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f4e:	0004c783          	lbu	a5,0(s1)
    80003f52:	05279763          	bne	a5,s2,80003fa0 <namex+0x156>
    path++;
    80003f56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f58:	0004c783          	lbu	a5,0(s1)
    80003f5c:	ff278de3          	beq	a5,s2,80003f56 <namex+0x10c>
  if(*path == 0)
    80003f60:	c79d                	beqz	a5,80003f8e <namex+0x144>
    path++;
    80003f62:	85a6                	mv	a1,s1
  len = path - s;
    80003f64:	8a5e                	mv	s4,s7
    80003f66:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f68:	01278963          	beq	a5,s2,80003f7a <namex+0x130>
    80003f6c:	dfbd                	beqz	a5,80003eea <namex+0xa0>
    path++;
    80003f6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	ff279ce3          	bne	a5,s2,80003f6c <namex+0x122>
    80003f78:	bf8d                	j	80003eea <namex+0xa0>
    memmove(name, s, len);
    80003f7a:	2601                	sext.w	a2,a2
    80003f7c:	8556                	mv	a0,s5
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	dc8080e7          	jalr	-568(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003f86:	9a56                	add	s4,s4,s5
    80003f88:	000a0023          	sb	zero,0(s4)
    80003f8c:	bf9d                	j	80003f02 <namex+0xb8>
  if(nameiparent){
    80003f8e:	f20b03e3          	beqz	s6,80003eb4 <namex+0x6a>
    iput(ip);
    80003f92:	854e                	mv	a0,s3
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	adc080e7          	jalr	-1316(ra) # 80003a70 <iput>
    return 0;
    80003f9c:	4981                	li	s3,0
    80003f9e:	bf19                	j	80003eb4 <namex+0x6a>
  if(*path == 0)
    80003fa0:	d7fd                	beqz	a5,80003f8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	85a6                	mv	a1,s1
    80003fa8:	b7d1                	j	80003f6c <namex+0x122>

0000000080003faa <dirlink>:
{
    80003faa:	7139                	addi	sp,sp,-64
    80003fac:	fc06                	sd	ra,56(sp)
    80003fae:	f822                	sd	s0,48(sp)
    80003fb0:	f426                	sd	s1,40(sp)
    80003fb2:	f04a                	sd	s2,32(sp)
    80003fb4:	ec4e                	sd	s3,24(sp)
    80003fb6:	e852                	sd	s4,16(sp)
    80003fb8:	0080                	addi	s0,sp,64
    80003fba:	892a                	mv	s2,a0
    80003fbc:	8a2e                	mv	s4,a1
    80003fbe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fc0:	4601                	li	a2,0
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	dd8080e7          	jalr	-552(ra) # 80003d9a <dirlookup>
    80003fca:	e93d                	bnez	a0,80004040 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fcc:	04c92483          	lw	s1,76(s2)
    80003fd0:	c49d                	beqz	s1,80003ffe <dirlink+0x54>
    80003fd2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd4:	4741                	li	a4,16
    80003fd6:	86a6                	mv	a3,s1
    80003fd8:	fc040613          	addi	a2,s0,-64
    80003fdc:	4581                	li	a1,0
    80003fde:	854a                	mv	a0,s2
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	b8a080e7          	jalr	-1142(ra) # 80003b6a <readi>
    80003fe8:	47c1                	li	a5,16
    80003fea:	06f51163          	bne	a0,a5,8000404c <dirlink+0xa2>
    if(de.inum == 0)
    80003fee:	fc045783          	lhu	a5,-64(s0)
    80003ff2:	c791                	beqz	a5,80003ffe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff4:	24c1                	addiw	s1,s1,16
    80003ff6:	04c92783          	lw	a5,76(s2)
    80003ffa:	fcf4ede3          	bltu	s1,a5,80003fd4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ffe:	4639                	li	a2,14
    80004000:	85d2                	mv	a1,s4
    80004002:	fc240513          	addi	a0,s0,-62
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	df4080e7          	jalr	-524(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000400e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004012:	4741                	li	a4,16
    80004014:	86a6                	mv	a3,s1
    80004016:	fc040613          	addi	a2,s0,-64
    8000401a:	4581                	li	a1,0
    8000401c:	854a                	mv	a0,s2
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	c44080e7          	jalr	-956(ra) # 80003c62 <writei>
    80004026:	1541                	addi	a0,a0,-16
    80004028:	00a03533          	snez	a0,a0
    8000402c:	40a00533          	neg	a0,a0
}
    80004030:	70e2                	ld	ra,56(sp)
    80004032:	7442                	ld	s0,48(sp)
    80004034:	74a2                	ld	s1,40(sp)
    80004036:	7902                	ld	s2,32(sp)
    80004038:	69e2                	ld	s3,24(sp)
    8000403a:	6a42                	ld	s4,16(sp)
    8000403c:	6121                	addi	sp,sp,64
    8000403e:	8082                	ret
    iput(ip);
    80004040:	00000097          	auipc	ra,0x0
    80004044:	a30080e7          	jalr	-1488(ra) # 80003a70 <iput>
    return -1;
    80004048:	557d                	li	a0,-1
    8000404a:	b7dd                	j	80004030 <dirlink+0x86>
      panic("dirlink read");
    8000404c:	00004517          	auipc	a0,0x4
    80004050:	5dc50513          	addi	a0,a0,1500 # 80008628 <syscalls+0x1d8>
    80004054:	ffffc097          	auipc	ra,0xffffc
    80004058:	4f0080e7          	jalr	1264(ra) # 80000544 <panic>

000000008000405c <namei>:

struct inode*
namei(char *path)
{
    8000405c:	1101                	addi	sp,sp,-32
    8000405e:	ec06                	sd	ra,24(sp)
    80004060:	e822                	sd	s0,16(sp)
    80004062:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004064:	fe040613          	addi	a2,s0,-32
    80004068:	4581                	li	a1,0
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	de0080e7          	jalr	-544(ra) # 80003e4a <namex>
}
    80004072:	60e2                	ld	ra,24(sp)
    80004074:	6442                	ld	s0,16(sp)
    80004076:	6105                	addi	sp,sp,32
    80004078:	8082                	ret

000000008000407a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000407a:	1141                	addi	sp,sp,-16
    8000407c:	e406                	sd	ra,8(sp)
    8000407e:	e022                	sd	s0,0(sp)
    80004080:	0800                	addi	s0,sp,16
    80004082:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004084:	4585                	li	a1,1
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	dc4080e7          	jalr	-572(ra) # 80003e4a <namex>
}
    8000408e:	60a2                	ld	ra,8(sp)
    80004090:	6402                	ld	s0,0(sp)
    80004092:	0141                	addi	sp,sp,16
    80004094:	8082                	ret

0000000080004096 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	e04a                	sd	s2,0(sp)
    800040a0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040a2:	0001d917          	auipc	s2,0x1d
    800040a6:	e8e90913          	addi	s2,s2,-370 # 80020f30 <log>
    800040aa:	01892583          	lw	a1,24(s2)
    800040ae:	02892503          	lw	a0,40(s2)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	fea080e7          	jalr	-22(ra) # 8000309c <bread>
    800040ba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040bc:	02c92683          	lw	a3,44(s2)
    800040c0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040c2:	02d05763          	blez	a3,800040f0 <write_head+0x5a>
    800040c6:	0001d797          	auipc	a5,0x1d
    800040ca:	e9a78793          	addi	a5,a5,-358 # 80020f60 <log+0x30>
    800040ce:	05c50713          	addi	a4,a0,92
    800040d2:	36fd                	addiw	a3,a3,-1
    800040d4:	1682                	slli	a3,a3,0x20
    800040d6:	9281                	srli	a3,a3,0x20
    800040d8:	068a                	slli	a3,a3,0x2
    800040da:	0001d617          	auipc	a2,0x1d
    800040de:	e8a60613          	addi	a2,a2,-374 # 80020f64 <log+0x34>
    800040e2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040e4:	4390                	lw	a2,0(a5)
    800040e6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040e8:	0791                	addi	a5,a5,4
    800040ea:	0711                	addi	a4,a4,4
    800040ec:	fed79ce3          	bne	a5,a3,800040e4 <write_head+0x4e>
  }
  bwrite(buf);
    800040f0:	8526                	mv	a0,s1
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	09c080e7          	jalr	156(ra) # 8000318e <bwrite>
  brelse(buf);
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	0d0080e7          	jalr	208(ra) # 800031cc <brelse>
}
    80004104:	60e2                	ld	ra,24(sp)
    80004106:	6442                	ld	s0,16(sp)
    80004108:	64a2                	ld	s1,8(sp)
    8000410a:	6902                	ld	s2,0(sp)
    8000410c:	6105                	addi	sp,sp,32
    8000410e:	8082                	ret

0000000080004110 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004110:	0001d797          	auipc	a5,0x1d
    80004114:	e4c7a783          	lw	a5,-436(a5) # 80020f5c <log+0x2c>
    80004118:	0af05d63          	blez	a5,800041d2 <install_trans+0xc2>
{
    8000411c:	7139                	addi	sp,sp,-64
    8000411e:	fc06                	sd	ra,56(sp)
    80004120:	f822                	sd	s0,48(sp)
    80004122:	f426                	sd	s1,40(sp)
    80004124:	f04a                	sd	s2,32(sp)
    80004126:	ec4e                	sd	s3,24(sp)
    80004128:	e852                	sd	s4,16(sp)
    8000412a:	e456                	sd	s5,8(sp)
    8000412c:	e05a                	sd	s6,0(sp)
    8000412e:	0080                	addi	s0,sp,64
    80004130:	8b2a                	mv	s6,a0
    80004132:	0001da97          	auipc	s5,0x1d
    80004136:	e2ea8a93          	addi	s5,s5,-466 # 80020f60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000413c:	0001d997          	auipc	s3,0x1d
    80004140:	df498993          	addi	s3,s3,-524 # 80020f30 <log>
    80004144:	a035                	j	80004170 <install_trans+0x60>
      bunpin(dbuf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	15e080e7          	jalr	350(ra) # 800032a6 <bunpin>
    brelse(lbuf);
    80004150:	854a                	mv	a0,s2
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	07a080e7          	jalr	122(ra) # 800031cc <brelse>
    brelse(dbuf);
    8000415a:	8526                	mv	a0,s1
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	070080e7          	jalr	112(ra) # 800031cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004164:	2a05                	addiw	s4,s4,1
    80004166:	0a91                	addi	s5,s5,4
    80004168:	02c9a783          	lw	a5,44(s3)
    8000416c:	04fa5963          	bge	s4,a5,800041be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004170:	0189a583          	lw	a1,24(s3)
    80004174:	014585bb          	addw	a1,a1,s4
    80004178:	2585                	addiw	a1,a1,1
    8000417a:	0289a503          	lw	a0,40(s3)
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	f1e080e7          	jalr	-226(ra) # 8000309c <bread>
    80004186:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004188:	000aa583          	lw	a1,0(s5)
    8000418c:	0289a503          	lw	a0,40(s3)
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f0c080e7          	jalr	-244(ra) # 8000309c <bread>
    80004198:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000419a:	40000613          	li	a2,1024
    8000419e:	05890593          	addi	a1,s2,88
    800041a2:	05850513          	addi	a0,a0,88
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	ba0080e7          	jalr	-1120(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ae:	8526                	mv	a0,s1
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	fde080e7          	jalr	-34(ra) # 8000318e <bwrite>
    if(recovering == 0)
    800041b8:	f80b1ce3          	bnez	s6,80004150 <install_trans+0x40>
    800041bc:	b769                	j	80004146 <install_trans+0x36>
}
    800041be:	70e2                	ld	ra,56(sp)
    800041c0:	7442                	ld	s0,48(sp)
    800041c2:	74a2                	ld	s1,40(sp)
    800041c4:	7902                	ld	s2,32(sp)
    800041c6:	69e2                	ld	s3,24(sp)
    800041c8:	6a42                	ld	s4,16(sp)
    800041ca:	6aa2                	ld	s5,8(sp)
    800041cc:	6b02                	ld	s6,0(sp)
    800041ce:	6121                	addi	sp,sp,64
    800041d0:	8082                	ret
    800041d2:	8082                	ret

00000000800041d4 <initlog>:
{
    800041d4:	7179                	addi	sp,sp,-48
    800041d6:	f406                	sd	ra,40(sp)
    800041d8:	f022                	sd	s0,32(sp)
    800041da:	ec26                	sd	s1,24(sp)
    800041dc:	e84a                	sd	s2,16(sp)
    800041de:	e44e                	sd	s3,8(sp)
    800041e0:	1800                	addi	s0,sp,48
    800041e2:	892a                	mv	s2,a0
    800041e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e6:	0001d497          	auipc	s1,0x1d
    800041ea:	d4a48493          	addi	s1,s1,-694 # 80020f30 <log>
    800041ee:	00004597          	auipc	a1,0x4
    800041f2:	44a58593          	addi	a1,a1,1098 # 80008638 <syscalls+0x1e8>
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	962080e7          	jalr	-1694(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004200:	0149a583          	lw	a1,20(s3)
    80004204:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004206:	0109a783          	lw	a5,16(s3)
    8000420a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000420c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004210:	854a                	mv	a0,s2
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	e8a080e7          	jalr	-374(ra) # 8000309c <bread>
  log.lh.n = lh->n;
    8000421a:	4d3c                	lw	a5,88(a0)
    8000421c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000421e:	02f05563          	blez	a5,80004248 <initlog+0x74>
    80004222:	05c50713          	addi	a4,a0,92
    80004226:	0001d697          	auipc	a3,0x1d
    8000422a:	d3a68693          	addi	a3,a3,-710 # 80020f60 <log+0x30>
    8000422e:	37fd                	addiw	a5,a5,-1
    80004230:	1782                	slli	a5,a5,0x20
    80004232:	9381                	srli	a5,a5,0x20
    80004234:	078a                	slli	a5,a5,0x2
    80004236:	06050613          	addi	a2,a0,96
    8000423a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000423c:	4310                	lw	a2,0(a4)
    8000423e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004240:	0711                	addi	a4,a4,4
    80004242:	0691                	addi	a3,a3,4
    80004244:	fef71ce3          	bne	a4,a5,8000423c <initlog+0x68>
  brelse(buf);
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	f84080e7          	jalr	-124(ra) # 800031cc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004250:	4505                	li	a0,1
    80004252:	00000097          	auipc	ra,0x0
    80004256:	ebe080e7          	jalr	-322(ra) # 80004110 <install_trans>
  log.lh.n = 0;
    8000425a:	0001d797          	auipc	a5,0x1d
    8000425e:	d007a123          	sw	zero,-766(a5) # 80020f5c <log+0x2c>
  write_head(); // clear the log
    80004262:	00000097          	auipc	ra,0x0
    80004266:	e34080e7          	jalr	-460(ra) # 80004096 <write_head>
}
    8000426a:	70a2                	ld	ra,40(sp)
    8000426c:	7402                	ld	s0,32(sp)
    8000426e:	64e2                	ld	s1,24(sp)
    80004270:	6942                	ld	s2,16(sp)
    80004272:	69a2                	ld	s3,8(sp)
    80004274:	6145                	addi	sp,sp,48
    80004276:	8082                	ret

0000000080004278 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004278:	1101                	addi	sp,sp,-32
    8000427a:	ec06                	sd	ra,24(sp)
    8000427c:	e822                	sd	s0,16(sp)
    8000427e:	e426                	sd	s1,8(sp)
    80004280:	e04a                	sd	s2,0(sp)
    80004282:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004284:	0001d517          	auipc	a0,0x1d
    80004288:	cac50513          	addi	a0,a0,-852 # 80020f30 <log>
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	95e080e7          	jalr	-1698(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004294:	0001d497          	auipc	s1,0x1d
    80004298:	c9c48493          	addi	s1,s1,-868 # 80020f30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429c:	4979                	li	s2,30
    8000429e:	a039                	j	800042ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	dda080e7          	jalr	-550(ra) # 8000207e <sleep>
    if(log.committing){
    800042ac:	50dc                	lw	a5,36(s1)
    800042ae:	fbed                	bnez	a5,800042a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b0:	509c                	lw	a5,32(s1)
    800042b2:	0017871b          	addiw	a4,a5,1
    800042b6:	0007069b          	sext.w	a3,a4
    800042ba:	0027179b          	slliw	a5,a4,0x2
    800042be:	9fb9                	addw	a5,a5,a4
    800042c0:	0017979b          	slliw	a5,a5,0x1
    800042c4:	54d8                	lw	a4,44(s1)
    800042c6:	9fb9                	addw	a5,a5,a4
    800042c8:	00f95963          	bge	s2,a5,800042da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042cc:	85a6                	mv	a1,s1
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	dae080e7          	jalr	-594(ra) # 8000207e <sleep>
    800042d8:	bfd1                	j	800042ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042da:	0001d517          	auipc	a0,0x1d
    800042de:	c5650513          	addi	a0,a0,-938 # 80020f30 <log>
    800042e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	9ba080e7          	jalr	-1606(ra) # 80000c9e <release>
      break;
    }
  }
}
    800042ec:	60e2                	ld	ra,24(sp)
    800042ee:	6442                	ld	s0,16(sp)
    800042f0:	64a2                	ld	s1,8(sp)
    800042f2:	6902                	ld	s2,0(sp)
    800042f4:	6105                	addi	sp,sp,32
    800042f6:	8082                	ret

00000000800042f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042f8:	7139                	addi	sp,sp,-64
    800042fa:	fc06                	sd	ra,56(sp)
    800042fc:	f822                	sd	s0,48(sp)
    800042fe:	f426                	sd	s1,40(sp)
    80004300:	f04a                	sd	s2,32(sp)
    80004302:	ec4e                	sd	s3,24(sp)
    80004304:	e852                	sd	s4,16(sp)
    80004306:	e456                	sd	s5,8(sp)
    80004308:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000430a:	0001d497          	auipc	s1,0x1d
    8000430e:	c2648493          	addi	s1,s1,-986 # 80020f30 <log>
    80004312:	8526                	mv	a0,s1
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	8d6080e7          	jalr	-1834(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000431c:	509c                	lw	a5,32(s1)
    8000431e:	37fd                	addiw	a5,a5,-1
    80004320:	0007891b          	sext.w	s2,a5
    80004324:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004326:	50dc                	lw	a5,36(s1)
    80004328:	efb9                	bnez	a5,80004386 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000432a:	06091663          	bnez	s2,80004396 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000432e:	0001d497          	auipc	s1,0x1d
    80004332:	c0248493          	addi	s1,s1,-1022 # 80020f30 <log>
    80004336:	4785                	li	a5,1
    80004338:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	962080e7          	jalr	-1694(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004344:	54dc                	lw	a5,44(s1)
    80004346:	06f04763          	bgtz	a5,800043b4 <end_op+0xbc>
    acquire(&log.lock);
    8000434a:	0001d497          	auipc	s1,0x1d
    8000434e:	be648493          	addi	s1,s1,-1050 # 80020f30 <log>
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	896080e7          	jalr	-1898(ra) # 80000bea <acquire>
    log.committing = 0;
    8000435c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	d80080e7          	jalr	-640(ra) # 800020e2 <wakeup>
    release(&log.lock);
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	932080e7          	jalr	-1742(ra) # 80000c9e <release>
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	6121                	addi	sp,sp,64
    80004384:	8082                	ret
    panic("log.committing");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2ba50513          	addi	a0,a0,698 # 80008640 <syscalls+0x1f0>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1b6080e7          	jalr	438(ra) # 80000544 <panic>
    wakeup(&log);
    80004396:	0001d497          	auipc	s1,0x1d
    8000439a:	b9a48493          	addi	s1,s1,-1126 # 80020f30 <log>
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	d42080e7          	jalr	-702(ra) # 800020e2 <wakeup>
  release(&log.lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8f4080e7          	jalr	-1804(ra) # 80000c9e <release>
  if(do_commit){
    800043b2:	b7c9                	j	80004374 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b4:	0001da97          	auipc	s5,0x1d
    800043b8:	baca8a93          	addi	s5,s5,-1108 # 80020f60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043bc:	0001da17          	auipc	s4,0x1d
    800043c0:	b74a0a13          	addi	s4,s4,-1164 # 80020f30 <log>
    800043c4:	018a2583          	lw	a1,24(s4)
    800043c8:	012585bb          	addw	a1,a1,s2
    800043cc:	2585                	addiw	a1,a1,1
    800043ce:	028a2503          	lw	a0,40(s4)
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	cca080e7          	jalr	-822(ra) # 8000309c <bread>
    800043da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043dc:	000aa583          	lw	a1,0(s5)
    800043e0:	028a2503          	lw	a0,40(s4)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	cb8080e7          	jalr	-840(ra) # 8000309c <bread>
    800043ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ee:	40000613          	li	a2,1024
    800043f2:	05850593          	addi	a1,a0,88
    800043f6:	05848513          	addi	a0,s1,88
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	94c080e7          	jalr	-1716(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	d8a080e7          	jalr	-630(ra) # 8000318e <bwrite>
    brelse(from);
    8000440c:	854e                	mv	a0,s3
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	dbe080e7          	jalr	-578(ra) # 800031cc <brelse>
    brelse(to);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	db4080e7          	jalr	-588(ra) # 800031cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004420:	2905                	addiw	s2,s2,1
    80004422:	0a91                	addi	s5,s5,4
    80004424:	02ca2783          	lw	a5,44(s4)
    80004428:	f8f94ee3          	blt	s2,a5,800043c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	c6a080e7          	jalr	-918(ra) # 80004096 <write_head>
    install_trans(0); // Now install writes to home locations
    80004434:	4501                	li	a0,0
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	cda080e7          	jalr	-806(ra) # 80004110 <install_trans>
    log.lh.n = 0;
    8000443e:	0001d797          	auipc	a5,0x1d
    80004442:	b007af23          	sw	zero,-1250(a5) # 80020f5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	c50080e7          	jalr	-944(ra) # 80004096 <write_head>
    8000444e:	bdf5                	j	8000434a <end_op+0x52>

0000000080004450 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004450:	1101                	addi	sp,sp,-32
    80004452:	ec06                	sd	ra,24(sp)
    80004454:	e822                	sd	s0,16(sp)
    80004456:	e426                	sd	s1,8(sp)
    80004458:	e04a                	sd	s2,0(sp)
    8000445a:	1000                	addi	s0,sp,32
    8000445c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000445e:	0001d917          	auipc	s2,0x1d
    80004462:	ad290913          	addi	s2,s2,-1326 # 80020f30 <log>
    80004466:	854a                	mv	a0,s2
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	782080e7          	jalr	1922(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004470:	02c92603          	lw	a2,44(s2)
    80004474:	47f5                	li	a5,29
    80004476:	06c7c563          	blt	a5,a2,800044e0 <log_write+0x90>
    8000447a:	0001d797          	auipc	a5,0x1d
    8000447e:	ad27a783          	lw	a5,-1326(a5) # 80020f4c <log+0x1c>
    80004482:	37fd                	addiw	a5,a5,-1
    80004484:	04f65e63          	bge	a2,a5,800044e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004488:	0001d797          	auipc	a5,0x1d
    8000448c:	ac87a783          	lw	a5,-1336(a5) # 80020f50 <log+0x20>
    80004490:	06f05063          	blez	a5,800044f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004494:	4781                	li	a5,0
    80004496:	06c05563          	blez	a2,80004500 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000449a:	44cc                	lw	a1,12(s1)
    8000449c:	0001d717          	auipc	a4,0x1d
    800044a0:	ac470713          	addi	a4,a4,-1340 # 80020f60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044a6:	4314                	lw	a3,0(a4)
    800044a8:	04b68c63          	beq	a3,a1,80004500 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ac:	2785                	addiw	a5,a5,1
    800044ae:	0711                	addi	a4,a4,4
    800044b0:	fef61be3          	bne	a2,a5,800044a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044b4:	0621                	addi	a2,a2,8
    800044b6:	060a                	slli	a2,a2,0x2
    800044b8:	0001d797          	auipc	a5,0x1d
    800044bc:	a7878793          	addi	a5,a5,-1416 # 80020f30 <log>
    800044c0:	963e                	add	a2,a2,a5
    800044c2:	44dc                	lw	a5,12(s1)
    800044c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	da2080e7          	jalr	-606(ra) # 8000326a <bpin>
    log.lh.n++;
    800044d0:	0001d717          	auipc	a4,0x1d
    800044d4:	a6070713          	addi	a4,a4,-1440 # 80020f30 <log>
    800044d8:	575c                	lw	a5,44(a4)
    800044da:	2785                	addiw	a5,a5,1
    800044dc:	d75c                	sw	a5,44(a4)
    800044de:	a835                	j	8000451a <log_write+0xca>
    panic("too big a transaction");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	17050513          	addi	a0,a0,368 # 80008650 <syscalls+0x200>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	05c080e7          	jalr	92(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800044f0:	00004517          	auipc	a0,0x4
    800044f4:	17850513          	addi	a0,a0,376 # 80008668 <syscalls+0x218>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	04c080e7          	jalr	76(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004500:	00878713          	addi	a4,a5,8
    80004504:	00271693          	slli	a3,a4,0x2
    80004508:	0001d717          	auipc	a4,0x1d
    8000450c:	a2870713          	addi	a4,a4,-1496 # 80020f30 <log>
    80004510:	9736                	add	a4,a4,a3
    80004512:	44d4                	lw	a3,12(s1)
    80004514:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004516:	faf608e3          	beq	a2,a5,800044c6 <log_write+0x76>
  }
  release(&log.lock);
    8000451a:	0001d517          	auipc	a0,0x1d
    8000451e:	a1650513          	addi	a0,a0,-1514 # 80020f30 <log>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	77c080e7          	jalr	1916(ra) # 80000c9e <release>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004536:	1101                	addi	sp,sp,-32
    80004538:	ec06                	sd	ra,24(sp)
    8000453a:	e822                	sd	s0,16(sp)
    8000453c:	e426                	sd	s1,8(sp)
    8000453e:	e04a                	sd	s2,0(sp)
    80004540:	1000                	addi	s0,sp,32
    80004542:	84aa                	mv	s1,a0
    80004544:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004546:	00004597          	auipc	a1,0x4
    8000454a:	14258593          	addi	a1,a1,322 # 80008688 <syscalls+0x238>
    8000454e:	0521                	addi	a0,a0,8
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	60a080e7          	jalr	1546(ra) # 80000b5a <initlock>
  lk->name = name;
    80004558:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000455c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004560:	0204a423          	sw	zero,40(s1)
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004570:	1101                	addi	sp,sp,-32
    80004572:	ec06                	sd	ra,24(sp)
    80004574:	e822                	sd	s0,16(sp)
    80004576:	e426                	sd	s1,8(sp)
    80004578:	e04a                	sd	s2,0(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000457e:	00850913          	addi	s2,a0,8
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	666080e7          	jalr	1638(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000458c:	409c                	lw	a5,0(s1)
    8000458e:	cb89                	beqz	a5,800045a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004590:	85ca                	mv	a1,s2
    80004592:	8526                	mv	a0,s1
    80004594:	ffffe097          	auipc	ra,0xffffe
    80004598:	aea080e7          	jalr	-1302(ra) # 8000207e <sleep>
  while (lk->locked) {
    8000459c:	409c                	lw	a5,0(s1)
    8000459e:	fbed                	bnez	a5,80004590 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045a0:	4785                	li	a5,1
    800045a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045a4:	ffffd097          	auipc	ra,0xffffd
    800045a8:	422080e7          	jalr	1058(ra) # 800019c6 <myproc>
    800045ac:	591c                	lw	a5,48(a0)
    800045ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045b0:	854a                	mv	a0,s2
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	6ec080e7          	jalr	1772(ra) # 80000c9e <release>
}
    800045ba:	60e2                	ld	ra,24(sp)
    800045bc:	6442                	ld	s0,16(sp)
    800045be:	64a2                	ld	s1,8(sp)
    800045c0:	6902                	ld	s2,0(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret

00000000800045c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	e04a                	sd	s2,0(sp)
    800045d0:	1000                	addi	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d4:	00850913          	addi	s2,a0,8
    800045d8:	854a                	mv	a0,s2
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	610080e7          	jalr	1552(ra) # 80000bea <acquire>
  lk->locked = 0;
    800045e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffe097          	auipc	ra,0xffffe
    800045f0:	af6080e7          	jalr	-1290(ra) # 800020e2 <wakeup>
  release(&lk->lk);
    800045f4:	854a                	mv	a0,s2
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6a8080e7          	jalr	1704(ra) # 80000c9e <release>
}
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6902                	ld	s2,0(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000460a:	7179                	addi	sp,sp,-48
    8000460c:	f406                	sd	ra,40(sp)
    8000460e:	f022                	sd	s0,32(sp)
    80004610:	ec26                	sd	s1,24(sp)
    80004612:	e84a                	sd	s2,16(sp)
    80004614:	e44e                	sd	s3,8(sp)
    80004616:	1800                	addi	s0,sp,48
    80004618:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000461a:	00850913          	addi	s2,a0,8
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5ca080e7          	jalr	1482(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004628:	409c                	lw	a5,0(s1)
    8000462a:	ef99                	bnez	a5,80004648 <holdingsleep+0x3e>
    8000462c:	4481                	li	s1,0
  release(&lk->lk);
    8000462e:	854a                	mv	a0,s2
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	66e080e7          	jalr	1646(ra) # 80000c9e <release>
  return r;
}
    80004638:	8526                	mv	a0,s1
    8000463a:	70a2                	ld	ra,40(sp)
    8000463c:	7402                	ld	s0,32(sp)
    8000463e:	64e2                	ld	s1,24(sp)
    80004640:	6942                	ld	s2,16(sp)
    80004642:	69a2                	ld	s3,8(sp)
    80004644:	6145                	addi	sp,sp,48
    80004646:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004648:	0284a983          	lw	s3,40(s1)
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	37a080e7          	jalr	890(ra) # 800019c6 <myproc>
    80004654:	5904                	lw	s1,48(a0)
    80004656:	413484b3          	sub	s1,s1,s3
    8000465a:	0014b493          	seqz	s1,s1
    8000465e:	bfc1                	j	8000462e <holdingsleep+0x24>

0000000080004660 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004660:	1141                	addi	sp,sp,-16
    80004662:	e406                	sd	ra,8(sp)
    80004664:	e022                	sd	s0,0(sp)
    80004666:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004668:	00004597          	auipc	a1,0x4
    8000466c:	03058593          	addi	a1,a1,48 # 80008698 <syscalls+0x248>
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	a0850513          	addi	a0,a0,-1528 # 80021078 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	4e2080e7          	jalr	1250(ra) # 80000b5a <initlock>
}
    80004680:	60a2                	ld	ra,8(sp)
    80004682:	6402                	ld	s0,0(sp)
    80004684:	0141                	addi	sp,sp,16
    80004686:	8082                	ret

0000000080004688 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004688:	1101                	addi	sp,sp,-32
    8000468a:	ec06                	sd	ra,24(sp)
    8000468c:	e822                	sd	s0,16(sp)
    8000468e:	e426                	sd	s1,8(sp)
    80004690:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004692:	0001d517          	auipc	a0,0x1d
    80004696:	9e650513          	addi	a0,a0,-1562 # 80021078 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	550080e7          	jalr	1360(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a2:	0001d497          	auipc	s1,0x1d
    800046a6:	9ee48493          	addi	s1,s1,-1554 # 80021090 <ftable+0x18>
    800046aa:	0001e717          	auipc	a4,0x1e
    800046ae:	98670713          	addi	a4,a4,-1658 # 80022030 <disk>
    if(f->ref == 0){
    800046b2:	40dc                	lw	a5,4(s1)
    800046b4:	cf99                	beqz	a5,800046d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b6:	02848493          	addi	s1,s1,40
    800046ba:	fee49ce3          	bne	s1,a4,800046b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	9ba50513          	addi	a0,a0,-1606 # 80021078 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5d8080e7          	jalr	1496(ra) # 80000c9e <release>
  return 0;
    800046ce:	4481                	li	s1,0
    800046d0:	a819                	j	800046e6 <filealloc+0x5e>
      f->ref = 1;
    800046d2:	4785                	li	a5,1
    800046d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046d6:	0001d517          	auipc	a0,0x1d
    800046da:	9a250513          	addi	a0,a0,-1630 # 80021078 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5c0080e7          	jalr	1472(ra) # 80000c9e <release>
}
    800046e6:	8526                	mv	a0,s1
    800046e8:	60e2                	ld	ra,24(sp)
    800046ea:	6442                	ld	s0,16(sp)
    800046ec:	64a2                	ld	s1,8(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret

00000000800046f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046f2:	1101                	addi	sp,sp,-32
    800046f4:	ec06                	sd	ra,24(sp)
    800046f6:	e822                	sd	s0,16(sp)
    800046f8:	e426                	sd	s1,8(sp)
    800046fa:	1000                	addi	s0,sp,32
    800046fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046fe:	0001d517          	auipc	a0,0x1d
    80004702:	97a50513          	addi	a0,a0,-1670 # 80021078 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	4e4080e7          	jalr	1252(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000470e:	40dc                	lw	a5,4(s1)
    80004710:	02f05263          	blez	a5,80004734 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004714:	2785                	addiw	a5,a5,1
    80004716:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004718:	0001d517          	auipc	a0,0x1d
    8000471c:	96050513          	addi	a0,a0,-1696 # 80021078 <ftable>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	57e080e7          	jalr	1406(ra) # 80000c9e <release>
  return f;
}
    80004728:	8526                	mv	a0,s1
    8000472a:	60e2                	ld	ra,24(sp)
    8000472c:	6442                	ld	s0,16(sp)
    8000472e:	64a2                	ld	s1,8(sp)
    80004730:	6105                	addi	sp,sp,32
    80004732:	8082                	ret
    panic("filedup");
    80004734:	00004517          	auipc	a0,0x4
    80004738:	f6c50513          	addi	a0,a0,-148 # 800086a0 <syscalls+0x250>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	e08080e7          	jalr	-504(ra) # 80000544 <panic>

0000000080004744 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004744:	7139                	addi	sp,sp,-64
    80004746:	fc06                	sd	ra,56(sp)
    80004748:	f822                	sd	s0,48(sp)
    8000474a:	f426                	sd	s1,40(sp)
    8000474c:	f04a                	sd	s2,32(sp)
    8000474e:	ec4e                	sd	s3,24(sp)
    80004750:	e852                	sd	s4,16(sp)
    80004752:	e456                	sd	s5,8(sp)
    80004754:	0080                	addi	s0,sp,64
    80004756:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004758:	0001d517          	auipc	a0,0x1d
    8000475c:	92050513          	addi	a0,a0,-1760 # 80021078 <ftable>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	48a080e7          	jalr	1162(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004768:	40dc                	lw	a5,4(s1)
    8000476a:	06f05163          	blez	a5,800047cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000476e:	37fd                	addiw	a5,a5,-1
    80004770:	0007871b          	sext.w	a4,a5
    80004774:	c0dc                	sw	a5,4(s1)
    80004776:	06e04363          	bgtz	a4,800047dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000477a:	0004a903          	lw	s2,0(s1)
    8000477e:	0094ca83          	lbu	s5,9(s1)
    80004782:	0104ba03          	ld	s4,16(s1)
    80004786:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000478a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000478e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004792:	0001d517          	auipc	a0,0x1d
    80004796:	8e650513          	addi	a0,a0,-1818 # 80021078 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	504080e7          	jalr	1284(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800047a2:	4785                	li	a5,1
    800047a4:	04f90d63          	beq	s2,a5,800047fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047a8:	3979                	addiw	s2,s2,-2
    800047aa:	4785                	li	a5,1
    800047ac:	0527e063          	bltu	a5,s2,800047ec <fileclose+0xa8>
    begin_op();
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	ac8080e7          	jalr	-1336(ra) # 80004278 <begin_op>
    iput(ff.ip);
    800047b8:	854e                	mv	a0,s3
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	2b6080e7          	jalr	694(ra) # 80003a70 <iput>
    end_op();
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	b36080e7          	jalr	-1226(ra) # 800042f8 <end_op>
    800047ca:	a00d                	j	800047ec <fileclose+0xa8>
    panic("fileclose");
    800047cc:	00004517          	auipc	a0,0x4
    800047d0:	edc50513          	addi	a0,a0,-292 # 800086a8 <syscalls+0x258>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	d70080e7          	jalr	-656(ra) # 80000544 <panic>
    release(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	89c50513          	addi	a0,a0,-1892 # 80021078 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4ba080e7          	jalr	1210(ra) # 80000c9e <release>
  }
}
    800047ec:	70e2                	ld	ra,56(sp)
    800047ee:	7442                	ld	s0,48(sp)
    800047f0:	74a2                	ld	s1,40(sp)
    800047f2:	7902                	ld	s2,32(sp)
    800047f4:	69e2                	ld	s3,24(sp)
    800047f6:	6a42                	ld	s4,16(sp)
    800047f8:	6aa2                	ld	s5,8(sp)
    800047fa:	6121                	addi	sp,sp,64
    800047fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047fe:	85d6                	mv	a1,s5
    80004800:	8552                	mv	a0,s4
    80004802:	00000097          	auipc	ra,0x0
    80004806:	34c080e7          	jalr	844(ra) # 80004b4e <pipeclose>
    8000480a:	b7cd                	j	800047ec <fileclose+0xa8>

000000008000480c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000480c:	715d                	addi	sp,sp,-80
    8000480e:	e486                	sd	ra,72(sp)
    80004810:	e0a2                	sd	s0,64(sp)
    80004812:	fc26                	sd	s1,56(sp)
    80004814:	f84a                	sd	s2,48(sp)
    80004816:	f44e                	sd	s3,40(sp)
    80004818:	0880                	addi	s0,sp,80
    8000481a:	84aa                	mv	s1,a0
    8000481c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000481e:	ffffd097          	auipc	ra,0xffffd
    80004822:	1a8080e7          	jalr	424(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004826:	409c                	lw	a5,0(s1)
    80004828:	37f9                	addiw	a5,a5,-2
    8000482a:	4705                	li	a4,1
    8000482c:	04f76763          	bltu	a4,a5,8000487a <filestat+0x6e>
    80004830:	892a                	mv	s2,a0
    ilock(f->ip);
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	082080e7          	jalr	130(ra) # 800038b6 <ilock>
    stati(f->ip, &st);
    8000483c:	fb840593          	addi	a1,s0,-72
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	2fe080e7          	jalr	766(ra) # 80003b40 <stati>
    iunlock(f->ip);
    8000484a:	6c88                	ld	a0,24(s1)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	12c080e7          	jalr	300(ra) # 80003978 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004854:	46e1                	li	a3,24
    80004856:	fb840613          	addi	a2,s0,-72
    8000485a:	85ce                	mv	a1,s3
    8000485c:	05093503          	ld	a0,80(s2)
    80004860:	ffffd097          	auipc	ra,0xffffd
    80004864:	e24080e7          	jalr	-476(ra) # 80001684 <copyout>
    80004868:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000486c:	60a6                	ld	ra,72(sp)
    8000486e:	6406                	ld	s0,64(sp)
    80004870:	74e2                	ld	s1,56(sp)
    80004872:	7942                	ld	s2,48(sp)
    80004874:	79a2                	ld	s3,40(sp)
    80004876:	6161                	addi	sp,sp,80
    80004878:	8082                	ret
  return -1;
    8000487a:	557d                	li	a0,-1
    8000487c:	bfc5                	j	8000486c <filestat+0x60>

000000008000487e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000487e:	7179                	addi	sp,sp,-48
    80004880:	f406                	sd	ra,40(sp)
    80004882:	f022                	sd	s0,32(sp)
    80004884:	ec26                	sd	s1,24(sp)
    80004886:	e84a                	sd	s2,16(sp)
    80004888:	e44e                	sd	s3,8(sp)
    8000488a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000488c:	00854783          	lbu	a5,8(a0)
    80004890:	c3d5                	beqz	a5,80004934 <fileread+0xb6>
    80004892:	84aa                	mv	s1,a0
    80004894:	89ae                	mv	s3,a1
    80004896:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004898:	411c                	lw	a5,0(a0)
    8000489a:	4705                	li	a4,1
    8000489c:	04e78963          	beq	a5,a4,800048ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a0:	470d                	li	a4,3
    800048a2:	04e78d63          	beq	a5,a4,800048fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a6:	4709                	li	a4,2
    800048a8:	06e79e63          	bne	a5,a4,80004924 <fileread+0xa6>
    ilock(f->ip);
    800048ac:	6d08                	ld	a0,24(a0)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	008080e7          	jalr	8(ra) # 800038b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048b6:	874a                	mv	a4,s2
    800048b8:	5094                	lw	a3,32(s1)
    800048ba:	864e                	mv	a2,s3
    800048bc:	4585                	li	a1,1
    800048be:	6c88                	ld	a0,24(s1)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	2aa080e7          	jalr	682(ra) # 80003b6a <readi>
    800048c8:	892a                	mv	s2,a0
    800048ca:	00a05563          	blez	a0,800048d4 <fileread+0x56>
      f->off += r;
    800048ce:	509c                	lw	a5,32(s1)
    800048d0:	9fa9                	addw	a5,a5,a0
    800048d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048d4:	6c88                	ld	a0,24(s1)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	0a2080e7          	jalr	162(ra) # 80003978 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048de:	854a                	mv	a0,s2
    800048e0:	70a2                	ld	ra,40(sp)
    800048e2:	7402                	ld	s0,32(sp)
    800048e4:	64e2                	ld	s1,24(sp)
    800048e6:	6942                	ld	s2,16(sp)
    800048e8:	69a2                	ld	s3,8(sp)
    800048ea:	6145                	addi	sp,sp,48
    800048ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ee:	6908                	ld	a0,16(a0)
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	3ce080e7          	jalr	974(ra) # 80004cbe <piperead>
    800048f8:	892a                	mv	s2,a0
    800048fa:	b7d5                	j	800048de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048fc:	02451783          	lh	a5,36(a0)
    80004900:	03079693          	slli	a3,a5,0x30
    80004904:	92c1                	srli	a3,a3,0x30
    80004906:	4725                	li	a4,9
    80004908:	02d76863          	bltu	a4,a3,80004938 <fileread+0xba>
    8000490c:	0792                	slli	a5,a5,0x4
    8000490e:	0001c717          	auipc	a4,0x1c
    80004912:	6ca70713          	addi	a4,a4,1738 # 80020fd8 <devsw>
    80004916:	97ba                	add	a5,a5,a4
    80004918:	639c                	ld	a5,0(a5)
    8000491a:	c38d                	beqz	a5,8000493c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000491c:	4505                	li	a0,1
    8000491e:	9782                	jalr	a5
    80004920:	892a                	mv	s2,a0
    80004922:	bf75                	j	800048de <fileread+0x60>
    panic("fileread");
    80004924:	00004517          	auipc	a0,0x4
    80004928:	d9450513          	addi	a0,a0,-620 # 800086b8 <syscalls+0x268>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	c18080e7          	jalr	-1000(ra) # 80000544 <panic>
    return -1;
    80004934:	597d                	li	s2,-1
    80004936:	b765                	j	800048de <fileread+0x60>
      return -1;
    80004938:	597d                	li	s2,-1
    8000493a:	b755                	j	800048de <fileread+0x60>
    8000493c:	597d                	li	s2,-1
    8000493e:	b745                	j	800048de <fileread+0x60>

0000000080004940 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004940:	715d                	addi	sp,sp,-80
    80004942:	e486                	sd	ra,72(sp)
    80004944:	e0a2                	sd	s0,64(sp)
    80004946:	fc26                	sd	s1,56(sp)
    80004948:	f84a                	sd	s2,48(sp)
    8000494a:	f44e                	sd	s3,40(sp)
    8000494c:	f052                	sd	s4,32(sp)
    8000494e:	ec56                	sd	s5,24(sp)
    80004950:	e85a                	sd	s6,16(sp)
    80004952:	e45e                	sd	s7,8(sp)
    80004954:	e062                	sd	s8,0(sp)
    80004956:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004958:	00954783          	lbu	a5,9(a0)
    8000495c:	10078663          	beqz	a5,80004a68 <filewrite+0x128>
    80004960:	892a                	mv	s2,a0
    80004962:	8aae                	mv	s5,a1
    80004964:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004966:	411c                	lw	a5,0(a0)
    80004968:	4705                	li	a4,1
    8000496a:	02e78263          	beq	a5,a4,8000498e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496e:	470d                	li	a4,3
    80004970:	02e78663          	beq	a5,a4,8000499c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004974:	4709                	li	a4,2
    80004976:	0ee79163          	bne	a5,a4,80004a58 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000497a:	0ac05d63          	blez	a2,80004a34 <filewrite+0xf4>
    int i = 0;
    8000497e:	4981                	li	s3,0
    80004980:	6b05                	lui	s6,0x1
    80004982:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004986:	6b85                	lui	s7,0x1
    80004988:	c00b8b9b          	addiw	s7,s7,-1024
    8000498c:	a861                	j	80004a24 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000498e:	6908                	ld	a0,16(a0)
    80004990:	00000097          	auipc	ra,0x0
    80004994:	22e080e7          	jalr	558(ra) # 80004bbe <pipewrite>
    80004998:	8a2a                	mv	s4,a0
    8000499a:	a045                	j	80004a3a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000499c:	02451783          	lh	a5,36(a0)
    800049a0:	03079693          	slli	a3,a5,0x30
    800049a4:	92c1                	srli	a3,a3,0x30
    800049a6:	4725                	li	a4,9
    800049a8:	0cd76263          	bltu	a4,a3,80004a6c <filewrite+0x12c>
    800049ac:	0792                	slli	a5,a5,0x4
    800049ae:	0001c717          	auipc	a4,0x1c
    800049b2:	62a70713          	addi	a4,a4,1578 # 80020fd8 <devsw>
    800049b6:	97ba                	add	a5,a5,a4
    800049b8:	679c                	ld	a5,8(a5)
    800049ba:	cbdd                	beqz	a5,80004a70 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049bc:	4505                	li	a0,1
    800049be:	9782                	jalr	a5
    800049c0:	8a2a                	mv	s4,a0
    800049c2:	a8a5                	j	80004a3a <filewrite+0xfa>
    800049c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	8b0080e7          	jalr	-1872(ra) # 80004278 <begin_op>
      ilock(f->ip);
    800049d0:	01893503          	ld	a0,24(s2)
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	ee2080e7          	jalr	-286(ra) # 800038b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049dc:	8762                	mv	a4,s8
    800049de:	02092683          	lw	a3,32(s2)
    800049e2:	01598633          	add	a2,s3,s5
    800049e6:	4585                	li	a1,1
    800049e8:	01893503          	ld	a0,24(s2)
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	276080e7          	jalr	630(ra) # 80003c62 <writei>
    800049f4:	84aa                	mv	s1,a0
    800049f6:	00a05763          	blez	a0,80004a04 <filewrite+0xc4>
        f->off += r;
    800049fa:	02092783          	lw	a5,32(s2)
    800049fe:	9fa9                	addw	a5,a5,a0
    80004a00:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a04:	01893503          	ld	a0,24(s2)
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	f70080e7          	jalr	-144(ra) # 80003978 <iunlock>
      end_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	8e8080e7          	jalr	-1816(ra) # 800042f8 <end_op>

      if(r != n1){
    80004a18:	009c1f63          	bne	s8,s1,80004a36 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a1c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a20:	0149db63          	bge	s3,s4,80004a36 <filewrite+0xf6>
      int n1 = n - i;
    80004a24:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a28:	84be                	mv	s1,a5
    80004a2a:	2781                	sext.w	a5,a5
    80004a2c:	f8fb5ce3          	bge	s6,a5,800049c4 <filewrite+0x84>
    80004a30:	84de                	mv	s1,s7
    80004a32:	bf49                	j	800049c4 <filewrite+0x84>
    int i = 0;
    80004a34:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a36:	013a1f63          	bne	s4,s3,80004a54 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a3a:	8552                	mv	a0,s4
    80004a3c:	60a6                	ld	ra,72(sp)
    80004a3e:	6406                	ld	s0,64(sp)
    80004a40:	74e2                	ld	s1,56(sp)
    80004a42:	7942                	ld	s2,48(sp)
    80004a44:	79a2                	ld	s3,40(sp)
    80004a46:	7a02                	ld	s4,32(sp)
    80004a48:	6ae2                	ld	s5,24(sp)
    80004a4a:	6b42                	ld	s6,16(sp)
    80004a4c:	6ba2                	ld	s7,8(sp)
    80004a4e:	6c02                	ld	s8,0(sp)
    80004a50:	6161                	addi	sp,sp,80
    80004a52:	8082                	ret
    ret = (i == n ? n : -1);
    80004a54:	5a7d                	li	s4,-1
    80004a56:	b7d5                	j	80004a3a <filewrite+0xfa>
    panic("filewrite");
    80004a58:	00004517          	auipc	a0,0x4
    80004a5c:	c7050513          	addi	a0,a0,-912 # 800086c8 <syscalls+0x278>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	ae4080e7          	jalr	-1308(ra) # 80000544 <panic>
    return -1;
    80004a68:	5a7d                	li	s4,-1
    80004a6a:	bfc1                	j	80004a3a <filewrite+0xfa>
      return -1;
    80004a6c:	5a7d                	li	s4,-1
    80004a6e:	b7f1                	j	80004a3a <filewrite+0xfa>
    80004a70:	5a7d                	li	s4,-1
    80004a72:	b7e1                	j	80004a3a <filewrite+0xfa>

0000000080004a74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a74:	7179                	addi	sp,sp,-48
    80004a76:	f406                	sd	ra,40(sp)
    80004a78:	f022                	sd	s0,32(sp)
    80004a7a:	ec26                	sd	s1,24(sp)
    80004a7c:	e84a                	sd	s2,16(sp)
    80004a7e:	e44e                	sd	s3,8(sp)
    80004a80:	e052                	sd	s4,0(sp)
    80004a82:	1800                	addi	s0,sp,48
    80004a84:	84aa                	mv	s1,a0
    80004a86:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a88:	0005b023          	sd	zero,0(a1)
    80004a8c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	bf8080e7          	jalr	-1032(ra) # 80004688 <filealloc>
    80004a98:	e088                	sd	a0,0(s1)
    80004a9a:	c551                	beqz	a0,80004b26 <pipealloc+0xb2>
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	bec080e7          	jalr	-1044(ra) # 80004688 <filealloc>
    80004aa4:	00aa3023          	sd	a0,0(s4)
    80004aa8:	c92d                	beqz	a0,80004b1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	050080e7          	jalr	80(ra) # 80000afa <kalloc>
    80004ab2:	892a                	mv	s2,a0
    80004ab4:	c125                	beqz	a0,80004b14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ab6:	4985                	li	s3,1
    80004ab8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004abc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ac0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ac4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ac8:	00004597          	auipc	a1,0x4
    80004acc:	c1058593          	addi	a1,a1,-1008 # 800086d8 <syscalls+0x288>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	08a080e7          	jalr	138(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004ad8:	609c                	ld	a5,0(s1)
    80004ada:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ade:	609c                	ld	a5,0(s1)
    80004ae0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ae4:	609c                	ld	a5,0(s1)
    80004ae6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aea:	609c                	ld	a5,0(s1)
    80004aec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004af0:	000a3783          	ld	a5,0(s4)
    80004af4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004af8:	000a3783          	ld	a5,0(s4)
    80004afc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b00:	000a3783          	ld	a5,0(s4)
    80004b04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b08:	000a3783          	ld	a5,0(s4)
    80004b0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b10:	4501                	li	a0,0
    80004b12:	a025                	j	80004b3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b14:	6088                	ld	a0,0(s1)
    80004b16:	e501                	bnez	a0,80004b1e <pipealloc+0xaa>
    80004b18:	a039                	j	80004b26 <pipealloc+0xb2>
    80004b1a:	6088                	ld	a0,0(s1)
    80004b1c:	c51d                	beqz	a0,80004b4a <pipealloc+0xd6>
    fileclose(*f0);
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	c26080e7          	jalr	-986(ra) # 80004744 <fileclose>
  if(*f1)
    80004b26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b2a:	557d                	li	a0,-1
  if(*f1)
    80004b2c:	c799                	beqz	a5,80004b3a <pipealloc+0xc6>
    fileclose(*f1);
    80004b2e:	853e                	mv	a0,a5
    80004b30:	00000097          	auipc	ra,0x0
    80004b34:	c14080e7          	jalr	-1004(ra) # 80004744 <fileclose>
  return -1;
    80004b38:	557d                	li	a0,-1
}
    80004b3a:	70a2                	ld	ra,40(sp)
    80004b3c:	7402                	ld	s0,32(sp)
    80004b3e:	64e2                	ld	s1,24(sp)
    80004b40:	6942                	ld	s2,16(sp)
    80004b42:	69a2                	ld	s3,8(sp)
    80004b44:	6a02                	ld	s4,0(sp)
    80004b46:	6145                	addi	sp,sp,48
    80004b48:	8082                	ret
  return -1;
    80004b4a:	557d                	li	a0,-1
    80004b4c:	b7fd                	j	80004b3a <pipealloc+0xc6>

0000000080004b4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b4e:	1101                	addi	sp,sp,-32
    80004b50:	ec06                	sd	ra,24(sp)
    80004b52:	e822                	sd	s0,16(sp)
    80004b54:	e426                	sd	s1,8(sp)
    80004b56:	e04a                	sd	s2,0(sp)
    80004b58:	1000                	addi	s0,sp,32
    80004b5a:	84aa                	mv	s1,a0
    80004b5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	08c080e7          	jalr	140(ra) # 80000bea <acquire>
  if(writable){
    80004b66:	02090d63          	beqz	s2,80004ba0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b6e:	21848513          	addi	a0,s1,536
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	570080e7          	jalr	1392(ra) # 800020e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b7a:	2204b783          	ld	a5,544(s1)
    80004b7e:	eb95                	bnez	a5,80004bb2 <pipeclose+0x64>
    release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	11c080e7          	jalr	284(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004b8a:	8526                	mv	a0,s1
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	e72080e7          	jalr	-398(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	64a2                	ld	s1,8(sp)
    80004b9a:	6902                	ld	s2,0(sp)
    80004b9c:	6105                	addi	sp,sp,32
    80004b9e:	8082                	ret
    pi->readopen = 0;
    80004ba0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ba4:	21c48513          	addi	a0,s1,540
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	53a080e7          	jalr	1338(ra) # 800020e2 <wakeup>
    80004bb0:	b7e9                	j	80004b7a <pipeclose+0x2c>
    release(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0ea080e7          	jalr	234(ra) # 80000c9e <release>
}
    80004bbc:	bfe1                	j	80004b94 <pipeclose+0x46>

0000000080004bbe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bbe:	7159                	addi	sp,sp,-112
    80004bc0:	f486                	sd	ra,104(sp)
    80004bc2:	f0a2                	sd	s0,96(sp)
    80004bc4:	eca6                	sd	s1,88(sp)
    80004bc6:	e8ca                	sd	s2,80(sp)
    80004bc8:	e4ce                	sd	s3,72(sp)
    80004bca:	e0d2                	sd	s4,64(sp)
    80004bcc:	fc56                	sd	s5,56(sp)
    80004bce:	f85a                	sd	s6,48(sp)
    80004bd0:	f45e                	sd	s7,40(sp)
    80004bd2:	f062                	sd	s8,32(sp)
    80004bd4:	ec66                	sd	s9,24(sp)
    80004bd6:	1880                	addi	s0,sp,112
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	8aae                	mv	s5,a1
    80004bdc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	de8080e7          	jalr	-536(ra) # 800019c6 <myproc>
    80004be6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	000080e7          	jalr	ra # 80000bea <acquire>
  while(i < n){
    80004bf2:	0d405463          	blez	s4,80004cba <pipewrite+0xfc>
    80004bf6:	8ba6                	mv	s7,s1
  int i = 0;
    80004bf8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bfa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bfc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c00:	21c48c13          	addi	s8,s1,540
    80004c04:	a08d                	j	80004c66 <pipewrite+0xa8>
      release(&pi->lock);
    80004c06:	8526                	mv	a0,s1
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	096080e7          	jalr	150(ra) # 80000c9e <release>
      return -1;
    80004c10:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c12:	854a                	mv	a0,s2
    80004c14:	70a6                	ld	ra,104(sp)
    80004c16:	7406                	ld	s0,96(sp)
    80004c18:	64e6                	ld	s1,88(sp)
    80004c1a:	6946                	ld	s2,80(sp)
    80004c1c:	69a6                	ld	s3,72(sp)
    80004c1e:	6a06                	ld	s4,64(sp)
    80004c20:	7ae2                	ld	s5,56(sp)
    80004c22:	7b42                	ld	s6,48(sp)
    80004c24:	7ba2                	ld	s7,40(sp)
    80004c26:	7c02                	ld	s8,32(sp)
    80004c28:	6ce2                	ld	s9,24(sp)
    80004c2a:	6165                	addi	sp,sp,112
    80004c2c:	8082                	ret
      wakeup(&pi->nread);
    80004c2e:	8566                	mv	a0,s9
    80004c30:	ffffd097          	auipc	ra,0xffffd
    80004c34:	4b2080e7          	jalr	1202(ra) # 800020e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c38:	85de                	mv	a1,s7
    80004c3a:	8562                	mv	a0,s8
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	442080e7          	jalr	1090(ra) # 8000207e <sleep>
    80004c44:	a839                	j	80004c62 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c46:	21c4a783          	lw	a5,540(s1)
    80004c4a:	0017871b          	addiw	a4,a5,1
    80004c4e:	20e4ae23          	sw	a4,540(s1)
    80004c52:	1ff7f793          	andi	a5,a5,511
    80004c56:	97a6                	add	a5,a5,s1
    80004c58:	f9f44703          	lbu	a4,-97(s0)
    80004c5c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c60:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c62:	05495063          	bge	s2,s4,80004ca2 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004c66:	2204a783          	lw	a5,544(s1)
    80004c6a:	dfd1                	beqz	a5,80004c06 <pipewrite+0x48>
    80004c6c:	854e                	mv	a0,s3
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	6c4080e7          	jalr	1732(ra) # 80002332 <killed>
    80004c76:	f941                	bnez	a0,80004c06 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c78:	2184a783          	lw	a5,536(s1)
    80004c7c:	21c4a703          	lw	a4,540(s1)
    80004c80:	2007879b          	addiw	a5,a5,512
    80004c84:	faf705e3          	beq	a4,a5,80004c2e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c88:	4685                	li	a3,1
    80004c8a:	01590633          	add	a2,s2,s5
    80004c8e:	f9f40593          	addi	a1,s0,-97
    80004c92:	0509b503          	ld	a0,80(s3)
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	a7a080e7          	jalr	-1414(ra) # 80001710 <copyin>
    80004c9e:	fb6514e3          	bne	a0,s6,80004c46 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ca2:	21848513          	addi	a0,s1,536
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	43c080e7          	jalr	1084(ra) # 800020e2 <wakeup>
  release(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	fee080e7          	jalr	-18(ra) # 80000c9e <release>
  return i;
    80004cb8:	bfa9                	j	80004c12 <pipewrite+0x54>
  int i = 0;
    80004cba:	4901                	li	s2,0
    80004cbc:	b7dd                	j	80004ca2 <pipewrite+0xe4>

0000000080004cbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	715d                	addi	sp,sp,-80
    80004cc0:	e486                	sd	ra,72(sp)
    80004cc2:	e0a2                	sd	s0,64(sp)
    80004cc4:	fc26                	sd	s1,56(sp)
    80004cc6:	f84a                	sd	s2,48(sp)
    80004cc8:	f44e                	sd	s3,40(sp)
    80004cca:	f052                	sd	s4,32(sp)
    80004ccc:	ec56                	sd	s5,24(sp)
    80004cce:	e85a                	sd	s6,16(sp)
    80004cd0:	0880                	addi	s0,sp,80
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	892e                	mv	s2,a1
    80004cd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	cee080e7          	jalr	-786(ra) # 800019c6 <myproc>
    80004ce0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ce2:	8b26                	mv	s6,s1
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	f04080e7          	jalr	-252(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cee:	2184a703          	lw	a4,536(s1)
    80004cf2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfa:	02f71763          	bne	a4,a5,80004d28 <piperead+0x6a>
    80004cfe:	2244a783          	lw	a5,548(s1)
    80004d02:	c39d                	beqz	a5,80004d28 <piperead+0x6a>
    if(killed(pr)){
    80004d04:	8552                	mv	a0,s4
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	62c080e7          	jalr	1580(ra) # 80002332 <killed>
    80004d0e:	e941                	bnez	a0,80004d9e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d10:	85da                	mv	a1,s6
    80004d12:	854e                	mv	a0,s3
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	36a080e7          	jalr	874(ra) # 8000207e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1c:	2184a703          	lw	a4,536(s1)
    80004d20:	21c4a783          	lw	a5,540(s1)
    80004d24:	fcf70de3          	beq	a4,a5,80004cfe <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d28:	09505263          	blez	s5,80004dac <piperead+0xee>
    80004d2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d2e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d30:	2184a783          	lw	a5,536(s1)
    80004d34:	21c4a703          	lw	a4,540(s1)
    80004d38:	02f70d63          	beq	a4,a5,80004d72 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d3c:	0017871b          	addiw	a4,a5,1
    80004d40:	20e4ac23          	sw	a4,536(s1)
    80004d44:	1ff7f793          	andi	a5,a5,511
    80004d48:	97a6                	add	a5,a5,s1
    80004d4a:	0187c783          	lbu	a5,24(a5)
    80004d4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d52:	4685                	li	a3,1
    80004d54:	fbf40613          	addi	a2,s0,-65
    80004d58:	85ca                	mv	a1,s2
    80004d5a:	050a3503          	ld	a0,80(s4)
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	926080e7          	jalr	-1754(ra) # 80001684 <copyout>
    80004d66:	01650663          	beq	a0,s6,80004d72 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d6a:	2985                	addiw	s3,s3,1
    80004d6c:	0905                	addi	s2,s2,1
    80004d6e:	fd3a91e3          	bne	s5,s3,80004d30 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d72:	21c48513          	addi	a0,s1,540
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	36c080e7          	jalr	876(ra) # 800020e2 <wakeup>
  release(&pi->lock);
    80004d7e:	8526                	mv	a0,s1
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f1e080e7          	jalr	-226(ra) # 80000c9e <release>
  return i;
}
    80004d88:	854e                	mv	a0,s3
    80004d8a:	60a6                	ld	ra,72(sp)
    80004d8c:	6406                	ld	s0,64(sp)
    80004d8e:	74e2                	ld	s1,56(sp)
    80004d90:	7942                	ld	s2,48(sp)
    80004d92:	79a2                	ld	s3,40(sp)
    80004d94:	7a02                	ld	s4,32(sp)
    80004d96:	6ae2                	ld	s5,24(sp)
    80004d98:	6b42                	ld	s6,16(sp)
    80004d9a:	6161                	addi	sp,sp,80
    80004d9c:	8082                	ret
      release(&pi->lock);
    80004d9e:	8526                	mv	a0,s1
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	efe080e7          	jalr	-258(ra) # 80000c9e <release>
      return -1;
    80004da8:	59fd                	li	s3,-1
    80004daa:	bff9                	j	80004d88 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dac:	4981                	li	s3,0
    80004dae:	b7d1                	j	80004d72 <piperead+0xb4>

0000000080004db0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004db0:	1141                	addi	sp,sp,-16
    80004db2:	e422                	sd	s0,8(sp)
    80004db4:	0800                	addi	s0,sp,16
    80004db6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004db8:	8905                	andi	a0,a0,1
    80004dba:	c111                	beqz	a0,80004dbe <flags2perm+0xe>
      perm = PTE_X;
    80004dbc:	4521                	li	a0,8
    if(flags & 0x2)
    80004dbe:	8b89                	andi	a5,a5,2
    80004dc0:	c399                	beqz	a5,80004dc6 <flags2perm+0x16>
      perm |= PTE_W;
    80004dc2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dc6:	6422                	ld	s0,8(sp)
    80004dc8:	0141                	addi	sp,sp,16
    80004dca:	8082                	ret

0000000080004dcc <exec>:

int
exec(char *path, char **argv)
{
    80004dcc:	df010113          	addi	sp,sp,-528
    80004dd0:	20113423          	sd	ra,520(sp)
    80004dd4:	20813023          	sd	s0,512(sp)
    80004dd8:	ffa6                	sd	s1,504(sp)
    80004dda:	fbca                	sd	s2,496(sp)
    80004ddc:	f7ce                	sd	s3,488(sp)
    80004dde:	f3d2                	sd	s4,480(sp)
    80004de0:	efd6                	sd	s5,472(sp)
    80004de2:	ebda                	sd	s6,464(sp)
    80004de4:	e7de                	sd	s7,456(sp)
    80004de6:	e3e2                	sd	s8,448(sp)
    80004de8:	ff66                	sd	s9,440(sp)
    80004dea:	fb6a                	sd	s10,432(sp)
    80004dec:	f76e                	sd	s11,424(sp)
    80004dee:	0c00                	addi	s0,sp,528
    80004df0:	84aa                	mv	s1,a0
    80004df2:	dea43c23          	sd	a0,-520(s0)
    80004df6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	bcc080e7          	jalr	-1076(ra) # 800019c6 <myproc>
    80004e02:	892a                	mv	s2,a0

  begin_op();
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	474080e7          	jalr	1140(ra) # 80004278 <begin_op>

  if((ip = namei(path)) == 0){
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	24e080e7          	jalr	590(ra) # 8000405c <namei>
    80004e16:	c92d                	beqz	a0,80004e88 <exec+0xbc>
    80004e18:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	a9c080e7          	jalr	-1380(ra) # 800038b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e22:	04000713          	li	a4,64
    80004e26:	4681                	li	a3,0
    80004e28:	e5040613          	addi	a2,s0,-432
    80004e2c:	4581                	li	a1,0
    80004e2e:	8526                	mv	a0,s1
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	d3a080e7          	jalr	-710(ra) # 80003b6a <readi>
    80004e38:	04000793          	li	a5,64
    80004e3c:	00f51a63          	bne	a0,a5,80004e50 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e40:	e5042703          	lw	a4,-432(s0)
    80004e44:	464c47b7          	lui	a5,0x464c4
    80004e48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e4c:	04f70463          	beq	a4,a5,80004e94 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e50:	8526                	mv	a0,s1
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	cc6080e7          	jalr	-826(ra) # 80003b18 <iunlockput>
    end_op();
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	49e080e7          	jalr	1182(ra) # 800042f8 <end_op>
  }
  return -1;
    80004e62:	557d                	li	a0,-1
}
    80004e64:	20813083          	ld	ra,520(sp)
    80004e68:	20013403          	ld	s0,512(sp)
    80004e6c:	74fe                	ld	s1,504(sp)
    80004e6e:	795e                	ld	s2,496(sp)
    80004e70:	79be                	ld	s3,488(sp)
    80004e72:	7a1e                	ld	s4,480(sp)
    80004e74:	6afe                	ld	s5,472(sp)
    80004e76:	6b5e                	ld	s6,464(sp)
    80004e78:	6bbe                	ld	s7,456(sp)
    80004e7a:	6c1e                	ld	s8,448(sp)
    80004e7c:	7cfa                	ld	s9,440(sp)
    80004e7e:	7d5a                	ld	s10,432(sp)
    80004e80:	7dba                	ld	s11,424(sp)
    80004e82:	21010113          	addi	sp,sp,528
    80004e86:	8082                	ret
    end_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	470080e7          	jalr	1136(ra) # 800042f8 <end_op>
    return -1;
    80004e90:	557d                	li	a0,-1
    80004e92:	bfc9                	j	80004e64 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e94:	854a                	mv	a0,s2
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	bf4080e7          	jalr	-1036(ra) # 80001a8a <proc_pagetable>
    80004e9e:	8baa                	mv	s7,a0
    80004ea0:	d945                	beqz	a0,80004e50 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea2:	e7042983          	lw	s3,-400(s0)
    80004ea6:	e8845783          	lhu	a5,-376(s0)
    80004eaa:	c7ad                	beqz	a5,80004f14 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eac:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eae:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004eb0:	6c85                	lui	s9,0x1
    80004eb2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eb6:	def43823          	sd	a5,-528(s0)
    80004eba:	ac0d                	j	800050ec <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ebc:	00004517          	auipc	a0,0x4
    80004ec0:	82450513          	addi	a0,a0,-2012 # 800086e0 <syscalls+0x290>
    80004ec4:	ffffb097          	auipc	ra,0xffffb
    80004ec8:	680080e7          	jalr	1664(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ecc:	8756                	mv	a4,s5
    80004ece:	012d86bb          	addw	a3,s11,s2
    80004ed2:	4581                	li	a1,0
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	c94080e7          	jalr	-876(ra) # 80003b6a <readi>
    80004ede:	2501                	sext.w	a0,a0
    80004ee0:	1aaa9a63          	bne	s5,a0,80005094 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee4:	6785                	lui	a5,0x1
    80004ee6:	0127893b          	addw	s2,a5,s2
    80004eea:	77fd                	lui	a5,0xfffff
    80004eec:	01478a3b          	addw	s4,a5,s4
    80004ef0:	1f897563          	bgeu	s2,s8,800050da <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004ef4:	02091593          	slli	a1,s2,0x20
    80004ef8:	9181                	srli	a1,a1,0x20
    80004efa:	95ea                	add	a1,a1,s10
    80004efc:	855e                	mv	a0,s7
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	17a080e7          	jalr	378(ra) # 80001078 <walkaddr>
    80004f06:	862a                	mv	a2,a0
    if(pa == 0)
    80004f08:	d955                	beqz	a0,80004ebc <exec+0xf0>
      n = PGSIZE;
    80004f0a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f0c:	fd9a70e3          	bgeu	s4,s9,80004ecc <exec+0x100>
      n = sz - i;
    80004f10:	8ad2                	mv	s5,s4
    80004f12:	bf6d                	j	80004ecc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f14:	4a01                	li	s4,0
  iunlockput(ip);
    80004f16:	8526                	mv	a0,s1
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	c00080e7          	jalr	-1024(ra) # 80003b18 <iunlockput>
  end_op();
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	3d8080e7          	jalr	984(ra) # 800042f8 <end_op>
  p = myproc();
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	a9e080e7          	jalr	-1378(ra) # 800019c6 <myproc>
    80004f30:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f32:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f36:	6785                	lui	a5,0x1
    80004f38:	17fd                	addi	a5,a5,-1
    80004f3a:	9a3e                	add	s4,s4,a5
    80004f3c:	757d                	lui	a0,0xfffff
    80004f3e:	00aa77b3          	and	a5,s4,a0
    80004f42:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f46:	4691                	li	a3,4
    80004f48:	6609                	lui	a2,0x2
    80004f4a:	963e                	add	a2,a2,a5
    80004f4c:	85be                	mv	a1,a5
    80004f4e:	855e                	mv	a0,s7
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	4dc080e7          	jalr	1244(ra) # 8000142c <uvmalloc>
    80004f58:	8b2a                	mv	s6,a0
  ip = 0;
    80004f5a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f5c:	12050c63          	beqz	a0,80005094 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f60:	75f9                	lui	a1,0xffffe
    80004f62:	95aa                	add	a1,a1,a0
    80004f64:	855e                	mv	a0,s7
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	6ec080e7          	jalr	1772(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f6e:	7c7d                	lui	s8,0xfffff
    80004f70:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f72:	e0043783          	ld	a5,-512(s0)
    80004f76:	6388                	ld	a0,0(a5)
    80004f78:	c535                	beqz	a0,80004fe4 <exec+0x218>
    80004f7a:	e9040993          	addi	s3,s0,-368
    80004f7e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f82:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	ee6080e7          	jalr	-282(ra) # 80000e6a <strlen>
    80004f8c:	2505                	addiw	a0,a0,1
    80004f8e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f96:	13896663          	bltu	s2,s8,800050c2 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f9a:	e0043d83          	ld	s11,-512(s0)
    80004f9e:	000dba03          	ld	s4,0(s11)
    80004fa2:	8552                	mv	a0,s4
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	ec6080e7          	jalr	-314(ra) # 80000e6a <strlen>
    80004fac:	0015069b          	addiw	a3,a0,1
    80004fb0:	8652                	mv	a2,s4
    80004fb2:	85ca                	mv	a1,s2
    80004fb4:	855e                	mv	a0,s7
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	6ce080e7          	jalr	1742(ra) # 80001684 <copyout>
    80004fbe:	10054663          	bltz	a0,800050ca <exec+0x2fe>
    ustack[argc] = sp;
    80004fc2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc6:	0485                	addi	s1,s1,1
    80004fc8:	008d8793          	addi	a5,s11,8
    80004fcc:	e0f43023          	sd	a5,-512(s0)
    80004fd0:	008db503          	ld	a0,8(s11)
    80004fd4:	c911                	beqz	a0,80004fe8 <exec+0x21c>
    if(argc >= MAXARG)
    80004fd6:	09a1                	addi	s3,s3,8
    80004fd8:	fb3c96e3          	bne	s9,s3,80004f84 <exec+0x1b8>
  sz = sz1;
    80004fdc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe0:	4481                	li	s1,0
    80004fe2:	a84d                	j	80005094 <exec+0x2c8>
  sp = sz;
    80004fe4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fe6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe8:	00349793          	slli	a5,s1,0x3
    80004fec:	f9040713          	addi	a4,s0,-112
    80004ff0:	97ba                	add	a5,a5,a4
    80004ff2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ff6:	00148693          	addi	a3,s1,1
    80004ffa:	068e                	slli	a3,a3,0x3
    80004ffc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005000:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005004:	01897663          	bgeu	s2,s8,80005010 <exec+0x244>
  sz = sz1;
    80005008:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500c:	4481                	li	s1,0
    8000500e:	a059                	j	80005094 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005010:	e9040613          	addi	a2,s0,-368
    80005014:	85ca                	mv	a1,s2
    80005016:	855e                	mv	a0,s7
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	66c080e7          	jalr	1644(ra) # 80001684 <copyout>
    80005020:	0a054963          	bltz	a0,800050d2 <exec+0x306>
  p->trapframe->a1 = sp;
    80005024:	058ab783          	ld	a5,88(s5)
    80005028:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000502c:	df843783          	ld	a5,-520(s0)
    80005030:	0007c703          	lbu	a4,0(a5)
    80005034:	cf11                	beqz	a4,80005050 <exec+0x284>
    80005036:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005038:	02f00693          	li	a3,47
    8000503c:	a039                	j	8000504a <exec+0x27e>
      last = s+1;
    8000503e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005042:	0785                	addi	a5,a5,1
    80005044:	fff7c703          	lbu	a4,-1(a5)
    80005048:	c701                	beqz	a4,80005050 <exec+0x284>
    if(*s == '/')
    8000504a:	fed71ce3          	bne	a4,a3,80005042 <exec+0x276>
    8000504e:	bfc5                	j	8000503e <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005050:	4641                	li	a2,16
    80005052:	df843583          	ld	a1,-520(s0)
    80005056:	158a8513          	addi	a0,s5,344
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	dde080e7          	jalr	-546(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005062:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005066:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000506a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000506e:	058ab783          	ld	a5,88(s5)
    80005072:	e6843703          	ld	a4,-408(s0)
    80005076:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005078:	058ab783          	ld	a5,88(s5)
    8000507c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005080:	85ea                	mv	a1,s10
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	aa4080e7          	jalr	-1372(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000508a:	0004851b          	sext.w	a0,s1
    8000508e:	bbd9                	j	80004e64 <exec+0x98>
    80005090:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005094:	e0843583          	ld	a1,-504(s0)
    80005098:	855e                	mv	a0,s7
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	a8c080e7          	jalr	-1396(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800050a2:	da0497e3          	bnez	s1,80004e50 <exec+0x84>
  return -1;
    800050a6:	557d                	li	a0,-1
    800050a8:	bb75                	j	80004e64 <exec+0x98>
    800050aa:	e1443423          	sd	s4,-504(s0)
    800050ae:	b7dd                	j	80005094 <exec+0x2c8>
    800050b0:	e1443423          	sd	s4,-504(s0)
    800050b4:	b7c5                	j	80005094 <exec+0x2c8>
    800050b6:	e1443423          	sd	s4,-504(s0)
    800050ba:	bfe9                	j	80005094 <exec+0x2c8>
    800050bc:	e1443423          	sd	s4,-504(s0)
    800050c0:	bfd1                	j	80005094 <exec+0x2c8>
  sz = sz1;
    800050c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c6:	4481                	li	s1,0
    800050c8:	b7f1                	j	80005094 <exec+0x2c8>
  sz = sz1;
    800050ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ce:	4481                	li	s1,0
    800050d0:	b7d1                	j	80005094 <exec+0x2c8>
  sz = sz1;
    800050d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d6:	4481                	li	s1,0
    800050d8:	bf75                	j	80005094 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050da:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050de:	2b05                	addiw	s6,s6,1
    800050e0:	0389899b          	addiw	s3,s3,56
    800050e4:	e8845783          	lhu	a5,-376(s0)
    800050e8:	e2fb57e3          	bge	s6,a5,80004f16 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ec:	2981                	sext.w	s3,s3
    800050ee:	03800713          	li	a4,56
    800050f2:	86ce                	mv	a3,s3
    800050f4:	e1840613          	addi	a2,s0,-488
    800050f8:	4581                	li	a1,0
    800050fa:	8526                	mv	a0,s1
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	a6e080e7          	jalr	-1426(ra) # 80003b6a <readi>
    80005104:	03800793          	li	a5,56
    80005108:	f8f514e3          	bne	a0,a5,80005090 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000510c:	e1842783          	lw	a5,-488(s0)
    80005110:	4705                	li	a4,1
    80005112:	fce796e3          	bne	a5,a4,800050de <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005116:	e4043903          	ld	s2,-448(s0)
    8000511a:	e3843783          	ld	a5,-456(s0)
    8000511e:	f8f966e3          	bltu	s2,a5,800050aa <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005122:	e2843783          	ld	a5,-472(s0)
    80005126:	993e                	add	s2,s2,a5
    80005128:	f8f964e3          	bltu	s2,a5,800050b0 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000512c:	df043703          	ld	a4,-528(s0)
    80005130:	8ff9                	and	a5,a5,a4
    80005132:	f3d1                	bnez	a5,800050b6 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005134:	e1c42503          	lw	a0,-484(s0)
    80005138:	00000097          	auipc	ra,0x0
    8000513c:	c78080e7          	jalr	-904(ra) # 80004db0 <flags2perm>
    80005140:	86aa                	mv	a3,a0
    80005142:	864a                	mv	a2,s2
    80005144:	85d2                	mv	a1,s4
    80005146:	855e                	mv	a0,s7
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	2e4080e7          	jalr	740(ra) # 8000142c <uvmalloc>
    80005150:	e0a43423          	sd	a0,-504(s0)
    80005154:	d525                	beqz	a0,800050bc <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005156:	e2843d03          	ld	s10,-472(s0)
    8000515a:	e2042d83          	lw	s11,-480(s0)
    8000515e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005162:	f60c0ce3          	beqz	s8,800050da <exec+0x30e>
    80005166:	8a62                	mv	s4,s8
    80005168:	4901                	li	s2,0
    8000516a:	b369                	j	80004ef4 <exec+0x128>

000000008000516c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000516c:	7179                	addi	sp,sp,-48
    8000516e:	f406                	sd	ra,40(sp)
    80005170:	f022                	sd	s0,32(sp)
    80005172:	ec26                	sd	s1,24(sp)
    80005174:	e84a                	sd	s2,16(sp)
    80005176:	1800                	addi	s0,sp,48
    80005178:	892e                	mv	s2,a1
    8000517a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000517c:	fdc40593          	addi	a1,s0,-36
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	b2e080e7          	jalr	-1234(ra) # 80002cae <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005188:	fdc42703          	lw	a4,-36(s0)
    8000518c:	47bd                	li	a5,15
    8000518e:	02e7eb63          	bltu	a5,a4,800051c4 <argfd+0x58>
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	834080e7          	jalr	-1996(ra) # 800019c6 <myproc>
    8000519a:	fdc42703          	lw	a4,-36(s0)
    8000519e:	01a70793          	addi	a5,a4,26
    800051a2:	078e                	slli	a5,a5,0x3
    800051a4:	953e                	add	a0,a0,a5
    800051a6:	611c                	ld	a5,0(a0)
    800051a8:	c385                	beqz	a5,800051c8 <argfd+0x5c>
    return -1;
  if(pfd)
    800051aa:	00090463          	beqz	s2,800051b2 <argfd+0x46>
    *pfd = fd;
    800051ae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b2:	4501                	li	a0,0
  if(pf)
    800051b4:	c091                	beqz	s1,800051b8 <argfd+0x4c>
    *pf = f;
    800051b6:	e09c                	sd	a5,0(s1)
}
    800051b8:	70a2                	ld	ra,40(sp)
    800051ba:	7402                	ld	s0,32(sp)
    800051bc:	64e2                	ld	s1,24(sp)
    800051be:	6942                	ld	s2,16(sp)
    800051c0:	6145                	addi	sp,sp,48
    800051c2:	8082                	ret
    return -1;
    800051c4:	557d                	li	a0,-1
    800051c6:	bfcd                	j	800051b8 <argfd+0x4c>
    800051c8:	557d                	li	a0,-1
    800051ca:	b7fd                	j	800051b8 <argfd+0x4c>

00000000800051cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051cc:	1101                	addi	sp,sp,-32
    800051ce:	ec06                	sd	ra,24(sp)
    800051d0:	e822                	sd	s0,16(sp)
    800051d2:	e426                	sd	s1,8(sp)
    800051d4:	1000                	addi	s0,sp,32
    800051d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	7ee080e7          	jalr	2030(ra) # 800019c6 <myproc>
    800051e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdcf60>
    800051e6:	4501                	li	a0,0
    800051e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ea:	6398                	ld	a4,0(a5)
    800051ec:	cb19                	beqz	a4,80005202 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ee:	2505                	addiw	a0,a0,1
    800051f0:	07a1                	addi	a5,a5,8
    800051f2:	fed51ce3          	bne	a0,a3,800051ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f6:	557d                	li	a0,-1
}
    800051f8:	60e2                	ld	ra,24(sp)
    800051fa:	6442                	ld	s0,16(sp)
    800051fc:	64a2                	ld	s1,8(sp)
    800051fe:	6105                	addi	sp,sp,32
    80005200:	8082                	ret
      p->ofile[fd] = f;
    80005202:	01a50793          	addi	a5,a0,26
    80005206:	078e                	slli	a5,a5,0x3
    80005208:	963e                	add	a2,a2,a5
    8000520a:	e204                	sd	s1,0(a2)
      return fd;
    8000520c:	b7f5                	j	800051f8 <fdalloc+0x2c>

000000008000520e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000520e:	715d                	addi	sp,sp,-80
    80005210:	e486                	sd	ra,72(sp)
    80005212:	e0a2                	sd	s0,64(sp)
    80005214:	fc26                	sd	s1,56(sp)
    80005216:	f84a                	sd	s2,48(sp)
    80005218:	f44e                	sd	s3,40(sp)
    8000521a:	f052                	sd	s4,32(sp)
    8000521c:	ec56                	sd	s5,24(sp)
    8000521e:	e85a                	sd	s6,16(sp)
    80005220:	0880                	addi	s0,sp,80
    80005222:	8b2e                	mv	s6,a1
    80005224:	89b2                	mv	s3,a2
    80005226:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005228:	fb040593          	addi	a1,s0,-80
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	e4e080e7          	jalr	-434(ra) # 8000407a <nameiparent>
    80005234:	84aa                	mv	s1,a0
    80005236:	16050063          	beqz	a0,80005396 <create+0x188>
    return 0;

  ilock(dp);
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	67c080e7          	jalr	1660(ra) # 800038b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005242:	4601                	li	a2,0
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	8526                	mv	a0,s1
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	b50080e7          	jalr	-1200(ra) # 80003d9a <dirlookup>
    80005252:	8aaa                	mv	s5,a0
    80005254:	c931                	beqz	a0,800052a8 <create+0x9a>
    iunlockput(dp);
    80005256:	8526                	mv	a0,s1
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	8c0080e7          	jalr	-1856(ra) # 80003b18 <iunlockput>
    ilock(ip);
    80005260:	8556                	mv	a0,s5
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	654080e7          	jalr	1620(ra) # 800038b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000526a:	000b059b          	sext.w	a1,s6
    8000526e:	4789                	li	a5,2
    80005270:	02f59563          	bne	a1,a5,8000529a <create+0x8c>
    80005274:	044ad783          	lhu	a5,68(s5)
    80005278:	37f9                	addiw	a5,a5,-2
    8000527a:	17c2                	slli	a5,a5,0x30
    8000527c:	93c1                	srli	a5,a5,0x30
    8000527e:	4705                	li	a4,1
    80005280:	00f76d63          	bltu	a4,a5,8000529a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005284:	8556                	mv	a0,s5
    80005286:	60a6                	ld	ra,72(sp)
    80005288:	6406                	ld	s0,64(sp)
    8000528a:	74e2                	ld	s1,56(sp)
    8000528c:	7942                	ld	s2,48(sp)
    8000528e:	79a2                	ld	s3,40(sp)
    80005290:	7a02                	ld	s4,32(sp)
    80005292:	6ae2                	ld	s5,24(sp)
    80005294:	6b42                	ld	s6,16(sp)
    80005296:	6161                	addi	sp,sp,80
    80005298:	8082                	ret
    iunlockput(ip);
    8000529a:	8556                	mv	a0,s5
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	87c080e7          	jalr	-1924(ra) # 80003b18 <iunlockput>
    return 0;
    800052a4:	4a81                	li	s5,0
    800052a6:	bff9                	j	80005284 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052a8:	85da                	mv	a1,s6
    800052aa:	4088                	lw	a0,0(s1)
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	46e080e7          	jalr	1134(ra) # 8000371a <ialloc>
    800052b4:	8a2a                	mv	s4,a0
    800052b6:	c921                	beqz	a0,80005306 <create+0xf8>
  ilock(ip);
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	5fe080e7          	jalr	1534(ra) # 800038b6 <ilock>
  ip->major = major;
    800052c0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052c4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052c8:	4785                	li	a5,1
    800052ca:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800052ce:	8552                	mv	a0,s4
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	51c080e7          	jalr	1308(ra) # 800037ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d8:	000b059b          	sext.w	a1,s6
    800052dc:	4785                	li	a5,1
    800052de:	02f58b63          	beq	a1,a5,80005314 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e2:	004a2603          	lw	a2,4(s4)
    800052e6:	fb040593          	addi	a1,s0,-80
    800052ea:	8526                	mv	a0,s1
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	cbe080e7          	jalr	-834(ra) # 80003faa <dirlink>
    800052f4:	06054f63          	bltz	a0,80005372 <create+0x164>
  iunlockput(dp);
    800052f8:	8526                	mv	a0,s1
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	81e080e7          	jalr	-2018(ra) # 80003b18 <iunlockput>
  return ip;
    80005302:	8ad2                	mv	s5,s4
    80005304:	b741                	j	80005284 <create+0x76>
    iunlockput(dp);
    80005306:	8526                	mv	a0,s1
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	810080e7          	jalr	-2032(ra) # 80003b18 <iunlockput>
    return 0;
    80005310:	8ad2                	mv	s5,s4
    80005312:	bf8d                	j	80005284 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005314:	004a2603          	lw	a2,4(s4)
    80005318:	00003597          	auipc	a1,0x3
    8000531c:	3e858593          	addi	a1,a1,1000 # 80008700 <syscalls+0x2b0>
    80005320:	8552                	mv	a0,s4
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	c88080e7          	jalr	-888(ra) # 80003faa <dirlink>
    8000532a:	04054463          	bltz	a0,80005372 <create+0x164>
    8000532e:	40d0                	lw	a2,4(s1)
    80005330:	00003597          	auipc	a1,0x3
    80005334:	3d858593          	addi	a1,a1,984 # 80008708 <syscalls+0x2b8>
    80005338:	8552                	mv	a0,s4
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	c70080e7          	jalr	-912(ra) # 80003faa <dirlink>
    80005342:	02054863          	bltz	a0,80005372 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005346:	004a2603          	lw	a2,4(s4)
    8000534a:	fb040593          	addi	a1,s0,-80
    8000534e:	8526                	mv	a0,s1
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	c5a080e7          	jalr	-934(ra) # 80003faa <dirlink>
    80005358:	00054d63          	bltz	a0,80005372 <create+0x164>
    dp->nlink++;  // for ".."
    8000535c:	04a4d783          	lhu	a5,74(s1)
    80005360:	2785                	addiw	a5,a5,1
    80005362:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005366:	8526                	mv	a0,s1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	484080e7          	jalr	1156(ra) # 800037ec <iupdate>
    80005370:	b761                	j	800052f8 <create+0xea>
  ip->nlink = 0;
    80005372:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005376:	8552                	mv	a0,s4
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	474080e7          	jalr	1140(ra) # 800037ec <iupdate>
  iunlockput(ip);
    80005380:	8552                	mv	a0,s4
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	796080e7          	jalr	1942(ra) # 80003b18 <iunlockput>
  iunlockput(dp);
    8000538a:	8526                	mv	a0,s1
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	78c080e7          	jalr	1932(ra) # 80003b18 <iunlockput>
  return 0;
    80005394:	bdc5                	j	80005284 <create+0x76>
    return 0;
    80005396:	8aaa                	mv	s5,a0
    80005398:	b5f5                	j	80005284 <create+0x76>

000000008000539a <sys_dup>:
{
    8000539a:	7179                	addi	sp,sp,-48
    8000539c:	f406                	sd	ra,40(sp)
    8000539e:	f022                	sd	s0,32(sp)
    800053a0:	ec26                	sd	s1,24(sp)
    800053a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053a4:	fd840613          	addi	a2,s0,-40
    800053a8:	4581                	li	a1,0
    800053aa:	4501                	li	a0,0
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	dc0080e7          	jalr	-576(ra) # 8000516c <argfd>
    return -1;
    800053b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053b6:	02054363          	bltz	a0,800053dc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053ba:	fd843503          	ld	a0,-40(s0)
    800053be:	00000097          	auipc	ra,0x0
    800053c2:	e0e080e7          	jalr	-498(ra) # 800051cc <fdalloc>
    800053c6:	84aa                	mv	s1,a0
    return -1;
    800053c8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ca:	00054963          	bltz	a0,800053dc <sys_dup+0x42>
  filedup(f);
    800053ce:	fd843503          	ld	a0,-40(s0)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	320080e7          	jalr	800(ra) # 800046f2 <filedup>
  return fd;
    800053da:	87a6                	mv	a5,s1
}
    800053dc:	853e                	mv	a0,a5
    800053de:	70a2                	ld	ra,40(sp)
    800053e0:	7402                	ld	s0,32(sp)
    800053e2:	64e2                	ld	s1,24(sp)
    800053e4:	6145                	addi	sp,sp,48
    800053e6:	8082                	ret

00000000800053e8 <sys_getreadcount>:
{
    800053e8:	1141                	addi	sp,sp,-16
    800053ea:	e422                	sd	s0,8(sp)
    800053ec:	0800                	addi	s0,sp,16
}
    800053ee:	00003517          	auipc	a0,0x3
    800053f2:	50652503          	lw	a0,1286(a0) # 800088f4 <readCount>
    800053f6:	6422                	ld	s0,8(sp)
    800053f8:	0141                	addi	sp,sp,16
    800053fa:	8082                	ret

00000000800053fc <sys_read>:
{
    800053fc:	7179                	addi	sp,sp,-48
    800053fe:	f406                	sd	ra,40(sp)
    80005400:	f022                	sd	s0,32(sp)
    80005402:	1800                	addi	s0,sp,48
  readCount++;
    80005404:	00003717          	auipc	a4,0x3
    80005408:	4f070713          	addi	a4,a4,1264 # 800088f4 <readCount>
    8000540c:	431c                	lw	a5,0(a4)
    8000540e:	2785                	addiw	a5,a5,1
    80005410:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005412:	fd840593          	addi	a1,s0,-40
    80005416:	4505                	li	a0,1
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	8b6080e7          	jalr	-1866(ra) # 80002cce <argaddr>
  argint(2, &n);
    80005420:	fe440593          	addi	a1,s0,-28
    80005424:	4509                	li	a0,2
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	888080e7          	jalr	-1912(ra) # 80002cae <argint>
  if(argfd(0, 0, &f) < 0)
    8000542e:	fe840613          	addi	a2,s0,-24
    80005432:	4581                	li	a1,0
    80005434:	4501                	li	a0,0
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	d36080e7          	jalr	-714(ra) # 8000516c <argfd>
    8000543e:	87aa                	mv	a5,a0
    return -1;
    80005440:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005442:	0007cc63          	bltz	a5,8000545a <sys_read+0x5e>
  return fileread(f, p, n);
    80005446:	fe442603          	lw	a2,-28(s0)
    8000544a:	fd843583          	ld	a1,-40(s0)
    8000544e:	fe843503          	ld	a0,-24(s0)
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	42c080e7          	jalr	1068(ra) # 8000487e <fileread>
}
    8000545a:	70a2                	ld	ra,40(sp)
    8000545c:	7402                	ld	s0,32(sp)
    8000545e:	6145                	addi	sp,sp,48
    80005460:	8082                	ret

0000000080005462 <sys_write>:
{
    80005462:	7179                	addi	sp,sp,-48
    80005464:	f406                	sd	ra,40(sp)
    80005466:	f022                	sd	s0,32(sp)
    80005468:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000546a:	fd840593          	addi	a1,s0,-40
    8000546e:	4505                	li	a0,1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	85e080e7          	jalr	-1954(ra) # 80002cce <argaddr>
  argint(2, &n);
    80005478:	fe440593          	addi	a1,s0,-28
    8000547c:	4509                	li	a0,2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	830080e7          	jalr	-2000(ra) # 80002cae <argint>
  if(argfd(0, 0, &f) < 0)
    80005486:	fe840613          	addi	a2,s0,-24
    8000548a:	4581                	li	a1,0
    8000548c:	4501                	li	a0,0
    8000548e:	00000097          	auipc	ra,0x0
    80005492:	cde080e7          	jalr	-802(ra) # 8000516c <argfd>
    80005496:	87aa                	mv	a5,a0
    return -1;
    80005498:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000549a:	0007cc63          	bltz	a5,800054b2 <sys_write+0x50>
  return filewrite(f, p, n);
    8000549e:	fe442603          	lw	a2,-28(s0)
    800054a2:	fd843583          	ld	a1,-40(s0)
    800054a6:	fe843503          	ld	a0,-24(s0)
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	496080e7          	jalr	1174(ra) # 80004940 <filewrite>
}
    800054b2:	70a2                	ld	ra,40(sp)
    800054b4:	7402                	ld	s0,32(sp)
    800054b6:	6145                	addi	sp,sp,48
    800054b8:	8082                	ret

00000000800054ba <sys_close>:
{
    800054ba:	1101                	addi	sp,sp,-32
    800054bc:	ec06                	sd	ra,24(sp)
    800054be:	e822                	sd	s0,16(sp)
    800054c0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054c2:	fe040613          	addi	a2,s0,-32
    800054c6:	fec40593          	addi	a1,s0,-20
    800054ca:	4501                	li	a0,0
    800054cc:	00000097          	auipc	ra,0x0
    800054d0:	ca0080e7          	jalr	-864(ra) # 8000516c <argfd>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054d6:	02054463          	bltz	a0,800054fe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	4ec080e7          	jalr	1260(ra) # 800019c6 <myproc>
    800054e2:	fec42783          	lw	a5,-20(s0)
    800054e6:	07e9                	addi	a5,a5,26
    800054e8:	078e                	slli	a5,a5,0x3
    800054ea:	97aa                	add	a5,a5,a0
    800054ec:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054f0:	fe043503          	ld	a0,-32(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	250080e7          	jalr	592(ra) # 80004744 <fileclose>
  return 0;
    800054fc:	4781                	li	a5,0
}
    800054fe:	853e                	mv	a0,a5
    80005500:	60e2                	ld	ra,24(sp)
    80005502:	6442                	ld	s0,16(sp)
    80005504:	6105                	addi	sp,sp,32
    80005506:	8082                	ret

0000000080005508 <sys_fstat>:
{
    80005508:	1101                	addi	sp,sp,-32
    8000550a:	ec06                	sd	ra,24(sp)
    8000550c:	e822                	sd	s0,16(sp)
    8000550e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005510:	fe040593          	addi	a1,s0,-32
    80005514:	4505                	li	a0,1
    80005516:	ffffd097          	auipc	ra,0xffffd
    8000551a:	7b8080e7          	jalr	1976(ra) # 80002cce <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000551e:	fe840613          	addi	a2,s0,-24
    80005522:	4581                	li	a1,0
    80005524:	4501                	li	a0,0
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	c46080e7          	jalr	-954(ra) # 8000516c <argfd>
    8000552e:	87aa                	mv	a5,a0
    return -1;
    80005530:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005532:	0007ca63          	bltz	a5,80005546 <sys_fstat+0x3e>
  return filestat(f, st);
    80005536:	fe043583          	ld	a1,-32(s0)
    8000553a:	fe843503          	ld	a0,-24(s0)
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	2ce080e7          	jalr	718(ra) # 8000480c <filestat>
}
    80005546:	60e2                	ld	ra,24(sp)
    80005548:	6442                	ld	s0,16(sp)
    8000554a:	6105                	addi	sp,sp,32
    8000554c:	8082                	ret

000000008000554e <sys_link>:
{
    8000554e:	7169                	addi	sp,sp,-304
    80005550:	f606                	sd	ra,296(sp)
    80005552:	f222                	sd	s0,288(sp)
    80005554:	ee26                	sd	s1,280(sp)
    80005556:	ea4a                	sd	s2,272(sp)
    80005558:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000555a:	08000613          	li	a2,128
    8000555e:	ed040593          	addi	a1,s0,-304
    80005562:	4501                	li	a0,0
    80005564:	ffffd097          	auipc	ra,0xffffd
    80005568:	78a080e7          	jalr	1930(ra) # 80002cee <argstr>
    return -1;
    8000556c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000556e:	10054e63          	bltz	a0,8000568a <sys_link+0x13c>
    80005572:	08000613          	li	a2,128
    80005576:	f5040593          	addi	a1,s0,-176
    8000557a:	4505                	li	a0,1
    8000557c:	ffffd097          	auipc	ra,0xffffd
    80005580:	772080e7          	jalr	1906(ra) # 80002cee <argstr>
    return -1;
    80005584:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005586:	10054263          	bltz	a0,8000568a <sys_link+0x13c>
  begin_op();
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	cee080e7          	jalr	-786(ra) # 80004278 <begin_op>
  if((ip = namei(old)) == 0){
    80005592:	ed040513          	addi	a0,s0,-304
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	ac6080e7          	jalr	-1338(ra) # 8000405c <namei>
    8000559e:	84aa                	mv	s1,a0
    800055a0:	c551                	beqz	a0,8000562c <sys_link+0xde>
  ilock(ip);
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	314080e7          	jalr	788(ra) # 800038b6 <ilock>
  if(ip->type == T_DIR){
    800055aa:	04449703          	lh	a4,68(s1)
    800055ae:	4785                	li	a5,1
    800055b0:	08f70463          	beq	a4,a5,80005638 <sys_link+0xea>
  ip->nlink++;
    800055b4:	04a4d783          	lhu	a5,74(s1)
    800055b8:	2785                	addiw	a5,a5,1
    800055ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	22c080e7          	jalr	556(ra) # 800037ec <iupdate>
  iunlock(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	3ae080e7          	jalr	942(ra) # 80003978 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055d2:	fd040593          	addi	a1,s0,-48
    800055d6:	f5040513          	addi	a0,s0,-176
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	aa0080e7          	jalr	-1376(ra) # 8000407a <nameiparent>
    800055e2:	892a                	mv	s2,a0
    800055e4:	c935                	beqz	a0,80005658 <sys_link+0x10a>
  ilock(dp);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	2d0080e7          	jalr	720(ra) # 800038b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ee:	00092703          	lw	a4,0(s2)
    800055f2:	409c                	lw	a5,0(s1)
    800055f4:	04f71d63          	bne	a4,a5,8000564e <sys_link+0x100>
    800055f8:	40d0                	lw	a2,4(s1)
    800055fa:	fd040593          	addi	a1,s0,-48
    800055fe:	854a                	mv	a0,s2
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	9aa080e7          	jalr	-1622(ra) # 80003faa <dirlink>
    80005608:	04054363          	bltz	a0,8000564e <sys_link+0x100>
  iunlockput(dp);
    8000560c:	854a                	mv	a0,s2
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	50a080e7          	jalr	1290(ra) # 80003b18 <iunlockput>
  iput(ip);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	458080e7          	jalr	1112(ra) # 80003a70 <iput>
  end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	cd8080e7          	jalr	-808(ra) # 800042f8 <end_op>
  return 0;
    80005628:	4781                	li	a5,0
    8000562a:	a085                	j	8000568a <sys_link+0x13c>
    end_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	ccc080e7          	jalr	-820(ra) # 800042f8 <end_op>
    return -1;
    80005634:	57fd                	li	a5,-1
    80005636:	a891                	j	8000568a <sys_link+0x13c>
    iunlockput(ip);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	4de080e7          	jalr	1246(ra) # 80003b18 <iunlockput>
    end_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	cb6080e7          	jalr	-842(ra) # 800042f8 <end_op>
    return -1;
    8000564a:	57fd                	li	a5,-1
    8000564c:	a83d                	j	8000568a <sys_link+0x13c>
    iunlockput(dp);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	4c8080e7          	jalr	1224(ra) # 80003b18 <iunlockput>
  ilock(ip);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	25c080e7          	jalr	604(ra) # 800038b6 <ilock>
  ip->nlink--;
    80005662:	04a4d783          	lhu	a5,74(s1)
    80005666:	37fd                	addiw	a5,a5,-1
    80005668:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	17e080e7          	jalr	382(ra) # 800037ec <iupdate>
  iunlockput(ip);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	4a0080e7          	jalr	1184(ra) # 80003b18 <iunlockput>
  end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	c78080e7          	jalr	-904(ra) # 800042f8 <end_op>
  return -1;
    80005688:	57fd                	li	a5,-1
}
    8000568a:	853e                	mv	a0,a5
    8000568c:	70b2                	ld	ra,296(sp)
    8000568e:	7412                	ld	s0,288(sp)
    80005690:	64f2                	ld	s1,280(sp)
    80005692:	6952                	ld	s2,272(sp)
    80005694:	6155                	addi	sp,sp,304
    80005696:	8082                	ret

0000000080005698 <sys_unlink>:
{
    80005698:	7151                	addi	sp,sp,-240
    8000569a:	f586                	sd	ra,232(sp)
    8000569c:	f1a2                	sd	s0,224(sp)
    8000569e:	eda6                	sd	s1,216(sp)
    800056a0:	e9ca                	sd	s2,208(sp)
    800056a2:	e5ce                	sd	s3,200(sp)
    800056a4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056a6:	08000613          	li	a2,128
    800056aa:	f3040593          	addi	a1,s0,-208
    800056ae:	4501                	li	a0,0
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	63e080e7          	jalr	1598(ra) # 80002cee <argstr>
    800056b8:	18054163          	bltz	a0,8000583a <sys_unlink+0x1a2>
  begin_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	bbc080e7          	jalr	-1092(ra) # 80004278 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056c4:	fb040593          	addi	a1,s0,-80
    800056c8:	f3040513          	addi	a0,s0,-208
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	9ae080e7          	jalr	-1618(ra) # 8000407a <nameiparent>
    800056d4:	84aa                	mv	s1,a0
    800056d6:	c979                	beqz	a0,800057ac <sys_unlink+0x114>
  ilock(dp);
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	1de080e7          	jalr	478(ra) # 800038b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056e0:	00003597          	auipc	a1,0x3
    800056e4:	02058593          	addi	a1,a1,32 # 80008700 <syscalls+0x2b0>
    800056e8:	fb040513          	addi	a0,s0,-80
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	694080e7          	jalr	1684(ra) # 80003d80 <namecmp>
    800056f4:	14050a63          	beqz	a0,80005848 <sys_unlink+0x1b0>
    800056f8:	00003597          	auipc	a1,0x3
    800056fc:	01058593          	addi	a1,a1,16 # 80008708 <syscalls+0x2b8>
    80005700:	fb040513          	addi	a0,s0,-80
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	67c080e7          	jalr	1660(ra) # 80003d80 <namecmp>
    8000570c:	12050e63          	beqz	a0,80005848 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005710:	f2c40613          	addi	a2,s0,-212
    80005714:	fb040593          	addi	a1,s0,-80
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	680080e7          	jalr	1664(ra) # 80003d9a <dirlookup>
    80005722:	892a                	mv	s2,a0
    80005724:	12050263          	beqz	a0,80005848 <sys_unlink+0x1b0>
  ilock(ip);
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	18e080e7          	jalr	398(ra) # 800038b6 <ilock>
  if(ip->nlink < 1)
    80005730:	04a91783          	lh	a5,74(s2)
    80005734:	08f05263          	blez	a5,800057b8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005738:	04491703          	lh	a4,68(s2)
    8000573c:	4785                	li	a5,1
    8000573e:	08f70563          	beq	a4,a5,800057c8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005742:	4641                	li	a2,16
    80005744:	4581                	li	a1,0
    80005746:	fc040513          	addi	a0,s0,-64
    8000574a:	ffffb097          	auipc	ra,0xffffb
    8000574e:	59c080e7          	jalr	1436(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005752:	4741                	li	a4,16
    80005754:	f2c42683          	lw	a3,-212(s0)
    80005758:	fc040613          	addi	a2,s0,-64
    8000575c:	4581                	li	a1,0
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	502080e7          	jalr	1282(ra) # 80003c62 <writei>
    80005768:	47c1                	li	a5,16
    8000576a:	0af51563          	bne	a0,a5,80005814 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000576e:	04491703          	lh	a4,68(s2)
    80005772:	4785                	li	a5,1
    80005774:	0af70863          	beq	a4,a5,80005824 <sys_unlink+0x18c>
  iunlockput(dp);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	39e080e7          	jalr	926(ra) # 80003b18 <iunlockput>
  ip->nlink--;
    80005782:	04a95783          	lhu	a5,74(s2)
    80005786:	37fd                	addiw	a5,a5,-1
    80005788:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	05e080e7          	jalr	94(ra) # 800037ec <iupdate>
  iunlockput(ip);
    80005796:	854a                	mv	a0,s2
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	380080e7          	jalr	896(ra) # 80003b18 <iunlockput>
  end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	b58080e7          	jalr	-1192(ra) # 800042f8 <end_op>
  return 0;
    800057a8:	4501                	li	a0,0
    800057aa:	a84d                	j	8000585c <sys_unlink+0x1c4>
    end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	b4c080e7          	jalr	-1204(ra) # 800042f8 <end_op>
    return -1;
    800057b4:	557d                	li	a0,-1
    800057b6:	a05d                	j	8000585c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057b8:	00003517          	auipc	a0,0x3
    800057bc:	f5850513          	addi	a0,a0,-168 # 80008710 <syscalls+0x2c0>
    800057c0:	ffffb097          	auipc	ra,0xffffb
    800057c4:	d84080e7          	jalr	-636(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057c8:	04c92703          	lw	a4,76(s2)
    800057cc:	02000793          	li	a5,32
    800057d0:	f6e7f9e3          	bgeu	a5,a4,80005742 <sys_unlink+0xaa>
    800057d4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057d8:	4741                	li	a4,16
    800057da:	86ce                	mv	a3,s3
    800057dc:	f1840613          	addi	a2,s0,-232
    800057e0:	4581                	li	a1,0
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	386080e7          	jalr	902(ra) # 80003b6a <readi>
    800057ec:	47c1                	li	a5,16
    800057ee:	00f51b63          	bne	a0,a5,80005804 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057f2:	f1845783          	lhu	a5,-232(s0)
    800057f6:	e7a1                	bnez	a5,8000583e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057f8:	29c1                	addiw	s3,s3,16
    800057fa:	04c92783          	lw	a5,76(s2)
    800057fe:	fcf9ede3          	bltu	s3,a5,800057d8 <sys_unlink+0x140>
    80005802:	b781                	j	80005742 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005804:	00003517          	auipc	a0,0x3
    80005808:	f2450513          	addi	a0,a0,-220 # 80008728 <syscalls+0x2d8>
    8000580c:	ffffb097          	auipc	ra,0xffffb
    80005810:	d38080e7          	jalr	-712(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005814:	00003517          	auipc	a0,0x3
    80005818:	f2c50513          	addi	a0,a0,-212 # 80008740 <syscalls+0x2f0>
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	d28080e7          	jalr	-728(ra) # 80000544 <panic>
    dp->nlink--;
    80005824:	04a4d783          	lhu	a5,74(s1)
    80005828:	37fd                	addiw	a5,a5,-1
    8000582a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	fbc080e7          	jalr	-68(ra) # 800037ec <iupdate>
    80005838:	b781                	j	80005778 <sys_unlink+0xe0>
    return -1;
    8000583a:	557d                	li	a0,-1
    8000583c:	a005                	j	8000585c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	2d8080e7          	jalr	728(ra) # 80003b18 <iunlockput>
  iunlockput(dp);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	2ce080e7          	jalr	718(ra) # 80003b18 <iunlockput>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	aa6080e7          	jalr	-1370(ra) # 800042f8 <end_op>
  return -1;
    8000585a:	557d                	li	a0,-1
}
    8000585c:	70ae                	ld	ra,232(sp)
    8000585e:	740e                	ld	s0,224(sp)
    80005860:	64ee                	ld	s1,216(sp)
    80005862:	694e                	ld	s2,208(sp)
    80005864:	69ae                	ld	s3,200(sp)
    80005866:	616d                	addi	sp,sp,240
    80005868:	8082                	ret

000000008000586a <sys_open>:

uint64
sys_open(void)
{
    8000586a:	7131                	addi	sp,sp,-192
    8000586c:	fd06                	sd	ra,184(sp)
    8000586e:	f922                	sd	s0,176(sp)
    80005870:	f526                	sd	s1,168(sp)
    80005872:	f14a                	sd	s2,160(sp)
    80005874:	ed4e                	sd	s3,152(sp)
    80005876:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005878:	f4c40593          	addi	a1,s0,-180
    8000587c:	4505                	li	a0,1
    8000587e:	ffffd097          	auipc	ra,0xffffd
    80005882:	430080e7          	jalr	1072(ra) # 80002cae <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005886:	08000613          	li	a2,128
    8000588a:	f5040593          	addi	a1,s0,-176
    8000588e:	4501                	li	a0,0
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	45e080e7          	jalr	1118(ra) # 80002cee <argstr>
    80005898:	87aa                	mv	a5,a0
    return -1;
    8000589a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000589c:	0a07c963          	bltz	a5,8000594e <sys_open+0xe4>

  begin_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	9d8080e7          	jalr	-1576(ra) # 80004278 <begin_op>

  if(omode & O_CREATE){
    800058a8:	f4c42783          	lw	a5,-180(s0)
    800058ac:	2007f793          	andi	a5,a5,512
    800058b0:	cfc5                	beqz	a5,80005968 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058b2:	4681                	li	a3,0
    800058b4:	4601                	li	a2,0
    800058b6:	4589                	li	a1,2
    800058b8:	f5040513          	addi	a0,s0,-176
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	952080e7          	jalr	-1710(ra) # 8000520e <create>
    800058c4:	84aa                	mv	s1,a0
    if(ip == 0){
    800058c6:	c959                	beqz	a0,8000595c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058c8:	04449703          	lh	a4,68(s1)
    800058cc:	478d                	li	a5,3
    800058ce:	00f71763          	bne	a4,a5,800058dc <sys_open+0x72>
    800058d2:	0464d703          	lhu	a4,70(s1)
    800058d6:	47a5                	li	a5,9
    800058d8:	0ce7ed63          	bltu	a5,a4,800059b2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	dac080e7          	jalr	-596(ra) # 80004688 <filealloc>
    800058e4:	89aa                	mv	s3,a0
    800058e6:	10050363          	beqz	a0,800059ec <sys_open+0x182>
    800058ea:	00000097          	auipc	ra,0x0
    800058ee:	8e2080e7          	jalr	-1822(ra) # 800051cc <fdalloc>
    800058f2:	892a                	mv	s2,a0
    800058f4:	0e054763          	bltz	a0,800059e2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058f8:	04449703          	lh	a4,68(s1)
    800058fc:	478d                	li	a5,3
    800058fe:	0cf70563          	beq	a4,a5,800059c8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005902:	4789                	li	a5,2
    80005904:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005908:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000590c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005910:	f4c42783          	lw	a5,-180(s0)
    80005914:	0017c713          	xori	a4,a5,1
    80005918:	8b05                	andi	a4,a4,1
    8000591a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000591e:	0037f713          	andi	a4,a5,3
    80005922:	00e03733          	snez	a4,a4
    80005926:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000592a:	4007f793          	andi	a5,a5,1024
    8000592e:	c791                	beqz	a5,8000593a <sys_open+0xd0>
    80005930:	04449703          	lh	a4,68(s1)
    80005934:	4789                	li	a5,2
    80005936:	0af70063          	beq	a4,a5,800059d6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	03c080e7          	jalr	60(ra) # 80003978 <iunlock>
  end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	9b4080e7          	jalr	-1612(ra) # 800042f8 <end_op>

  return fd;
    8000594c:	854a                	mv	a0,s2
}
    8000594e:	70ea                	ld	ra,184(sp)
    80005950:	744a                	ld	s0,176(sp)
    80005952:	74aa                	ld	s1,168(sp)
    80005954:	790a                	ld	s2,160(sp)
    80005956:	69ea                	ld	s3,152(sp)
    80005958:	6129                	addi	sp,sp,192
    8000595a:	8082                	ret
      end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	99c080e7          	jalr	-1636(ra) # 800042f8 <end_op>
      return -1;
    80005964:	557d                	li	a0,-1
    80005966:	b7e5                	j	8000594e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005968:	f5040513          	addi	a0,s0,-176
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	6f0080e7          	jalr	1776(ra) # 8000405c <namei>
    80005974:	84aa                	mv	s1,a0
    80005976:	c905                	beqz	a0,800059a6 <sys_open+0x13c>
    ilock(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	f3e080e7          	jalr	-194(ra) # 800038b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005980:	04449703          	lh	a4,68(s1)
    80005984:	4785                	li	a5,1
    80005986:	f4f711e3          	bne	a4,a5,800058c8 <sys_open+0x5e>
    8000598a:	f4c42783          	lw	a5,-180(s0)
    8000598e:	d7b9                	beqz	a5,800058dc <sys_open+0x72>
      iunlockput(ip);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	186080e7          	jalr	390(ra) # 80003b18 <iunlockput>
      end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	95e080e7          	jalr	-1698(ra) # 800042f8 <end_op>
      return -1;
    800059a2:	557d                	li	a0,-1
    800059a4:	b76d                	j	8000594e <sys_open+0xe4>
      end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	952080e7          	jalr	-1710(ra) # 800042f8 <end_op>
      return -1;
    800059ae:	557d                	li	a0,-1
    800059b0:	bf79                	j	8000594e <sys_open+0xe4>
    iunlockput(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	164080e7          	jalr	356(ra) # 80003b18 <iunlockput>
    end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	93c080e7          	jalr	-1732(ra) # 800042f8 <end_op>
    return -1;
    800059c4:	557d                	li	a0,-1
    800059c6:	b761                	j	8000594e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059c8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059cc:	04649783          	lh	a5,70(s1)
    800059d0:	02f99223          	sh	a5,36(s3)
    800059d4:	bf25                	j	8000590c <sys_open+0xa2>
    itrunc(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	fec080e7          	jalr	-20(ra) # 800039c4 <itrunc>
    800059e0:	bfa9                	j	8000593a <sys_open+0xd0>
      fileclose(f);
    800059e2:	854e                	mv	a0,s3
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	d60080e7          	jalr	-672(ra) # 80004744 <fileclose>
    iunlockput(ip);
    800059ec:	8526                	mv	a0,s1
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	12a080e7          	jalr	298(ra) # 80003b18 <iunlockput>
    end_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	902080e7          	jalr	-1790(ra) # 800042f8 <end_op>
    return -1;
    800059fe:	557d                	li	a0,-1
    80005a00:	b7b9                	j	8000594e <sys_open+0xe4>

0000000080005a02 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a02:	7175                	addi	sp,sp,-144
    80005a04:	e506                	sd	ra,136(sp)
    80005a06:	e122                	sd	s0,128(sp)
    80005a08:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	86e080e7          	jalr	-1938(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a12:	08000613          	li	a2,128
    80005a16:	f7040593          	addi	a1,s0,-144
    80005a1a:	4501                	li	a0,0
    80005a1c:	ffffd097          	auipc	ra,0xffffd
    80005a20:	2d2080e7          	jalr	722(ra) # 80002cee <argstr>
    80005a24:	02054963          	bltz	a0,80005a56 <sys_mkdir+0x54>
    80005a28:	4681                	li	a3,0
    80005a2a:	4601                	li	a2,0
    80005a2c:	4585                	li	a1,1
    80005a2e:	f7040513          	addi	a0,s0,-144
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	7dc080e7          	jalr	2012(ra) # 8000520e <create>
    80005a3a:	cd11                	beqz	a0,80005a56 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	0dc080e7          	jalr	220(ra) # 80003b18 <iunlockput>
  end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	8b4080e7          	jalr	-1868(ra) # 800042f8 <end_op>
  return 0;
    80005a4c:	4501                	li	a0,0
}
    80005a4e:	60aa                	ld	ra,136(sp)
    80005a50:	640a                	ld	s0,128(sp)
    80005a52:	6149                	addi	sp,sp,144
    80005a54:	8082                	ret
    end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	8a2080e7          	jalr	-1886(ra) # 800042f8 <end_op>
    return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	b7fd                	j	80005a4e <sys_mkdir+0x4c>

0000000080005a62 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a62:	7135                	addi	sp,sp,-160
    80005a64:	ed06                	sd	ra,152(sp)
    80005a66:	e922                	sd	s0,144(sp)
    80005a68:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	80e080e7          	jalr	-2034(ra) # 80004278 <begin_op>
  argint(1, &major);
    80005a72:	f6c40593          	addi	a1,s0,-148
    80005a76:	4505                	li	a0,1
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	236080e7          	jalr	566(ra) # 80002cae <argint>
  argint(2, &minor);
    80005a80:	f6840593          	addi	a1,s0,-152
    80005a84:	4509                	li	a0,2
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	228080e7          	jalr	552(ra) # 80002cae <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a8e:	08000613          	li	a2,128
    80005a92:	f7040593          	addi	a1,s0,-144
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	256080e7          	jalr	598(ra) # 80002cee <argstr>
    80005aa0:	02054b63          	bltz	a0,80005ad6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aa4:	f6841683          	lh	a3,-152(s0)
    80005aa8:	f6c41603          	lh	a2,-148(s0)
    80005aac:	458d                	li	a1,3
    80005aae:	f7040513          	addi	a0,s0,-144
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	75c080e7          	jalr	1884(ra) # 8000520e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aba:	cd11                	beqz	a0,80005ad6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	05c080e7          	jalr	92(ra) # 80003b18 <iunlockput>
  end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	834080e7          	jalr	-1996(ra) # 800042f8 <end_op>
  return 0;
    80005acc:	4501                	li	a0,0
}
    80005ace:	60ea                	ld	ra,152(sp)
    80005ad0:	644a                	ld	s0,144(sp)
    80005ad2:	610d                	addi	sp,sp,160
    80005ad4:	8082                	ret
    end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	822080e7          	jalr	-2014(ra) # 800042f8 <end_op>
    return -1;
    80005ade:	557d                	li	a0,-1
    80005ae0:	b7fd                	j	80005ace <sys_mknod+0x6c>

0000000080005ae2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ae2:	7135                	addi	sp,sp,-160
    80005ae4:	ed06                	sd	ra,152(sp)
    80005ae6:	e922                	sd	s0,144(sp)
    80005ae8:	e526                	sd	s1,136(sp)
    80005aea:	e14a                	sd	s2,128(sp)
    80005aec:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aee:	ffffc097          	auipc	ra,0xffffc
    80005af2:	ed8080e7          	jalr	-296(ra) # 800019c6 <myproc>
    80005af6:	892a                	mv	s2,a0
  
  begin_op();
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	780080e7          	jalr	1920(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b00:	08000613          	li	a2,128
    80005b04:	f6040593          	addi	a1,s0,-160
    80005b08:	4501                	li	a0,0
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	1e4080e7          	jalr	484(ra) # 80002cee <argstr>
    80005b12:	04054b63          	bltz	a0,80005b68 <sys_chdir+0x86>
    80005b16:	f6040513          	addi	a0,s0,-160
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	542080e7          	jalr	1346(ra) # 8000405c <namei>
    80005b22:	84aa                	mv	s1,a0
    80005b24:	c131                	beqz	a0,80005b68 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	d90080e7          	jalr	-624(ra) # 800038b6 <ilock>
  if(ip->type != T_DIR){
    80005b2e:	04449703          	lh	a4,68(s1)
    80005b32:	4785                	li	a5,1
    80005b34:	04f71063          	bne	a4,a5,80005b74 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	e3e080e7          	jalr	-450(ra) # 80003978 <iunlock>
  iput(p->cwd);
    80005b42:	15093503          	ld	a0,336(s2)
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	f2a080e7          	jalr	-214(ra) # 80003a70 <iput>
  end_op();
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	7aa080e7          	jalr	1962(ra) # 800042f8 <end_op>
  p->cwd = ip;
    80005b56:	14993823          	sd	s1,336(s2)
  return 0;
    80005b5a:	4501                	li	a0,0
}
    80005b5c:	60ea                	ld	ra,152(sp)
    80005b5e:	644a                	ld	s0,144(sp)
    80005b60:	64aa                	ld	s1,136(sp)
    80005b62:	690a                	ld	s2,128(sp)
    80005b64:	610d                	addi	sp,sp,160
    80005b66:	8082                	ret
    end_op();
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	790080e7          	jalr	1936(ra) # 800042f8 <end_op>
    return -1;
    80005b70:	557d                	li	a0,-1
    80005b72:	b7ed                	j	80005b5c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	fa2080e7          	jalr	-94(ra) # 80003b18 <iunlockput>
    end_op();
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	77a080e7          	jalr	1914(ra) # 800042f8 <end_op>
    return -1;
    80005b86:	557d                	li	a0,-1
    80005b88:	bfd1                	j	80005b5c <sys_chdir+0x7a>

0000000080005b8a <sys_exec>:

uint64
sys_exec(void)
{
    80005b8a:	7145                	addi	sp,sp,-464
    80005b8c:	e786                	sd	ra,456(sp)
    80005b8e:	e3a2                	sd	s0,448(sp)
    80005b90:	ff26                	sd	s1,440(sp)
    80005b92:	fb4a                	sd	s2,432(sp)
    80005b94:	f74e                	sd	s3,424(sp)
    80005b96:	f352                	sd	s4,416(sp)
    80005b98:	ef56                	sd	s5,408(sp)
    80005b9a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b9c:	e3840593          	addi	a1,s0,-456
    80005ba0:	4505                	li	a0,1
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	12c080e7          	jalr	300(ra) # 80002cce <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005baa:	08000613          	li	a2,128
    80005bae:	f4040593          	addi	a1,s0,-192
    80005bb2:	4501                	li	a0,0
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	13a080e7          	jalr	314(ra) # 80002cee <argstr>
    80005bbc:	87aa                	mv	a5,a0
    return -1;
    80005bbe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005bc0:	0c07c263          	bltz	a5,80005c84 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bc4:	10000613          	li	a2,256
    80005bc8:	4581                	li	a1,0
    80005bca:	e4040513          	addi	a0,s0,-448
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	118080e7          	jalr	280(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bd6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bda:	89a6                	mv	s3,s1
    80005bdc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bde:	02000a13          	li	s4,32
    80005be2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005be6:	00391513          	slli	a0,s2,0x3
    80005bea:	e3040593          	addi	a1,s0,-464
    80005bee:	e3843783          	ld	a5,-456(s0)
    80005bf2:	953e                	add	a0,a0,a5
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	01c080e7          	jalr	28(ra) # 80002c10 <fetchaddr>
    80005bfc:	02054a63          	bltz	a0,80005c30 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c00:	e3043783          	ld	a5,-464(s0)
    80005c04:	c3b9                	beqz	a5,80005c4a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c06:	ffffb097          	auipc	ra,0xffffb
    80005c0a:	ef4080e7          	jalr	-268(ra) # 80000afa <kalloc>
    80005c0e:	85aa                	mv	a1,a0
    80005c10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c14:	cd11                	beqz	a0,80005c30 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c16:	6605                	lui	a2,0x1
    80005c18:	e3043503          	ld	a0,-464(s0)
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	046080e7          	jalr	70(ra) # 80002c62 <fetchstr>
    80005c24:	00054663          	bltz	a0,80005c30 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c28:	0905                	addi	s2,s2,1
    80005c2a:	09a1                	addi	s3,s3,8
    80005c2c:	fb491be3          	bne	s2,s4,80005be2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c30:	10048913          	addi	s2,s1,256
    80005c34:	6088                	ld	a0,0(s1)
    80005c36:	c531                	beqz	a0,80005c82 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c38:	ffffb097          	auipc	ra,0xffffb
    80005c3c:	dc6080e7          	jalr	-570(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c40:	04a1                	addi	s1,s1,8
    80005c42:	ff2499e3          	bne	s1,s2,80005c34 <sys_exec+0xaa>
  return -1;
    80005c46:	557d                	li	a0,-1
    80005c48:	a835                	j	80005c84 <sys_exec+0xfa>
      argv[i] = 0;
    80005c4a:	0a8e                	slli	s5,s5,0x3
    80005c4c:	fc040793          	addi	a5,s0,-64
    80005c50:	9abe                	add	s5,s5,a5
    80005c52:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c56:	e4040593          	addi	a1,s0,-448
    80005c5a:	f4040513          	addi	a0,s0,-192
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	16e080e7          	jalr	366(ra) # 80004dcc <exec>
    80005c66:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c68:	10048993          	addi	s3,s1,256
    80005c6c:	6088                	ld	a0,0(s1)
    80005c6e:	c901                	beqz	a0,80005c7e <sys_exec+0xf4>
    kfree(argv[i]);
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	d8e080e7          	jalr	-626(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c78:	04a1                	addi	s1,s1,8
    80005c7a:	ff3499e3          	bne	s1,s3,80005c6c <sys_exec+0xe2>
  return ret;
    80005c7e:	854a                	mv	a0,s2
    80005c80:	a011                	j	80005c84 <sys_exec+0xfa>
  return -1;
    80005c82:	557d                	li	a0,-1
}
    80005c84:	60be                	ld	ra,456(sp)
    80005c86:	641e                	ld	s0,448(sp)
    80005c88:	74fa                	ld	s1,440(sp)
    80005c8a:	795a                	ld	s2,432(sp)
    80005c8c:	79ba                	ld	s3,424(sp)
    80005c8e:	7a1a                	ld	s4,416(sp)
    80005c90:	6afa                	ld	s5,408(sp)
    80005c92:	6179                	addi	sp,sp,464
    80005c94:	8082                	ret

0000000080005c96 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c96:	7139                	addi	sp,sp,-64
    80005c98:	fc06                	sd	ra,56(sp)
    80005c9a:	f822                	sd	s0,48(sp)
    80005c9c:	f426                	sd	s1,40(sp)
    80005c9e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	d26080e7          	jalr	-730(ra) # 800019c6 <myproc>
    80005ca8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005caa:	fd840593          	addi	a1,s0,-40
    80005cae:	4501                	li	a0,0
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	01e080e7          	jalr	30(ra) # 80002cce <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005cb8:	fc840593          	addi	a1,s0,-56
    80005cbc:	fd040513          	addi	a0,s0,-48
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	db4080e7          	jalr	-588(ra) # 80004a74 <pipealloc>
    return -1;
    80005cc8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cca:	0c054463          	bltz	a0,80005d92 <sys_pipe+0xfc>
  fd0 = -1;
    80005cce:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cd2:	fd043503          	ld	a0,-48(s0)
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	4f6080e7          	jalr	1270(ra) # 800051cc <fdalloc>
    80005cde:	fca42223          	sw	a0,-60(s0)
    80005ce2:	08054b63          	bltz	a0,80005d78 <sys_pipe+0xe2>
    80005ce6:	fc843503          	ld	a0,-56(s0)
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	4e2080e7          	jalr	1250(ra) # 800051cc <fdalloc>
    80005cf2:	fca42023          	sw	a0,-64(s0)
    80005cf6:	06054863          	bltz	a0,80005d66 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cfa:	4691                	li	a3,4
    80005cfc:	fc440613          	addi	a2,s0,-60
    80005d00:	fd843583          	ld	a1,-40(s0)
    80005d04:	68a8                	ld	a0,80(s1)
    80005d06:	ffffc097          	auipc	ra,0xffffc
    80005d0a:	97e080e7          	jalr	-1666(ra) # 80001684 <copyout>
    80005d0e:	02054063          	bltz	a0,80005d2e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d12:	4691                	li	a3,4
    80005d14:	fc040613          	addi	a2,s0,-64
    80005d18:	fd843583          	ld	a1,-40(s0)
    80005d1c:	0591                	addi	a1,a1,4
    80005d1e:	68a8                	ld	a0,80(s1)
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	964080e7          	jalr	-1692(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d28:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d2a:	06055463          	bgez	a0,80005d92 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d2e:	fc442783          	lw	a5,-60(s0)
    80005d32:	07e9                	addi	a5,a5,26
    80005d34:	078e                	slli	a5,a5,0x3
    80005d36:	97a6                	add	a5,a5,s1
    80005d38:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d3c:	fc042503          	lw	a0,-64(s0)
    80005d40:	0569                	addi	a0,a0,26
    80005d42:	050e                	slli	a0,a0,0x3
    80005d44:	94aa                	add	s1,s1,a0
    80005d46:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d4a:	fd043503          	ld	a0,-48(s0)
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	9f6080e7          	jalr	-1546(ra) # 80004744 <fileclose>
    fileclose(wf);
    80005d56:	fc843503          	ld	a0,-56(s0)
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	9ea080e7          	jalr	-1558(ra) # 80004744 <fileclose>
    return -1;
    80005d62:	57fd                	li	a5,-1
    80005d64:	a03d                	j	80005d92 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d66:	fc442783          	lw	a5,-60(s0)
    80005d6a:	0007c763          	bltz	a5,80005d78 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d6e:	07e9                	addi	a5,a5,26
    80005d70:	078e                	slli	a5,a5,0x3
    80005d72:	94be                	add	s1,s1,a5
    80005d74:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d78:	fd043503          	ld	a0,-48(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	9c8080e7          	jalr	-1592(ra) # 80004744 <fileclose>
    fileclose(wf);
    80005d84:	fc843503          	ld	a0,-56(s0)
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	9bc080e7          	jalr	-1604(ra) # 80004744 <fileclose>
    return -1;
    80005d90:	57fd                	li	a5,-1
}
    80005d92:	853e                	mv	a0,a5
    80005d94:	70e2                	ld	ra,56(sp)
    80005d96:	7442                	ld	s0,48(sp)
    80005d98:	74a2                	ld	s1,40(sp)
    80005d9a:	6121                	addi	sp,sp,64
    80005d9c:	8082                	ret
	...

0000000080005da0 <kernelvec>:
    80005da0:	7111                	addi	sp,sp,-256
    80005da2:	e006                	sd	ra,0(sp)
    80005da4:	e40a                	sd	sp,8(sp)
    80005da6:	e80e                	sd	gp,16(sp)
    80005da8:	ec12                	sd	tp,24(sp)
    80005daa:	f016                	sd	t0,32(sp)
    80005dac:	f41a                	sd	t1,40(sp)
    80005dae:	f81e                	sd	t2,48(sp)
    80005db0:	fc22                	sd	s0,56(sp)
    80005db2:	e0a6                	sd	s1,64(sp)
    80005db4:	e4aa                	sd	a0,72(sp)
    80005db6:	e8ae                	sd	a1,80(sp)
    80005db8:	ecb2                	sd	a2,88(sp)
    80005dba:	f0b6                	sd	a3,96(sp)
    80005dbc:	f4ba                	sd	a4,104(sp)
    80005dbe:	f8be                	sd	a5,112(sp)
    80005dc0:	fcc2                	sd	a6,120(sp)
    80005dc2:	e146                	sd	a7,128(sp)
    80005dc4:	e54a                	sd	s2,136(sp)
    80005dc6:	e94e                	sd	s3,144(sp)
    80005dc8:	ed52                	sd	s4,152(sp)
    80005dca:	f156                	sd	s5,160(sp)
    80005dcc:	f55a                	sd	s6,168(sp)
    80005dce:	f95e                	sd	s7,176(sp)
    80005dd0:	fd62                	sd	s8,184(sp)
    80005dd2:	e1e6                	sd	s9,192(sp)
    80005dd4:	e5ea                	sd	s10,200(sp)
    80005dd6:	e9ee                	sd	s11,208(sp)
    80005dd8:	edf2                	sd	t3,216(sp)
    80005dda:	f1f6                	sd	t4,224(sp)
    80005ddc:	f5fa                	sd	t5,232(sp)
    80005dde:	f9fe                	sd	t6,240(sp)
    80005de0:	cfdfc0ef          	jal	ra,80002adc <kerneltrap>
    80005de4:	6082                	ld	ra,0(sp)
    80005de6:	6122                	ld	sp,8(sp)
    80005de8:	61c2                	ld	gp,16(sp)
    80005dea:	7282                	ld	t0,32(sp)
    80005dec:	7322                	ld	t1,40(sp)
    80005dee:	73c2                	ld	t2,48(sp)
    80005df0:	7462                	ld	s0,56(sp)
    80005df2:	6486                	ld	s1,64(sp)
    80005df4:	6526                	ld	a0,72(sp)
    80005df6:	65c6                	ld	a1,80(sp)
    80005df8:	6666                	ld	a2,88(sp)
    80005dfa:	7686                	ld	a3,96(sp)
    80005dfc:	7726                	ld	a4,104(sp)
    80005dfe:	77c6                	ld	a5,112(sp)
    80005e00:	7866                	ld	a6,120(sp)
    80005e02:	688a                	ld	a7,128(sp)
    80005e04:	692a                	ld	s2,136(sp)
    80005e06:	69ca                	ld	s3,144(sp)
    80005e08:	6a6a                	ld	s4,152(sp)
    80005e0a:	7a8a                	ld	s5,160(sp)
    80005e0c:	7b2a                	ld	s6,168(sp)
    80005e0e:	7bca                	ld	s7,176(sp)
    80005e10:	7c6a                	ld	s8,184(sp)
    80005e12:	6c8e                	ld	s9,192(sp)
    80005e14:	6d2e                	ld	s10,200(sp)
    80005e16:	6dce                	ld	s11,208(sp)
    80005e18:	6e6e                	ld	t3,216(sp)
    80005e1a:	7e8e                	ld	t4,224(sp)
    80005e1c:	7f2e                	ld	t5,232(sp)
    80005e1e:	7fce                	ld	t6,240(sp)
    80005e20:	6111                	addi	sp,sp,256
    80005e22:	10200073          	sret
    80005e26:	00000013          	nop
    80005e2a:	00000013          	nop
    80005e2e:	0001                	nop

0000000080005e30 <timervec>:
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	e10c                	sd	a1,0(a0)
    80005e36:	e510                	sd	a2,8(a0)
    80005e38:	e914                	sd	a3,16(a0)
    80005e3a:	6d0c                	ld	a1,24(a0)
    80005e3c:	7110                	ld	a2,32(a0)
    80005e3e:	6194                	ld	a3,0(a1)
    80005e40:	96b2                	add	a3,a3,a2
    80005e42:	e194                	sd	a3,0(a1)
    80005e44:	4589                	li	a1,2
    80005e46:	14459073          	csrw	sip,a1
    80005e4a:	6914                	ld	a3,16(a0)
    80005e4c:	6510                	ld	a2,8(a0)
    80005e4e:	610c                	ld	a1,0(a0)
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	30200073          	mret
	...

0000000080005e5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e5a:	1141                	addi	sp,sp,-16
    80005e5c:	e422                	sd	s0,8(sp)
    80005e5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e60:	0c0007b7          	lui	a5,0xc000
    80005e64:	4705                	li	a4,1
    80005e66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e68:	c3d8                	sw	a4,4(a5)
}
    80005e6a:	6422                	ld	s0,8(sp)
    80005e6c:	0141                	addi	sp,sp,16
    80005e6e:	8082                	ret

0000000080005e70 <plicinithart>:

void
plicinithart(void)
{
    80005e70:	1141                	addi	sp,sp,-16
    80005e72:	e406                	sd	ra,8(sp)
    80005e74:	e022                	sd	s0,0(sp)
    80005e76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	b22080e7          	jalr	-1246(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e80:	0085171b          	slliw	a4,a0,0x8
    80005e84:	0c0027b7          	lui	a5,0xc002
    80005e88:	97ba                	add	a5,a5,a4
    80005e8a:	40200713          	li	a4,1026
    80005e8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e92:	00d5151b          	slliw	a0,a0,0xd
    80005e96:	0c2017b7          	lui	a5,0xc201
    80005e9a:	953e                	add	a0,a0,a5
    80005e9c:	00052023          	sw	zero,0(a0)
}
    80005ea0:	60a2                	ld	ra,8(sp)
    80005ea2:	6402                	ld	s0,0(sp)
    80005ea4:	0141                	addi	sp,sp,16
    80005ea6:	8082                	ret

0000000080005ea8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ea8:	1141                	addi	sp,sp,-16
    80005eaa:	e406                	sd	ra,8(sp)
    80005eac:	e022                	sd	s0,0(sp)
    80005eae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005eb0:	ffffc097          	auipc	ra,0xffffc
    80005eb4:	aea080e7          	jalr	-1302(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005eb8:	00d5179b          	slliw	a5,a0,0xd
    80005ebc:	0c201537          	lui	a0,0xc201
    80005ec0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ec2:	4148                	lw	a0,4(a0)
    80005ec4:	60a2                	ld	ra,8(sp)
    80005ec6:	6402                	ld	s0,0(sp)
    80005ec8:	0141                	addi	sp,sp,16
    80005eca:	8082                	ret

0000000080005ecc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ecc:	1101                	addi	sp,sp,-32
    80005ece:	ec06                	sd	ra,24(sp)
    80005ed0:	e822                	sd	s0,16(sp)
    80005ed2:	e426                	sd	s1,8(sp)
    80005ed4:	1000                	addi	s0,sp,32
    80005ed6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	ac2080e7          	jalr	-1342(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ee0:	00d5151b          	slliw	a0,a0,0xd
    80005ee4:	0c2017b7          	lui	a5,0xc201
    80005ee8:	97aa                	add	a5,a5,a0
    80005eea:	c3c4                	sw	s1,4(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret

0000000080005ef6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ef6:	1141                	addi	sp,sp,-16
    80005ef8:	e406                	sd	ra,8(sp)
    80005efa:	e022                	sd	s0,0(sp)
    80005efc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005efe:	479d                	li	a5,7
    80005f00:	04a7cc63          	blt	a5,a0,80005f58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f04:	0001c797          	auipc	a5,0x1c
    80005f08:	12c78793          	addi	a5,a5,300 # 80022030 <disk>
    80005f0c:	97aa                	add	a5,a5,a0
    80005f0e:	0187c783          	lbu	a5,24(a5)
    80005f12:	ebb9                	bnez	a5,80005f68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f14:	00451613          	slli	a2,a0,0x4
    80005f18:	0001c797          	auipc	a5,0x1c
    80005f1c:	11878793          	addi	a5,a5,280 # 80022030 <disk>
    80005f20:	6394                	ld	a3,0(a5)
    80005f22:	96b2                	add	a3,a3,a2
    80005f24:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f28:	6398                	ld	a4,0(a5)
    80005f2a:	9732                	add	a4,a4,a2
    80005f2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f38:	953e                	add	a0,a0,a5
    80005f3a:	4785                	li	a5,1
    80005f3c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f40:	0001c517          	auipc	a0,0x1c
    80005f44:	10850513          	addi	a0,a0,264 # 80022048 <disk+0x18>
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	19a080e7          	jalr	410(ra) # 800020e2 <wakeup>
}
    80005f50:	60a2                	ld	ra,8(sp)
    80005f52:	6402                	ld	s0,0(sp)
    80005f54:	0141                	addi	sp,sp,16
    80005f56:	8082                	ret
    panic("free_desc 1");
    80005f58:	00002517          	auipc	a0,0x2
    80005f5c:	7f850513          	addi	a0,a0,2040 # 80008750 <syscalls+0x300>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5e4080e7          	jalr	1508(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005f68:	00002517          	auipc	a0,0x2
    80005f6c:	7f850513          	addi	a0,a0,2040 # 80008760 <syscalls+0x310>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5d4080e7          	jalr	1492(ra) # 80000544 <panic>

0000000080005f78 <virtio_disk_init>:
{
    80005f78:	1101                	addi	sp,sp,-32
    80005f7a:	ec06                	sd	ra,24(sp)
    80005f7c:	e822                	sd	s0,16(sp)
    80005f7e:	e426                	sd	s1,8(sp)
    80005f80:	e04a                	sd	s2,0(sp)
    80005f82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f84:	00002597          	auipc	a1,0x2
    80005f88:	7ec58593          	addi	a1,a1,2028 # 80008770 <syscalls+0x320>
    80005f8c:	0001c517          	auipc	a0,0x1c
    80005f90:	1cc50513          	addi	a0,a0,460 # 80022158 <disk+0x128>
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	bc6080e7          	jalr	-1082(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f9c:	100017b7          	lui	a5,0x10001
    80005fa0:	4398                	lw	a4,0(a5)
    80005fa2:	2701                	sext.w	a4,a4
    80005fa4:	747277b7          	lui	a5,0x74727
    80005fa8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fac:	14f71e63          	bne	a4,a5,80006108 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fb0:	100017b7          	lui	a5,0x10001
    80005fb4:	43dc                	lw	a5,4(a5)
    80005fb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb8:	4709                	li	a4,2
    80005fba:	14e79763          	bne	a5,a4,80006108 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	479c                	lw	a5,8(a5)
    80005fc4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fc6:	14e79163          	bne	a5,a4,80006108 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fca:	100017b7          	lui	a5,0x10001
    80005fce:	47d8                	lw	a4,12(a5)
    80005fd0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fd2:	554d47b7          	lui	a5,0x554d4
    80005fd6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fda:	12f71763          	bne	a4,a5,80006108 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fde:	100017b7          	lui	a5,0x10001
    80005fe2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe6:	4705                	li	a4,1
    80005fe8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fea:	470d                	li	a4,3
    80005fec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff0:	c7ffe737          	lui	a4,0xc7ffe
    80005ff4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc5ef>
    80005ff8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ffa:	2701                	sext.w	a4,a4
    80005ffc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffe:	472d                	li	a4,11
    80006000:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006002:	0707a903          	lw	s2,112(a5)
    80006006:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006008:	00897793          	andi	a5,s2,8
    8000600c:	10078663          	beqz	a5,80006118 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	100017b7          	lui	a5,0x10001
    80006014:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006018:	43fc                	lw	a5,68(a5)
    8000601a:	2781                	sext.w	a5,a5
    8000601c:	10079663          	bnez	a5,80006128 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006020:	100017b7          	lui	a5,0x10001
    80006024:	5bdc                	lw	a5,52(a5)
    80006026:	2781                	sext.w	a5,a5
  if(max == 0)
    80006028:	10078863          	beqz	a5,80006138 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000602c:	471d                	li	a4,7
    8000602e:	10f77d63          	bgeu	a4,a5,80006148 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	ac8080e7          	jalr	-1336(ra) # 80000afa <kalloc>
    8000603a:	0001c497          	auipc	s1,0x1c
    8000603e:	ff648493          	addi	s1,s1,-10 # 80022030 <disk>
    80006042:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006044:	ffffb097          	auipc	ra,0xffffb
    80006048:	ab6080e7          	jalr	-1354(ra) # 80000afa <kalloc>
    8000604c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	aac080e7          	jalr	-1364(ra) # 80000afa <kalloc>
    80006056:	87aa                	mv	a5,a0
    80006058:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000605a:	6088                	ld	a0,0(s1)
    8000605c:	cd75                	beqz	a0,80006158 <virtio_disk_init+0x1e0>
    8000605e:	0001c717          	auipc	a4,0x1c
    80006062:	fda73703          	ld	a4,-38(a4) # 80022038 <disk+0x8>
    80006066:	cb6d                	beqz	a4,80006158 <virtio_disk_init+0x1e0>
    80006068:	cbe5                	beqz	a5,80006158 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000606a:	6605                	lui	a2,0x1
    8000606c:	4581                	li	a1,0
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	c78080e7          	jalr	-904(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006076:	0001c497          	auipc	s1,0x1c
    8000607a:	fba48493          	addi	s1,s1,-70 # 80022030 <disk>
    8000607e:	6605                	lui	a2,0x1
    80006080:	4581                	li	a1,0
    80006082:	6488                	ld	a0,8(s1)
    80006084:	ffffb097          	auipc	ra,0xffffb
    80006088:	c62080e7          	jalr	-926(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000608c:	6605                	lui	a2,0x1
    8000608e:	4581                	li	a1,0
    80006090:	6888                	ld	a0,16(s1)
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	c54080e7          	jalr	-940(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	4721                	li	a4,8
    800060a0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060a2:	4098                	lw	a4,0(s1)
    800060a4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060a8:	40d8                	lw	a4,4(s1)
    800060aa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060ae:	6498                	ld	a4,8(s1)
    800060b0:	0007069b          	sext.w	a3,a4
    800060b4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060b8:	9701                	srai	a4,a4,0x20
    800060ba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060be:	6898                	ld	a4,16(s1)
    800060c0:	0007069b          	sext.w	a3,a4
    800060c4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060c8:	9701                	srai	a4,a4,0x20
    800060ca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060ce:	4685                	li	a3,1
    800060d0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800060d2:	4705                	li	a4,1
    800060d4:	00d48c23          	sb	a3,24(s1)
    800060d8:	00e48ca3          	sb	a4,25(s1)
    800060dc:	00e48d23          	sb	a4,26(s1)
    800060e0:	00e48da3          	sb	a4,27(s1)
    800060e4:	00e48e23          	sb	a4,28(s1)
    800060e8:	00e48ea3          	sb	a4,29(s1)
    800060ec:	00e48f23          	sb	a4,30(s1)
    800060f0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060f4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f8:	0727a823          	sw	s2,112(a5)
}
    800060fc:	60e2                	ld	ra,24(sp)
    800060fe:	6442                	ld	s0,16(sp)
    80006100:	64a2                	ld	s1,8(sp)
    80006102:	6902                	ld	s2,0(sp)
    80006104:	6105                	addi	sp,sp,32
    80006106:	8082                	ret
    panic("could not find virtio disk");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	67850513          	addi	a0,a0,1656 # 80008780 <syscalls+0x330>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	434080e7          	jalr	1076(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006118:	00002517          	auipc	a0,0x2
    8000611c:	68850513          	addi	a0,a0,1672 # 800087a0 <syscalls+0x350>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	424080e7          	jalr	1060(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006128:	00002517          	auipc	a0,0x2
    8000612c:	69850513          	addi	a0,a0,1688 # 800087c0 <syscalls+0x370>
    80006130:	ffffa097          	auipc	ra,0xffffa
    80006134:	414080e7          	jalr	1044(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006138:	00002517          	auipc	a0,0x2
    8000613c:	6a850513          	addi	a0,a0,1704 # 800087e0 <syscalls+0x390>
    80006140:	ffffa097          	auipc	ra,0xffffa
    80006144:	404080e7          	jalr	1028(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006148:	00002517          	auipc	a0,0x2
    8000614c:	6b850513          	addi	a0,a0,1720 # 80008800 <syscalls+0x3b0>
    80006150:	ffffa097          	auipc	ra,0xffffa
    80006154:	3f4080e7          	jalr	1012(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006158:	00002517          	auipc	a0,0x2
    8000615c:	6c850513          	addi	a0,a0,1736 # 80008820 <syscalls+0x3d0>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	3e4080e7          	jalr	996(ra) # 80000544 <panic>

0000000080006168 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006168:	7159                	addi	sp,sp,-112
    8000616a:	f486                	sd	ra,104(sp)
    8000616c:	f0a2                	sd	s0,96(sp)
    8000616e:	eca6                	sd	s1,88(sp)
    80006170:	e8ca                	sd	s2,80(sp)
    80006172:	e4ce                	sd	s3,72(sp)
    80006174:	e0d2                	sd	s4,64(sp)
    80006176:	fc56                	sd	s5,56(sp)
    80006178:	f85a                	sd	s6,48(sp)
    8000617a:	f45e                	sd	s7,40(sp)
    8000617c:	f062                	sd	s8,32(sp)
    8000617e:	ec66                	sd	s9,24(sp)
    80006180:	e86a                	sd	s10,16(sp)
    80006182:	1880                	addi	s0,sp,112
    80006184:	892a                	mv	s2,a0
    80006186:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006188:	00c52c83          	lw	s9,12(a0)
    8000618c:	001c9c9b          	slliw	s9,s9,0x1
    80006190:	1c82                	slli	s9,s9,0x20
    80006192:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006196:	0001c517          	auipc	a0,0x1c
    8000619a:	fc250513          	addi	a0,a0,-62 # 80022158 <disk+0x128>
    8000619e:	ffffb097          	auipc	ra,0xffffb
    800061a2:	a4c080e7          	jalr	-1460(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800061a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800061aa:	0001cb17          	auipc	s6,0x1c
    800061ae:	e86b0b13          	addi	s6,s6,-378 # 80022030 <disk>
  for(int i = 0; i < 3; i++){
    800061b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061b6:	0001cc17          	auipc	s8,0x1c
    800061ba:	fa2c0c13          	addi	s8,s8,-94 # 80022158 <disk+0x128>
    800061be:	a8b5                	j	8000623a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800061c0:	00fb06b3          	add	a3,s6,a5
    800061c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061ca:	0207c563          	bltz	a5,800061f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ce:	2485                	addiw	s1,s1,1
    800061d0:	0711                	addi	a4,a4,4
    800061d2:	1f548a63          	beq	s1,s5,800063c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800061d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061d8:	0001c697          	auipc	a3,0x1c
    800061dc:	e5868693          	addi	a3,a3,-424 # 80022030 <disk>
    800061e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061e2:	0186c583          	lbu	a1,24(a3)
    800061e6:	fde9                	bnez	a1,800061c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061e8:	2785                	addiw	a5,a5,1
    800061ea:	0685                	addi	a3,a3,1
    800061ec:	ff779be3          	bne	a5,s7,800061e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061f0:	57fd                	li	a5,-1
    800061f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061f4:	02905a63          	blez	s1,80006228 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061f8:	f9042503          	lw	a0,-112(s0)
    800061fc:	00000097          	auipc	ra,0x0
    80006200:	cfa080e7          	jalr	-774(ra) # 80005ef6 <free_desc>
      for(int j = 0; j < i; j++)
    80006204:	4785                	li	a5,1
    80006206:	0297d163          	bge	a5,s1,80006228 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000620a:	f9442503          	lw	a0,-108(s0)
    8000620e:	00000097          	auipc	ra,0x0
    80006212:	ce8080e7          	jalr	-792(ra) # 80005ef6 <free_desc>
      for(int j = 0; j < i; j++)
    80006216:	4789                	li	a5,2
    80006218:	0097d863          	bge	a5,s1,80006228 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000621c:	f9842503          	lw	a0,-104(s0)
    80006220:	00000097          	auipc	ra,0x0
    80006224:	cd6080e7          	jalr	-810(ra) # 80005ef6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006228:	85e2                	mv	a1,s8
    8000622a:	0001c517          	auipc	a0,0x1c
    8000622e:	e1e50513          	addi	a0,a0,-482 # 80022048 <disk+0x18>
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	e4c080e7          	jalr	-436(ra) # 8000207e <sleep>
  for(int i = 0; i < 3; i++){
    8000623a:	f9040713          	addi	a4,s0,-112
    8000623e:	84ce                	mv	s1,s3
    80006240:	bf59                	j	800061d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006242:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006246:	00479693          	slli	a3,a5,0x4
    8000624a:	0001c797          	auipc	a5,0x1c
    8000624e:	de678793          	addi	a5,a5,-538 # 80022030 <disk>
    80006252:	97b6                	add	a5,a5,a3
    80006254:	4685                	li	a3,1
    80006256:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006258:	0001c597          	auipc	a1,0x1c
    8000625c:	dd858593          	addi	a1,a1,-552 # 80022030 <disk>
    80006260:	00a60793          	addi	a5,a2,10
    80006264:	0792                	slli	a5,a5,0x4
    80006266:	97ae                	add	a5,a5,a1
    80006268:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000626c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006270:	f6070693          	addi	a3,a4,-160
    80006274:	619c                	ld	a5,0(a1)
    80006276:	97b6                	add	a5,a5,a3
    80006278:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000627a:	6188                	ld	a0,0(a1)
    8000627c:	96aa                	add	a3,a3,a0
    8000627e:	47c1                	li	a5,16
    80006280:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006282:	4785                	li	a5,1
    80006284:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006288:	f9442783          	lw	a5,-108(s0)
    8000628c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006290:	0792                	slli	a5,a5,0x4
    80006292:	953e                	add	a0,a0,a5
    80006294:	05890693          	addi	a3,s2,88
    80006298:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000629a:	6188                	ld	a0,0(a1)
    8000629c:	97aa                	add	a5,a5,a0
    8000629e:	40000693          	li	a3,1024
    800062a2:	c794                	sw	a3,8(a5)
  if(write)
    800062a4:	100d0d63          	beqz	s10,800063be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ac:	00c7d683          	lhu	a3,12(a5)
    800062b0:	0016e693          	ori	a3,a3,1
    800062b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800062b8:	f9842583          	lw	a1,-104(s0)
    800062bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062c0:	0001c697          	auipc	a3,0x1c
    800062c4:	d7068693          	addi	a3,a3,-656 # 80022030 <disk>
    800062c8:	00260793          	addi	a5,a2,2
    800062cc:	0792                	slli	a5,a5,0x4
    800062ce:	97b6                	add	a5,a5,a3
    800062d0:	587d                	li	a6,-1
    800062d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d6:	0592                	slli	a1,a1,0x4
    800062d8:	952e                	add	a0,a0,a1
    800062da:	f9070713          	addi	a4,a4,-112
    800062de:	9736                	add	a4,a4,a3
    800062e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800062e2:	6298                	ld	a4,0(a3)
    800062e4:	972e                	add	a4,a4,a1
    800062e6:	4585                	li	a1,1
    800062e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062ea:	4509                	li	a0,2
    800062ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800062f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800062f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062fc:	6698                	ld	a4,8(a3)
    800062fe:	00275783          	lhu	a5,2(a4)
    80006302:	8b9d                	andi	a5,a5,7
    80006304:	0786                	slli	a5,a5,0x1
    80006306:	97ba                	add	a5,a5,a4
    80006308:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000630c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006310:	6698                	ld	a4,8(a3)
    80006312:	00275783          	lhu	a5,2(a4)
    80006316:	2785                	addiw	a5,a5,1
    80006318:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000631c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006320:	100017b7          	lui	a5,0x10001
    80006324:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006328:	00492703          	lw	a4,4(s2)
    8000632c:	4785                	li	a5,1
    8000632e:	02f71163          	bne	a4,a5,80006350 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006332:	0001c997          	auipc	s3,0x1c
    80006336:	e2698993          	addi	s3,s3,-474 # 80022158 <disk+0x128>
  while(b->disk == 1) {
    8000633a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000633c:	85ce                	mv	a1,s3
    8000633e:	854a                	mv	a0,s2
    80006340:	ffffc097          	auipc	ra,0xffffc
    80006344:	d3e080e7          	jalr	-706(ra) # 8000207e <sleep>
  while(b->disk == 1) {
    80006348:	00492783          	lw	a5,4(s2)
    8000634c:	fe9788e3          	beq	a5,s1,8000633c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006350:	f9042903          	lw	s2,-112(s0)
    80006354:	00290793          	addi	a5,s2,2
    80006358:	00479713          	slli	a4,a5,0x4
    8000635c:	0001c797          	auipc	a5,0x1c
    80006360:	cd478793          	addi	a5,a5,-812 # 80022030 <disk>
    80006364:	97ba                	add	a5,a5,a4
    80006366:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000636a:	0001c997          	auipc	s3,0x1c
    8000636e:	cc698993          	addi	s3,s3,-826 # 80022030 <disk>
    80006372:	00491713          	slli	a4,s2,0x4
    80006376:	0009b783          	ld	a5,0(s3)
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006380:	854a                	mv	a0,s2
    80006382:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006386:	00000097          	auipc	ra,0x0
    8000638a:	b70080e7          	jalr	-1168(ra) # 80005ef6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000638e:	8885                	andi	s1,s1,1
    80006390:	f0ed                	bnez	s1,80006372 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006392:	0001c517          	auipc	a0,0x1c
    80006396:	dc650513          	addi	a0,a0,-570 # 80022158 <disk+0x128>
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	904080e7          	jalr	-1788(ra) # 80000c9e <release>
}
    800063a2:	70a6                	ld	ra,104(sp)
    800063a4:	7406                	ld	s0,96(sp)
    800063a6:	64e6                	ld	s1,88(sp)
    800063a8:	6946                	ld	s2,80(sp)
    800063aa:	69a6                	ld	s3,72(sp)
    800063ac:	6a06                	ld	s4,64(sp)
    800063ae:	7ae2                	ld	s5,56(sp)
    800063b0:	7b42                	ld	s6,48(sp)
    800063b2:	7ba2                	ld	s7,40(sp)
    800063b4:	7c02                	ld	s8,32(sp)
    800063b6:	6ce2                	ld	s9,24(sp)
    800063b8:	6d42                	ld	s10,16(sp)
    800063ba:	6165                	addi	sp,sp,112
    800063bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063be:	4689                	li	a3,2
    800063c0:	00d79623          	sh	a3,12(a5)
    800063c4:	b5e5                	j	800062ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c6:	f9042603          	lw	a2,-112(s0)
    800063ca:	00a60713          	addi	a4,a2,10
    800063ce:	0712                	slli	a4,a4,0x4
    800063d0:	0001c517          	auipc	a0,0x1c
    800063d4:	c6850513          	addi	a0,a0,-920 # 80022038 <disk+0x8>
    800063d8:	953a                	add	a0,a0,a4
  if(write)
    800063da:	e60d14e3          	bnez	s10,80006242 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063de:	00a60793          	addi	a5,a2,10
    800063e2:	00479693          	slli	a3,a5,0x4
    800063e6:	0001c797          	auipc	a5,0x1c
    800063ea:	c4a78793          	addi	a5,a5,-950 # 80022030 <disk>
    800063ee:	97b6                	add	a5,a5,a3
    800063f0:	0007a423          	sw	zero,8(a5)
    800063f4:	b595                	j	80006258 <virtio_disk_rw+0xf0>

00000000800063f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063f6:	1101                	addi	sp,sp,-32
    800063f8:	ec06                	sd	ra,24(sp)
    800063fa:	e822                	sd	s0,16(sp)
    800063fc:	e426                	sd	s1,8(sp)
    800063fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006400:	0001c497          	auipc	s1,0x1c
    80006404:	c3048493          	addi	s1,s1,-976 # 80022030 <disk>
    80006408:	0001c517          	auipc	a0,0x1c
    8000640c:	d5050513          	addi	a0,a0,-688 # 80022158 <disk+0x128>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	7da080e7          	jalr	2010(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006418:	10001737          	lui	a4,0x10001
    8000641c:	533c                	lw	a5,96(a4)
    8000641e:	8b8d                	andi	a5,a5,3
    80006420:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006422:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006426:	689c                	ld	a5,16(s1)
    80006428:	0204d703          	lhu	a4,32(s1)
    8000642c:	0027d783          	lhu	a5,2(a5)
    80006430:	04f70863          	beq	a4,a5,80006480 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006434:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006438:	6898                	ld	a4,16(s1)
    8000643a:	0204d783          	lhu	a5,32(s1)
    8000643e:	8b9d                	andi	a5,a5,7
    80006440:	078e                	slli	a5,a5,0x3
    80006442:	97ba                	add	a5,a5,a4
    80006444:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006446:	00278713          	addi	a4,a5,2
    8000644a:	0712                	slli	a4,a4,0x4
    8000644c:	9726                	add	a4,a4,s1
    8000644e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006452:	e721                	bnez	a4,8000649a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006454:	0789                	addi	a5,a5,2
    80006456:	0792                	slli	a5,a5,0x4
    80006458:	97a6                	add	a5,a5,s1
    8000645a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000645c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006460:	ffffc097          	auipc	ra,0xffffc
    80006464:	c82080e7          	jalr	-894(ra) # 800020e2 <wakeup>

    disk.used_idx += 1;
    80006468:	0204d783          	lhu	a5,32(s1)
    8000646c:	2785                	addiw	a5,a5,1
    8000646e:	17c2                	slli	a5,a5,0x30
    80006470:	93c1                	srli	a5,a5,0x30
    80006472:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006476:	6898                	ld	a4,16(s1)
    80006478:	00275703          	lhu	a4,2(a4)
    8000647c:	faf71ce3          	bne	a4,a5,80006434 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006480:	0001c517          	auipc	a0,0x1c
    80006484:	cd850513          	addi	a0,a0,-808 # 80022158 <disk+0x128>
    80006488:	ffffb097          	auipc	ra,0xffffb
    8000648c:	816080e7          	jalr	-2026(ra) # 80000c9e <release>
}
    80006490:	60e2                	ld	ra,24(sp)
    80006492:	6442                	ld	s0,16(sp)
    80006494:	64a2                	ld	s1,8(sp)
    80006496:	6105                	addi	sp,sp,32
    80006498:	8082                	ret
      panic("virtio_disk_intr status");
    8000649a:	00002517          	auipc	a0,0x2
    8000649e:	39e50513          	addi	a0,a0,926 # 80008838 <syscalls+0x3e8>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	0a2080e7          	jalr	162(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
