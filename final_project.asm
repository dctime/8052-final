ORG 0000H
JMP START
ORG 000BH
JMP ONEMS
ORG 001BH
JMP BUZZERFLIP
ORG 0050H

START:
MODESETUP:
  CLR 52H // Set mode to Edit Mode
DISPLAYMEMORYSETUP:
  // look from the right side of the led matrix
  // the MSB bit is not in the scope
  MOV 020H, #00010000B
  MOV 021H, #01010000B
  MOV 022H, #00110000B
  MOV 023H, #00000000B
  MOV 024H, #00000000B
TIMER0SET:
  // MOD 1 
  // TMOD.1 0
  // TMOD.0 1
  ANL TMOD, #11111101B
  ORL TMOD, #00000001B
  // TMOD.2 0 Use Timer
  ANL TMOD, #11111011B
  // TR0 1
  SETB TR0
  // TMOD.3 Gate 0
  ANL TMOD, #11110111B
  // 1ms
  MOV TH0, #252
  MOV TL0, #23
  
TIMER1SET:
  // Mode 1
  // TMOD.5 = 0
  // TMOD.4 = 1
  ANL TMOD, #11011111B
  ORL TMOD, #00010000B
  // TMOD.6 0 Timer Mode
  ANL TMOD, #10111111B
  // TMOD.7 0 Gate
  ANL TMOD, #01111111B
  CLR TF1
  // Low C
  // Buzzer Frequency init value
  MOV 040H, #241
  MOV 041H, #242
  MOV TH1, 040H
  MOV TL1, 041H
  // Disable Timer
  CLR TR1

INTERRUPTSETUP:
  // TF0 Enable
  SETB 0A9H
  // TF0 Low Priority
  CLR 0B9H
  // TF1 Enable
  SETB 0ABH
  // TF1 High Priority
  SETB 0BBH
  // Enable All
  SETB 0AFH

MODEEDIT:
LCDSHOWMODEDIT:
  MOV A, #00111011B
  CALL USEATOCOMMANDLCD
  MOV A, #00001110B // DCB
  CALL USEATOCOMMANDLCD
  MOV A, #00000110B // AC setting and screen
  CALL USEATOCOMMANDLCD
  MOV A, #00000001B
  CALL USEATOCOMMANDLCD
  MOV A, #10000000B // set ddram memory pointer to 0
  CALL USEATOCOMMANDLCD

  CALL CLEARLCD
  MOV DPTR, #LCDINITTEXT
  CALL WRITEDPTRTOLCD
  JMP INITCURSOR

INITCURSOR:
  // cursor column #00000001B
  MOV 030H, #00000001B
  // cursor row
  MOV 031H, #00000001B
  // cursor timer
  MOV 034H, #236
  MOV 035H, #4
  SETB 051H // blink enable
INITKEYBOARD:
  CLR 050H // keyboard trigger locker
LOOPEDIT:
  CALL SCANLED

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
  CLR 050H
	JMP ENDOFLOOPEDIT // 重新從第一行偵測
// 當偵測到時
COL1:
	CJNE A, #0EH, COL2 // 00001110
  MOV R0, #0
	JMP KEYBOARDEVENT
COL2:
	CJNE A, #0DH, COL3 // 00001101
  MOV R0, #1
	JMP KEYBOARDEVENT
COL3:
	CJNE A, #0BH, COL4 // 00001011
  MOV R0, #2
	JMP KEYBOARDEVENT
COL4:
	CJNE A, #07H, KEYBOARD // 00000111
  MOV R0, #3
  JMP KEYBOARDEVENT
KEYBOARDEVENT:
  MOV A, 032H
	ADD A, R0 
  MOV 032H, A

  JNB 050H, KEYBOARDUNLOCKED
  // locked
  JMP AFTERKEYBOARD
KEYBOARDUNLOCKED:
  SETB 050H // keyboard locked
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
  // test - set C High
  SETB TR1
  MOV A, #7
  CALL TURNAINTOFREQUENCY
  JMP AFTERKEYBOARD
KEYBOARDNOT3:
  CJNE A, #4, KEYBOARDNOT4 // left
  // 4
  CALL CHECKANDMOVECURSORLEFT
  JMP AFTERKEYBOARD
KEYBOARDNOT4:
  CJNE A, #5, KEYBOARDNOT5 // enter
  // 5
  CPL 051H
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
  CJNE A, #15, KEYBOARDNOT15 // run the sim
  // 15
  JMP MODEGAMEOFLIFE
