ORG 0000H
AJMP START
ORG 0050H

START:
PLACEPATTERNMEMORY:
  MOV 02BH, #00110110B
  MOV 02CH, #01111111B
  MOV 02DH, #00111110B
  MOV 02EH, #00011100B
  MOV 02FH, #00001000B
KEYBOARD:
ROW1:
	MOV P2, #07FH // 01111111
	CALL KEYBOARDDELAY
	MOV A, P2
	ANL A, #0FH // 00001111 遮罩
	MOV 032H, #0 // TABLE[0][...]
	CJNE A, #0FH, COL1 // there is someone pressing this column
ROW2:
	MOV P2, #0BFH // 10111111
	CALL KEYBOARDDELAY
	MOV A, P2
	ANL A, #0FH
	MOV 032H, #4 // TABLE[1][...]
	CJNE A, #0FH, COL1
ROW3:
	MOV P2, #0DFH // 11011111
	CALL KEYBOARDDELAY
	MOV A, P2
	ANL A, #0FH
	MOV 032H, #8 // TABLE[2][...]
	CJNE A, #0FH, COL1
ROW4:
	MOV P2, #0EFH // 打進去看看有沒有
	CALL KEYBOARDDELAY
	MOV A, P2
	ANL A, #0FH
	MOV 032H, #12 // TABLE[3][...]
	CJNE A, #0FH, COL1
NOTHINGPRESSED:
	JMP KEYBOARD // 重新從第一行偵測
// 當偵測到時
COL1:
	CJNE A, #0EH, COL2 // 00001110
  MOV A, 032H
	ADD A, #0 
  MOV 032H, A
	JMP KEYBOARDEVENT
COL2:
	CJNE A, #0DH, COL3 // 00001101
  MOV A, 032H
	ADD A, #1 
  MOV 032H, A
	JMP KEYBOARDEVENT
COL3:
	CJNE A, #0BH, COL4 // 00001011
  MOV A, 032H
	ADD A, #2 
  MOV 032H, A
	JMP KEYBOARDEVENT
COL4:
	CJNE A, #07H, KEYBOARD // 00000111
  MOV A, 032H
	ADD A, #3 
  MOV 032H, A
  JMP KEYBOARDEVENT
KEYBOARDEVENT:
  // TODO: What to do when keyboard pressed
  JMP KEYBOARD

KEYBOARDDELAY:
  MOV 034H, #30H
KEYBOARDDELAY1:
  DJNZ 034H, KEYBOARDDELAY1
  RET


// TODO: Use Interrupt With Timer
PLACELEDDISPLAYMEMORY:
  // look from the right side of the led matrix
  MOV 020H, 02BH
  MOV 021H, 02CH
  MOV 022H, 02DH
  MOV 023H, 02EH
  MOV 024H, 02FH
SCANLED:
INITSCAN:
  // init the led so that it will light up
  MOV P0, #00000000B // column MSB right 
  MOV P1, #00000000B // row MSB down
  MOV 027H, #020H // column data pointer
	MOV 025H, #00000001B // column light up
  MOV 026H, #00000001B // row light up
CHECKCOLUMNLIGHTUP:
  PUSH 0E0H // 0E0H: A
  MOV A, 025H
  CJNE A, #00100000B, PASSCHECKCOLUMNLIGHTUP

  MOV 025H, #00000001B
  MOV 027H, #020H
  POP 0E0H
  JMP CHECKROWLIGHTUP
PASSCHECKCOLUMNLIGHTUP:
  POP 0E0H
CHECKROWLIGHTUP:
  PUSH 0E0H
  MOV A, 026H
  CJNE A, #10000000B, PASSCHECKROWLIGHTUP
  // check row failed
  MOV 026H, #00000001B
  INC 027H // data pointer + 1

  MOV A, 025H
  RL A
  MOV 025H, A
  POP 0E0H

  JMP CHECKCOLUMNLIGHTUP
PASSCHECKROWLIGHTUP:
  POP 0E0H
LITUP:
  PUSH 00H
  PUSH 0E0H

  MOV R0, 027H // pointer
  MOV A, @R0
  ANL A, 026H // row light up
  
  MOV P0, 025H // column
  MOV P1, A

  POP 0E0H
  POP 00H
AFTERLIT:
  PUSH 0E0H

  MOV A, 026H
  RL A // row + 1
  MOV 026H, A

  POP 0E0H
  CALL LEDDELAY
  MOV P0, #00000000B
  MOV P1, #00000000B
	JMP CHECKROWLIGHTUP

LEDDELAY:
	MOV 028H, #030H
LEDDELAY1:
	DJNZ 028H, LEDDELAY1
	RET
END
