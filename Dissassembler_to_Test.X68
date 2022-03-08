*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

            * GROUP CHARACTERS TOGETHER INTO A CONTINUOUS SECTION OF MEMORY.
GROUP       MOVE.L  #0,D0       * PUT THE COUNTER FOR THE LOOP IN D0
SHIFT       MOVE.B  (A1),D2     * COPY BYTE AT A1 TO DATA REGISTER
            BTST    D2,(A1)+    * MOVE THE BIT VALUE AT A1 INTO D2, MOVE A1 TO THE NEXT ADDRESS
            ADD.B   D2,D3       * ADD THE BIT VALUE IN D2 TO D3
            ADD.B   #1,D0       * INCREMENT COUNTER
            CMP.B   D1,D0       * LOOP FOR EACH CHARACTER
            BEQ     DONE_INPUT     
            LSL.L   #4,D3       * SHIFT ALL OF D3 ONE BYTE TO THE LEFT
            BRA     SHIFT       * LOOP
DONE_INPUT  SUBA    #$2,A1      * CLEAR THE LAST TWO MEMORY ADDRESSES OF ANY DATA THAT WON'T GET OVERWRITTEN BY TRANSFERRING-IN D3'S CONTENTS
            MOVE.B  #$FF,(A1)+
            MOVE.B  #$FF,(A1)+
            RTS
            
            * CONVERT ASCII TO HEX BY SUBTRACTING 30 FROM EACH CHARACTER
CONVERT_IPT MOVE.B  #0,D0       * PUT THE COUNTER FOR THE LOOP IN D0
        
ASCII_HEX   SUB.B   #$30,(A1)   * SUBTRACT 30 FROM BYTE LOCATION
            ADD.B   #1,D0       * ADD 1 TO COUNTER
            CMP.B   #$11,(A1)   * CONVERT TO HEX CHARACTERS IF NECESSARY, OTHERWISE BRANCH TO NEXT_CH
            BLT     NEXT_CH     
            BGT     TRY_B
            MOVE.B  #$A,(A1)
            BRA     NEXT_CH
TRY_B       CMP.B   #$12,(A1)   
            BGT     TRY_C
            MOVE.B  #$B,(A1)
            BRA     NEXT_CH              
TRY_C       CMP.B   #$13,(A1)   
            BGT     TRY_D
            MOVE.B  #$C,(A1)
            BRA     NEXT_CH
TRY_D       CMP.B   #$14,(A1)   
            BGT     TRY_E
            MOVE.B  #$D,(A1) 
            BRA     NEXT_CH
TRY_E       CMP.B   #$15,(A1)   
            BGT     TRY_F
            MOVE.B  #$E,(A1) 
            BRA     NEXT_CH
TRY_F       CMP.B   #$16,(A1)
            BNE     INV_INPUT   * BRANCH IF THE CHARACTER IS BEYOND F   
            MOVE.B  #$F,(A1)    
            BRA     NEXT_CH        
NEXT_CH     ADDA.W  #$1,A1      * INCREMENT A1 TO NEXT CHARACTER
            CMP.B   D1,D0       * COMPARE NUMBER OF CHARACTERS IN ADDRESS TO COUNTER
            BLT     ASCII_HEX   * LOOP WHILE COUNTER IS LESS THAN NUMBER OF CHARACTERS  
            RTS
            
INV_INPUT   LEA     ERROR,A1
            MOVE.B  #14,D0
            TRAP    #15
            jsr     clearreg
            BRA     START
            
            * READ USER INPUT AS STRING INTO START ADDRESS VARIABLE POINTED TO BY A1
GET_ADDR    MOVE.B  #2,D0       * TRAP TASK 2 MOVES USER INPUT AS STRING INTO (A1)
            TRAP    #15
        
            CMP.L   #0,D1       * VERIFY THAT THE INPUT IS BETWEEN 1 AND 6 CHARACTERS INCLUSIVE, OTHERWISE START OVER
            BEQ     INV_INPUT
            CMP.L   #6,D1
            BGT     INV_INPUT
        
            ADDA.W  D1,A1       * MOVE A1 TO END OF STRING. D1 CONTAINS SIZE OF INPUT IN HEX, VIA TRAP 2
            MOVE.B  #$FF,(A1)   * REMOVE 00 AT END TO PREP FOR CONVERSION TO HEX 
            RTS 

DISP_MESSG  LEA     BANNER,A1
            MOVE.B  #14,D0
            TRAP    #15  
            LEA     INSTRCT_A,A1
            MOVE.B  #14,D0
            TRAP    #15 
            LEA     INSTRCT_B,A1
            MOVE.B  #14,D0
            TRAP    #15 
            LEA     INSTRCT_C,A1
            MOVE.B  #14,D0
            TRAP    #15 
            LEA     INSTRCT_D,A1
            MOVE.B  #14,D0
            TRAP    #15 
            LEA     INSTRCT_E,A1
            MOVE.B  #14,D0
            TRAP    #15 
            LEA     INSTRCT_F,A1
            MOVE.B  #14,D0
            TRAP    #15 
            RTS

