{{────────────────────────────────────────────────────────────────────────────
File: "Piezospeaker.spin"

Under Construction.  
────────────────────────────────────────────────────────────────────────────}}

OBJ

  sw  : "Square Wave"                    ' Import square wave cog object


PUB beep(pin, freq, dur) 

  sw.start(@pin)
  repeat until dur == 0
  sw.stop