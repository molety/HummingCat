;  Black Cat Library for WonderWitch                                  ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     display functions                                               ;

			bits 16

;%include		"..\..\nasm\misc\c16.mac"	; NASM付属
%include		"..\macros.asm"
%include		"..\wwbios.asm"


			segment		_TEXT public class=CODE
			segment		TEXT  public class=CODE
			segment		_DATA public class=DATA
			segment		DATA  public class=DATA
			group		CGROUP _TEXT TEXT
			group		DGROUP _DATA DATA

			global		_BCDisp_RotateFont
			global		__BCDisp_RotateFont
			global		_BCDisp_RotateFontMono
			global		__BCDisp_RotateFontMono
			global		_BCDisp_RotateFont16
			global		__BCDisp_RotateFont16
			global		_BCDisp_RotateFont16P
			global		__BCDisp_RotateFont16P

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(グレースケールモード/4色カラーモード用)

			segment		TEXT

_BCDisp_RotateFont:
			push		bp
			mov		bp, sp
			MULTIPUSH	cx, si, di
			mov		di, [bp + 4]
			mov		si, [bp + 6]
			mov		cx, [bp + 8]
.loop_pt:
			push		cx
			call		__BCDisp_RotateFont
			pop		cx
			loop		.loop_pt
			MULTIPOP	cx, si, di
			pop		bp
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(グレースケールモード/4色カラーモード用)

			segment		TEXT

__BCDisp_RotateFont:
%macro rotfont_unit 2
			mov		ax, [si]
%if %1 != 0
			rol		ax, %1
%endif
			rol		ah, 1
			rcr		bh, 1
			rol		al, 1
			rcr		bl, 1
			rol		ah, 1
			rcr		ch, 1
			rol		al, 1
			rcr		cl, 1
			rol		ah, 1
			rcr		dh, 1
			rol		al, 1
			rcr		dl, 1
			rol		ah, 1
			rcr		bp, %2
			rol		al, 1
			rcr		bp, 1
			rol		bp, %2
%endmacro

			rotfont_unit 0, 1
			add		si, 2
			rotfont_unit 0, 2
			add		si, 2
			rotfont_unit 0, 3
			add		si, 2
			rotfont_unit 0, 4
			add		si, 2
			rotfont_unit 0, 5
			add		si, 2
			rotfont_unit 0, 6
			add		si, 2
			rotfont_unit 0, 7
			add		si, 2
			rotfont_unit 0, 8
			sub		si, 14
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			rotfont_unit 4, 1
			add		si, 2
			rotfont_unit 4, 2
			add		si, 2
			rotfont_unit 4, 3
			add		si, 2
			rotfont_unit 4, 4
			add		si, 2
			rotfont_unit 4, 5
			add		si, 2
			rotfont_unit 4, 6
			add		si, 2
			rotfont_unit 4, 7
			add		si, 2
			rotfont_unit 4, 8
			add		si, 2
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(モノクロフォント用)

			segment		TEXT

_BCDisp_RotateFontMono:
			push		bp
			mov		bp, sp
			MULTIPUSH	cx, si, di
			mov		di, [bp + 4]
			mov		si, [bp + 6]
			mov		cx, [bp + 8]
.loop_pt:
			push		cx
			call		__BCDisp_RotateFontMono
			pop		cx
			loop		.loop_pt
			MULTIPOP	cx, si, di
			pop		bp
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(モノクロフォント用)

			segment		TEXT

__BCDisp_RotateFontMono:
%macro rotfontm_unit 1
			mov		ax, [si]

			rol		al, 1
			rcr		bl, 1
			rol		al, 1
			rcr		bh, 1
			rol		al, 1
			rcr		cl, 1
			rol		al, 1
			rcr		ch, 1
			rol		al, 1
			rcr		dl, 1
			rol		al, 1
			rcr		dh, 1
			rol		al, 1
			rcr		bp, %1
			rol		al, 1
			rcr		bp, 1
			rol		bp, %1

			rol		ah, 1
			rcr		bl, 1
			rol		ah, 1
			rcr		bh, 1
			rol		ah, 1
			rcr		cl, 1
			rol		ah, 1
			rcr		ch, 1
			rol		ah, 1
			rcr		dl, 1
			rol		ah, 1
			rcr		dh, 1
			rol		ah, 1
			rcr		bp, %1 + 1
			rol		ah, 1
			rcr		bp, 1
			rol		bp, %1 + 1
%endmacro

			rotfontm_unit 1
			add		si, 2
			rotfontm_unit 3
			add		si, 2
			rotfontm_unit 5
			add		si, 2
			rotfontm_unit 7
			add		si, 2
			rol		bp, 8
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(16色カラーモード用)

			segment		TEXT

_BCDisp_RotateFont16:
			push		bp
			mov		bp, sp
			MULTIPUSH	cx, si, di
			mov		di, [bp + 4]
			mov		si, [bp + 6]
			mov		cx, [bp + 8]
.loop_pt:
			push		cx
			call		__BCDisp_RotateFont16
			pop		cx
			loop		.loop_pt
			MULTIPOP	cx, si, di
			pop		bp
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(16色カラーモード用)

			segment		TEXT

