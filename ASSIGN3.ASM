;----------------------------------------------------------------------------
; CPSC 359
; "Assignment 3"
; Author:  Ian Stewart
;          10045484
; Date:    November 16, 2012
;----------------------------------------------------------------------------


extern _rand
extern _srand
extern _time
extern _printf

[GLOBAL mystart]

%define XSTART 512              ; starting coordinates of shape
%define YSTART 25
%define SQUAREWIDTH 40          ; size of squares in shapes (each shape consists of 4 squares)
%define GAMEWIDTH 400           ; width of the game space (GAMEWIDTH / SQUAREWIDTH = max number of squares on x axis)
%define BOXTHICKNESS 10         ; thickness of box
%define BOXCOLOR 7              ; color of box
%define GAMELENGTH 720          ; length of the game space
%define XGAMODE 4105h           ; XGA video mode code (w/ linear addr bit)
%define XGAXRES 1024            ; horizontal resolution of XGA screen
%define XGAYRES 768
%define LEVEL 4                 ; number pixels shape moves at every iteration. Must be a facter of SQUAREWIDTH and length of box - thickness of box. (eg. change to 1 or 2 for slower movement, 5 medium, 10 for extremely fast)
%define QUIT 1
%define ENT 2
%define RIGHT 3
%define LEFT 4
%define UP 5
%define DOWN 6

%macro setupXGA 0
         mov  ah, 0fh             ; BIOS function - get current video mode
         int  10h                 ; call BIOS video interrupt
         mov  [vidmode], al       ; save the current video mode
         mov  eax, 4f02h          ; SVGA function - set SVGA video mode
         mov  ebx, XGAMODE        ; select XGA video mode
         int  10h                 ; call BIOS video interrupt
%endmacro

%macro cleanXGA 0
         mov  ah, 00h             ; BIOS function - set video mode
         mov  al, [vidmode]       ; restore the old video mode
         int  10h                 ; call BIOS video interrupt
%endmacro

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

         setupXGA

         push dword 0     ; srand (time(NULL));
         call _time
         add esp, 4
         push dword eax
         call _srand
         add esp, 4

         push dword BOXTHICKNESS  ; thickness
         push dword BOXCOLOR ; color
         push dword GAMEWIDTH+BOXTHICKNESS ; width is GAMEWIDTH+thickness
         push dword GAMELENGTH+BOXTHICKNESS ; length is GAMELENGTH+thickness
         push dword YSTART-BOXTHICKNESS ; y value is at YSTART-thickness
         push dword XSTART-(GAMEWIDTH+BOXTHICKNESS)/2-5 ; x value is at XSTART-width/2-5
         call drawBox
         call waitVRetrace
         call blitDBuff

         mov byte [action], 0
waitKeyPress:                    ; wait for enter or arrow key to start
         cmp byte [action], 0
         je waitKeyPress
         cmp byte [action], QUIT ; if escape is pressed, quit
         je near end

mainLoop:
         mov eax, YSTART
         mov ebx, XGAXRES
         mul ebx
         add eax, XSTART
         cmp byte [dBuff + eax], 0  ;see if starting coordinates are empty
         jne near end

         ;get random number. If 0 draw and move I, 1 draw and move J, 2 draw and move L, ...
         call getRandom
         cmp eax, 0
         jne J

         push dword 11 ; color cyan
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH-SQUAREWIDTH ; x
         call drawI

         push dword 11 ; color cyan
         push dword SQUAREWIDTH
         push dword SQUAREWIDTH
         push dword YSTART
         push dword XSTART-SQUAREWIDTH-SQUAREWIDTH
         push dword YSTART
         push dword XSTART-SQUAREWIDTH
         push dword YSTART
         push dword XSTART
         push dword YSTART
         push dword XSTART+SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je near end

         jmp mainLoop    ; loop

J:
         cmp eax, 1
         jne L


         push dword 1 ;color low blue
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         call drawJ

         push dword 1 ;color low blue
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         push dword YSTART+SQUAREWIDTH
         push dword XSTART-SQUAREWIDTH
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART+SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je near end

         jmp mainLoop

L:
         cmp eax, 2
         jne O

         push dword 42 ;color orange
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART+SQUAREWIDTH ; x
         call drawL

         push dword 42 ;color orange
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART+SQUAREWIDTH ; x
         push dword YSTART+SQUAREWIDTH
         push dword XSTART+SQUAREWIDTH
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART-SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je near end

         jmp mainLoop

O:
         cmp eax, 3
         jne S

         push dword 14 ;color yellow
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         call drawO

         push dword 14 ;color yellow
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         push dword YSTART+SQUAREWIDTH
         push dword XSTART-SQUAREWIDTH
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART
         push dword XSTART
         call moveShape
         cmp eax, 1
         je near end

         jmp mainLoop

S:
         cmp eax, 4
         jne T

         push dword 10 ;color green
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART ; x
         call drawS

         push dword 10 ;color green
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART ; x
         push dword YSTART
         push dword XSTART+SQUAREWIDTH
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART-SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je near end

         jmp mainLoop

T:
         cmp eax, 5
         jne Z

         push dword 35 ;color purple
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART ; x
         call drawT

         push dword 35 ;color purple
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART ; x
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART-SQUAREWIDTH
         push dword YSTART+SQUAREWIDTH
         push dword XSTART+SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je end

         jmp mainLoop

Z:
         push dword 40 ;color red
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         call drawZ

         push dword 40 ;color red
         push dword SQUAREWIDTH ; width
         push dword SQUAREWIDTH ; length
         push dword YSTART ; y
         push dword XSTART-SQUAREWIDTH ; x
         push dword YSTART
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART
         push dword YSTART+SQUAREWIDTH
         push dword XSTART+SQUAREWIDTH
         call moveShape
         cmp eax, 1
         je end

         jmp mainLoop

end:
         cleanXGA

         call remove_handler

         push dword [lineCount]
         push dword linesClearedString
         call _printf
         add esp, 8
         

         ret

;---------------------------------------
; Procedures for intertupt handling


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

;
; newInt9() : new ISR 9
;
newInt9:
        enter 0,0
        push eax

        in al, 60h
        cmp al, 1h
        je storeQuit
        cmp al, 1Ch
        je storeEnter
        cmp al, 4Dh
        je storeRight
        cmp al, 50h
        je storeDown
        cmp al, 4Bh
        je storeLeft
        cmp al, 48h
        je storeUp
        jmp clearPIC

storeUp:
        mov byte [action], UP
        jmp clearPIC

storeLeft:
        mov byte [action], LEFT
        jmp clearPIC

storeDown:
        mov byte [action], DOWN
        jmp clearPIC