START:      jsr     clearreg
            jsr     clearscreen
            JSR     DISP_MESSG

            LEA     PROMPT_S,A1
            MOVE.B  #14,D0
            TRAP    #15            
            
            
            LEA     $200,A1    * THIS WILL CAUSE THE STARTING AND ENDING ADDRESS VALUES TO BE SAVED IN THE ROW STARTING AT $2000
            JSR     GET_ADDR    ********************* ^ THIS MAY NEED TO BE CHANGED **********************
            
            SUBA.W  D1,A1       * SET A1 TO FIRST BYTE OF ADDRESS
            JSR     CONVERT_IPT * CONVERT 10,11,12,13,14,15 TO A,B,C,D,E,F
            SUBA.W  D1,A1       * RESET A1 TO FIRST BYTE OF ADDRESS
            JSR     GROUP       * GROUP BITS TOGETHER INTO DATA REGISTER D3
            SUBA.W  D1,A1
            MOVE.L  D3,(A1)     * SAVE D3 CONTENTS AT A1 
            
            CLR.L   D3          * CLEAR D3 SINCE IT STILL CONTAINS THE LAST VALUE READ 

            LEA     PROMPT_E,A1
            MOVE.B  #14,D0
            TRAP    #15
            LEA     $200,A1

            ADDA.L  #$4,A1      * INCREMENT A1 BY 32 BITS TO ALLOW ADDRESS TO BE READ TO ADAJCENT MEMORY 
            JSR     GET_ADDR
            SUBA.W  D1,A1       * SET A1 TO FIRST BYTE OF ADDRESS
            JSR     CONVERT_IPT * CONVERT 10,11,12,13,14,15 TO A,B,C,D,E,F
            SUBA.W  D1,A1       * RESET A1 TO FIRST BYTE OF ADDRESS
            JSR     GROUP       * GROUP BITS TOGETHER INTO DATA REGISTER D3
            SUBA.W  D1,A1
            MOVE.L  D3,(A1)     * SAVE D3 CONTENTS AT A1               

            MOVE.L  $200,D2
            MOVE.L  $204,D3
            CMP.L   D2,D3
            BLT     INV_INPUT   * LOAD THE INPUT VALUES INTO D2 AND D3. RESTART IF THE END ADDRESS IS LESS THAN THE START
            CLR.L   D2
            CLR.L   D3
            JSR CLEARREG
            MOVE.L  $200,A4
            MOVE.L  $204,A5
            MOVE.B  #15,OUTLOOP
            BRA     SCAN

    RTS
    NOP
    RTS
    moveq   #40,d1
    LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7
    MOVE.B    D0,D1
    MOVE.B    D0,(A0)
    MOVE.B    D0,(A0)+
    MOVE.B    D0,-(A0)
    MOVE.B    (A0),D0
    MOVE.B    (A0),(A1)
    MOVE.B    (A0),(A1)+
    MOVE.B    (A0),-(A1)
    MOVE.B    (A0)+,D0
    MOVE.B    (A0)+,(A1)
    MOVE.B    (A0)+,(A1)+
    MOVE.B    (A0)+,-(A1)
    MOVE.B    -(A0),D0
    MOVE.B    -(A0),(A1)
    MOVE.B    -(A0),(A1)+
    MOVE.B    -(A0),-(A1)
    MOVE.W    D0,D1
    MOVE.W    D0,(A0)
    MOVE.W    D0,(A0)+
    MOVE.W    D0,-(A0)
    MOVE.W    A0,D0
    MOVE.W    A0,(A1)
    MOVE.W    A0,(A1)+
    MOVE.W    A0,-(A1)
    MOVE.W    (A0),D0
    MOVE.W    (A0),(A1)
    MOVE.W    (A0),(A1)+
    MOVE.W    (A0),-(A1)
    MOVE.W    (A0)+,D0
    MOVE.W    (A0)+,(A1)
    MOVE.W    (A0)+,(A1)+
    MOVE.W    (A0)+,-(A1)
    MOVE.W    -(A0),D0
    MOVE.W    -(A0),(A1)
    MOVE.W    -(A0),(A1)+
    MOVE.W    -(A0),-(A1)
    MOVE.L    D0,D1
    MOVE.L    D0,(A0)
    MOVE.L    D0,(A0)+
    MOVE.L    D0,-(A0)
    MOVE.L    A0,D0
    MOVE.L    A0,(A1)
    MOVE.L    A0,(A1)+
    MOVE.L    A0,-(A1)
    MOVE.L    (A0),D0
    MOVE.L    (A0),(A1)
    MOVE.L    (A0),(A1)+
    MOVE.L    (A0),-(A1)
    MOVE.L    (A0)+,D0
    MOVE.L    (A0)+,(A1)
    MOVE.L    (A0)+,(A1)+
    MOVE.L    (A0)+,-(A1)
    MOVE.L    -(A0),D0
    MOVE.L    -(A0),(A1)
    MOVE.L    -(A0),(A1)+
    MOVE.L    -(A0),-(A1)

    MOVEA.W    D0,A0
    MOVEA.W    A0,A0
    MOVEA.W    (A0),A0
    MOVEA.W    (A0)+,A0
    MOVEA.W    -(A0),A0
    MOVEA.L    D0,A0
    MOVEA.L    A0,A0
    MOVEA.L    (A0),A0
    MOVEA.L    (A0)+,A0
    MOVEA.L    -(A0),A0  
    ADD.B     D1,D2
    ADD.B     D1,(A1)
    ADD.B     D1,(A1)+
    ADD.B     D1,-(A1)
    ADD.B     (A1),D1
    ADD.B     (A1)+,D1
    ADD.B     -(A1),D1
    ADD.W     D1,D2
    ADD.W     D1,(A1)
    ADD.W     D1,(A1)+
    ADD.W     D1,-(A1)
    ADD.W     (A1),D1
    ADD.W     (A1)+,D1
    ADD.W     -(A1),D1
    ADD.L     D1,D2
    ADD.L     D1,(A1)
    ADD.L     D1,(A1)+
    ADD.L     D1,-(A1)
    ADD.L     (A1),D1
    ADD.L     (A1)+,D1
    ADD.L     -(A1),D1
    ADDA.W        D1,A2
    ADDA.W        (A1),A2
    ADDA.W        (A1)+,A2
    ADDA.W        -(A1),A2
    ADDA.L        D1,A2
    ADDA.L        (A1),A2
    ADDA.L        (A1)+,A2
    ADDA.L        -(A1),A2
    SUB.B     D1,D2
    SUB.B     D1,(A1)
    SUB.B     D1,(A1)+
    SUB.B     D1,-(A1)
    SUB.B     (A1),D1
    SUB.B     (A1)+,D1
    SUB.B     -(A1),D1
    SUB.W     D1,D2
    SUB.W     D1,(A1)
    SUB.W     D1,(A1)+
    SUB.W     D1,-(A1)
    SUB.W     A1,D1
    SUB.W     (A1),D1
    SUB.W     (A1)+,D1
    SUB.W     -(A1),D1
    SUB.L     D1,D2

    SUB.L     D1,(A1)
    SUB.L     D1,(A1)+
    SUB.L     D1,-(A1)
    SUB.L     A1,D1
    SUB.L     (A1),D1
    SUB.L     (A1)+,D1
    SUB.L     -(A1),D1    

    AND.B     D1,D2
    AND.B     D1,(A1)
    AND.B     D1,(A1)+
    AND.B     D1,-(A1)
    AND.B     (A1),D1
    AND.B     (A1)+,D1
    AND.B     -(A1),D1
    AND.W     D1,D2
    AND.W     D1,(A1)
    AND.W     D1,(A1)+
    AND.W     D1,-(A1)
    AND.W     (A1),D1
    AND.W     (A1)+,D1
    AND.W     -(A1),D1
    AND.L     D1,D2
    AND.L     D1,(A1)
    AND.L     D1,(A1)+
    AND.L     D1,-(A1)
    AND.L     (A1),D1
    AND.L     (A1)+,D1
    AND.L     -(A1),D1
    OR.B     D1,D2
    OR.B     D1,(A1)
    OR.B     D1,(A1)+
    OR.B     D1,-(A1)
    OR.B     (A1),D1
    OR.B     (A1)+,D1
    OR.B     -(A1),D1
    OR.W     D1,D2
    OR.W     D1,(A1)
    OR.W     D1,(A1)+
    OR.W     D1,-(A1)
    OR.W     (A1),D1
    OR.W     (A1)+,D1
    OR.W     -(A1),D1
    OR.L     D1,D2
    OR.L     D1,(A1)
    OR.L     D1,(A1)+
    OR.L     D1,-(A1)
    OR.L     (A1),D1
    OR.L     (A1)+,D1
    OR.L     -(A1),D1
    LSL.B     D1,D2
    LSL.W     D1,D2
    LSL.W     (A1)
    LSL.W     (A1)+
    LSL.W     -(A1)
    LSL.L     D1,D2
    LSR.B     D1,D2
    LSR.W     D1,D2
    LSR.W     (A1)
    LSR.W     (A1)+
    LSR.W     -(A1)
    LSR.L     D1,D2    
    ASR.B     D1,D2
    ASR.W     D1,D2
    ASR.W     (A1)
    ASR.W     (A1)+
    ASR.W     -(A1)
    ASR.L     D1,D2
    ASL.B     D1,D2
    ASL.W     D1,D2
    ASL.W     (A1)
    ASL.W     (A1)+
    ASL.W     -(A1)
    ASL.L     D1,D2  
    BGT.B     label1
    BGT.B     label2
    BLE.B     label1
    BLE.B     label2
    BGE.B     label1
    BEQ.B     label2
    BEQ.W     label1
    JSR       (A0)
    JSR       $1234
    JSR       $12345678
    JSR       label1
    JSR       label2
    JSR       label3
    NOP
    RTS
