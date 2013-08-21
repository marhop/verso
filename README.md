# Verso - a simple XMP metadata editor for JPEG images

Verso is a tool for editing image metadata embedded in JPEG files. Metadata
may consist of information like description, date, creator, etc. and is stored
in [XMP format](https://en.wikipedia.org/wiki/Extensible_Metadata_Platform)
inside the JPEG files. (There is no support for EXIF or IPTC metadata!)

Verso is written in Perl and features a Gtk3 GUI. Metadata editing is based on
[Phil Harvey's ExifTool](http://www.sno.phy.queensu.ca/~phil/exiftool/).

## Status

The program is not completely finished yet (see the TODO items below), but it
can already be used to work with image metadata.

## Installation

Just put the `verso.pl` file (you may rename it) somewhere in your path, e.g.
`~/bin/verso` or `/opt/verso`. Then start it with:

    $ verso path/to/imagedirectory

## What about the name?

[Recto and verso](https://en.wikipedia.org/wiki/Recto_and_verso) are the
"front" and "back" sides of a leaf of paper. The metadata that can be edited
with Verso is the same one might have written on the back (aka verso) side of
a photo, back in the olden days of non-digital photography.

## TODO

* Figure out how to scale and auto rotate images in Gtk3 so they fit in the
  program window. (If anybody knows how to do this - please let me know!)

* Enable the file opening menu.

* Make metadata fields (and other stuff) configurable via a config file and/or
  a GUI menu instead of modifying the source code (although this is quite
  easy).

* Write some more documentation (perldoc/man).
