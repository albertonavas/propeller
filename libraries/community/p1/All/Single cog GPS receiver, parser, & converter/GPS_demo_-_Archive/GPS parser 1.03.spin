{{ ┌──────────────────────────────────────────┐ 1.03 - latitude and longitude now receive up to five decimal places                           
   │ GPS receiver and parser                  │        Message discriminator now checks the three bytes of the message type                   
   │ Author: Chris Gadd                       │        datePtr restructures a local string - prevents gibberish if no RMC message is received 
   │ Copyright (c) 2019 Chris Gadd            │        altitude, course, speed binary values are returned as value x 100
   │ See end of file for terms of use.        │        added method to return number of satellites in view
   └──────────────────────────────────────────┘      
   Reads messages from a GPS receiver, parses the message, and creates text strings from the fields
    Longitude, latitude, altitude, speed, and course are also presented as values

  To use:
    Start with IO pin and baud
    setLock before reading - this ensures that the values are all from the same reading
    checkStatus to determine if receiver is "A" ok, or "V" navigation receiver warning
    read datePtr, timePtr, latPtr, lonPtr, altPtr, crsPtr, and spdPtr as ASCII strings   (pst.str(gps.timePtr))
    read lat_val, lon_val, alt_val, spd_val, crs_val as binary                           (pst.dec(gps.spdVal))
        latitude and longitude are provided in degrees & decimal minutes * 10_000_000
          12°34.56789 = 12 x 10_000_000 + 3456789 * 10 / 6 = 12_576_130
        and also as minutes x 100_000
          12°34.56789 = 12 x 6_000_000 + 3456789 = 75_456_789
        altitude is returned in units x 100  -  12M   = 1200 | 12.345M  = 1234
        course is returned in degrees x 100  -  12°   = 1200 | 12.345°  = 1234
        speed is returned in knots x 100     -  12kts = 1200 | 12.345kts = 1234
    unLock after reading to allow the pasm routine to update the strings
    
                                   ┌────────────────────┐                                           
                                   │ ┌────────────────┐ │                                           
                                   │ │                │ │                                           
                                   │ │    CIROCOMM    │ │                                           
             Prop in    TTL_Tx Yel─┤ │                │ │                                           
             not used   TTL_Rx Blu─┤ │        ┌┐      │ │                                           
             3v3        Vcc    Red─┤ │        └┘      │ │                                           
                        Gnd    Blk─┤ │                │ │                                           
             not used  UART Tx Grn─┤ │           595K │ │                                           
             not used  UART Rx Wht─┤ └────────────────┘ │                                           
                                   └────────────────────┘                                           
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
GGA Global Positioning System Fix Data. Time, Position and fix related data for a GPS receiver
                                               
         1          2         3 4          5 6 7  8     9    10 11  12 13  14   15                                                                 
         |          |         | |          | | |  |     |    |  |    | |   |    |                                                                  
  $--GGA,hhmmss.sss,llll.lllll,a,yyyyy.yyyyy,a,x,xx,x.x,xx.x,M,xxx.x,M,x.x,xxxx*hh                                                                 
                                                                                                                                                   
  1) Time (UTC)                                                                                                                                    
  2) Latitude                                                                                                                                      
  3) N or S (North or South)                                                                                                                       
  4) Longitude                                                                                                                                     
  5) E or W (East or West)                                                                                                                         
  6) GPS Quality Indicator,                                                                                                                        
     0 - fix not available,                                                                                                                        
     1 - GPS fix,                                                                                                                                  
     2 - Differential GPS fix                                                                                                                      
  7) Number of satellites in view, 00 - 12                                                                                                         
  8) Horizontal Dilution of precision                                                                                                              
  9) Antenna Altitude above/below mean-sea-level (geoid)                                                                                           
  10) Units of antenna altitude, meters                                                                                                            
  11) Geoidal separation, the difference between the WGS-84 earth ellipsoid and mean-sea-level (geoid), "-" means mean-sea-level below ellipsoid   
  12) Units of geoidal separation, meters                                                                                                          
  13) Age of differential GPS data, time in seconds since last SC104 type 1 or 9 update, null field when DGPS is not used                          
  14) Differential reference station ID, 0000-1023                                                                                                 
  15) Checksum                                                                                                                                     
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
RMC Recommended Minimum Navigation Information

         1          2 3         4 5          6 7    8      9     10    11 12 13                  
         |          | |         | |          | |    |      |      |     | |  |                   
  $--RMC,hhmmss.sss,A,llll.lllll,a,yyyyy.yyyyy,a,x.xx,xxx.xx,xxxxxx,xxx.x,e,a*hh                 
                                                                                                 
  1) Time (UTC)                                                                                  
  2) Status, A = ok, V = Navigation receiver warning            
  3) Latitude                                                                                    
  4) N or S                                                                                      
  5) Longitude                                                                                   
  6) E or W                                                                                      
  7) Speed over ground, knots                                                                    
  8) Track made good, degrees true                                                               
  9) Date, ddmmyy                                                                                
  10) Magnetic Variation, degrees                                                                
  11) E or W                                                                                     
  12) Mode (A - Autonomous / D - Differential / E - Estimated / N - Data not valid)              
  13) Checksum                                                                                   

}}                                                                                                                                                
CON
  RMC           = 1
  GGA           = 2

  DOT_FLAG      = 1
  
