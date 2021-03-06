{{
*******************************************************
* - MixingBoard3.1.spin                               *
* - Program to Read a Potientiometer utilizing        *
*   an RC time circuit & FullDuplexSerial.spin object *
* - Author: Larry W. Schoolcraft                      *
*                                                     *
*******************************************************
 * You will need the components to build the circuit below as well as the-->
   Parallax 2x16 Serial LCD Display.
 * You will also need eight extra LEDs unless you are using the P8X32A QuickStart-->
   Development Board.
 * As of this point the Propeller is unable to Send or recieve MIDI Data, 
   do to I have not figured out how to send or recieve MIDI Data on the device.
 * It does however give an incrementing/decrementing digital Value to a potientiometer.
 * The follwing circuit is the RC Time circuit where 8 branches of RC circuits are-->
   designed to increase/decrease the RC time constant as you turn VR1(potientiometer). 
 * Leave one pin of VR1 Disconnected so that you get the Full range of resistance(0 to -->
   50K ohms).
 * The resistances in the eight I/O pin branches are a combination of series & parallel-->
   resistors; the capacitor C2 is two 0.1uF capacitors in parallel with each other.
 * To the right of the branches, I have listed the the combinations needed to achieve-->
   the resistances shown on each branch of the schematic diagram.
 * "+" means the resistors are in series; "||" means the resistors are in parallel with-->
   each other; connect them exactly as listed. 
                            R1
 3.3V Toggled ─────┳────────────┐
      I/O pin1      │       10     │
                    │ LED1         │
                    └───┐        │
                          │         VR1
                      R10  1K   ───────┐   R2    
                          │        50K    ┣────────── I/O pin 2    [1 (220K) || 1 (22K)] 
                    Pin38                │   11k
                                          │
                                          │   R3     C2
                                          ┣───────────── I/O pin 3  [1 (220K) || 1 (22K)] 
                                          │   11K   0.2uF              *** 2  0.1uF capacitors in Parallel
                                          │
                                          │   R4     C3
                                          ┣───────────── I/O pin 4  [1 (10K) + 1 (470)]
                                          │ 10.47K  0.22uF
                                          │
                                          │   R5     C4
                                          ┣───────────── I/O pin 5  [1 (10K) + 1 (270)]
                                          │ 10.27K   1uF
                                          │
                                          │   R6     C5
                                          ┣───────────── I/O pin 6  [1 (10K) || 1 (1M)]
                                          │   9.9K   2.2uF
                                          │
                                          │   R7     C6
                                          ┣───────────── I/O pin 7  [1 (10K) || 2 (1M)]
                                          │   9.8K   4.7uF
                                          │
                                          │   R8     C7
                                          ┣───────────── I/O pin 8  [1 (10K) || 3 (1M)] 
                                          │   9.71K   6.8uF
                                          │
                                          │   R9     C8
                                          ┣───────────── I/O pin 9  [1 (2.2K) + 1 (2.2K)]
                                          │   4.4K   68uf
                                          │
                                       C1 0.1uF
                                          │
                                          │
                                    Pin   
                                     38

}}        

CON

    _clkmode  =  xtal1  + pll2x
    _xinfreq  =  5_000_000
        power  = 1
     circuit0  = 2
     circuit1  = 3
     circuit2  = 4
     circuit3  = 5
     circuit4  = 6
     circuit5  = 7
     circuit6  = 8
     circuit7  = 9
      TX_Pin2  = 10   'Ignore this pin for now
   output_pin0 = 16
   output_pin1 = 17
   output_pin2 = 18
   output_pin3 = 19
   output_pin4 = 20
   output_pin5 = 21
   output_pin6 = 22
   output_pin7 = 23
               
        TX_Pin = 0      'Connect this pin to the LCD Display
        Baud1   = 19_200
        Baud2   = 32_500
VAR

 byte   Delay
 byte   Velocity      {{Variable which is the MIDI data expression for Volume(Value of the potientiometer)}}
 byte   Status        {{The following Variables are MIDI expressions to communicate - }} 
 byte   Action        {{- Bytes of Data that are sent before the Velocity Value}}
 byte   Channel
 byte   Control_Number
 
OBJ

  LCD  :  "FullDuplexSerial.spin"
