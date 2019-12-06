{{ DS1302_full.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ DS1302 driver v1.3                  │ BR             │ (C)2010             │  8Jul2010     │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A full-featured DS1302 timekeeping chip driver.  Based on the original object by           │
│ Daniel Robert.                                                                             │
│                                                                                            │
│ Notes:                                                                                     │
│ •Original object here: http://obex.parallax.com/objects/89/                                │
│ •12 hour mode is not supported in this object.  The reason is that it would add            │
│  significant complexity to this object for minimal benefit.  A better solution is          │
│  to handle the 12/24 hour conversion in software outside of this object if needed.         │
│  Okay.  So it is nearly full-featured.                                                     │
│ •The DS1302 data sheet specs the maximum frequency on the clk pin as:                      │
│  0.5MHz@2V, 2MHz@5V --> 1.5MHz@3.3V (1.5 uS per clock, 120 ticks@clkfreq=80MHz)            │
│  Original object had a 2 uS pause between clock pin transitions.  However, it seems to     │
│  work fine with no wait @ clkfreq=80MHz...apparently spin can't outrun the DS1302.         │
│  Not tested at clkfreq=100MHz.                                                             │
│ •Experimented with trickle charger using 1 diode+2K resistor setting. 10µF                 │
│  electrolytic cap kept DS1302 powered up for >10 minutes. Implies a 1000µF should be good  │
│  for ~16 hrs of backup power...enough to last through a typical brown-out or black-out     │
│  (if leakage current and wide tolerance band of electrolytics doesn't kill it first)       │
│ •Note that this device needs to have a 32.768KHz crystal with 6pF capacitance in order to  │
│  keep accurate time: http://forums.parallax.com/forums/default.aspx?f=25&m=467246          │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
DEVICE PINOUT & REFERENCE CIRCUIT
                      ┌────┐               1000µF
               3.3V │      │ backup_Vin  ── to gnd
   xtal          xi │DS1302│ clk         ─── to prop pin
   32.768 KHz    xo │      │ io          ─ 1KΩ resistor to prop pin
                    ┌│      │ ce          ─── to prop pin
                GND  └──────┘      


TRICKLE CHARGER NOTES
'Trickle charger setup     tc_enable     diodeSel    resistSel
'                              |            |          |
' write(command(clock,tc,w),(%1010 << 4) + (2 << 2)+ ( 3 ))

Diode select register bits:  00 = trickle charger disabled
                             01 = 1 diode enabled
                             10 = 2 diodes connected in series (more voltage drop when in charging mode)
                             11 = trickle charger disabled

Resistor select bits:        00 = no resistor   0Ω
                             01 = R1            2KΩ
                             10 = R2            4KΩ
                             11 = R3            8KΩ

'Examples of other useful config and control commands
'write(command(clock,sec,w),read(command(clock,sec,r))&%1000_0000)      'set clock halt bit
'write(command(clock,ctrl,w),%1000_0000)                                'set write-protect bit
'write(command(clock,hr,w),read(command(clock,hr,r))&%1000_0000)        'set 12h mode

V1.1 - 27Oct09 fixed mis-labeled pins in docs (clk and io were swapped in 1.0)
V1.2 - 28Mar10 fixed bug in config method that caused seconds to be reset (thanks, Doug!)
v1.3 - 26Jun10 cleanup and additional documentation

}}
CON
'command byte options   
  #0, clock,ram
  #0, sec, mi, hr, day, mo, dow, yr, ctrl, tc, #31, burst
  #0, w,r

  
VAR
  byte clk                                   'clock
  byte io                                    'data io
  byte ce                                    'chip enable
  byte datar


PUB command(clock_or_ram, register, r_or_w)
''Returns a DS1302 command byte
''clock_or_ram : select clock or ram (allowed values: clock, ram)
''register     : register name (allowed values: 0-30, sec, mi, hr, day, mo, dow, yr, ctrl, tc, burst)
''r_or_w       : read or write (allowed values: w, r)
''Usage        : cmd:=command(rtc#ram, 21, rtc#w)        --> write to RAM byte 21
''               cmd:=command(rtc#clock, rtc#min, rtc#r) --> read minute register

  return (1<<7) + (clock_or_ram<<6) + (register<<1) + r_or_w


PUB init( inClk, inIo, inCe ) 
''Initialize propeller serial com channel with DS1302.  Call once after prop power-up.
''Usage: rtc.init(clk_pin, io_pin, chipEnable_pin)

  clk := inClk                               'save pin numbers
  io  := inIo
  ce  := inCe

  dira[ce]~~                                 'configure chip enable pin
  outa[ce]~            
  dira[clk]~~                                'configure clock pin
  outa[clk]~           
  

PUB config
''Config DS1302.  Call once after DS1302 power-up.
''Usage: rtc.config

  write(command(clock,ctrl,w),0)                                        'clear write-protect bit
  write(command(clock,sec,w),read(command(clock,sec,r)) & %0111_1111)   'clear halt bit
  write(command(clock,hr,w),read(command(clock,hr,r)) & %0111_1111)     'set 24hr mode
  write(command(clock,tc,w),0)                                          'disable trickle charger


PUB setDatetime( _mth, _day, _year, _dow, _hr, _min, _sec )
''Set date and time

  write($8c, bin2bcd( _year ) )
  write($8a, _dow )
  write($88, bin2bcd( _mth ) )
  write($86, bin2bcd( _day ) )
  write($84, bin2bcd( _hr ) )
  write($82, bin2bcd( _min ) )
  write($80, bin2bcd( _sec ) )


PUB readDate( _day, _mth, _year, _dow )
''Read current date (day, month, year, day-of-week)
''Usage: rtc.readDate( @day, @month, @year, @dow )

  byte[_year] := bcd2bin( read($8d) )
  byte[_mth] :=  bcd2bin( read($89) )
  byte[_day] :=  bcd2bin( read($87) )
  byte[_dow] :=  bcd2bin( read($8b) )

  
PUB readTime( _hr, _min, _sec ) | tmp1, tmp2
''Read current hour, minute, second
''Usage: rtc.readTime( @hour, @minute, @second )

  byte[_hr]  := bcd2bin( read($85) )
  byte[_min] := bcd2bin( read($83) )
  byte[_sec] := bcd2bin( read($81) )

  
Pub read( cmd ) | i
''Read a byte of data per command byte

  outa[ce]~~           
  writeByte( cmd )
  dira[io]~             'set to input
  readByte
  outa[ce]~            
  return(datar)


Pub write( cmd, data ) 
''Write a byte of data per cmd byte

  outa[ce]~~           
  writeByte( cmd )
  writeByte( data )
  outa[ce]~            


PUB writeN(cmd, dataPtr, n)|i
''Write a stream of n bytes from byte array pointed to by dataPtr

  outa[ce]~~           
  writeByte( cmd )
  repeat i from 0 to n
    writeByte(byte[dataPtr][i])
  outa[ce]~            
  

Pub readN(cmd, dataPtr, n)|i
''Read a stream of n bytes of data and put in byte array pointed
''to by dataPtr

  outa[ce]~~           
  writeByte( cmd )
  dira[io]~             'set to input
  repeat i from 0 to n
    readByte
    byte[dataPtr][i]:=datar
  outa[ce]~            
 

PRI readByte|i

  datar~                           
  repeat i from 0 to 7          
     if ina[io] == 1
      datar |= |< i     ' set bit
    outa[clk]~~          
    outa[clk]~           


PRI writeByte( cmd ) | i  

  dira[io]~~              'set to output 
  repeat i from 0 to 7    
    outa[io] := cmd       
    outa[clk]~~          
    cmd >>= 1
    outa[clk]~           

PRI bin2bcd(dataIn) | tmp
'Convert a byte of binary data to binary coded decimal

  tmp:= dataIn/10
  result := dataIn - ( tmp * 10 ) + ( tmp << 4 )


PRI bcd2bin(dataIn)
'Convert a byte of binary coded decimal data to binary

  result := (dataIn & %00001111) +  ((dataIn >> 4) & %00001111)*10


DAT

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}} 