KEYBOARDNOT15:
  // it should not happen
AFTERKEYBOARD:
  JMP ENDOFLOOPEDIT

KEYBOARDDELAY:
  MOV 033H, #30H
KEYBOARDDELAY1:
  DJNZ 033H, KEYBOARDDELAY1
  RET

ENDOFLOOPEDIT:
  JMP LOOPEDIT


MODEGAMEOFLIFE:
INITGAMEOFLIFE:
  MOV 047H, #0 // round counter
  SETB 052H // set mode to GAMEOFLIFE
  MOV 03DH, #67
  MOV 03EH, #96

  PUSH 082H // DPL
  PUSH 083H // DPH

  CALL CLEARLCD
  MOV DPTR, #LCDGAMEOFLIFETEXTROW0  
  CALL WRITEDPTRTOLCD

  MOV A, #11000000B // second row
  CALL USEATOCOMMANDLCD
  MOV DPTR, #LCDGAMEOFLIFETEXTROW1  
  CALL WRITEDPTRTOLCD
  
  POP 083H // DPH
  POP 082H // DPL

  MOV DPTR, #BUZZERSEQUENCETABLE0 
LOOPGAMEOFLIFE:
  CALL SCANLED
  JMP ENDOFLOOPGAMEOFLIFE
ENDOFLOOPGAMEOFLIFE:
  JMP LOOPGAMEOFLIFE

// --- main calls ---
SCANLED:
INITSCAN:
  // init the led so that it will light up
  ANL 080H, #11100000B // column MSB right 
  ANL 090H, #10000000B // row MSB down // P1
  MOV 027H, #020H // column data pointer
	MOV 025H, #00000001B // column light up
  MOV 026H, #00000001B // row light up
CHECKCOLUMNLIGHTUP:
  PUSH 0E0H // 0E0H: A
  MOV A, 025H
  CJNE A, #00100000B, PASSCHECKCOLUMNLIGHTUP
  // end of a scan session
  POP 0E0H
  RET
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

  // MOV P1, A Filter P1.7
  ANL A, #01111111B
  MOV B, A
  MOV A, P1
  ANL A, #10000000B
  ORL A, 0F0H // B
LITUPCLEAN:
  CLR 090H
  CLR 091H
  CLR 092H
  CLR 093H
  CLR 094H
  CLR 095H
  CLR 096H

LITUPCHECK0:
  CJNE A, #00000001B, LITUPCHECK1
  SETB 090H
  JMP ENDLITUPFILLIN
LITUPCHECK1:
  CJNE A, #00000010B, LITUPCHECK2
  SETB 091H
  JMP ENDLITUPFILLIN
LITUPCHECK2:
  CJNE A, #00000100B, LITUPCHECK3
  SETB 092H
  JMP ENDLITUPFILLIN
LITUPCHECK3:
  CJNE A, #00001000B, LITUPCHECK4
  SETB 093H
  JMP ENDLITUPFILLIN
LITUPCHECK4:
  CJNE A, #00010000B, LITUPCHECK5
  SETB 094H
  JMP ENDLITUPFILLIN
LITUPCHECK5:
  CJNE A, #00100000B, LITUPCHECK6
  SETB 095H
  JMP ENDLITUPFILLIN
LITUPCHECK6:
  CJNE A, #01000000B, ENDLITUPFILLIN
  SETB 096H
  JMP ENDLITUPFILLIN

ENDLITUPFILLIN:
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
  ANL 090H, #10000000B // P1
	JMP CHECKROWLIGHTUP

LEDDELAY:
	MOV 028H, #030H
LEDDELAY1:
	DJNZ 028H, LEDDELAY1
	RET

BUZZERFLIP:
  CPL 097H
  MOV TH1, 040H
  MOV TL1, 041H
  RETI

BUZZERTABLE:
  DB 241, 22
  DB 241, 242
  DB 242, 182
  DB 243, 122
  DB 244, 41
  DB 244, 214
  DB 245, 112
  DB 246, 8
  DB 246, 155
  DB 247, 30
  DB 247, 157
  DB 248, 23
  // -----
  DB 248, 139
  DB 248, 242
  DB 249, 90
  DB 249, 183
  DB 250, 20
  DB 250, 102
  DB 250, 184
  DB 251, 3
  DB 251, 74
  DB 251, 143
  DB 251, 206
  DB 252, 11
  // -----
  DB 252, 67
  DB 252, 120
  DB 252, 171
  DB 252, 219
  DB 253, 8
  DB 253, 51
  DB 253, 91
  DB 253, 129
  DB 253, 165
  DB 253, 199
  DB 253, 231
  DB 254, 5
  // -----

