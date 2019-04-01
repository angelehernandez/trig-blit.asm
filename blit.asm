; #########################################################################
;
;   blit.asm - Assembly file for EECS205 Assignment 3
;   Angel Hernandez
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES ebx ecx edx x:DWORD, y:DWORD, color:DWORD

      INITIALIZATION:
            mov ebx, x        ;ebx = x
            mov ecx, y        ;ecx = y
            mov edx, color    ;edx = color

      CHECK:
            cmp ebx, 0        ;x < 0
            jl GET_OUT
            cmp ebx, 640      ;x > 640
            jg GET_OUT
            cmp ecx, 0        ;y < 0
            jl GET_OUT
            cmp ecx, 480      ;y > 480
            jg GET_OUT

      BODY:
            mov eax, 640      ;eax = 640
            imul ecx          ;eax = 640 * y
            xor edx, edx      ;edx = 0
            add ebx, eax      ;ebx = x + 640*y
            
            mov edx, color          ;edx = color
            mov ecx, ScreenBitsPtr  ;ecx = ScreenBitsPtr
            mov [ecx + ebx], dl     ;ScreenBitsPtr + ebx

      GET_OUT:
	      ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	
	invoke RotateBlit, ptrBitmap, xcenter, ycenter, 0

	ret 			; Don't delete this line!!!	
BasicBlit ENDP

