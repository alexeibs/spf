spf
===

SPF - Spline Photo Filter, simple command line tool written on [D language](http://dlang.org/)

###usage

Command line format: *spf spline-points-sorted-by-x input output*

Example: ```spf 0.3,0.4,0.6,0.7 input.jpg output.jpg```

Each spline point are specified by pair of numbers. Points (0, 0) and (1, 1) are included implicitly.
Format of the output file is the same as the input format. JPEG outputs are saved with 100% quality.

###download

[win32 binary](http://alexeibs.github.io/spf/spf-win32.7z)