VAR
  byte  status
  byte  lockID
  byte  cog

DAT                                                           '' shared registers, only updated after verifying checksum 
lat_val                 long      0                           ''  using a lock to ensure values are not read while being updated
lon_val                 long      0                           ''  and not updated while being read
alt_val                 long      0 
crs_val                 long      0 
spd_val                 long      0
sat_val                 long      0

time_str                byte      "12:34:56       ",0         ' all strings reserve 16 bytes
date_str                byte      "12/34/56       ",0       
lat_str                 byte      "89°59.99999 N  ",0
lon_str                 byte      "179°59.99999 W ",0  
alt_str                 byte      "6553.50M       ",0        
crs_str                 byte      "359.90°        ",0         
spd_str                 byte      "123.40 kts     ",0

PUB Null                                                '' Not a top level object

PUB Start(GPS_in,bitrate) | tempPtrs, sharedPtrs, lockNbr, statusPtr, okay

  bitrate := clkfreq / bitrate
  |< GPS_in
  tempPtrs := @temp_lat_val
  sharedPtrs := @lat_val
  lockNbr := lockID := locknew
  statusPtr := @status
  okay := cog := cognew(@entry, @GPS_in) + 1
  waitcnt(clkfreq / 1000 + cnt)
  return okay

PUB stop
  if cog
    cogstop(cog~ - 1)
    lockret(lockID)

PUB getStatus
  if status
    return status
  return "V"

PUB setLock | timeout, locked                           '' Set lock to prevent pasm routine from overwriting shared data
  timeout := clkfreq / 1000 + cnt                       
  repeat until (locked := (lockset(lockID) == 0)) or cnt - timeout > 0
  return locked                                         ' returns true if successful / false if already locked

PUB unLock                                              '' Unlock to allow pasm routine to update shared data
  lockclr(lockID)
      
PUB timePtr                                             '' returns the address of string containing the time "hh:mm:ss",0
  result := @time_str

PUB datePtr | strPtr                                    '' returns the address of string containing the date as "20yy/mm/dd",0
  strPtr := string("20??/??/??")                        
  bytemove(strPtr + 2,@date_str + 6,2)
  bytemove(strPtr + 5,@date_str + 3,2)
  bytemove(strPtr + 8,@date_str + 0,2)
' return @date_str                                      ' @date_str contains date as dd/mm/yy
  return strPtr                                         ' strPtr contains date as 20yy,mm,dd
  
PUB latPtr                                              '' returns the address of string containing the latitude "89°59.9999 N",0
  result := @lat_str