BUZZERSEQUENCETABLE0:
  DB 27, 27, 27, 36, 36, 36, 27, 27, 27, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36
  DB 27, 27, 27, 36, 36, 36, 27, 27, 27, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36
  DB 36, 36, 36, 36, 36, 36, 27, 36, 27, 36, 27, 36

BUZZERSEQUENCETABLE1:
  DB 30, 30, 30, 30, 30, 30, 29, 29, 29, 29, 29, 29
  DB 27, 27, 27, 27, 27, 27, 25, 25, 25, 25, 25, 25
  DB 27, 27, 27, 27, 27, 27, 29, 29, 29, 29, 29, 29
  DB 30, 30, 30, 30, 30, 30, 32, 32, 32, 32, 32, 32
  DB 30, 30, 30, 30, 30, 30, 29, 29, 29, 29, 29, 29
  DB 27, 27, 27, 27, 27, 27, 25, 25, 25, 25, 25, 25
  DB 27, 27, 27, 27, 27, 27, 29, 29, 29, 29, 29, 29
  DB 30, 30, 30, 30, 30, 30, 32, 32, 32, 32, 32, 32

BUZZERSEQUENCETABLE2:
  DB 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
  DB 15, 15, 15, 15, 15, 15, 13, 13, 13, 13, 13, 13
  DB 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17
  DB 15, 15, 15, 15, 15, 15, 13, 13, 13, 13, 13, 13
  DB 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
  DB 15, 15, 15, 15, 15, 15, 13, 13, 13, 13, 13, 13
  DB 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17
  DB 15, 15, 15, 15, 15, 15, 13, 13, 13, 13, 13, 13

BUZZERSEQUENCETABLE3:
  DB 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
  DB 20, 20, 20, 20, 20, 20, 22, 22, 22, 22, 22, 22
  DB 23, 23, 23, 23, 23, 23, 22, 22, 22, 22, 22, 22
  DB 20, 20, 20, 20, 20, 20, 15, 15, 15, 15, 15, 15
  DB 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18
  DB 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18
  DB 20, 20, 20, 20, 20, 20, 17, 17, 17, 17, 17, 17
  DB 15, 15, 15, 15, 15, 15, 13, 13, 13, 13, 13, 13

BUZZERSEQUENCETABLE4:
  DB 15, 15, 10, 10, 15, 15, 18, 18, 10, 10, 18, 18
  DB 27, 27, 29, 29, 30, 30, 29, 29, 27, 27, 22, 22
  DB 15, 15, 10, 10, 15, 15, 18, 18, 10, 10, 18, 18
  DB 27, 27, 29, 29, 30, 30, 29, 29, 27, 27, 22, 22
  DB 15, 15, 10, 10, 15, 15, 18, 18, 10, 10, 18, 18
  DB 27, 27, 29, 29, 30, 30, 29, 29, 27, 27, 22, 22
  DB 15, 15, 10, 10, 15, 15, 18, 18, 10, 10, 18, 18
  DB 27, 27, 29, 29, 30, 30, 29, 29, 27, 27, 22, 22

BUZZERSEQUENCETABLE5:
  DB 11, 11, 8, 8, 15, 15, 8, 8, 11, 11, 8, 8
  DB 11, 11, 8, 8, 15, 15, 8, 8, 11, 11, 8, 8
  DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
  DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
  DB 22, 22, 18, 18, 22, 22, 18, 18, 15, 15, 18, 18
  DB 15, 15, 10, 10, 15, 15, 10, 10, 6, 6, 10, 10
  DB 6, 6, 3, 3, 6, 6, 10, 10, 6, 6, 10, 10
  DB 15, 15, 10, 10, 15, 15, 18, 18, 20, 20, 22, 22

; BUZZERSEQUENCETABLE6:
;   DB 11, 11, 3, 3, 10, 10, 3, 3, 8, 8, 3, 3
;   DB 11, 11, 3, 3, 10, 10, 3, 3, 8, 8, 3, 3
;   DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
;   DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
;   DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
;   DB 18, 18, 8, 8, 17, 17, 8, 8, 15, 15, 8, 8
;   DB 18, 18, 22, 22, 18, 18, 15, 15, 18, 18, 15, 15
;   DB 10, 10, 15, 15, 10, 10, 6, 6, 10, 10, 6, 6

