*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* start of main


    LEA     $101e,A4  *example starting address. This is our current memory pointer as well
    LEA     $1022,A5  *example end address. These are the same, so we only scan 1 command. The move command below
     
SCAN
    CMP     A5,A4     *have we gone through all the memory. a5 is the end point and a4 is the beginning. We can change this to check differently in the future
    BGT     done      *if so done!
    lea     $A000,A2  *load the address where the binary version will be held 
    move.w  (A4)+,D0  *move the current value at the memory pointer into d0
    move.b  #16,D7    *set up loop for 16 times / 16 bits to rotate
    bra     STARTLOOP *start loop to convert to binary
    
    
    move   a1,$a2 *HERE: change the EA to see the subroutine work. btw if you change these pay attention to the new memory locations. may need to adjust ending point 
    move   #1235,$2005    
    
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
    
    
*this is where we start looking for opcodes but in this case 
*its a sample move print out. No verification is done, but it is marked
*where each step of verification can happen. This is a general pattern we 
*can follow for opcode subroutines
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
*Notes: This example doesn't loop, but should demonstrate the EA subroutines by changing the move opcode above.
*if there are any problems let me know, or if this code is clunky to read as well I can explain it more. 
*This is a very brute force way of doing this but we are on a time crunch lol. Finally It's important to make sure 
*that ALL verification gets done before calling the EA subroutine because you dont want to be printing out the 
*opcode and then realize its wrong halfway through lmao.
OpCodeSearch
    jsr resetvar *this will need to be at the start of every opcode subroutine

    lea $a002,a2  *loads bits where size starts in oopcode
    jsr read2bits *adds the two bits up. can do size verification check here
    move.b d3,size *saves in variable  
    
    lea $a00a,a2   *loads address where mode bits start
    jsr read3bits  *reads the mode bits. After this part is where you can do verification
    jsr sourcesub     *prints ea
    lea comma,a1   *prints comma
    jsr printstr   
    lea $a007,a2   *loads where destination register starts
    jsr read3bits *reads register
    jsr destinationsub

    jsr checkvar    *these will need to be at the end of every opcode that can have mode = 7
    jsr checkvar2   *we need 2 different types because in the case of move both EA can be absolute words/longs
    jsr newline
           
    
    
    bra scan         *end of sample
*----------end of main---------    
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

resetvar                 *resets all the variables since the checks rely on them being 0
    move.b #0,size
    move.l #0,absdata
    move.l #0,imdata
    move.l #0,absdata2
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
done 
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