storeRight:
        mov byte [action], RIGHT
        jmp clearPIC

storeEnter:
        mov byte [action], ENT
        jmp clearPIC

storeQuit:
        mov byte [action], QUIT

clearPIC:
        ; clear PIC
        mov al, 20h
        out 20h, al

        pop eax
        leave
        iret
;endProc

endNewInt9:     ; dummy label to mark end of newInt9 in memory
;---------------------------------------

;
; PROC getRandom()
;
getRandom:
         enter 0,0
         push ecx
         push edx


         call _rand        ; return rand() % 7;
         mov edx, 0
         mov ecx, 7
         div ecx
         mov eax, edx

         pop edx
         pop ecx
         leave
         ret

;
; PROC waitVRetrace()
;
; wait for vertical retrace phase
waitVRetrace:
        enter 0,0
        pushad

        ; input port (need to use dx when port > 255)
        mov     dx, 0x3DA

waitVRetraceLoop1:
        ; read byte from 0x3DA
        in      al, dx

        ; keep looping while 4th bit is set
        and     al, 0x08
        cmp     al, 0
        jne     waitVRetraceLoop1

waitVRetraceLoop2:
        ; read byte from 0x3DA
        in      al, dx

        ; keep looping while 4th bit is clear
        and     al, 0x08
        cmp     al, 0
        je      waitVRetraceLoop2

        popad

        leave
        ret

;
; PROC pseudoBlitDBuff(start coordinate, number of bytes to move)
;
; copy a portion of double buffer to LFB
pseudoBlitDBuff:
        enter 0,0
        pushad

        ; set count to second parameter
        mov ecx, [ebp+12]

        mov bx, es
        
        ; set es to LFB (fs)
        mov ax, fs
        mov es, ax

        ; set destination to LFB (start coordinate)
        mov edi, [ebp+8]

        ; set source to double buffer (start coordinate)
        mov edx, [ebp+8]
        add edx, dBuff
        mov esi, edx
        
        cld
        rep movsb

        ; restore es
        mov es, bx


        popad
        leave
        ret 8

;
; PROC blitDBuff()
;
; copy double buffer to LFB
blitDBuff:
        enter 0,0
        pushad

        ; set count to size of LFB (and double buffer)
        mov     ecx, (XGAXRES * XGAYRES)

        ; preserve es in bx
        mov     bx, es

        ; set es to LFB (fs)
        mov     ax, fs
        mov     es, ax

        ; set destination to beginning of LFB (0)
        mov     edi, 0
        ; and source to beginning of double buffer
        mov     esi, dBuff

        ; clear df to move forward
        cld

        ; copy the double buffer to LFB
        rep     movsb

        ; restore es
        mov     es, bx

        popad

        leave
        ret

;
; PROC drawBox(x, y, length, width, color, thickness)
;
drawBox
          enter 0,0
          push eax

          push dword [ebp+24] ; color
          push dword [ebp+20] ; width
          push dword [ebp+28] ; length (thickness)
          push dword [ebp+12] ; y
          push dword [ebp+8]  ; x
          call drawRect       ; draw top

          push dword [ebp+24]
          mov eax, [ebp+20]
          add eax, [ebp+28]
          push dword eax      ; width + thickness
          push dword [ebp+28]
          mov eax, [ebp+12]   ; y + length
          add eax, [ebp+16]
          push dword eax
          push dword [ebp+8]
          call drawRect       ; draw bottom

          push dword [ebp+24]
          push dword [ebp+28]
          push dword [ebp+16]
          push dword [ebp+12]
          push dword [ebp+8]
          call drawRect       ; draw left

          push dword [ebp+24]
          push dword [ebp+28]
          push dword [ebp+16]
          push dword [ebp+12]
          mov eax, [ebp+8]
          add eax, [ebp+20]
          push dword eax
          call drawRect       ; draw right

          pop eax
          leave
          ret 24



; All shapes are made up of 4 rectangles and the length and width
; parameters specify the length and width of one of four rectangles. Even though
; the shapes need fewer than 4 drawRect calls, I still implemented them in this fashion
; for consistency. The x and y parameters specify the top left-hand pixel of the shape.

;
; PROC drawI(x, y, length, width, color)
;
drawI:
         enter 0,0
         push eax

         mov eax, [ebp+20]
         mov ebx, 4
         mul ebx             ; width of I in eax

         push dword [ebp+24] ; color
         push dword eax      ; width*4
         push dword [ebp+16]  ; length
         push dword [ebp+12]  ; y
         push dword [ebp+8]  ; x
         call drawRect

         call waitVRetrace
         call blitDBuff

         pop eax
         leave
         ret 20

;
; PROC drawJ(x, y, length, width, color)
;
drawJ:
         enter 0,0
         push eax
         push ebx

         push dword [ebp+24] ; color
         push dword [ebp+20] ; width
         push dword [ebp+16] ; length
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect ; draw top left

         mov eax, [ebp+20]
         mov ebx, 3
         mul ebx              ; width of bottom 3 rectangles

         push dword [ebp+24] ; color
         push dword eax      ; width*3
         push dword [ebp+16] ; length

         mov eax, [ebp+12]
         mov ebx, [ebp+16]
         add eax, ebx        ; y + length

         push dword eax  ; y + length
         push dword [ebp+8] ; x
         call drawRect ; draw bottom 3 rectangles

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20

;
; PROC drawL(x, y, length, width, color)
;
drawL:
         enter 0,0
         push eax
         push ebx

         push dword [ebp+24] ; color
         push dword [ebp+20] ; width
         push dword [ebp+16] ; length
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect ; draw top left

         mov eax, [ebp+20]
         mov ebx, 3
         mul ebx              ; width of bottom 3 rectangles

         push dword [ebp+24] ; color
         push dword eax      ; width*3
         push dword [ebp+16] ; length

         mov eax, [ebp+12]
         mov ebx, [ebp+16]
         add eax, ebx        ; y + length

         push dword eax

         mov eax, [ebp+8]
         mov ebx, [ebp+20]
         add ebx, ebx
         sub eax, ebx      ; x - 2*width

         push dword eax
         call drawRect ; draw bottom 3 rectangles

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20

;
; PROC drawO(x, y, length, width, color)
;
drawO:
         enter 0,0
         push eax
         push ebx

         mov eax, [ebp+16]
         add eax, eax        ; length*2 in eax
         mov ebx, [ebp+20]
         add ebx, ebx        ; width*2 in ebx

         push dword [ebp+24] ; color
         push dword ebx      ; width*2
         push dword eax      ; length*2
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20

