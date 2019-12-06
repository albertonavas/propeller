{{
 in kermit dir
┌──────────────────────────────────────────┐
│ MonVarsVGA 2.2                           │
│ Author: Eric Ratliff                     │               
│ Copyright (c) 2008, 2009 Eric Ratliff    │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

object to show variables on VGA screen, leaving main program free to run fast
functions similarly to "TV_Terminal" but for VGA instead
8 variables per line
can show up to 512 signed decimal longs with commas for 1024 x 768 resolution
shows index of array in each row in a special column on the left
numbers are only repainted if they change to reduce flicker and increase update speed
requires 3 cogs in addition to whatever cog starts it

This object is intended for use in two different methods:
1. To eavesdrop on a program's long variables by giving it the address of the first of some sequential long global variables
2. To show a formatted screen of information by delibrately pushing values to an array
A mixture of method 1 & 2 is OK

Note that in Spin, byte variables inserted in midst of long variables are not sequential, they are stored somewhere else.
This object works for assembly program debugging only if the assembly program delibrately pushes values to hub memory for display.

Eric Ratliff, 2008.7.1 adapting to VGA display from video display
Eric Ratliff, 2008.10.25 adding hex display option, call this ver 1.1
Eric Ratliff, 2008.11.30 adding stop function, call this ver 1.2
Eric Ratliff, 2008.12.21 added lock to make screen clearing work without corruption, call this ver 1.3
Eric Ratliff, 2008.12.27 fixed bug about returning lock in a set state, and about not being sure lock is clear before starting to
                         use it, call this version 1.4_BB
Eric Ratliff, 2008.12.27 merge "VGA_HiresTerminal", called this ver 2.0, was published to object exchange
Eric Ratliff, 2009.1.2 move where num.init is called till before cognew call of "run", call this ver 2.1
                       also fixed some comments, expecially about locking and 'master cog'
Eric Ratliff, 2009.1.2 enable calling object to separately start a monitor cog so it can do more than just monitror variables, call this ver 2.2
Eric Ratliff, 2009.1.9 add constants to reveal formatting used in "UHexStart"
Eric Ratliff, 2009.1.24 renamed "StartPrep" routine to "VGA_OnlyStart" and improved comments describing it
Eric Ratliff, 2009.2.7 added line coloring methods, added return of string length to NULL terminated string routines
Eric Ratliff, 2009.3.12 special version with BB_BB_BB_BB as the 'neutral value'
Eric Ratliff, 2009.5.3 got rid of duplicate constant definitions
Eric Ratliff, 2009.5.31 identified dummy argument as such, instead of removing it

}}
CON
  DevBoardVGABasePin = 16 ' the base pin in the Development Board
  cols = VGA#cols               ' horiontal character count available on screen
  rows = VGA#rows               ' vertical character count available on screen
  chrs = cols * rows            ' total character spaces available on screen
  Ascii0 = 48
  AsciiA = 65
  Ascii_ = 95

  CharsPerNumber = 14           ' this depends on formatting we use in "ShowNumber", using the longest case
  CharsForRowLeader = 3
  VarsPerRow = (cols-CharsForRowLeader)/CharsPerNumber  ' how mny numbers will fit in one row
  RowsPerBand = 4               ' how many rows in each shade band
  LeftoverCharsPerRow = cols-(VarsPerRow*CharsPerNumber) ' how many extra spaces remain on a line
  MaxVars = VarsPerRow * rows   ' total variables we can display
  NumBytesInLongLog = 2         ' quantity of bytes in a long as power of 2
  RemainderMask = (1 << NumBytesInLongLog)-1                          ' one less than the number of bytes in a long
  UnlikelyValue = $FEDC         ' to fill old values array so that first pass will see all variables as changed
  NeutralValue = $bbbbbbbb      ' value that will look pristine on screen when seen in right bytes of partially used long
  ' unsigned hexidecimal format definition constants we use. these allow external calls to sumulate "UHexStart"
  uhexFormat = Num#HEX9         
  uhexSignness = false

OBJ
  Num   : "Numbers"             ' string manipulations
  VGA   : "VGA_Hires_Text"      ' computer monitor display

