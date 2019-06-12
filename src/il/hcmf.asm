;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     micro functions                                                 ;

			bits 16

%define _HCMF_

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
			extern		init_track
			global		declare_priority
			global		retract_priority
			global		mf_play
			global		mf_stop
			global		mf_set
			global		mf_rewind
			global		mf_tempo

	;===== ルーチンの説明 =====
	;In  ; 入力レジスタ/スタック (スタックは[bp + 6]がトップ)
	;Out ; 出力レジスタ
	;S.E.; 副作用(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 優先度の宣言 =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; なし
	;S.E.; ax/bx破壊、Spc.NeedArbitrate = 1
declare_priority:
			mov		al, [si + Slt.InUseTrackBit]
			mov		bl, [si + Slt.Priority]
			xor		bh, bh

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
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 優先度の取り下げ =====
	;宣言テーブル上の値が自分のものかどうか調べ、
	;自分の値であれば取り下げ
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; なし
	;S.E.; ax/bx/dx破壊、Spc.NeedArbitrate = 1
retract_priority:
			mov		bl, [si + Slt.Priority]
			xor		bh, bh
			xor		dx, dx

			cmp		si, [bx + Drv.PDT + 00h]
			jne		.track0_passed
			mov		[bx + Drv.PDT + 00h], dx
.track0_passed:
			cmp		si, [bx + Drv.PDT + 08h]
			jne		.track1_passed
			mov		[bx + Drv.PDT + 08h], dx
.track1_passed:
			cmp		si, [bx + Drv.PDT + 10h]
			jne		.track2_passed
			mov		[bx + Drv.PDT + 10h], dx
.track2_passed:
			cmp		si, [bx + Drv.PDT + 18h]
			jne		.track3_passed
			mov		[bx + Drv.PDT + 18h], dx
.track3_passed:
			mov		byte [bp + Spc.NeedArbitrate], 01h
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Micro Function 'mf_play' =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;In  ;    al = 発音モード(0:禁止、0以外:許可)
	;Out ; なし
	;S.E.; 
mf_play:
		;future statusの変更
			or		byte [si + Slt.Status], 80h

			or		al, al
			jz		.disable_mode
		;優先度宣言処理の呼び出し
			call		declare_priority
			retn
.disable_mode:
		;優先度取り下げ処理の呼び出し
			call		retract_priority
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Micro Function 'mf_stop' =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; なし
	;S.E.; 
mf_stop:
		;既にfuture statusがstopなら何もしない
			test		byte [si + Slt.Status], 80h
			jz		.exit
		;future statusの変更
			and		byte [si + Slt.Status], 7fh
		;優先度取り下げ処理の呼び出し
			call		retract_priority
.exit:
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Micro Function 'mf_set' =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; なし
	;S.E.; 
mf_set:
			MULTIPUSH	ax, bx
		;トラックワークエリアの実割り当て決定
			mov		word [si + Slt.Track0WorkArea], 0000h
			mov		word [si + Slt.Track1WorkArea], 0000h
			mov		word [si + Slt.Track2WorkArea], 0000h
			mov		word [si + Slt.Track3WorkArea], 0000h

			mov		al, [si + Slt.InUseTrackBit]
			mov		bx, [si + Slt.AssignedTrackTop]

			shr		al, 1
			jnc		.track0_passed
			mov		[si + Slt.Track0WorkArea], bx
			add		bx, Trk_size
.track0_passed:
			shr		al, 1
			jnc		.track1_passed
			mov		[si + Slt.Track1WorkArea], bx
			add		bx, Trk_size
.track1_passed:
			shr		al, 1
			jnc		.track2_passed
			mov		[si + Slt.Track2WorkArea], bx
			add		bx, Trk_size
.track2_passed:
			shr		al, 1
			jnc		.track3_passed
			mov		[si + Slt.Track3WorkArea], bx
			add		bx, Trk_size
.track3_passed:

			MULTIPOP	ax, bx
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Micro Function 'mf_rewind' =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;Out ; なし
	;S.E.; 
mf_rewind:
			MULTIPUSH	ax, bx, dx, di, es
			mov		bx, [si + Slt.ScoreOfs]
			mov		es, [si + Slt.ScoreSeg]
			mov		al, [si + Slt.InUseTrackBit]

		;トラックワークエリア初期化
			shr		al, 1
			jnc		.track0_passed
			mov		di, [si + Slt.Track0WorkArea]
			call		init_track
			mov		dx, [es:bx + 2]
			add		dx, bx
			mov		[di + Trk.ReadPtr], dx
.track0_passed:
			shr		al, 1
			jnc		.track1_passed
			mov		di, [si + Slt.Track1WorkArea]
			call		init_track
			mov		dx, [es:bx + 4]
			add		dx, bx
			mov		[di + Trk.ReadPtr], dx
.track1_passed:
			shr		al, 1
			jnc		.track2_passed
			mov		di, [si + Slt.Track2WorkArea]
			call		init_track
			mov		dx, [es:bx + 6]
			add		dx, bx
			mov		[di + Trk.ReadPtr], dx
.track2_passed:
			shr		al, 1
			jnc		.track3_passed
			mov		di, [si + Slt.Track3WorkArea]
			call		init_track
			mov		dx, [es:bx + 8]
			add		dx, bx
			mov		[di + Trk.ReadPtr], dx
.track3_passed:

			mov		byte [si + Slt.n_EndedTrack], 00h
			mov		word [si + Slt.AbsLenCnt], 0000h
			mov		byte [si + Slt.Ch2SweepDepth], 00h
			mov		byte [si + Slt.Ch2SweepTime], 00h
			mov		byte [si + Slt.Ch3Noise], 0ffh

			MULTIPOP	ax, bx, dx, di, es
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== Micro Function 'mf_tempo' =====
	;In  ; ds:si = Sltワークエリアへのポインタ
	;S.E.; Slt.AbsLenPerIntrptが設定される
mf_tempo:
			MULTIPUSH	ax, bx, dx
	;被除数の設定
			mov		ax, [si + Slt.PlaySpeed]
			mov		dx, [si + Slt.Tempo]
			mul		dx
	;除数の設定
			mov		bx, [Drv.IntrptFreq]
	;除算の実行
			div		bx
			mov		[si + Slt.AbsLenPerIntrpt], ax

			MULTIPOP	ax, bx, dx
			retn
