;  Sound Driver 'Humming Cat' for WonderWitch                         ;
;                 Copyright (c) 2002-2003,2009,2019  molety           ;
;     symbol definitions                                              ;

	;���J���[�`���Q
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

	;�G���[�R�[�h
HCERR_OK		equ		0000h	;OK
HCERR_INTERNAL_ERROR	equ		0ffffh	;�����G���[
HCERR_NOT_INITIALIZED	equ		0fffeh	;�h���C�o��������
HCERR_MEM_NOT_ENOUGH	equ		0fffdh	;�������s��
HCERR_WRONG_SLOT	equ		0fffch	;�錾�O�̃X���b�g�ԍ�
HCERR_ALREADY_ASSIGNED_SLOT	equ	0fffbh	;���Ƀg���b�N���蓖�čς݂̃X���b�g
HCERR_TRACK_NOT_ENOUGH	equ		0fffah	;�g���b�N���s��
HCERR_INVALID_PARAM	equ		0fff9h	;�����ȃp�����[�^

	;�h���C�o�{�̂ւ̗v��
REQ_NONE		equ		00h	;�v���Ȃ�
REQ_MF_SET		equ		01h	;�X�R�A�f�[�^�̃Z�b�g
REQ_MF_REWIND		equ		02h	;�X���b�g�̊����߂�
REQ_MF_TEMPO		equ		04h	;�e���|/���t�X�s�[�h�̕ύX

	;�R���_�N�g�E�V�[�P���X
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

	;�X�R�A�f�[�^���̃R�}���h
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

	;����/�x���Ȃǂ̎��
TYPE_REST		equ		00h	;�x��
TYPE_WAIT		equ		01h	;�E�F�C�g
TYPE_NOTE		equ		02h	;����
TYPE_PORTAMENTO		equ		03h	;�|���^�����g

	;���[�N�G���A
;-------- -------- -------- -------- -------- -------- -------- --------

	;���ꃏ�[�N�G���A	(�K��IRAM��Ɋm��)
	;�ꕔ�������Ċ��荞�݃��[�`������p�Ȃ̂�
	;���[�U�[�v���Z�X������Q�Ƃ��Ă��Ӗ��̂���l�͓����Ȃ�
	struc Spc
.DSreg:			resw		1	;DS���W�X�^�l(DS:0000=Drv_start)
.Tempo:			resw		1	;�e���|�p���[�N�G���A
.SlotNum:		resb		1	;�������̃X���b�g�ԍ�
.SlotAdr:		resw		1	;�������̃X���b�g���[�N�G���A
.TrackNum:		resb		1	;�������̃g���b�N�ԍ�
.TrackAdr:		resw		1	;�������̃g���b�N���[�N�G���A
.UserSRAMBank:		resw		1	;���[�U�[�v���Z�X��SRAM�o���N�ԍ�
.PrevSRAMBank:		resw		1	;���荞�ݒ��O��SRAM�o���N�ԍ�
.NeedSRAMRestore:	resb		1	;SRAM�o���N�̕��A���K�v�Ȃ�1
.NeedArbitrate:		resb		1	;PCM�`�����l���������݌��̒��₪�K�v�Ȃ�1
.InIntrpt:		resb		1	;��d���荞�ݖh�~
.LCDSegment:		resw		1	;LCD�Z�O�����g�̏��(for debug)
			alignb		16
	endstruc	; struc Spc

	;�X���b�g���[�N�G���A
	struc Slt
		;__hcat_assign_track�Ō���
.n_AssignedTrack:	resb		1	;���蓖�Ă�ꂽ�g���b�N��
.AssignedTrackTop:	resw		1	;�擪�̃g���b�N���[�N�G���A�̃A�h���X
		;__hcat_set_score�Ō���
.n_InUseTrack:		resb		1	;�g���Ă���g���b�N��
.InUseTrackBit:		resb		1	;�g���Ă���g���b�N(bit0:�g���b�N0�A�c)
.ScoreOfs:		resw		1	;�X�R�A�f�[�^�̃A�h���X(Ofs)
.ScoreSeg:		resw		1	;�X�R�A�f�[�^�̃A�h���X(Seg)
.Track0WorkArea:	resw		1	;�g���b�N���[�N�G���A�̃A�h���X
.Track1WorkArea:	resw		1
.Track2WorkArea:	resw		1
.Track3WorkArea:	resw		1
.Priority:		resb		1	;�D��x * 2 (=0,2,4,6)
		;�󋵂ɂ���ĕω�
.Status:		resb		1	;bit6:current bit7:future ��~��0;���t��1
.Request:		resb		1	;�v���󂯕t������
.PlaySpeed:		resw		1	;���t�X�s�[�h(�W��16) * 64
.Track0MasterVol:	resb		1	;�}�X�^�[�{�����[��
.Track1MasterVol:	resb		1
.Track2MasterVol:	resb		1
.Track3MasterVol:	resb		1
.Tempo:			resw		1	;�e���|
.AbsLenPerIntrpt:	resw		1	;���荞�ݖ��̐�Ή����̑��� * 256
		;�������牺�́Amf_rewind���Ƀg���b�N���[�N�G���A�ƈꏏ�ɏ�����
.n_EndedTrack:		resb		1	;���t�I�������g���b�N��
.AbsLenCnt:		resw		1
.Ch2SweepDepth:		resb		1
.Ch2SweepTime:		resb		1
.Ch3Noise:		resb		1	;�m�C�Y���[�h(on->0..7, off->255)
			alignb		2
	endstruc	; struc Slt

	;�g���b�N���[�N�G���A
	struc Trk
.Status:		resb		1	;���t�I��0;������1;�L�[�I����2;�L�[�I�t�ナ���[�X��3
.Type:			resb		1	;�x��0;�E�F�C�g1;����2;�|���^�����g3
.ReadPtr:		resw		1	;�ǂݎ��|�C���^
.AbsLen:		resw		1	;��Ή���
.GateTime:		resw		1	;�Q�[�g�^�C��(��Ή����\��)
.PastTime:		resw		1	;�o�ߎ���(��Ή����\��)
.Note:			resb		1	;����
.Vol:			resb		1	;����
.PanPot:		resb		1	;�p���|�b�g�l
.SlurCnt:		resb		1	;�X���[�J�E���^
.InSlur:		resb		1	;�X���[�������t���O
.Detune:		resw		1	;�f�B�`���[����
.PitchShift:		resw		1	;BIOS(SOUND_SET_PITCH)�ݒ�l�ɑ΂���ψʗ�
.GateTimeRatio:		resb		1	;������
.DefaultLen:		resb		1	;�f�t�H���g����
.PortamentoRatio:	resw		1	;�|���^�����g�����ړ�����(�|���^�����g���łȂ���0)
.PortamentoDest:	resb		1	;�|���^�����g�I������
.WaveFormNum:		resb		1	;�g�`�f�[�^�ԍ�

.AmpEnvOfs:		resw		1	;���ʃG���x���[�v�f�[�^�̃A�h���X(Ofs)
.AmpEnvSeg:		resw		1	;���ʃG���x���[�v�f�[�^�̃A�h���X(Seg)
.AmpEnvReadPtr:		resw		1	;�ǂݎ��|�C���^
.AmpEnvLoopTop:		resw		1	;���[�v�g�b�v�̃A�h���X
.AmpEnvLoopCnt:		resw		1	;���[�v�J�E���^
.AmpEnvWaitCnt:		resw		1	;�E�F�C�g�J�E���^
.AmpEnvVol:		resb		1	;����
.AmpEnvPanPot:		resb		1	;�p���|�b�g�l

.PchEnvOfs:		resw		1	;�����G���x���[�v�f�[�^�̃A�h���X(Ofs)
.PchEnvSeg:		resw		1	;�����G���x���[�v�f�[�^�̃A�h���X(Seg)
.PchEnvReadPtr:		resw		1	;�ǂݎ��|�C���^
.PchEnvLoopTop:		resw		1	;���[�v�g�b�v�̃A�h���X
.PchEnvLoopCnt:		resw		1	;���[�v�J�E���^
.PchEnvWaitCnt:		resw		1	;�E�F�C�g�J�E���^
.PchEnvDetune:		resw		1	;�f�B�`���[����
.PchEnvPitchShift:	resw		1	;BIOS(SOUND_SET_PITCH)�ݒ�l�ɑ΂���ψʗ�

.LoopNestLevel:		resb		1	;���[�v�̓���q�̐[��
			alignb		2
.Loop0Top:		resw		1	;���[�v0�g�b�v�̃A�h���X
.Loop0Bottom:		resw		1	;���[�v0�{�g���̃A�h���X
.Loop0Cnt:		resb		1	;���[�v0�J�E���^(0:�������[�v)
			alignb		2
.Loop1Top:		resw		1	;���[�v1�g�b�v�̃A�h���X
.Loop1Bottom:		resw		1	;���[�v1�{�g���̃A�h���X
.Loop1Cnt:		resb		1	;���[�v1�J�E���^
			alignb		2
.Loop2Top:		resw		1	;���[�v2�g�b�v�̃A�h���X
.Loop2Bottom:		resw		1	;���[�v2�{�g���̃A�h���X
.Loop2Cnt:		resb		1	;���[�v2�J�E���^
			alignb		2
	endstruc	; struc Trk

	;PCM�`�����l�����[�N�G���A
	struc Chn
.ToneHeight:		resw		1	;����(4�Z���g�P��)
.BiosPitch:		resw		1	;BIOS(SOUND_SET_PITCH)�ݒ�l
.VolLeft:		resb		1	;����(��)
.VolRight:		resb		1	;����(�E)
.WaveFormNum:		resb		1	;�g�`�f�[�^�ԍ�
	endstruc	; struc Chn

	;PCM�`�����l�����o�b�t�@
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
.OutputMode:		resb		1	;SOUND_GET_OUTPUT�̒l
.ChannelMode:		resb		1	;SOUND_GET_CHANNEL�̒l
			alignb		2
	endstruc

	;�g�`�Q�ƃe�[�u��
	struc WaveForm
.Ofs:			resw		1
.Seg:			resw		1
	endstruc

	;���ʃG���x���[�v�Q�ƃe�[�u��
	struc AmpEnv
.Ofs:			resw		1
.Seg:			resw		1
	endstruc

	;�����G���x���[�v�Q�ƃe�[�u��
	struc PchEnv
.Ofs:			resw		1
.Seg:			resw		1
	endstruc


NumOfWaveForm		equ		32	;�g�`�f�[�^���̌Œ�l
NumOfAmpEnv		equ		32	;���ʃG���x���[�v���̌Œ�l
NumOfPchEnv		equ		32	;�����G���x���[�v���̌Œ�l
NumOfPriority		equ		4	;�D��x���x�����̌Œ�l

	;�h���C�o���[�N�G���A
	struc Drv
.SpcTop:		resw		1	;���ꃏ�[�N�G���A�̐擪
.TrackTop:		resw		1	;�g���b�N���[�N�G���A�̐擪
.n_Slot:		resb		1	;�X���b�g��(��)
.n_Track:		resb		1	;�g���b�N��(��)
.n_EmptyTrack:		resb		1	;���g�p�̃g���b�N��
.n_WaveForm		resb		1	;�g�`�f�[�^��(�Œ�)
.n_AmpEnv		resb		1	;���ʃG���x���[�v��(�Œ�)
.n_PchEnv		resb		1	;�����G���x���[�v��(�Œ�)
.n_Priority		resb		1	;�D��x���x����(�Œ�)

	;�R���_�N�g�E�V�[�P���X
.CSStatus:		resb		1	;CS�X�e�[�^�X(0:��~��;1:���쒆)
.CSOfs:			resw		1	;CS�ǂݎ��|�C���^(�I�t�Z�b�g)
.CSSeg:			resw		1	;CS�ǂݎ��|�C���^(�Z�O�����g)
.CSJumpMark:		resw		1	;CS�W�����v��}�[�N

	;�D��x�錾�e�[�u��(Priority Declare Table)
.PDT:			resw		NumOfPriority * 4

.IntrptFreq:		resw		1	;���荞�ݎ��g��(�W��75) * 5
.EnvInterval:		resw		1	;�G���x���[�v�Ԋu(�W��1)
.CSInterval:		resw		1	;conduct sequence�Ԋu(�W��5)

.HookChained:		resb		1	;�t�b�N���`�F�[������Ȃ�1
.HookChainOfs:		resw		1
.HookChainSeg:		resw		1

.ProfileFlag:		resb		1	;�v���t�@�C�����O�p�t���O

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
	;�_�u���o�b�t�@�̊e�o�b�t�@�̈���w���|�C���^
.ChnBufCurr:		resw		1
.ChnBufPrev:		resw		1

	;�������݋����ꂽ�X���b�g�̃A�h���X
.Ch0PermittedSlot:	resw		1
.Ch1PermittedSlot:	resw		1
.Ch2PermittedSlot:	resw		1
.Ch3PermittedSlot:	resw		1
	;�g�`�؂�ւ����Ƀt���OON
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