;
; PROC drawS(x, y, length, width, color)
;
drawS:
         enter 0,0
         push eax
         push ebx

         mov eax, [ebp+20]
         add eax, eax        ;width*2 in eax

         push dword [ebp+24] ; color
         push dword eax      ; width*2
         push dword [ebp+16]  ; length
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect     ; draw top 2 rectangles

         push dword [ebp+24] ; color
         push dword eax      ; width*2
         push dword [ebp+16] ; length

         mov eax, [ebp+12]
         mov ebx, [ebp+16]
         add eax, ebx        ; y + length

         push dword eax

         mov eax, [ebp+8]
         mov ebx, [ebp+20]
         sub eax, ebx      ; x - width

         push dword eax
         call drawRect    ; draw bottom 2 rectangles

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20

;
; PROC drawT(x, y, length, width, color)
;
drawT:
         enter 0,0
         push eax
         push ebx

         push dword [ebp+24] ; color
         push dword [ebp+20] ; width
         push dword [ebp+16] ; length
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect ; draw top rectangle

         mov eax, [ebp+20]
         mov ebx, 3
         mul ebx              ; width of bottom 3 rectangles

         push dword [ebp+24] ; color
         push dword eax      ; width*3
         push dword [ebp+16] ; length

         mov eax, [ebp+12]
         mov ebx, [ebp+16]
         add eax, ebx        ; y + length

         push dword eax

         mov eax, [ebp+8]
         mov ebx, [ebp+20]
         sub eax, ebx      ; x - width

         push dword eax
         call drawRect ; draw bottom 3 rectangles

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20

;
; PROC drawZ(x, y, length, width, color)
;
drawZ:
         enter 0,0
         push eax
         push ebx

         mov eax, [ebp+20]
         add eax, eax        ;width*2 in eax

         push dword [ebp+24] ; color
         push dword eax      ; width*2
         push dword [ebp+16]  ; length
         push dword [ebp+12] ; y
         push dword [ebp+8] ; x
         call drawRect     ; draw top 2 rectangles

         push dword [ebp+24] ; color
         push dword eax      ; width*2
         push dword [ebp+16] ; length

         mov eax, [ebp+12]
         mov ebx, [ebp+16]
         add eax, ebx        ; y + length

         push dword eax

         mov eax, [ebp+8]
         mov ebx, [ebp+20]
         add eax, ebx      ; x + width

         push dword eax
         call drawRect    ; draw bottom 2 rectangles

         call waitVRetrace
         call blitDBuff

         pop ebx
         pop eax
         leave
         ret 20


;
; PROC drawRect(x, y, length, width, color)
;
drawRect:
         enter 0, 0
         pushad
         ; calculate pixel offset
         mov eax, [ebp+12] ; y
         shl eax, 10           ; eax * 1024 (xres)
         add eax, [ebp+8]               ; element offset = (y*width)+x


         mov ebx, 0               ; ebx counts number of rows
init:                             ; ecx counts the number of horiz pixels
         mov ecx, [ebp+20]
draw:                             ; draw one horiz line
         mov dl, [ebp+24]
         mov byte [dBuff + eax], dl
         inc eax
         loop draw

         sub eax, [ebp+20]           ; move cursor back to begining of rect
         add eax, XGAXRES         ; move one row down
         inc ebx
         cmp ebx, [ebp+16]
         jl init                  ; stop when number of rows is above length
                                  ; otherwise, fill a new row

         popad
         leave
         ret 20 ; 5 arguments

;
; PROC moveShape(x1, y1, x2, y2, x3, y3, x4, y4, length, width, color)
; parameters specify the top left coordinate of every square in shape
; returns 1 if escape key is pressed, 0 otherwise
;
moveShape:
         enter 0,0
         push ebx
         push ecx
         push edx
         push edi

         mov byte [action], 0

         mov ecx, 0
         
         mov esi, 999    ; time to wait after shape as been moved all the way to the bottom (makes translating left/right possible for a split second after shape has touched the bottom)

moveShapeLoop:
         cmp byte [action], QUIT
         jne moveShapeLoop2
         mov eax, 1
         jmp moveShapeEnd

moveShapeLoop2:
         cmp byte [action], RIGHT
         jne moveShapeLoop3

         push dword [ebp+48]  ; color
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         mov eax, [ebp+36]    ; get y4 and add to ecx
         add eax, ecx
         push dword eax       ; y4 + ecx
         push dword [ebp+32]  ; x4
         mov eax, [ebp+28]
         add eax, ecx
         push dword eax       ; y3 + ecx
         push dword [ebp+24]  ; x3
         mov eax, [ebp+20]
         add eax, ecx
         push dword eax       ; y2 + ecx
         push dword [ebp+16]  ; x2
         mov eax, [ebp+12]
         add eax, ecx
         push dword eax       ; y1 + ecx
         push dword [ebp+8]   ; x1
         call rightTrans

         mov eax, dword [x1]      ; change x values after translation
         mov dword [ebp+8], eax
         mov eax, dword [x2]
         mov dword [ebp+16], eax
         mov eax, dword [x3]
         mov dword [ebp+24], eax
         mov eax, dword [x4]
         mov dword [ebp+32], eax

moveShapeLoop3:
         cmp byte [action], LEFT
         jne moveShapeLoop4

         push dword [ebp+48]  ; color
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         mov eax, [ebp+36]    ; get y4 and add to ecx
         add eax, ecx
         push dword eax       ; y4 + ecx
         push dword [ebp+32]  ; x4
         mov eax, [ebp+28]
         add eax, ecx
         push dword eax       ; y3 + ecx
         push dword [ebp+24]  ; x3
         mov eax, [ebp+20]
         add eax, ecx
         push dword eax       ; y2 + ecx
         push dword [ebp+16]  ; x2
         mov eax, [ebp+12]
         add eax, ecx
         push dword eax       ; y1 + ecx
         push dword [ebp+8]   ; x1
         call leftTrans
         
         mov eax, dword [x1]      ; change x values after translation
         mov dword [ebp+8], eax
         mov eax, dword [x2]
         mov dword [ebp+16], eax
         mov eax, dword [x3]
         mov dword [ebp+24], eax
         mov eax, dword [x4]
         mov dword [ebp+32], eax