PUB lonPtr                                              '' returns the address of string containing the longitude "179°59.9999 W",0  
  result := @lon_str
  
PUB altPtr                                              '' returns the address of string containing the altitude "6553.5M",0           
  result := @alt_str
  
PUB crsPtr                                              '' returns the address of string containing the course "179.0°",0              
  result := @crs_str

PUB spdPtr                                              '' returns the address of string containing the speed "100.00 kts",0           
  result := @spd_str
  
PUB latVal                                              '' returns the value of latitude in degrees and decimal minutes x 1_000_000
                                                        '  12°34.5678 N = 12_576_130
  return lat_val / 600_000 * 1_000_000 + lat_val // 600_000 * 10 / 6

PUB latVal_minutes                                      '' returns the value of latitude in minutes x 100,000
  return lat_val                                        '  12°34.5678 N = 7_545_678

PUB lonVal                                              '' returns the value of latitude in degrees and decimal minutes x 1_000_000
                                                        '  123°45.6789 W = -123_761_315
  return lon_val / 600_000 * 1_000_000 + lon_val // 600_000 * 10 / 6      

PUB lonVal_minutes                                      '' returns the value of longitude in minutes x 100,000   
  return lon_val                                        '  123°45.6789 W = -74_256_789

PUB altVal                                              '' returns the value of altitude in meters x 10
  return alt_val

PUB crsVal                                              '' returns the value of course in degrees x 10
  return crs_val

PUB spdVal                                              '' returns the value of speed in knots x 100                
  return spd_val

PUB satsVal
  return sat_val
  
DAT                                                                             '' temporary registers for storing data as it is received
temp_lat_val            long      0
temp_lon_val            long      0 
temp_alt_val            long      0 
temp_crs_val            long      0 
temp_spd_val            long      0
temp_sat_val            long      0

temp_time_str           byte      "00:00:00       ",0
temp_date_str           byte      "00/00/00       ",0
temp_lat_str            byte      "00°00.00000 N  ",0
temp_lon_str            byte      "000°00.00000 W ",0
temp_alt_str            byte      "0000.00M       ",0
temp_crs_str            byte      "000.00°        ",0
temp_spd_str            byte      "000.00 kts     ",0
                        
DAT                     org
entry
                        mov       rd_ptr,par
                        rdlong    rx_mask,rd_ptr
                        add       rd_ptr,#4                    
                        rdlong    bit_delay,rd_ptr
                        add       rd_ptr,#4
                        rdlong    cog_ptr,rd_ptr                                ' read address of temp_ptrs
                        movd      :load_long_loop,#lat_val_address
                        mov       loop_counter,#6                               ' six temporary longs
:load_long_loop         mov       0-0,cog_ptr
                        add       :load_long_loop,d1
                        add       cog_ptr,#4
                        djnz      loop_counter,#:load_long_loop
                        movd      :load_string_loop,#time_address
                        mov       loop_counter,#7                               ' seven temporary strings
:load_string_loop       mov       0-0,cog_ptr
                        add       :load_string_loop,d1
                        add       cog_ptr,#16                                   ' each string reserves 16 bytes
                        djnz      loop_counter,#:load_string_loop
                        add       rd_ptr,#4
                        rdlong    shared_address,rd_ptr                         ' read address of 1st shared_register
                        add       rd_ptr,#4
                        rdbyte    lock,rd_ptr
                        add       rd_ptr,#4
                        rdword    status_address,rd_ptr
'---------------------------------------------------------------------------------------------------------------------------
Wait_for_start
                        call      #Receive_byte                                
                        cmp       UART_byte,#"$"              wz
          if_ne         jmp       #Wait_for_start
                        mov       checksum,#0
                        mov       Message,#0
                        mov       BCD_value,#0
                        movs      parse_byte,#parse_header
Main_loop
                        call      #Receive_byte
                        cmp       UART_byte,#"*"              wz
          if_e          jmp       #End                                      
                        xor       checksum,UART_byte
                        jmp       parse_byte
