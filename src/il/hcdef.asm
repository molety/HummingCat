;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     symbol definitions                                              ;

	;公開ルーチン群
%ifndef _HCCORE_
			extern		lcd0on
			extern		lcd0off
			extern		lcd0flash
			extern		lcd1on
			extern		lcd1off
			extern		lcd1flash
			extern		lcd2on
			extern		lcd2off
			extern		lcd2flash
			extern		lcd3on
			extern		lcd3off
			extern		lcd3flash
			extern		lcd4on
			extern		lcd4off
			extern		lcd4flash
			extern		lcd5on
			extern		lcd5off
			extern		lcd5flash
%endif

	;エラーコード
HCERR_OK		equ		0000h	;OK
HCERR_INTERNAL_ERROR	equ		0ffffh	;内部エラー
HCERR_NOT_INITIALIZED	equ		0fffeh	;ドライバ未初期化
HCERR_MEM_NOT_ENOUGH	equ		0fffdh	;メモリ不足
HCERR_WRONG_SLOT	equ		0fffch	;宣言外のスロット番号
HCERR_ALREADY_ASSIGNED_SLOT	equ	0fffbh	;既にトラック割り当て済みのスロット
HCERR_TRACK_NOT_ENOUGH	equ		0fffah	;トラック数不足
HCERR_INVALID_PARAM	equ		0fff9h	;無効なパラメータ

	;ドライバ本体への要求
REQ_NONE		equ		00h	;要求なし
REQ_MF_SET		equ		01h	;スコアデータのセット
REQ_MF_REWIND		equ		02h	;スロットの巻き戻し
REQ_MF_TEMPO		equ		04h	;テンポ/演奏スピードの変更

	;コンダクト・シーケンス
CS_NO			equ		00h	;none
CS_PL			equ		01h	;play
CS_CO			equ		02h	;continue
CS_ST			equ		03h	;stop
CS_EO			equ		04h	;enable output
CS_SP			equ		05h	;speed
CS_VA			equ		06h	;master-volume absolute
CS_VR			equ		07h	;master-volume relative
CS_WT			equ		08h	;wait
CS_JM			equ		09h	;jump mark
CS_JP			equ		0ah	;jump
CS_JVL			equ		0bh	;jump on master-volume less or equal
CS_JVG			equ		0ch	;jump on master-volume greater or equal
CS_JCL			equ		0dh	;jump on checkpoint count less or equal
CS_EN			equ		1fh	;end

	;スコアデータ中のコマンド
CMD_TEMPO		equ		0c0h
CMP_DEFAULTLEN		equ		0c1h
CMD_GATETIMERATIO0	equ		0c2h
CMD_VOL0		equ		0cbh
CMD_RELVOL		equ		0dbh
CMD_RELVOLUP		equ		0dch
CMD_RELVOLDOWN		equ		0ddh
CMD_PANPOT		equ		0deh
CMD_RELPANPOT		equ		0dfh
CMD_DETUNE		equ		0e0h
CMD_RELDETUNE		equ		0e1h
CMD_DETUNEREG		equ		0e2h
CMD_RELDETUNEREG	equ		0e3h
CMD_SLUR1		equ		0e4h
CMD_PORTAMENTO		equ		0e8h
CMD_CH2SWEEP		equ		0e9h
CMD_CH3NOISE		equ		0eah
CMD_WAVEFORM		equ		0ebh
CMD_AMPENV		equ		0ech
CMD_PCHENV		equ		0edh
CMD_LOOPTOP		equ		0eeh
CMD_LOOPBOTTOM		equ		0efh
CMD_LOOPEXIT		equ		0f0h
CMD_KEYOFF		equ		0f1h

CMD_CHECKPOINT		equ		0feh
CMD_TRACKEND		equ		0ffh

	;音符/休符などの種別
TYPE_REST		equ		00h	;休符
TYPE_WAIT		equ		01h	;ウェイト
TYPE_NOTE		equ		02h	;音符
TYPE_PORTAMENTO		equ		03h	;ポルタメント

	;ワークエリア
;-------- -------- -------- -------- -------- -------- -------- --------

	;特殊ワークエリア	(必ずIRAM上に確保)
	;一部を除いて割り込みルーチン内専用なので
	;ユーザープロセス側から参照しても意味のある値は得られない
	struc Spc
.DSreg:			resw		1	;DSレジスタ値(DS:0000=Drv_start)
.Tempo:			resw		1	;テンポ用ワークエリア
.SlotNum:		resb		1	;処理中のスロット番号
.SlotAdr:		resw		1	;処理中のスロットワークエリア
.TrackNum:		resb		1	;処理中のトラック番号
.TrackAdr:		resw		1	;処理中のトラックワークエリア
.UserSRAMBank:		resw		1	;ユーザープロセスのSRAMバンク番号
.PrevSRAMBank:		resw		1	;割り込み直前のSRAMバンク番号
.NeedSRAMRestore:	resb		1	;SRAMバンクの復帰が必要なら1
.NeedArbitrate:		resb		1	;PCMチャンネル書き込み権の調停が必要なら1
.InIntrpt:		resb		1	;二重割り込み防止
.LCDSegment:		resw		1	;LCDセグメントの状態(for debug)
			alignb		16
	endstruc	; struc Spc

	;スロットワークエリア
	struc Slt
		;__hcat_assign_trackで決定