moveShapeLoop4:
         cmp byte [action], UP
         jne moveShapeLoop5

         push dword [ebp+48]  ; color
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         mov eax, [ebp+36]    ; get y4 and add to ecx
         add eax, ecx
         push dword eax       ; y4 + ecx
         push dword [ebp+32]  ; x4
         mov eax, [ebp+28]
         add eax, ecx
         push dword eax       ; y3 + ecx
         push dword [ebp+24]  ; x3
         mov eax, [ebp+20]
         add eax, ecx
         push dword eax       ; y2 + ecx
         push dword [ebp+16]  ; x2
         mov eax, [ebp+12]
         add eax, ecx
         push dword eax       ; y1 + ecx
         push dword [ebp+8]   ; x1
         call rotate
         
         mov eax, dword [x1]      ; change x and y values after rotation
         mov dword [ebp+8], eax
         mov eax, dword [y1]
         sub eax, ecx
         mov dword [ebp+12], eax
         mov eax, dword [x2]
         mov dword [ebp+16], eax
         mov eax, dword [y2]
         sub eax, ecx
         mov dword [ebp+20], eax
         mov eax, dword [x3]
         mov dword [ebp+24], eax
         mov eax, dword [y3]
         sub eax, ecx
         mov dword [ebp+28], eax
         mov eax, dword [x4]
         mov dword [ebp+32], eax
         mov eax, dword [y4]
         sub eax, ecx
         mov dword [ebp+36], eax

moveShapeLoop5:
         mov byte [action], 0

         mov eax, [ebp+36]    ; get y4 and add to ecx
         add eax, ecx

         push dword 0         ; delete shape by coloring it black
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         push dword eax       ; y4 + ecx
         push dword [ebp+32]  ; x4
         call drawRect        ; first square of shape

         shl eax, 10
         mov edi, eax         ;edi contains minimum y value

         mov eax, [ebp+28]    ; y3 + ecx
         add eax, ecx

         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+24]
         call drawRect        ; second square of shape

         shl eax, 10
         cmp eax, edi
         jge moveShapeMinNext ; see if y3 < y4 and move into edi if it is
         mov edi, eax

moveShapeMinNext:
         mov eax, [ebp+20]    ; y2 + ecx
         add eax, ecx

         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+16]
         call drawRect        ; third square of shape

         shl eax, 10
         cmp eax, edi
         jge moveShapeMinNext2 ; y2 < current min ?
         mov edi, eax

moveShapeMinNext2:
         mov eax, [ebp+12]     ; y1 + ecx
         add eax, ecx


         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+8]
         call drawRect         ; last square of shape

         shl eax, 10
         cmp eax, edi
         jge moveShapeMinNext3  ; y1 < current min ?
         mov edi, eax

moveShapeMinNext3:
         mov eax, [ebp+12]    ; y1 + ecx
         add eax, ecx
         add eax, [ebp+40]
         shl eax, 10
         add eax, [ebp+8]   ; (y1+ecx+length) * xres + x1 in eax
         mov edx, eax
         add edx, [ebp+44]  ; (y1+ecx+length) * xres + x1 + width in edx

moveShapeTest
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near moveShapeNext      ; if line below shape is not black then done moving
         inc eax
         cmp eax, edx      ;keep testing while eax < (y1+ecx+length) * xres + x1 + width
         jl moveShapeTest

         mov eax, [ebp+20]   ; y2 + ecx
         add eax, ecx
         add eax, [ebp+40]
         shl eax, 10
         add eax, [ebp+16]   ; (y2+ecx+length) * xres + x2 in eax
         mov edx, eax
         add edx, [ebp+44]  ; (y2+ecx+length) * xres + x2 + width in edx

moveShapeTest2
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near moveShapeNext      ; if line below shape is not black then done moving
         inc eax
         cmp eax, edx      ;keep testing while eax < (y2+ecx+length) * xres + x2 + width
         jl moveShapeTest2

         mov eax, [ebp+28]  ; y3 + ecx
         add eax, ecx
         add eax, [ebp+40]
         shl eax, 10
         add eax, [ebp+24]   ; (y3+ecx+length) * xres + x3 in eax
         mov edx, eax
         add edx, [ebp+44]  ; (y3+ecx+length) * xres + x3 + width in edx

moveShapeTest3
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near moveShapeNext      ; if line below shape is not black then done moving
         inc eax
         cmp eax, edx      ;keep testing while eax < (y3+ecx+length) * xres + x3 + width
         jl moveShapeTest3

         mov eax, [ebp+36]   ; y4 + ecx
         add eax, ecx
         add eax, [ebp+40]
         shl eax, 10
         add eax, [ebp+32]   ; (y4+ecx+length) * xres + x4 in eax
         mov edx, eax
         add edx, [ebp+44]  ; (y4+ecx+length) * xres + x4 + width in edx

moveShapeTest4
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near moveShapeNext      ; if line below shape is not black then done moving
         inc eax
         cmp eax, edx      ;keep testing while eax < (y4+ecx+length) * xres + x4 + width
         jl moveShapeTest4

         add ecx, LEVEL    ; inc ecx by LEVEL

         mov eax, [ebp+36]
         add eax, ecx

         push dword [ebp+48]         ;draw shape at y+1
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+32]
         call drawRect

         mov eax, [ebp+28]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+24]
         call drawRect

         mov eax, [ebp+20]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+16]
         call drawRect

         mov eax, [ebp+12]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+8]
         call drawRect

         ; using the pseudoBlitDBuff function to write to screen
         mov eax, [ebp+40]  ; square width in eax
         shl eax, 10        ; eax * 1024
         shl eax, 2         ; eax * 4

         mov ebx, eax             ; I am using the value XGAXRES*SQUAREWIDTH*4 for speed consistancy beteween all shapes
         add ebx, edi             ; add the minimum y value (*XGAXRES) to XGAXRES*SQUAREWIDTH*4
         cmp ebx, XGAXRES*XGAYRES    ; making sure copying XGAXRES*SQUAREWIDTH*4 bytes is possible
         jle moveShapeGood
         sub ebx, XGAXRES*XGAYRES    ; y + XGAXRES*SQUAREWIDTH*4 - XGAXRES*XGAYRES
         mov edx, eax
         sub edx, ebx                ; XGAXRES*XGAYRES - minY * XGAXRES (number of bytes allowed to copy)
         push dword edx
         jmp moveShapeContinue

moveShapeGood:
         push dword eax           ; push XGAXRES*SQUAREWIDTH*4
moveShapeContinue:
         push dword edi           ; push minimum y * XGAXRES (starting coordinate for pseudoBlitDBuff)
         call waitVRetrace
         call pseudoBlitDBuff
         jmp moveShapeLoop        ; loop

moveShapeNext:
         mov eax, [ebp+36]
         add eax, ecx

         push dword [ebp+48]         ;redraw shape that was deleted at end
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+32]
         call drawRect

         mov eax, [ebp+28]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+24]
         call drawRect

         mov eax, [ebp+20]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+16]
         call drawRect

         mov eax, [ebp+12]
         add eax, ecx

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword eax
         push dword [ebp+8]
         call drawRect
         
         dec esi
         cmp esi, 0
         jg near moveShapeLoop    ; loop back to start until esi is 0

         push dword [ebp+40]
         mov eax, [ebp+36]   ; check if a line was created and remove it
         add eax, ecx
         push dword eax
         mov eax, [ebp+28]
         add eax, ecx
         push dword eax
         mov eax, [ebp+20]
         add eax, ecx
         push dword eax
         mov eax, [ebp+12]
         add eax, ecx
         push dword eax
         call lineCheck

         mov eax, 0

