;----------------------------------------------------------------------------
; Moving a shape on screen; demonstrates defining ISRs for hardware interrupts
; needs to be linked with utilprocs.asm
; author: Jalal Kawash
;----------------------------------------------------------------------------

[GLOBAL mystart]                  
[EXTERN drawRect]
[EXTERN drawTriangle]
[EXTERN transRight]
[EXTERN setupXGA]
[EXTERN cleanXGA]
[EXTERN lock_mem]
[EXTERN install_handler]
[EXTERN remove_handler]

%define QUIT 1
%define RIGHT 2

;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

mystart:

         push dword newInt9
         push dword endNewInt9
         call lock_mem  ; lock code in newInt9

         push dword action
         push dword endData
         call lock_mem ; lock variable action used by newInt9

         push dword newInt9 ; address of new handler
         call install_handler

         call setupXGA

         ; draw a rectangle
         push dword 50; color
         push dword 500 ; xlength
         push dword 100 ; ylength
         push dword 100 ; y
         push dword 200 ; x       
         call drawRect

         ; draw a fancy shape with triangles
         mov edi, 60 ; starting color
         mov ecx, 70 ; number of triangles
         mov eax, 50 ; side length
         mov edx, 5  ; x
         mov ebx, 5  ; y

fancy:
         push dword edi ; color
         push dword eax ; length
         push dword edx ; y
         push dword ebx ; x
         call drawTriangle
         add eax, 5
         add ebx, 5
         add edx, 5
         add edi, 1
         
         loop fancy


         mov byte [action], 0

nextKey:

         cmp byte [action], RIGHT
         je moveRight
         cmp byte [action], QUIT
         je done
         ; rest of case statement
         jmp nextKey

moveRight:
         mov byte [action], 0 ; reset action
         call transRight
         jmp nextKey

done:
        call cleanXGA

        call remove_handler

        ret
;----------------------------------------------------------------------------
; Procedures
;----------------------------------------------------------------------------

;
; newInt9() : new ISR 9
;

newInt9:
        enter 0,0
        push eax

        in al, 60h
        cmp al, 10h
        je storeQuit
        cmp al, 1h
        je storeQuit
        cmp al, 4Dh
        je storeRight
        jmp clearPIC

storeRight:
        mov byte [action], RIGHT
        jmp clearPIC

storeQuit:
        mov byte [action], QUIT

clearPIC:
        ; clear PIC
        mov al, 20h
        out 20h, al

        pop eax
        leave
        iret ; watch out: must be iret
;endProc

endNewInt9:     ; dummy label to mark end of newInt9 in memory




;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------

action resb 1                    ; action assigned by new interrupt
endData resb 1                   ; dummy to mark end of data section for locking