RotateBlit PROC USES ebx ecx edx esi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
LOCAL cosa:DWORD, sina:DWORD, shiftX:DWORD, shiftY:DWORD, dstWidth:DWORD, dstHeight:DWORD, 
dstX:DWORD, dstY:DWORD, srcX:DWORD, srcY:DWORD

      INITIALIZATION:
            ;;cosa = FixedCos(angle)
            invoke FixedCos, angle  ;eax = cos(angle)
            mov cosa, eax           ;cosa = cos(angle)

            ;;sina = FixedSin(angle)
            invoke FixedSin, angle  ;eax = sin(angle)
            mov sina, eax           ;sina = sin(angle)

            ;;esi = lpBitmap
            mov esi, lpBmp          ;esi = lpBmp -> ESI MATTERS

      INIT_SHIFTX:
            ;;cosa/2
            mov eax, cosa     ;eax = cosa
            sar eax, 1        ;eax = cosa/2

            ;;first term
            mov ebx, (EECS205BITMAP PTR [esi]).dwWidth
            sal ebx, 16       ;convert ebx to fixed point
            xor edx, edx      ;edx = 0
            imul ebx          ;edx = (cosa/2) * (EECS205BITMAP PTR [esi]).dwWidth
            mov shiftX, edx   ;mov first term into shiftX
                  
            ;;sina/2
            mov eax, sina     ;eax = sina
            shr eax, 1        ;eax = sina/2

            ;;second term
            mov ebx, (EECS205BITMAP PTR[esi]).dwHeight
            sal ebx, 16       ;convert ebx to fixed point
            xor edx, edx      ;edx = 0
            imul ebx          ;edx = (sina/2) * (EECS205BITMAP PTR[esi]).dwHeight

            ;;FINALLY
            sub shiftX, edx   ;shiftX = (cosa/2) * (EECS205BITMAP PTR [esi]).dwWidth - (sina/2) * (EECS205BITMAP PTR[esi]).dwHeight

      INIT_SHIFTY:
            ;;cosa/2
            mov eax, cosa     ;eax = cosa
            sar eax, 1        ;eax = cosa/2

            ;;first term
            mov ebx, (EECS205BITMAP PTR [esi]).dwHeight
            sal ebx, 16       ;convert ebx to fixed point
            xor edx, edx      ;edx = 0
            imul ebx          ;edx = (cosa/2) * (EECS205BITMAP PTR [esi]).dwWidth
            mov shiftY, edx   ;mov first term into shiftY
                  
            ;;sina/2
            mov eax, sina     ;eax = sina
            sar eax, 1        ;eax = sina/2

            ;;second term
            mov ebx, (EECS205BITMAP PTR[esi]).dwWidth
            sal ebx, 16       ;convert ebx to fixed point
            xor edx, edx      ;edx = 0
            imul ebx          ;edx = (sina/2) * (EECS205BITMAP PTR[esi]).dwHeight

            ;;FINALLY
            add shiftY, edx   ;shiftY = (cosa/2) * (EECS205BITMAP PTR [esi]).dwWidth - (sina/2) * (EECS205BITMAP PTR[esi]).dwHeight

      INIT_DSTWIDTH:
            ;;dstWidth
            mov eax, (EECS205BITMAP PTR [esi]).dwWidth
            add eax, (EECS205BITMAP PTR[esi]).dwHeight
            mov dstWidth, eax

      INIT_DSTHEIGHT:
            mov dstHeight, eax

            ;;init
            mov eax, dstWidth ;eax = dstWidth
            neg eax           ;eax = -dstWidth            
            mov dstX, eax     ;dstX = -dstWidth

      DSTX_LOOP:
            ;;init
            mov eax, dstHeight
            neg eax
            mov dstY, eax

      DSTY_LOOP:
            ;first term
            mov eax, dstX           ;eax = dstX
            sal eax, 16             ;convert to fixed point
            mov ebx, cosa           ;ebx = cosa
            xor edx, edx            ;edx = 0
            imul ebx                ;edx = dstX * cosa
            mov srcX, edx           ;mov result into srcX
            ;second term
            mov eax, dstY           ;eax = dstY
            sal eax, 16             ;convert to fixed point
            mov ebx, sina           ;ebx = sina
            xor edx, edx            ;edx = 0
            imul ebx                ;edx = dstY * sina
            ;FINALLY
            add srcX, edx           ;srcX = dstX * cosa + dstY * sina

            ;;srcY
            ;first term
            mov eax, dstY           ;eax = dstY
            sal eax, 16             ;convert to fixed point
            mov ebx, cosa           ;ebx = cosa
            xor edx, edx            ;edx = 0
            imul ebx                ;edx = dstY * cosa
            mov srcY, edx           ;mov result into srcY
            ;second term
            mov eax, dstX           ;eax = dstX
            sal eax, 16             ;convert to fixed point
            mov ebx, sina           ;ebx = sina
            xor edx, edx            ;edx = 0
            imul ebx                ;edx = dstX* sina
            ;FINALLY
            sub srcY, edx            ;ecx = dstY * cosa - dstX * sina

            ;srcX >= 0 && srcX < dwWidth
            cmp srcX, 0        ;srcX < 0
            jl SKIP_BODY
            
            mov eax, srcX     ;eax = srcX
            cmp eax, (EECS205BITMAP PTR [esi]).dwWidth
            jge SKIP_BODY

            ;srcY >= 0 && srcY < dwHeight
            cmp srcY, 0        ;srcY < 0
            jl SKIP_BODY
            
            mov eax, srcY     ;eax = srcY
            cmp eax, (EECS205BITMAP PTR [esi]).dwHeight
            jge SKIP_BODY

            ;bitmap pixel (srcX,srcY) is not transparent
            mov eax, srcY
            mov ebx, (EECS205BITMAP PTR [esi]).dwWidth
            xor edx, edx
            imul ebx
            add eax, srcX

            mov ebx, (EECS205BITMAP PTR [esi]).lpBytes
            mov al, BYTE PTR [ebx + eax]
            cmp al, (EECS205BITMAP PTR [esi]).bTransparent
            je SKIP_BODY

            ;body
            mov ebx, xcenter
            add ebx, dstX
            sub ebx, shiftX

            mov ecx, ycenter
            add ecx, dstY
            sub ecx, shiftY

            mov dl, al

            invoke DrawPixel, ebx, ecx, edx

      SKIP_BODY:
            inc dstY

      DSTY_COND:
            mov eax, dstHeight
            cmp dstY, eax	;dstY >= dstHeight
            jl DSTY_LOOP

            inc dstX

      DSTX_COND:
            ;;dstX < dstWidth
            mov eax, dstX
            cmp eax, dstWidth ;dstX >= dstWidth
            jl DSTX_LOOP

      ret 			; Don't delete this line!!!		
RotateBlit ENDP

END