End
                        call      #Receive_byte                                 ' compare the calculated checksum to the
                        call      #ASCII_to_BCD                                 '  checksum in the message
                        call      #Receive_byte                                
                        call      #ASCII_to_BCD                                
                        and       BCD_value,#$FF
                        cmp       BCD_value,checksum          wz
          if_ne         jmp       #Clear_temps
Copy_temps_to_shared
:set_lock
                        lockset   lock                        wc
          if_c          jmp       #:set_lock
                        mov       rd_ptr,lat_val_address                       
                        mov       wr_ptr,shared_address                        
                        mov       loop_counter,#7 * 16 / 4 + 6                  ' copy 7 strings of 16 bytes and 6 hex values, as longs
:copy_loop
                        rdlong    temp,rd_ptr
                        add       rd_ptr,#4
                        wrlong    temp,wr_ptr
                        add       wr_ptr,#4
                        djnz      loop_counter,#:copy_loop
                        lockclr   lock
                        jmp       #Wait_for_start
Clear_temps                                                                     ' clear temporary registers in case of incomplete message
                        mov       wr_ptr,lat_val_address                       
                        mov       loop_counter,#7 * 16 / 4 + 5                 
                        mov       temp,#0
:clear_loop
                        wrlong    temp,wr_ptr
                        add       wr_ptr,#4
                        djnz      loop_counter,#:clear_loop
                        jmp       #Wait_for_start
'......................................................................................................................
parse_byte              jmp       #0-0
'......................................................................................................................
parse_header
                        movs      parse_byte,#:parse_header_loop
                        movd      :parse_header_byte,#msg_str
                        mov       byte_counter,#5
:parse_header_loop
                        cmp       UART_byte,#","              wz                
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
:parse_header_byte      mov       0-0,UART_byte
                        add       :parse_header_byte,d1
                        sub       byte_counter,#1
                        jmp       #Main_loop
:End
                        cmp       msg_str + 2,#"G"            wz
          if_e          cmp       msg_str + 3,#"G"            wz
          if_e          cmp       msg_str + 4,#"A"            wz
          if_e          mov       Message,#GGA
                        cmp       msg_str + 2,#"R"            wz
          if_e          cmp       msg_str + 3,#"M"            wz
          if_e          cmp       msg_str + 4,#"C"            wz
          if_e          mov       Message,#RMC
                        tjz       Message,#Wait_for_start                       ' Disregard message if not RMC or GGA
                        movs      parse_byte,#parse_time
                        jmp       #Main_loop
'......................................................................................................................
parse_time                                                                      ' "17:40:46",0 - received as 174046.022
                        movs      parse_byte,#:parse_time_loop
                        mov       wr_ptr,time_address              
                        mov       byte_counter,#8
:parse_time_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#6             wz
          if_ne         cmp       byte_counter,#3             wz
          if_e          mov       UART_byte,#":"
          if_e          call      #String_builder
                        jmp       #Main_loop          
:End
                        cmp       Message,#RMC                wz
          if_e          movs      parse_byte,#parse_status
          if_ne         movs      parse_byte,#parse_lat
                        jmp       #Main_loop
'......................................................................................................................
parse_status
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        wrbyte    UART_byte,status_address
                        jmp       #Main_loop
:End
                        movs      parse_byte,#parse_lat
                        jmp       #Main_loop
'......................................................................................................................
parse_lat                                                                       ' "38°36.05241 N",0 - received as 3836.05241,N
                        movs      parse_byte,#:parse_lat_loop                   ' always 2 degree digits and 2 minute digits
                        mov       wr_ptr,lat_address                            ' varying number of fractional digits       
                        mov       byte_counter,#11