moveShapeEnd:
         pop edi
         pop edx
         pop ecx
         pop ebx
         leave
         ret 44    ; 11 arguments


;
; PROC lineCheck(y1, y2, y3, y4, length)
; parameters specify the y values to check for a line.
; Checks for a line in the tetris game and removes it
;
lineCheck:
         enter 16,0
         pushad
         mov ecx, 0
         
         mov dword [ebp-4], 0
         mov dword [ebp-8], 0
         mov dword [ebp-12], 0
         mov dword [ebp-16], 0

         mov edi, [ebp+8]           ; current y value into edi
         jmp lineCheckMainLoopN4

lineCheckMainLoop:
         cmp ecx, 1
         jne lineCheckMainLoopN2
         mov edi, [ebp+12]
         jmp lineCheckMainLoopN4

lineCheckMainLoopN2:
         cmp ecx, 2
         jne lineCheckMainLoopN3
         mov edi, [ebp+16]
         jmp lineCheckMainLoopN4

lineCheckMainLoopN3:
         cmp ecx, 3
         jne near lineCheckNext
         mov edi, [ebp+20]

lineCheckMainLoopN4:
         mov eax, edi
         shl eax, 10

lineCheckBox:
         inc eax
         cmp byte [dBuff + eax], BOXCOLOR
         jne lineCheckBox

         add eax, BOXTHICKNESS
lineCheckLoop:
         inc eax
         cmp byte [dBuff + eax], 0
         je near lineCheckLoopCounter
         cmp byte [dBuff + eax], BOXCOLOR
         jne lineCheckLoop

         ; line found
         inc dword [lineCount]

         cmp ecx, 0              ; move y value into a local variable to remember it
         jne lineCheckFound1
         mov [ebp-4], edi
         jmp lineCheckFoundC
lineCheckFound1:
         cmp ecx, 1
         jne lineCheckFound2
         mov [ebp-8], edi
         jmp lineCheckFoundC
lineCheckFound2:
         cmp ecx, 2
         jne lineCheckFound3
         mov [ebp-12], edi
         jmp lineCheckFoundC
lineCheckFound3:
         mov [ebp-16], edi

lineCheckFoundC:
         push dword 0 ; color
         push dword XGAXRES
         push dword [ebp+24]
         push dword edi
         push dword 0
         call drawRect       ; delete line

         ; redraw box
         push dword BOXTHICKNESS  ; thickness
         push dword BOXCOLOR ; color
         push dword GAMEWIDTH+BOXTHICKNESS ; width is GAMEWIDTH+thickness
         push dword GAMELENGTH+BOXTHICKNESS ; length is GAMELENGTH+thickness
         push dword YSTART-BOXTHICKNESS ; y value is at YSTART-thickness
         push dword XSTART-(GAMEWIDTH+BOXTHICKNESS)/2-5 ; x value is at XSTART-width/2
         call drawBox

lineCheckLoopCounter:
         inc ecx
         jmp lineCheckMainLoop

lineCheckRedraw:
         ; delete box by coloring it black
         push dword BOXTHICKNESS  ; thickness
         push dword 0 ; color
         push dword GAMEWIDTH+BOXTHICKNESS ; width is GAMEWIDTH+thickness
         push dword GAMELENGTH+BOXTHICKNESS ; length is GAMELENGTH+thickness
         push dword YSTART-BOXTHICKNESS ; y value is at YSTART-thickness
         push dword XSTART-(GAMEWIDTH+BOXTHICKNESS)/2-5 ; x value is at XSTART-width/2
         call drawBox

         mov esi, [ebp+24]
         shl esi, 10

         mov eax, edi
         shl eax, 10
         sub eax, 1

lineCheckDelete:
         mov bl, byte [dBuff + eax]  ; move buffer above line down a line
         mov edx, eax
         add edx, esi                ; esi contains the length of a square
         mov byte [dBuff + edx], bl
         dec eax
         cmp eax, 0
         jge lineCheckDelete

         ; redraw box
         push dword BOXTHICKNESS  ; thickness
         push dword BOXCOLOR ; color
         push dword GAMEWIDTH+BOXTHICKNESS ; width is GAMEWIDTH+thickness
         push dword GAMELENGTH+BOXTHICKNESS ; length is GAMELENGTH+thickness
         push dword YSTART-BOXTHICKNESS ; y value is at YSTART-thickness
         push dword XSTART-(GAMEWIDTH+BOXTHICKNESS)/2-5 ; x value is at XSTART-width/2
         call drawBox

lineCheckNext:
         cmp dword [ebp-4], 0
         je lineCheckNext1
         mov edi, [ebp-4]
         mov dword [ebp-4], 0
         jmp lineCheckRedraw

lineCheckNext1:
         cmp dword [ebp-8], 0
         je lineCheckNext2
         mov edi, [ebp-8]
         mov dword [ebp-8], 0
         jmp lineCheckRedraw

lineCheckNext2:
         cmp dword [ebp-12], 0
         je lineCheckNext3
         mov edi, [ebp-12]
         mov dword [ebp-12], 0
         jmp lineCheckRedraw
         
 lineCheckNext3:
         cmp dword [ebp-16], 0
         je lineCheckNext4
         mov edi, [ebp-16]
         mov dword [ebp-16], 0
         jmp lineCheckRedraw
         
 lineCheckNext4:
         call waitVRetrace
         call blitDBuff
 
         popad
         leave
         ret 20  ; 5 arguments



;
; PROC rotate(x1, y1, x2, y2, x3, y3, x4, y4, length, width, color)
; parameters specify the top left coordinate of every square in shape
; returns the new x and y values in memory locations (x1, y1, x2, y2, ...)
;
rotate:
         enter 0,0
         pushad

         push dword 0         ; delete shape by coloring it black
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         push dword [ebp+36]  ; y4
         push dword [ebp+32]  ; x4
         call drawRect        ; first square of shape

         mov edi, [ebp+36]    ; edi contains minimum y value
         mov esi, [ebp+32]    ; esi contains minimum x value corresponding to minimum y value

         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect        ; second square of shape

         mov eax, [ebp+28]
         cmp eax, edi
         jg rotateMin1
         je rotateEqual1
         mov edi, eax
         mov esi, [ebp+24]

rotateEqual1:
         mov eax, [ebp+24]
         cmp eax, esi
         jge rotateMin1
         mov esi, eax