label1
    NOP
    RTS
    LEA       $12,A0
    LEA       $1234,A0
    LEA       $12345678,A0
label2
    MOVEQ     #$0,D0
    MOVEQ     #$12,D0
    MOVEQ     #$FF,D0
label3
   
    ADDA.W    $12,A2
    ADDA.W    $1234,A2
    ADDA.W    $12345678,A2
    ADDA.W    #$1234,A2
    ADDA.L    $12,A2
    ADDA.L    $1234,A2
    ADDA.L    $12345678,A2
    ADDA.L    #$12345678,A2

    AND.B     D1,$12
    AND.B     D1,$1234
    AND.B     D1,$12345678
    AND.B     $12,D1
    AND.B     $1234,D1
    AND.B     $12345678,D1
    AND.B     #$12,D1
    AND.W     D1,$12
    AND.W     D1,$1234
    AND.W     D1,$12345678
    AND.W     $12,D1
    AND.W     $1234,D1
    AND.W     $12345678,D1
    AND.W     #$1234,D1
    AND.L     D1,$12
    AND.L     D1,$1234
    AND.L     D1,$12345678
    AND.L     $12,D1
    AND.L     $1234,D1
    AND.L     $12345678,D1
    AND.L     #$12345678,D1
    LSL.B     #$1,D2
    LSL.W     #$2,D2
    LSL.L     #$3,D2
    LSL.W     $12
    LSL.W     $1234
    LSL.W     $12345678
    ASR.B     #$1,D2
    ASR.W     #$2,D2
    ASR.L     #$3,D2
    ASR.W     $12
    ASR.W     $1234
    ASR.W     $12345678
label4
    BGT.B     label4
    BGT.B     label4
    BGT.B     label4
    BLE.W     label1
    BLE.W     label2
    BLE.W     label3
    BEQ.W     label1
    BEQ.W     label2
    BEQ.W     label3
    JSR       label1
    JSR       label2
    JSR       label3

    
      
*------------loop that reads the machine code--------  
*--------------and converts to binary----------------   
SCAN                  *sets up the loop that will read the machine code  
    CMP.L     A5,A4     *have we gone through all the memory. a5 is the end point and a4 is the beginning. We can change this to check differently in the future
    BGT     restartsub      *if so we are done!
    CMP.B   #0,OUTLOOP
    BEQ     continuesub
    SUB.B   #1,OUTLOOP

    lea     $A000,A2  *load the address where the binary version will be held
    move.l  a4,d6 
    move.w  (A4)+,D0  *move the current value at the memory pointer into d0
    move.b  #16,D7    *set up loop for 16 times / 16 bits to rotate
    bra     STARTLOOP *start loop to convert to binary
    
STARTLOOP

    cmp     #0,D7           *if loop complete start looking for opcode
    beq     OpCodeSearch    
    subi    #1,D7           *update loop
    
    
    ROL.W   #1,D0           rol bits to the right by 1
    BCS     ADDONE          if c flag is flipped bit = 1
    BRA     ADDZERO         else its a 0
    
ADDONE
    MOVE.B  #1,(A2)+        adds one at current a2 pointer and loops to beginning
    BRA     STARTLOOP
    
ADDZERO
    MOVE.B  #0,(A2)+        adds zero at current a2 pointer and loops to beginning
    BRA     STARTLOOP    
    
