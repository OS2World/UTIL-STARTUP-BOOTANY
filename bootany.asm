F1_scancode     equ     59
reply_interval  equ     5               ; wait up to 5 seconds for reply

                include bootany.inc

code            segment


                assume  cs:Code, ds:Code, es:Code, ss:Code
                org     0

bootany         proc    near
;
;               Setup the stack
;
                mov     AX,CS           ; Get current segment
                mov     DS,AX           ; Set DS temporarily
                cli                     ; disable interrupts
                mov     SS,AX           ; set stack segment
                mov     SP,NewBootLocation ; initialize stack pointer
                sti                     ; reenable interrupts
;
;               DOS loads this pgm at 0000:7C00. Any boot routine
;               we call also expects to execute there so the first
;               exercise is to move this code somewhere else.
;
                mov     CX,512          ; bytes to move
                mov     SI,BootLocation ; Get boot address
                les     DI,DWORD PTR SecBoot[SI] ; Load ES=07A0,DI=0000
                rep     movsb           ; Copy to new location

                lea     SI,down+NewBootLocation ; address relocated e.p.
                jmp     SI

down            equ     $
;
;               Turn off Numlock (while DS is still 0)
;
                mov     AL,DS:[KeyboardFlags] ; Get keyboard flags
                and     AL,bootOpts.numlockMask[DI] ; Mask numlock flag
                mov     DS:[KeyboardFlags],AL ; Save keyboard flags
;
;               Set up data segment
;
                mov     AX,ES           ; Get current segment
                mov     DS,AX           ; Set data segment
prompt:
;
;               Display the menu
;
                call    Clear           ; clear the screen
                mov     CX,max_partitions ; set to max partitions
                xor     BX,BX           ; set base offset into table
                mov     SI,-1           ; set index
                mov     DL,Numeric      ; get first numeric value
promptloop:
                inc     DL              ; Increment Func Key number
                cmp     part.partition[BX],0 ; any entry?
                je      finishPrompt    ; No skip rest

                mov     key,DL          ;  save in message
                lea     SI,FkeyMsg      ; get msg addr
                call    Send

                lea     SI,part.text[BX] ; get data addr
                call    Send

                add     BX,SIZE PartData ; next entry address
                loop    promptloop
finishPrompt:
                inc     DL              ; get Func key number
                mov     basicKey,DL     ; save in message
                lea     SI,rombasic     ; get msg address
                call    Send

                mov     AH,01h          ; SetTickCount
                sub     CX,CX           ; hi-order tick count
                sub     DX,DX           ; lo-order tick count
                int     1ah             ; BiosTimerService
;
;               Get the reply
;
reply:
                mov     AH,1            ; keyboard status
                int     16h             ; keybd bios service
                jnz     read_scancode   ; jump if reply
                sub     AH,AH           ; GetTickCount
                int     1ah             ; BiosTimerService
                cmp     DX,192*reply_interval/10 ; check for timeout
                jb      reply           ; wait for scancode
                mov     AL,default      ; prior system id
                cmp     AL,'?'          ; validate key
                je      error           ; no default
                jmp     system          ; boot default system
read_scancode:
                sub     AH,AH           ; read keyboard
                int     16h             ; keybd bios service
                sub     AH,F1_scancode-1 ; Turn into index
                jbe     error           ; Invalid code check
                mov     AL,AH           ; Copy to AL
                add     AL,Numeric      ; Make numeric
                cmp     AL,basicKey     ; max Function key
                ja      error           ; branch if bad response
                jne     system          ; if not basic, branch
                int     18h             ; else invoke rom basic
error:
                jmp     prompt          ; reissue prompt
;
;               A valid function key was depressed (or defaulted)
;               Attempt to boot the corresponding partition.
;
system:
                mov     key,AL          ; save function key number
                dec     AL              ; subtract for offset
                sub     AL,Numeric      ; convert to binary
                mov     AH,SIZE PartData ; Get entry size
                mul     AH              ; Get offset
                mov     BX,AX           ; move to usable register
                mov     AL,part.partition[BX] ; get partition number
                dec     AL              ; subtract for offset
                mov     BL,SIZE PartitionEntry ; Get entry size
                mul     BL              ; Get offset
                mov     BX,AX           ; move to usable register
