        page    61,132
        title   Bstrap - update fixed disk bootstrap
        subttl  Code
        page    +
Code    segment
        assume  cs:Code, ds:Code, es:Code, ss:Code
        org     80h
parmLen db      ?
parm    db      ?
        org     100h
        include bootany.inc
Bstrap  proc    far
        mov     SI,DS                           ; Get data segment
        mov     ES,SI                           ; Make sure the same
;
;       Read current bootstrap record
;
        mov     AX,201h                         ; read 1 sector
        lea     BX,Boot                         ; buffer address
        mov     CX,1                            ; cyl 0, sector 1
        mov     DX,80h                          ; head 0, drive 0
        int     13h                             ; read fixed disk boot
        jnc     ReadOk                          ; Go on if ok
        mov     bx,2                            ; write to stderr
        mov     cx,Err1l                        ; length of message
        lea     dx,Err1                         ; message address
        mov     ah,40h                          ; write to stream
        int     21h                             ; send message
        jmp     Exit                            ; Exit program
ReadOk:
;
;       Read in file named as parm (boot program)
;       First find the program name
;
        sub     CX,CX                           ; clear register
        sub     SI,SI                           ; clear register
        mov     CL,parmLen                      ; Get length of parm
        cmp     CL,0                            ; Better be there
        jbe     NameError                       ; its not
        lea     DI,parm                         ; get name address
        mov     AL,' '                          ; what we will ignore
        repe scasb
        jcxz    NameError                       ; No parm - write msg
        jmp     NameThere                       ; it is
NameError:
        mov     bx,2                            ; write to stderr
        mov     cx,NameErrl                     ; length of message
        lea     dx,NameErr                      ; message address
        mov     ah,40h                          ; write to stream
        int     21h                             ; send message
        jmp     Exit
;
;       Found the name - Open and Read the file
;
NameThere:
        dec     DI                              ; Point to first byte
        inc     CX                              ; Correct the count
        mov     BX,CX                           ; get bytes left
        mov     [BX+DI],BYTE PTR 0              ; move in terminator
        mov     DX,DI                           ; Get file name start
        sub     AL,AL                           ; Open for read
        mov     AH,3dh                          ; Open function
        int     21h                             ; Call DOS
        jc      FileError
        lea     DX,Boot                         ; buffer address
        mov     CX,PartAddr                     ; maximum boot length
        mov     BX,AX                           ; read from file
        mov     AH,3fh                          ; read from stream
        int     21h                             ; dos service
        jnc     FileOk                          ; continue if file ok
FileError:
        mov     AH,3Eh                          ; Close the file
        int     21h                             ; dos service
        mov     BX,2                            ; write to stderr
        mov     CX,Err2l                        ; length of message
        lea     DX,Err2                         ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message
        jmp     Exit                            ; Exit program
;
;       The new boot program is not in our "in-memory" copy of the
;       boot sector
;
FileOk:
;
;       Close the file
;
        mov     AH,3Eh                          ; Close the file
        int     21h                             ; dos service
;
;       Update the boot sector with User Data
;       Put out first message
;
        mov     bx,2                            ; write to stderr
        mov     cx,Msg1l                        ; length of message
        lea     dx,Msg1                         ; message address
        mov     ah,40h                          ; write to stream
        int     21h                             ; send message

        mov     CX,max_partitions               ; get loop count

PartLoop:
;
;       Find out what partition this Function Key will be for
;
        mov     Index,CX                        ; Save index
        sub     CL,max_partitions+1             ; get negative index
        neg     CL                              ; turn positive
        add     CL,Numeric                      ; make displayable
        mov     Q1FKey,CL                       ; move into message
        mov     Q2FKey,CL                       ; move into message
        mov     Q3FKey,CL                       ; move into message
        mov     AL,max_partitions               ; get max value
        add     AL,Numeric                      ; make displayable
        mov     Q1Max,AL                        ; move into message
        mov     BX,2                            ; write to stderr
        mov     CX,Q1l                          ; length of message
        lea     DX,Q1                           ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message
        call    GetChar                         ; Get the number
        cmp     AL,'0'                          ; See if '0'
        jne     NoExit                          ; If not continue
        jmp     TestNumLock                     ; Exit loop