VAR
  'byte VGACogStatus  ' results of trying to start the VGA display cog
  'screen buffer - using bytes because I don't plan to do any scrolling
  byte  screen[cols*rows]
  'row colors
  word  colors[rows]
  'cursor control bytes
  byte  cx0, cy0, cm0, cx1, cy1, cm1
  byte FormatBuffer[20]         ' place to build numeric strings in

  'long IncTime_C     ' how often we will look for changed numbers in order to repaint them (clocks)
  byte VarMonCogCode  ' ID of started cog, -1 code shows failure to start
  long Stack[75]      ' space for new cog, 53 fails, 54 seems to work
  long sync           ' gets signal for vertical refresh sync
  long LastValues[cols/14 * rows]                       ' previous values of displayed variables, maximim possible needed size
  long TheFormat      ' how to show number
  long Signed         ' are numbers signed?
  long StopFlag       ' post a non zero value to get cogs to stop
  byte ScreenIsBlanked ' flag to show screen blanking is complete

PRI dec_formattad(VariableValue, FormatCode, ColumnIndex,RowIndex)| NumericString
'' create and show the string showing signed decimal value of long
'' NOT safe to use with mulitple cogs writing to screen without locking
  NumericString := Num.ToStr(VariableValue, FormatCode)
  ' copy number over existing characters in display
  str(NumericString,ColumnIndex,RowIndex)

PRI uhex(VariableValue,SeperatorInterval,ColumnIndex,RowIndex)| Nibble, NibbleIndex, CharIndex, AsciiOffset, BunchCount
'' create and show the string showing unsigned hex value of long
'' NOT safe to use with mulitple cogs writing to screen without locking
  BunchCount := 0
  CharIndex := 0                ' where we are in writing formatted characters
  repeat NibbleIndex from 0 to 7                        ' from high order nibble at 0 to low order nibble at 7
    ' shift right to eliminate lower order bits, mask to get rid of higher order bits
    Nibble := (VariableValue >> (28 - (NibbleIndex << 2))) & $F ' get 4 bits of current character to display
    if Nibble > 9
      AsciiOffset := AsciiA - 10
    else
      AsciiOffset := Ascii0

    FormatBuffer[CharIndex] := Nibble + AsciiOffset
    'FormatBuffer[CharIndex] := AsciiOffset
    CharIndex++

    ' see if we are at a seperator place and put one in if needed, except at end
    BunchCount++
    if (BunchCount == SeperatorInterval) and (NibbleIndex <> 7)
      BunchCount := 0
      FormatBuffer[CharIndex] := Ascii_
      CharIndex++
    
  FormatBuffer[CharIndex+1] := 0                        ' null terminate the string
  str(@FormatBuffer,ColumnIndex,RowIndex)

PRI str(string_ptr,ColumnIndex,RowIndex):StringLength|DisplayIndex ' Print a zero-terminated string
' copy a null terminated string to the display array
' find place in display array from row and column indicies
  ' partial range limiting
  ColumnIndex := ColumnIndex <# cols
  RowIndex := RowIndex <# rows
  ' 2D to 1D
  DisplayIndex := ColumnIndex + (RowIndex * cols)
  StringLength := strsize(string_ptr)
  repeat StringLength
    screen[DisplayIndex++] := byte[string_ptr++]

