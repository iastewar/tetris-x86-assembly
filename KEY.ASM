;----------------------------------------------------------------------------
; CPSC 355 Example Program
; "Empty Project"
; Author:  Sonny Chan
; Date:    May 16, 2001
;----------------------------------------------------------------------------

[GLOBAL mystart]                  ; export the start address
[GLOBAL _myKeyInt]
[GLOBAL _myKeyInt_Size]
[GLOBAL _keyVal]

extern _printf

;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

; out custom keyboard ISR
_myKeyInt:
        push    eax

        ; retrieve a byte from port 0x60 (keyboard input)
        in      al, 0x60
        mov     byte [_keyVal], al

        ; send byte 0x20 to port 0x20 to reset the PIC
        mov     al, 0x20
        out     0x20, al

        pop     eax

        ret

; calculate the size of the ISR
_myKeyInt_Size      dd  $-_myKeyInt

; code belongs in this section starting here

mystart:
        ; while keyVal is 0, keep looping back to mystart
        cmp     byte [_keyVal], 0
        je      mystart

        ; if the code scanned is 0x01 (ESC key), exit
        cmp     byte [_keyVal], 0x01
        je      exit

        ; otherwise, print out the value of the key code
        push    dword [_keyVal]
        push    dword keyMsg
        call    _printf
        add     esp, 8

        ; reset keyVal to 0
        mov     dword [_keyVal], 0
        jmp     mystart

exit:        
        ret


;----------------------------------------------------------------------------
[SECTION .data]
;----------------------------------------------------------------------------
keyMsg      db      "read: %x", 13, 10, 0
_keyVal     dd      0
; all initialized data variables and constant definitions go here


;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------

; all uninitialized data elements go here

