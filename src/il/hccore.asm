;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     sound driver core                                               ;

			bits 16

%define _HCCORE_

%include		"..\wwbios.asm"
%include		"hcdef.asm"
%include		"hcmacro.asm"

			segment		_TEXT public class=CODE
			segment		TEXT  public class=CODE
			segment		_DATA public class=DATA
			segment		DATA  public class=DATA
			group		CGROUP _TEXT TEXT
			group		DGROUP _DATA DATA

			extern		_il_get_ds
			extern		_il_to_far
			extern		cn_table
			extern		mf_play
			extern		mf_stop
			extern		mf_set
			extern		mf_rewind
			extern		mf_tempo
			extern		read_scoredata
			extern		init_ampenv
			extern		proceed_ampenv_to_release
			extern		process_ampenv
			extern		init_pchenv
			extern		process_pchenv

			global		__hcat_main
			global		key_on
			global		mute
			global		init_slot
			global		init_track
			global		lcd0on
			global		lcd0off
			global		lcd0flash
			global		lcd1on
			global		lcd1off
			global		lcd1flash
			global		lcd2on
			global		lcd2off
			global		lcd2flash
			global		lcd3on
			global		lcd3off
			global		lcd3flash
			global		lcd4on
			global		lcd4off
			global		lcd4flash
			global		lcd5on
			global		lcd5off
			global		lcd5flash

	;===== ���[�`���̐��� =====
	;In  ; ���̓��W�X�^/�X�^�b�N (�X�^�b�N��[bp + 6]���g�b�v)
	;Out ; �o�̓��W�X�^
	;S.E.; ����p(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ���荞�ݏ�����(�h���C�o�{��) =====
__hcat_main:
				;���̎��_�ł�DS = IRAM���Spc���[�N�G���A
			cli
			cmp		byte [Spc.InIntrpt], 0
			je		.intrpt_ok
			sti
			retf
.intrpt_ok:		inc		byte [Spc.InIntrpt]
			sti

			MULTIPUSH	ax, bx, cx, dx, si, di, bp, ds, es

		;SRAM�o���N�̐ݒ�ADS�̐ݒ�
			mov		dl, 0
			mov		bl, 0		;0 = BANK_SRAM
			BIOS_BANK	BANK_GET_MAP
			mov		[Spc.PrevSRAMBank], ax
			cmp		ax, [Spc.UserSRAMBank]
			je		.srambank_ok
			mov		dl, 1
			mov		cx, [Spc.UserSRAMBank]
			BIOS_BANK	BANK_SET_MAP
.srambank_ok:
			mov		[Spc.NeedSRAMRestore], dl
			mov		ax, [Spc.DSreg]
			mov		ds, ax

			mov		bp, [Drv.SpcTop]

		;�v���t�@�C�����O�p�R�[�h
			mov		byte [Drv.ProfileFlag], 01h

;	���C������[
		;�R���_�N�g�E�V�[�P���X�̏���
	;			call		conduct_sequence

		;�X���b�g�����̌Ăяo�����[�v
			mov		si, Drv.Slt_start	;Slt���[�N�G���A�̐擪
			mov		cl, [Drv.n_Slot]
			mov		ch, 00h
.loop_for_slot:
			mov		[bp + Spc.SlotAdr], si
			call		process_slot
			add		si, Slt_size
			loop		.loop_for_slot

		;�D��x�ɂ�钲�⏈��
			cmp		byte [bp + Spc.NeedArbitrate], 01h
			jc		.skip_arbitrate
			call		arbitrate_permission
			mov		byte [bp + Spc.NeedArbitrate], 00h
.skip_arbitrate:

		;PCM�`�����l�����[�N�G���A�ւ̏�������
			call		write_channel_workarea

		;PCM�`�����l���̋쓮
			call		drive_pcm

		;��Ή����J�E���^�̍X�V
			call		update_counter


		;SRAM�o���N�̕��A
			cmp		byte [bp + Spc.NeedSRAMRestore], 0
			je		.no_restore_srambank
			mov		bl, 0		;0 = BANK_SRAM
			mov		cx, [bp + Spc.PrevSRAMBank]
			BIOS_BANK	BANK_SET_MAP
.no_restore_srambank:

			MULTIPOP	ax, bx, cx, dx, si, di, bp, ds, es

			cli
			dec		byte [Spc.InIntrpt]
			sti

			retf


;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �X���b�g���� =====
	;In  ; ds:si = Slt���[�N�G���A�ւ̃|�C���^
	;Out ; 
	;S.E.; 
process_slot:
			MULTIPUSH	ax, bx, cx, si, di

		;���䕔����̗v�������邩���ׂđΉ�
			mov		al, [si + Slt.Request]
			test		al, REQ_MF_SET
			jz		.p1
			call		mf_set
.p1:
			test		al, REQ_MF_REWIND
			jz		.p2
			call		mf_rewind
.p2:
			test		al, REQ_MF_TEMPO
			jz		.p3
			call		mf_tempo
.p3:

			test		byte [si + Slt.Status], 80h
			jz		.exit
			mov		es, [si + Slt.ScoreSeg]
			lea		bx, [si + Slt.Track0WorkArea]

			mov		ax, [si + Slt.Tempo]
			mov		[bp + Spc.Tempo], ax
			mov		cx, 4
.loop_for_track:
			mov		di, [bx]
			or		di, di
			jz		.loop_for_track_skip
			mov		[bp + Spc.TrackAdr], di
			push		ax
			mov		al, 4
			sub		al, cl
			mov		[bp + Spc.TrackNum], al
			pop		ax
			call		process_track
%ifdef DEBUG
			call		lcd0flash
%endif
.loop_for_track_skip:
			add		bx, 2
			loop		.loop_for_track

		;Slt.n_EndedTrack == Slt.n_InUseTrack�ɂȂ�����X�R�A�I�[
			mov		al, [si + Slt.n_EndedTrack]
			cmp		al, [si + Slt.n_InUseTrack]
			jc		.not_ended
			call		mf_stop
			and		byte [si + Slt.Status], 3fh
			mov		byte [si + Slt.Request], REQ_MF_REWIND
			jmp		.scoreend_exit
.not_ended:

		;Spc.Tempo != Slt.Tempo�Ȃ�mf_tempo�̌Ăяo�����K�v
			mov		ax, [bp + Spc.Tempo]
			cmp		ax, [si + Slt.Tempo]
			je		.exit
			mov		[si + Slt.Tempo], ax
			call		mf_tempo

.exit:
			mov		byte [si + Slt.Request], REQ_NONE
.scoreend_exit:
		;future status��current status�ɔ��f
			sar		byte [si + Slt.Status], 1

			MULTIPOP	ax, bx, cx, si, di
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �g���b�N���� =====
	;In  ; ds:si = Slt���[�N�G���A�ւ̃|�C���^
	;In  ; ds:di = Trk���[�N�G���A�ւ̃|�C���^
	;In  ; es    = �X�R�A�f�[�^�̃Z�O�����g
	;Out ; 
	;S.E.; 
process_track:
			cmp		byte [di + Trk.Status], 00h
			je		.exit

.loop_top:
			mov		ax, [di + Trk.PastTime]
			cmp		byte [di + Trk.Status], 02h
			jne		.p1
			cmp		ax, [di + Trk.GateTime]
			jc		.p1
			call		key_off
.p1:
			mov		dx, [di + Trk.AbsLen]
			cmp		ax, dx
			jc		.envelope
			sub		ax, dx
			mov		[di + Trk.PastTime], ax

			call		read_scoredata

		;�g���b�N�I�[�ɒB�������`�F�b�N
			cmp		byte [di + Trk.Status], 00h
			jne		.p2
			inc		byte [si + Slt.n_EndedTrack]
			jmp		.exit
.p2:
			cmp		byte [di + Trk.SlurCnt], 00h
			jna		.p3
			mov		byte [di + Trk.InSlur], 01h
			dec		byte [di + Trk.SlurCnt]
.p3:
			jmp		.loop_top


.envelope:
			call		process_ampenv
			call		process_pchenv

.exit:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== PCM�`�����l���������݌��̒��� =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; �D��x�錾�e�[�u���ɏ]����PCM�`�����l���ւ̏������݌��𒲒₷��
arbitrate_permission:
			MULTIPUSH	ax, bx, cx

			mov		cx, NumOfPriority
.track0:
			mov		bx, cx
			shl		bx, 1
			mov		ax, [bx + Drv.PDT + 00h - 2]
			or		ax, ax
			loopz		.track0
			mov		[Drv.Ch0PermittedSlot], ax

			mov		cx, NumOfPriority
.track1:
			mov		bx, cx
			shl		bx, 1
			mov		ax, [bx + Drv.PDT + 08h - 2]
			or		ax, ax
			loopz		.track1
			mov		[Drv.Ch1PermittedSlot], ax

			mov		cx, NumOfPriority
.track2:
			mov		bx, cx
			shl		bx, 1
			mov		ax, [bx + Drv.PDT + 10h - 2]
			or		ax, ax
			loopz		.track2
			mov		[Drv.Ch2PermittedSlot], ax

			mov		cx, NumOfPriority
.track3:
			mov		bx, cx
			shl		bx, 1
			mov		ax, [bx + Drv.PDT + 18h - 2]
			or		ax, ax
			loopz		.track3
			mov		[Drv.Ch3PermittedSlot], ax

			MULTIPOP	ax, bx, cx
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== PCM�`�����l�����[�N�G���A�ւ̏������� =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; 
write_channel_workarea:
			MULTIPUSH	ax, bx, cx, si, di

			mov		bx, [Drv.ChnBufCurr]
			lea		bx, [bx + ChnBuf.Ch0]
			mov		si, [Drv.Ch0PermittedSlot]
			or		si, si
			jz		.channel0_mute
			mov		di, [si + Slt.Track0WorkArea]
			mov		ah, [si + Slt.Track0MasterVol]
			call		.write_sub
			jmp		.channel0_end
.channel0_mute:
			call		.write_sub_mute
.channel0_end:
			add		bx, Chn_size
			mov		si, [Drv.Ch1PermittedSlot]
			or		si, si
			jz		.channel1_mute
			mov		di, [si + Slt.Track1WorkArea]
			mov		ah, [si + Slt.Track1MasterVol]
			call		.write_sub
			jmp		.channel1_end
.channel1_mute:
			call		.write_sub_mute
.channel1_end:
			add		bx, Chn_size
			mov		si, [Drv.Ch2PermittedSlot]
			or		si, si
			jz		.channel2_mute
			mov		di, [si + Slt.Track2WorkArea]
			mov		ah, [si + Slt.Track2MasterVol]
			call		.write_sub
			jmp		.channel2_end
.channel2_mute:
			call		.write_sub_mute
.channel2_end:
			add		bx, Chn_size
			mov		si, [Drv.Ch3PermittedSlot]
			or		si, si
			jz		.channel3_mute
		;Ch3�̂݃m�C�Y���[�h�̐ݒ菈��������
			mov		al, [si + Slt.Ch3Noise]
			push		bx
			mov		bx, [Drv.ChnBufCurr]
			mov		[bx + ChnBuf.Ch3Noise], al
			pop		bx
			mov		di, [si + Slt.Track3WorkArea]
			mov		ah, [si + Slt.Track3MasterVol]
			call		.write_sub
			jmp		.channel3_end
.channel3_mute:
			call		.write_sub_mute
.channel3_end:
			MULTIPOP	ax, bx, cx, si, di
			retn

.write_sub_mute:
			xor		ax, ax
			mov		[bx + Chn.ToneHeight], ax
			mov		[bx + Chn.VolLeft], al
			mov		[bx + Chn.VolRight], al
			retn

		;@@@!!! si��j�󂷂�̂Œ��� !!!
.write_sub:
		;@@@Trk.Status <= 1�Ȃ�mute�ł��������m��Ȃ�
			cmp		byte [di + Trk.Status], 00h
			je		.write_sub_mute

			mov		al, [di + Trk.WaveFormNum]
			mov		[bx + Chn.WaveFormNum], al

			mov		al, [di + Trk.Vol]
			add		al, [di + Trk.AmpEnvVol]
			add		al, ah		;�}�X�^�[�{�����[���l�����Z
			sub		al, 30
			jnc		.write_sub2
			xor		al, al
.write_sub2:
			mov		cl, [di + Trk.PanPot]
			add		cl, [di + Trk.AmpEnvPanPot]
			SIGNEDBOUND	cl, -15, 15
			or		cl, cl
			jns		.write_sub4
		;�p���|�b�g�����̎�(��>�E)
			mov		[bx + Chn.VolLeft], al
			add		al, cl
			jc		.write_sub3
			xor		al, al
.write_sub3:
			mov		[bx + Chn.VolRight], al
			jmp		.write_sub6
		;�p���|�b�g�����̎�(��<=�E)
.write_sub4:
			mov		[bx + Chn.VolRight], al
			sub		al, cl
			jnc		.write_sub5
			xor		al, al
.write_sub5:
			mov		[bx + Chn.VolLeft], al

.write_sub6:
			mov		al, [di + Trk.Note]
			or		al, al
			jz		.write_sub_mute
			xor		ah, ah
			imul		ax, byte 25
			add		ax, [di + Trk.Detune]
			add		ax, [di + Trk.PchEnvDetune]
			SIGNEDBOUND	ax, 0, 2399
			mov		[bx + Chn.ToneHeight], ax
			mov		si, ax
			MULTIPUSH	ax, ds
			call		_il_get_ds
			mov		ds, ax
			shl		si, 1
			mov		si, [si + cn_table]
			MULTIPOP	ax, ds
			add		si, [di + Trk.PitchShift]
			add		si, [di + Trk.PchEnvPitchShift]
			SIGNEDBOUND	si, 0, 2047
			mov		[bx + Chn.BiosPitch], si

			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== PCM�`�����l���쓮 =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; 
drive_pcm:
			MULTIPUSH	ax, bx, cx, dx, si, di, ds, es

			mov		si, [Drv.ChnBufCurr]
			mov		di, [Drv.ChnBufPrev]
			mov		bl, [si + ChnBuf.Ch3Noise]
			cmp		bl, [di + ChnBuf.Ch3Noise]
			je		.skip_noise
			cmp		bl, 08h
			jc		.noise_on
			mov		byte [si + ChnBuf.Ch3Noise], 0ffh
			and		byte [si + ChnBuf.ChannelMode], 7fh
			jmp		.skip_noise
.noise_on:
			or		byte [si + ChnBuf.ChannelMode], 80h
			or		bl, 18h		;�J�E���^����ON
			push		ax
			BIOS_SOUND	SOUND_SET_NOISE
			pop		ax

.skip_noise:
			mov		bl, [si + ChnBuf.ChannelMode]
			cmp		bl, [di + ChnBuf.ChannelMode]
			je		.skip_channel_mode
			push		ax
			BIOS_SOUND	SOUND_SET_CHANNEL
			pop		ax

.skip_channel_mode:
			mov		bl, [si + ChnBuf.OutputMode]
			cmp		bl, [di + ChnBuf.OutputMode]
			je		.skip_output_mode
			push		ax
			BIOS_SOUND	SOUND_SET_OUTPUT
			pop		ax

.skip_output_mode:
			lea		si, [si + ChnBuf.Ch0]
			lea		di, [di + ChnBuf.Ch0]
			xor		ax, ax
			mov		cx, 4
.loop_for_channel:
			mov		bx, ax
			shl		bx, 1
			cmp		word [bx + Drv.Ch0PermittedSlot], 0000h
			jne		.output_on
		;���������ꂽ�X���b�g���Ȃ����͏�������
			mov		bl, 00h		;Volume
			push		ax
			BIOS_SOUND	SOUND_SET_VOLUME
			pop		ax
			jmp		.skip3

.output_on:
			mov		bx, ax
			cmp		byte [bx + Drv.Ch0WaveFormChange], 0
			je		.skip1
			mov		bl, [si + Chn.WaveFormNum]
			xor		bh, bh
			imul		bx, 4
			MULTIPUSH	ax, ds
			mov		dx, [bx + Drv.WaveForm_start]
			mov		ds, [bx + Drv.WaveForm_start + 02h]
			BIOS_SOUND	SOUND_SET_WAVE
			MULTIPOP	ax, ds

.skip1:
			mov		bx, [si + Chn.BiosPitch]
			cmp		bx, [di + Chn.BiosPitch]
			je		.skip2
			push		ax
			BIOS_SOUND	SOUND_SET_PITCH
			pop		ax

.skip2:
			mov		bh, [si + Chn.VolLeft]
			mov		bl, [si + Chn.VolRight]
			cmp		bh, [di + Chn.VolLeft]
			jne		.set_vol
			cmp		bl, [di + Chn.VolRight]
			je		.skip3
.set_vol:
			shl		bh, 4
			or		bl, bh
%ifdef DEBUG
;			cmp		bx, 0000h
;			jne		.sss
			call		lcd4flash
.sss:
%endif
			push		ax
			BIOS_SOUND	SOUND_SET_VOLUME
			pop		ax

.skip3:
			add		si, Chn_size
			add		di, Chn_size
			inc		al
			loop		.loop_for_channel

;.copy_curr_to_prev:
;			lea		si, [Drv.Ch0Curr]
;			lea		di, [Drv.Ch0Prev]
;			mov		ax, ds
;			mov		es, ax
;			cld
;			mov		cx, (Chn_size * 4 + 6) / 2 ;@@@Chn���[�N�G���A�̃T�C�Y�������ƒ�`���Ďg���ׂ�
;		rep	movsw

.swap_curr_and_prev:
			mov		si, [Drv.ChnBufCurr]
			mov		di, [Drv.ChnBufPrev]
		;@@@ChannelMode, OutputMode�͂Ƃ肠�����R�s�[
		;@@@�R�s�[�����ɏ����ł�����@������΂����ꌟ��
			mov		bl, [si + ChnBuf.ChannelMode]
			mov		[di + ChnBuf.ChannelMode], bl
			mov		bl, [si + ChnBuf.OutputMode]
			mov		[di + ChnBuf.OutputMode], bl
			mov		[Drv.ChnBufCurr], di
			mov		[Drv.ChnBufPrev], si

			mov		byte [Drv.Ch0WaveFormChange], 0
			mov		byte [Drv.Ch1WaveFormChange], 0
			mov		byte [Drv.Ch2WaveFormChange], 0
			mov		byte [Drv.Ch3WaveFormChange], 0

			MULTIPOP	ax, bx, cx, dx, si, di, ds, es
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ��Ή����J�E���^�̍X�V =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; 
update_counter:
			MULTIPUSH	ax, bx, cx, dx, si, di
			mov		si, Drv.Slt_start	;Slt���[�N�G���A�̐擪
			mov		cl, [Drv.n_Slot]
			mov		ch, 00h
.loop_for_slot:
			test		byte [si + Slt.Status], 80h
			jz		.loop_for_slot_skip

		;�J�E���^��i�߂�v�Z
			mov		ax, [si + Slt.AbsLenCnt]
			mov		bx, ax
			mov		dx, [si + Slt.AbsLenPerIntrpt]
			add		ax, dx
			mov		[si + Slt.AbsLenCnt], ax
			sub		ah, bh
			mov		al, ah
			mov		ah, 00h

		;Trk.PastTime�ɃJ�E���^�̑��������Z
			push		cx
			lea		bx, [si + Slt.Track0WorkArea]
			mov		cx, 4
.loop_for_track:
			mov		di, [bx]
			or		di, di
			jz		.loop_for_track_skip
			add		[di + Trk.PastTime], ax
%ifdef DEBUG
			or		ax, ax
			jz		.s1
			call		lcd4on
.s1:
%endif
.loop_for_track_skip:
			add		bx, 2
			loop		.loop_for_track
			pop		cx

.loop_for_slot_skip:
			add		si, Slt_size
			loop		.loop_for_slot

			MULTIPOP	ax, bx, cx, dx, si, di
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Key-On���� =====
	;In  ;    ax = ��Ή���(== Trk.AbsLen)
	;In  ;    bl = ����
	;In  ; ds:di = Trk���[�N�G���A�ւ̃|�C���^
	;Out ; 
	;S.E.; [di + Trk.GateTime]���Z�b�g�����
key_on:
			MULTIPUSH	ax, dx

		;�X�e�[�^�X�̕ύX
			mov		byte [di + Trk.Status], 02h
		;�����̐ݒ�
			mov		[di + Trk.Note], bl

		;Trk.GateTime�̎Z�o
		;(��Ή���0)Trk.GateTime = 0x7fff (12bit�̍ő�l0x0fff���傫�Ȓl)
		;(�X���[�� )Trk.GateTime = Trk.AbsLen
		;(�ʏ�     )Trk.GateTime = (Trk.AbsLen * Trk.GateTimeRatio) >> 3

	;			mov		ax, [di + Trk.AbsLen]
			or		ax, ax
			jz		.abslen0
			cmp		byte [di + Trk.InSlur], 01h
			je		.in_slur
			mov		dl, [di + Trk.GateTimeRatio]
			xor		dh, dh
			mul		dx		;���ʂ�ax�Ɏ��܂�͂�
			shr		ax, 3
			mov		[di + Trk.GateTime], ax
			jmp		.env
.abslen0:
			mov		word [di + Trk.GateTime], 7fffh
			jmp		.env
.in_slur:
	;			mov		ax, [di + Trk.AbsLen]
			mov		[di + Trk.GateTime], ax

.env:
		;(�X���[���łȂ����)���ʃG���x���[�v�̏�����
			cmp		byte [di + Trk.InSlur], 01h
			je		.exit
			call		init_ampenv
		;(�X���[���łȂ����(�X���[���ł�?))�����G���x���[�v�̏�����
			call		init_pchenv

.exit:
			MULTIPOP	ax, dx
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Key-Off���� =====
key_off:
		;�X�e�[�^�X�̕ύX
			mov		byte [di + Trk.Status], 03h
		;�G���x���[�v�������[�X���ֈڍs
			call		proceed_ampenv_to_release
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Mute���� =====
mute:
		;�X�e�[�^�X�̕ύX
			mov		byte [di + Trk.Status], 01h
		;������0�Ƀ��Z�b�g(@@@���������̔�������ǂ���Εs�v�ɂȂ邩��)
			mov		byte [di + Trk.Note], 00h
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;   Common sub routines
;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �X���b�g���[�N�G���A�̏����� =====
	;In  ; ds:si = �X���b�g���[�N�G���A�ւ̃|�C���^
	;Out ; 
	;S.E.; �X���b�g���[�N�G���A�������������
	;Slt_size = Slt�\���̂̑傫��
	;Slt_size�������łȂ��ƁA�Ō�1�o�C�g���N���A�����Ȃ�
init_slot:
			MULTIPUSH	ax, cx, di, es
			mov		di, si
			mov		ax, ds
			mov		es, ax
			cld
			mov		cx, Slt_size / 2
			mov		ax, 0000h
		rep	stosw
			MULTIPOP	ax, cx, di, es

			mov		word [si + Slt.Tempo], 120
			mov		word [si + Slt.PlaySpeed], 16 * 64
			mov		byte [si + Slt.Track0MasterVol], 15
			mov		byte [si + Slt.Track1MasterVol], 15
			mov		byte [si + Slt.Track2MasterVol], 15
			mov		byte [si + Slt.Track3MasterVol], 15

			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== �g���b�N���[�N�G���A�̏����� =====
	;In  ; ds:di = �g���b�N���[�N�G���A�ւ̃|�C���^
	;Out ; 
	;S.E.; �g���b�N���[�N�G���A�������������
	;Trk_size = Trk�\���̂̑傫��
	;Trk_size�������łȂ��ƁA�Ō�1�o�C�g���N���A�����Ȃ�
init_track:
			MULTIPUSH	ax, cx, di, es
			mov		ax, ds
			mov		es, ax
			cld
			mov		cx, Trk_size / 2
			mov		ax, 0000h
		rep	stosw
			MULTIPOP	ax, cx, di, es

			MULTIPUSH	ax
			mov		byte [di + Trk.Status], 01h
			mov		byte [di + Trk.Vol], 13
			mov		byte [di + Trk.PanPot], 0
			mov		byte [di + Trk.GateTimeRatio], 7
			mov		byte [di + Trk.DefaultLen], 48
			mov		byte [di + Trk.WaveFormNum], 0
			mov		ax, [Drv.AmpEnv_start + AmpEnv.Ofs]
			mov		[di + Trk.AmpEnvOfs], ax
			mov		ax, [Drv.AmpEnv_start + AmpEnv.Seg]
			mov		[di + Trk.AmpEnvSeg], ax
			mov		ax, [Drv.PchEnv_start + PchEnv.Ofs]
			mov		[di + Trk.PchEnvOfs], ax
			mov		ax, [Drv.PchEnv_start + PchEnv.Seg]
			mov		[di + Trk.PchEnvSeg], ax
			MULTIPOP	ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== LCD�Z�O�����g�̓_��/����(for debug) =====
	;In  ; �Ȃ�
	;Out ; �Ȃ�
	;S.E.; 
lcd0on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0001h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd0off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0001h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd0flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0001h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn

lcd1on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0002h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd1off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0002h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd1flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0002h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn

lcd2on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0004h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd2off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0004h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd2flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0004h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn

lcd3on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0008h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd3off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0008h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd3flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0008h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn

lcd4on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0010h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd4off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0010h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd4flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0010h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn

lcd5on:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			or		bx, 0020h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd5off:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			and		bx, ~(0020h)
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
lcd5flash:
			MULTIPUSH	ax, bx
			mov		bx, [bp + Spc.LCDSegment]
			xor		bx, 0020h
			mov		[bp + Spc.LCDSegment], bx
			BIOS_DISP	LCD_SET_SEGMENTS
			MULTIPOP	ax, bx
			retn