__BCDisp_RotateFont16:
%macro rotfont16_unit 2
			mov		ax, [si]
%if %1 != 0
			rol		ax, %1
%endif
			rol		ah, 1
			rcr		bh, 1
			rol		al, 1
			rcr		bl, 1
			rol		ah, 1
			rcr		dh, 1
			rol		al, 1
			rcr		dl, 1
			add		si, 2
			mov		ax, [si]
%if %1 != 0
			rol		ax, %1
%endif
			rol		ah, 1
			rcr		ch, 1
			rol		al, 1
			rcr		cl, 1
			rol		ah, 1
			rcr		bp, %2
			rol		al, 1
			rcr		bp, 1
			rol		bp, %2
%endmacro

			rotfont16_unit 0, 1
			add		si, 2
			rotfont16_unit 0, 2
			add		si, 2
			rotfont16_unit 0, 3
			add		si, 2
			rotfont16_unit 0, 4
			add		si, 2
			rotfont16_unit 0, 5
			add		si, 2
			rotfont16_unit 0, 6
			add		si, 2
			rotfont16_unit 0, 7
			add		si, 2
			rotfont16_unit 0, 8
			sub		si, 30
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			rotfont16_unit 2, 1
			add		si, 2
			rotfont16_unit 2, 2
			add		si, 2
			rotfont16_unit 2, 3
			add		si, 2
			rotfont16_unit 2, 4
			add		si, 2
			rotfont16_unit 2, 5
			add		si, 2
			rotfont16_unit 2, 6
			add		si, 2
			rotfont16_unit 2, 7
			add		si, 2
			rotfont16_unit 2, 8
			sub		si, 30
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			rotfont16_unit 4, 1
			add		si, 2
			rotfont16_unit 4, 2
			add		si, 2
			rotfont16_unit 4, 3
			add		si, 2
			rotfont16_unit 4, 4
			add		si, 2
			rotfont16_unit 4, 5
			add		si, 2
			rotfont16_unit 4, 6
			add		si, 2
			rotfont16_unit 4, 7
			add		si, 2
			rotfont16_unit 4, 8
			sub		si, 30
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			rotfont16_unit 6, 1
			add		si, 2
			rotfont16_unit 6, 2
			add		si, 2
			rotfont16_unit 6, 3
			add		si, 2
			rotfont16_unit 6, 4
			add		si, 2
			rotfont16_unit 6, 5
			add		si, 2
			rotfont16_unit 6, 6
			add		si, 2
			rotfont16_unit 6, 7
			add		si, 2
			rotfont16_unit 6, 8
			add		si, 2
			mov		[di], bx
			add		di, 2
			mov		[di], cx
			add		di, 2
			mov		[di], dx
			add		di, 2
			mov		[di], bp
			add		di, 2

			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(16色カラーパックトモード用)

			segment		TEXT

_BCDisp_RotateFont16P:
			push		bp
			mov		bp, sp
			MULTIPUSH	cx, si, di
			mov		di, [bp + 4]
			mov		si, [bp + 6]
			mov		cx, [bp + 8]
.loop_pt:
			push		cx
			call		__BCDisp_RotateFont16P
			pop		cx
			loop		.loop_pt
			MULTIPOP	cx, si, di
			pop		bp
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;キャラクタフォント90度回転(16色カラーパックトモード用)

			segment		TEXT

__BCDisp_RotateFont16P:
%macro rotfont16p_unit 0
			mov		ax, [si]
			add		si, 4
			mov		ch, al
			and		ch, 0x0f
			mov		bp, ax
			and		bp, 0x0f00
			ror		ax, 4
			and		ax, 0x0f0f
			mov		bh, al
			mov		dh, ah

			mov		ax, [si]
			and		ax, 0xf0f0
			or		bh, al
			or		dh, ah
			mov		ax, [si]
			add		si, 4
			rol		ax, 4
			and		al, 0xf0
			or		ch, al
			and		ax, 0xf000
			or		bp, ax

			mov		ax, [si]
			add		si, 4
			mov		cl, al
			and		cl, 0x0f
			ror		ax, 4
			mov		bl, al
			and		bl, 0x0f
			mov		dl, ah
			and		dl, 0x0f
			ror		al, 4
			and		ax, 0x000f
			or		bp, ax

			mov		ax, [si]
			and		ax, 0xf0f0
			or		bl, al
			or		dl, ah
			mov		ax, [si]
			ror		ax, 4
			and		ah, 0xf0
			or		cl, ah
			and		ax, 0x00f0
			or		bp, ax

			mov		[di], bx
			add		di, 4
			mov		[di], cx
			add		di, 4
			mov		[di], dx
			add		di, 4
			mov		[di], bp
%endmacro

			add		si, 16
			rotfont16p_unit
			sub		si, 10
			add		di, 4
			rotfont16p_unit
			sub		si, 30
			sub		di, 26
			rotfont16p_unit
			sub		si, 10
			add		di, 4
			rotfont16p_unit
			add		si, 18
			add		di, 2

			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		DATA

