;----------------------------------------------------------------------------
; Defines some procedures to be used externally
; author: Jalal Kawash
;----------------------------------------------------------------------------

[GLOBAL drawRect]
[GLOBAL drawTriangle]
[GLOBAL transRight]
[GLOBAL setupXGA]
[GLOBAL cleanXGA]
[GLOBAL waitForKey]
[GLOBAL lock_mem]
[GLOBAL install_handler]
[GLOBAL remove_handler]                 


%define XGAMODE   4105h               ; XGA video mode code (w/ linear addr bit)
%define XGAXRES   1024                ; horizontal resolution of XGA screen
%define XGAYRES   768                ; vertical resolution of XGA screen



;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

;
; PROC drawTriangle(x, y, length, color)
;

drawTriangle:
         enter 0, 0
         pushad
         ; calculate pixel offset for (x,y)
         mov eax, [ebp+12]
         mov ebx, XGAXRES
         mul ebx
         add eax, [ebp+8]               ; element offset = (y*width)+x
         mov ebx, eax             ; save point

         mov ecx, [ebp+16]          ; length of rect
         mov edx, ecx
drawT:
         mov dl, [ebp+20] ; color
         mov byte [es:eax], dl    ; draw  vertical side
         mov byte [es:ebx], dl ; draw horizontal side
         mov byte [es:(eax+ecx)], dl  ; draw oblique side
         
         inc ebx
         add eax, XGAXRES
         loop drawT

         popad
         leave
         ret 16 ; 4 arguments
;endProc


;
; PROC drawRect(x, y, ylength, xlength, color)
;

drawRect:
         enter 0, 0
         pushad
         ; calculate pixel offset
         mov eax, [ebp+12] ; y
         mov ebx, XGAXRES
         mul ebx
         add eax, [ebp+8]               ; element offset = (y*width)+x
         

         mov ebx, 0               ; ebx counts number of rows
init:                             ; ecx counts the number of horiz pixels
         mov ecx, [ebp+20]          
drawR:                             ; draw one horiz line
         mov dl, [ebp+24]
         mov byte [es:eax], dl
         inc eax
         loop drawR

         sub eax, [ebp+20]           ; move cursor back to begining of rect
         add eax, XGAXRES         ; move one row down
         inc ebx
         cmp ebx, [ebp+16]
         jle init                  ; stop when number of rows is above length
                                  ; otherwise, fill a new row

         popad
         leave
         ret 20 ; 5 arguments
;endProc

;
; PROC transRight()
;

transRight:
         enter 0, 0
         pushad

         mov edi, XGAXRES - 1 ; x of far-right pixel

         ; calculate pixel offset for (x,y)
         mov eax, 0 ; eax = y = 0
         add eax, edi ; element offset = (y*width)+x
         mov edi, eax ; save point offset in edx

transLoop:         
         mov bl, [es:eax] ; save far-most right pixel
         ; what happens if you comment out the previous line
         ; and the line that moves bl back to [es:eax] below?
         mov ecx, XGAXRES - 1 ; loop counter
moveRow: ; translate one row
         mov dl, [es:eax -1]
         mov [es:eax], dl ; translate one pixel to the right
         dec eax ; move to the previous pixel in the row
         loop moveRow

         mov [es:eax], bl ; move far-most right pixel to far-most left

         add edi, XGAXRES ; move one row down
         mov eax, edi
         cmp edi, XGAXRES*XGAYRES
         jl transLoop


         popad
         leave
         ret
;endProc

;
; Proc setupXGA()
;
setupXGA:
         enter 0,0
         mov  ah, 0fh             ; BIOS function - get current video mode
         int  10h                 ; call BIOS video interrupt
         mov  [vidmode], al       ; save the current video mode
         mov  eax, 4f02h          ; SVGA function - set SVGA video mode
         mov  ebx, XGAMODE        ; select XGA video mode
         int  10h                 ; call BIOS video interrupt
        
         mov  ax, fs              ; put the selector for the frame buffer
         mov  es, ax              ; (currently in FS) into ES
         leave
         ret
;endProc

;
; Proc waitForKey()
;
waitForKey:
         enter 0, 0
         push eax
         mov  ah, 1               ; select DOS function - input character
         int  0f1h                ; call OS function to wait for key press
         pop eax
         leave
         ret
;endProc

;
; Proc cleanXGA()
;
cleanXGA:
         enter 0, 0
         mov  ah, 00h             ; BIOS function - set video mode
         mov  al, [vidmode]       ; restore the old video mode
         int  10h                 ; call BIOS video interrupt
         leave
         ret
;endProc

;----------------------------------------------------------------------------
; procedures for interrupt handeling
;____________________________________________________________________________

;
; Proc lock_mem(start_address, end_address)
; locks a memory region from start_address to end_address
;

lock_mem:
         enter 0,0
         pushad
         ; lock mem section
         mov   ax, 0006h          ; select DPMI function get segment base
         mov   bx, cs             ; of CS
         int   31h
         shl   ecx, 16
         mov   cx, dx             ; then use it to lock region in memory
         add   ecx, [ebp+8]
         mov   ebx, ecx
         shr   ebx, 16
         mov   esi, [ebp+12]
         sub   esi, [ebp+8]
         mov   edi, esi
         shr   esi, 16
         mov   ax, 0600h          ; with DPMI function lock linear region
         int   31h

         popad
         leave
         ret 8


;
; Proc install_handler(handler_address)
; installs the new handler into INT 9H, saving the oldhandler's address.
;

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
         mov   edx, [ebp+8]       ; and our handler's offset
         int   31h
         popad
         leave
         ret 4

;
; Proc remove_handler()
; restores old handler
;

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
[SECTION .bss]
;----------------------------------------------------------------------------

vidmode  resb 1                   ; the old video mode
oldhsel resw 1                   ; the old handler's selector
oldhoff resd 1                   ; the old handler's offset




