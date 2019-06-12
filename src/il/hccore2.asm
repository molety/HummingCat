;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     score data reading                                              ;

			bits 16

%define _HCCORE2_

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
			extern		key_on
			extern		mute
			global		read_scoredata

	;===== ルーチンの説明 =====
	;In  ; 入力レジスタ/スタック (スタックは[bp + 6]がトップ)
	;Out ; 出力レジスタ
	;S.E.; 副作用(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== スコアデータの読み取り =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;In  ; es    = スコアデータのセグメント
	;Out ; 
	;S.E.; 読んだ分だけTrk.ReadPtrを増加
read_scoredata:
			MULTIPUSH	bx, si
			mov		si, [di + Trk.ReadPtr]
%ifdef DEBUG
			call		lcd1flash
%endif

.loop_top:
			mov		bl, [es:si]
			inc		si
			cmp		bl, 0c0h
			jnc		.read_command
			call		read_note
			jmp		.exit

.read_command:
			cmp		bl, CMD_TRACKEND
			jne		.jump_to_routines
			call		cmd_trackend
			jmp		.exit

.jump_to_routines:
			sub		bl, 0c0h
			shl		bl, 1
			xor		bh, bh
			call		[cs:bx + routine_table]
			jmp		.loop_top

.exit:
			mov		[di + Trk.ReadPtr], si
			MULTIPOP	bx, si
			retn

routine_table:
			dw		cmd_tempo, cmd_defaultlen, cmd_gatetimeratio, cmd_gatetimeratio
			dw		cmd_gatetimeratio, cmd_gatetimeratio, cmd_gatetimeratio, cmd_gatetimeratio
			dw		cmd_gatetimeratio, cmd_gatetimeratio, cmd_gatetimeratio, cmd_vol
			dw		cmd_vol, cmd_vol, cmd_vol, cmd_vol
			dw		cmd_vol, cmd_vol, cmd_vol, cmd_vol
			dw		cmd_vol, cmd_vol, cmd_vol, cmd_vol
			dw		cmd_vol, cmd_vol, cmd_vol, cmd_relvol
			dw		cmd_relvolup, cmd_relvoldown, cmd_panpot, cmd_relpanpot
			dw		cmd_detune, cmd_reldetune, cmd_pitchshift, cmd_relpitchshift
			dw		cmd_slur, cmd_slur, cmd_slur, cmd_slur
			dw		cmd_portamento, cmd_ch2sweep, cmd_ch3noise, cmd_waveform
			dw		cmd_ampenv, cmd_pchenv, cmd_looptop, cmd_loopbottom
			dw		cmd_loopexit, cmd_keyoff, reserve, reserve
			dw		reserve, reserve, reserve, reserve
			dw		reserve, reserve, reserve, reserve
			dw		reserve, reserve, cmd_checkpoint, cmd_trackend

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== ノート/休符/ウェイトの読み取り =====
	;In  ;    bl = 読んだスコアデータ
	;In  ; es:si = スコアデータへのポインタ
	;Out ; 
	;S.E.; 読んだ分だけsiを増加
read_note:
			shr		bl, 1
			jc		.len_specified
			mov		al, [di + Trk.DefaultLen]
			mov		ah, 00h
			jmp		.p1
.len_specified:
			call		read_note_len
.p1:
			mov		[di + Trk.AbsLen], ax

			cmp		bl, 01h
			jc		.rest
			je		.wait
.note:
			mov		byte [di + Trk.Type], TYPE_NOTE
			call		key_on
%ifdef DEBUG
			call		lcd2flash
%endif
			jmp		.exit
.rest:
			mov		byte [di + Trk.Type], TYPE_REST
			call		mute
			jmp		.exit
.wait:
			mov		byte [di + Trk.Type], TYPE_WAIT

.exit:
		;スラー処理中フラグoff
			mov		byte [di + Trk.InSlur], 00h
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音長指定の読み取り =====
	;In  ; es:si = スコアデータへのポインタ
	;Out ;    ax = 絶対音長(0～4095)
	;S.E.; 読んだ分だけsiを増加
read_note_len:
			mov		ah, 00h
			mov		al, [es:si]
			inc		si
			cmp		al, 0f0h
			jc		.exit
			and		al, 0fh
			mov		ah, al
			mov		al, [es:si]
			inc		si
.exit:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== トラック終端 =====
	;In  ; es:si = スコアデータへのポインタ
	;Out ; 
	;S.E.; Trk.Status = 0
	;S.E.; 読んだ分だけsiを増加
cmd_trackend:
			mov		byte [di + Trk.Status], 00h
%ifdef DEBUG
			call		lcd3on
%endif
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_tempo:
			mov		al, [es:si]
			inc		si
			mov		ah, [es:si]
			inc		si
			mov		[bp + Spc.Tempo], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_defaultlen:
			mov		al, [es:si]
			inc		si
			mov		[di + Trk.DefaultLen], al
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_gatetimeratio:
			shr		bl, 1
			sub		bl, 02h
			mov		[di + Trk.GateTimeRatio], bl
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_vol:
			shr		bl, 1
			sub		bl, 0bh
			mov		[di + Trk.Vol], bl
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_relvol:
			mov		al, [es:si]
			inc		si
			add		al, [di + Trk.Vol]
			SIGNEDBOUND	al, 0, 15
			mov		[di + Trk.Vol], al
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_relvolup:
			cmp		byte [di + Trk.Vol], 15
			jae		.skip
			inc		byte [di + Trk.Vol]
.skip:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_relvoldown:
			cmp		byte [di + Trk.Vol], 0
			jbe		.skip
			dec		byte [di + Trk.Vol]
.skip:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_panpot:
			mov		al, [es:si]
			inc		si
			mov		[di + Trk.PanPot], al
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_relpanpot:
			mov		al, [es:si]
			inc		si
			add		al, [di + Trk.PanPot]
			SIGNEDBOUND	al, -15, 15
			mov		[di + Trk.PanPot], al
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_detune:
			mov		al, [es:si]
			inc		si
			mov		ah, [es:si]
			inc		si
			mov		[di + Trk.Detune], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_reldetune:
			mov		al, [es:si]
			inc		si
			mov		ah, [es:si]
			inc		si
			add		ax, [di + Trk.Detune]
			SIGNEDBOUND	ax, -2399, 2399
			mov		[di + Trk.Detune], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_pitchshift:
			mov		al, [es:si]
			inc		si
			mov		ah, [es:si]
			inc		si
			mov		[di + Trk.PitchShift], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_relpitchshift:
			mov		al, [es:si]
			inc		si
			mov		ah, [es:si]
			inc		si
			add		ax, [di + Trk.PitchShift]
			SIGNEDBOUND	ax, -2047, 2047
			mov		[di + Trk.PitchShift], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_ch3noise:
			mov		al, [es:si]
			inc		si
			cmp		al, 08h
			jc		.noise_enable
			mov		al, 0ffh
.noise_enable:
			push		si
			mov		si, [bp + Spc.SlotAdr]
			mov		[si + Slt.Ch3Noise], al
			pop		si
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_waveform:
			mov		al, [es:si]
			inc		si
			mov		[di + Trk.WaveFormNum], al
			mov		bl, [bp + Spc.TrackNum]
			xor		bh, bh
			mov		byte [bx + Drv.Ch0WaveFormChange], 1
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_ampenv:
			mov		bl, [es:si]
			inc		si
			xor		bh, bh
			imul		bx, 4
			mov		ax, [bx + Drv.AmpEnv_start]
			mov		[di + Trk.AmpEnvOfs], ax
			mov		ax, [bx + Drv.AmpEnv_start + 02h]
			mov		[di + Trk.AmpEnvSeg], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_pchenv:
			mov		bl, [es:si]
			inc		si
			xor		bh, bh
			imul		bx, 4
			mov		ax, [bx + Drv.PchEnv_start]
			mov		[di + Trk.PchEnvOfs], ax
			mov		ax, [bx + Drv.PchEnv_start + 02h]
			mov		[di + Trk.PchEnvSeg], ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_looptop:
			mov		bl, [di + Trk.LoopNestLevel]
			inc		bl
			mov		[di + Trk.LoopNestLevel], bl
			xor		bh, bh
			imul		bx, 6
			mov		al, [es:si]
			inc		si
			mov		[bx + di + Trk.Loop0Top - 6 + 0], si
			mov		[bx + di + Trk.Loop0Top - 6 + 4], al
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_loopbottom:
			mov		bl, [di + Trk.LoopNestLevel]
			xor		bh, bh
			imul		bx, 6
			mov		[bx + di + Trk.Loop0Top - 6 + 2], si
			mov		al, [bx + di + Trk.Loop0Top - 6 + 4]
			sub		al, 1		;decではだめ
			jc		.skip_counter_update	;無限ループならカウンタ更新なし
			mov		[bx + di + Trk.Loop0Top - 6 + 4], al
.skip_counter_update:
			jz		.counter_zero
			mov		si, [bx + di + Trk.Loop0Top - 6 + 0]
			jmp		.exit
.counter_zero:
			dec		byte [di + Trk.LoopNestLevel]
.exit:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT
cmd_loopexit:
			mov		bl, [di + Trk.LoopNestLevel]
			xor		bh, bh
			imul		bx, 6
			mov		al, [bx + di + Trk.Loop0Top - 6 + 4]
			dec		al		;decで良い
			jnz		.exit
			mov		si, [bx + di + Trk.Loop0Top - 6 + 2]
			dec		byte [di + Trk.LoopNestLevel]
.exit:
			retn

cmd_slur:
cmd_portamento:
cmd_ch2sweep:
cmd_keyoff:
reserve:
cmd_checkpoint:
			retn
