/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - alignable output stream                                */

package hcm;
import java.io.*;

public class AlignOutputStream extends FilterOutputStream
{
	static final int PADDING_BYTE = 0xcc;
	int totalWrittenSize;

	public AlignOutputStream(OutputStream out)
	{
		super(out);
		totalWrittenSize = 0;
	}

	public void write(int b) throws IOException
	{
		super.write(b);
		totalWrittenSize++;
	}
/* �I�[�o�[���C�h���Ă͂����Ȃ�(totalWrittenSize���d�ɉ��Z���Ă��܂�)
	public void write(byte[] block) throws IOException
	{
		super.write(block);
		totalWrittenSize += block.length;
	}

	public void write(byte[] block, int offset, int size) throws IOException
	{
		super.write(block, offset, size);
		totalWrittenSize += size;
	}
 */
	// BYTE(1byte)��������
	public void writeByte(int b) throws IOException
	{
		super.write(b);
		totalWrittenSize++;
	}

	// WORD(2bytes)��������(���g���G���f�B�A��)
	public void writeWord(int b) throws IOException
	{
		super.write(b);
		super.write(b >>> 8);
		totalWrittenSize += 2;
	}

	// �A���C�������g�̂��߂Ƀp�f�B���O����
	public void paddingToAlign(int align) throws IOException
	{
		int padding_size = 0;

		if ((totalWrittenSize % align) > 0) {
			padding_size = align - (totalWrittenSize % align);
		}
		for (int i = 0; i < padding_size; i++) {
			super.write(PADDING_BYTE);
		}
		totalWrittenSize += padding_size;
	}
}