PUB Main

    dira[power]~~           {{ Sets I/O Pin 1 to input}}
    dira[output_pin0]~~     {{ Sets LED Pin 16 to output}}
    dira[output_pin1]~~     {{ Sets LED Pin 17 to output}}
    dira[output_pin2]~~     {{ Sets LED Pin 18 to output}}
    dira[output_pin3]~~     {{ Sets LED Pin 19 to output}}
    dira[output_pin4]~~     {{ Sets LED Pin 20 to output}}
    dira[output_pin5]~~     {{ Sets LED Pin 21 to output}}
    dira[output_pin6]~~     {{ Sets LED Pin 22 to output}}
    dira[output_pin7]~~     {{ Sets LED Pin 23 to output}}
    dira[circuit0]~         {{ Sets I/O Pin 2 to input}} 
    dira[circuit1]~         {{ Sets I/O Pin 3 to input}}
    dira[circuit2]~         {{ Sets I/O Pin 4 to input}}
    dira[circuit3]~         {{ Sets I/O Pin 5 to input}}
    dira[circuit4]~         {{ Sets I/O Pin 6 to input}}
    dira[circuit5]~         {{ Sets I/O Pin 7 to input}}
    dira[circuit6]~         {{ Sets I/O Pin 8 to input}}
    dira[circuit7]~         {{ Sets I/O Pin 9 to input}}
    
    Delay:= clkfreq/10_000   ' Variable assignment
    
    repeat                   ' Repeat loop
    
      waitcnt(clkfreq/10_000 + cnt)  'Clock delay
      !outa[power]               'Sets  I/O pin 1 to toggle on/off  along with clock delay
      
      if ina[circuit0]== 1      {{ The following 8 statements are basically saying that if-->}}
        outa[output_pin0]:= 1   {{ --> the 8 different RC time branches of the above-->}}
      else                      {{ --> circuit are on or off, then the corresponding LEDs-->}}
        outa[output_pin0]:= 0   {{ --> are on/off along with the branches.}}
        
      if ina[circuit1] == 1
        outa[output_pin1]:= 1
      else
        outa[output_pin1]:= 0
        
      if ina[circuit2] == 1
        outa[output_pin2]:= 1
      else
        outa[output_pin2]:= 0
        
      if ina[circuit3] == 1
        outa[output_pin3]:= 1
      else
        outa[output_pin3]:= 0

      if ina[circuit4] == 1
        outa[output_pin4]:= 1
      else
        outa[output_pin4]:= 0
        
      if ina[circuit5] == 1
        outa[output_pin5]:= 1
      else
        outa[output_pin5]:= 0
        
      if ina[circuit6] == 1
        outa[output_pin6]:= 1
      else
        outa[output_pin6]:= 0

      if ina[circuit7] == 1
        outa[output_pin7]:= 1
      else
        outa[output_pin7]:= 0

      {{ Before the next statement the all output pins are toggling in phase, on all the time,-->}}
      {{ --> or out of phase with I/O pin 1 (power pin).}}
      {{ The next statement says that if the RC time branches of the circuit are all on or -->}}
      {{ --> off at the same time the Velocity(Potientiomer Value) has a value from 0 to 127. }}
      {{ The "& outa[power]~~" portion of the statement below sets the power pin to always --> }}
      {{ --> be on and supply constant power the circuit.}}
      {{ --> I stumbled onto this by accident and it actually is what makes the circuit work.-->}}
      {{ --> If you delete all sections below and just run the above portion of the object-->}}
      {{ --> you will find that with the potientiometer turned all the way down, all of the-->}}
      {{ --> LEDs blink at the same time and are blinking in phase with the power pin...-->}}
      {{ --> As you gradually turn the potientiometer up, each LED will go from blinking in-->}}
      {{ --> phase, to being on all the time, then to blinking out of phase with the power-->}}
      {{ --> pin. this continues until all LEDs are blinking out of phase with the power-->}}
      {{ --> pin. I thought that this could give me an eight bit digital representation of-->}}
      {{ --> the pot value. When I added the statement below, I was trying to create sixteen-->}}
      {{ --> statements to tell the processor that if certain branches were on or off, and they--> }}
      {{ --> were in phase or out of phase, then the LEDs would represent a binary number.-->}}
      {{ I could then assign a variable expression to repersent that number.}}
      {{ What would actually happen is that the number on the serial LCD display would blink-->}}
      {{ --> between 0 and the numerical weight of whatever LED was blinking out of phase at-->}}
      {{ --> that time.}}
      {{ I decided to try one statement at a time and after the follwing statement, I noticed-->}}
      {{ --> that all of the LEDs would light up one after another as I turned the potientiometer.}}
      {{ However, becuase each LED stays lit when you reach a higher value, you can only get-->}}
      {{ --> eight values, but it does work.}}
              
      if ina[circuit7..circuit0]== %11111111 or ina[circuit7..circuit0]== %00000000 & outa[power]~~
       
        Velocity<#= 127      'Limits the highest Velocity value to 127.
        Velocity #>= 0       'Limits the lowest Velocity value to 0.

       {{ The following 8 statements assign a binary Velocity value to each of the-->}}
       {{ -->8 LEDs.}}
       {{ They then run the different objects that control the serial LCD display -->}}
       {{ --> utilizing the FullDuplexSerial.spin object that operates the LCD display-->}}
       {{ --> and at some point will send the MIDI Data from the Potientiometer to my-->}}
       {{ --> Cakewalk recording software, once I figure out how to do so.}}
       
      if outa[output_pin7..output_pin0]== %00000000  
                                                     
        Velocity:= %00000000
        Run_Display
        Send_Display_Data
        Midi_TX    
      if outa[output_pin7..output_pin0]== %00000001

        Velocity:= %00000010
        Run_Display
        Send_Display_Data
        Midi_TX    
      if outa[output_pin7..output_pin0]== %00000011
        
        Velocity:= %00001000
        Run_Display
        Send_Display_Data
        Midi_TX    
      if outa[output_pin7..output_pin0]== %00000111
        
        Velocity:= %00010000
        Run_Display2
        Send_Display_Data
        Midi_TX    
      if outa[output_pin7..output_pin0]== %00001111
        
        Velocity:= %00100000
        Run_Display2
        Send_Display_Data
        Midi_TX    
      if outa[output_pin7..output_pin0]== %00011111
        
        Velocity:= %01000000
        Run_Display2
        Send_Display_Data
        Midi_TX    
         
      if outa[output_pin7..output_pin0]== %00111111
        
        Velocity:= %01011001
        Run_Display2
        Send_Display_Data   
      if outa[output_pin7..output_pin0]== %01111111
        
        Velocity:= %01101000
        Run_Display3
        Send_Display_Data
        Midi_TX     
      if outa[output_pin7..output_pin0]== %11111111
        
        Velocity:= %01111111
        Run_Display3
        Send_Display_Data
        Midi_TX    
