# Verso

editor for embedded image metadata

## Rationale

Verso is an editor for metadata embedded in image files. Metadata can be used
to describe, amongst others, the image's content and the depicted persons, to
provide the date of its creation or to state license information. It can also
contain technical data like shutter speed and focal length.

Verso's default configuration makes it an editor for XMP metadata embedded in
JPEG files, particularly for the Dublin Core metadata elements Description,
Date, Creator and Rights. But since metadata editing is based on ExifTool and
Verso is highly customizable you may adjust the metadata fields that can be
displayed and edited, as long as ExifTool can handle them. So Verso can easily
be adapted to edit for example IPTC or EXIF instead of (or in addition to) XMP
metadata. Metadata fields can be added in the configuration file or on the fly
via command line options. When configured properly, Verso can be used to edit
metadata of non-image files like MP4 videos or PDF documents as well; it
displays just a dummy icon for such files though.

Verso is written in Perl and features a Gtk3 GUI.

## Installation

Debian and Arch Linux packages are available [here][Verso]. If that does not fit
your needs, read on.

You will need Perl (minimum version 5.10) and the following non-core modules:

  * Image::ExifTool
  * Gtk3
  * Config::General

On a usual Debian desktop system, the following should get you started:

    # apt install libimage-exiftool-perl libgtk3-perl libconfig-general-perl

When these prerequisites are met, download the [program source files from
GitHub][VersoGitHub]. If you're on Linux/Gnome, run the following command to
install:

    $ make
    $ sudo make install

You can then start Verso from the Applications menu or from the command line.
Documentation is available from the man page. To uninstall Verso run one of
the following two commands (purge includes the configuration file
`/etc/verso.conf`, but not `~/.verso.conf`):

    $ sudo make uninstall
    $ sudo make purge

## Project Website

The project website is [here][Verso]. The source code can be found on
[GitHub][VersoGitHub].

## License

Copyright 2013-2023 Martin Hoppenheit <martin@hoppenheit.info>

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

[Verso]: https://martin.hoppenheit.info/code/verso/
[VersoGitHub]: https://github.com/marhop/verso