NoExit:
        cmp     AL,'1'                          ; See if valid value
        jl      PartError                       ; No - reprompt
        cmp     AL,Numeric+max_partitions       ; Check max value
        ja      PartError                       ; Too big - reprompt
        mov     Q2Pnum,AL                       ; Save part number
        mov     Err3P,AL                        ; Save part number
        sub     AL,Numeric+1                    ; Turn into index
        push    AX                              ; Save for later
        mov     AH,SIZE PartData                ; Get entry size
        mul     AH                              ; Get offset into table
        mov     Data,AX                         ; Get data address
        mov     BX,AX                           ; Get data address
        pop     AX                              ; Restore value
        mov     AH,SIZE PartitionEntry          ; Get entry size
        mul     AH                              ; Get offset into table
        mov     Entry,AX                        ; Get entry address
        cmp     part.partition[BX],0            ; Already in use?
        je      BootTest                        ; No - use it
        mov     BX,2                            ; write to stderr
        mov     CX,Err3l                        ; length of message
        lea     DX,Err3                         ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message
PartError:
        mov     CX,Index                        ; restore index
        jmp     Partloop

BootTest:
;       Check to see if the partition is marked bootable -
;       If not, see if it should be made bootable
;
        mov     BX,Entry                        ; Get Entry address
        cmp     partitionTable.BootIndicator[BX],0 ; Can partition boot
        jne     PartBoot                        ; Yes - use it
        push    AX                              ; Save for later
        mov     BX,2                            ; write to stderr
        mov     CX,Q2l                          ; length of message
        lea     DX,Q2                           ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message
        call    GetChar                         ; Get the number
        pop     CX                              ; Restore value
        and     AL,0DFh                         ; Convert to upper case
        cmp     AL,'Y'                          ; See if 'Y'
        je      MakeBoot                        ;  Make it bootable
        cmp     AL,'N'                          ; See if 'N'
        jne     BootTest                        ;  Bad reply
        jmp     PartError                       ;  Don't make it boot
MakeBoot:
        mov     partitionTable.BootIndicator[BX],80h ; Turn on boot flag
        mov     AX,CX                           ; Restore part #

PartBoot:
        mov     BX,Data                         ; Get table offset
        mov     AL,Q2Pnum                       ; Get part number
        sub     AL,Numeric                      ; Convert to binary
        mov     part.partition[BX],AL           ; Save partition #

PartBootLoop:
;
;       Get partitition description from user
;
        mov     BX,2                            ; write to stderr
        mov     CX,Q3l                          ; length of message
        lea     DX,Q3                           ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message

        mov     CX,part_text_len                ; set to text length
        cld                                     ; copy forward
        lea     DI,part.text                    ; Get base
        add     DI,Data                         ; Add entry offset
        mov     AL,' '                          ; Get data start
        rep stosb                               ; Copy the data
        lea     DX,TextBuffer                   ; get input area addr
        mov     AH,10                           ; Buffered Input Code
        int     21h                             ; Get data
        sub     CX,CX                           ; Clear register
        mov     CL,TextBuffer+1                 ; Get length entered
        jcxz    PartBootLoop                    ; Reprompt if null
        cld                                     ; copy forward
        lea     DI,part.text                    ; Get base
        add     DI,Data                         ; Add entry offset
        lea     SI,TextBuffer+2                 ; Get data start
        rep movsb                               ; Copy the data
        mov     CX,Index                        ; Restore loop index
        loop    NextPart                        ; Set up next partition
        jmp     TestNumLock
NextPart:
        jmp     PartLoop
