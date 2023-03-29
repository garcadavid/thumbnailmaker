
// this file was written by an instructor
// ***************************************************************************

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <iomanip>
#include <cmath>

using namespace std;

// ***************************************************************
//  Prototypes for external functions.
//	The "C" specifies to use the standard C/C++ style
//	calling convention.

extern "C" bool getfilename(int, char* [], FILE **, FILE **);
extern "C" bool setheader(FILE *, FILE *, int *, int *, int, int);
extern "C" bool readRow(FILE *, int, unsigned char []);
extern "C" bool writeRow(FILE *, int, unsigned char []);

// ***************************************************************
//  Basic C++ program (does not use any objects).

int main(int argc, char* argv[])
{

// --------------------------------------------------------------------
//  Declare variables and simple display header
//	By default, C++ integers are doublewords (32-bits).

	string	bars;
	bars.append(50,'-');

	const	int	thumbWidth = 300;
	const	int	thumbHeight = 200;

	FILE		*originalImage, *thumbImage;
	int		picHeight, picWidth;
	double		widthRatio;
	double		heightRatio;
	unsigned char	*oldRow;
	unsigned char	*newRow;
	int		idx;
	int		thumbIndex;
	int		newIndex;
	int		currRow;

// --------------------------------------------------------------------
//  If command line arguments OK
//	get imgae size
//	loop to perform downsampling

	if (getfilename(argc, argv, &originalImage, &thumbImage)) {

		if (!setheader(originalImage, thumbImage,
				&picWidth, &picHeight,
				thumbWidth, thumbHeight))
			return	0;

		widthRatio = static_cast<double>(picWidth) /
				static_cast<double>(thumbWidth);
		heightRatio = static_cast<double>(picHeight) /
				static_cast<double>(thumbHeight);

		oldRow = new unsigned char [picWidth*3];
		newRow = new unsigned char [thumbWidth*3];

		thumbIndex = 0;
		newIndex = 0;
		currRow = 0;

		while (thumbIndex < thumbHeight) {

			if (!readRow(originalImage, picWidth, oldRow))
				break;
			currRow++;

			for (int c = 0; c < (thumbWidth*3); c+=3) {
				idx = static_cast<int>(static_cast<double>(c)
						* widthRatio);
				idx = (idx/3)*3;
				newRow[c] = oldRow[idx];
				newRow[c+1] = oldRow[idx+1];
				newRow[c+2] = oldRow[idx+2];
			}

			if (!writeRow(thumbImage, thumbWidth, newRow))
				break;

			thumbIndex++;
			newIndex = static_cast<int>(static_cast<double>(thumbIndex)
						* heightRatio);

			while (currRow < newIndex) {
				if (!readRow(originalImage, picWidth, oldRow))
					exit(EXIT_FAILURE);
				currRow++;
			}
		}
		delete [] newRow;
		delete [] oldRow;
	}

// --------------------------------------------------------------------
//  Note, file are closed automatically by OS.
//  All done...

	return 0;
}

