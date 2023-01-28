#Include "fbgfx.bi"
OPTION BASE 0

CONST verdad = 1, falso = 0

'-----------------------------------------------------------------
'| CPU Stuff
'-----------------------------------------------------------------

CONST NTSCMode = 0

'--NTSC
'CONST CPUSpeed = 1789772
'CONST VBSec = 60
'CONST MaxY = 224
'--PAL
'CONST CPUSpeed = 1773447
'CONST VBSec = 50
'CONST MaxY = 240

'CONST NMIClockTicks = CPUSpeed / VBSec
'-----------------------------------------------------------------
'| TU Modes
'-----------------------------------------------------------------
CONST tmVal = falso, tmAddr = verdad
'-----------------------------------------------------------------
'| Vectors
'-----------------------------------------------------------------
CONST NMIVector = 65530, ResetVector = 65532, IRQVector = 65534
'-----------------------------------------------------------------
'| Registers
'-----------------------------------------------------------------
CONST PPUCtrl1 = &H2000, PPUCtrl2 = &H2001, PPUStat = &H2002, SPRAddr = &H2003
CONST SPRIO = &H2004, BgScroll = &H2005, VRAMAddr = &H2006, VRAMIO = &H2007

CONST pAPUP1C1 = &H4000, pAPUP1C2 = &H4001, pAPUP1F1 = &H4002, pAPUP1F2 = &H4003
CONST pAPUP2C1 = &H4004, pAPUP2C2 = &H4005, pAPUP2F1 = &H4006, pAPUP2F2 = &H4007
CONST pAPUTC1 = &H4008, pAPUTC2 = &H4009, pAPUTF1 = &H400A, pAPUTF2 = &H400B
CONST pAPUNC1 = &H400C, pAPUNC2 = &H400D, pAPUNF1 = &H400E, pAPUNF2 = &H400F
CONST pAPUDMCC = &H4010, pAPUDMCV = &H4011, pAPUDMCA = &H4012, pAPUDMCDL = &H4013
CONST SPRDMA = &H4014, pAPUStCh = &H4015, Joypad1 = &H4016, Joypad2 = &H4017
'-----------------------------------------------------------------
'| Addressing Modes Defines
'-----------------------------------------------------------------
CONST Imm = 1, AbsAdr = 2, Zp = 3, ImpAdr = 4, Ind = 5, Absx = 6, Absy = 7
CONST Zpx = 8, Zpy = 9, Idx = 10, Idy = 11, Rel = 12, Acc = 13, ERA = 14
'-----------------------------------------------------------------
'| Opcode Defines
'-----------------------------------------------------------------
CONST ADC = 0, ANDOp = 1, ASL = 2, BCC = 3, BCS = 4, BEQ = 5, BITe = 6, BMI = 7, BNE = 8
CONST BPL = 9, BRK = 10, BVC = 11, BVS = 12, CLC = 13, CLD = 14, CLI = 15, CLV = 16
CONST CMP = 17, CPX = 18, CPY = 19, DEC = 20, DEX = 21, DEY = 22, EOR = 23, INC = 24
CONST INX = 25, INY = 26, JMP = 27, JSR = 28, LDA = 29, LDX = 30, LDY = 31, LSR = 32
CONST NOP = 33, ORA = 34, PHA = 35, PHP = 36, PLA = 37, PLP = 38, ROL = 39, ROR = 40
CONST RTI = 41, RTS = 42, SBC = 43, SEC = 44, SED = 45, SEI = 46, STA = 47, STX = 48
CONST STY = 49, TAX = 50, TAY = 51, TSX = 52, TXA = 53, TXS = 54, TYA = 55, ERO = 56
'-----------------------------------------------------------------
'| Type Structures
'-----------------------------------------------------------------
TYPE FkSndSt
   Enabled AS Long
END TYPE

TYPE JoypadSt
   Bits(24) AS Long
   Count AS Long
   Strobe AS Long
   ZapperButtPressed AS Long
END TYPE

TYPE CCRSt
   c AS Long   'Carry
   Z AS Long   'Zero
   i AS Long   'Interrupt
   D AS Long   'Decimal
   B AS Long   'Break
   v AS Long   'oVerflow
   N AS Long   'Negative
END TYPE
'-----------------------------------------------------------------
'| Video Stuff
'-----------------------------------------------------------------
CONST frameskip = 1

DIM SHARED PPUMem(&H3FFF) AS LONG, SpriteMem(&HFF) AS Long

aaaaa = (256 * 224) '/ 2
DIM SHARED gfxarray(aaaaa) AS Long

DIM SHARED gfxshiftarray(0 TO 1, 0 TO 15) AS Long
DIM SHARED MyPal(255) AS Long
DIM SHARED font(52, 5) AS Long

DIM SHARED VBlanks AS Long
'-----------------------------------------------------------------
'| Keyboard Stuff
'-----------------------------------------------------------------
DIM SHARED KBState(256) AS Long
'-----------------------------------------------------------------
'| Variable/Type structure dimming
'-----------------------------------------------------------------
DIM SHARED MainMem1(&H3FFF) AS LONG, MainMem2(&H3FFF) AS Long
DIM SHARED MainMem3(&H3FFF) AS LONG, MainMem4(&H3FFF) AS Long
Dim Shared DefSeg As Long ' ni idea si va a funcionar

DIM SHARED PulseChan(0 TO 1) AS FkSndSt, TriChan AS FkSndSt
DIM SHARED NoiseChan AS FkSndSt, PCMChan AS FkSndSt

DIM SHARED LineRate AS LONG, LineTotal AS LONG, ScanLine AS Long
DIM SHARED VBScanLine AS LONG, MaxScanLine AS LONG, MHBValue AS Long
DIM SHARED LineTicks AS SINGLE, LineTickCount AS SINGLE, CPUSpeed AS SINGLE
DIM SHARED VBlanking AS LONG, MHBUsing AS Long 'Bool
DIM SHARED VBCount AS LONG, VBSec AS LONG, NMIClockticks AS LONG
DIM SHARED LineTickCountInt AS LONG

DIM SHARED currkey AS STRING
DIM SHARED a AS LONG, X AS LONG, Y AS Long, SP AS LONG, PC AS LONG
DIM SHARED p AS Long, col As long
DIM SHARED Clockticks AS LONG, TU AS LONG, TU2 AS Long
DIM SHARED CCR AS CCRSt, Joypad(1) AS JoypadSt

DIM SHARED rotl(15, 255) AS LONG, rotr(15, 255) AS Long

DIM SHARED Addressmode(255) AS LONG, instruc(255) AS Long
DIM SHARED ticks(255) AS LONG, bytes(255) AS Long, Mn(55) AS STRING

DIM SHARED VRAMAddrHigh AS LONG, VRAMAddress AS LONG, VRAMAddrUsing AS Long
DIM SHARED SPRAddress AS Long
DIM SHARED BgScrollX AS LONG, BgScrollY AS LONG, BgScrollUsing AS Long

DIM SHARED MapperNum AS LONG, SRAMEnabled AS LONG, ROMTrainer AS Long
DIM SHARED NMIonVblank AS LONG, NMIonSprHit AS LONG, SSize AS Long
DIM SHARED BkPTA AS LONG, sppta AS LONG, PPUAdrI AS Long
DIM SHARED NTabAdr AS Long
DIM SHARED SprVis AS LONG, BgVis AS LONG, SprClip AS Long
DIM SHARED BGClip AS LONG, DispType AS Long
DIM SHARED VBlankOcc AS LONG, Spr0Occ AS LONG, ScLnSprCnt AS Long
DIM SHARED VFirstRead AS LONG, SFirstRead AS Long
DIM SHARED VRAMWrFlg AS Long
DIM SHARED PRGPages AS LONG, CHRPages AS LONG, MirrorMethod AS Long

DIM SHARED opcodet AS Long
DIM SHARED tmp AS LONG, tmpbyte AS Long, tmplbyte AS LONG
DIM SHARED tmpshortint AS Long