:parse_lat_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       UART_byte,#"."              wz
          if_ne         call      #ASCII_to_BCD
                        cmp       byte_counter,#9             wz
          if_e          mov       UART_byte,#"°"
          if_e          call      #String_builder
          if_e          call      #BCD_to_Hex                                   ' Convert the BCD degrees into a hex value
          if_e          mov       degrees,Hex_value
                        jmp       #Main_loop
:End
:pad_value                                                                      ' Pad the BCD value with 0's if necessary    
                        cmp       byte_counter,#0             wz                '  ensures that 12°34.5678 and 12°34.567
          if_ne         mov       UART_byte,#"0"                                '  both calculate correctly
          if_ne         call      #ASCII_to_BCD
          if_ne         djnz      byte_counter,#:pad_value
                        mov       UART_byte,#" "
                        call      #String_builder
                        call      #BCD_to_Hex
                        call      #Calc_degrees                                 ' Combine degrees * 600,000 with minutes
                        movs      parse_byte,#parse_ns
                        jmp       #Main_loop
parse_ns
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        cmp       UART_byte,#"S"              wz               
          if_e          neg       degrees,degrees                               ' invert latitude if South
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        wrlong    degrees,lat_val_address
                        movs      parse_byte,#parse_lon
                        jmp       #Main_loop
'......................................................................................................................
parse_lon                                                                       ' "076°54.3021 W",0 - received as 07654.3021,W
                        movs      parse_byte,#:parse_lon_loop
                        mov       wr_ptr,lon_address
                        mov       byte_counter,#12
:parse_lon_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       UART_byte,#"."              wz
          if_ne         call      #ASCII_to_BCD                        
                        cmp       byte_counter,#9             wz
          if_e          mov       UART_byte,#"°"
          if_e          call      #String_builder
          if_e          call      #BCD_to_Hex                                   ' Convert the BCD degrees into a hex value
          if_e          mov       degrees,Hex_value
                        jmp       #Main_loop
:End
:pad_value                                                                      ' Pad the BCD value with 0's if necessary    
                        cmp       byte_counter,#0             wz                '  ensures that 12°34.5678 and 12°34.567
          if_ne         mov       UART_byte,#"0"                                '  both calculate correctly
          if_ne         call      #ASCII_to_BCD
          if_ne         djnz      byte_counter,#:pad_value
                        mov       UART_byte,#" "
                        call      #String_builder
                        call      #BCD_to_Hex
                        call      #Calc_degrees                                 ' Combine degrees * 600,000 with minutes 
                        movs      parse_byte,#parse_ew
                        jmp       #Main_loop
parse_ew
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        cmp       UART_byte,#"W"              wz
          if_e          neg       degrees,degrees                               ' invert longitude if West
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        wrlong    degrees,lon_val_address
                        cmp       Message,#RMC                wz
          if_e          movs      parse_byte,#parse_speed
          if_ne         movs      parse_byte,#parse_quality
                        jmp       #Main_loop
'......................................................................................................................
parse_speed                                                                     ' "123.12 kts",0 - received as 123.12
                        mov       wr_ptr,spd_address
                        call      #Parse_field
                        mov       UART_byte,#" "
                        call      #String_builder
                        mov       UART_byte,#"k"
                        call      #String_builder
                        mov       UART_byte,#"t"
                        call      #String_builder
                        mov       UART_byte,#"s"
                        call      #String_builder
                        mov       UART_byte,#0
                        call      #String_builder
                        wrlong    Hex_value,spd_val_address
                        movs      parse_byte,#parse_track
                        jmp       #Main_loop
'......................................................................................................................
parse_track                                                                     ' "312.12°",0 - received as 312.12
                        mov       wr_ptr,crs_address
                        call      #Parse_field
                        mov       UART_byte,#"°"
                        call      #String_builder
                        mov       UART_byte,#0
                        call      #String_builder
                        wrlong    Hex_value,crs_val_address
                        movs      parse_byte,#parse_date
                        jmp       #Main_loop
'......................................................................................................................
parse_date                                                                      ' "05/02/13",0 received as 050213
                        movs      parse_byte,#:parse_date_loop
                        mov       wr_ptr,date_address
                        mov       byte_counter,#8
