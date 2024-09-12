;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                     A H E A D   (Amsdos Header Utility)                    @
;@                                                                            @
;@               (c) 2015 by Prodatron / SymbiosiS (Jörn Mika)                @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;==============================================================================
;### CODE-AREA ################################################################
;==============================================================================

txttit  db 13,10
        db "AHEAD 1.1 for SymbOS SymShell",13,10
        db "  AmsDOS Fileheader Utility",13,10
        db "  (c)oded 2015 by Prodatron/SymbiosiS",13,10
        db "=====================================",13,10,0

txterrpar
db "Missing or wrong parameters",13,10,13,10
db "Usage:",13,10
db "AHEAD %r FILEMASK.EXT",13,10
db "    removes AmsDOS fileheaders from all files, if existing",13,10
db "AHEAD %a FILEMASK.EXT [%p:BBBB[,LLLL[,XXXX[,TT]]]]",13,10
db "    adds AmsDOS fileheaders to all files, if not existing;",13,10,0
txterrpar1
db "    the optional %p parameter specifies the begin BBBB,",13,10
db "    optional length LLLL, optional execution address EEEE",13,10
db "    and the optional file type TT (all HEX, 4 or 2 digits)",13,10
db "    Type can be 00=Basic, 01=Binary, 02=Screen, 13=ASCII",13,10,0
txterrpar2
db "AHEAD %i FILEMASK.EXT",13,10
db "    displays AmsDOS fileheader information of all files",13,10
db 13,10,0
txterrfil db "Operation aborted. A disc error occured.",13,10,0

txtmsgfil db " - ",0
txtmsghad db "header added",13,10,0
txtmsghrm db "header removed",13,10,0
txtmsghex db "untouched (existing header)",13,10,0
txtmsghnx db "untouched (no header found)",13,10,0
txtmsgino db "no header",13,10,0
txtmsgihd db 13,10,"  Length XXXX, Begin XXXX, Execute XXXX, Type XX",13,10,0
txtmsgend0 db 13,10,"XX files examined, XX headers removed",13,10,0
txtmsgend1 db 13,10,"XX files examined, XX headers added",13,10,0
txtmsgend2 db 13,10,"XX files examined",13,10
txtmsglfd db 13,10,0


;### PRGPRZ -> Programm-Prozess
prgprz  call SyShell_PARALL     ;angehangene Parameter und Shell-Prozess, -Höhe und -Breite holen
        push de
        call SyShell_PARSHL
        jp c,prgend

        ld hl,txttit            ;title text
        call SyShell_STROUT0
        jp c,prgend

        pop de
        call hedpar
        call hedope

;### PRGEND -> Programm beenden
prgendp ld hl,txterrpar
        call SyShell_STROUT0
        ld hl,txterrpar1
        call SyShell_STROUT0
        ld hl,txterrpar2
prgend0 call SyShell_STROUT0

prgend  ld e,0
        call SyShell_EXIT       ;tell Shell, that process will quit
        ld hl,(App_BegCode+prgpstnum)
        call SySystem_PRGEND    ;end own application
prgend1 rst #30                 ;wait until end
        jr prgend1

;### PRGERR -> Beendet Prozess, falls Fehler oder EOF
prgerr  jp nz,prgend    ;EOF
        jp c,prgend     ;Fehler
        ret


;==============================================================================
;### AMSHEAD SPECIFIC CODE ####################################################
;==============================================================================

;### HEDPAR -> get filemask, mode and additonal parameters
;### Input      D=number of parameters, E=number of flags
hedparflt   dw hedparfl0,0
            dw hedparfl1,0
            dw hedparfl2,0
            dw hedparfl3,0
            dw 0

hedparfl0   db "r",0    ;remove header
hedparfl1   db "a",0    ;add header
hedparfl2   db "i",0    ;show header
hedparfl3   db "p:"     ;parameters for adding header

hedparc     db 0        ;(hedparc)=command type (0=remove, 1=add, 2=info)
hedparmsk   db "*.*",0

prgparpth ds 256
prgparpen dw 0

