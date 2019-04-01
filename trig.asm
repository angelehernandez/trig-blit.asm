; #########################################################################
;
;   trig.asm - Assembly file for EECS205 Assignment 3
;   Angel Hernandez
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943 			;;  PI / 2
PI =  205887				;;  PI 
TWO_PI	= 411774 			;;  2 * PI 
PI_INC_RECIP =  5340353  	;;  Use reciprocal to find the table entry for a given angle
	    					;; (It is easier to use than divison would be)


	;; If you need to, you can place global variables here
	
.CODE

Make0to2pi PROC angle:FXPT
		
		mov eax, angle		;eax = angle

	CONDITIONALS:
		cmp eax, 0			;eax < 0
		jl ANGLE_NEG		;jump to negative cond

		cmp eax, TWO_PI		;eax > 2*PI
		jge ANGLE_BIG		;jump to 0 < ANGLE < 2*PI

		jmp PASS			;skip bodies
		
	ANGLE_NEG:
		add eax, TWO_PI		;eax = eax + 2*pi
		jmp CONDITIONALS	;jump back to conditionals

	ANGLE_BIG:
		sub eax, TWO_PI		;eax = eax - 2*pi
		jmp CONDITIONALS	;jump back to conditionals

	PASS:
		ret

Make0to2pi ENDP

FixedSin PROC USES ebx ecx edx edi angle:FXPT
	
	INITIALIZATION:
		invoke Make0to2pi, angle	;eax = angle (0 to 2pi)
		mov ebx, PI_INC_RECIP		;ebx = 256/pi
	
	QUAD_CONDS:
		cmp eax, PI_HALF 	;eax < PI/2
		jle QUAD_1			;jump to 0 < angle < PI/2

		cmp eax, PI			;eax < PI
		jle QUAD_2			;jump to PI/2 < angle < PI

		cmp eax, PI + PI_HALF	;eax < 3*PI/2
		jle QUAD_3				;jump to PI < angle < 3*PI/2

		jmp QUAD_4			;else: eax < 2
	
	QUAD_1:
		mul ebx				;eax = angle * 1/pi, but actually edx
		movzx eax, WORD PTR [SINTAB + 2 * edx]	;eax = sin(angle)
		jmp RETURN

	QUAD_2:
		mul ebx				;eax = angle * 1/pi, but actually edx
		mov ecx, 255		;ecx = 255
		sub ecx, edx		;ecx = 255 - angle/pi
		movzx eax, WORD PTR [SINTAB + 2 * ecx]	;eax = sin(angle)
		jmp RETURN

	QUAD_3:
		mul ebx				;eax = angle * 1/pi, but actually edx
		sub edx, 256		;edx = angle/pi - 256
		movzx eax, WORD PTR [SINTAB + 2 * edx]	;eax = sin(angle)
		neg eax
		jmp RETURN

	QUAD_4:
		mul ebx				;eax = angle * 1/pi, but actually edx
		mov ecx, 511		;ecx = 511
		sub ecx, edx		;ecx = 511 - angle/pi
		movzx eax, WORD PTR [SINTAB + 2 * ecx]	;eax = sin(angle)
		neg eax				;eax = -sin(angle)
		jmp RETURN

	RETURN:
		ret			; Don't delete this line!!!
FixedSin ENDP 
	
FixedCos PROC angle:FXPT

	add angle, PI_HALF			;eax = angle + pi/2
	invoke FixedSin, angle		;FixedSin(eax)

	ret			; Don't delete this line!!!	
FixedCos ENDP	
END
