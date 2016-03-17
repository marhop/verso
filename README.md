# Verso

An (XMP/JPEG) image metadata editor.

## Rationale

Verso is a tool for editing metadata embedded in image files. Metadata can be
used for example to describe the image's content and the depicted persons, to
provide information about the date of its creation and to state its creator
and any rights/license information.

Verso's default configuration makes it an editor for [XMP][XMP] metadata
embedded in JPEG files. The metadata fields are structured with the [Dublin
Core][DC] elements Description, Date, Creator and Rights.

Since metadata editing is based on [Phil Harvey's ExifTool][ET] and Verso is
highly configurable you may adjust the metadata elements that can be displayed
and edited, as long as ExifTool can handle them. So Verso can easily be
adapted to edit for example IPTC or EXIF instead of (or in addition to) XMP
metadata, just by messing with the configuration file.

Verso is written in Perl and features a Gtk3 GUI.

![Verso screenshot](screenshot.jpg)

## Installation

You will need Perl (minimum version 5.10) and the following non-core modules:

* Image::ExifTool
* Gtk3
* Config::General
* File::HomeDir
* List::MoreUtils

On Debian:

    # aptitude install libimage-exiftool-perl libgtk3-perl \
        libconfig-general-perl libfile-homedir-perl liblist-moreutils-perl

To compile the manpage file you also need [Pandoc].

When these prerequisites are met, download the [program files][VersoDownload].
If you're on Linux/Gnome, run the following command to install:

    $ sudo make install

You can then start Verso from the Applications menu. To uninstall Verso run
one of the following two commands (purge includes `/etc/verso.conf`):

    $ sudo make uninstall
    $ sudo make purge

For manual installation put the `verso.pl` file somewhere in your path (and
maybe rename it), e.g. `~/bin/verso` or `/opt/verso`. Then make it executable
and start it with:

    $ verso path/to/imagedirectory

## Configuration

If you wish to change Verso's settings, copy the default configuration file
`verso.conf` either to `~/.verso.conf` (user specific configuration) or to
`/etc/verso.conf` (system wide configuration) and adjust it to your liking.
The default configuration file contains all configurable options together with
their default values and some descriptive comments.

A user specific configuration file takes precedence over a system wide
configuration file.

## What about the name?

[Recto and verso][RV] are the "front" and "back" sides of a leaf of paper. The
metadata that can be edited with Verso is the same one might have written on
the back (aka verso) side of a photo, back in the olden days of non-digital
photography.

## Project Website

The project website is [here][Verso], the program files are
[here][VersoDownload]. The source code can be found on [GitHub][VersoGitHub].

## License

Copyright 2013-2016 Martin Hoppenheit <martin@hoppenheit.info>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

[Verso]: http://martin.hoppenheit.info/code/verso
[VersoGitHub]: https://github.com/marhop/verso
[VersoDownload]: http://martin.hoppenheit.info/code/verso/verso.tar.gz
[DC]: http://dublincore.org
[XMP]: https://en.wikipedia.org/wiki/Extensible_Metadata_Platform
[ET]: http://www.sno.phy.queensu.ca/~phil/exiftool/
[RV]: https://en.wikipedia.org/wiki/Recto_and_verso
[Pandoc]: http://pandoc.org/

