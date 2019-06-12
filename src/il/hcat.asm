;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     function calls                                                  ;

			bits 16

%define _HCAT_

%include		"..\wwbios.asm"
%include		"hcdef.asm"
%include		"hcmacro.asm"

%define			DRIVER_VERSION		"0.06"

			segment		_TEXT public class=CODE
			segment		TEXT  public class=CODE
			segment		_DATA public class=DATA
			segment		DATA  public class=DATA
			group		CGROUP _TEXT TEXT
			group		DGROUP _DATA DATA

			extern		_il_get_ds
			extern		_il_to_far
			extern		__hcat_main
			extern		init_slot
			extern		init_track
			extern		mf_play
			extern		mf_stop
			extern		mf_set
			extern		mf_rewind
			extern		mf_tempo
			global		cn_table

	;===== ���[�`���̐��� =====
	;In  ; ���̓��W�X�^/�X�^�b�N (�X�^�b�N��[bp + 6]���g�b�v)
	;Out ; �o�̓��W�X�^
	;S.E.; ����p(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		DATA

	;===== ����-BIOS�ݒ�l�ϊ��e�[�u�� =====
			align		2
cn_table:
%include		"cn_table.asm"

			align		2
builtin_waveform0:			;��`�g
			db		0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
			db		00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
builtin_waveform1:			;��`�g(����1/2)
			db		0ffh, 0ffh, 0ffh, 0ffh, 00h, 00h, 00h, 00h
			db		0ffh, 0ffh, 0ffh, 0ffh, 00h, 00h, 00h, 00h
builtin_waveform2:			;Magical Book�ɍڂ��Ă���g�`(�����g?)
			db		0a8h, 0dch, 0eeh, 0efh, 0deh, 0bch, 9ah, 89h
			db		67h, 56h, 34h, 12h, 01h, 11h, 32h, 75h

			align		2
builtin_ampenv0:
			dw		0003h
			db		00h
			db		03h, 00h
builtin_ampenv1:
			dw		0013h
			db		63h, 0fh, 0fh, 0fh, 04h,
			db		0ffh, 08h, 0ffh, 08h, 0ffh, 08h, 0ffh, 08h
;			db		0ffh, 78h, 0ffh, 00h
			db		3eh, 0ffh, 14h, 06h, 00h

			align		2
builtin_pchenv0:
			dw		0003h
			db		00h
			db		00h
builtin_pchenv1:
			dw		000ah
			db		0f2h, 64h, 53h, 0ch, 0b3h, 0ch, 06h, 00h
			db		00h

		;@@@���g�p
			align		2
builtin_waveform_ptr:
			dw		builtin_waveform0
builtin_ampenv_ptr:
			dw		builtin_ampenv0
builtin_pchenv_ptr:
			dw		builtin_pchenv0


builtin_cs:

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== IL�\���� (TEXT�Z�O�����g�̐擪�ɒu��) =====
_link_pos:		dw		0, 0		; void far *link_pos;
_n_methods:		dw		26		; int n_methods;
__get_info:		DFARPTR		_hcat_get_info	; ILinfo far *(far *_get_info)(void);

			DFARPTR		__hcat_calc_workarea_size
			DFARPTR		__hcat_init
			DFARPTR		__hcat_release
			DFARPTR		__hcat_chain_hook
			DFARPTR		__hcat_get_workarea
			DFARPTR		__hcat_set_waveform
			DFARPTR		__hcat_set_ampenv
			DFARPTR		__hcat_set_pchenv
			DFARPTR		__hcat_assign_track
			DFARPTR		__hcat_set_score
			DFARPTR		__hcat_check_status
			DFARPTR		__hcat_play
			DFARPTR		__hcat_continue
			DFARPTR		__hcat_stop
			DFARPTR		__hcat_enable_output
			DFARPTR		__hcat_change_speed
			DFARPTR		__hcat_change_mastervol
			DFARPTR		__hcat_start_cs
			DFARPTR		__hcat_stop_cs
			DFARPTR		__hcat_set_driver_mode
			DFARPTR		__hcat_reserve1
			DFARPTR		__hcat_reserve2
			DFARPTR		__hcat_reserve3
			DFARPTR		__hcat_reserve4
			DFARPTR		__hcat_reserve5

	;ILinfo�\���̂ւ̃|�C���^��Ԃ��֐�
_hcat_get_info:		mov		ax, _hcat_info
			push		ax
			call		_il_to_far
			add		sp, byte 2
			retf

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		DATA

	;===== ILinfo�\���� =====
_hcat_info:
_className:		DFARPTR		className	;char far *className;
_name:			DFARPTR		name		;char far *name;
_version:		DFARPTR		version		;char far *version;
_description:		DFARPTR		description	;char far *description;
_depends:		dw		0, 0		;char far * far *depends;

	;ILinfo�\���̂���Q�Ƃ������
className:		db		"Hcat", 0
name:			db		"hcat", 0
version:		db		DRIVER_VERSION, 0
description:		db		"Sound Driver 'Humming Cat'", 0
;depends:

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���[�N�G���A�̃T�C�Y���v�Z =====
	;In  ; [bp + 6](w) = �X���b�g��
	;In  ; [bp + 8](w) = �g���b�N��
	;Out ; ax = ���[�N�G���A�̃T�C�Y
	;S.E.; dx�j��
	;���̃t�@���N�V�����̂݁A�h���C�o�������O�ł��Ăяo���\ 
__hcat_calc_workarea_size:
			mov		dx, Drv_size
			mov		ax, [bp + 6]
			imul		ax, byte Slt_size
			add		dx, ax
			mov		ax, [bp + 8]
			imul		ax, byte Trk_size
			add		ax, dx
			retf

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;ax, bx, cx, dx
	;si, di
	;(sp,) bp
	;(cs,) ds, es, (ss)

	;===== �h���C�o�̏����� =====
	;In  ; [bp + 6](d) = intvector_t�^�\���̂ւ�far�|�C���^
	;In  ; [bp +10](d) = ���[�N�G���A�̐擪�ւ�far�|�C���^(16�o�C�g���E)
	;In  ; [bp +14](w) = �X���b�g��
	;In  ; [bp +16](w) = �g���b�N��
	;In  ; [bp +18](w) = ���荞�ݎ��g��
	;In  ; [bp +20](w) = ���[�U�[�v���Z�X��SRAM�o���N�ԍ�
	;Out ; ax = �G���[�R�[�h
	;S.E.; intvector_t�^�\���̂Ɋ��荞�݃��[�`���ւ̃x�N�^������
__hcat_init:
			push		bp
			mov		bp, sp
			MULTIPUSH	bx, cx, dx, si, di, ds, es
			BIOS_SYSTEM	SYS_GET_MY_IRAM ;ax=offset(seg;always0)
			cmp		ax, 0000h
			je		.alloc_workarea
		;���łɃ������m�ۍς݂̂Ƃ�(���[�N�G���A�̏������݂̂ɂ���\��)
		;(���o�[�W�����ł̓G���[)
			mov		ax, HCERR_INTERNAL_ERROR
			jmp		.exit

.alloc_workarea:
			mov		cx, Spc_size
			mov		di, [bp + 10]
			mov		es, [bp + 12]
			NORMFARPTR	es, di
			mov		ax, es
			or		ax, di
			jz		.iram_all	;���[�N�G���A=IRAM
			mov		bx, 0000h
			BIOS_SYSTEM	SYS_ALLOC_IRAM
			cmp		ax, 0000h
			jne		.init_workarea
			mov		ax, HCERR_MEM_NOT_ENOUGH
			jmp		.exit

.iram_all:
			add		cx, Drv_size
			mov		ax, [bp + 14]
			imul		ax, byte Slt_size
			add		cx, ax
			mov		ax, [bp + 16]
			imul		ax, byte Trk_size
			add		cx, ax
			mov		bx, 0000h
			BIOS_SYSTEM	SYS_ALLOC_IRAM
			cmp		ax, 0000h
			jne		.p2
			mov		ax, HCERR_MEM_NOT_ENOUGH
			jmp		.exit
.p2:
			mov		bx, 0000h
			mov		es, bx
			mov		di, ax
			add		di, Spc_size
			NORMFARPTR	es, di

.init_workarea:
		;Spc���[�N�G���A������
			MULTIPUSH	ax, cx, di, es
			mov		di, ax
			mov		ax, ss
			mov		es, ax
			cld
			mov		cx, Spc_size / 2
			mov		ax, 0000h
		rep	stosw
			MULTIPOP	ax, cx, di, es

			mov		bx, ax
			mov		[ss:bx + Spc.DSreg], es

			mov		di, [bp + 6]
			mov		es, [bp + 8]
			mov		bl, [bp + 14]		;n_Slot
			mov		bh, [bp + 16]		;n_Track
			mov		cx, [bp + 18]		;IntrptFreq
			mov		dx, [bp + 20]		;UserSRAMBank
		;BP, DS�ݒ�
			mov		bp, ax
			mov		ds, [bp + Spc.DSreg]

		;intvector�̐ݒ�
		;ss:bp(Spc���[�N�G���A)���p���O���t���E���w���Ă��邱�Ƃ��O��
			push		ds
			push		bp
			mov		ax, ss
			mov		ds, ax
			NORMFARPTR	ds, bp
			mov		[es:di], word __hcat_main
			mov		[es:di + 2], cs
			mov		[es:di + 4], ds		;myIRAM���w��
			mov		[es:di + 6], word 0000h
			pop		bp
			pop		ds

		;Drv���[�N�G���A������
			MULTIPUSH	ax, cx, di, es
			mov		ax, ds
			mov		es, ax
			cld
			mov		cx, Drv_size / 2
			mov		ax, 0000h
		rep	stosw
			MULTIPOP	ax, cx, di, es

			mov		[Drv.SpcTop], bp

			mov		[bp + Spc.UserSRAMBank], dx
			mov		al, bl
			mov		ah, 0
			imul		ax, byte Slt_size
			add		ax, Drv_size
			mov		[Drv.TrackTop], ax
			mov		[Drv.n_Slot], bl
			mov		[Drv.n_Track], bh
			mov		[Drv.n_EmptyTrack], bh
			mov		ax, 5
			mul		cx
			mov		[Drv.IntrptFreq], ax

			mov		ax, cx
			xor		dx, dx
			mov		bx, 75
			div		bx
			cmp		ax, 1
			adc		al, 0		;ax == 0�̂Ƃ�1���₷
			mov		[Drv.EnvInterval], ax

			mov		ax, cx
			xor		dx, dx
			mov		bx, 15
			div		bx
			cmp		ax, 1
			adc		al, 0		;ax == 0�̂Ƃ�1���₷
			mov		[Drv.CSInterval], ax

			mov		byte [Drv.n_WaveForm], NumOfWaveForm
			mov		byte [Drv.n_AmpEnv], NumOfAmpEnv
			mov		byte [Drv.n_PchEnv], NumOfPchEnv
			mov		byte [Drv.n_Priority], NumOfPriority
		;�g�`�Q�ƃe�[�u�������Z�b�g
			call		_il_get_ds
			mov		dx, ax
			mov		cx, NumOfWaveForm / 2
			lea		di, [Drv.WaveForm_start]
.reset_waveform_table:
			mov		ax, builtin_waveform0 ;@@@[builtin_waveform_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			mov		ax, builtin_waveform1 ;@@@[builtin_waveform_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			loop		.reset_waveform_table
		;���ʃG���x���[�v�Q�ƃe�[�u�������Z�b�g
			mov		cx, NumOfAmpEnv / 2
			lea		di, [Drv.AmpEnv_start]
.reset_ampenv_table:
			mov		ax, builtin_ampenv0 ;@@@[builtin_ampenv_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			mov		ax, builtin_ampenv1 ;@@@[builtin_ampenv_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			loop		.reset_ampenv_table
		;�����G���x���[�v�Q�ƃe�[�u�������Z�b�g
			mov		cx, NumOfPchEnv / 2
			lea		di, [Drv.PchEnv_start]
.reset_pchenv_table:
			mov		ax, builtin_pchenv0 ;@@@[builtin_pchenv_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			mov		ax, builtin_pchenv1 ;@@@[builtin_pchenv_ptr]
			mov		[di], ax
			mov		[di + 02h], dx
			add		di, 04h
			loop		.reset_pchenv_table

		;�D��x�錾�e�[�u�������Z�b�g
			mov		cx, 4 * NumOfPriority	;�g���b�N��x�D��x�i����
.reset_priority:
			mov		bx, cx
			dec		bx
			mov		word [bx + Drv.PDT], 0000h
			loop		.reset_priority

		;PCM�`�����l�����[�N�G���A��������
			lea		ax, [Drv.ChnBufA_start]
			mov		[Drv.ChnBufCurr], ax
			lea		ax, [Drv.ChnBufB_start]
			mov		[Drv.ChnBufPrev], ax
;			mov		byte [Drv.Chn0WaveFormChange], 0
;			mov		byte [Drv.Chn1WaveFormChange], 0
;			mov		byte [Drv.Chn2WaveFormChange], 0
;			mov		byte [Drv.Chn3WaveFormChange], 0
			mov		byte [Drv.ChnBufA_start + ChnBuf.Ch3Noise], 0ffh
			mov		byte [Drv.ChnBufB_start + ChnBuf.Ch3Noise], 0ffh

		;Slt���[�N�G���A������
			mov		si, Drv.Slt_start	;Slt���[�N�G���A�̐擪
			mov		cl, [Drv.n_Slot]
			mov		ch, 00h
.loop_for_slot:
			call		init_slot
			add		si, Slt_size
			loop		.loop_for_slot

		;Trk���[�N�G���A������
			mov		di, [Drv.TrackTop]	;Trk���[�N�G���A�̐擪
			mov		cl, [Drv.n_Track]
			mov		ch, 00h
.loop_for_track:
			call		init_track
			add		di, Trk_size
			loop		.loop_for_track

		;�����̏�����
			BIOS_SOUND	SOUND_INIT

			BIOS_SOUND	SOUND_GET_OUTPUT
			and		al, 00001111b	;@@@bit7�̏��͎�����(��肪����΍Č���)
;			or		al, 00001001b
			or		al, 00001111b
			mov		[Drv.ChnBufA_start + ChnBuf.OutputMode], al
			mov		[Drv.ChnBufB_start + ChnBuf.OutputMode], al
			mov		bl, al
			BIOS_SOUND	SOUND_SET_OUTPUT

			BIOS_SOUND	SOUND_GET_CHANNEL
			and		al, 00001111b
			or		al, 00001111b
			mov		[Drv.ChnBufA_start + ChnBuf.ChannelMode], al
			mov		[Drv.ChnBufB_start + ChnBuf.ChannelMode], al
			mov		bl, al
			BIOS_SOUND	SOUND_SET_CHANNEL

		;�g�ݍ��ݔg�`�f�[�^�̓o�^
			push		ds
			call		_il_get_ds
			mov		ds, ax
			mov		dx, builtin_waveform0
			mov		cx, 04h
			mov		al, 00h
.wf_loop:
			push		ax
			BIOS_SOUND	SOUND_SET_WAVE
			pop		ax
			inc		al
			loop		.wf_loop
			pop		ds

			mov		ax, HCERR_OK
.exit:
			MULTIPOP	bx, cx, dx, si, di, ds, es
			pop		bp
			retf

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �h���C�o�̉�� =====
	;In  ; �Ȃ�
	;Out ; ax = 
	;S.E.; 
__hcat_release:
			FUNCCALLIN

			mov		bx, ax
			BIOS_SYSTEM	SYS_FREE_IRAM

			BIOS_SOUND	SOUND_INIT

			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���荞�݃t�b�N�̃`�F�[�� =====
	;In  ; [bp + 6](d) = intvector_t�^�\���̂ւ�far�|�C���^
	;Out ; ax = 
	;S.E.; 
__hcat_chain_hook:
			FUNCCALLIN

			mov		dx, [bp + 6]
			mov		bx, [bp + 8]
			mov		ax, dx
			or		ax, bx
			jz		.unchain
			mov		[Drv.HookChainOfs], dx
			mov		[Drv.HookChainSeg], bx
			mov		byte [Drv.HookChained], 01h
			jmp		.exit

.unchain:
			mov		byte [Drv.HookChained], 00h

.exit:
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���[�N�G���A�̃A�h���X�𓾂� =====
	;In  ; �Ȃ�
	;Out ; dx:ax = ���[�N�G���A�̐擪�ւ�far�|�C���^
	;Out ; �h���C�o������������0000:0000��Ԃ�
	;S.E.; 
__hcat_get_workarea:
			push		bp
			mov		bp, sp
			MULTIPUSH	bx, cx, si, di, ds, es
			BIOS_SYSTEM	SYS_GET_MY_IRAM
			cmp		ax, 0000h
			jne		.iram_ok
			mov		dx, 0000h	;�G���[����0000:0000��Ԃ�
			jmp		.exit
.iram_ok:
			mov		bx, ax
			mov		dx, [ss:bx + Spc.DSreg]
			mov		ax, 0000h
.exit:
			MULTIPOP	bx, cx, si, di, ds, es
			pop		bp
			retf

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �g�`�f�[�^�̓o�^ =====
	;In  ; [bp + 6](w) = �g�`�f�[�^�ԍ�
	;In  ; [bp + 8](d) = �g�`�f�[�^�ւ�far�|�C���^
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_set_waveform:
			FUNCCALLIN

			mov		ax, [bp + 6]
			cmp		ax, NumOfWaveForm
			jc		.num_ok
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit

.num_ok:
			imul		ax, byte WaveForm_size
			lea		di, [Drv.WaveForm_start]
			add		di, ax
			cli
			mov		ax, [bp + 8]
			mov		[di + WaveForm.Ofs], ax
			mov		ax, [bp + 10]
			mov		[di + WaveForm.Seg], ax
			sti

			mov		ax, HCERR_OK
.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���ʃG���x���[�v�f�[�^�̓o�^ =====
	;In  ; [bp + 6](w) = ���ʃG���x���[�v�f�[�^�ԍ�
	;In  ; [bp + 8](d) = ���ʃG���x���[�v�f�[�^�ւ�far�|�C���^
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_set_ampenv:
			FUNCCALLIN

			mov		ax, [bp + 6]
			cmp		ax, NumOfAmpEnv
			jc		.num_ok
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit

.num_ok:
			imul		ax, byte AmpEnv_size
			lea		di, [Drv.AmpEnv_start]
			add		di, ax
			cli
			mov		ax, [bp + 8]
			mov		[di + AmpEnv.Ofs], ax
			mov		ax, [bp + 10]
			mov		[di + AmpEnv.Seg], ax
			sti

			mov		ax, HCERR_OK
.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �����G���x���[�v�̓o�^ =====
	;In  ; [bp + 6](w) = �����G���x���[�v�f�[�^�ԍ�
	;In  ; [bp + 8](d) = �����G���x���[�v�f�[�^�ւ�far�|�C���^
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_set_pchenv:
			FUNCCALLIN

			mov		ax, [bp + 6]
			cmp		ax, NumOfPchEnv
			jc		.num_ok
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit

.num_ok:
			imul		ax, byte PchEnv_size
			lea		di, [Drv.PchEnv_start]
			add		di, ax
			cli
			mov		ax, [bp + 8]
			mov		[di + PchEnv.Ofs], ax
			mov		ax, [bp + 10]
			mov		[di + PchEnv.Seg], ax
			sti

			mov		ax, HCERR_OK
.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �g���b�N�̊��蓖�� =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = ���蓖�Ă�g���b�N��
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_assign_track:
			FUNCCALLIN

			READSLOTNUM

			cmp		byte [si + Slt.n_AssignedTrack], 00h
			je		.slot_unassigned_ok
			mov		ax, HCERR_ALREADY_ASSIGNED_SLOT
			jmp		.exit
.slot_unassigned_ok:
			mov		dx, [bp + 8]
			cmp		dx, 4
			jna		.track_num_ok
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit
.track_num_ok:
			mov		bl, [Drv.n_EmptyTrack]
			mov		bh, 00h
			cmp		dx, bx
			jna		.n_empty_track_ok
			mov		ax, HCERR_TRACK_NOT_ENOUGH
			jmp		.exit
.n_empty_track_ok:

			mov		al, [Drv.n_Track]
			mov		ah, 00h
			sub		ax, bx
			imul		ax, byte Trk_size
			add		ax, [Drv.TrackTop]
			mov		[si + Slt.AssignedTrackTop], ax
			mov		[si + Slt.n_AssignedTrack], dl
			sub		[Drv.n_EmptyTrack], dl
			mov		ax, HCERR_OK

.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �X�R�A�f�[�^�̓o�^ =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](d) = �X�R�A�f�[�^�ւ�far�|�C���^
	;In  ; [bp +12](w) = �D��x
	;In  ; [bp +14](w) = �������[�h(0:�f�[�^�Z�b�g�̂݁A1:�������t)
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_set_score:
			FUNCCALLIN

			READSLOTNUM

			mov		cx, [bp + 12]
			cmp		cx, NumOfPriority
			jc		.priority_ok
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit
.priority_ok:

		;@@@��O�I��es:di�ŃX�R�A�f�[�^���w���Ă���
			mov		di, [bp + 8]
			mov		es, [bp + 10]
			mov		ax, [es:di + 00h]
			cmp		ax, [si + Slt.n_AssignedTrack]
			jna		.track_num_ok
			mov		ax, HCERR_TRACK_NOT_ENOUGH
			jmp		.exit
.track_num_ok:

		;���݂̃X�R�A�͉��t��~����
			push		bp
			mov		bp, [Drv.SpcTop]
			cli
			call		mf_stop		;@@@ax/bx/dx�j��
			and		byte [Drv.CSStatus], 7fh
			sti
			pop		bp

			NORMFARPTR	es, di
			mov		dl, [es:di + 00h]
			mov		dh, [es:di + 01h]
			shl		cx, 1
			mov		al, [bp + 14]

			mov		bp, [Drv.SpcTop]
			cli
			mov		[si + Slt.ScoreOfs], di
			mov		[si + Slt.ScoreSeg], es
			mov		[si + Slt.n_InUseTrack], dl
			mov		[si + Slt.InUseTrackBit], dh
			mov		[si + Slt.Priority], cx
			or		byte [si + Slt.Request], REQ_MF_SET | REQ_MF_REWIND | REQ_MF_TEMPO
			or		al, al
			jz		.not_immediate_mode
			call		mf_play		;@@@�K��al!=0�ŌĂ΂��
.not_immediate_mode:
			sti

			mov		ax, HCERR_OK

.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �X���b�g�̏�Ԃ𓾂� =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;Out ; ax = �X�e�[�^�X(bit0:current, bit1:future) / ��:�G���[
	;S.E.; 
__hcat_check_status:
			FUNCCALLIN

			READSLOTNUM

			mov		al, [si + Slt.Status]
			shr		al, 6
			mov		ah, 00h
.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �ŏ����牉�t =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = �������[�h(0:�֎~�A1:����)
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_play:
			FUNCCALLIN

			READSLOTNUM

			mov		al, [bp + 8]
			mov		bp, [Drv.SpcTop]
			cli
			call		mf_play
			or		byte [si + Slt.Request], REQ_MF_REWIND
			and		byte [Drv.CSStatus], 7fh
			sti
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �O���~�����ʒu���牉�t =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = �������[�h(0:�֎~�A1:����)
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_continue:
			FUNCCALLIN

			READSLOTNUM

			mov		al, [bp + 8]
			mov		bp, [Drv.SpcTop]
			cli
			call		mf_play
			and		byte [Drv.CSStatus], 7fh
			sti
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���t���~ =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_stop:
			FUNCCALLIN

			READSLOTNUM

			mov		bp, [Drv.SpcTop]
			cli
			call		mf_stop
			and		byte [Drv.CSStatus], 7fh
			sti
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �������� =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = �g���b�N�ԍ�(bit0:�g���b�N0�Abit1:�g���b�N1�A�c)
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_enable_output:
			FUNCCALLIN

			READSLOTNUM
			mov		al, [bp + 8]
			mov		bp, [Drv.SpcTop]
			xor		bh, bh
			cli
			mov		bl, [si + Slt.Priority]
			and		al, [si + Slt.InUseTrackBit]

			shr		al, 1
			jnc		.track0_passed
			mov		[bx + Drv.PDT + 00h], si
.track0_passed:
			shr		al, 1
			jnc		.track1_passed
			mov		[bx + Drv.PDT + 08h], si
.track1_passed:
			shr		al, 1
			jnc		.track2_passed
			mov		[bx + Drv.PDT + 10h], si
.track2_passed:
			shr		al, 1
			jnc		.track3_passed
			mov		[bx + Drv.PDT + 18h], si
.track3_passed:

			mov		byte [bp + Spc.NeedArbitrate], 01h
			sti
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���t�X�s�[�h�̕ύX =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = ���t�X�s�[�h(1..256)
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_change_speed:
			FUNCCALLIN

			READSLOTNUM

			mov		ax, HCERR_INVALID_PARAM
			mov		dx, [bp + 8]
			cmp		dx, 1
			jc		.exit
			cmp		dx, 256
			ja		.exit

			imul		dx, byte 64
			cli
			mov		[si + Slt.PlaySpeed], dx
			or		byte [si + Slt.Request], REQ_MF_TEMPO
			sti
			mov		ax, HCERR_OK

.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �}�X�^�[�{�����[���̕ύX =====
	;In  ; [bp + 6](w) = �X���b�g�ԍ�
	;In  ; [bp + 8](w) = �g���b�N�ԍ�(bit0:�g���b�N0�Abit1:�g���b�N1�A�c)
	;In  ; [bp +10](w) = �}�X�^�[�{�����[��(0..15)
				;In  ; [bp +12](w) = ���[�h
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_change_mastervol:
			FUNCCALLIN

			READSLOTNUM
			mov		al, [bp + 8]
			mov		ah, [bp + 10]
			cli
			and		al, [si + Slt.InUseTrackBit]

			shr		al, 1
			jnc		.track0_passed
			mov		[si + Slt.Track0MasterVol], ah
.track0_passed:
			shr		al, 1
			jnc		.track1_passed
			mov		[si + Slt.Track1MasterVol], ah
.track1_passed:
			shr		al, 1
			jnc		.track2_passed
			mov		[si + Slt.Track2MasterVol], ah
.track2_passed:
			shr		al, 1
			jnc		.track3_passed
			mov		[si + Slt.Track3MasterVol], ah
.track3_passed:
			sti
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �R���_�N�g�E�V�[�P���X�̊J�n =====
	;In  ; [bp + 6](d) = �R���_�N�g�E�V�[�P���X�ւ�far�|�C���^
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_start_cs:
			FUNCCALLIN

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �R���_�N�g�E�V�[�P���X�̒�~ =====
	;In  ; �Ȃ�
	;Out ; ax = �G���[�R�[�h(��ɐ���)
	;S.E.; 
__hcat_stop_cs:
			FUNCCALLIN

			and		byte [Drv.CSStatus], 7fh
			mov		ax, HCERR_OK

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �h���C�o�̓��샂�[�h�̐ݒ� =====
	;In  ; [bp + 6](w) = �@�\�ԍ�
	;In  ; [bp + 8](w) = �p�����[�^
	;Out ; ax = �G���[�R�[�h
	;S.E.; 
__hcat_set_driver_mode:
			FUNCCALLIN

			mov		bl, [bp + 6]
			mov		ax, [bp + 8]
			cmp		bl, 00h
			je		.func0
			mov		ax, HCERR_INVALID_PARAM
			jmp		.exit

		;�����X�s�[�J�̃X�P�[�����O�l�ݒ�
.func0:
			and		al, 03h
			shl		al, 1
			mov		si, [Drv.ChnBufCurr]
			cli
			mov		ah, [si + ChnBuf.OutputMode]
			and		ah, 0f9h
			or		ah, al
			mov		[si + ChnBuf.OutputMode], ah
			sti
			mov		ax, HCERR_OK
.exit:
			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �\��1 =====
__hcat_reserve1:
			FUNCCALLIN

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �\��2 =====
__hcat_reserve2:
			FUNCCALLIN

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �\��3 =====
__hcat_reserve3:
			FUNCCALLIN

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �\��4 =====
__hcat_reserve4:
			FUNCCALLIN

			FUNCCALLOUT

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �\��5 =====
__hcat_reserve5:
			FUNCCALLIN

			FUNCCALLOUT
