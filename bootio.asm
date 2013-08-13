        page    61,132
        TITLE   bootio.c
_DATA   SEGMENT  WORD PUBLIC 'DATA'
_DATA   ENDS
DGROUP  GROUP   _DATA
        ASSUME DS: DGROUP, SS: DGROUP
_TEXT   SEGMENT  WORD PUBLIC 'CODE'
        ASSUME  CS: _TEXT
        PUBLIC  _BOOTIO
_BOOTIO PROC NEAR
;
;       Semantics  int bootio(int iotype, char *buffer)
;
        push    BP
        mov     BP,SP                   ; Save stack pointer
        push    ES
        push    SS
        pop     ES
        push    BX
        push    CX
        push    DX
        mov     AX,WORD PTR [BP+4]      ; Get iotype
        mov     AH,AL                   ; Move to correct byte
        mov     AL,1                    ; Read 1 track
        mov     BX,WORD PTR [BP+6]      ; Get buffer address
        mov     DX,80h                  ; Head 0, Drive C
        mov     CX,1                    ; Cylinder 0, sector 1
        int     13h                     ; perform I/O
        jc      error
        xor     AX, AX                  ; show good status
        jmp     SHORT goback
error:
        mov     AX, -1                  ; show bad status
goback:
        pop     DX
        pop     CX
        pop     BX
        pop     ES
        mov     SP,BP
        pop     BP
        ret
_BOOTIO ENDP
_TEXT   ENDS
        END