*------------------------------------------------------
*-----------------opcode searching starts here---------    
*this is where we start looking for opcodes. i marked
*where i think each step of verification can happen. This is a general pattern we 
*can follow for opcode subroutines. unless anyone has wants to go a different way lmao. This is very brute force way to do this
*1) read the bits that we need to verify first. Example being reading 3 bits of  source mode
*   and verify they are valid. If they = 7 then make sure the register is valid
*2) if you need to do this with destination mode as well do that beforre or after. 
*3) You can also check size by reading the two bits and veryifing that they are valid. Some opcodes
*   cant be byte size for example
*4) check any other specific bits you need to
*5) once everything is checked and valid we can now print out the opcode name, size, and memory location (this will be handled in the opcode)
*   and getting ready to call the EA subroutines
*6) depending on the format in assembly you will be calling the destination or source subroutine first.
*   Make sure to read the mode bits first before calling either subroutine. This is important, because 
*   it sets the memory pointer to the correct location after reading the initial 3 bits and storing them in d3
*7) once this is done the opcode should be fully outputed onto the console and should loop back to scan. 
OpCodeSearch
  
    *START OPCODE SEARCHING HERE. For adding more opcodes: compare the hex value of whatever opcode you want to jump to with the number in d3 :)
    jsr newline       *setup to search for opcode
    
    
    move.b #16,d2
    move.l d6,d1
    move.b #15,d0
    trap    #15
    jsr printspace
    
    
    lea $a000,a2
    jsr read4bits
    cmp #4,d3
    blt movesub
    cmp #7,d3
    beq moveqsub
    cmp #8,d3
    beq orsub
    cmp #4,d3
    beq jsrsub      *is it jsr?
    cmp #12,d3        *is it and?
    beq andsub
    cmp #6,d3        *is it BCC?
    beq bccsub
    cmp #14,d3        *is it lsl,asl,rol?
    beq lslsub
    cmp #9,d3         *is it sub (Note: if the the source is #<data> the machine code converts the command into subq or subi which is not a required opcode)
    beq subsub
    cmp #13,d3
    beq addsub
    
    bra scan         $$
*----------end of searching/main----------------------    

*----------bit reading subroutines--------------------
read1bit
    move.b  (a2)+,d3
    rts
    
read2bits              *reads 2 bits from pre-set address. Uses data registers d6,d5 and stores result in d3
    move.b  (a2)+,d5
    muls    #2,d5
    add.b   d5,d6
    add.b   (a2)+,d6
    move.b  d6,d3
    move.b  #0,d6
    rts

read3bits              *reads 3 bits by reading the first one multiplying it by 4 and then calling read2bits
    move.b  (a2)+,d5
    muls    #4,d5
    add.b   d5,d6
    jsr     read2bits
    rts

read4bits              *reads 4 bits using the same method as read3bits
    move.b  (a2)+,d6
    muls    #8,d6
    jsr     read3bits
    rts

*-----------------------------------------------------
*--------------------OpCode Subroutines---------------
*--------------------move sub-------------------------
movesub *check to make sure bits 13-12 arent = 0. and that destination mode != 1 or 7 with register = 4
    jsr resetvar
    lea $a002,a2
    jsr read2bits
    cmp #0,d3
    beq scan       $$
    move.b d3,size
    lea $a007,a2
    jsr read3bits
    cmp #1,d3
    beq moveasub
    cmp #7,d3
    beq movemodeseven
    bra movecont
    
movemodeseven
    lea $a004,a2
    jsr read3bits
    cmp #1,d3
    bgt scan        $$
movecont
    lea move,a1
    jsr printstr
    move.b size,d3
    jsr printsize2 
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    lea comma,a1
    jsr printstr
    lea $a007,a2
    jsr read3bits
    jsr destinationsub
    jsr checkvar
    jsr checkvar2
    bra scan
*--------------------movea sub------------------------
moveasub
    lea move,a1
    jsr printstr
    lea an,a1
    jsr printstr
    move.b size,d3
    jsr printsize2
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    lea comma,a1
    jsr printstr
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr ansub
    jsr checkvar
    jsr checkvar2
    bra scan
*--------------------moveq sub------------------------
moveqsub
    jsr resetvar
    lea $a007,a2
    move.b (a2),d3
    cmp #0,d3
    bne scan         $$
    suba #1,a4
    move.b (a4)+,d3
    move.l d3,imdata
    lea moveq,a1
    jsr printstr
    jsr printspace
    lea datamode,a1
    jsr printstr
    lea comma,a1
    jsr printstr
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    jsr checkvar
    bra scan
    
*--------------------lsl memory shift-----------------
lslsub *checks memory shifts first this only needs to be checked once
    lea $a00a,a2
    jsr read3bits
    cmp #2,d3
    blt lslsub2    *bad addressing mode
    cmp #7,d3
    bne lslcont
    jsr read3bits
    cmp #4,d3
    beq lslsub2    *correct mode wrong register#
    
lslcont *checking specific bits 11-8. Can be 2 or 3. also need to check bits 7 and 6 to make sure they are = to 3
    jsr resetvar
    lea $a004,a2
    jsr read4bits *get bits 11-8
    cmp #3,d3
    bgt lslsub2   *less than 2
    cmp #2,d3
    blt lslsub2   *greater than 3
    jsr read2bits *get bits 7-6
    cmp #3,d3
    bne lslsub2   *validation is done now. It has to be lsl or lsr
    
    lea ls,a1     *print opcode
    jsr printstr
    
    move.b $a007,d3 *print left or right shift
    jsr printLorR
    
    jsr printspace
      
    lea $a00a,a2    *print EA
    jsr read3bits
    jsr sourcesub
    
    jsr checkvar    *print any absolute or immediete data
    jsr checkvar2
    bra scan

*-------------------lsl register shift---------------     
lslsub2 *checks register shifts. Steps needed: check bits 7-6 and make sure its NOT 3. check bits 4 and 3 and make sure its 1 
    jsr resetvar
    lea $a008,a2   checkinng bits 7-6
    jsr read2bits
    cmp #3,d3
    beq  aslsub
     
    lea $a00b,a2   checking bits 5-4
    jsr read2bits
    cmp #1,d3
    bne aslsub
    
    lea ls,a1      *validation is done print out
    jsr printstr    
    
    lea $a007,a2
    jsr read1bit
    jsr printLorR
    
    jsr read2bits
    jsr printSize
    cmp #0,(a2)    *check if its immediete data stored or a register in bits 11-9
    beq imShift    * branch if immediete data
    
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    bra lsl2cont
    