hedpar  ld a,d
        cp 1
        jp nz,prgendp
        push de
        ld iy,hedparflt
        call SyShell_PARFLG
        pop de
        jp c,prgendp
        ld a,l
        ld c,0
        cp 1
        jr z,hedpar1
        inc c
        cp 2
        jr z,hedpar1
        inc c
        cp 4
        jr z,hedpar1
        cp 10
        jp nz,prgendp
        ld bc,(3*4+2+hedparflt)
        ld d,4
        ld iy,heddatbeg
        call hedpar2
        jr z,hedpar1
        ld d,4
        ld iy,heddatlen
        call hedpar2
        jr z,hedpar1
        ld d,4
        ld iy,heddatexe
        call hedpar2
        jr z,hedpar1
        ld d,2
        ld iy,heddattyp
        call hedpar2
hedpar1 ld a,c
        ld (hedparc),a
        ld de,0
        ld hl,(SyShell_CmdParas)
        ld bc,prgparpth
        call SyShell_PTHADD
        ld (prgparpen),hl
        bit 0,a
        ret z
        ld hl,hedparmsk
        ld bc,4
        ldir
        ret

hedpar2 ld hl,0
hedpar3 ld a,(bc)
        inc bc
        call clclcs
        sub "0"
        jp c,prgendp
        cp 10
        jr c,hedpar4
        add "0"+10-"a"
        cp 16
        jp nc,prgendp
hedpar4 add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add l
        ld l,a
        ld a,0
        adc h
        ld h,a
        dec d
        jr nz,hedpar3
        ld (iy+0),l
        ld (iy+1),h
        ld a,(bc)
        or a
        ret z
        cp ","
        jp nz,prgendp
        inc bc
        ret

heddatbeg   dw 0
heddatlen   dw 0
heddatexe   dw 0
heddattyp   db 2,0

;### HEDOPE -> add/remove/info Amsdos headers
;### Input      (hedparc)=command type (0=remove, 1=add, 2=info)
hedopen dw 0    ;number of examined files
hedopec dw 0    ;number of converted files

hedope  call hednxt
        ld hl,txterrfil
        jp c,prgend0
        jp z,hedope9
        ld hl,(hedopen)
        inc hl
        ld (hedopen),hl
        push af
        push bc
        ld hl,prgparpth
        call SyShell_STROUT0
        ld hl,txtmsgfil
        call SyShell_STROUT0
        pop bc
        pop de
        ld a,(hedparc)
        cp 1
        ld a,d
        jr c,hedope3
        jr z,hedope4
        or a                ;*** SHOW INFOS
        ld hl,txtmsgino
        jp z,hedope2
        ld de,txtmsgihd+2+9
        ld a,(hednxthed+24+1)
        call clchex
        ld a,(hednxthed+24+0)
        call clchex
        ld de,txtmsgihd+2+21
        ld a,(hednxthed+21+1)
        call clchex
        ld a,(hednxthed+21+0)
        call clchex
        ld de,txtmsgihd+2+35
        ld a,(hednxthed+26+1)
        call clchex
        ld a,(hednxthed+26+0)
        call clchex
        ld de,txtmsgihd+2+46
        ld a,(hednxthed+18+0)
        call clchex
        ld hl,txtmsgihd
        jp hedope2
hedope3 or a                ;*** REMOVE HEADER
        ld hl,txtmsghnx
        jp z,hedope2
        ld hl,hedopec
        inc (hl)
        call hedtmp             ;create tmp file
        ld hl,(hednxthed+24)
        ld (hedcopl),hl
        call hedcop             ;copy remaining data (without header) into tmp file and rename it
        ld hl,txtmsghrm
        jp hedope2
hedope4 or a                ;*** ADD HEADER
        ld hl,txtmsghex
        jp nz,hedope2
        ld hl,hedopec
        inc (hl)
        ld a,(hednxthnd)
        ld ix,0
        ld iy,0
        ld c,0
        call SyFile_FILPOI      ;go back to file begin
        call hedtmp             ;create tmp file
        ld hl,hednxthed
        ld de,hednxthed+1
        ld bc,128-1
        ld (hl),b
        ldir                    ;reset header
        ld hl,hednxthed+1
        ld de,hednxthed+2
        ld (hl),32
        ld bc,8+3
        push hl
        ldir                    ;reset filename
        pop de
        ld hl,(hednxtnam)
hedopn5 ld a,(hl)               ;copy filename
        inc hl
        or a
        jr z,hedopn7
        cp "."
        jr nz,hedopn6
        ld de,hednxthed+9
        jr hedopn5
hedopn6 ld (de),a
        inc de
        jr hedopn5
