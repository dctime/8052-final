ORG 0000H
JMP START
ORG 000BH
JMP ONEMS
ORG 0050H

START:
INITCURSOR:
  // cursor column #00000001B
  MOV 030H, #00000001B
  // cursor row
  MOV 031H, #00000001B
  // cursor timer
  MOV 034H, #235
  MOV 035H, #3
TIMER0SET:
  // MOD 1 
  // TMOD.1 0
  // TMOD.0 0
  ANL TMOD, #11111100B
  // TMOD.2 0 Use Timer
  ANL TMOD, #11111011B
  // TR0 1
  SETB TR0
  // TMOD.3 Gate 0
  ANL TMOD, #11110111B
  // 1ms
  MOV TH0, #253
  MOV TL0, #20
INTERRUPTSETUP:
  // Enable All
  SETB 0AFH
  // TF0 Enable
  SETB 0A9H
  // TF0 Low Priority
  CLR 0B9H
INITPATTERNMEMORY:
  MOV 02BH, #00110110B
  MOV 02CH, #01111111B
  MOV 02DH, #00111110B
  MOV 02EH, #00011100B
  MOV 02FH, #00001000B
MOVEPATTERNTODISPLAYMEMORY:
  // look from the right side of the led matrix
  MOV 020H, 02BH
  MOV 021H, 02CH
  MOV 022H, 02DH
  MOV 023H, 02EH
  MOV 024H, 02FH

LOOP:
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
  // end of a scan session
  POP 0E0H
  JMP KEYBOARD
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
	JMP ENDOFLOOP // 重新從第一行偵測
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
  MOV A, 032H // last time keyboard index
  CJNE A, #0, KEYBOARDNOT0 // left up
  // 0
  JMP AFTERKEYBOARD
KEYBOARDNOT0:
  CJNE A, #1, KEYBOARDNOT1 // up
  // 1
  CALL CHECKANDMOVECURSORUP
  JMP AFTERKEYBOARD
KEYBOARDNOT1:
  CJNE A, #2, KEYBOARDNOT2
  // 2
  JMP AFTERKEYBOARD
KEYBOARDNOT2:
  CJNE A, #3, KEYBOARDNOT3
  // 3
  JMP AFTERKEYBOARD
KEYBOARDNOT3:
  CJNE A, #4, KEYBOARDNOT4 // left
  // 4
  CALL CHECKANDMOVECURSORLEFT
  JMP AFTERKEYBOARD
KEYBOARDNOT4:
  CJNE A, #5, KEYBOARDNOT5 // enter
  // 5
  JMP AFTERKEYBOARD
KEYBOARDNOT5:
  CJNE A, #6, KEYBOARDNOT6 // right
  // 6
  CALL CHECKANDMOVECURSORRIGHT
  JMP AFTERKEYBOARD
KEYBOARDNOT6:
  CJNE A, #7, KEYBOARDNOT7
  // 7
  JMP AFTERKEYBOARD
KEYBOARDNOT7:
  CJNE A, #8, KEYBOARDNOT8
  // 8
  JMP AFTERKEYBOARD
KEYBOARDNOT8:
  CJNE A, #9, KEYBOARDNOT9 // down
  // 9
  CALL CHECKANDMOVECURSORDOWN
  JMP AFTERKEYBOARD
KEYBOARDNOT9:
  CJNE A, #10, KEYBOARDNOT10
  // 10
  JMP AFTERKEYBOARD
KEYBOARDNOT10:
  CJNE A, #11, KEYBOARDNOT11
  // 11
  JMP AFTERKEYBOARD
KEYBOARDNOT11:
  CJNE A, #12, KEYBOARDNOT12
  // 12
  JMP AFTERKEYBOARD
KEYBOARDNOT12:
  CJNE A, #13, KEYBOARDNOT13
  // 13
  JMP AFTERKEYBOARD
KEYBOARDNOT13:
  CJNE A, #14, KEYBOARDNOT14
  // 14
  JMP AFTERKEYBOARD
KEYBOARDNOT14:
  CJNE A, #15, KEYBOARDNOT15
  // 15
  JMP AFTERKEYBOARD
KEYBOARDNOT15:
  // it should not happen
AFTERKEYBOARD:
  JMP ENDOFLOOP

KEYBOARDDELAY:
  MOV 033H, #30H
KEYBOARDDELAY1:
  DJNZ 033H, KEYBOARDDELAY1
  RET

ENDOFLOOP:
  JMP LOOP

ONEMS:
CURSORBLINK:
  DJNZ 034H, CURSORBLINKRETI
  MOV 034H, #235
  DJNZ 035H, CURSORBLINK
  // blink!
  // target column
  MOV R0, #01FH
  MOV A, 030H
  RL A
CURSORBLINKPOINTERLOCATING:
  INC R0
  RR A
  CJNE A, #00000001B, CURSORBLINKPOINTERLOCATING
  // pointer ready
  // set the target bit to zero
  MOV A, @R0
  MOV 036H, A // processing data
  MOV A, 31H
  CPL A
  ANL A, 036H
  MOV @R0, A

  // invert get the bit and paste the bit  
  MOV A, 036H
  CPL A
  ANL A, 031H
  ORL A, @R0
  MOV @R0, A
  
  MOV 035H, #3
  JMP CURSORBLINKRETI
CURSORBLINKRETI:
  // Reset Timer
  // 1ms
  MOV TH0, #253
  MOV TL0, #20
  RETI

// ----- cursor call -----
CHECKANDMOVECURSORLEFT:
  MOV A, 030H
  CJNE A, #00000001B, CURSORMOVELEFT
  RET
CURSORMOVELEFT:
  RR A
  MOV 030H, A
  RET
CHECKANDMOVECURSORRIGHT:
  MOV A, 030H
  CJNE A, #00010000B, CURSORMOVERIGHT
  RET
CURSORMOVERIGHT:
  RL A
  MOV 030H, A
  RET
CHECKANDMOVECURSORUP:
  MOV A, 031H
  CJNE A, #00000001B, CURSORMOVEUP
  RET
CURSORMOVEUP:
  RR A
  MOV 031H, A
  RET
CHECKANDMOVECURSORDOWN:
  MOV A, 031H
  CJNE A, #01000000B, CURSORMOVEDOWN
  RET
CURSORMOVEDOWN:
  RL A
  MOV 031H, A
  RET
END