.n_AssignedTrack:	resb		1	;割り当てられたトラック数
.AssignedTrackTop:	resw		1	;先頭のトラックワークエリアのアドレス
		;__hcat_set_scoreで決定
.n_InUseTrack:		resb		1	;使われているトラック数
.InUseTrackBit:		resb		1	;使われているトラック(bit0:トラック0、…)
.ScoreOfs:		resw		1	;スコアデータのアドレス(Ofs)
.ScoreSeg:		resw		1	;スコアデータのアドレス(Seg)
.Track0WorkArea:	resw		1	;トラックワークエリアのアドレス
.Track1WorkArea:	resw		1
.Track2WorkArea:	resw		1
.Track3WorkArea:	resw		1
.Priority:		resb		1	;優先度 * 2 (=0,2,4,6)
		;状況によって変化
.Status:		resb		1	;bit6:current bit7:future 停止中0;演奏中1
.Request:		resb		1	;要求受け付け窓口
.PlaySpeed:		resw		1	;演奏スピード(標準16) * 64
.Track0MasterVol:	resb		1	;マスターボリューム
.Track1MasterVol:	resb		1
.Track2MasterVol:	resb		1
.Track3MasterVol:	resb		1
.Tempo:			resw		1	;テンポ
.AbsLenPerIntrpt:	resw		1	;割り込み毎の絶対音長の増分 * 256
		;ここから下は、mf_rewind時にトラックワークエリアと一緒に初期化
.n_EndedTrack:		resb		1	;演奏終了したトラック数
.AbsLenCnt:		resw		1
.Ch2SweepDepth:		resb		1
.Ch2SweepTime:		resb		1
.Ch3Noise:		resb		1	;ノイズモード(on->0..7, off->255)
			alignb		2
	endstruc	; struc Slt

	;トラックワークエリア
	struc Trk
.Status:		resb		1	;演奏終了0;消音中1;キーオン中2;キーオフ後リリース中3
.Type:			resb		1	;休符0;ウェイト1;音符2;ポルタメント3
.ReadPtr:		resw		1	;読み取りポインタ
.AbsLen:		resw		1	;絶対音長
.GateTime:		resw		1	;ゲートタイム(絶対音長表現)
.PastTime:		resw		1	;経過時間(絶対音長表現)
.Note:			resb		1	;音程
.Vol:			resb		1	;音量
.PanPot:		resb		1	;パンポット値
.SlurCnt:		resb		1	;スラーカウンタ
.InSlur:		resb		1	;スラー処理中フラグ
.Detune:		resw		1	;ディチューン量
.PitchShift:		resw		1	;BIOS(SOUND_SET_PITCH)設定値に対する変位量
.GateTimeRatio:		resb		1	;音長比
.DefaultLen:		resb		1	;デフォルト音長
.PortamentoRatio:	resw		1	;ポルタメント音程移動割合(ポルタメント中でない時0)
.PortamentoDest:	resb		1	;ポルタメント終了音程
.WaveFormNum:		resb		1	;波形データ番号

.AmpEnvOfs:		resw		1	;音量エンベロープデータのアドレス(Ofs)
.AmpEnvSeg:		resw		1	;音量エンベロープデータのアドレス(Seg)
.AmpEnvReadPtr:		resw		1	;読み取りポインタ
.AmpEnvLoopTop:		resw		1	;ループトップのアドレス
.AmpEnvLoopCnt:		resw		1	;ループカウンタ
.AmpEnvWaitCnt:		resw		1	;ウェイトカウンタ
.AmpEnvVol:		resb		1	;音量
.AmpEnvPanPot:		resb		1	;パンポット値

.PchEnvOfs:		resw		1	;音程エンベロープデータのアドレス(Ofs)
.PchEnvSeg:		resw		1	;音程エンベロープデータのアドレス(Seg)
.PchEnvReadPtr:		resw		1	;読み取りポインタ
.PchEnvLoopTop:		resw		1	;ループトップのアドレス
.PchEnvLoopCnt:		resw		1	;ループカウンタ
.PchEnvWaitCnt:		resw		1	;ウェイトカウンタ
.PchEnvDetune:		resw		1	;ディチューン量
.PchEnvPitchShift:	resw		1	;BIOS(SOUND_SET_PITCH)設定値に対する変位量

.LoopNestLevel:		resb		1	;ループの入れ子の深さ
			alignb		2
.Loop0Top:		resw		1	;ループ0トップのアドレス
.Loop0Bottom:		resw		1	;ループ0ボトムのアドレス
.Loop0Cnt:		resb		1	;ループ0カウンタ(0:無限ループ)
			alignb		2
