% VERSO(1)

# NAME

verso - an (XMP/JPEG) image metadata editor

# SYNOPSIS

**verso** [*file*|*directory*]

# DESCRIPTION

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

[XMP]: https://en.wikipedia.org/wiki/Extensible_Metadata_Platform
[DC]: http://dublincore.org
[ET]: http://www.sno.phy.queensu.ca/~phil/exiftool/

# CONFIGURATION

The default configuration file */etc/verso.conf* contains all configurable
options together with their default values and some descriptive comments.

# FILES

*/etc/verso.conf*

System wide configuration file.

*~/.verso.conf*

User specific configuration file.

A user specific configuration file takes precedence over a system wide
configuration file.

# SEE ALSO

exiftool(1p)

# WHAT ABOUT THE NAME?

[Recto and verso][RV] are the "front" and "back" sides of a leaf of paper. The
metadata that can be edited with Verso is the same one might have written on
the back (aka verso) side of a photo, back in the olden days of non-digital
photography.

[RV]: https://en.wikipedia.org/wiki/Recto_and_verso

# BUGS

Verso currently fails to open files whose names contain umlaut characters.

# AUTHOR

Martin Hoppenheit <http://martin.hoppenheit.info/code/verso>

# COPYRIGHT

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