; BUZZERSEQUENCETABLE7:
;   DB 22, 22, 18, 18, 22, 22, 18, 18, 15, 15, 18, 18
;   DB 15, 15, 10, 10, 15, 15, 10, 10, 6, 6, 10, 10
;   DB 6, 6, 3, 3, 6, 6, 10, 10, 6, 6, 10, 10
;   DB 15, 15, 10, 10, 15, 15, 18, 18, 15, 15, 18, 18
;   DB 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
;   DB 36, 36, 36, 36, 36, 36, 15, 15, 13, 13, 15, 15
;   DB 15, 15, 15, 15, 15, 15, 36, 36, 36, 36, 36, 36
;   DB 11, 11, 11, 11, 13, 13, 11, 11, 8, 8, 6, 6

// --- buzzer callables --
TURNAINTOFREQUENCY:
  PUSH 0E0H // A
  PUSH 0F0H // B
  PUSH 082H // DPL
  PUSH 083H // DPH
  CJNE A, #36, NOTNOSOUND
  CLR TR1
  CLR 097H // weird
  JMP RETTURNAINTOFREQUENCY
NOTNOSOUND:
  SETB TR1
  MOV B, #2
  MUL AB
  MOV B, A
  MOV DPTR, #BUZZERTABLE
  MOVC A, @A+DPTR
  MOV 040H, A
  MOV A, B
  INC A
  MOVC A, @A+DPTR
  MOV 041H, A
  JMP RETTURNAINTOFREQUENCY
RETTURNAINTOFREQUENCY:
  POP 083H // DPH
  POP 082H // DPL
  POP 0F0H // B
  POP 0E0H // A
  RET

ONEMS:
// this will modify display memory
ONEMSCHECKMODE:
// edit mode or game of life mode
JB 052H, ONECYCLE
JMP CURSORBLINK
CURSORBLINK:
  PUSH 000H // R0
  PUSH 0E0H // A

  JNB 051H,  CURSORBLINKRETI

  DJNZ 034H, CURSORBLINKRETI
  MOV 034H, #236
  DJNZ 035H, CURSORBLINKRETI
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
  
  // success -> update timer
  MOV 035H, #4
  JMP CURSORBLINKRETI
CURSORBLINKRETI:
  POP 0E0H // A
  POP 000H // R0

  JMP ENDONEMS
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

// NOTE: Check Mode and if GAMEOFLIFEMODE RUN ONECYCLE
ONECYCLE:
  PUSH 0E0H // A
  PUSH 000H // R0
  PUSH 0F0H // B
  
  DJNZ 03DH, ENDCYCLENOUPDATETEMP
  MOV 03DH, #67

  MOV A, 03EH // 96 init
  CJNE A, #0, UPDATEFREQUENCY
  JMP NOUPDATEFREQUENCY
UPDATEFREQUENCY:
  MOV A, #96
  CLR C
  SUBB A, 03EH
  MOVC A, @A+DPTR
  CALL TURNAINTOFREQUENCY
NOUPDATEFREQUENCY:
  DJNZ 03EH, ENDCYCLENOUPDATETEMP
  JMP INITCYCLE
ENDCYCLENOUPDATETEMP:
  JMP ENDCYCLENOUPDATE
INITCYCLE:
  MOV 043H, #0 // alive counter
  MOV 037H, #10000000B // column
  MOV 038H, #10000000B // row
CYCLENEXTCOLUMN:
  MOV A, 037H
  RL A
  CJNE A, #00100000B, CYCLEROWCHECKED
  JMP ENDCYCLE
CYCLEROWCHECKED:
  MOV 037H, A
CYCLENEXTROW:
  MOV A, 038H
  RL A
  CJNE A, #10000000B, CYCLECOLUMNROWCHECKED
  MOV 038H, #10000000B
  JMP CYCLENEXTCOLUMN
CYCLECOLUMNROWCHECKED:
  MOV 038H, A
CYCLECOLUMNROWREADY:
CYCLEGETNEIGHBORALIVES:
CYCLEINITNEIGHBORBIT:
  MOV 039H, #0 // alive counter
  MOV 03CH, #0 // neighbor ID 0 - 7