PUB Send_Display_Data     {{ Sends the combined MIDI data (in binary) to the display.}}

    
    dira[TX_Pin2]~~
    Action:=  %1011
    Channel:= %0001
    Status:= Action or Channel
    Control_Number:= %0111
    
    
    

    LCD.start(TX_PIN, TX_PIN, %1000, 19_200)
    LCD.tx(17)                                  'Turn on Backlight for LCD Display.
    LCD.tx(22)                                  'Turn Display on with cursor off & no blink.
    LCD.tx(148)                                 'Go to Line 2 Position 0 on display
    LCD.bin(Status,4)                           'Print value of the variable Status in binary
    LCD.tx(152)                                 'Go to Line 2 Position 4 on display
    LCD.bin(Control_Number, 4)                  'Print value of the variable Control_Number in binary
    LCD.tx(156)                                 'Go to Line 2 Position 8 on display 
    LCD.bin(Velocity,8)                         'Print value of the variable Velocity in binary
    
PUB MIDI_TX              {{Sends MIDI data using I/O pin 10 to computer over USB port.}}
                         {{Ignore for now...}}

    dira[TX_Pin2]~~
    Action:=  %10110000
    Status:= Action 
    Control_Number:= %00010100

    LCD.start(TX_Pin2, TX_Pin2, %1000, 32_500) 
    LCD.bin(Status,8)
    LCD.bin(Control_Number, 8)
    LCD.bin(Velocity,8)          
PUB Run_Display         {{Sends Velocity Value(in decimal) from 0 to 9.}}

    LCD.start(TX_PIN, TX_PIN, %1000, 19_200)
    LCD.tx(17)                                  'Turn on Backlight for LCD Display.
    LCD.tx(22)                                  'Turn Display on with cursor off & no blink.
    LCD.tx(128)                                 'Go to Line 1 Position 0 on display
    LCD.str(string("Velocity="))                'Print the word "Velocity=" on display
    LCD.tx(138)                                 'Go to Line 1 Posistion 10 on display
    LCD.str(string("  "))                       'Print 2 blank spaces to erase values higher than 9
    LCD.tx(140)                                 'Go to Line 1 Posistion 12 on display
    LCD.dec(Velocity)                           'Print value of the variable Velocity

PUB Run_Display2       {{Sends Velocity Value(in decimal) from 10 to 99.}}

    LCD.start(TX_PIN, TX_PIN, %1000, 19_200)
    LCD.tx(17)                                  'Turn on Backlight for LCD Display.
    LCD.tx(22)                                  'Turn Display on with cursor off & no blink.
    LCD.tx(128)                                 'Go to Line 1 Position 0 on display 
    LCD.str(string("Velocity="))                'Print the word "Velocity=" on display
    LCD.tx(138)                                 'Go to Line 1 Posistion 10 on display
    LCD.str(string(" "))                        'Print a blank space to erase values higher than 99
    LCD.tx(139)                                 'Go to Line 1 Posistion 11 on display
    LCD.dec(Velocity)                           'Print value of the variable Velocity
    
PUB Run_Display3      {{Sends Velocity Value(in decimal) from 100 to 127.}}

    LCD.start(TX_PIN, TX_PIN, %1000, 19_200)
    LCD.tx(17)                                  'Turn on Backlight for LCD Display.
    LCD.tx(22)                                  'Turn Display on with cursor off & no blink.
    LCD.tx(128)                                 'Go to Line 1 Position 0 on display
    LCD.str(string("Velocity="))                'Print the word "Velocity=" on display
    LCD.tx(138)                                 'Go to Line 1 Posistion 9 on display 
    LCD.dec(Velocity)                           'Print value of the variable Velocity
        