;
;       See if Num Lock should be turned off
;
TestNumLock:
        mov     bx,2                            ; write to stderr
        mov     cx,Q4l                          ; length of message
        lea     dx,Q4                           ; message address
        mov     ah,40h                          ; write to stream
        int     21h                             ; send message
        call    GetChar                         ; Get the number
        and     AL,0DFh                         ; Convert to upper case
        cmp     AL,'Y'                          ; See if 'Y'
        je      ResetTable                      ;  Off is default
        cmp     AL,'N'                          ; See if 'N'
        jne     TestNumLock                     ;  Bad reply
        mov     AL,NumLockOn                    ; Get NumLock on mask
        mov     bootOpts.numlockMask,AL         ; Reset Mask
;
;       Swap the BootIndicator with the System Id to insure that there
;       will be only one bootable partition at a time.
;
ResetTable:
        mov     CX,max_partitions               ; Get number of parts
        sub     BX,BX                           ; Clear index
ResetTableLoop:
        mov     AL,partitionTable.BootIndicator[BX] ; get indicator
        cmp     AL,80h                          ; bootable partition?
        jne     PartOk                          ; don't mess with it
        mov     AL,partitionTable.SystemId[BX]  ; Get System ID
        mov     partitionTable.BootIndicator[BX],AL ; Save here
        mov     partitionTable.SystemId[BX],80h ; Make System ID inv.
PartOk:
        add     BX,SIZE PartitionEntry          ; Next Entry
        loop    ResetTableLoop
;
;       Rewrite the boot record
;
        lea     BX,Boot                         ; buffer address
        mov     CX,1                            ; cyl 0, sector 1
        mov     DX,80h                          ; head 0, drive 0
        mov     AX,301h                         ; write 1 sector
        int     13h                             ; update boot record
        jc      Exit                            ; exit if error
;
;       Write out message
;
        mov     BX,2                            ; write to stderr
        mov     CX,Msgl                         ; length of message
        lea     DX,Msg                          ; message address
        mov     AH,40h                          ; write to stream
        int     21h                             ; send message
Exit:
        int     20h                             ; exit program

TextBuffer db   16,0
        db      16 dup(0)

Msg1    db      13,10,'<CTRL><BREAK> may be used to end the install '
        db      'at any time',10
Msg1l   equ     $-Msg1

Q1      db      13,10,'What partition should be assigned to F'
Q1Fkey  db      '#? (1-'
Q1Max   db      '#, 0 to end) '
Q1l     equ     $-Q1

Q2      db      13,10,'Partition '
Q2Pnum  db      '# is not bootable.',13,10
        db      '      Reply Y to make it bootable, '
        db      'N to assign F'
Q2Fkey  db      '# to a new partition. '
Q2l     equ     $-Q2

Q3      db      13,10,'Enter partition description to be assigned to F'
Q3Fkey  db      '# (15 chars max) '
Q3l     equ     $-Q3

Q4      db      13,10,'Do you want Num Lock turned off at boot? '
        db      '(Y or N) '
Q4l     equ     $-Q4

Err1    db      13,10,'Error Reading Boot Sector'
Err1l   equ     $-Err1

NameErr db      13,10,'Invalid file name for new boot program'
NameErrl equ    $-NameErr

Err2    db      13,10,'Error Reading New Boot Program'
Err2l   equ     $-Err2

Err3    db      13,10,'Partition '
Err3P   db      '# is already defined'
Err3l   equ     $-Err3

msg     db      13,10,'Boot record updated.',13,10
msgl    equ     $-msg

Index   dw     0
Entry   dw     0
Data    dw     0

Boot           db      DataAddr dup(?)
part           PartData max_partitions dup(<>)
bootOpts       BootData <>
partitionTable PartitionEntry 4 dup(<>)
Validation     db      2 dup(0)

Bstrap  endp

GetChar proc    near
        mov     AH,1                   ; Get keyboard input
        int     21h
        cmp     AL,0
        jne     GetCharRet
        mov     AH,1                   ; Get extended code
        int     21h
        sub     AL,AL                  ; show bad, not ASCII
GetCharRet:
        ret
GetChar endp

Code    ends
        end     Bstrap
