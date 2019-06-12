/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - comment                                                */

package hcm;
import java.io.*;

public class Comment
{
	String str;

	public Comment()
	{
		str = "";
	}

	public void set(String s)
	{
		str = s;
	}

	public int getSize()
	{
		int size = 1;

		try {
			size = str.getBytes("Shift_JIS").length + 1;
		} catch (UnsupportedEncodingException e) {}

		return size;
	}

	public byte[] getContent()
	{
		byte[] temp;
		byte[] content;

		try {
			temp = str.getBytes("Shift_JIS");
		} catch (UnsupportedEncodingException e) {
			temp = new byte[0];
		}

		content = new byte[temp.length + 1];
		for (int i = 0; i < temp.length; i++) {
			content[i] = temp[i];
		}
		content[temp.length] = 0;

		return content;
	}
}
