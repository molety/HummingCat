/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - waveform                                               */

package hcm;
import java.io.*;

public class WaveForm implements ChunkItem
{
	int number;
	int index;
	int[] buf;

	public WaveForm(int n)
	{
		number = n;
		index = 0;
		buf = new int[32];
	}

	public void write(int b)
	{
		if (index < 32) {
			buf[index++] = b;
		}
	}

	// ChunkItem interface
	public int getSize()
	{
		return 16;
	}
	public int getNumber()
	{
		return number;
	}
	public void writeTo(OutputStream out) throws IOException
	{
		for (int i = 0; i < 32; i += 2) {
			out.write(buf[i] | (buf[i + 1] << 4));
		}
	}
}