CYCLECHECKVALIDATENEIGHBORID:
  MOV A, 03CH
  CJNE A, #8, CYCLEADJUSTNEIGHBORBIT
CYCLECHECKNEIGHBORIDINVALID:
// neighbor count is ready
CYCLESTORENEWITERATION:
  // NOTE: 039H: neighbor alives 037H, 038H: column and row loc
  // NOTE: OLD: 20H - 24H
  // NOTE: NEW: 2BH - 2FH
CYCLEIDENTIFYBITALIVEORDEAD:
CYCLEINITIDENTIFYBITALIVEORDEAD:
  MOV R0, #20H
  MOV A, 037H
CYCLEIDENTIFYBITALIVEORDEADCHECKCOLUMN:
  CJNE A, #00000001, CYCLEIDENTIFYBITALIVEORDEADCHECKCOLUMNWRONG
CYCLEIDENTIFYBITALIVEORDEADCHECKCOLUMNRIGHT:
  JMP CYCLEIDENTIFYBITALIVEORDEADGETROW
CYCLEIDENTIFYBITALIVEORDEADCHECKCOLUMNWRONG:
  RR A
  INC R0
  JMP CYCLEIDENTIFYBITALIVEORDEADCHECKCOLUMN
CYCLEIDENTIFYBITALIVEORDEADGETROW:
  // find if alive or dead not neighbor
  MOV A, @R0
  ANL A, 038H
  CJNE A, #00000000B, CYCLEIDENTIFYBITALIVEORDEADALIVE
  JMP CYCLEIDENTIFYBITALIVEORDEADDEAD

CYCLEIDENTIFYBITALIVEORDEADALIVE: 
  MOV A, 039H
  CJNE A, #2, CYCLEIDENTIFYBITALIVEORDEADALIVENOT2
  JMP CYCLENEXTITERATIONALIVE
CYCLEIDENTIFYBITALIVEORDEADALIVENOT2: 
  CJNE A, #3, CYCLEIDENTIFYBITALIVEORDEADALIVEOTHER
  JMP CYCLENEXTITERATIONALIVE
CYCLEIDENTIFYBITALIVEORDEADALIVEOTHER: 
  JMP CYCLENEXTITERATIONDEAD

CYCLEIDENTIFYBITALIVEORDEADDEAD: 
  MOV A, 039H
  CJNE A, #3, CYCLEIDENTIFYBITALIVEORDEADALIVEOTHER
  JMP CYCLENEXTITERATIONALIVE
CYCLEIDENTIFYBITALIVEORDEADDEADOTHER:
  JMP CYCLENEXTITERATIONDEAD

CYCLENEXTITERATIONALIVE:
  MOV A, 037H
  MOV R0, #2BH
  INC 043H // sequence score + 1
CYCLENEXTITERATIONALIVECHECKCOLUMN:
  CJNE A, #00000001B, CYCLENEXTITERATIONALIVENEXTCOLUMN
  JMP CYCLENEXTITERATIONALIVECOLUMNCHECKED
CYCLENEXTITERATIONALIVENEXTCOLUMN:
  RR A
  INC R0
  JMP CYCLENEXTITERATIONALIVECHECKCOLUMN
CYCLENEXTITERATIONALIVECOLUMNCHECKED:
  MOV A, @R0
  ORL A, 038H
  MOV @R0, A
  JMP CYCLEENDSTORENEWITERATION

CYCLENEXTITERATIONDEAD:
  MOV A, 037H
  MOV R0, #2BH
CYCLENEXTITERATIONDEADCHECKCOLUMN:
  CJNE A, #00000001B, CYCLENEXTITERATIONDEADNEXTCOLUMN
  JMP CYCLENEXTITERATIONDEADCOLUMNCHECKED
CYCLENEXTITERATIONDEADNEXTCOLUMN:
  RR A
  INC R0
  JMP CYCLENEXTITERATIONDEADCHECKCOLUMN
CYCLENEXTITERATIONDEADCOLUMNCHECKED:
  MOV A, 038H
  CPL A
  ANL A, @R0
  MOV @R0, A

  JMP CYCLEENDSTORENEWITERATION

CYCLEENDSTORENEWITERATION:
  JMP CYCLENEXTROW

// temp function for neighbor
CYCLEPUTAINTO03AHRL:
  CJNE A, #00100000B, CYCLENORMALPUTAINTO03AHRL
  MOV 03AH, #00000001B
  RET
