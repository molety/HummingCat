/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    memory functions                                                */

#include <sys/bios.h>
#include <sys/process.h>
#include "../bcat.h"

#define MAX_BLOCKS_LIMIT 1024
#define ADDR_LIMIT 0xffff

struct bc_mcb {			/* MemoryControlBlock */
	struct bc_mcb *Next;
	ushort TopAddr;
	ushort BlockSize;
};
typedef struct bc_mcb BC_MCB;

static unsigned maxBlocks = 0;
static BC_MCB *mcbEntry = NULL;
static unsigned mcbNum = 0;

int BCMem_Init(unsigned max_blocks);
void *BCMem_Alloc(ushort alloc_size, ushort align);
int BCMem_Free(void *ptr);
int BCMem_TestIntegrity(void);

/* ���������蓖�ă��[�`���Q�̏����� */
int BCMem_Init(unsigned max_blocks) {
	int i;

	if (max_blocks > MAX_BLOCKS_LIMIT) {
		return BCERR_OUT_OF_RANGE;
	}
	maxBlocks = max_blocks;

	mcbEntry = (BC_MCB *)(((unsigned)(_pc->_heap) + 1) & ~1);
	mcbNum = maxBlocks + 2;
	mcbEntry[0].TopAddr = (unsigned)mcbEntry + sizeof(BC_MCB) * mcbNum;
	mcbEntry[0].BlockSize = 0;
	mcbEntry[0].Next = &mcbEntry[1];
	mcbEntry[1].TopAddr = ADDR_LIMIT;
	mcbEntry[1].BlockSize = 0;
	mcbEntry[1].Next = NULL;			/* .Next = NULL�Ń��X�g�I�[ */

	for (i = 0; i < maxBlocks; i++) {
		mcbEntry[i + 2].TopAddr = 0;	/* .TopAddr = 0�Ŗ��g�p�G���g�� */
		mcbEntry[i + 2].BlockSize = 0;
		mcbEntry[i + 2].Next = NULL;
	}

	return BCERR_OK;
}

/* �������̊��蓖�� */
/* align��2�ׂ̂���Ɍ��� */
void *BCMem_Alloc(ushort alloc_size, ushort align) {
	BC_MCB *prev, *curr, *next;
	ushort gap_top;
	long gap_size;
	int i;

	/* �󂫃�������T�� */
	prev = mcbEntry;
	curr = prev->Next;
	while (curr != NULL) {
		gap_top = (prev->TopAddr + prev->BlockSize + align - 1) & ~(align - 1);
		gap_size = (long)(curr->TopAddr) - (long)gap_top;
		if (gap_size >= (long)alloc_size) {
			break;
		} else {
			prev = curr;
			curr = prev->Next;
		}
	}
	if (curr == NULL) return NULL;

	/* ��MCB��T�� */
	next = curr;
	curr = mcbEntry + 2;
	for (i = 0; i < maxBlocks; i++) {
		if (curr->TopAddr == 0) {
			break;
		}
		curr++;
	}
	if (i == maxBlocks) return NULL;

	/* MCB�ɓo�^���� */
	curr->TopAddr = gap_top;
	curr->BlockSize = alloc_size;
	curr->Next = next;
	prev->Next = curr;

	return (void *)(curr->TopAddr);
}

/* �������̉�� */
int BCMem_Free(void *ptr) {
	BC_MCB *prev, *curr;

	if (ptr == NULL || (ushort)ptr == ADDR_LIMIT) {
		return BCERR_INVALID_PARAM;
	}

	/* �Y������MCB��T�� */
	prev = mcbEntry;
	curr = prev->Next;
	while (curr != NULL) {
		if ((ushort)ptr == curr->TopAddr) {
			break;
		} else {
			prev = curr;
			curr = prev->Next;
		}
	}
	if (curr == NULL) return BCERR_INVALID_PARAM;

	/* ��������������� */
	prev->Next = curr->Next;
	curr->TopAddr = 0;
	curr->BlockSize = 0;
	curr->Next = NULL;

	return BCERR_OK;
}

/* ���������蓖�Ă�����ɍs���Ă��邩���� */
int BCMem_TestIntegrity(void) {
	BC_MCB *prev, *curr;
	ushort gap_top;
	long gap_size;

	prev = mcbEntry;
	curr = prev->Next;
	while (curr != NULL) {
		gap_top = prev->TopAddr + prev->BlockSize;
		gap_size = (long)(curr->TopAddr) - (long)gap_top;
		if (gap_size < 0) {
			return BCERR_FAILED;	/* �������u���b�N���d�Ȃ荇���Ă�����ُ� */
		} else {
			prev = curr;
			curr = prev->Next;
		}
	}

	return BCERR_OK;
}
