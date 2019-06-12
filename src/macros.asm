;=== general macros for NASM ===

	;===== farポインタ値の定義 =====
%imacro DFARPTR 1
			dw		%1, seg %1
%endmacro

	;===== farポインタの正規化 =====
	;NORMFARPTR seg, reg
%imacro NORMFARPTR 2
			push		ax
			mov		ax, %1
			push		%2
			shr		%2, 4
			add		ax, %2
			pop		%2
			mov		%1, ax
			and		%2, byte 0fh
			pop		ax
%endmacro

	;===== 複数レジスタのプッシュ(NASMのマニュアルより) =====
%imacro MULTIPUSH 1-*
%rep %0
			push		%1
%rotate 1
%endrep
%endmacro

	;===== 複数レジスタのポップ(NASMのマニュアルより) =====
%imacro MULTIPOP 1-*
%rep %0
%rotate -1
			pop		%1
%endrep
%endmacro

	;===== レジスタ値を範囲内に収める(符号付き比較) =====
	;SIGNEDBOUND reg, lower, upper
%imacro SIGNEDBOUND 3
			cmp		%1, %2
			jge		%%lower_bound_ok
			mov		%1, %2
			jmp		%%upper_bound_ok
%%lower_bound_ok:
			cmp		%1, %3
			jle		%%upper_bound_ok
			mov		%1, %3
%%upper_bound_ok:
%endmacro

	;===== レジスタ値を範囲内に収める(符号無し比較) =====
	;UNSIGNEDBOUND reg, lower, upper
%imacro UNSIGNEDBOUND 3
			cmp		%1, %2
			jae		%%lower_bound_ok
			mov		%1, %2
			jmp		%%upper_bound_ok
%%lower_bound_ok:
			cmp		%1, %3
			jbe		%%upper_bound_ok
			mov		%1, %3
%%upper_bound_ok:
%endmacro