CYCLENORMALPUTAINTO03AHRL:
  MOV 03AH, A
  RET
CYCLEPUTAINTO03AHRR:
  CJNE A, #10000000B, CYCLENORMALPUTAINTO03AHRR
  MOV 03AH, #00010000B
  RET
CYCLENORMALPUTAINTO03AHRR:
  MOV 03AH, A
  RET

CYCLEPUTAINTO03BHRL:
  CJNE A, #10000000B, CYCLENORMALPUTAINTO03BHRL
  MOV 03BH, #00000001B
  RET
CYCLENORMALPUTAINTO03BHRL:
  MOV 03BH, A
  RET
CYCLEPUTAINTO03BHRR:
  CJNE A, #10000000B, CYCLENORMALPUTAINTO03BHRR
  MOV 03BH, #01000000B
  RET
CYCLENORMALPUTAINTO03BHRR:
  MOV 03BH, A
  RET

CYCLEADJUSTNEIGHBORBIT:
  // 03AH <- 037H // column
  // 03BH <- 038H // row
  CJNE A, #0, CYCLEBITNOT0
  // Neighbor ID: 0
  MOV A, 037H
  RR A
  CALL CYCLEPUTAINTO03AHRR

  MOV A, 038H
  RR A
  CALL CYCLEPUTAINTO03BHRR

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT0:
  CJNE A, #1, CYCLEBITNOT1
  // Neighbor ID: 1
  MOV 03AH, 037H

  MOV A, 038H
  RR A
  CALL CYCLEPUTAINTO03BHRR

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT1:
  CJNE A, #2, CYCLEBITNOT2
  // Neighbor ID: 2
  MOV A, 037H
  RL A
  CALL CYCLEPUTAINTO03AHRL

  MOV A, 038H
  RR A
  CALL CYCLEPUTAINTO03BHRR

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT2:
  CJNE A, #3, CYCLEBITNOT3
  // Neighbor ID: 3
  MOV A, 037H
  RR A
  CALL CYCLEPUTAINTO03AHRR

  MOV 03BH, 038H

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT3:
  CJNE A, #4, CYCLEBITNOT4
  // Neighbor ID: 4
  MOV A, 037H
  RL A
  CALL CYCLEPUTAINTO03AHRL

  MOV 03BH, 038H

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT4:
  CJNE A, #5, CYCLEBITNOT5
  // Neighbor ID: 5
  MOV A, 037H
  RR A
  CALL CYCLEPUTAINTO03AHRR

  MOV A, 038H
  RL A
  CALL CYCLEPUTAINTO03BHRL

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT5:
  CJNE A, #6, CYCLEBITNOT6
  // Neighbor ID: 6
  MOV 03AH, 037H

  MOV A, 038H
  RL A
  CALL CYCLEPUTAINTO03BHRL

  JMP CYCLEINITGETTINGPOINTER
CYCLEBITNOT6:
  // Neighbor ID: 7
  MOV A, 037H
  RL A
  CALL CYCLEPUTAINTO03AHRL

  MOV A, 038H
  RL A
  CALL CYCLEPUTAINTO03BHRL
  JMP CYCLEINITGETTINGPOINTER
CYCLEINITGETTINGPOINTER:
  // left up
  MOV A, 03AH
  MOV R0, #20H
CYCLECHECKPOINTER:
  CJNE A, #00000001B, CYCLEPOINTERNOTREACH
  JMP CYCLEPOINTERREACH
CYCLEPOINTERNOTREACH:
  RR A
  INC R0
  JMP CYCLECHECKPOINTER
CYCLEPOINTERREACH:
  MOV A, @R0
  ANL A, 03BH
  CJNE A, #00000000B, CYCLECALCULATINGBITISONE
  JMP CYCLECALCULATINGBITNOTONE
CYCLECALCULATINGBITISONE:
  INC 039H
  JMP CYCLEAFTERCALCULATINGBIT
CYCLECALCULATINGBITNOTONE:
  JMP CYCLEAFTERCALCULATINGBIT
CYCLEAFTERCALCULATINGBIT:
  INC 03CH
  JMP CYCLECHECKVALIDATENEIGHBORID

  JMP CYCLENEXTROW 
ENDCYCLE:
  MOV 020H, 02BH
  MOV 021H, 02CH
  MOV 022H, 02DH
  MOV 023H, 02EH
  MOV 024H, 02FH