DIM SHARED CPURunning AS LONG, TUMode AS Long

DIM SHARED DebugTrace AS Long

DIM SHARED DirFiles(1 TO 700) AS STRING, FileCount AS LONG, filename AS STRING, topnum AS Long

DIM TmpStuff AS STRING

' *************************************************************************
' *************************************************************************

DECLARE SUB disptxt (Xt, Yt, text$)
DECLARE SUB drawbacktilebasic (Xn AS LONG, Yn AS LONG, colup AS Long, address AS LONG)
DECLARE SUB drawspritebasic (Xn AS LONG, Yn AS LONG, colup AS LONG, address AS LONG, hflip AS LONG, vflip AS Long)
DECLARE SUB ModeQPset (Xt, Yt, col as long)
DECLARE SUB ModeQPSetArr (Xt, Yt, col as long)
DECLARE SUB psetbig (Xt, Yt, col as long)
'Keyboard
'DECLARE SUB initkbd ALIAS "installisr" (BYVAL arrayseg, BYVAL arrayofs)
'DECLARE SUB deinitkbd ALIAS "removeisr" ()
'Mode Q
DECLARE SUB ModeQDrawArray ()
DECLARE SUB ModeQInit ()
'Font
DECLARE SUB LoadFont ()
'FileOpen Dialog
Declare SUB LoadFile ()
'Other
DECLARE SUB DrawScreen ()
DECLARE SUB JoypadSetStrobe (jp AS LONG, ss AS Long)
DECLARE SUB Addrmode (adrmode AS Long)
DECLARE SUB exec6502 ()
DECLARE SUB SetCCR (mf AS Long)
DECLARE SUB Execop (inst AS Long)
DECLARE SUB irq6502 ()
DECLARE SUB MemoryTUEquals (ta AS Long)
DECLARE SUB checkacc (tc AS Long)
DECLARE FUNCTION TUVal ()
DECLARE FUNCTION MemoryTUGet ()
DECLARE SUB nmi6502 ()
DECLARE SUB VBlank ()
DECLARE SUB Reset6502 ()
DECLARE SUB ReadInfoArrays ()
DECLARE FUNCTION JoypadGet (jp AS Long)
DECLARE FUNCTION GetCCR ()
DECLARE FUNCTION MemGet (Addr AS LONG)
DECLARE SUB MemSet (Addr AS LONG, ValSet AS Long)

'-----------------------------------------------------------------
'| Start of program!
'-----------------------------------------------------------------

ReadInfoArrays

LoadFile

ModeQInit

'initkbd VARSEG(KBState(0)), VARPTR(KBState(0))

DebugTrace = 0'verdad
                  
CPURunning = verdad
WHILE CPURunning = verdad
   While Clockticks > 0
      opcodet = MemGet(PC)
      Addrmode (Addressmode(opcodet))
      PC = PC + bytes(opcodet)
      Execop (instruc(opcodet))
      Clockticks = Clockticks - ticks(opcodet)
   Wend
   'exec6502()
   VBlank
WEND

'deinitkbd
Print "Fin????"
Sleep:END


'-----------------------------------------------------------------
'| Data for the information arrays!
'-----------------------------------------------------------------
'AddressingMode
DATA 4,10,14,14,14,3,3,14,4,1,13,14,14,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14
DATA 2,10,14,14,3,3,3,14,4,1,13,14,2,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14
DATA 4,10,14,14,14,3,3,14,4,1,13,14,2,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14
DATA 4,10,14,14,14,3,3,14,4,1,13,14,5,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14
DATA 14,10,14,14,3,3,3,14,4,1,4,14,2,2,2,14
DATA 12,11,14,14,8,8,9,14,4,7,4,14,14,6,14,14
DATA 1,10,1,14,3,3,3,14,4,1,4,14,2,2,2,14
DATA 12,11,14,14,8,8,9,14,4,7,4,14,6,6,7,14
DATA 1,10,14,14,3,3,3,14,4,1,4,14,2,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14
DATA 1,10,14,14,3,3,3,14,4,1,4,14,2,2,2,14
DATA 12,11,14,14,14,8,8,14,4,7,14,14,14,6,6,14

'Instruc
DATA 10,34,56,56,56,34,2,56,36,34,2,56,56,34,2,56
DATA 9,34,56,56,56,34,2,56,13,34,56,56,56,34,2,56
DATA 28,1,56,56,6,1,39,56,38,1,39,56,6,1,39,56
DATA 7,1,56,56,56,1,39,56,44,1,56,56,56,1,39,56
DATA 41,23,56,56,56,23,32,56,35,23,32,56,27,23,32,56
DATA 11,23,56,56,56,23,32,56,15,23,56,56,56,23,32,56
DATA 42,0,56,56,56,0,40,56,37,0,40,56,27,0,40,56
DATA 12,0,56,56,56,0,40,56,46,0,56,56,56,0,40,56
DATA 56,47,56,56,49,47,48,56,22,47,53,56,49,47,48,56
DATA 3,47,56,56,49,47,48,56,55,47,54,56,56,47,56,56
DATA 31,29,30,56,31,29,30,56,51,29,50,56,31,29,30,56
DATA 4,29,56,56,31,29,30,56,16,29,52,56,31,29,30,56
DATA 19,17,56,56,19,17,20,56,26,17,21,56,19,17,20,56
DATA 8,17,56,56,56,17,20,56,14,17,56,56,56,17,20,56
DATA 18,43,56,56,18,43,24,56,25,43,33,56,18,43,24,56
DATA 5,43,56,56,56,43,24,56,45,43,56,56,56,43,24,56

'Ticks
DATA 7,6,0,0,0,3,5,0,3,2,2,0,0,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0
DATA 6,6,0,0,3,3,5,0,4,2,2,0,4,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0
DATA 6,6,0,0,0,3,5,0,3,2,2,0,3,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0
DATA 6,6,0,0,0,3,5,0,4,2,2,0,5,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0
DATA 0,6,0,0,3,3,3,0,2,2,2,0,4,4,4,0
DATA 3,5,0,0,4,4,4,0,2,4,2,0,0,4,0,0
DATA 2,6,2,0,3,3,3,0,2,2,2,0,4,4,4,0
DATA 3,5,0,0,4,4,4,0,2,4,2,0,4,4,4,0
DATA 2,6,0,0,3,3,5,0,2,2,2,0,4,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0
DATA 2,6,0,0,3,3,5,0,2,2,2,0,4,4,6,0
DATA 3,5,0,0,0,4,6,0,2,4,0,0,0,4,7,0

'Bytes
DATA 1,2,1,1,1,2,2,1,1,2,1,1,1,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1
DATA 3,2,1,1,2,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1
DATA 1,2,1,1,1,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1
DATA 1,2,1,1,1,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1
DATA 1,2,1,1,2,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,2,2,2,1,1,3,1,1,1,3,1,1
DATA 2,2,2,1,2,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,2,2,2,1,1,3,1,1,3,3,3,1
DATA 2,2,1,1,2,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1
DATA 2,2,1,1,2,2,2,1,1,2,1,1,3,3,3,1
DATA 2,2,1,1,1,2,2,1,1,3,1,1,1,3,3,1

'My Palette

'0=Black, 1=Blue, 2=Green, 3=Cyan, 4=Red, 5=Magenta, 6=Brown, 7=White, 8=Grey
'9=LtBlue, 10=LtGreen, 11=LtCyan, 12=LtRed, 13=LtMagenta, 14=Yellow, 15=LtWhite
mypalette:
DATA 8,1,1,1,5,5,4,6,2,2,2,2,1,0,0,0
DATA 8,3,1,1,5,5,4,4,14,2,2,2,3,0,0,0
DATA 15,11,9,5,13,5,5,12,14,14,10,10,11,0,0,0
DATA 15,11,8,13,13,13,12,12,14,14,10,10,11,8,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