:parse_date_loop        
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:end
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#6             wz
          if_ne         cmp       byte_counter,#3             wz
          if_e          mov       UART_byte,#"/"
          if_e          call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        movs      parse_byte,#parse_magvar
                        jmp       #Main_loop
'......................................................................................................................
parse_magvar
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_mag_ew
'                       jmp       #Main_loop
parse_mag_ew
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
                        jmp       #Main_loop                                    ' End of GPRMC message
'......................................................................................................................
parse_quality                                                                   ' GPGGA message branch
                        cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
          if_ne         jmp       #Main_loop
:End
                        movs      parse_byte,#parse_satellites
                        jmp       #Main_loop
'......................................................................................................................
parse_satellites
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #ASCII_to_BCD          
                        jmp       #Main_loop
:End
                        call      #BCD_to_Hex
                        wrlong    Hex_value,sat_val_address
                        movs      parse_byte,#parse_dilution
                        jmp       #Main_loop
'......................................................................................................................
parse_dilution
                        cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
          if_ne         jmp       #Main_loop
:End
                        movs      parse_byte,#parse_altitude
                        jmp       #Main_loop
'......................................................................................................................
parse_altitude                                                                  ' "6553.5M",0 - received as 6553.5,M
                        mov       wr_ptr,alt_address
                        call      #Parse_field
                        movs      parse_byte,#parse_units
                        jmp       #Main_loop
parse_units
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        rdbyte    UART_byte,alt_address
                        cmp       UART_byte,#"-"              wz
          if_e          neg       Hex_value,Hex_value
                        wrlong    Hex_value,alt_val_address
                        movs      parse_byte,#parse_geo_seperation
                        jmp       #Main_loop
'......................................................................................................................
parse_geo_seperation
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_geo_units
'                       jmp       #Main_loop
'......................................................................................................................
parse_geo_units
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_age
'                       jmp       #Main_loop
'......................................................................................................................
parse_age
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_ID
'                       jmp       #Main_loop
'......................................................................................................................
parse_ID
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
                        jmp       #Main_loop                                    ' End of GPGGA message
'==========================================================================================================================================
String_builder
                        wrbyte    UART_byte,wr_ptr
                        add       wr_ptr,#1
                        sub       byte_counter,#1
String_builder_ret      ret
'------------------------------------------------------------------------------------------------------------------------------------------
Receive_byte
                        mov       Bit_counter,#8
                        mov       Delay_counter,Bit_delay                      
                        shr       Delay_counter,#1                             
                        add       Delay_counter,Bit_delay                      
                        waitpne   Rx_mask,Rx_mask
                        add       Delay_counter,cnt                            
:loop
                        waitcnt   Delay_counter,Bit_delay
                        test      Rx_mask,ina                 wc               
                        rcr       UART_byte,#1                                 
                        djnz      Bit_counter,#:Loop                           
                        shr       UART_byte,#32 - 8                            
                        waitcnt   Delay_counter,Bit_delay                      
Receive_byte_ret        ret
'------------------------------------------------------------------------------------------------------------------------------------------
Parse_field
                        movs      parse_byte,#:Parse_field_loop
                        mov       byte_counter,#10
                        mov       frac_counter,#2
                        andn      flags,DOT_FLAG
:Parse_field_loop
                        cmp       UART_byte,#","              wz
          if_z          jmp       #:pad_value
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       UART_byte,#"."              wz
          if_z          or        flags,DOT_FLAG
          if_nz         cmp       UART_byte,"-"               wz
          if_z          jmp       #Main_loop
                        test      flags,DOT_FLAG              wz
          if_z          call      #ASCII_to_BCD
          if_nz         cmpsub    frac_counter,#1             wc
          if_c_and_nz   call      #ASCII_to_BCD
                        jmp       #Main_loop
