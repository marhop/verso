# Release 1.2.1

2023-12-30

* Bugfix: UTF-8 encoded file paths (in particular, directory names containing
  things like umlaut characters (e.g., äöÜ)) can now be opened.

# Release 1.2.0

2020-03-26

* Verso can now open multiple files in the GUI Open dialog and an arbitrary
  combination of files and directories in the CLI. In particular this makes file
  globbing like `$ verso dir/*.jpg` possible.
* Bugfix: File paths with spaces in the directory part can now be opened.

# Release 1.1.1

2019-07-05

* Bugfix: Files with different extensions like *.{jpg,tif} are now sorted
  correctly by file name rather than by extension.

# Release 1.1.0

2019-07-03

* Previously, when opening a file in a format that cannot be rendered, Verso
  would crash. Now it displays a dummy icon instead but still allows to edit the
  file's metadata. That's useful for example to edit XMP metadata of an MP4
  video.

# Release 1.0.0

2017-07-31

* Initial release.