imShift  
    lea $a004,a2
    jsr read3bits  
    move.l d3,imdata
    lea datamode,a1
    jsr printstr
    
lsl2cont    
    lea comma,a1
    jsr printstr
    
    lea $a00d,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    
    jsr checkvar   
    jsr checkvar2
    bra scan  
    
*-------------------asl memory subroutine--------
aslsub
    
aslcont *checking specific bits 11-8. Can be 0 or 1. also need to check bits 7 and 6 to make sure they are = to 3
    jsr resetvar
    lea $a004,a2
    jsr read4bits *get bits 11-8
    cmp #1,d3
    bgt aslsub2   *branch if greater than 1
    jsr read2bits *get bits 7-6
    cmp #3,d3
    bne aslsub2   *validation is done now. It has to be asl or asr
    
    lea as,a1     *print opcode
    jsr printstr
    
    move.b $a007,d3 *print left or right shift
    jsr printLorR
    
    jsr printspace
      
    lea $a00a,a2    *print EA
    jsr read3bits
    jsr sourcesub
    
    jsr checkvar    *print any absolute or immediete data
    jsr checkvar2
    bra scan
 
*----------------as register subroutine------------   
aslsub2
    
    jsr resetvar
    lea $a008,a2   checkinng bits 7-6
    jsr read2bits
    cmp #3,d3
    beq  rolsub
     
    lea $a00b,a2   checking bits 4-3
    jsr read2bits
    cmp #0,d3
    bne rolsub
    
    lea as,a1      *validation is done print out
    jsr printstr    
    
    lea $a007,a2
    jsr read1bit
    jsr printLorR
    
    jsr read2bits
    jsr printSize
    cmp.b #0,(a2)    *check if its immediete data stored or a register in bits 11-9
    beq imShiftasl    * branch if immediete data
    
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    bra asl2cont
    
imShiftasl  
    lea $a004,a2
    jsr read3bits  
    move.l d3,imdata
    lea datamode,a1
    jsr printstr
    
asl2cont    
    lea comma,a1
    jsr printstr
    
    lea $a00d,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    
    jsr checkvar   
    jsr checkvar2
    
    bra scan
    
*--------------ror memory rotate-------------------
rolsub
    jsr resetvar
    lea $a004,a2
    jsr read4bits *get bits 11-8
    cmp #7,d3
    bgt rolsub2   *greater than 7
    cmp #6,d3
    blt rolsub2   *less than 6
    jsr read2bits *get bits 7-6
    cmp #3,d3
    bne rolsub2  *validation is done now. It has to be rol or ror
    
    lea ro,a1     *print opcode
    jsr printstr
    
    move.b $a007,d3 *print left or right shift
    jsr printLorR
    
    jsr printspace
      
    lea $a00a,a2    *print EA
    jsr read3bits
    jsr sourcesub
    
    jsr checkvar    *print any absolute or immediete data
    jsr checkvar2
    bra scan
*--------------for register rotate---------------
rolsub2
    jsr resetvar
    lea $a008,a2   checkinng bits 7-6
    jsr read2bits
    cmp #3,d3
    beq  scan      $$
     
    lea $a00b,a2   checking bits 4-3
    jsr read2bits
    cmp #3,d3
    bne scan       $$
      
    lea ro,a1      *validation is done print out
    jsr printstr    
    
    lea $a007,a2
    jsr read1bit
    jsr printLorR
    
    jsr read2bits
    jsr printSize
    cmp.b #0,(a2)    *check if its immediete data stored or a register in bits 11-9
    beq imShiftrol    * branch if immediete data
    
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    bra rol2cont
    
imShiftrol  
    lea $a004,a2
    jsr read3bits  
    move.l d3,imdata
    lea datamode,a1
    jsr printstr
    
rol2cont    
    lea comma,a1
    jsr printstr
    
    lea $a00d,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    
    jsr checkvar   
    jsr checkvar2
    
    bra scan
*-------------------BCC subroutine--------------------
bccsub       *first check bits 11-8 are NOT 1. Then check if 8 bit displacement = 00 or ff. if 00 another 16 bit displacement. if ff then 32 bit displacement
    jsr resetvar
    sub #2,a4
    move.l a4,d2
    add #2,a4
    
    lea $a004,a2    *checking bits 11-8
    jsr read4bits
    cmp #1,d3
    beq scan      $$
            *this is all the validation that can happen on this step so we can start printing the opcode
    
    
    
    jsr read4bits   *reads the next 8 bits. This is to check for $00 or $FF
    move.b d3,d4
    jsr read4bits
    add.b d4,d3
       
    cmp #0,d3               *checks bit displacement, but if no displacemnt move foward
    beq sixteenBitDisplacement
    cmp #255,d3
    beq thirtyTwoBitDisplacement
    
    sub   #1,a4
    move.b (a4)+,d4
    cmp    #7,d4
    bgt    bytenegative
    add.b   d4,d2

    bra bccCont
bytenegative
    move.b #$FF,d5
    sub.b    d4,d5
    sub.b   d5,d2
    bra    bccCont
    
sixteenBitDisplacement
    move.w (a4)+,d4
    cmp    #$80,d4
    bgt    wordnegative
    add.w d4,d2 
    bra bccCont
wordnegative
    move.w #$FFFF,d5
    sub.w    d4,d5
    sub.w   d5,d2
    bra    bccCont
    
thirtyTwoBitDisplacement  
    move.l (a4)+,d4
    cmp    #$8000,d4
    bgt    longnegative
    add.l  d4,d2 
    bra    bccCont
longnegative
    move.l #$FFFFFFFF,d5
    sub.l    d4,d5
    sub.l   d5,d2

bccCont
    move.l d2,displacementvalue
    lea $a004,a2    
    jsr read4bits
    jsr printBcc
    jsr printstr
    jsr printspace
    move.l displacementvalue,d1
    move.b #16,d2
    move.b #15,d0
    trap #15
    bra scan
