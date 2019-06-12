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

	;===== ルーチンの説明 =====
	;In  ; 入力レジスタ/スタック (スタックは[bp + 6]がトップ)
	;Out ; 出力レジスタ
	;S.E.; 副作用(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 割り込み処理部(ドライバ本体) =====
__hcat_main:
				;この時点ではDS = IRAM上のSpcワークエリア
			cli
			cmp		byte [Spc.InIntrpt], 0
			je		.intrpt_ok
			sti
			retf
.intrpt_ok:		inc		byte [Spc.InIntrpt]
			sti

			MULTIPUSH	ax, bx, cx, dx, si, di, bp, ds, es

		;SRAMバンクの設定、DSの設定
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

		;プロファイリング用コード
			mov		byte [Drv.ProfileFlag], 01h

;	メインだよー
		;コンダクト・シーケンスの処理
	;			call		conduct_sequence

		;スロット処理の呼び出しループ
			mov		si, Drv.Slt_start	;Sltワークエリアの先頭
			mov		cl, [Drv.n_Slot]
			mov		ch, 00h
.loop_for_slot:
			mov		[bp + Spc.SlotAdr], si
			call		process_slot
			add		si, Slt_size
			loop		.loop_for_slot

		;優先度による調停処理
			cmp		byte [bp + Spc.NeedArbitrate], 01h
			jc		.skip_arbitrate
			call		arbitrate_permission
			mov		byte [bp + Spc.NeedArbitrate], 00h
.skip_arbitrate:

		;PCMチャンネルワークエリアへの書き込み
			call		write_channel_workarea

		;PCMチャンネルの駆動
			call		drive_pcm

		;絶対音長カウンタの更新
			call		update_counter


		;SRAMバンクの復帰
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

	;===== スロット処理 =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; 
	;S.E.; 
process_slot:
			MULTIPUSH	ax, bx, cx, si, di

		;制御部からの要求があるか調べて対応
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

		;Slt.n_EndedTrack == Slt.n_InUseTrackになったらスコア終端
			mov		al, [si + Slt.n_EndedTrack]
			cmp		al, [si + Slt.n_InUseTrack]
			jc		.not_ended
			call		mf_stop
			and		byte [si + Slt.Status], 3fh
			mov		byte [si + Slt.Request], REQ_MF_REWIND
			jmp		.scoreend_exit
.not_ended:

		;Spc.Tempo != Slt.Tempoならmf_tempoの呼び出しが必要
			mov		ax, [bp + Spc.Tempo]
			cmp		ax, [si + Slt.Tempo]
			je		.exit
			mov		[si + Slt.Tempo], ax
			call		mf_tempo

.exit:
			mov		byte [si + Slt.Request], REQ_NONE
.scoreend_exit:
		;future statusをcurrent statusに反映
			sar		byte [si + Slt.Status], 1

			MULTIPOP	ax, bx, cx, si, di
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== トラック処理 =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;In  ; ds:di = Trkワークエリアへのポインタ
	;In  ; es    = スコアデータのセグメント
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

		;トラック終端に達したかチェック
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

	;===== PCMチャンネル書き込み権の調停 =====
	;In  ; なし
	;Out ; なし
	;S.E.; 優先度宣言テーブルに従ってPCMチャンネルへの書き込み権を調停する
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

	;===== PCMチャンネルワークエリアへの書き込み =====
	;In  ; なし
	;Out ; なし
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
		;Ch3のみノイズモードの設定処理が入る
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

		;@@@!!! siを破壊するので注意 !!!
.write_sub:
		;@@@Trk.Status <= 1ならmuteでいいかも知れない
			cmp		byte [di + Trk.Status], 00h
			je		.write_sub_mute

			mov		al, [di + Trk.WaveFormNum]
			mov		[bx + Chn.WaveFormNum], al

			mov		al, [di + Trk.Vol]
			add		al, [di + Trk.AmpEnvVol]
			add		al, ah		;マスターボリューム値を加算
			sub		al, 30
			jnc		.write_sub2
			xor		al, al
.write_sub2:
			mov		cl, [di + Trk.PanPot]
			add		cl, [di + Trk.AmpEnvPanPot]
			SIGNEDBOUND	cl, -15, 15
			or		cl, cl
			jns		.write_sub4
		;パンポットが負の時(左>右)
			mov		[bx + Chn.VolLeft], al
			add		al, cl
			jc		.write_sub3
			xor		al, al
.write_sub3:
			mov		[bx + Chn.VolRight], al
			jmp		.write_sub6
		;パンポットが正の時(左<=右)
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

	;===== PCMチャンネル駆動 =====
	;In  ; なし
	;Out ; なし
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
			or		bl, 18h		;カウンタ制御ON
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
		;発音許可されたスロットがない時は消音する
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
;			mov		cx, (Chn_size * 4 + 6) / 2 ;@@@Chnワークエリアのサイズをちゃんと定義して使うべき
;		rep	movsw

.swap_curr_and_prev:
			mov		si, [Drv.ChnBufCurr]
			mov		di, [Drv.ChnBufPrev]
		;@@@ChannelMode, OutputModeはとりあえずコピー
		;@@@コピーせずに処理できる方法があればいずれ検討
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

	;===== 絶対音長カウンタの更新 =====
	;In  ; なし
	;Out ; なし
	;S.E.; 
update_counter:
			MULTIPUSH	ax, bx, cx, dx, si, di
			mov		si, Drv.Slt_start	;Sltワークエリアの先頭
			mov		cl, [Drv.n_Slot]
			mov		ch, 00h
.loop_for_slot:
			test		byte [si + Slt.Status], 80h
			jz		.loop_for_slot_skip

		;カウンタを進める計算
			mov		ax, [si + Slt.AbsLenCnt]
			mov		bx, ax
			mov		dx, [si + Slt.AbsLenPerIntrpt]
			add		ax, dx
			mov		[si + Slt.AbsLenCnt], ax
			sub		ah, bh
			mov		al, ah
			mov		ah, 00h

		;Trk.PastTimeにカウンタの増分を加算
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

	;===== Key-On処理 =====
	;In  ;    ax = 絶対音長(== Trk.AbsLen)
	;In  ;    bl = 音程
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; [di + Trk.GateTime]がセットされる
key_on:
			MULTIPUSH	ax, dx

		;ステータスの変更
			mov		byte [di + Trk.Status], 02h
		;音程の設定
			mov		[di + Trk.Note], bl

		;Trk.GateTimeの算出
		;(絶対音長0)Trk.GateTime = 0x7fff (12bitの最大値0x0fffより大きな値)
		;(スラー中 )Trk.GateTime = Trk.AbsLen
		;(通常     )Trk.GateTime = (Trk.AbsLen * Trk.GateTimeRatio) >> 3

	;			mov		ax, [di + Trk.AbsLen]
			or		ax, ax
			jz		.abslen0
			cmp		byte [di + Trk.InSlur], 01h
			je		.in_slur
			mov		dl, [di + Trk.GateTimeRatio]
			xor		dh, dh
			mul		dx		;結果はaxに収まるはず
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
		;(スラー中でなければ)音量エンベロープの初期化
			cmp		byte [di + Trk.InSlur], 01h
			je		.exit
			call		init_ampenv
		;(スラー中でなければ(スラー中でも?))音程エンベロープの初期化
			call		init_pchenv

.exit:
			MULTIPOP	ax, dx
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Key-Off処理 =====
key_off:
		;ステータスの変更
			mov		byte [di + Trk.Status], 03h
		;エンベロープをリリース部へ移行
			call		proceed_ampenv_to_release
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Mute処理 =====
mute:
		;ステータスの変更
			mov		byte [di + Trk.Status], 01h
		;音程を0にリセット(@@@消音条件の判定を改良すれば不要になるかも)
			mov		byte [di + Trk.Note], 00h
			retn

;-------- -------- -------- -------- -------- -------- -------- --------
;   Common sub routines
;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== スロットワークエリアの初期化 =====
	;In  ; ds:si = スロットワークエリアへのポインタ
	;Out ; 
	;S.E.; スロットワークエリアが初期化される
	;Slt_size = Slt構造体の大きさ
	;Slt_sizeが偶数でないと、最後1バイトをクリアし損なう
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

	;===== トラックワークエリアの初期化 =====
	;In  ; ds:di = トラックワークエリアへのポインタ
	;Out ; 
	;S.E.; トラックワークエリアが初期化される
	;Trk_size = Trk構造体の大きさ
	;Trk_sizeが偶数でないと、最後1バイトをクリアし損なう
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

	;===== LCDセグメントの点灯/消灯(for debug) =====
	;In  ; なし
	;Out ; なし
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
