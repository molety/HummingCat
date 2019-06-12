/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - amplitude envelope                                     */

package hcm;
import java.io.*;

public class AmpEnv implements ChunkItem
{
	int number;
	ByteArrayOutputStream baos;
	int releasePartPtr;

	public AmpEnv(int n)
	{
		number = n;
		baos = new ByteArrayOutputStream();
		releasePartPtr = 0;
	}

	public void writeByte(int b)
	{
		baos.write(b);
	}

	public void setReleasePart()
	{
		releasePartPtr = 2 + baos.size();
	}

	// ChunkItem interface
	public int getSize()
	{
		return (2 + baos.size());
	}
	public int getNumber()
	{
		return number;
	}
	public void writeTo(OutputStream out) throws IOException
	{
		out.write(releasePartPtr & 0xff);
		out.write((releasePartPtr >> 8) & 0xff);
		baos.writeTo(out);
	}
}