*--------------------sub subroutine------------------
subsub *----------------opmode(bits 8-6) cannot be 3 or 7. if less than 3 then destination than correct modes have to be checked, otherwise all modes are fine
    jsr resetvar
    
    lea $a007,a2     check opmode
    jsr read3bits      
    cmp #3,d3        opmode cant be 3 or 7 
    beq scan         $$
    cmp #7,d3        
    beq scan         $$ thats all we need to check because easy68k automatically converts incorect addressing modes to the correct command such as subi,suba,subq
    
    lea sub,a1        
    jsr printstr
    cmp #3,d3
    bgt eafirst
easecond
    move.b d3,size
    jsr printsize
    addi #1,size
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    lea comma,a1
    jsr printstr
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    jsr checkvar
    bra scan
    
 
eafirst
    subq.b #4,d3
    move.b d3,size
    jsr printsize
    addi #1,size
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr dnsub
    lea comma,a1
    jsr printstr
    lea $a00a,a2
    jsr read3bits 
    jsr sourcesub
    jsr checkvar
    bra scan
*----------------------addsub------------------------
addsub
   jsr resetvar
    
    lea $a007,a2     check opmode
    jsr read3bits      
    cmp #3,d3        opmode cant be 3 or 7 
    beq addasub 
    cmp #7,d3        
    beq addasub         thats all we need to check because easy68k automatically converts incorect addressing modes to the correct command such as subi,suba,subq
    
    lea add,a1        
    jsr printstr
    cmp #3,d3
    bgt eafirst
    bra easecond
    
addasub
    lea add,a1        
    jsr printstr
    lea an,a1
    jsr printstr
    cmp #3,d3
    beq longadda
    move.b #2,size
    bra addacont
longadda
    move.b #1,size
addacont
    jsr printsize2
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    lea comma,a1
    jsr printstr
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr ansub
    bra scan
    
    
*-------------------AND sub--------------------------
andsub  *---------this is pretty much a repeat of the sub above. It will be using the same easecond, eafirst subroutine
    jsr resetvar
    
    lea $a007,a2   check opmode
    jsr read3bits
    cmp #3,d3       ca
    beq scan        $$
    cmp #7,d3
    beq scan        $$
    cmp #7,d3
    blt andcont
     
andcont    
    lea and,a1
    jsr printstr
    cmp #3,d3
    bgt eafirst
    bra easecond
*-------------------Not sub---------------------------
notsub    *check that size !=3 and mode 7 register <2
    jsr resetvar
    lea $a004,a2
    jsr read4bits
    cmp #6,d3
    bne rtssub
    jsr read2bits
    cmp #3,d3
    beq rtssub
    jsr read3bits
    cmp #1,d3
    beq rtssub
    cmp #7,d3
    bne notcont
    jsr read3bits
    cmp #2,d3
    blt notcont
    bra rtssub
notcont
    lea $a008,a2
    jsr read2bits
    move.b d3,size
    
    lea not,a1
    jsr printstr
    jsr printsize
    jsr read3bits
    jsr sourcesub
    jsr checkvar
    bra scan
    
*------------------JSR sub----------------------------
jsrsub *checking that is required are on bits 5-3. can only be 2, 7 (register 0,1), and bits 11-8 have to = E
    jsr resetvar
    lea $a004,a2
    jsr read4bits
    cmp #14,d3
    bne notsub
    lea $a00a,a2
    jsr read3bits
    cmp #2,d3
    beq jsrcont
    cmp #7,d3
    bne notsub
    jsr read3bits
    cmp #2,d3
    blt jsrcont
    bra notsub
jsrcont
    lea jsr,a1
    jsr printstr
    jsr printspace
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    jsr printspace 
    jsr checkvar
    bra scan
*-------------------rts sub------------------------
rtssub
    lea $a008,a2
    jsr read4bits
    cmp #7,d3
    bne leasub
    jsr read4bits
    cmp #5,d3
    bne nopsub  
    lea rts,a1
    jsr printstr
    
    bra scan
*-------------------nop sub------------------------
nopsub  
    cmp #1,d3
    bne leasub
    lea nopsub,a1
    jsr printstr
    bra scan
*-------------------lea sub-----------------------
leasub
    jsr resetvar
    
    lea $a007,a2
    jsr read3bits
    cmp #7,d3
    bne scan       $$
    jsr read3bits
    cmp #2,d3
    beq leacont
    cmp #7,d3
    bne scan        $$
    jsr read3bits
    cmp #2,d3
    blt leacont
    bra scan       $$
    
leacont
    lea lea,a1
    jsr printstr
    jsr printspace
    lea $a00a,a2
    jsr read3bits
    jsr sourcesub
    
    lea comma,a1
    jsr printstr
    
    lea $a004,a2
    jsr read3bits
    move.b d3,d1
    jsr ansub
    jsr checkvar
    bra scan  
*-------------------or sub-------------------------
orsub
    jsr resetvar
    lea $a007,a2     check opmode
    jsr read3bits      
    cmp #3,d3        opmode cant be 3 or 7 
    beq scan         $$
    cmp #7,d3        
    beq scan         $$
    
    jsr read3bits
    cmp #1,d3
    beq scan        $$
    
    lea or,a1
    jsr printstr
    
    lea $a007,a2
    jsr read3bits
    cmp #3,d3
    bgt eafirst
    bra easecond
*-------------------EA source and destination sub-----
sourcesub              *subroutine that prepares the data for the general ea subroutine. Used when the 
    move.l  d3,d4      *    used when the register is after the mode.
    jsr     read3bits  *first need to move the current mode value out of d3 where it is stored and hold it in d4.
    move.b  d3,d1      *moves the mode that was just found to d1 for future output purposes
    bra easub          *starts the ea subroutine
    
destinationsub         *does the same thing as sourcesub but the register is before the mode so we sub 6 form the current a2 pointer
    move.l d3,d4
    suba   #6,a2
    jsr    read3bits
    move.b d3,d1 
