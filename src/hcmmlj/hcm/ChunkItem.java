/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - chunk item                                             */

package hcm;
import java.io.*;

interface ChunkItem
{
	int getSize();
	int getNumber();
	void writeTo(OutputStream out) throws IOException;
}
