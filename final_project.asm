ORG 0000H
JMP START
ORG 000BH
JMP ONEMS
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
  MOV TH0, #253
  MOV TL0, #20
INTERRUPTSETUP:
  // Enable All
  SETB 0AFH
  // TF0 Enable
  SETB 0A9H
  // TF0 Low Priority
  CLR 0B9H

MODEEDIT:
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
  SETB 052H // set mode to GAMEOFLIFE
LOOPGAMEOFLIFE:
  CALL SCANLED
  JMP ENDOFLOOPGAMEOFLIFE
ENDOFLOOPGAMEOFLIFE:
  JMP LOOPGAMEOFLIFE

// --- main calls ---
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

ONEMS:
// this will modify display memory
ONEMSCHECKMODE:
JB 052H, ONECYCLE
JMP CURSORBLINK
// TODO: MAKE SURE IN EDIT MODE
CURSORBLINK:
  PUSH 080H // R0
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
  
  MOV 035H, #4
  JMP CURSORBLINKRETI
CURSORBLINKRETI:
  // Reset Timer
  // 1ms
  MOV TH0, #253
  MOV TL0, #20

  POP 0E0H // A
  POP 080H // R0
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

// NOTE: Check Mode and if GAMEOFLIFEMODE RUN ONECYCLE
// TODO: Move ONECYCLE TO ONEMS and with an enable bool and 1s update rate, let led lit up
ONECYCLE:
  PUSH 0E0H // A
  PUSH 00H // R0
INITCYCLE:
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
  // TODO: find if alive or dead
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
  POP 00H // R0
  POP 0E0H // A
  RETI

END
