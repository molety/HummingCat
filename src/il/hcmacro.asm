;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     macro definitions                                               ;

;%include		"..\..\nasm\misc\c16.mac"	; NASM�t��
%include		"..\macros.asm"

	;===== function call�n�� =====
	;In  ; �Ȃ�
	;Out ; ds:0000 = Drv���[�N�G���A�̐擪
	;Out ; ss:bx = Spc���[�N�G���A�̐擪
	;S.E.; ax�j��
%imacro FUNCCALLIN 0
%push in_func
			push		bp
			mov		bp, sp
			MULTIPUSH	bx, cx, dx, si, di, ds, es
			BIOS_SYSTEM	SYS_GET_MY_IRAM
			or		ax, ax
			jnz		%$iram_ok
			mov		ax, HCERR_NOT_INITIALIZED
			jmp		%$func_exit
%$iram_ok:
			mov		bx, ax
			mov		ds, [ss:bx + Spc.DSreg]
%endmacro

	;===== �X���b�g�ԍ��ǂݎ�� =====
	;In  ; [bp + 6] = �X���b�g�ԍ�
	;Out ; ds:si = Slt���[�N�G���A�̐擪
	;S.E.; ax�j��
%imacro READSLOTNUM 0
			mov		si, [bp + 6]
			mov		al, [Drv.n_Slot]
			mov		ah, 00h
			cmp		si, ax
			jc		%$slot_num_ok
			mov		ax, HCERR_WRONG_SLOT
			jmp		%$func_exit
%$slot_num_ok:
			imul		si, byte Slt_size
			add		si, Drv.Slt_start
%endmacro

	;===== function call�I��� =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; �Ȃ�
%imacro FUNCCALLOUT 0
%$func_exit:
%pop
			MULTIPOP	bx, cx, dx, si, di, ds, es
			pop		bp
			retf
%endmacro
