/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - track                                                  */

package hcm;
import java.io.*;
import java.util.*;

public class Track
{
	int octave;
	int defaultLen;
	int loopNest;
	int slurCount;
	LinkedList tokenList;
	ByteArrayOutputStream baos;

	public Track()
	{
		octave = 4;
		defaultLen = 48;
		loopNest = 0;
		slurCount = 0;
		baos = new ByteArrayOutputStream();
	}

	public void writeByte(int b)
	{
		baos.write(b);
	}

	public void writeNote(int note, int abslen)
	{
		if (abslen < 0) {
			writeByte(note << 1);
		} else {
			writeByte((note << 1) | 0x01);
			if (abslen < 240) {
				writeByte(abslen);
			} else {
				writeByte(((abslen >> 8) & 0x0f) | 0xf0);
				writeByte(abslen & 0xff);
			}
		}
	}

	public int getSize()
	{
		return baos.size();
	}
	public void writeTo(OutputStream out) throws IOException
	{
		baos.writeTo(out);
	}
}
