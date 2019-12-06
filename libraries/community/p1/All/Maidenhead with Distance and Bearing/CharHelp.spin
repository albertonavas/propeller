{{

*******************************************
*  Common character and string functions  *
*  Author: Thomas P. Sullivan             *
*  Copyright (c) 2008 TPS                 *
*  See end of file for terms of use.      *
*******************************************

-----------------REVISION HISTORY-----------------
 v1.0.0 - Original Version

}}


CON

  ascii_0 = 48 
  ascii_9 = 57 

  ascii_a = 97
  ascii_z = 97+25

  ascii__A = 65
  ascii__Z = 65+25

PUB IsAlpha(c): rtn

  If((c=>ascii_a)AND(c=<ascii_z))OR((c=>ascii__A)AND(c=<ascii__Z))
    rtn := 1
  Else
    rtn := 0

PUB IsUpper(c): rtn

  If((c=>ascii__A)AND(c=<ascii__Z))
    rtn := 1
  Else
    rtn := 0

PUB IsDigit(c): rtn

  If((c=>ascii_0)AND(c=<ascii_9))
    rtn := 1
  Else
    rtn := 0

PUB ToUpper(c): rtn

  If((c=>"a")AND(c=<"z"))
    rtn := c - 32
  Else
    rtn := c

PUB StrToUpper(s) | nn

  Repeat nn from 0 to StrSize(@s)
    BYTE[s][nn] := ToUpper(BYTE[s][nn])


DAT

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