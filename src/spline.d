module Spline;

import std.range;
import std.math;

struct Point {
    double x, y;
};

struct Poly {
    double a = 0;
    double b = 0;
    double c = 0;
    double d = 0;
    double x0 = 0;
    int opCmp(const ref Poly p) const
    {
        return cast(int)sgn(x0 - p.x0);
    }
    bool opEquals(ref const Poly p) const
    {
        return x0 == p.x0;
    }
};

double splineValue(Poly spline, double x)
{
    x -= spline.x0;
    return ((spline.d * x + spline.c) * x + spline.b) * x + spline.a;
}

double splineValue(Poly[] splines, in double x)
{
    if (splines.empty)
        return double.nan;
    Poly s = {x0: x};
    auto lowerSplines = assumeSorted(splines).lowerBound(s);
    if (!lowerSplines.empty)
        return splineValue(lowerSplines[$ - 1], x);
    return s < splines[0] ? double.nan : splineValue(splines[0], x);
}

Poly[] linearSpline(Point[] points)
{
    Poly[] result = new Poly[1];
    result[0].x0 = points[0].x;
    result[0].a = points[0].y;
    result[0].b = (points[1].y - points[0].y) / (points[1].x - points[0].x);
    result[0].c = 0;
    result[0].d = 0;
    return result;
}

Poly[] calculateSplines(Point[] points)
{
    auto n = points.length - 1;
    if (n < 1)
        return new Poly[0];
    if (n == 1)
        return linearSpline(points);
        
    Poly[] splines = new Poly[n];
    double[] h = new double[n];
    double[] f = new double[n];
    double[] k = new double[n];
    double[] I = new double[n];
    
    h[0] = points[1].x - points[0].x,
    f[0] = (points[1].y - points[0].y) / h[0],
    k[0] = I[0] = 0;
    for (int i = 1; i < n; ++i) {
        h[i] = points[i + 1].x - points[i].x;
        f[i] = (points[i + 1].y - points[i].y) / h[i];
        auto s = (h[i - 1] + h[i]) * 2 - h[i - 1] * I[i - 1];
        auto r = (f[i] - f[i - 1]) * 3;
        k[i] = (r - h[i - 1] * k[i - 1]) / s;
        I[i] = h[i] / s;
    }

    splines[n - 1].c = k[n - 1];
    splines[n - 1].d = splines[n - 1].c / (-3 * h[n - 1]);
    splines[n - 1].b = f[n - 1] - splines[n - 1].c * h[n - 1] * 2.0 / 3.0;
    splines[n - 1].a = points[n - 1].y;
    splines[n - 1].x0 = points[n - 1].x;
    for(int i = n - 2; i >= 0; --i) {
        splines[i].c = k[i] - I[i] * splines[i + 1].c;
        splines[i].d = (splines[i + 1].c - splines[i].c) / (3 * h[i]);
        splines[i].b = f[i] - (splines[i + 1].c + 2 * splines[i].c) * h[i] / 3;
        splines[i].a = points[i].y;
        splines[i].x0 = points[i].x;
    }
    return splines;
}
