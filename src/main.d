import std.stdio;
import std.file;
import std.math;
import std.array;
import std.string;
import std.algorithm;
import std.conv;
import derelict.freeimage.freeimage;
import Spline;

double[] parseDoubleArray(string stringSpline)
{
    double[] result;
    foreach(string strNumber; split(stringSpline, ",")) {
        if (strNumber.isNumeric()) {
            double number = to!double(strNumber);
            result ~= number;
        }
    }
    return result;
}

Point[] getPoints2d(double[] points1d)
{
    int pointCount = points1d.length / 2;
    Point[] points = new Point[pointCount + 2];
    points[0].x = 0;
    points[0].y = 0;
    for (int i = 0; i < pointCount; ++i) {
        points[i + 1].x = points1d[i * 2];
        points[i + 1].y = points1d[i * 2 + 1];
    }
    points[pointCount + 1].x = 1;
    points[pointCount + 1].y = 1;

    return points;
}

BYTE applySplines(BYTE value, Poly[] splines)
{
    double newValue = splineValue(splines, value / 255.0);
    if (newValue < 0)
        newValue = 0;
    else if (newValue > 1)
        newValue = 1;
    return cast(BYTE)round(newValue * 255);
}

void main(string[] args)
{
    if (args.length != 4) {
        writeln("command line format: splinefilter 0.3,0.4 example.png output.png");
        return;
    }
    auto splineString = args[1];
    auto inputName = args[2].dup;
    auto outputName = args[3].dup;

    auto points1d = parseDoubleArray(splineString);
    Poly[] splines = calculateSplines(getPoints2d(points1d));

    DerelictFI.load();
    FreeImage_Initialise();
    scope(exit) FreeImage_DeInitialise();

    if (!exists(inputName)) {
        writefln("input file %s not found", inputName);
        return;
    }

    auto format = FreeImage_GetFileType(inputName.ptr, 0);
    if (format == FIF_UNKNOWN) {
        writeln("unknown file format");
        return;
    }

    auto bitmap = FreeImage_Load(format, inputName.ptr);
    scope(exit) FreeImage_Unload(bitmap);

    auto tmpBitmap = FreeImage_ConvertTo32Bits(bitmap);
    swap(tmpBitmap, bitmap);
    FreeImage_Unload(tmpBitmap);

    int width = FreeImage_GetWidth(bitmap);
    int height = FreeImage_GetHeight(bitmap);
    int nPixels = width * height;

    auto pixels = FreeImage_GetBits(bitmap);
    for (int i = 0; i < nPixels; ++i) {
        pixels[i * 4] = applySplines(pixels[i * 4], splines);
        pixels[i * 4 + 1] = applySplines(pixels[i * 4 + 1], splines);
        pixels[i * 4 + 2] = applySplines(pixels[i * 4 + 2], splines);
    }

    if (format != FIF_JPEG) {
        FreeImage_Save(format, bitmap, outputName.ptr);
    } else {
        auto bitmap24 = FreeImage_ConvertTo24Bits(bitmap);
        scope(exit) FreeImage_Unload(bitmap24);

        FreeImage_Save(format, bitmap24, outputName.ptr, JPEG_QUALITYSUPERB | JPEG_OPTIMIZE);
    }
}