'Mnemonics
DATA "ADC","AND","ASL","BCC","BCS","BEQ","BIT","BMI","BNE","BPL","BRK","BVC"
DATA "BVS","CLC","CLD","CLI","CLV","CMP","CPX","CPY","DEC","DEX","DEY","EOR"
DATA "INC","INX","INY","JMP","JSR","LDA","LDX","LDY","LSR","NOP","ORA","PHA"
DATA "PHP","PLA","PLP","ROL","ROR","RTI","RTS","SBC","SEC","SED","SEI","STA"
DATA "STX","STY","TAX","TAY","TSX","TXA","TXS","TYA"

'Real Palette
pal:
DATA &h7F,&h7F,&h7F,&hFF,&h00,&h00,&hBF,&h00,&h00,&hBF,&h2B,&h47
DATA &h87,&h00,&h97,&h23,&h00,&hAB,&h00,&h13,&hAB,&h00,&h17,&h8B
DATA &h00,&h30,&h53,&h00,&h78,&h00,&h00,&h6B,&h00,&h00,&h5B,&h00
DATA &h58,&h43,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &hBF,&hBF,&hBF,&hF8,&h78,&h00,&hF8,&h58,&h00,&hFF,&h47,&h6B
DATA &hCD,&h00,&hDB,&h5B,&h00,&hE7,&h00,&h38,&hF8,&h13,&h5F,&hE7
DATA &h00,&h7F,&hAF,&h00,&hB8,&h00,&h00,&hAB,&h00,&h47,&hAB,&h00
DATA &h8B,&h8B,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &hF8,&hF8,&hF8,&hFF,&hBF,&h3F,&hFF,&h88,&h6B,&hF8,&h78,&h98
DATA &hF8,&h78,&hF8,&h98,&h58,&hF8,&h58,&h78,&hF8,&h47,&hA3,&hFF
DATA &h00,&hB8,&hF8,&h18,&hF8,&hB8,&h57,&hDB,&h5B,&h98,&hF8,&h58
DATA &hDB,&hEB,&h00,&h78,&h78,&h78,&h00,&h00,&h00,&h00,&h00,&h00
DATA &hFF,&hFF,&hFF,&hFF,&hE7,&hA7,&hF8,&hB8,&hB8,&hF8,&hB8,&hD8
DATA &hF8,&hB8,&hF8,&hC3,&hA7,&hFB,&hB0,&hD0,&hF0,&hAB,&hE3,&hFF
DATA &h7B,&hDB,&hFB,&h78,&hF8,&hD8,&hB8,&hF8,&hB8,&hD8,&hF8,&hB8
DATA &hFF,&hFF,&h00,&hF8,&hD8,&hF8,&h00,&h00,&h00,&h00,&h00,&h00

DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00

DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00

DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00,&h00
DATA &h00,&h00,&h00,&h00,&h00,&hff,&h00,&hff,&h00,&hff,&h00,&h00
 

'Screenshot Header Data
scrnshot:
DATA &h42, &h4D, &h36, &hF4, 00, 00, 00, 00, 00, 00, &h36, 04, 00, 00, &h28, 00
DATA 00, 00, 00, 01, 00, 00, &hE0, 00, 00, 00, 01, 00, 08, 00, 00, 00
DATA 00, 00, 00, &hE0, 00, 00, &h12, &h0B, 00, 00, &h12, &h0B, 00, 00, 00, 01
DATA 00, 00, 00, 01, 00, 00
'-----------------------------------------------------------------

Sub Addrmode (adrmode AS Long)

SELECT CASE adrmode
   CASE ImpAdr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Imm
      TU = MemGet(PC + 1)
      TUMode = tmVal
      IF DebugTrace = falso THEN EXIT SUB
   CASE Rel
      TU2 = MemGet(PC + 1)
      IF TU2 AND &H80 THEN TU2 = TU2 - 256
      IF DebugTrace = falso THEN EXIT SUB
   CASE AbsAdr
      TU = rotl(8, MemGet(PC + 2)) + MemGet(PC + 1)
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Zp
      TU = MemGet(PC + 1)
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Absx
      TU = rotl(8, MemGet(PC + 2)) + MemGet(PC + 1) + X
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Acc
      TU = 65536
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Zpx
      TU = MemGet(PC + 1) + X
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Ind
      TU = rotl(8, MemGet(PC + 2)) + MemGet(PC + 1)
      TU = rotl(8, MemGet(TU + 1)) + MemGet(TU)
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Absy
      TU = rotl(8, MemGet(PC + 2)) + MemGet(PC + 1) + Y
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Zpy
      TU = MemGet(PC + 1) + Y
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Idx
      TU = MemGet(PC + 1) + X
      TU = rotl(8, MemGet(TU + 1)) + MemGet(TU)
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB
   CASE Idy
      TU = MemGet(PC + 1)
      TU = rotl(8, MemGet(TU + 1)) + MemGet(TU) + Y
      TUMode = tmAddr
      IF DebugTrace = falso THEN EXIT SUB

   CASE ERA
      PRINT "Illegal!  Clockticks: "; Clockticks, "PC: "; HEX$(PC), "Opcode: "; HEX$(MemGet(PC))
      CPURunning = falso
      Sleep:end

END SELECT

'EXIT SUB
         
IF Multikey(SC_s) THEN DebugTrace = falso: EXIT SUB 
Locate 25,1

DIM PCAS AS STRING * 8, TBAS AS STRING * 2, NBAS AS STRING * 2, NB2AS AS STRING * 2, TIAS AS STRING * 3
PCAS = STRING$(4 - LEN(HEX$(PC)), "0") + HEX$(PC)
TBAS = STRING$(2 - LEN(HEX$(MemGet(PC))), "0") + HEX$(MemGet(PC))
NBAS = STRING$(2 - LEN(HEX$(MemGet(PC + 1))), "0") + HEX$(MemGet(PC + 1))
NB2AS = STRING$(2 - LEN(HEX$(MemGet(PC + 2))), "0") + HEX$(MemGet(PC + 2))
TIAS = Mn(instruc(MemGet(PC)))

SELECT CASE adrmode
   CASE Imm
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " #$"; NBAS ;"     "
   CASE AbsAdr
      PRINT PCAS; TBAS; NBAS; NB2AS; "    "; TIAS; " $"; NB2AS; NBAS ;"     "
   CASE Zp
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " $00"; NBAS ;"     "
   CASE ImpAdr
      PRINT PCAS; TBAS; "        "; TIAS;"     "
   CASE Ind
      PRINT PCAS; TBAS; NBAS; NB2AS; "    "; TIAS; " ($"; NB2AS; NBAS; ")";"     "
   CASE Absx
      PRINT PCAS; TBAS; NBAS; NB2AS; "    "; TIAS; " $"; NB2AS; NBAS; ", X";"     "
   CASE Absy
      PRINT PCAS; TBAS; NBAS; NB2AS; "    "; TIAS; " $"; NB2AS; NBAS; ", Y";"     "
   CASE Zpx
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " $00"; NBAS; ", X";"     "
   CASE Zpy
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " $00"; NBAS; ", Y";"     "
   CASE Idx
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " ($"; NBAS; ", X)";"     "
   CASE Idy
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " ($"; NBAS; "), Y";"     "
   CASE Rel
      PRINT PCAS; TBAS; NBAS; "      "; TIAS; " ";
      IF MemGet(PC + 1) AND &H80 THEN PRINT "-";
      PRINT "$"; HEX$(ABS(TU2))     ;"     "
   CASE Acc
      PRINT PCAS; TBAS; "        "; TIAS; " A";"     "
END SELECT

END SUB

DEFINT C, R
SUB disptxt (Xt, Yt, text$)
	'Shell ("echo"+" 2")'text$+xt+yt
	Exit Sub