:pad_value
                        cmp       frac_counter,#0             wz
          if_nz         mov       UART_byte,#"0"
          if_nz         call      #ASCII_to_BCD
          if_nz         djnz      frac_counter,#:pad_value
                        call      #BCD_to_hex
Parse_field_ret         ret
'------------------------------------------------------------------------------------------------------------------------------------------
ASCII_to_BCD                                                                    ' Convert up to eight characters into binary-coded decimal
                        mov       temp,UART_byte
                        cmp       temp,#"A"                   wc
          if_ae         sub       temp,#"0" + 7
          if_b          sub       temp,#"0"
                        shl       BCD_value,#4
                        or        BCD_value,temp
ASCII_to_BCD_ret        ret
'------------------------------------------------------------------------------------------------------------------------------------------
BCD_to_Hex                                                                      ' Convert up to eight binary-coded digits into Hexadecimal
                        mov       Hex_value,#00                                                                                                        
                        mov       Bit_counter,#32                               ' Count 32 bits to shift
:Outer_Loop
                        mov       Nibble_counter,#8                             ' Count 8 nibbles to rotate
                        shr       BCD_value,#1                wc
                        rcr       Hex_value,#1                
:Inner_Loop
                        rol       BCD_value,#4                                  
                        mov       temp,BCD_value                                ' Rotate high nibble into low nibble location   
                        and       temp,#$0F                                     ' Copy rotated value                            
                        cmp       temp,#05                    wc                ' Mask the low nibble                           
          if_ae         sub       BCD_value,#03                                 ' Sub three if nibble is >= 5
                        djnz      Nibble_counter,#:Inner_Loop                   ' Loop until all eight nibbles are checked
                        djnz      Bit_counter,#:Outer_Loop                      ' Loop until all 32 bits of long are shifted
                        mov       BCD_value,#0                                  ' BCD_value is cleared at end of subroutine
BCD_to_Hex_ret          ret
'------------------------------------------------------------------------------------------------------------------------------------------
Calc_degrees                                                                    ' Convert lat and lon into degrees * 6_000_000 + minutes x 100_000
                        shl       degrees,#22                                   ' 6_000_000 = 2^22 + 2^21 - 2^18 - 2^15 + 2^12 - 2^9 - 2^7
                        mov       temp,degrees                ' 2^22
                        shr       degrees,#1                                                                   
                        add       temp,degrees                ' + 2^21
                        shr       degrees,#3
                        sub       temp,degrees                ' - 2^18
                        shr       degrees,#3
                        sub       temp,degrees                ' - 2^15
                        shr       degrees,#3
                        add       temp,degrees                ' + 2^12
                        shr       degrees,#3
                        sub       temp,degrees                ' - 2^9
                        shr       degrees,#2
                        sub       temp,degrees                ' - 2^7                        
                        add       temp,Hex_value                                ' Hex_value contains minutes to five decimal places
                        mov       degrees,temp
Calc_degrees_ret        ret
'==========================================================================================================================================
d1                      long      |< 9

lat_val_address         res       1                                             ' lat_val_address through lock must remain in this order
lon_val_address         res       1        
alt_val_address         res       1        
crs_val_address         res       1        
spd_val_address         res       1
sat_val_address         res       1
time_address            res       1        
date_address            res       1        
lat_address             res       1        
lon_address             res       1        
alt_address             res       1        
crs_address             res       1        
spd_address             res       1        
shared_address          res       1        
lock                    res       1        
status_address          res       1

rd_ptr                  res       1
wr_ptr                  res       1
cog_ptr                 res       1

bit_delay               res       1
Delay_counter           res       1
Nibble_counter          res       1
Byte_counter            res       1
Loop_counter            res       1
Bit_counter             res       1
Frac_counter            res       1

Rx_mask                 res       1
UART_byte               res       1
checksum                res       1
Message                 res       1
msg_str                 res       5
flags                   res       1

BCD_value               res       1
Hex_value               res       1
degrees                 res       1
temp                    res       1

                        fit       496

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