.Loop1Top:		resw		1	;ループ1トップのアドレス
.Loop1Bottom:		resw		1	;ループ1ボトムのアドレス
.Loop1Cnt:		resb		1	;ループ1カウンタ
			alignb		2
.Loop2Top:		resw		1	;ループ2トップのアドレス
.Loop2Bottom:		resw		1	;ループ2ボトムのアドレス
.Loop2Cnt:		resb		1	;ループ2カウンタ
			alignb		2
	endstruc	; struc Trk

	;PCMチャンネルワークエリア
	struc Chn
.ToneHeight:		resw		1	;音高(4セント単位)
.BiosPitch:		resw		1	;BIOS(SOUND_SET_PITCH)設定値
.VolLeft:		resb		1	;音量(左)
.VolRight:		resb		1	;音量(右)
.WaveFormNum:		resb		1	;波形データ番号
	endstruc	; struc Chn

	;PCMチャンネル情報バッファ
	struc ChnBuf
.Ch0:
			resb		Chn_size
.Ch1:
			resb		Chn_size
.Ch2:
			resb		Chn_size
.Ch3:
			resb		Chn_size
;@@@.Ch2SweepDepth:	resb		1
;@@@.Ch2SweepTime:	resb		1
.Ch3Noise:		resb		1
.OutputMode:		resb		1	;SOUND_GET_OUTPUTの値
.ChannelMode:		resb		1	;SOUND_GET_CHANNELの値
			alignb		2
	endstruc

	;波形参照テーブル
	struc WaveForm
.Ofs:			resw		1
.Seg:			resw		1
	endstruc

	;音量エンベロープ参照テーブル
	struc AmpEnv
.Ofs:			resw		1
.Seg:			resw		1
	endstruc

	;音程エンベロープ参照テーブル
	struc PchEnv
.Ofs:			resw		1
.Seg:			resw		1
	endstruc


NumOfWaveForm		equ		32	;波形データ数の固定値
NumOfAmpEnv		equ		32	;音量エンベロープ数の固定値
NumOfPchEnv		equ		32	;音程エンベロープ数の固定値
NumOfPriority		equ		4	;優先度レベル数の固定値

	;ドライバワークエリア
	struc Drv
.SpcTop:		resw		1	;特殊ワークエリアの先頭
.TrackTop:		resw		1	;トラックワークエリアの先頭
.n_Slot:		resb		1	;スロット数(可変)
.n_Track:		resb		1	;トラック数(可変)
.n_EmptyTrack:		resb		1	;未使用のトラック数
.n_WaveForm		resb		1	;波形データ数(固定)
.n_AmpEnv		resb		1	;音量エンベロープ数(固定)
.n_PchEnv		resb		1	;音程エンベロープ数(固定)
.n_Priority		resb		1	;優先度レベル数(固定)

	;コンダクト・シーケンス
.CSStatus:		resb		1	;CSステータス(0:停止中;1:動作中)
.CSOfs:			resw		1	;CS読み取りポインタ(オフセット)
.CSSeg:			resw		1	;CS読み取りポインタ(セグメント)
.CSJumpMark:		resw		1	;CSジャンプ先マーク

	;優先度宣言テーブル(Priority Declare Table)
.PDT:			resw		NumOfPriority * 4

.IntrptFreq:		resw		1	;割り込み周波数(標準75) * 5
.EnvInterval:		resw		1	;エンベロープ間隔(標準1)
.CSInterval:		resw		1	;conduct sequence間隔(標準5)

.HookChained:		resb		1	;フックをチェーンするなら1
.HookChainOfs:		resw		1
.HookChainSeg:		resw		1

.ProfileFlag:		resb		1	;プロファイリング用フラグ

			alignb		2
.WaveForm_start:
%rep NumOfWaveForm
			resb		WaveForm_size
%endrep

.AmpEnv_start:
%rep NumOfAmpEnv
			resb		AmpEnv_size
%endrep

.PchEnv_start:
%rep NumOfPchEnv
			resb		PchEnv_size
%endrep

			alignb		2
.Chn_start:
	;ダブルバッファの各バッファ領域を指すポインタ
.ChnBufCurr:		resw		1
.ChnBufPrev:		resw		1

	;書き込み許可されたスロットのアドレス
.Ch0PermittedSlot:	resw		1
.Ch1PermittedSlot:	resw		1
.Ch2PermittedSlot:	resw		1
.Ch3PermittedSlot:	resw		1
	;波形切り替え時にフラグON
.Ch0WaveFormChange:	resb		1
.Ch1WaveFormChange:	resb		1
.Ch2WaveFormChange:	resb		1
.Ch3WaveFormChange:	resb		1

			alignb		2
.ChnBufA_start:
			resb		ChnBuf_size

			alignb		2
.ChnBufB_start:
			resb		ChnBuf_size

			alignb		2
.Slt_start:
	endstruc	; struc Drv