;
;               Only boot bootable partitions.
;
check:
                cmp     partitionTable.BootIndicator[BX],0
                                        ; bootable partition?
                je      error           ; No - display menu again
;
;               Read in and validate the partition's boot sector.
;
select:
                mov     DH,partitionTable.BeginHead[BX]
                                        ; head from partition table
                mov     DL,80h          ; drive 0
                mov     CL,partitionTable.BeginSector[BX]
                                        ; sector from table
                mov     CH,partitionTable.BeginCyl[BX]
                                        ; cylinder from partition table
                push    BX              ; Save index
                les     BX,DWORD PTR PrimBoot ; address primary boot loc
                mov     AX,201h         ; function, # of sectors
                int     13h             ; read system boot record
                pop     BX              ; Restore index
                jc      error           ; exit if error
                cmp     word ptr ES:510,0aa55h ; test signature
                jne     error           ; reprompt if invalid
;
;               Hide the previously booted partition and unhide the
;               partition to be booted.
;
                mov     AL,key          ; get depressed key number
                mov     DL,default      ; get last booted
                mov     default,AL      ; save Function key number
                mov     DI,defaultPart  ; Get default index
                mov     defaultPart,BX  ; Save new index
                cmp     DL,'?'          ; any default?
                je      SetCurrent      ; no - Only set up current
                cmp     AL,DL           ; current = default?
                je      EndBoot         ; yes - skip reset
                mov     AL,partitionTable.SystemId[DI]
                                        ; Get partition type
                mov     partitionTable.BootIndicator[DI],AL
                                        ; Save as boot indicator
                mov     partitionTable.SystemId[DI],80h
                                        ; Booted part. won't see it now
SetCurrent:
                mov     AL,partitionTable.BootIndicator[BX]
                                        ; Get partition type
                mov     partitionTable.SystemId[BX],AL
                                        ; Put it where it belongs
                mov     partitionTable.BootIndicator[BX],80h
                                        ; Show partition is bootable
;
;               Clear the screen, update the boot sector with new
;               values, and give control to the partitions boot program
;
EndBoot:
                call    Clear           ; clear the screen
                mov     AX,301h         ; write sector
                les     BX,DWORD PTR SecBoot ; buffer address
                mov     CX,1            ; cylinder 0, sector 1
                sub     DH,DH           ; head 0
                mov     DL,80h          ; drive 0
                int     13h             ; replace boot record
                cli                     ; disable interrupts
                mov     SI,BootLocation ; get address of area read
                jmp     SI              ; enter second level boot
Clear:
                mov     AH,15           ; return current video mode
                int     10h             ; bios service
                sub     AH,AH           ; set mode
                int     10h             ; reset video mode
                ret
Send:
                cld                     ; reset direction flag
                lodsb                   ; load argument from string
                test    AL,80h          ; test for end of string
                pushf                   ; save flags
                and     AL,7fh          ; insure valid character
                mov     AH,14           ; write tty
                int     10h             ; bios video service
                popf                    ; restore flags
                jz      Send            ; do until end of string
                ret                     ; return to caller

SecBoot         dw      0,NewBootSeg    ; ES=7A0, BX=0
PrimBoot        dw      0,BootSeg       ; ES=7C0, BX=0
FkeyMsg         db      13,10,'F'
key             db      'X . . .',+0A0h
rombasic        db      13,10,'F'
basicKey        db      'X . . . ROM BASIC',13,10,10
                db      'Default: F'
default         db      '?',' '+80h
defaultPart     dw      -1
used            equ     $ - bootany
clearAmt        equ     DataAddr - used ; Assembly error if code too big

                db      clearAmt dup(0) ; clear rest of record

part            PartData max_partitions dup(<>)

bootOpts        BootData <>

partitionTable  PartitionEntry 4 dup(<>)

bootany         endp
code            ends

                end