*---------------------ea subroutine------------------
easub     *d5 = mode value, d6  = register value
    
    cmp #0,d4   is it dn?
    beq dnsub
    cmp #1,d4   is it an?
    beq ansub
    cmp #2,d4   is it (an)?
    beq anparensub
    cmp #3,d4   is it (an)+?
    beq anpostsub
    cmp #4,d4   is it -(an)?
    beq anpresub
    cmp #7,d4   is it (xxx).w,(xxx).l,#<data>?
    beq immedietesub
    bra dnsub    not a valid addressing value. shouldnt be needed if all validation is done in the opcode       
    
dnsub                   *prints dn and the register value
    lea dn,a1           *loads 'd' into a1
    jsr printstr        *prints whatever is in a1
    jsr printnum        *prints whatever is in d2
    rts                 *return 
    
ansub                   *same format as dnsub     
    lea an,a1
    jsr printstr
    jsr printnum
    rts
    
anparensub              *same thing just more outputing with the two parenthesis
    lea beginparen,a1
    jsr printstr
    lea an,a1
    jsr printstr
    jsr printnum
    lea endparen,a1
    jsr printstr
    rts 
    
anpostsub               *same thing
    jsr anparensub
    lea plus,a1
    jsr printstr
    rts
    
anpresub                *same thing
    lea minus,a1
    jsr printstr
    jsr anparensub
    rts

*-----------------mode=7 subroutines-----------------------    
immedietesub            *checks what register the mode is
    cmp #0,d1           *(xxx).W?
    beq xxxw
    cmp #1,d1
    beq xxxl            (xxx).L?
    cmp #4,d1
    beq setdata         #<data>?
    rts                 not a valid register. This should also be checked in the opcode. This can be another subroutine if we want to make it

xxxw
    lea abswmode,a1    prints the addressing mode out
    jsr printstr
    cmp.l   #0,absdata this checks if this is the first absolute addressing mode
    bne     xxxl2      if not we need to save the data somewhere else
    move.w (a4)+,d2    else we move the data to the absdata variable 
    move.l d2,absdata
    rts                retturn
    
xxxl                   *same as above but with long variables
    lea abslmode,a1
    jsr printstr
    cmp.l   #0,absdata
    bne     xxxl2
    move.l (a4)+,absdata
    rts

xxxw2                  *called if this is the second absolute addressing mode in the opcode
    move.w (a4)+,d2
    move.l d2,absdata2
    rts
    
xxxl2
    move.l (a4)+,d2    *same as above
    move.l d2,absdata2
    rts
    
