/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - score                                                  */

package hcm;
import java.io.*;

public class Score implements ChunkItem
{
	int number;
	Track[] track;
	Comment comment;

	public Score(int n)
	{
		number = n;
		track = new Track[4];
		comment = new Comment();
	}

	public void setComment(String cm)
	{
		comment.set(cm);
	}

	// ChunkItem interface
	public int getSize()
	{
		int trackSize = 0;

		for (int i = 0; i < 4; i++) {
			if (track[i] != null)  trackSize += track[i].getSize();
		}
		return (10 + trackSize + comment.getSize());
	}
	public int getNumber()
	{
		return number;
	}
	public void writeTo(OutputStream out) throws IOException
	{
		int n_track = 0;
		int track_bit = 0;
		int offset = 10 + comment.getSize();

		for (int i = 0; i < 4; i++) {
			if (track[i] != null) {
				n_track++;
				track_bit |= (1 << i);
			}
		}
		out.write(n_track);
		out.write(track_bit);
		for (int i = 0; i < 4; i++) {
			if (track[i] != null) {
				out.write(offset);
				out.write(offset >> 8);
				offset += track[i].getSize();
			} else {
				out.write(0);
				out.write(0);
			}
		}
		out.write(comment.getContent());
		for (int i = 0; i < 4; i++) {
			if (track[i] != null) {
				track[i].writeTo(out);
			}
		}
	}
}
