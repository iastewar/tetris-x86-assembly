;----------------------------------------------------------------------------
; CPSC 355 Example Program
; "Empty Project"
; Author:  Sonny Chan
; Date:    May 16, 2001
;----------------------------------------------------------------------------

[GLOBAL mystart]                  ; export the start address
[GLOBAL _myMouseInt]
[GLOBAL _myMouseInt_Size]
[GLOBAL _mouseVal]
[GLOBAL _mouseCount]

extern _printf

;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

; out custom mouseboard ISR
_myMouseInt:
        push    eax

        ; retrieve a byte from port 0x60 (mouseboard input)
        in      al, 0x60
        mov     byte [_mouseVal], al

        ; increment mouseCount % 3
        inc     dword [_mouseCount]
        cmp     dword [_mouseCount], 3
        jne     .continue
        mov     dword [_mouseCount], 0
        
.continue:
        ; send byte 0x20 to port 0x20 and 0xA0
        ; to reset the master & slave PIC
        mov     al, 0x20

        out     0xA0, al
        out     0x20, al

        pop     eax

        ret

; calculate the size of the ISR
_myMouseInt_Size      dd  $-_myMouseInt

; code belongs in this section starting here

mystart:
        ; set last mouseCount to 2 (initial value)
        mov     ebx, 2
        
mouseLoop:
        movzx   ecx, byte [_mouseVal]
        mov     edx, dword [_mouseCount]

        ; while mouseCount (edx) equals the last mouseCount (ebx),loop
        cmp     edx, ebx
        je      mouseLoop

        pushad

        ; otherwise, print out the value of the mouse code
        push    ecx
        push    edx
        push    dword mouseMsg
        call    _printf
        add     esp, 12

        popad

        ; exit if both L and R buttons are pressed
        ; ie: (count == 0) && (code & 0x03 == 0x03)
        cmp     edx, 0
        jne     .continue

        and     ecx, 0x03
        cmp     ecx, 0x03

        je      exit

.continue:
        ; set last mouseCount (ebx) to current mouseCount (edx)
        mov     ebx, edx

        jmp     mouseLoop
        
exit:        
        ret


;----------------------------------------------------------------------------
[SECTION .data]
;----------------------------------------------------------------------------
mouseMsg        db      "read (%d): %x", 13, 10, 0
_mouseVal       dd      0
_mouseCount     dd      2
; all initialized data variables and constant definitions go here


;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------

; all uninitialized data elements go here

