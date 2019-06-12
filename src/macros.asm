;=== general macros for NASM ===

	;===== far�|�C���^�l�̒�` =====
%imacro DFARPTR 1
			dw		%1, seg %1
%endmacro

	;===== far�|�C���^�̐��K�� =====
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

	;===== �������W�X�^�̃v�b�V��(NASM�̃}�j���A�����) =====
%imacro MULTIPUSH 1-*
%rep %0
			push		%1
%rotate 1
%endrep
%endmacro

	;===== �������W�X�^�̃|�b�v(NASM�̃}�j���A�����) =====
%imacro MULTIPOP 1-*
%rep %0
%rotate -1
			pop		%1
%endrep
%endmacro

	;===== ���W�X�^�l��͈͓��Ɏ��߂�(�����t����r) =====
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

	;===== ���W�X�^�l��͈͓��Ɏ��߂�(����������r) =====
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
