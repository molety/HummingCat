/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - version                                                */

package hcm;

public class Ver
{
	public static final int COMPILER_VER_ID = 0x0006;	// �R���p�C���o�[�W����
	public static final int PACK_VER_ID = 0x0002;		// �p�b�N�o�[�W����

	public static String getVerString(int ver)
	{
		String temp = "00" + Integer.toHexString(ver & 0xff);

		return (Integer.toHexString((ver >> 8) & 0xff) + "."
				+ temp.substring(temp.length() - 2));
	}
}
