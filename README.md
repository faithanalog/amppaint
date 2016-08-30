Amplitude Painter
=================

Spectral painter for use with anything that can do FM audio broadcasts. Tested
with [rpitx's](https://github.com/F5OEO/rpitx) pifm tool.


Build/Install
=============

This is a [stack](https://www.haskellstack.org) project.

    stack setup    #Install GHC if needed

    stack build    #Build amppaint

    stack install  #Install amppaint to $HOME/.local/bin


Usage
=====

    amppaint <infile> <outfile>

where your input is any image file (format does not matter as long as it can be
read by [JuicyPixels](http://hackage.haskell.org/package/JuicyPixels)), and your
output is a WAV file.

Your input image is expected to be a monochrome image. If it's not, amppain will
try to convert it to monochrome by taking the brightness of each pixel, keeping
any brighter than 50% and rejecting any darker than 50%.

For best results, convert your image to monochrome manually before handing it
over to amppaint.

Additionally, I use a width of **960px** for a nice resolution. The wider your
image, the larger your FFT will need to be, and the lower your waterfall update
rate will need to be to view it properly, so don't go too insane with it.

NOTE: This tool is designed for waterfall views which scroll from top to bottom.
If your tool scrolls from bottom to top you'll need to flip your image before
processing it.


Broadcast
=========

Head over to the [rpitx](https://github.com/F5OEO/rpitx) page and follow the
instructions for converting/transmitting with pifm. Tune in to the frequency
with a tool that can view the waterfall like GQRX, and see your image. You may
need to zoom in quite a bit to see it. make sure to use a high FFT size.

For GQRX, I generally start with

* FFT Size: 65536
* Rate: 20fps (or 25fps)
* Zoom: 16x

and then mess with my rate and zoom as needed to fix up the aspect ratio while
looking good.

![](http://i.ukl.me/2016-08-30-18:39:18-XcvbwAqJaiRGC0H7E3figGHwHdw~.png)
