;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     macro definitions                                               ;

;%include		"..\..\nasm\misc\c16.mac"	; NASM付属
%include		"..\macros.asm"

	;===== function call始め =====
	;In  ; なし
	;Out ; ds:0000 = Drvワークエリアの先頭
	;Out ; ss:bx = Spcワークエリアの先頭
	;S.E.; ax破壊
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

	;===== スロット番号読み取り =====
	;In  ; [bp + 6] = スロット番号
	;Out ; ds:si = Sltワークエリアの先頭
	;S.E.; ax破壊
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

	;===== function call終わり =====
	;In  ; なし
	;Out ; なし
	;S.E.; なし
%imacro FUNCCALLOUT 0
%$func_exit:
%pop
			MULTIPOP	bx, cx, dx, si, di, ds, es
			pop		bp
			retf
%endmacro