setdata                 *called if mode = 7  and register = 4
    lea datamode,a1     *prints addressing mode out (#<data>)
    jsr printstr
    move.b size,d5      *grabs the size
    cmp.b #1,size       *if the size is a byte branch here
    beq dataword
    cmp.b #3,size       *if size is a word branch here
    beq dataword
    cmp.b #2,size       *if size is a long branch here
    beq datalong
    bra dataword
    rts                 idk if it can be 0 somehow because i think by defualt the size is always word, but idk 

databyte                *store byte data 
    move.w (a4)+,d2
    move.l d2,imdata
    rts

dataword                *store word data
    move.w (a4)+,d2
    move.l d2,imdata
    rts
datalong                *store long data
    move.l (a4)+,imdata
    rts
    
*---------------------printing shortcuts---------------
printimdata             *prints the imdata and then checks if absolute data also need to be printed
    jsr printspace
    move.l imdata,d1
    jsr printnum
    cmp.l #0,absdata
    bne printabsdata
    rts

printabsdata            *uses trap 15 to print the memory address of the absolute data
    jsr printspace
    move.l absdata,d1
    move.l #16,d2
    move.l #15,d0
    trap   #15
    rts

printabsdata2           *same as above just prints the 2nd variable not the 1st
    jsr printspace
    move.l absdata2,d1
    move.l #16,d2
    move.l #15,d0
    trap   #15
    rts
       
printstr                 *prints whatever is in a1
    
    move    #14,d0
    trap    #15
    rts    
    
printnum                 *prints whatever is in d0
    move    #3,d0
    trap    #15
    rts    
printspace               *prints a tab even though it says space. Could be usefule for indent between memory -> opcode -> addressing modes -> data
    lea space,a1
    jsr printstr  
    rts

newline
    lea enter,a1
    jsr printstr
    rts 

printLorR
    cmp #0,d3
    beq printR
    bra printL

printR
    lea r,a1
    jsr printstr
    rts

printL
    lea l,a1
    jsr printstr
    rts
printSize
    cmp #0,d3
    beq printByte
    cmp #1,d3
    beq printWord
    bra PrintLong
printsize2
    cmp #1,d3
    beq printByte
    cmp #3,d3
    beq printWord
    bra printLong
printByte
    lea byte,a1
    jsr printstr
    rts       

printWord
    lea word,a1
    jsr printstr
    rts 
    
printLong
    lea long,a1
    jsr printstr
    rts 
    
printBcc
    lea b,a1
    jsr printstr
    cmp #0,d3
    beq bra
    cmp #2,d3
    beq bhi
    cmp #3,d3
    beq bls
    cmp #4,d3
    beq bcc
    cmp #5,d3
    beq bcs
    cmp #6,d3
    beq bne
    cmp #7,d3
    beq beq
    cmp #8,d3
    beq bvc
    cmp #9,d3
    beq bvs
    cmp #10,d3
    beq bpi
    cmp #11,d3
    beq bmi
    cmp #12,d3
    beq bge
    cmp #13,d3
    beq blt
    cmp #14,d3
    beq bgt
    cmp #15,d3
    beq ble
    
bra
    lea ra,a1
    rts
bhi
    lea hi,a1
    rts
bls
    lea ls,a1
    rts
bcc
    lea cc,a1
    rts
bcs
    lea cs,a1
    rts
bne
    lea ne,a1
    rts
beq
    lea eq,a1
    rts
bvc
    lea vc,a1
    rts
bvs
    lea vs,a1
    rts
bpi
    lea pi,a1
    rts
bmi
    lea mi,a1
    rts
bge
    lea ge,a1
    rts
blt
    lea lt,a1
    rts
bgt
    lea gt,a1
    rts
ble
    lea le,a1
    rts
    
*--------------variable subroutines---------------
resetvar                 *resets all the variables since the checks rely on them being 0
    move.b #0,size
    move.l #0,absdata
    move.l #0,imdata
    move.l #0,absdata2
    clr.l  d1
    clr.l  d4
    rts

CLEARREG
    MOVE.L #0,A1
    MOVE.L #0,A2
    MOVE.L #0,A3
    MOVE.L #0,A4
    MOVE.L #0,A5
    MOVE.L #0,A6

    CLR.L  D1
    CLR.L  D2
    CLR.L  D3
    CLR.L  D4
    CLR.L  D5
    CLR.L  D6
    CLR.L  D7
    RTS

checkvar
    cmp.l #0,imdata *checks if any data has been stored ( if mode was = 7)
    bne printimdata
    cmp.l #0,absdata
    bne printabsdata
    rts

checkvar2            *needed with the extra variable in case of two absolute addressing modes
    cmp.l #0,absdata2
    bne printabsdata2
    rts
resetoutputloop
    jsr clearscreen
    lea banner,a1
    jsr printstr
    jsr newline
    jsr newline
    jsr newline
    jsr newline
    jsr newline
    move.b #15,OUTLOOP
    bra scan
continuesub
    jsr newline
    jsr newline
    lea continuemsg,a1
    jsr printstr
    lea $410,a1
    move.b #2,d0
    trap   #15
    cmp.b  #89,(a1)
    beq resetoutputloop
    cmp.b  #121,(a1)
    beq resetoutputloop
    cmp.b  #78,(a1)
    beq restartsub
    cmp.b  #110,(a1)
    beq restartsub
    jsr newline
    lea erroryn,a1
    jsr printstr
    bra continuesub
    
restartsub
    jsr newline
    lea restartmsg,a1
    jsr printstr
    lea $410,a1
    move.b #2,d0
    trap   #15
    cmp.b  #89,(a1)
    beq START
    cmp.b  #121,(a1)
    beq START
    cmp.b  #78,(a1)
    beq done
    cmp.b  #110,(a1)
    beq done
    jsr newline
    lea erroryn,a1
    jsr printstr
    bra restartsub

clearscreen
    move.b #11,d0
    move.w #$FF00,d1
    trap   #15
    rts
       

* Put variables and constants here
cr  equ $0d
lf  equ $0a
size dc.b 00
absdata dc.l 0000000
absdata2 dc.l 0000000
imdata dc.l 00000000
imdata2 dc.l 00000000
displacementvalue dc.l 00000000
byte dc '.b ',0
word dc '.w ',0
long dc '.l ',0
dn   dc    'd',0
an  dc    'a',0
plus dc '+',0
minus dc '-',0
comma dc ',',0
beginparen dc '(',0
endparen dc ')',0 
datamode dc '#<data>',0 
abswmode dc '(xxx).w',0
abslmode dc '(xxx).l',0
space dc.b  '   ',0
enter dc.b '',cr,lf,0
alldone dc.b 'Program Done. Thank you!',0
sub dc.b    'sub',0
and dc.b    'and',0
not dc.b    'not',0
jsr dc.b    'jsr',0
rts dc.b    'rts',0
nop dc.b    'nop',0
add dc.b    'add',0
lea dc.b    'lea',0
move dc.b   'move',0
moveq dc.b  'moveq',0
or dc.b     'or',0
ls  dc.b    'ls',0   
as  dc.b    'as',0  
ro  dc.b    'ro',0                                                                                                  
r   dc.b    'r',0
l   dc.b    'l',0
b   dc.b    'b',0
ra   dc.b    'ra',0
hi   dc.b    'hi',0
cc   dc.b    'cc',0
cs  dc.b    'cs',0
ne   dc.b    'ne',0
eq   dc.b    'eq',0
vc   dc.b    'vc',0
vs  dc.b    'vs',0
pi   dc.b    'pi',0
mi   dc.b    'mi',0
ge   dc.b    'ge',0
lt   dc.b    'lt',0
gt   dc.b    'gt',0
le   dc.b    'le',0
BANNER      DC.B    '******************<--|TERAFLOP 68K DISASSEMBLER|-->*****************',$0D,$0A,0
INSTRCT_A   DC.B    'INSTRUCTIONS: ENTER THE STARTING AND ENDING ADDRESSES WHEN PROMPTED.',$0D,$0A,0
INSTRCT_B   DC.B    'EACH ADDRESS MUST BE GIVEN IN HEXADECIMAL. ENSURE THAT THE END ADDRESS',$0D,$0A,0
INSTRCT_C   DC.B    'IS GREATER THAN THE START ADDRESS. ENTER THE HEXADECIMAL VALUE OF THE',$0D,$0A,0
INSTRCT_D   DC.B    'ADDRESS ONLY. FOR EXAMPLE, IF THE STARTING ADDRESS IS "00A2CE0" ENTER',$0D,$0A,0
INSTRCT_E   DC.B    '"A2CE0" ONLY. DO NOT ENTER ADDRESS VALUES LONGER THAN 6 OR LESS THAN 1',$0D,$0A,0
INSTRCT_F   DC.B    'CHARACTER(S). DO NOT ENTER ADDRESSES OUTSIDE OF THE RANGE 0 TO FFFFF0.',$0D,$0A,0
PROMPT_S    DC.B    'ENTER A START ADDRESS > ',0
PROMPT_E    DC.B    'ENTER AN END ADDRESS > ',0
ERROR       DC.B    '********************INVALID INPUT!!! RESTARTING.********************',$0D,$0A,0 
erroryn     dc.b    'INVALID INPUT! PLEASE INPUT Y OR N',cr,lf,0
continuemsg dc.b   'PRINT NEXT LINES Y/N: ',0
restartmsg dc.b   'ENTER NEW STARTING AND END ADDRESS? Y/N: ',0
OUTLOOP     DC.B    00
    move.b d1,d2  *if there is not a command before this then the variables will affect how branching works for some reason. idk why but this is the easy fix
done 
    jsr newline
    jsr newline
    lea alldone,a1
    jsr printstr    


    END    START        ; last line of source



















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