rotateMin1:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect        ; third square of shape
         
         mov eax, [ebp+20]
         cmp eax, edi
         jg rotateMin2
         je rotateEqual2
         mov edi, eax
         mov esi, [ebp+16]

rotateEqual2:
         mov eax, [ebp+16]
         cmp eax, esi
         jge rotateMin2
         mov esi, eax

rotateMin2:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect         ; last square of shape

         mov eax, [ebp+12]
         cmp eax, edi
         jg rotateMin3
         je rotateEqual3
         mov edi, eax
         mov esi, [ebp+8]

rotateEqual3:
         mov eax, [ebp+8]
         cmp eax, esi
         jge rotateMin3
         mov esi, eax

rotateMin3:                    ; now x0 = esi and y0 = edi
         mov eax, edi
         sub eax, [ebp+12]
         add eax, esi          ; eax = x1new = y0 - y1old + x0

         mov ebx, [ebp+8]
         sub ebx, esi
         add ebx, edi          ; ebx = y1new = x1old - x0 + y0

         add eax, [ebp+44]     ; rotating the shape consistanly moves the shape to the left so must move shape to right to compensate
         mov dword [x1], eax
         mov dword [y1], ebx

         shl ebx, 10
         add ebx, eax
         mov ecx, 0
rotateTestO1:
         mov edx, 0
rotateTestI1:
         mov eax, edx
         shl eax, 10
         add eax, ebx
         add eax, ecx
         cmp eax, 0                 ; make sure eax is within boundries
         jl near rotateNext
         cmp eax, XGAXRES*XGAYRES
         jge near rotateNext
         cmp byte [dBuff + eax], 0  ; see if drawing a square here is possible
         jne near rotateNext
         inc edx
         cmp edx, [ebp+40]
         jl rotateTestI1
         inc ecx
         cmp ecx, [ebp+44]
         jl rotateTestO1

         mov eax, edi
         sub eax, [ebp+20]
         add eax, esi          ; eax = x2new = y0 - y2old + x0

         mov ebx, [ebp+16]
         sub ebx, esi
         add ebx, edi          ; ebx = y2new = x2old - x0 + y0

         add eax, [ebp+44]
         mov dword [x2], eax
         mov dword [y2], ebx

         shl ebx, 10
         add ebx, eax
         mov ecx, 0
rotateTestO2:
         mov edx, 0
rotateTestI2:
         mov eax, edx
         shl eax, 10
         add eax, ebx
         add eax, ecx
         cmp eax, 0                 ; make sure eax is within boundries
         jl near rotateNext
         cmp eax, XGAXRES*XGAYRES
         jge near rotateNext
         cmp byte [dBuff + eax], 0  ; see if drawing a square here is possible
         jne near rotateNext
         inc edx
         cmp edx, [ebp+40]
         jl rotateTestI2
         inc ecx
         cmp ecx, [ebp+44]
         jl rotateTestO2
         
         mov eax, edi
         sub eax, [ebp+28]
         add eax, esi          ; eax = x3new = y0 - y3old + x0

         mov ebx, [ebp+24]
         sub ebx, esi
         add ebx, edi          ; ebx = y3new = x3old - x0 + y0

         add eax, [ebp+44]
         mov dword [x3], eax
         mov dword [y3], ebx

         shl ebx, 10
         add ebx, eax
         mov ecx, 0
rotateTestO3:
         mov edx, 0
rotateTestI3:
         mov eax, edx
         shl eax, 10
         add eax, ebx
         add eax, ecx
         cmp eax, 0                 ; make sure eax is within boundries
         jl near rotateNext
         cmp eax, XGAXRES*XGAYRES
         jge near rotateNext
         cmp byte [dBuff + eax], 0  ; see if drawing a square here is possible
         jne near rotateNext
         inc edx
         cmp edx, [ebp+40]
         jl rotateTestI3
         inc ecx
         cmp ecx, [ebp+44]
         jl rotateTestO3

         mov eax, edi
         sub eax, [ebp+36]
         add eax, esi          ; eax = x4new = y0 - y4old + x0

         mov ebx, [ebp+32]
         sub ebx, esi
         add ebx, edi          ; ebx = y4new = x4old - x0 + y0

         add eax, [ebp+44]
         mov dword [x4], eax
         mov dword [y4], ebx

         shl ebx, 10
         add ebx, eax
         mov ecx, 0
rotateTestO4:
         mov edx, 0
rotateTestI4:
         mov eax, edx
         shl eax, 10
         add eax, ebx
         add eax, ecx
         cmp eax, 0                 ; make sure eax is within boundries
         jl near rotateNext
         cmp eax, XGAXRES*XGAYRES
         jge near rotateNext
         cmp byte [dBuff + eax], 0  ; see if drawing a square here is possible
         jne near rotateNext
         inc edx
         cmp edx, [ebp+40]
         jl rotateTestI4
         inc ecx
         cmp ecx, [ebp+44]
         jl rotateTestO4


         push dword [ebp+48]    ; draw shape at new coordinates
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [y4]
         push dword [x4]
         call drawRect

         mov edi, [y4]
         shl edi, 10          ;edi contains minimum y value

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [y3]
         push dword [x3]
         call drawRect

         mov eax, [y3]
         shl eax, 10
         cmp eax, edi
         jge rotateMinNext ; see if y3 < y4 and move into edi if it is
         mov edi, eax

rotateMinNext:
         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [y2]
         push dword [x2]
         call drawRect

         mov eax, [y2]
         shl eax, 10
         cmp eax, edi
         jge rotateMinNext2 ; y2 < current min ?
         mov edi, eax

rotateMinNext2:
         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [y1]
         push dword [x1]
         call drawRect

         mov eax, [y1]
         shl eax, 10
         cmp eax, edi
         jge rotateMinNext3 ; y1 < current min ?
         mov edi, eax

rotateMinNext3:
         ; using the pseudoBlitDBuff function to write to screen
         mov eax, [ebp+40]  ; square width in eax
         shl eax, 10        ; eax * 1024
         shl eax, 2         ; eax * 4

         mov ebx, eax             ; I am using the value XGAXRES*SQUAREWIDTH*4 for speed consistancy beteween all shapes
         add ebx, edi             ; add the minimum y value (*XGAXRES) to XGAXRES*SQUAREWIDTH*4
         cmp ebx, XGAXRES*XGAYRES    ; making sure copying XGAXRES*SQUAREWIDTH*4 bytes is possible
         jle rotateGood
         sub ebx, XGAXRES*XGAYRES    ; y + XGAXRES*SQUAREWIDTH*4 - XGAXRES*XGAYRES
         mov edx, eax
         sub edx, ebx                ; XGAXRES*XGAYRES - minY * XGAXRES (number of bytes allowed to copy)
         push dword edx
         jmp rotateContinue