hedopn7 ld hl,(heddatbeg)       ;copy length/begin/execute/type
        ld (hednxthed+21),hl
        ld hl,(heddatexe)
        ld (hednxthed+26),hl
        ld hl,(heddatlen)
        ld a,l
        or h
        jr nz,hedopn8
        ld hl,(hednxtnam)
        ld bc,-9
        add hl,bc
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
hedopn8 ld (hednxthed+64),hl
        ld (hednxthed+24),hl
        ld a,(heddattyp)
        ld (hednxthed+18),a
        ld hl,hednxthed
        call hednxt8
        ld (hednxthed+67),de
        ld a,(hedtmphnd)
        ld hl,hednxthed
        ld bc,128
        ld de,(App_BnkNum)
        call SyFile_FILOUT      ;write header into tmp file
        jr c,hedtmp1
        ld hl,-1
        ld (hedcopl),hl
        call hedcop             ;copy all data (after the header) into tmp file and rename it
        ld hl,txtmsghad
hedope2 call SyShell_STROUT0
hedope0 ld a,(hednxthnd)
        call SyFile_FILCLO
        jp hedope
hedope9 ld a,(hedopen)
        call clcdez
        ld (txtmsgend0+2),hl
        ld (txtmsgend1+2),hl
        ld (txtmsgend2+2),hl
        ld a,(hedopec)
        call clcdez
        ld (txtmsgend0+21),hl
        ld (txtmsgend1+21),hl
        ld a,(hedparc)
        cp 1
        ld hl,txtmsgend0
        jp c,prgend0
        ld hl,txtmsgend1
        jp z,prgend0
        ld hl,txtmsgend2
        jp prgend0

;### HEDTMP -> creates tmp file
hedtmphnd   db 0    ;file handle
hedtmpfil   db "ahead.tmp",0

hedtmp  ld hl,hedtmpfil
        ld de,(prgparpen)
        ld bc,10
        ldir
        ld ix,(App_BnkNum-1)
        ld hl,prgparpth
        xor a
        call SyFile_FILNEW
        jr c,hedtmp0
        ld (hedtmphnd),a
        ret
hedtmp1 ld a,(hedtmphnd)
        call SyFile_FILCLO
hedtmp0 ld a,(hednxthnd)
        call SyFile_FILCLO
hedtmp2 ld hl,txterrfil
        jp prgend0

;### HEDCOP -> copies all remaining data from source file to tmp file, deletes source file and renames tmp file in source file
hedcopl dw 0
hedcop  ld hl,lodbuf
        ld bc,1024
        add hl,bc
        ld b,4096/256
        ld de,(App_BnkNum)
        ld a,(hednxthnd)
        push hl
        push de
        call SyFile_FILINP
        pop de
        pop hl
        jr c,hedtmp1
        ld a,c
        or b
        jr z,hedcop1
        ld a,(hedcopl+1)
        sub 4096/256
        jr nc,hedcop2
        ld bc,(hedcopl)
hedcop2 ld (hedcopl),a
        ld a,(hedtmphnd)
        push bc
        call SyFile_FILOUT
        pop bc
        jr c,hedtmp1
        ld a,b
        cp 4096/256
        jr z,hedcop
hedcop1 ld a,(hednxthnd)
        call SyFile_FILCLO
        ld a,(hedtmphnd)
        call SyFile_FILCLO
        ld hl,(hednxtnam)
        ld de,(prgparpen)
        ld bc,13
        ldir
        ld ix,(App_BnkNum-1)
        ld hl,prgparpth
        call SyFile_DIRDEL
        jr c,hedtmp2
        ld hl,hedtmpfil
        ld de,(prgparpen)
        ld bc,10
        ldir
        ld ix,(App_BnkNum-1)
        ld hl,prgparpth
        ld de,(hednxtnam)
        call SyFile_DIRREN
        jp c,hedtmp2
        ret

;### HEDNXT -> opens next file and loads first 128bytes
;### Output     CF=1      -> disc error
;###            ZF=1      -> no (more) file entries found
;###            CF=0,ZF=0 -> BC=number of loaded bytes, A=0 no header found, A=1 header found
hednxtofs   dw 0    ;offset for next file in directory
hednxtcnt   dw 0    ;number of remaining files
hednxtbuf   dw 0    ;current address in directory buffer
hednxtnam   dw 0    ;pointer to current filename
hednxtfln   ds 4    ;file length
hednxthnd   db 0    ;file handle
hednxthed   ds 128  ;file first 128 bytes