CHANGESEQUENCEINIT:
  MOV A, 043H
  MOV B, #3
  DIV AB
CHANGESEQUENCEIS0:
  CJNE A, #0, CHANGESEQUENCENOT0
  // 0
  MOV DPTR, #BUZZERSEQUENCETABLE0
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT0:
  CJNE A, #1, CHANGESEQUENCENOT1
  // 1
  MOV DPTR, #BUZZERSEQUENCETABLE4
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT1:
  CJNE A, #2, CHANGESEQUENCENOT2
  // 2
  MOV DPTR, #BUZZERSEQUENCETABLE5
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT2:
  CJNE A, #3, CHANGESEQUENCENOT3
  // 3
  MOV DPTR, #BUZZERSEQUENCETABLE6
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT3:
  CJNE A, #4, CHANGESEQUENCENOT4
  // 4
  MOV DPTR, #BUZZERSEQUENCETABLE1
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT4:
  CJNE A, #5, CHANGESEQUENCENOT5
  // 5
  MOV DPTR, #BUZZERSEQUENCETABLE2
  JMP ENDCHANGESEQUENCE
CHANGESEQUENCENOT5:
  // 6
  MOV DPTR, #BUZZERSEQUENCETABLE3
  JMP ENDCHANGESEQUENCE

ENDCHANGESEQUENCE:
  // reset timer
  MOV 03EH, #96
CYCLEUPDATELCDINFO:
  INC 047H
CYCLECHANGELCDINFO:
  PUSH 082H
  PUSH 083H
  // Round Number
  MOV A, #10000010B
  CALL USEATOCOMMANDLCD 
  MOV A, 047H
  CALL WRITEATOLCDNUMBER
  // Alives Number
  MOV A, #10000111B
  CALL USEATOCOMMANDLCD
  MOV A, 043H
  CALL WRITEATOLCDNUMBER
  POP 083H
  POP 082H
ENDCYCLENOUPDATE:
  POP 0F0H // B
  POP 00H // R0
  POP 0E0H // A
  JMP ENDONEMS

ENDONEMS:
  // Reset Timer
  // 1ms
  MOV TH0, #252
  MOV TL0, #23
  RETI

// --- global function ---
USEATOCOMMANDLCD:
  MOV P3, #00000000B
	MOV P3, A
  // set mode
  ANL 080H, #10011111B // P0 write command
	ORL 080H, #10000000B // enable
	CALL LCDDELAY
	ANL 080H, #01111111B
	CALL LCDDELAY
	RET

USEASETTINGDATA:
  MOV P3, #00000000B
	MOV P3, A
  // set mode write into ram (ddram or cgram)
  ORL 080H, #00100000B
  ANL 080H, #10111111B
  // enable
  ORL 080H, #10000000B
	CALL LCDDELAY
  ANL 080H, #01111111B
  CALL LCDDELAY
	RET

LCDDELAY:
  MOV 044H, #010H
LCDDELAY1:
  MOV 045H, #0FFH
LCDDELAY2:
  DJNZ 045H, LCDDELAY2
  DJNZ 044H, LCDDELAY1
  RET

CLEARLCD:
  MOV A, #00000001B
  CALL USEATOCOMMANDLCD
  MOV A, #10000000B // set ddram memory pointer to 0
  CALL USEATOCOMMANDLCD
  RET

WRITEDPTRTOLCD:
STARTWRITEDPTRLCD:
  MOV 046H, #0
CHECKWRITEDPTRLCD:
  MOV A, 046H
  MOVC A, @A+DPTR
  CJNE A, #0, WRITEDPTRDATATOLCD
  RET
WRITEDPTRDATATOLCD:
  CALL USEASETTINGDATA
  INC 046H
  JMP CHECKWRITEDPTRLCD

LCDINITTEXT:
  DB "Edit Mode", 0
LCDGAMEOFLIFETEXTROW0:
  DB "R:   A:   D:   ", 0
LCDGAMEOFLIFETEXTROW1:
  DB "S:", 0

WRITEATOLCDNUMBER:
STARTWRITEATOLCDNUMBER:
WRITINGATOLCDNUMBER:
  MOV B, #100
  DIV AB
  ADD A, #48
  CALL USEASETTINGDATA
  MOV A, B
  MOV B, #10
  DIV AB
  ADD A, #48
  CALL USEASETTINGDATA
  MOV A, B
  ADD A, #48
  CALL USEASETTINGDATA
  RET

END