rotateGood:
         push dword eax           ; push XGAXRES*SQUAREWIDTH*4
rotateContinue:
         push dword edi           ; push minimum y * XGAXRES (starting coordinate for pseudoBlitDBuff)
         call waitVRetrace
         call pseudoBlitDBuff         
         jmp rotateEnd

rotateNext:
         push dword [ebp+48]         ;redraw shape that was deleted at end
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+36]
         push dword [ebp+32]
         call drawRect

         mov eax, [ebp+32]
         mov dword [x4], eax
         mov eax, [ebp+36]
         mov dword [y4], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect

         mov eax, [ebp+24]
         mov dword [x3], eax
         mov eax, [ebp+28]
         mov dword [y3], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect

         mov eax, [ebp+16]
         mov dword [x2], eax
         mov eax, [ebp+20]
         mov dword [y2], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect

         mov eax, [ebp+8]
         mov dword [x1], eax
         mov eax, [ebp+12]
         mov dword [y1], eax

rotateEnd:
         popad
         leave
         ret 44    ; 11 arguments

;
; PROC leftTrans(x1, y1, x2, y2, x3, y3, x4, y4, length, width, color)
; parameters specify the top left coordinate of every square in shape
; returns the new x values in memory (x1, x2, x3, x4)
;
leftTrans:
         enter 0,0
         pushad

         push dword 0         ; delete shape by coloring it black
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         push dword [ebp+36]  ; y4
         push dword [ebp+32]  ; x4
         call drawRect        ; first square of shape

         mov edi, [ebp+36]
         shl edi, 10          ;edi contains minimum y value

         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect        ; second square of shape

         mov eax, [ebp+28]
         shl eax, 10
         cmp eax, edi
         jge leftTransMinNext ; see if y3 < y4 and move into edi if it is
         mov edi, eax

leftTransMinNext:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect        ; third square of shape

         mov eax, [ebp+20]
         shl eax, 10
         cmp eax, edi
         jge leftTransMinNext2 ; y2 < current min ?
         mov edi, eax

leftTransMinNext2:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect         ; last square of shape

         mov eax, [ebp+12]
         shl eax, 10
         cmp eax, edi
         jge leftTransMinNext3  ; y1 < current min ?
         mov edi, eax

leftTransMinNext3:
         mov eax, [ebp+12]  ; y1
         shl eax, 10
         add eax, [ebp+8]
         sub eax, 1         ; y1 * xres + x1 - 1 in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax       ; y1 * xres + x1 - 1 + ((length - 1) * xres) in edx

leftTransTest
         cmp byte [dBuff + eax], 0    ; see if pixel is black
         jne near leftTransNext      ; if line to left of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y1 * xres + x1 - 1 + ((length - 1) * xres)
         jle leftTransTest

         mov eax, [ebp+20]   ; y2
         shl eax, 10
         add eax, [ebp+16]
         sub eax, 1          ; y2 * xres + x2 - 1 in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y2 * xres + x2 - 1 + ((length - 1) * xres) in edx

leftTransTest2
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near leftTransNext      ; if line to left of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y2 * xres + x2 - 1 + ((length - 1) * xres)
         jle leftTransTest2

         mov eax, [ebp+28]   ; y3
         shl eax, 10
         add eax, [ebp+24]
         sub eax, 1          ; y3 * xres + x3 - 1 in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y3 * xres + x3 - 1 + ((length - 1) * xres) in edx

leftTransTest3
         cmp byte [dBuff + eax], 0    ; see if pixel is black
         jne near leftTransNext      ; if line to left of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y3 * xres + x3 - 1 + ((length - 1) * xres)
         jl leftTransTest3

         mov eax, [ebp+36]   ; y4
         shl eax, 10
         add eax, [ebp+32]
         sub eax, 1          ; y4 * xres + x4 - 1 in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y4 * xres + x4 - 1 + ((length - 1) * xres) in edx

leftTransTest4
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near leftTransNext      ; if line to left of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y4 * xres + x4 - 1 + ((length - 1) * xres)
         jl leftTransTest4

         mov ecx, [ebp+44]  ; translate shape the width of a square (change to 1 to move a pixel like in assignment specs)

         mov eax, [ebp+32]
         sub eax, ecx
         mov dword [x4], eax

         push dword [ebp+48]         ;draw shape at x - ecx
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+36]
         push dword eax
         call drawRect

         mov eax, [ebp+24]
         sub eax, ecx
         mov dword [x3], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword eax
         call drawRect

         mov eax, [ebp+16]
         sub eax, ecx
         mov dword [x2], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword eax
         call drawRect

         mov eax, [ebp+8]
         sub eax, ecx
         mov dword [x1], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword eax
         call drawRect

         ; using the pseudoBlitDBuff function to write to screen
         sub edi, ecx

         mov eax, [ebp+40]  ; square width in eax
         shl eax, 10        ; eax * 1024
         shl eax, 2         ; eax * 4

         mov ebx, eax             ; I am using the value XGAXRES*SQUAREWIDTH*4 for speed consistancy beteween all shapes
         add ebx, edi             ; add the minimum y value (*XGAXRES) to XGAXRES*SQUAREWIDTH*4
         cmp ebx, XGAXRES*XGAYRES    ; making sure copying XGAXRES*SQUAREWIDTH*4 bytes is possible
         jle leftTransGood
         sub ebx, XGAXRES*XGAYRES    ; y + XGAXRES*SQUAREWIDTH*4 - XGAXRES*XGAYRES
         mov edx, eax
         sub edx, ebx                ; XGAXRES*XGAYRES - minY * XGAXRES (number of bytes allowed to copy)
         push dword edx
         jmp leftTransContinue

leftTransGood:
         push dword eax           ; push XGAXRES*SQUAREWIDTH*4
leftTransContinue:
         push dword edi           ; push minimum y * XGAXRES (starting coordinate for pseudoBlitDBuff)
         call waitVRetrace
         call pseudoBlitDBuff
         jmp leftTransEnd

leftTransNext:
         push dword [ebp+48]         ;redraw shape that was deleted at end
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+36]
         push dword [ebp+32]
         call drawRect

         mov eax, [ebp+32]
         mov dword [x4], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect

         mov eax, [ebp+24]
         mov dword [x3], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect

         mov eax, [ebp+16]
         mov dword [x2], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect
         
         mov eax, [ebp+8]
         mov dword [x1], eax

leftTransEnd:
         popad
         leave
         ret 44    ; 11 arguments

