*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* start of main

*------------testing address---------------
    LEA     $100c,A4  use these 2 address' for testing specific parts of the memory. a4 = beginning. a5 = end
    LEA     $1016,A5  
*------------------------------------------
    bra scan 
*------------loop that reads the machine code--------  
*--------------and converts to binary----------------   
SCAN                  *sets up the loop that will read the machine code  
    CMP     A5,A4     *have we gone through all the memory. a5 is the end point and a4 is the beginning. We can change this to check differently in the future
    BGT     done      *if so we are done!
    lea     $A000,A2  *load the address where the binary version will be held 
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
    lea $a000,a2
    jsr read4bits
    
    
    cmp #14,d3        *is it lsl,asl,rol?
    beq lslsub
    
    bra scan         starts reading next opcode 
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

*--------------------lsl memory shift-----------------
lslsub *checks memory shifts first
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

*---------------asl sub mem shift-----------
aslsub
    bra scan
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
    bra done    not a valid addressing value. shouldnt be needed if all validation is done in the opcode       
    
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
    beq databyte
    cmp.b #3,size       *if size is a word branch here
    beq dataword
    cmp.b #2,size       *if size is a long branch here
    beq datalong
    rts                 idk if it can be 0 somehow because i think by defualt the size is always word, but idk 

databyte                *store byte data 
    move.b (a4)+,d2
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
*--------------variable subroutines---------------
resetvar                 *resets all the variables since the checks rely on them being 0
    move.b #0,size
    move.l #0,absdata
    move.l #0,imdata
    move.l #0,absdata2
    move.l #0,d1
    rts
    
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
    
* Put variables and constants here
cr  equ $0d
lf  equ $0a
size dc.b 00
absdata dc.l 0000000
absdata2 dc.l 0000000
imdata dc.l 00000000
imdata2 dc.l 00000000
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
ls  dc.b    'ls',0                                                                                                       
r   dc.b    'r',0
l   dc.b    'l',0
done 
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