PUB Start(VGABasePin,pVariables,Quantity)
'' start a monitor cog, showing signed decimal numbers
  'TheFormat := Num#DSDEC14
  'Signed := true
  return PlainStart(VGABasePin,pVariables,Quantity,Num#DSDEC14,true)

PUB SHexStart(VGABasePin,pVariables,Quantity)
'' start a monitor cog, showing signed hex numbers
  'TheFormat := Num#HEX9
  'Signed := true
  return PlainStart(VGABasePin,pVariables,Quantity,Num#HEX9,true)

PUB UHexStart(VGABasePin,pVariables,Quantity)
'' start a monitor cog, showing unsigned hex numbers
  'TheFormat := Num#HEX9
  'Signed := false
  return PlainStart(VGABasePin,pVariables,Quantity,uhexFormat,uhexSignness)

PUB PreBlankVariables(pMonArray,StartIndex,EndIndex)
'' prevents paint of numbers, note, on restart some numbers may already be in display array
  LONGFILL(pMonArray+(StartIndex << NumBytesInLongLog),UnlikelyValue,EndIndex-StartIndex+1)     ' set variables that are monitored to the 'unlikely value'
  LONGFILL(@LastValues+(StartIndex << NumBytesInLongLog),UnlikelyValue,EndIndex-StartIndex+1)    ' set comparison variables to the 'unlikely value'

PUB LiveBlankScreen(StartIndex,EndIndex)|NumberIndex
'' blanks displayed numbers without changing saved or current values
  ' blank every number in specified range
  repeat NumberIndex from StartIndex to EndIndex
    BlankNumber(NumberIndex)    ' blank this number

PUB LiveString(pString,ColumnIndex,RowIndex):StringLength|NumberIndex,StartCnt,TimedOut
  '' for annotating the screen with text without messing up continuous numeric refreshing
  '' see if startup blanking of whole screen is complete yet
  StartCnt := cnt
  TimedOut := false
  repeat until ScreenIsBlanked or TimedOut            ' wait for initial screen blanking to finish
    if cnt-StartCnt > (clkfreq >>3)
      TimedOut := true
  if not TimedOut
    StringLength := str(pString,ColumnIndex,RowIndex)

PRI BlankNumber(VariableIndex)|ColumnIndex,RowIndex
' fill area in screen used by a particular monitored variable with spaces
  FindXY(VariableIndex,@ColumnIndex,@RowIndex)          ' see where number begins based on it's long index
  str(STRING("              "),ColumnIndex,RowIndex) ' string length should match "CharsPerNumber"

PRI FindXY(VariableIndex,pX,pY)
  ' figure the postion (it may be much more efficient to increment and reset these, unless most numbers never change)
  LONG[pY] := VariableIndex / VarsPerRow
  LONG[pX] := CharsForRowLeader + ((VariableIndex // VarsPerRow)*CharsPerNumber)

PRI PlainStart(VGABasePin,pVariables,Quantity,Format,SignedNess):Okay|PrepWorked, MonitorWorked
  PrepWorked := VGA_OnlyStart(VGABasePin,pVariables,Quantity,Format,SignedNess)
  if PrepWorked
    ' start a monitor cog
    VarMonCogCode := cognew(Run(VGABasePin,pVariables,Quantity),@Stack) + 1
    if VarMonCogCode            ' did we get a cog for variable monitoring?
      Okay := true
    else
      stop
      Okay := false
  else
    Okay := false

PUB VGA_OnlyStart(VGABasePin,pVariables,Quantity,Format,SignedNess)|VarIndex,pString,VGACogStatus,ScreenIndex, RowNumberString, RowIndex
'' start VGA driver and prepare for vairble monitoring
'' public calls to this routine also need to be followed by the starting of a variable monitoring cog with
'' looped call to "MonitorVariables" if they want live variable update, otherwise call "MonitorVariables" every time variable display needs updating
  TheFormat := Format
  Signed := SignedNess
  stop ' stop any running VGA and variable monitor cogs
  ' is quantity > fittable on screen?
    ' refuse to start, returning false
    
  ' fill old values array with unlikely value so that all variables are painted on first pass
  VarIndex := 0
  repeat Quantity
    LastValues[VarIndex] := UnlikelyValue
    VarIndex++
  
  ' fill screen with spaces
  ScreenIndex := 0
  repeat chrs
    screen[ScreenIndex++] := 32

  ' enumerate index of first variable in each row
  VarIndex := 0
  RowIndex := 0
  repeat rows
    RowNumberString := Num.ToStr(VarIndex,Num#SDEC4)
    str(RowNumberString+1,0,RowIndex)                   ' the +1 clips off the leading space/- character which is not needed
    VarIndex += VarsPerRow
    RowIndex++
  ScreenIsBlanked := true                               ' set flag to show that painting to screen will not be over written

  Num.Init                      ' start the string manipulation object, does not consume a cog

  ' start a mew cog for variable monitoring and retain it's ID or failure code
  'VarMonCogCode := cognew(Run(VGABasePin,pVariables,Quantity{,@StopFlag}),@Stack) + 1

  RowIndex := 0
  ' make dark light banding of 4 rows each to allow easy following of numbers along a line by eye
  repeat rows
    if ((RowIndex/RowsPerBand)//2) == 0
      colors[RowIndex++] := %%0000_2220
    else
      colors[RowIndex++] := %%1110_2220
  'set cursor 0
  'cm0 := %001 ' solid block
  cm0 := %000 ' no cursor
  'set cursor 1 to be a blinking underscore
  cm1 := %111

  VGACogStatus := VGA.Start(VGABasePin,@screen, @colors, @cx0, @sync) ' start VGA driver object with specified base pin, uses two cogs
  ' did we get a cog for the continuous variable monitor and the two cogs needed for the VGA driver?
  if VGACogStatus
    return true
  else  ' stop any launched COG and return false
    stop
    return false

PUB RedLine(RowIndex)
'' sets foreground color of a line to 75% red
'' also hides index number at start of line
  if RowIndex => 0 and RowIndex < rows
    LiveString(STRING("   "),0,RowIndex)                ' hide index so that only values on line jump out to eye in color
    RowForegroundColor(RowIndex,2,0,0)

PUB RowForegroundColor(RowIndex,Red,Green,Blue)
'' sets foreground color of a line
'' components may be 0 to 3
  if RowIndex => 0 and RowIndex < rows
    ' shift argumemts to base 4 position
    BYTE[@colors + RowIndex << 1] := Red << 6 + Green << 4 + Blue << 2

PUB RowBackgroundColor(RowIndex,Red,Green,Blue)
'' sets background color of a line
'' components may be 0 to 3
  if RowIndex => 0 and RowIndex < rows
    ' shift argumemts to base 4 position
    BYTE[@colors + RowIndex << 1 + 1] := Red << 6 + Green << 4 + Blue << 2

PUB Stop                        '' to stop monitor cog and text display cogs
  ScreenIsBlanked := false      ' screen will need to be blanked before we can place labels, or they will get blanked after placement
  
  VGA.stop                      ' stop any VGA cogs that were started calls child, which then calls grandchild
  if VarMonCogCode              ' is there a cog already running?
    cogstop(VarMonCogCode-1)    ' place the variable monitor cog in dormant state
    VarMonCogCode := 0

PRI Run(VGABasePin,pVariables,QtyToShow)
' routine that formats and outputs the variable values to the screen when they change

  'IncTime_C := clkfreq/20
  
  repeat
    MonitorVariables(VGABasePin,pVariables,QtyToShow)
    'waitcnt(IncTime_C + cnt) 'wait a little while, for no good reason I recall

PUB MonitorVariables(DummyArgument,pVariables,QtyToShow)|VarIndex, ThisValue
'' scan all varibles for changes and update to screen
'' public calls to this routine should be preceeded with call to "StartPrep"
' keeping the dummy argument just because I don't want to re-code a lot of callers 2009.5.31
  if ScreenIsBlanked            ' simple test to see if "StartPrep" was called
    VarIndex := 0
    repeat QtyToShow
      ThisValue := LONG[pVariables+(VarIndex << NumBytesInLongLog)]     ' get current value from array into simple variable
      ' has variable value changed?
      if LastValues[VarIndex] <> ThisValue
        ' update saved value
        LastValues[VarIndex] := ThisValue
        ' paint the new number to the screen
        ShowNumber(VarIndex,ThisValue)
      VarIndex++

PUB GetStack:pStack
'' crazy way to allow external objects that start their own monitoring cogs to use the otherwise wasted stack space of this object
  pStack := @Stack
  
PRI ShowNumber(VariableIndex,VariableValue)| RowIndex, ColumnIndex
  ' figure the postion (it may be much more efficient to increment and reset these, unless most numbers never change)
  'RowIndex := VariableIndex / VarsPerRow
  'ColumnIndex := CharsForRowLeader + ((VariableIndex // VarsPerRow)*CharsPerNumber)
  FindXY(VariableIndex,@ColumnIndex,@RowIndex)
  if Signed
    ' copy string to display array
    dec_formattad(VariableValue,TheFormat,ColumnIndex,RowIndex)
  else
    uhex(VariableValue,2,ColumnIndex+1,RowIndex)

' the folowing routines were brought in from formerly separate object "HexDisplayAccessory"
'' the following routines are intended for use with unsigned hex displays, to help showing binary strings and indifidual bytes

PUB PutByte(pVariablesBase,ByteIndex,TheByte)
'' to place one byte into variable array, does NOT check to see if this is new to a long
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' ByteIndex is index, sequential left to right & top to bottom, of where we want a byte to show on the screen
'' TheByte is the value to show
''          finishes top row first, then wraps to left of next row below all the way to the bottom
  ' place byte at
  BYTE[pVariablesBase + ((ByteIndex >> NumBytesInLongLog) << NumBytesInLongLog) + (RemainderMask - (ByteIndex & RemainderMask))] := TheByte

PUB SafePutByte(pVariablesBase,DisplaySize,ByteIndex,TheByte)
'' to place one byte into variable array, does NOT check to see if this is new to a long
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' DisplaySize is how many longs are in the display array
'' ByteIndex is index, sequential left to right & top to bottom, of where we want a byte to show on the screen
'' TheByte is the value to show
''           finishes top row first, then wraps to left of next row below all the way to the bottom
  if (ByteIndex < (DisplaySize << NumBytesInLongLog)) and ByteIndex => 0
    ' place the byte
    PutByte(pVariablesBase,ByteIndex,TheByte)

PUB SafePutLong(pVariablesBase,DisplaySizeLong,LongIndex,TheLong)
'' to place one long in variable array, does index range checking
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' DisplaySize is how many longs are in the display array
'' LongIndex is index, sequential left to right & top to bottom, of where we want a long to show on the screen
'' TheLong is the value to show
''           finishes top row first, then wraps to left of next row below all the way to the bottom
  if (LongIndex < DisplaySizeLong) and LongIndex => 0
    ' place the long
    LONG[pVariablesBase][LongIndex] := TheLong

PUB SafePutFrontierByte(pVariablesBase,DisplaySizeLong,ByteIndex,TheByte)
'' to place one byte in variable array, checks to see if this is new to a long
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' DisplaySize is how many longs are in the display array
'' ByteIndex is index, sequential left to right & top to bottom, of where we want a byte to show on the screen
'' TheByte is the value to show
''           finishes top row first, then wraps to left of next row below all the way to the bottom
  if (ByteIndex < (DisplaySizeLong << NumBytesInLongLog)) and ByteIndex => 0
    ' put neutral value in long if this is the first (leftmost as seen on display) byte used in the currrent long value
    NeutralizeIfLeftByte(pVariablesBase,ByteIndex)
    ' place the byte
    PutByte(pVariablesBase,ByteIndex,TheByte)

PRI NeutralizeIfLeftByte(pVariablesBase,ByteIndex)
' prior to placing one byte in the variable array in area that may have 'unlikely value' filling, replaces unlikely value with 0 if this is the high order byte
' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
' ByteIndex is byte index, sequential left to right & top to bottom, of where we want a byte to show on the screen
  ' is the position at the left of the long on the screen?
  if (ByteIndex & RemainderMask) == 0
    ' impending byte write will be at most significant byte, but we write a long to the address of the least significant byte, filling all bytes
    LONG[pVariablesBase][ByteIndex >> NumBytesInLongLog] := NeutralValue
    
PRI NeutralizeIfNotRightByte(pVariablesBase,ByteIndex)
' prior to placing one byte in the variable array in area that may have 'unlikely value' filling, replaces unlikely value with 0 if this is NOT the low order byte
' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
' ByteIndex is byte index, sequential left to right & top to bottom, of where we want a byte to show on the screen
  ' is the position at the left of the long on the screen?
  if (ByteIndex & RemainderMask) <> RemainderMask
    ' impending byte write will be at most significant byte, but we write a long to the address of the least significant byte, filling all bytes
    LONG[pVariablesBase][ByteIndex >> NumBytesInLongLog] := NeutralValue
    
PRI PutMeasuredString(pVariablesBase,StartingDisplayIndex,pString,StrLen)| DisplayIndex, MaxDisplayIndex, StringIndex
' places string of bytes in variable array, does NOT check index limits
' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
' StartingDisplayIndex is index, sequential left to right & top to bottom, of where we want string on the screen
' pString is the address of the string to copy, need not be long aligned
' StrLen is the byte count in the string, note that string need not be null terminated
  if StrLen > 0 ' is there any string at all?
    MaxDisplayIndex := StartingDisplayIndex + StrLen - 1
    StringIndex := 0
    ' copy every byte from source to destination
    repeat DisplayIndex from StartingDisplayIndex to MaxDisplayIndex
      PutByte(pVariablesBase,DisplayIndex,BYTE[pString + StringIndex])
      StringIndex++

PRI LimitByteIndex(DisplaySizeLong,ByteIndex)
' limit index of byte to safe range, for variables or display characters
  ByteIndex #>= 0                                                               ' zero is the minimum index                                                              
  ByteIndex <#= (DisplaySizeLong << NumBytesInLongLog)-1                        ' one less than number of bytes is maximum index
  return ByteIndex

PRI LimitStringIndicies(DisplaySizeLong,pByteIndex,pStrLen,ppString)|OriginalStart,OriginalEnd,OriginalLength,LimitedStart,LimitedEnd,LimitedStringLength,LeftTruncation
' truncate string into visible range of bytes
  ' save original requested beginning and end of string
  OriginalStart := LONG[pByteIndex]
  OriginalLength := LONG[pStrLen]
  OriginalEnd := OriginalStart + OriginalLength - 1
  
  ' clip ends to fit monitor
  LimitedStart := LimitByteIndex(DisplaySizeLong,OriginalStart)
  LimitedEnd := LimitByteIndex(DisplaySizeLong,OriginalEnd)
  
  ' is left truncation equal or greater than string length?
  LeftTruncation := LimitedStart - OriginalStart
  if LeftTruncation => OriginalLength
    LONG[pStrLen] := 0
    ' new start place is meaningless, zero length strings don't get shown, so don't bother to report it
    return
  else
    LONG[ppString] += LeftTruncation

  ' is right truncation equal of greater than string length?
  if (OriginalEnd - LimitedEnd) => OriginalLength
    LONG[pStrLen] := 0
    ' new start place is meaningless, zero length strings don't get shown, so don't bother to report it
    return

  ' report new start place
  LONG[pByteIndex] := LimitedStart
  ' report new string length, not allowing negative lengths        
  LONG[pStrLen] := (LimitedEnd - LimitedStart + 1) #> 0

PUB SafePutMeasuredString(pVariablesBase,DisplaySizeLong,ByteIndex,pString,StrLen)
'' places string of bytes into variable array, checks index limits
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' DisplaySizeLong is how many longs are in the display array
'' ByteIndex sequential left to right & top to bottom, of where we want string on the screen
'' pString is the address of the string to copy, need not be long aligned
'' StrLen is the byte count in the string, note that string need not be null terminated
  ' limit byte count to what fits on screen
  LimitStringIndicies(DisplaySizeLong,@ByteIndex,StrLen,@pString)
  ' put limited string on the screen
  PutMeasuredString(pVariablesBase,ByteIndex,pString,StrLen)

PUB SafePutMeasuredFrontierString(pVariablesBase,DisplaySizeLong,ByteIndex,pString,StrLen)|LastIndex,LastLongFirstIndex
'' places string of bytes into variable array, clearing 'unlikely value' numbers to neutral zeros as it goes, checks index limits
'' does NOT neutralize any bytes to the left of the beginning of the string
'' pVariablesBase is the pointer to the first byte of the displayed array, must be long aligned, i.e. a multiple of 4
'' DisplaySize is how many longs are in the display array
'' ByteIndex is byte index, sequential left to right & top to bottom, of where we want string on the screen
'' pString is the address of the string to copy, need not be long aligned
'' StrLen is the byte count in the string, note that string need not be null terminated
  ' limit byte count to what fits on screen
  LimitStringIndicies(DisplaySizeLong,@ByteIndex,@StrLen,@pString)

  ' padd extra bytes of last long with 'neutral values', to avoid seeing the 'unlikely values' used to blank refresh
  ' find last index of string
  LastIndex := ByteIndex + StrLen - 1
  ' find beginning index of long that end of string is in
  LastLongFirstIndex := (LastIndex >> NumBytesInLongLog) << NumBytesInLongLog
  ' does string start at of before first index of last long?
  if ByteIndex =< LastLongFirstIndex
    ' we may want to neutralize the last long's values
    ' is the last long to be used only partially used?
    NeutralizeIfNotRightByte(pVariablesBase,LastIndex)
    
  ' put limited string on the screen
  PutMeasuredString(pVariablesBase,ByteIndex,pString,StrLen)
  
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
