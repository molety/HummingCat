;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     envelope processing                                             ;

			bits 16

%define _HCENV_

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
			global		init_ampenv
			global		proceed_ampenv_to_release
			global		process_ampenv
			global		init_pchenv
			global		process_pchenv

	;===== ルーチンの説明 =====
	;In  ; 入力レジスタ/スタック (スタックは[bp + 6]がトップ)
	;Out ; 出力レジスタ
	;S.E.; 副作用(side effect)

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音量エンベロープの初期化 =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; 
init_ampenv:
			MULTIPUSH	ax
			mov		ax, [di + Trk.AmpEnvOfs]
			add		ax, 2
			mov		[di + Trk.AmpEnvReadPtr], ax
			mov		byte [di + Trk.AmpEnvVol], 15
			mov		byte [di + Trk.AmpEnvPanPot], 0
			mov		word [di + Trk.AmpEnvWaitCnt], 0001h
			MULTIPOP	ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音量エンベロープをリリース部へ移行 =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; 
proceed_ampenv_to_release:
			MULTIPUSH	si, es
			mov		si, [di + Trk.AmpEnvOfs]
			mov		es, [di + Trk.AmpEnvSeg]
			add		si, [es:si]
			mov		[di + Trk.AmpEnvReadPtr], si
			mov		word [di + Trk.AmpEnvWaitCnt], 0001h
			MULTIPOP	si, es
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音量エンベロープの処理 =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; 読んだ分だけTrk.AmpEnvReadPtrを増加
process_ampenv:
			dec		word [di + Trk.AmpEnvWaitCnt]
			jz		.env_top
			retn

.env_top:
			MULTIPUSH	ax, si, es
			mov		si, [di + Trk.AmpEnvReadPtr]
			mov		es, [di + Trk.AmpEnvSeg]
.env_main:
			mov		al, [es:si]
			inc		si
			sar		al, 1
			jnc		.env_loop

			sar		al, 1
			jnc		.env_panpot

.env_vol:
		;音量(絶対/相対)
			sar		al, 1
			jnc		.env_vol2
			add		al, [di + Trk.AmpEnvVol]
.env_vol2:
			SIGNEDBOUND	al, 0, 15
			mov		[di + Trk.AmpEnvVol], al
			mov		ax, [Drv.EnvInterval]
			mov		[di + Trk.AmpEnvWaitCnt], ax
			jmp		.exit

.env_panpot:
		;パンポット(絶対/相対)
			sar		al, 1
			jnc		.env_panpot2
			add		al, [di + Trk.AmpEnvPanPot]
.env_panpot2:
			SIGNEDBOUND	al, -15, 15
			mov		[di + Trk.AmpEnvPanPot], al
			jmp		.env_main

		;ループ/ウェイト
.env_loop:
			and		al, 7fh
			shr		al, 1
			jnc		.env_wait
			cmp		al, 3ch
			jnc		.env_loop2
			cmp		al, 01h
			je		.env_loopbottom
			xor		ah, ah
			jmp		.env_loop3
.env_loop2:
			and		al, 03h
			mov		ah, al
			mov		al, [es:si]
			inc		si
.env_loop3:
			mov		[di + Trk.AmpEnvLoopCnt], ax
			mov		[di + Trk.AmpEnvLoopTop], si
			jmp		.env_main
.env_loopbottom:
			mov		ax, [di + Trk.AmpEnvLoopCnt]
			sub		ax, 1			;decではだめ
			jc		.env_loopbottom2	;無限ループならカウンタ更新なし
			mov		[di + Trk.AmpEnvLoopCnt], ax
.env_loopbottom2:
			jz		.env_loopbottom3	;ループ終了なら読み取りポインタ更新なし
			mov		si, [di + Trk.AmpEnvLoopTop]
.env_loopbottom3:
			jmp		.env_main

.env_wait:
			cmp		al, 3ch
			jnc		.env_wait2
			or		al, al
			jz		.env_end
			xor		ah, ah
			jmp		.env_wait3
.env_wait2:
			and		al, 03h
			mov		ah, al
			mov		al, [es:si]
			inc		si
.env_wait3:
			mul		word [Drv.EnvInterval]
			mov		[di + Trk.AmpEnvWaitCnt], ax
			jmp		.exit

.env_end:
			dec		si