;
; PROC rightTrans(x1, y1, x2, y2, x3, y3, x4, y4, length, width, color)
; parameters specify the top left coordinate of every square in shape
; returns the new x values in memory (x1, x2, x3, x4)
;
rightTrans:
         enter 0,0
         pushad

         push dword 0         ; delete shape by coloring it black
         push dword [ebp+44]  ; width
         push dword [ebp+40]  ; length
         push dword [ebp+36]  ; y4
         push dword [ebp+32]  ; x4
         call drawRect        ; first square of shape

         mov edi, [ebp+36]
         shl edi, 10          ;edi contains minimum y value

         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect        ; second square of shape

         mov eax, [ebp+28]
         shl eax, 10
         cmp eax, edi
         jge rightTransMinNext ; see if y3 < y4 and move into edi if it is
         mov edi, eax

rightTransMinNext:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect        ; third square of shape

         mov eax, [ebp+20]
         shl eax, 10
         cmp eax, edi
         jge rightTransMinNext2 ; y2 < current min ?
         mov edi, eax

rightTransMinNext2:
         push dword 0
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect         ; last square of shape

         mov eax, [ebp+12]
         shl eax, 10
         cmp eax, edi
         jge rightTransMinNext3  ; y1 < current min ?
         mov edi, eax

rightTransMinNext3:
         mov eax, [ebp+12]  ; y1
         shl eax, 10
         add eax, [ebp+8]
         add eax, [ebp+44]  ; y1 * xres + x1 + width in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax       ; y1 * xres + x1 + width + ((length - 1) * xres) in edx

rightTransTest
         cmp byte [dBuff + eax], 0    ; see if pixel is black
         jne near rightTransNext      ; if line to right of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y1 * xres + x1 + width + ((length - 1) * xres)
         jle rightTransTest

         mov eax, [ebp+20]   ; y2
         shl eax, 10
         add eax, [ebp+16]   
         add eax, [ebp+44]   ; y2 * xres + x2 + width in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y2 * xres + x2 + width + ((length - 1) * xres) in edx

rightTransTest2
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near rightTransNext      ; if line to right of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y2 * xres + x2 + width + ((length - 1) * xres)
         jle rightTransTest2

         mov eax, [ebp+28]   ; y3
         shl eax, 10
         add eax, [ebp+24]
         add eax, [ebp+44]   ; y3 * xres + x3 + width in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y3 * xres + x3 + width + ((length - 1) * xres) in edx

rightTransTest3
         cmp byte [dBuff + eax], 0    ; see if pixel is black
         jne near rightTransNext      ; if line to right of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y3 * xres + x3 + width + ((length - 1) * xres)
         jl rightTransTest3

         mov eax, [ebp+36]   ; y4
         shl eax, 10
         add eax, [ebp+32]
         add eax, [ebp+44]   ; y4 * xres + x4 + width in eax
         mov edx, [ebp+40]
         sub edx, 1
         shl edx, 10
         add edx, eax        ; y4 * xres + x4 + width + ((length - 1) * xres) in edx

rightTransTest4
         cmp byte [dBuff + eax], 0   ; see if pixel is black
         jne near rightTransNext      ; if line to right of shape is not black then done moving
         add eax, XGAXRES
         cmp eax, edx      ;keep testing while eax <= y4 * xres + x4 + width + ((length - 1) * xres)
         jl rightTransTest4


         mov ecx, [ebp+44] ; translate shape the width of a square (change to 1 to move a pixel like in assignment specs)

         mov eax, [ebp+32]
         add eax, ecx
         mov dword [x4], eax

         push dword [ebp+48]         ;draw shape at x + ecx
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+36]
         push dword eax
         call drawRect

         mov eax, [ebp+24]
         add eax, ecx
         mov dword [x3], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword eax
         call drawRect

         mov eax, [ebp+16]
         add eax, ecx
         mov dword [x2], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword eax
         call drawRect

         mov eax, [ebp+8]
         add eax, ecx
         mov dword [x1], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword eax
         call drawRect

         ; using the pseudoBlitDBuff function to write to screen
         mov eax, [ebp+40]  ; square width in eax
         shl eax, 10        ; eax * 1024
         shl eax, 2         ; eax * 4

         mov ebx, eax             ; I am using the value XGAXRES*SQUAREWIDTH*4 for speed consistancy beteween all shapes
         add ebx, edi             ; add the minimum y value (*XGAXRES) to XGAXRES*SQUAREWIDTH*4
         cmp ebx, XGAXRES*XGAYRES    ; making sure copying XGAXRES*SQUAREWIDTH*4 bytes is possible
         jle rightTransGood
         sub ebx, XGAXRES*XGAYRES    ; y + XGAXRES*SQUAREWIDTH*4 - XGAXRES*XGAYRES
         mov edx, eax
         sub edx, ebx                ; XGAXRES*XGAYRES - minY * XGAXRES (number of bytes allowed to copy)
         push dword edx
         jmp rightTransContinue

rightTransGood:
         push dword eax           ; push XGAXRES*SQUAREWIDTH*4
rightTransContinue:
         push dword edi           ; push minimum y * XGAXRES (starting coordinate for pseudoBlitDBuff)
         call waitVRetrace
         call pseudoBlitDBuff
         jmp rightTransEnd

rightTransNext:
         push dword [ebp+48]         ;redraw shape that was deleted at end
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+36]
         push dword [ebp+32]
         call drawRect

         mov eax, [ebp+32]
         mov dword [x4], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+28]
         push dword [ebp+24]
         call drawRect

         mov eax, [ebp+24]
         mov dword [x3], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+20]
         push dword [ebp+16]
         call drawRect

         mov eax, [ebp+16]
         mov dword [x2], eax

         push dword [ebp+48]
         push dword [ebp+44]
         push dword [ebp+40]
         push dword [ebp+12]
         push dword [ebp+8]
         call drawRect

         mov eax, [ebp+8]
         mov dword [x1], eax

rightTransEnd:
         popad
         leave
         ret 44    ; 11 arguments

;----------------------------------------------------------------------------
[SECTION .data]
;----------------------------------------------------------------------------
         lineCount dd 0
         linesClearedString db "Lines Cleared: %d", 0


;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------
         vidmode  resb 1                     ; the old video mode

         oldhsel resw 1                      ; the old handler's selector
         oldhoff resd 1                      ; the old handler's offset
         action resb 1                       ; action assigned by new interrupt
         endData resb 1                      ; dummy to mark end of data section for locking
         
         x1 resd 1
         y1 resd 1
         x2 resd 1
         y2 resd 1
         x3 resd 1
         y3 resd 1
         x4 resd 1
         y4 resd 1

         dBuff    resb    XGAXRES * XGAYRES  ; double buffer


