{{ ******************************************************************************
   * Arrays In COG example                                                      *
   * James Burrows Feb 2008                                                     *
   * Version 1.0                                                                *
   ******************************************************************************
   ┌──────────────────────────────────────────┐
   │ Copyright (c) <2008> <James Burrows>     │               
   │   See end of file for terms of use.      │               
   └──────────────────────────────────────────┘

   this object provides the PUBLIC functions:
    -> N/A

   this object provides the PRIVATE functions:
    -> N/A

   this object uses the following sub OBJECTS:
    -> debug_pc
    -> fullduplexserial


   This example demonstrates basic self-modifiying PASM (propeller ASM) code to use a block of COG memory
   as an array.  It has an array of 50 long's of which "1" is written to each element in the array
   - then the array is read and the elements summed.  The result of the sum is written back to HUB memory and
   debugged back to the PC via SPIN

   Thanks to deSilva and PhilPi for the help. (ref http://forums.parallax.com/forums/default.aspx?f=25&m=250466)
 
   Read deSilva's "machine language tutorial" in the Propeller forum for help!
   at:
      http://forums.parallax.com/forums/default.aspx?f=25&m=209237
}}   

CON
    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000

    ' debug - USE onboard pins
    pcDebugRX       = 31
    pcDebugTX       = 30
     
    ' serial baud rates  
    pcDebugBaud     = 115200 

VAR
    long        stackGPS[20]
    long        asm_result
    long        PASMcogID
    
OBJ
    debug             : "Debug_PC"

PUB Start     
    ' start the PC debug object
    debug.startx(pcDebugRX,pcDebugTX,pcDebugBaud)

    repeat 6
        debug.putc(".")
        waitcnt(clkfreq/2+cnt)
    debug.putc(13)

    debug.str(string("ArraysInASM"))

    PASMcogID := cognew(@entry, @asm_result)

    debug.str(string("Running in cog "))
    debug.dec(PASMcogID)
    debug.putc(13)

    repeat
        ' show the results
        debug.str(string("data: "))
        debug.dec(asm_result)
        debug.putc(13)

        ' wait 1/2 sec
        waitcnt(clkfreq/2+cnt)        
    

        
DAT
'------------------------------------------------------------------------------------------------------------------------------
'| Entry
'------------------------------------------------------------------------------------------------------------------------------
                        org

entry                   mov     t1,par                      ' get address of HUB variable for SPIN to see

'------------------------------------------------------------------------------------------------------------------------------
'| WRITE to COG memory
'------------------------------------------------------------------------------------------------------------------------------
andAgain                mov     idxCount,#asmDataArray      ' Point to first array element.
                        movd    :write1,idxCount            ' move the address of asmDataArray to dst
                        mov     ctr,#50                     ' Initialize counter
:write1                 mov     0-0,#1                      ' put #1 into 0-0 (the element of asmDataArray) 
                        add     idxCount,#1                 ' increment count, so next...
                        movd    :write1,idxCount            ' write the address back to the :write1 dst field
                        djnz    ctr,#:write1                ' Back for another.

'------------------------------------------------------------------------------------------------------------------------------
'| READ from COG memory (PhilPi's example)
'------------------------------------------------------------------------------------------------------------------------------                        
                        movs    :read1,#asmDataArray        ' Point to first array element.
                        mov     ctr,#50                     ' Initialize counter.
                        mov     sum,#0                      ' Initialize sum.
:read1                  add     sum,0-0                     ' Add array element to sum. (0-0 is just a placeholder for the pointer value.)
                        add     :read1,#1                   ' Increment the pointer.
                        djnz    ctr,#:read1                 ' Back for another.

'------------------------------------------------------------------------------------------------------------------------------
'| WRITE the result (sum) back to the HUB memory
'------------------------------------------------------------------------------------------------------------------------------
                        wrlong  sum,t1

                        jmp     #andAgain


t1                      res         1
sum                     res         1
ctr                     res         1
idxCount                res         1
asmDataArray            res         50

FIT 496

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