hednxt  ld hl,(hednxtcnt)
        ld a,l
        or h
        jr nz,hednxt1
        ld hl,prgparpth
        db #dd:ld l,8+16
        ld de,lodbuf
        ld (hednxtbuf),de
        ld bc,1024
        ld iy,(hednxtofs)
db #fd:ld a,l
db #fd:or h
jr z,hednxt7
xor a
ret
hednxt7
        ld a,(App_BnkNum)
        db #dd:ld h,a
        push iy
        call SyFile_DIRINP
        pop de
        ret c               ;CF=1 -> error while reading directory
        ld a,l
        or h
        ret z               ;ZF=1 -> no (more) entries found
        ex de,hl
        add hl,de
        ld (hednxtofs),hl
        ex de,hl
hednxt1 dec hl
        ld (hednxtcnt),hl
        ld hl,(hednxtbuf)   ;build file path
        ld de,hednxtfln
        ld bc,4
        ldir
        ld bc,5
        add hl,bc
        ld (hednxtnam),hl
        ld de,(prgparpen)
hednxt2 ld a,(hl)
        ldi
        or a
        jr nz,hednxt2
        ld (hednxtbuf),hl
        ld ix,(App_BnkNum-1)
        ld hl,prgparpth
        call SyFile_FILOPN
        ret c
        ld (hednxthnd),a
        ld bc,128
        ld hl,hednxthed
        ld de,(App_BnkNum)
        push hl
        call SyFile_FILINP
        pop hl
        jr c,hednxt3
        jr z,hednxt4
hednxt6 xor a               ;couldn't load 128bytes -> no header
        inc a
        ld a,0
        ret
hednxt4 call hednxt8
        ld hl,(hednxthed+67)
        or a
        sbc hl,de
        jr nz,hednxt6
        ld a,(hednxthed+1)    ;filename shouldn't be 0 -> no header
        or a
        jr z,hednxt6
        xor a
        inc a
        ret
hednxt3 push af
        ld a,(hednxthnd)
        call SyFile_FILCLO
        pop af
        ret
hednxt8 ld b,67
        ld de,0
hednxt5 ld a,(hl)
        add e
        ld e,a
        ld a,0
        adc d
        ld d,a
        inc hl
        djnz hednxt5
        ret


;==============================================================================
;### SUB-ROUTINEN #############################################################
;==============================================================================

;### CLCLEN -> Ermittelt Länge eines Strings
;### Eingabe    HL=String
;### Ausgabe    HL=Stringende (0), BC=Länge (maximal 255)
;### Verändert  -
clclen  push af
        xor a
        ld bc,255
        cpir
        ld a,254
        sub c
        ld c,a
        dec hl
        pop af
        ret

;### CLCLCS -> Wandelt Groß- in Kleinbuchstaben um
;### Eingabe    A=Zeichen
;### Ausgabe    A=lcase(Zeichen)
;### Verändert  F
clclcs  cp "A"
        ret c
        cp "Z"+1
        ret nc
        add "a"-"A"
        ret

;### CLCHEX -> Converts 8bit value into hex string
;### Input      A=value, (DE)=string
;### Output     DE=DE+2
clchex  ld c,a          ;a=number -> (DE)=hexdigits, DE=DE+2
        rlca:rlca:rlca:rlca
        call clchex1
        ld a,c
clchex1 and 15
        add "0"
        cp "9"+1
        jr c,clchex2
        add "A"-"9"-1
clchex2 ld (de),a
        inc de
        ret

;### CLCDEZ -> Rechnet Byte in zwei Dezimalziffern um
;### Eingabe    A=Wert
;### Ausgabe    L=10er-Ascii-Ziffer, H=1er-Ascii-Ziffer
;### Veraendert AF
clcdez  ld l,0
clcdez1 sub 10
        jr c,clcdez2
        inc l
        jr clcdez1
clcdez2 add "0"+10
        ld h,a
        ld a,"0"
        add l
        ld l,a
        ret


;==============================================================================
;### DATA-AREA ################################################################
;==============================================================================

lodbuf  db 0    ;** last label in code area **

App_BegData

;### nothing here
db 0

;==============================================================================
;### TRANSFER-AREA ############################################################
;==============================================================================

App_BegTrns
;### PRGPRZS -> Stack für Programm-Prozess
        ds 64
prgstk  ds 6*2
        dw prgprz

App_PrcID   db 0
App_MsgBuf  ds 14