DIM h AS LONG, o AS Long
FOR o = 1 TO LEN(text$)
   IF ASC(MID$(text$, o, 1)) > 96 AND ASC(MID$(text$, o, 1)) < 123 THEN
      hus = ASC(MID$(text$, o, 1)) - 97
      GOTO rita
   END IF
   IF ASC(MID$(text$, o, 1)) > 48 AND ASC(MID$(text$, o, 1)) < 58 THEN
      hus = ASC(MID$(text$, o, 1)) - 20
      GOTO rita
   END IF
   SELECT CASE MID$(text$, o, 1)
      CASE "Ü": hus = 26
      CASE "Ñ": hus = 27
      CASE "î": hus = 28
      CASE "0": hus = 38
      CASE "(": hus = 39
      CASE ")": hus = 40
      CASE "$": hus = 41
      CASE ",": hus = 42
      CASE "+": hus = 43
      CASE "-": hus = 44
      CASE "*": hus = 45
      CASE "/": hus = 46
      CASE "=": hus = 47
      CASE ":": hus = 48
      CASE ".": hus = 49
      CASE "!": hus = 50
      CASE "?": hus = 51
      CASE "#": hus = 52
      CASE " "
         FOR i = 0 TO 6
            ModeQPset CINT(Xt), CINT(Yt + i), 0
            ModeQPset CINT(Xt + 1), CINT(Yt + i), 0
         NEXT i
         Xt = Xt + 2
         GOTO mellanmjoelk
   END SELECT
rita:
   FOR h = 0 TO 5
      IF font(hus, h) = 0 THEN
         FOR i = 0 TO 6
            ModeQPset CINT(Xt), CINT(Yt + i), 0
         NEXT i
         Xt = Xt + 1: EXIT FOR
      END IF
      IF (font(hus, h) AND 1) THEN ModeQPset CINT(Xt), CINT(Yt), 253 ELSE ModeQPset CINT(Xt), CINT(Yt), 0
      IF (font(hus, h) AND 2) THEN ModeQPset CINT(Xt), Yt + 1, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 1), 0
      IF (font(hus, h) AND 4) THEN ModeQPset CINT(Xt), Yt + 2, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 2), 0
      IF (font(hus, h) AND 8) THEN ModeQPset CINT(Xt), Yt + 3, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 3), 0
      IF (font(hus, h) AND 16) THEN ModeQPset CINT(Xt), Yt + 4, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 4), 0
      IF (font(hus, h) AND 32) THEN ModeQPset CINT(Xt), Yt + 5, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 5), 0
      IF (font(hus, h) AND 64) THEN ModeQPset CINT(Xt), Yt + 6, 253 ELSE ModeQPset CINT(Xt), CINT(Yt + 6), 0
      Xt = Xt + 1
   NEXT h
mellanmjoelk:
NEXT o

END SUB

DEFSNG C, R
SUB drawbacktilebasic (Xn AS LONG, Yn AS LONG, colup AS Long, address AS LONG)

DIM h AS LONG, i AS LONG, tpi AS Long
DIM Xn2 AS LONG, Yn2 AS LONG, addressnew AS Long

IF BGClip = falso AND Xn < 8 THEN EXIT SUB

Xn2 = Xn + 7
Yn2 = Yn

colup = rotl(2, colup) OR &H3F00

addressnew = address + BkPTA

FOR i = 0 TO 7
   FOR h = 0 TO 7
      tmpshortint = rotl(h, 1)

      IF (PPUMem(addressnew + i) AND tmpshortint) > 0 THEN
         IF (PPUMem(addressnew + 8 + i) AND tmpshortint) > 0 THEN
            psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 3)
         ELSE
            psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 1)
         END IF
      ELSE
         IF (PPUMem(addressnew + 8 + i) AND tmpshortint) > 0 THEN
            psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 2)
         END IF
      END IF
   NEXT h
NEXT i

END SUB

SUB DrawScreen

iF VBlanks MOD frameskip > 0 THEN EXIT SUB

DIM ColBk AS Long
DIM tpx AS LONG, tpy AS LONG, tpx2 AS LONG, tpy2 AS Long
DIM SPR AS Long
DIM address AS Long
DIM yr AS LONG, xr AS LONG, xx AS LONG, yy AS Long

'DEF SEG = VARSEG(gfxarray(0))
'For i& = 0 TO 57343: POKE i&, PPUMem(&H3F00): NEXT i&
For i& = 0 TO 57343:  gfxarray(i&)= PPUMem(&H3F00): NEXT i&

IF SprVis > 0 Then
   FOR SPR = 252 TO 0 STEP -4
      IF (SpriteMem(SPR + 2) AND &H20) = &H20 THEN
         IF SSize = verdad THEN
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR), SpriteMem(SPR + 2) AND &H3, rotl(10, SpriteMem(SPR + 1) AND 1) + rotl(4, SpriteMem(SPR + 1)), SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR) + 8, SpriteMem(SPR + 2) AND &H3, rotl(10, SpriteMem(SPR + 1) AND 1) + rotl(4, SpriteMem(SPR + 1)) + 16, SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
         ELSE
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR), SpriteMem(SPR + 2) AND &H3, sppta + rotl(4, SpriteMem(SPR + 1)), SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
         END IF
      END IF
   NEXT SPR
END IF

IF BgVis > 0 THEN
   FOR yr = 0 TO 7
      tpy = rotl(5, yr)
      FOR xr = 0 TO 7
         tpx = rotl(5, xr)
         ColBk = PPUMem(NTabAdr + &H3C0 + rotl(3, yr) + xr)
         FOR xx = 0 TO 3
            FOR yy = 0 TO 3
               tpy2 = rotl(3, yy)
               tmp = rotl(1, rotr(1, xx AND 2) + (yy AND 2))
               tmpbyte = rotr(tmp, ColBk AND rotl(tmp, 3))
               tmplbyte = rotl(4, PPUMem(NTabAdr + (rotl(2, tpy) + rotl(2, tpy2)) + (rotr(3, tpx) + xx)))
               drawbacktilebasic tpx + rotl(3, xx), tpy + tpy2, tmpbyte, tmplbyte
            NEXT yy
         NEXT xx
      NEXT xr
   NEXT yr
END IF

IF SprVis > 0 THEN
   FOR SPR = 252 TO 0 STEP -4
      IF (SpriteMem(SPR + 2) AND &H20) = 0 THEN
         IF SSize = verdad THEN
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR), SpriteMem(SPR + 2) AND &H3, rotl(10, SpriteMem(SPR + 1) AND 1) + rotl(4, SpriteMem(SPR + 1)), SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR) + 8, SpriteMem(SPR + 2) AND &H3, rotl(10, SpriteMem(SPR + 1) AND 1) + rotl(4, SpriteMem(SPR + 1)) + 16, SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
         ELSE
            drawspritebasic SpriteMem(SPR + 3), SpriteMem(SPR), SpriteMem(SPR + 2) AND &H3, sppta + rotl(4, SpriteMem(SPR + 1)), SpriteMem(SPR + 2) AND &H40, SpriteMem(SPR + 2) AND &H80
         END IF
      END IF
   NEXT SPR
END IF

ModeQDrawArray

END SUB

SUB drawspritebasic (Xn AS LONG, Yn AS LONG, colup AS LONG, address AS LONG, hflip AS LONG, vflip AS Long)

DIM h AS LONG, i AS LONG, col AS Long
DIM Xn2 AS LONG, Yn2 AS Long

IF SprClip = falso AND Xn < 8 THEN EXIT SUB

IF (Xn = 0) AND (Yn = 0) AND ((address AND &HFFF) = 0) THEN EXIT SUB

Xn2 = Xn + 7
Yn2 = Yn + 1

colup = rotl(2, colup) OR &H3F10

