;----------------------------------------------------------------------------
; keyboard interrupt demo; demonstrates defining ISRs for hardware interrupts
; author: Jalal Kawash
;----------------------------------------------------------------------------

[GLOBAL mystart]                  ; export the start address
[EXTERN _itoa]
[EXTERN _printf]

%macro printMsg 1
        mov ah, 09h
        mov edx, %1
        int 0f1h
%endmacro

;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

mystart:

        printMsg pressKey

top1:
        call testKB
        cmp al, 'q'
        jne top1

        ; note how keyboard is working normally
        ; before we change the ISR 9

        call lock_mem
        printMsg installing
        call install_handler
        printMsg installed

        ; now that a new ISR 9 is installed, the keyboard
        ; is no longer functioning as it should be
        ; the next loop simply prints the raw codes of keys
        ; it can be broken by the ESC or UP keys

        printMsg pressKey1
        mov dl, 0

read:          ; wait until a new key is pressed
        cmp [raw_key], dl
        je read

        ;convert raw key to hex
        push ebp
        mov ebp, esp
        push dword 16 ; radix
        push dword string
        push dword [raw_key]
        call _itoa
        mov esp, ebp
        pop ebp

        ; printf("(%s)",string)
        push ebp
        mov ebp, esp
        push dword string
        push dword formatString
        call _printf
        mov esp, ebp
        pop ebp


        mov dl, [raw_key]
        cmp dl, 01h ; escape key
        je done
        cmp dl, 048h ; second byte of up arrow key
        je done
        jmp read
done:
        call remove_handler

        ; old handler is removed, keyboard functions as it should be again

        printMsg uninstalled
        printMsg pressKey
top2:
        call testKB
        cmp al, 'q'
        jne top2


         ret
;----------------------------------------------------------------------------
; Procedures
;----------------------------------------------------------------------------

;
; testKB() ; returns a char in al
;
testKB:
        enter 0, 0

        ; read char from KB
        mov ah, 1
        int 0f1h ; char in al

        leave
        ret


;
; newInt9() : new ISR 9
;

newInt9:
        enter 0,0
        push eax

        in al, 60h
        mov [raw_key], al

        ; clear PIC
        mov al, 20h
        out 20h, al

        pop eax
        leave
        iret ; watch out: must be iret
;endProc

endNewInt9:     ; dummy label to mark end of newInt9 in memory


;----------------------------------------------------------------------------
; Function to lock the portal handler's code so that it won't be paged out.

lock_mem:
         enter 0,0
         pushad
         ; lock code section
         mov   ax, 0006h          ; select DPMI function get segment base
         mov   bx, cs             ; of CS
         int   31h
         shl   ecx, 16
         mov   cx, dx             ; then use it to lock our handler code
         add   ecx, newInt9
         mov   ebx, ecx
         shr   ebx, 16
         mov   esi, endNewInt9 - newInt9
         mov   edi, esi
         shr   esi, 16
         mov   ax, 0600h          ; with DPMI function lock linear region
         int   31h

         ;lock data section
         mov   ax, 0006h          ; select DPMI function get segment base
         mov   bx, cs             ; of CS
         int   31h
         shl   ecx, 16
         mov   cx, dx             ; then use it to lock our data
         add   ecx, raw_key
         mov   ebx, ecx
         shr   ebx, 16
         mov   esi, endData - raw_key
         mov   edi, esi
         shr   esi, 16
         mov   ax, 0600h          ; with DPMI function lock linear region
         int   31h


         popad
         leave
         ret


;----------------------------------------------------------------------------
; Procedure to install the new handler into INT 9H, saving the old
; handler's address.

install_handler:
         enter 0,0
         pushad
         mov   ax, 204h           ; use DPMI function get interrupt vector
         mov   bl, 9h           ; for INT 9H, available for application
         int   31h
         mov   [oldhsel], cx      ; store the old handler's selector
         mov   [oldhoff], edx     ; and offset

         mov   ax, 205h           ; use DPMI function set interrupt vector
         mov   bl, 9h             ; for INT 9H
         mov   cx, cs             ; put our CS as selector
         mov   edx, newInt9       ; and our handler's offset
         int   31h
         popad
         leave
         ret

;----------------------------------------------------------------------------
; Function that restores the old INT 9H handler's address into the IVT.

remove_handler:
         enter 0,0
         pushad
         mov   ax, 205h           ; use DPMI function set interrupt vector
         mov   bl, 09h           ; for INT 09H
         mov   cx, [oldhsel]      ; putting the old handler's selector
         mov   edx, [oldhoff]     ; and offset back
         int   31h
         popad
         leave
         ret

;----------------------------------------------------------------------------
[SECTION .data]
;----------------------------------------------------------------------------

pressKey db "Press any key, or q to quit", 10, 13, '$'
pressKey1 db "Press any key; use ESC or UP to quit", 10, 13, '$'
installing db "Installing new handler ...", 10, 13, '$'
installed db "New handler is installed!", 10, 13, '$'
uninstalled db "New handler uninstalled successfuly!", 10, 13, '$'
formatString db "(%s)", 0


;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------

; all uninitialized data elements go here

string  resb 17
oldhsel resw 1                   ; the old handler's selector
oldhoff resd 1                   ; the old handler's offset
raw_key resb 1                   ; raw key read from keyboard
endData resb 1