.exit:
			mov		[di + Trk.AmpEnvReadPtr], si
			MULTIPOP	ax, si, es
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音程エンベロープの初期化 =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; 
init_pchenv:
			MULTIPUSH	ax
			mov		ax, [di + Trk.PchEnvOfs]
			add		ax, 2
			mov		[di + Trk.PchEnvReadPtr], ax
			mov		word [di + Trk.PchEnvDetune], 0
			mov		word [di + Trk.PchEnvPitchShift], 0
			mov		word [di + Trk.PchEnvWaitCnt], 0001h
			MULTIPOP	ax
			retn

;-------- -------- -------- -------- -------- -------- -------- --------

			segment		TEXT

	;===== 音程エンベロープの処理 =====
	;In  ; ds:di = Trkワークエリアへのポインタ
	;Out ; 
	;S.E.; 読んだ分だけTrk.PchEnvReadPtrを増加
process_pchenv:
			dec		word [di + Trk.PchEnvWaitCnt]
			jz		.env_top
			retn

.env_top:
			MULTIPUSH	ax, bx, si, es
			mov		si, [di + Trk.PchEnvReadPtr]
			mov		es, [di + Trk.PchEnvSeg]
.env_main:
			mov		al, [es:si]
			inc		si
			sar		al, 1
			jnc		.env_loop

			mov		bl, al
			sar		al, 2
			cmp		al, -16
			je		.env_readdetune
			cbw
			jmp		.env_readdetune3
.env_readdetune:
			mov		al, [es:si]
			inc		si
			sar		al, 1
			jc		.env_readdetune2
			cbw
			jmp		.env_readdetune3
.env_readdetune2:
			mov		ah, al
			mov		al, [es:si]
			inc		si
.env_readdetune3:

			shr		bl, 1
			jnc		.env_pitchshift

.env_detune:
		;ディチューン(絶対/相対)
			shr		bl, 1
			jnc		.env_detune2
			add		ax, [di + Trk.PchEnvDetune]
.env_detune2:
			SIGNEDBOUND	ax, -2399, 2399
			mov		[di + Trk.PchEnvDetune], ax
			mov		ax, [Drv.EnvInterval]
			mov		[di + Trk.PchEnvWaitCnt], ax
			jmp		.exit

.env_pitchshift:
		;ピッチシフト(絶対/相対)
			shr		bl, 1
			jnc		.env_pitchshift2
			add		ax, [di + Trk.PchEnvPitchShift]
.env_pitchshift2:
			SIGNEDBOUND	ax, -2047, 2047
			mov		[di + Trk.PchEnvPitchShift], ax
			jmp		.env_main

		;ループ/ウェイト
.env_loop:
			and		al, 7fh
			shr		al, 1
			jnc		.env_wait
			cmp		al, 3ch
			jnc		.env_loop2
			cmp		al, 01h
			je		.env_loopbottom
			xor		ah, ah
			jmp		.env_loop3
.env_loop2:
			and		al, 03h
			mov		ah, al
			mov		al, [es:si]
			inc		si
.env_loop3:
			mov		[di + Trk.PchEnvLoopCnt], ax
			mov		[di + Trk.PchEnvLoopTop], si
			jmp		.env_main
.env_loopbottom:
			mov		ax, [di + Trk.PchEnvLoopCnt]
			sub		ax, 1			;decではだめ
			jc		.env_loopbottom2	;無限ループならカウンタ更新なし
			mov		[di + Trk.PchEnvLoopCnt], ax
.env_loopbottom2:
			jz		.env_loopbottom3	;ループ終了なら読み取りポインタ更新なし
			mov		si, [di + Trk.PchEnvLoopTop]
.env_loopbottom3:
			jmp		.env_main

.env_wait:
			cmp		al, 3ch
			jnc		.env_wait2
			or		al, al
			jz		.env_end
			xor		ah, ah
			jmp		.env_wait3
.env_wait2:
			and		al, 03h
			mov		ah, al
			mov		al, [es:si]
			inc		si
.env_wait3:
			mul		word [Drv.EnvInterval]
			mov		[di + Trk.PchEnvWaitCnt], ax
			jmp		.exit

.env_end:
			dec		si

.exit:
			mov		[di + Trk.PchEnvReadPtr], si
			MULTIPOP	ax, bx, si, es
			retn