FOR i = 0 TO 7
   FOR h = 0 TO 7
      'col = colup

      IF hflip = 64 THEN
         tmpshortint = rotl(7 - h, 1)
      ELSE
         tmpshortint = rotl(h, 1)
      END IF

      IF (PPUMem(address + i) AND tmpshortint) > 0 THEN
         IF (PPUMem(address + 8 + i) AND tmpshortint) > 0 THEN
            IF vflip = 128 THEN
               psetbig Xn2 - h, Yn2 + 7 - i, PPUMem(colup + 3)
            ELSE
               psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 3)
            END IF
         ELSE
            IF vflip = 128 THEN
               psetbig Xn2 - h, Yn2 + 7 - i, PPUMem(colup + 1)
            ELSE
               psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 1)
            END IF
         END IF
      ELSE
         IF (PPUMem(address + 8 + i) AND tmpshortint) > 0 THEN
            IF vflip = 128 THEN
               psetbig Xn2 - h, Yn2 + 7 - i, PPUMem(colup + 2)
            ELSE
               psetbig Xn2 - h, Yn2 + i, PPUMem(colup + 2)
            END IF
         END IF
      END IF
   NEXT h
NEXT i

END SUB

SUB exec6502

opcodet = MemGet(PC)
Addrmode (Addressmode(opcodet))
PC = PC + bytes(opcodet)
Execop (instruc(opcodet))
Clockticks = Clockticks + ticks(opcodet)

IF Clockticks > VBCount THEN VBlank

IF DebugTrace = falso THEN EXIT Sub
Dim TmpStuff AS STRING
TmpStuff = "A: " + HEX$(a) + " X: " + HEX$(X) + " Y: " + HEX$(Y) + " SP: " + HEX$(SP) + " P: "
IF CCR.c = verdad THEN TmpStuff = TmpStuff + "C" ELSE TmpStuff = TmpStuff + " "
IF CCR.Z = verdad THEN TmpStuff = TmpStuff + "Z" ELSE TmpStuff = TmpStuff + " "
IF CCR.i = verdad THEN TmpStuff = TmpStuff + "I" ELSE TmpStuff = TmpStuff + " "
IF CCR.D = verdad THEN TmpStuff = TmpStuff + "D" ELSE TmpStuff = TmpStuff + " "
IF CCR.B = verdad THEN TmpStuff = TmpStuff + "B" ELSE TmpStuff = TmpStuff + " "
IF CCR.v = verdad THEN TmpStuff = TmpStuff + "V" ELSE TmpStuff = TmpStuff + " "
IF CCR.N = verdad THEN TmpStuff = TmpStuff + "N" ELSE TmpStuff = TmpStuff + " "
TmpStuff = TmpStuff + " Ct:" + STR$(Clockticks)
shell ("echo "+TmpStuff)

'DO
'   IF KBState(32) THEN DebugTrace = falso  'D
'
'   FOR i = 0 TO 127
'      IF KBState(i) THEN EXIT DO
'   NEXT i
'LOOP

END SUB

SUB Execop (inst AS Long)

