{{┌──────────────────────────────────────────┐│ KermitConsoleDefs 1.0                    ││ constants for Kermit file receiving and  ││ debugging objects                        ││ Author: Eric Ratliff                     │               │ Copyright (c) 2009 Eric Ratliff          │               │ See end of file for terms of use.        │                └──────────────────────────────────────────┘KermitConsole.spin, Kermit file receiver objectby Eric Ratliff2009.5.25 new version from "KermitReceiverDefs.spin", now for console/serial driver opject & specialized debugger          redefines an error code enumeration}}CON{  ' receiver interface structure definition  ' this structure lets the receiver be a Spin only or an Assembly based object  ' "find" means input to receiver, "put" means output to receiver  KR_pDebugStruct        = 0    ' where in structure to find pointer to debug structure  'KR_pFileDataBuffer     = 1    ' where in structure to find pointer to circular file data buffer  'KR_FileDataBufferSizeL = 2    ' where in structure to find size of the file data buffer  'KR_FileDataBeginStatus = 3    ' where in structure to find the word size indicies of the circular file data buffer                                ' tail: oldest char in buffer, the least significant word                                ' head: where next will appear, the most significant word  KR_pFileNameBuffer     = 4    ' where in structure to find pointer to file name buffer  KR_FileNameBufferSizeB = 5    ' where in structure to find size of the file name buffer (longs){ KR_CallerObjectHS      = 6    ' where in structure to find handshake between caller & object        ' enumeration, Hand Shake (for caller to object)        KR_HS_ReceiveFailure= -3 ' code for process failed        KR_HS_ACKofAbort   = -2 ' code for ACK of caller aborting the process        KR_HS_DoNotRecieve = -1 ' code for don't look for files, or request of abort        KR_HS_SerialOnly   = 0  ' code for start serial driver if needed, and don't consume serial data        KR_HS_GetFileAttr  = 1  ' code for permission to get init, file name, and attributes        KR_HS_GotFileAttr  = 2  ' code for file name and size received        KR_HS_GetFile      = 3  ' code for permission to get any file sent}       KR_HS_GotFile      = 4  ' code for file receipt complete  KR_DeclaredFileLength  = 8    ' where in structure to put file size, is declared file size, which is later checked against measured file size        KRFLC_NoFileLength = -1 ' file length code, no file length known  'KR_RxPin               = 9    ' where in structure to find IO number for serial receive  'KR_TxPin               = 10   ' where in structure to find IO number for serial transmit  'KR_SerialMode          = 11   ' where in structure to find IO number for serial receive  'KR_baud                = 12   ' where in structure to find IO number for serial transmit  'KR_pSerialDriverStruct = 13   ' where in structure to put pointer to serial driver structure, pointer to sequential longs of the driver        ' pointer/enumeration, Serial Driver structure pointer/code        'KR_SD_NoSerialDriver = 0 ' this code must not be a valid hub address, this means assembly cog of serial driver is not started yet  KR_Size = 15                  ' size of the receiver interface structure (longs)  'NoDataInFileBuffer = -1}  NoFileLength = -1 ' file length code, no file length known  ' debug structure definition, offsets into contiguous longs  ' "find" means input to debugger, "put" means output to debugger  'KDB_LengthCheckFlag    = 0  KDB_PacketInputIndex    = 1   ' where in structure to put measured packet string lenght less 1  KDB_DeclPacketLength    = 2   ' where in structure to put string length implied by the declared remaining packet length  KDB_ExtrSequenceNumber  = 3   ' coded for the 'extracted' sequence number, as opposed to the 'expected' one  KDB_ExtractedChecksum   = 4   ' declared packet checksum to test against                    KDB_CalculatedChecksum  = 5   ' from sum calculated from received characters of a packet  KDB_InputStatusFlags    = 6   ' return value being passed to caller, shows if we have Kermit or Command going, etc.  KDB_PakType             = 7   ' ascii letters that are part of Kermit protocol definition, some shown in DAT section of tested receiver object  KDB_PacketErrorCode     = 8   ' see "packet error codes" below for code values  KDB_FileState           = 9   ' global that has state of file process  KDB_ParseState          = 10  ' global that has state of parse process  KDB_pPacket             = 11  ' where in structure to put pointer to packet contents  KDB_pFileOutput         = 12  ' where in structure to put pointer to packet contents  KDB_KR_VersionNumber    = 13  ' where in structure to put version number of Kermit receiver, steps of 100 decimal would indicate different object  'KDB_pArrayBase    = 14  ' where in structure to find pointer to some longs for arbitrary posting, which is also the base of the variable display array  KDB_MeasuredFileLength  = 15  ' where in structure to put measured file length  KDB_TrySerialMonitor    = 16  ' flag to show we want to try to launch a serial monitor cog if there is debugging        ' enumeration, Try Serial Monitor        KDB_TSM_DontTry     = 0        KDB_TSM_DoTry       = 1        'KDB_TSM_Failed      = 2        'KDB_TSM_Succeeded   = 3  KDB_ClearBeforeShowing  = 17  ' flag to explicitly cause clearing of input, file, and packet display  'KDB_DebuggerGetsFileData = 18  ' flag to explicitly cause clearing of input, file, and packet display  KDB_DebuggerStarted = 19 ' flag to show that debugger has started  KDB_ShowPacketResults = 20 ' copy of flag to incidate need to refresh debug display  KDB_ShowInput = 21 ' copy of flag to incidate need to refresh debug display  KDB_FileDataCount = 22 ' copy of count of output bytes to display  KDB_Size                = 23  ' size of the debug interface structure (longs)  ' debugger start result codes  'DebuggerNotStarted = 0  'NoSerialBufMonitor = 1  'DebuggerFullyStarted = 2  ' packet error codes  PEC_KermitPacketReady         = 0 ' successful parse of packet is complete  PEC_KermitPacketTimeout       = 1 ' got no characters while waiting for a packet  PEC_BadPacketStart            = 2 ' got other than MARK when looking for beginning of a packet  PEC_BadPacketLength           = 3 ' extracted packet length is out of Kermit limits  PEC_BadEOL                    = 4 ' got unexpected end of line character  PEC_ChecksumMismatch          = 5 ' packet had inconsistent checksum  PEC_WrongPacketSequence       = 6 ' packet had unexpected sequence number  PEC_MissingCharsInPacket      = 7 ' timeout but last character is the EOL character  'PEC_KeepProcessingNow         = 8 ' internal state code for parse routine  'PEC_WaitingForInput           = 9 ' state code for parse routing, means to call again later to see if there is more input in serial input buffer  PEC_InProcess                 = 8 ' need additional calls to finish parse  PEC_WaitingForInput           = 9 ' state code for parse routing, means to call again later to see if there is more input in serial input buffer  ErrorCodeRange                = 10 ' should be one higher than highest magnitude error code  'PEC_ProcessMoreNextCall      = 11 ' out of the range becuase it is never supposed to be a final code  ' definitions of fields & constants in Kermit (may be removing more from "KermitReceiver.Spin"  MARK = 1                      ' character that begins a Kermit packet  ' Kermit packet types  PT_SendInitiate_type = $53       ' Send Initiatetype, S  PT_ACK_type = $59                ' ACK type, Y  PT_NAK_type = $4E                ' NAK type, N  PT_Error_type = $45              ' Error type, E  PT_FileHeader_type = $46         ' File Header type, F  PT_FileAttributes_type = $41     ' File Atributes type, A  PT_Data_type = $44               ' Data type, D  PT_EndOfFile_type = $5A          ' End of file type, Z  PT_BreakTransmission_type = $42  ' Break Transmission type, B  ' attribute packet tags  KAPT_Length = $31             ' file length in bytes tag'VAR'  long ReceiveStructure[KR_Size]                        ' structure used for starting a Kermit Receive objectPUB DoNothing{PUB Init(pDebug,pFileDataBuffer,FileDataBufferSize,pFileNameBuffer,FileNameBufferSizeL,StartupMode,rxPin,txPin,SerialMode,baud,TrySerialMonitor,DebuggerConsumesFileData):pReceive  ReceiveStructure[KR_pDebugStruct] := pDebug  'ReceiveStructure[KR_pFileDataBuffer] := pFileDataBuffer  'ReceiveStructure[KR_FileDataBufferSizeL] := FileDataBufferSize  ReceiveStructure[KR_pFileNameBuffer] := pFileNameBuffer  ReceiveStructure[KR_FileNameBufferSizeB] := FileNameBufferSizeL  ReceiveStructure[KR_DeclaredFileLength] := KRFLC_NoFileLength  ReceiveStructure[KR_CallerObjectHS] := StartupMode                              ReceiveStructure[KR_RxPin] := rxPin  ReceiveStructure[KR_TxPin] := txPin  ReceiveStructure[KR_SerialMode] := SerialMode  ReceiveStructure[KR_baud] := baud  ReceiveStructure[KR_pSerialDriverStruct] := KR_SD_NoSerialDriver  if pDebug   ' is there a debug structure?    LONG[pDebug][KDB_TrySerialMonitor] := TrySerialMonitor    LONG[pDebug][KDB_PostRunFlag] := false    LONG[pDebug][KDB_ClearBeforeShowing] := false    LONG[pDebug][KDB_DebuggerGetsFileData] := DebuggerConsumesFileData  pReceive := @ReceiveStructure                         ' tell caller where to find the sufficiently sized, initialized structure}{{┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐│                                                   TERMS OF USE: MIT License                                                  │                                                            ├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ │files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    ││modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software││is furnished to do so, subject to the following conditions:                                                                   ││                                                                                                                              ││The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.││                                                                                                                              ││THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          ││WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         ││COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   ││ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}}