SELECT CASE inst
   CASE ADC
      tmpbyte = TUVal
      tmpshortint = a + tmpbyte + CCR.c
      IF (tmpbyte AND 128) <> (a AND 128) THEN
         CCR.v = falso
      ELSE
         IF a AND 128 THEN a = a - 256
         IF tmpbyte AND 128 THEN tmpbyte = tmpbyte - 256
         tmp = a + tmpbyte + CCR.c
         IF (tmp < -128) OR (tmp > 127) THEN CCR.v = verdad ELSE CCR.v = falso
      END IF
      
      IF tmpshortint > &HFF THEN CCR.c = verdad ELSE CCR.c = falso
      a = tmpshortint AND &HFF
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE ANDOp
      a = a AND TUVal
      IF (a AND 128) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE ASL
      tmpbyte = MemoryTUGet
      'tmpbyte = TUVal
      IF (tmpbyte AND 128) THEN CCR.c = verdad ELSE CCR.c = falso
      tmpbyte = rotl(1, tmpbyte) AND &HFF
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE BCC
      IF CCR.c = falso THEN PC = PC + TU2
      EXIT SUB
   CASE BCS
      IF CCR.c = verdad THEN PC = PC + TU2
      EXIT SUB
   CASE BEQ
      IF CCR.Z = verdad THEN PC = PC + TU2
      EXIT SUB
	CASE BITe
      'tmpbyte = MemoryTUGet
      tmpbyte = TUVal
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF (tmpbyte AND &H40) THEN CCR.v = verdad ELSE CCR.v = falso
      tmpbyte = tmpbyte AND a
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE BMI
      IF CCR.N = verdad THEN PC = PC + TU2
      EXIT SUB
   CASE BNE
      IF CCR.Z = falso THEN PC = PC + TU2
      EXIT SUB
   CASE BPL
      IF CCR.N = falso THEN PC = PC + TU2
      EXIT SUB
   CASE BRK
      MemSet SP, PC \ 256
      MemSet SP - 1, PC AND &HFF
      CCR.B = verdad
      MemSet SP - 2, GetCCR
      SP = SP - 3
      PC = rotl(8, MemGet(IRQVector + 1)) + MemGet(IRQVector)
      CCR.i = verdad
      Clockticks = Clockticks + 7
      EXIT SUB
   CASE BVC
      IF CCR.v = falso THEN PC = PC + TU2
      EXIT SUB
   CASE BVS
      IF CCR.v = verdad THEN PC = PC + TU2
      EXIT SUB
   CASE CLC
      CCR.c = falso
      EXIT SUB
   CASE CLD
      CCR.D = falso
      EXIT SUB
   CASE CLI
      CCR.i = falso
      EXIT SUB
   CASE CLV
      CCR.v = falso
      EXIT SUB
   CASE CMP
      tmpbyte = (a - TUVal)
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      IF tmpbyte >= 0 THEN CCR.c = verdad ELSE CCR.c = falso
      EXIT SUB
   CASE CPX
      tmpbyte = (X - TUVal)
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      IF tmpbyte >= 0 THEN CCR.c = verdad ELSE CCR.c = falso
      EXIT SUB
   CASE CPY
      tmpbyte = (Y - TUVal)
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      IF tmpbyte >= 0 THEN CCR.c = verdad ELSE CCR.c = falso
      EXIT SUB
   CASE DEC
      tmpbyte = (MemoryTUGet - 1) AND &HFF
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE DEX
      X = (X - 1) AND &HFF
      IF (X AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF X = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE DEY
      Y = (Y - 1) AND &HFF
      IF (Y AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF Y = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE EOR
      a = a XOR TUVal
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE INC
      tmpbyte = (MemoryTUGet + 1) AND &HFF
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE INX
      X = (X + 1) AND &HFF
      IF (X AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF X = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE INY
      Y = (Y + 1) AND &HFF
      IF (Y AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF Y = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE JMP
      PC = TU
      EXIT SUB
   CASE JSR
      MemSet SP, PC \ 256
      MemSet SP - 1, PC AND &HFF
      SP = SP - 2
      PC = TU
      EXIT SUB
   CASE LDA
      a = TUVal
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE LDX
      X = TUVal
      IF (X AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF X = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE LDY
      Y = TUVal
      IF (Y AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF Y = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE LSR
      tmpbyte = MemoryTUGet
      CCR.c = tmpbyte AND 1
      tmpbyte = rotr(1, tmpbyte) AND &HFF
      CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE NOP
      EXIT SUB
   CASE ORA
      a = a OR TUVal
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE PHA
      MemSet SP, a
      SP = SP - 1
      EXIT SUB
   CASE PHP
      MemSet SP, GetCCR
      SP = SP - 1
      EXIT SUB
   CASE PLA
      SP = SP + 1
      a = MemGet(SP)
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE PLP
      SP = SP + 1
      SetCCR (MemGet(SP))
      EXIT SUB
   CASE ROL
      tmpbyte = MemoryTUGet
      IF CCR.c = verdad THEN
         IF (tmpbyte AND &H80) THEN CCR.c = verdad ELSE CCR.c = falso
         tmpbyte = rotl(1, tmpbyte) OR 1
      ELSE
         IF (tmpbyte AND &H80) THEN CCR.c = verdad ELSE CCR.c = falso
         tmpbyte = rotl(1, tmpbyte)
      END IF
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE ROR
      tmpbyte = MemoryTUGet
      IF CCR.c = verdad THEN
         CCR.c = tmpbyte AND 1
         tmpbyte = rotr(1, tmpbyte) OR 128
      ELSE
         CCR.c = tmpbyte AND 1
         tmpbyte = rotr(1, tmpbyte)
      END IF
      tmpbyte = tmpbyte AND &HFF
      IF (tmpbyte AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF tmpbyte = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      MemoryTUEquals (tmpbyte)
      EXIT SUB
   CASE RTI
      SetCCR (MemGet(SP + 1))
      PC = rotl(8, MemGet(SP + 3)) + MemGet(SP + 2)
      SP = SP + 3
      EXIT SUB
   CASE RTS
      PC = rotl(8, MemGet(SP + 2)) + MemGet(SP + 1)
      SP = SP + 2
      EXIT SUB
   CASE SBC
      tmpbyte = TUVal
      tmpshortint = a - tmpbyte - (CCR.c XOR verdad)
      
      IF (tmpbyte AND 128) <> (a AND 128) THEN
         CCR.v = falso
      ELSE
         IF a AND 128 THEN a = a - 256
         IF tmpbyte AND 128 THEN tmpbyte = tmpbyte - 256
         tmp = a - tmpbyte - (CCR.c XOR verdad)
         IF (tmp < -128) OR (tmp > 127) THEN CCR.v = verdad ELSE CCR.v = falso
      END IF

      IF tmpshortint < 0 THEN CCR.c = falso ELSE CCR.c = verdad
      a = tmpshortint AND &HFF
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE SEC
      CCR.c = verdad
      EXIT SUB
   CASE SED
      CCR.D = verdad
      EXIT SUB
   CASE SEI
      CCR.i = verdad
      EXIT SUB
   CASE STA
      MemoryTUEquals (a)
      EXIT SUB
   CASE STX
      MemoryTUEquals (X)
      EXIT SUB
   CASE STY
      MemoryTUEquals (Y)
      EXIT SUB
   CASE TAX
      X = a
      IF (X AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF X = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE TAY
      Y = a
      IF (Y AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF Y = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE TSX
      X = SP AND &HFF
      IF (X AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF X = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE TXA
      a = X
      IF (a AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF a = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
   CASE TXS
      SP = X + 256
      EXIT SUB
   CASE TYA
      a = Y
      IF (Y AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
      IF Y = 0 THEN CCR.Z = verdad ELSE CCR.Z = falso
      EXIT SUB
END SELECT

END SUB

FUNCTION GetCCR

GetCCR = rotl(7, CCR.N) OR rotl(6, CCR.v) OR &H20 OR rotl(4, CCR.B) OR rotl(3, CCR.D) OR rotl(2, CCR.i) OR rotl(1, CCR.Z) OR CCR.c

END FUNCTION

SUB irq6502

MemSet SP, PC \ 256
MemSet SP - 1, PC AND &HFF
MemSet SP - 2, GetCCR
CCR.i = verdad
SP = SP - 3
PC = rotl(8, MemGet(IRQVector + 1)) + MemGet(IRQVector)
Clockticks = Clockticks + 7

END SUB

FUNCTION JoypadGet (jp AS Long)

SELECT CASE rotl(5, jp) OR Joypad(0).Count
   CASE 0
      JoypadGet = MultiKey(SC_Z) + &H40 + rotl(3, Joypad(0).ZapperButtPressed) ' boton a
   CASE 1
      JoypadGet = MultiKey(SC_X) + &H40 + rotl(3, Joypad(0).ZapperButtPressed) ' boton b
   CASE 2
      JoypadGet = MultiKey(SC_1) + &H40 + rotl(3, Joypad(0).ZapperButtPressed) ' select
   CASE 3
      JoypadGet = MultiKey(SC_2) + &H40 + rotl(3, Joypad(0).ZapperButtPressed) ' start
   CASE 4
      JoypadGet = MultiKey(SC_UP) + &H40 + rotl(3, Joypad(0).ZapperButtPressed)
   CASE 5
      JoypadGet = MultiKey(SC_DOWN) + &H40 + rotl(3, Joypad(0).ZapperButtPressed)
   CASE 6
      JoypadGet = MultiKey(SC_LEFT) + &H40 + rotl(3, Joypad(0).ZapperButtPressed)
   CASE 7
      JoypadGet = MultiKey(SC_RIGHT) + &H40 + rotl(3, Joypad(0).ZapperButtPressed)

   CASE ELSE
      JoypadGet = Joypad(jp).Bits(Joypad(jp).Count) + &H40 + rotl(3, Joypad(jp).ZapperButtPressed)
END SELECT

Joypad(jp).Count = Joypad(jp).Count + 1
IF Joypad(jp).Count = 24 THEN Joypad(jp).Count = 0

END FUNCTION

SUB JoypadSetStrobe (jp AS LONG, ss AS Long)

Joypad(jp).Strobe = ss
IF Joypad(jp).Strobe = falso THEN Joypad(jp).Count = 0

END SUB

SUB LoadFile

CLS

DIM tl AS STRING
DIM romctrl AS Long, romctrl2 AS STRING =" ", PRGLowAddr AS LONG, CHRAddr AS LONG

tl = Command
If tl="" Then tl = "PACMAN.nes" 

OPEN tl FOR BINARY AS #1

GET #1, 7, romctrl2
romctrl = ASC(romctrl2)
SRAMEnabled = rotr(1, romctrl AND &H2)
ROMTrainer = rotr(2, romctrl AND &H4)
MapperNum = rotr(4, romctrl AND &HF0)
GET #1, 8, romctrl2
romctrl = ASC(romctrl2)
IF romctrl = 44 THEN romctrl = 0
MapperNum = MapperNum OR (romctrl AND &HF0)
IF romctrl AND &H1 THEN
   MirrorMethod = 1
ELSE
   IF romctrl AND &H8 THEN MirrorMethod = 2 ELSE MirrorMethod = 0
END IF
GET #1, 5, romctrl2
PRGPages = ASC(romctrl2)
GET #1, 6, romctrl2
CHRPages = ASC(romctrl2)
PRGLowAddr = &H10 OR rotl(7, ROMTrainer)

CHRAddr = PRGLowAddr
FOR i = 1 TO PRGPages: CHRAddr = CHRAddr + 16384: NEXT i

LOCATE 23, 48: COLOR 3, 1: PRINT "€∞∞∞∞∞∞∞∞";

IF MapperNum > 0 THEN
   PRINT "Not Supported Mapper #!"
   Sleep:End
END IF

DIM tmpval AS Long, tmpval2 AS STRING * 1

IF ROMTrainer = 1 THEN
   FOR i = 0 TO &H1FF
      GET #1, 16 + i, tmpval2
      tmpval = ASC(tmpval2)
      MemSet &H7000 + i, tmpval
   NEXT i
END IF

IF PRGPages = 1 THEN
   FOR i = 0 TO &H3FFF
      GET #1, 1 + PRGLowAddr + i, tmpval2
      tmpval = ASC(tmpval2)
      MemSet 49152 + i, tmpval
   NEXT i
   LOCATE 23, 48: COLOR 3, 1: PRINT "€€€€€∞∞∞∞";
ELSEIF PRGPages = 2 THEN
   FOR i = 0 TO &H7FFF
      GET #1, 1 + PRGLowAddr + i, tmpval2
      tmpval = ASC(tmpval2)
      MemSet 32768 + i, tmpval
   NEXT i
   LOCATE 23, 48: COLOR 3, 1: PRINT "€€€€€€∞∞∞";
ELSE
   PRINT "Not Supported # of PRG Pages!"
   Sleep:End
END IF

IF CHRPages = 1 THEN
   FOR i = 0 TO &H1FFF
      GET #1, 1 + CHRAddr + i, tmpval2
      tmpval = ASC(tmpval2)
      PPUMem(i) = tmpval
   NEXT i
   LOCATE 23, 48: COLOR 3, 1: PRINT "€€€€€€€€∞";
ELSEIF CHRPages = 0 THEN
   LOCATE 23, 48: COLOR 3, 1: PRINT "€€€€€€€€∞";
ELSE
   PRINT "Not Supported # of CHR Pages!"
   Sleep:end
END IF

CLOSE #1
Reset6502

'Screen 12
LOCATE 23, 48: COLOR 3, 1: PRINT "€€€€€€€€€";

' antes estaba "tapado"
'For yy = 0 TO 3
'   FOR xx = 0 TO 15
'      LINE (rotl(4, xx), 350 + rotl(4, yy)) - (rotl(4, xx) + 15, 365 + rotl(4, yy)), xx + rotl(4, yy), BF
'   NEXT xx
'NEXT yy

END SUB

SUB LoadFont

OPEN "font.dat" FOR BINARY AS #2
bytes$ = " "
v1 = -1
1034 v1 = v1 + 1: v2 = -1
1134 v2 = v2 + 1
GET #2, , bytes$
font(v1, v2) = ASC(bytes$)
IF ASC(bytes$) = 0 THEN v2 = 0: GOTO 1034
IF ASC(bytes$) = 255 THEN font(v1, v2) = 0: GOTO 1234
GOTO 1134
1234 CLOSE #2

END SUB

FUNCTION MemGet (Addr AS LONG)

SELECT CASE Addr AND &H1C000
   CASE 0
      MemGet = MainMem1(Addr AND &H3FFF)
      EXIT Function
	CASE 16384
      MemGet = MainMem2(Addr AND &H3FFF)
      EXIT Function
	Case 32768
      MemGet = MainMem3(Addr AND &H3FFF)
      EXIT Function
	CASE 49152
      MemGet = MainMem4(Addr AND &H3FFF)
      EXIT FUNCTION
   CASE ELSE
      MemGet = a
      EXIT FUNCTION
END SELECT

END FUNCTION

SUB MemoryTUEquals (ta AS Long)

SELECT CASE TU
   CASE PPUCtrl1
      NMIonVblank = rotr(7, ta AND &H80)
      NMIonSprHit = rotr(6, ta AND &H40)
      SSize = rotr(5, ta AND &H20)
      BkPTA = rotl(8, ta AND &H10)
      sppta = rotl(9, ta AND &H8)
      PPUAdrI = rotr(2, ta AND &H4)
      NTabAdr = &H2000 OR rotl(10, ta AND &H3)
   CASE PPUCtrl2
      SprVis = ta AND &H10
      BgVis = ta AND &H8
      SprClip = rotr(2, ta AND &H4)
      BGClip = rotr(1, ta AND &H2)
      DispType = ta AND &H1
   CASE SPRAddr
      SPRAddress = ta
      SFirstRead = verdad
   CASE SPRIO
      SpriteMem(SPRAddress) = ta
      SPRAddress = SPRAddress + 1
   CASE BgScroll
      IF BgScrollUsing = falso THEN
         BgScrollUsing = verdad
         BgScrollX = ta
      ELSE
         BgScrollUsing = falso
         BgScrollY = ta
      END IF
   CASE VRAMAddr
      IF VRAMAddrUsing = falso THEN
         VRAMAddrUsing = verdad
         VRAMAddrHigh = ta AND &H3F
      ELSE
         VRAMAddrUsing = falso
         VRAMAddress = rotl(8, VRAMAddrHigh) + ta
         VFirstRead = verdad
      END IF
   CASE VRAMIO
      VRAMAddress = VRAMAddress AND &H3FFF
      PPUMem(VRAMAddress) = ta
      IF PPUAdrI = verdad THEN VRAMAddress = VRAMAddress + 32 ELSE VRAMAddress = VRAMAddress + 1
   CASE SPRDMA
      tmplbyte = rotl(8, ta)
      SELECT CASE tmplbyte AND 49152
      	CASE 0
            DEFSEG = (MainMem1(tmplbyte AND &H3FFF))
         CASE 32768
            DEFSEG = (MainMem3(tmplbyte AND &H3FFF))
         CASE 49152
            DEFSEG = (MainMem4(tmplbyte AND &H3FFF))
         CASE 16384
            DEFSEG = (MainMem2(tmplbyte AND &H3FFF))
      END SELECT
      
      FOR tmpbyte = 0 TO 255
         'SpriteMem(tmpbyte) = PEEK(tmpbyte)
         SpriteMem(tmpbyte) = MemGet(tmplbyte OR tmpbyte)
      NEXT tmpbyte
   CASE pAPUStCh
      PulseChan(0).Enabled = ta AND 1
      PulseChan(1).Enabled = rotr(1, ta AND 2)
      TriChan.Enabled = rotr(2, ta AND 4)
      NoiseChan.Enabled = rotr(3, ta AND 8)
      PCMChan.Enabled = rotr(4, ta AND 16)
   CASE Joypad1
      JoypadSetStrobe 0, ta AND 1
   CASE Joypad2
      JoypadSetStrobe 1, ta AND 1

   CASE ELSE
      MemSet TU, ta AND &HFF
      'MemSet TU, ta
END SELECT

END SUB

FUNCTION MemoryTUGet
DIM ToRet AS Long

SELECT CASE TU
   CASE PPUStat
      Spr0Occ = rotr(1, VBlankOcc)
      ToRet = VBlankOcc OR Spr0Occ OR ScLnSprCnt OR VRAMWrFlg
      VBlankOcc = falso
      BgScrollUsing = falso
   CASE SPRIO
      ToRet = SpriteMem(SPRAddress)
      IF SFirstRead = falso THEN SPRAddress = SPRAddress + 1 ELSE SFirstRead = falso
   CASE VRAMIO
      VRAMAddress = VRAMAddress AND &H3FFF
      ToRet = PPUMem(VRAMAddress)

      IF VFirstRead = falso THEN
         IF PPUAdrI = verdad THEN VRAMAddress = VRAMAddress + 32 ELSE VRAMAddress = VRAMAddress + 1
      ELSE
         VFirstRead = falso
      END IF
   CASE pAPUStCh
      ToRet = 0
      IF PulseChan(0).Enabled = verdad THEN ToRet = ToRet OR 1
      IF PulseChan(1).Enabled = verdad THEN ToRet = ToRet OR 2
      IF TriChan.Enabled = verdad THEN ToRet = ToRet OR 4
      IF NoiseChan.Enabled = verdad THEN ToRet = ToRet OR 8
      IF PCMChan.Enabled = verdad THEN ToRet = ToRet OR 16
   CASE Joypad1
      ToRet = JoypadGet(0)
   CASE Joypad2
      ToRet = JoypadGet(1)

   CASE ELSE
      ToRet = MemGet(TU)
END SELECT

MemoryTUGet = ToRet
END FUNCTION

SUB MemSet (Addr AS LONG, ValSet AS Long)

SELECT CASE Addr AND &H1C000
   CASE 0
      MainMem1(Addr AND &H3FFF) = ValSet
      EXIT SUB
   CASE 16384
      MainMem2(Addr AND &H3FFF) = ValSet
      EXIT SUB
   CASE 32768
      MainMem3(Addr AND &H3FFF) = ValSet
      EXIT SUB
   CASE 49152
      MainMem4(Addr AND &H3FFF) = ValSet
      EXIT SUB
   CASE ELSE
      a = ValSet
      EXIT SUB
END SELECT

END SUB

SUB ModeQCLSArray

'DEF SEG = VARSEG(gfxarray(0))
'FOR i& = 0 TO 57343: POKE i&, 0: NEXT i&
FOR i& = 0 TO (256*224): gfxarray(i&)= 0: NEXT i&

END SUB

SUB ModeQDrawArray
	Dim im As Long
	Dim As Long xm,ym

	im=0
For xm=0 To 223
   For ym=0 To 255
      col=gfxarray(im)
      im+=1
      PSet (ym,xm),col
   Next
Next

END SUB

SUB ModeQInit
  Screen 18
  Restore pal
  Dim r,g,b As integer
  For i = 0 TO 255
	 Read r,g,b
	 Palette i,b,g,r
  Next
End SUB

SUB ModeQPset (Xt, Yt, col as long)

'DEF SEG = &HA000
''POKE Yt * 256& + Xt, col
'POKE Xt + rotl(8, Yt), col
PSet (Yt,Xt),col

END SUB

SUB ModeQPSetArr (Xt, Yt, col as long)

'DEF SEG = VARSEG(gfxarray(0))
'POKE Xt + rotl(8, (Yt - 8)), col
'PSet (Xt,Yt-8),col
gfxarray(Xt + rotl(8, (Yt - 8)))=col

END SUB

SUB nmi6502
                  
MemSet SP, PC \ 256
MemSet SP - 1, PC AND &HFF
MemSet SP - 2, GetCCR
CCR.i = verdad
SP = SP - 3
PC = rotl(8, MemGet(NMIVector + 1)) + MemGet(NMIVector)
Clockticks = Clockticks + 7

END Sub

SUB psetbig (Xt, Yt, col as long)
DIM address AS Long

IF Xt < 0 OR Xt > 255 THEN EXIT SUB
IF Yt < 8 OR Yt > 231 THEN EXIT Sub ' 8 a un lado y 8 al otro son para el scroll, y no se ven

ModeQPSetArr Xt, Yt, col

'Exit SUB ' lo he anulado, para hacer pruebas (es raro que estuviera puesto)
address = rotr(4, X) + rotl(6, Y) + 2

gfxarray(address) = (gfxarray(address) AND (gfxshiftarray(1, X AND 15) XOR &HFFFF)) OR gfxshiftarray(col AND 1, X AND 15)
gfxarray(address + 16) = (gfxarray(address + 16) AND (gfxshiftarray(1, X AND 15) XOR &HFFFF)) OR gfxshiftarray(rotr(1, col AND 2), X AND 15)
gfxarray(address + 32) = (gfxarray(address + 32) AND (gfxshiftarray(1, X AND 15) XOR &HFFFF)) OR gfxshiftarray(rotr(2, col AND 4), X AND 15)
gfxarray(address + 48) = (gfxarray(address + 48) AND (gfxshiftarray(1, X AND 15) XOR &HFFFF)) OR gfxshiftarray(rotr(3, col AND 8), X AND 15)

'gfxarray(address) = gfxarray(address) OR gfxshiftarray(col AND 1, x AND 15)
'gfxarray(address + 16) = gfxarray(address + 16) OR gfxshiftarray(rotr(1, col AND 2), x AND 15)
'gfxarray(address + 32) = gfxarray(address + 32) OR gfxshiftarray(rotr(2, col AND 4), x AND 15)
'gfxarray(address + 48) = gfxarray(address + 48) OR gfxshiftarray(rotr(3, col AND 8), x AND 15)

END SUB

SUB ReadInfoArrays

LoadFont

gfxarray(0) = 256
gfxarray(1) = 240
DIM tmpval AS LONG
FOR X = 0 TO 1
   FOR Y = 0 TO 15
      tmpval = (X * 2 ^ ((((15 - Y) AND 8) XOR 8) + ((15 - Y) AND 7)))
      IF tmpval > 32767 THEN
         gfxshiftarray(X, Y) = tmpval - 65536
      ELSE
         gfxshiftarray(X, Y) = tmpval
      END IF
   NEXT Y
NEXT X

FOR i = 0 TO 255: READ Addressmode(i): NEXT i
FOR i = 0 TO 255: READ instruc(i): NEXT i
FOR i = 0 TO 255: READ ticks(i): NEXT i
FOR i = 0 TO 255: READ bytes(i): NEXT i
FOR i = 0 TO 255: Read mypal(i): Next I
FOR i = 0 TO 55: READ Mn(i): NEXT i 
 
FOR i = 0 TO 15: FOR h = 0 TO 255
   rotl(i, h) = (h * (2 ^ i))
   rotr(i, h) = (h \ (2 ^ i))
NEXT h: NEXT i

IF NTSCMode = 1 THEN
   CPUSpeed = 1789772.5
   VBSec = 60
   YMax = 224
   LineRate = 15720
   VBScanLine = 240
   MaxScanLine = 262
ELSE
   CPUSpeed = 1773447.4
   VBSec = 50
   YMax = 240
   LineRate = 15600
   VBScanLine = 240
   MaxScanLine = 312
END IF
LineTicks = CPUSpeed / LineRate

NMIClockticks = LineTicks * MaxScanLine

END SUB

SUB Reset6502

DIM i AS LONG

a = 0: X = 0: Y = 0: SP = &H1FF

Clockticks = NMIClockticks - 7

PC = rotl(8, MemGet(ResetVector + 1)) + MemGet(ResetVector)

CCR.c = falso: CCR.Z = falso: CCR.B = falso: CCR.i = verdad: CCR.D = verdad: CCR.v = falso: CCR.N = falso
NTabAdr = &H2000

FOR i = 0 TO &H7FFF: MemSet i, 0: NEXT i
FOR i = &H2000 TO &H3FFF: PPUMem(i) = 0: NEXT i
FOR i = 0 TO &HFF: SpriteMem(i) = 0: NEXT i

VRAMAddress = &H2000
VBCount = NMIClockticks
Joypad(0).Count = 0: Joypad(1).Count = 1
Joypad(0).Strobe = 0: Joypad(1).Strobe = 1
FOR i = 0 TO 23
   Joypad(0).Bits(i) = falso: Joypad(1).Bits(i) = falso
NEXT i
Joypad(0).Bits(17) = verdad
Joypad(1).Bits(18) = verdad
VBlanks = 0
VFirstRead = 0: SFirstRead = 0

END SUB

Sub SetCCR (mf AS LONG)

IF (mf AND &H80) THEN CCR.N = verdad ELSE CCR.N = falso
IF (mf AND &H40) THEN CCR.v = verdad ELSE CCR.v = falso
IF (mf AND &H10) THEN CCR.B = verdad ELSE CCR.B = falso
IF (mf AND &H8 ) THEN CCR.D = verdad ELSE CCR.D = falso
IF (mf AND &H4 ) THEN CCR.i = verdad ELSE CCR.i = falso
IF (mf AND &H2 ) THEN CCR.Z = verdad ELSE CCR.Z = falso
IF (mf AND &H1 ) THEN CCR.c = verdad ELSE CCR.c = falso

END SUB

Function TUVal
IF TUMode = tmAddr THEN
   TUVal = MemoryTUGet
   EXIT FUNCTION
ELSE
   TUVal = TU
   EXIT FUNCTION
END IF
END FUNCTION

SUB VBlank

If MultiKey(sc_r) Then Reset6502:EXIT SUB      
IF MultiKey(sc_d) THEN DebugTrace = verdad        
IF MultiKey(sc_f) THEN BgVis = 8: SprVis = 16 
IF MultiKey(sc_escape) THEN end
If MultiKey(sc_p) THEN                
	Locate 1,40:Print "Paleta"
   FOR Xt = 0 TO 15
      FOR yy = 0 TO 7
         FOR xx = 0 TO 7
            ModeQPset Xt * 8 + xx, 260 + yy, PPUMem(&H3F00 + Xt)
            ModeQPset Xt * 8 + xx, 268 + yy, PPUMem(&H3F10 + Xt)
         NEXT xx
      NEXT yy
   NEXT Xt
End IF

VBlankOcc = 128
Clockticks = NMIClockticks

VBlanks = VBlanks + 1

'disptxt 130, 224, "vblank #" + STR$(VBlanks)

IF VBlanks MOD frameskip = 0 THEN
      DrawScreen
End IF

If NMIonVblank = verdad Then
   nmi6502
   'disptxt 220, 224, "nmi"
End IF

END SUB

