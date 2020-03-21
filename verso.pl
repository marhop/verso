#!/usr/bin/perl

# Verso - editor for embedded image metadata
#
# Copyright 2013-2019 Martin Hoppenheit <martin@hoppenheit.info>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use 5.010;
use utf8;
use Image::ExifTool;
use Gtk3 -init;
use Config::General;
use Getopt::Long;
use Pod::Usage;
use Encode qw(decode);
use File::Basename;
use File::Temp qw(tempfile);
use File::Copy;
use List::Util qw(min);

my $app_name        = 'Verso';
my $app_version     = '1.1.1';
my $app_description = 'editor for embedded image metadata';
my $app_copyright   = 'Copyright 2013-2019 Martin Hoppenheit';
my $app_website     = 'https://martin.hoppenheit.info/code/verso/';

my $directory;  # full path of current directory (including ending '/')
my @files;      # full paths of all files in the current directory
my $index;      # index of current file in @files
my $exiftool = Image::ExifTool->new();

## Command line options. ##

my $opt_help     = 0;     # Help message.
my $opt_config   = undef; # Custom config file path.
my @opt_fields   = ();    # Additional metadata fields.
my $opt_readonly = 0;     # Readonly.

Getopt::Long::Configure('bundling');
GetOptions(
    'help|h'     => \$opt_help,
    'config|c=s' => \$opt_config,
    'field|f=s'  => \@opt_fields,
    'readonly|r' => \$opt_readonly,
);

pod2usage(1) if $opt_help;

## Load config. ##

my $conf;
# Custom config file from --config command line option.
if (defined $opt_config and -e $opt_config) {
    $conf = Config::General->new(
        -ConfigFile => $opt_config,
        -AutoTrue => 1,
    );
}
# User specifig config file.
elsif (-e "$ENV{HOME}/.verso.conf") {
    $conf = Config::General->new(
        -ConfigFile => "$ENV{HOME}/.verso.conf",
        -AutoTrue => 1,
    );
}
# System wide config file.
elsif (-e '/etc/verso.conf') {
    $conf = Config::General->new(
        -ConfigFile => '/etc/verso.conf',
        -AutoTrue => 1,
    );
}
# No config file, default values.
else {
    $conf = Config::General->new(
        -ConfigHash => {},
        -AutoTrue => 1,
    );
}
my %config = $conf->getall();

my @default_fields = (
    # A minimum field definition consists of a tag and a label; default values
    # are provided below for tooltip (the empty string) and editable (true).
    {
        tag      => 'XMP-dc:Description',
        label    => 'Description',
        tooltip  => 'The content and context of the image.',
        editable => 'yes',
    },
    {
        tag      => 'XMP-dc:Date',
        label    => 'Date',
        tooltip  => 'The date and time the image was taken.',
        editable => 'yes',
    },
    {
        tag      => 'XMP-dc:Creator',
        label    => 'Creator',
        tooltip  => 'The photographer who created the image.',
        editable => 'yes',
    },
    {
        tag      => 'XMP-dc:Rights',
        label    => 'Rights',
        tooltip  => 'The intellectual property rights or licenses.',
        editable => 'yes',
    },
);

$config{field}        //= \@default_fields;
$config{windowwidth}  //= 500;
$config{windowheight} //= 500;
$config{maximize}     //= 0;
$config{viewer}       //= 'xdg-open';
$config{extension}    //= [qw(jpg jpeg JPG JPEG)];

## Build GUI: basic stuff. ##

my $window = Gtk3::Window->new('toplevel');
$window->set_title('Verso');
$window->set_default_size($config{windowwidth}, $config{windowheight});
$window->maximize() if $config{maximize};
$window->signal_connect('delete-event' => sub { Gtk3::main_quit });

my $grid1 = Gtk3::Grid->new();
$window->add($grid1);

## Build GUI: menubar. Also keyboard shortcuts. ##

# Hex representations of key values (like 0x006f for the 'o' key) can be found
# in /usr/include/X11/keysymdef.h!

my $menubar = Gtk3::MenuBar->new();
$grid1->attach($menubar, 1, 1, 1, 1);

my $accelerators = Gtk3::AccelGroup->new();
$window->add_accel_group($accelerators);

my $menu_item_file = Gtk3::MenuItem->new_with_mnemonic('_File');
$menubar->append($menu_item_file);

my $menu_file = Gtk3::Menu->new();
$menu_item_file->set_submenu($menu_file);

my $menu_item_file_open = Gtk3::MenuItem->new_with_mnemonic('_Open');
$menu_file->append($menu_item_file_open);
$menu_item_file_open->signal_connect(
    'activate' => \&on_menu_file_open_activate
);
$menu_item_file_open->add_accelerator(
        'activate',
        $accelerators,
        0x006f, # 'GDK_o' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_save = Gtk3::MenuItem->new_with_mnemonic('_Save changes');
$menu_file->append($menu_item_file_save);
$menu_item_file_save->signal_connect(
    'activate' => \&on_menu_file_save_activate
);
$menu_item_file_save->add_accelerator(
        'activate',
        $accelerators,
        0x0073, # 'GDK_s' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_undo
    = Gtk3::MenuItem->new_with_mnemonic('_Undo changes');
$menu_file->append($menu_item_file_undo);
$menu_item_file_undo->signal_connect(
    'activate' => \&on_menu_file_undo_activate
);
$menu_item_file_undo->add_accelerator(
        'activate',
        $accelerators,
        0x007a, # 'GDK_z' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_view_external
    = Gtk3::MenuItem->new_with_mnemonic('View in _external viewer');
$menu_file->append($menu_item_file_view_external);
$menu_item_file_view_external->signal_connect(
    'activate' => \&on_menu_file_view_external_activate
);
$menu_item_file_view_external->add_accelerator(
    'activate',
    $accelerators,
    0x0065, # 'GDK_e' did not work
    'GDK_CONTROL_MASK',
    'GTK_ACCEL_VISIBLE'
);

my $separator = Gtk3::SeparatorMenuItem->new();
$menu_file->append($separator);

my $menu_item_file_first = Gtk3::MenuItem->new_with_mnemonic(
    'Go to _first file'
);
$menu_file->append($menu_item_file_first);
$menu_item_file_first->signal_connect(
    'activate' => \&on_menu_file_first_activate
);
$menu_item_file_first->add_accelerator(
        'activate',
        $accelerators,
        0x0066, # 'GDK_f' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_previous = Gtk3::MenuItem->new_with_mnemonic(
    'Go to _previous file'
);
$menu_file->append($menu_item_file_previous);
$menu_item_file_previous->signal_connect(
    'activate' => \&on_menu_file_previous_activate
);
$menu_item_file_previous->add_accelerator(
        'activate',
        $accelerators,
        0x0070, # 'GDK_p' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_next = Gtk3::MenuItem->new_with_mnemonic(
    'Go to _next file'
);
$menu_file->append($menu_item_file_next);
$menu_item_file_next->signal_connect(
    'activate' => \&on_menu_file_next_activate
);
$menu_item_file_next->add_accelerator(
        'activate',
        $accelerators,
        0x006e, # 'GDK_n' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_file_last = Gtk3::MenuItem->new_with_mnemonic(
    'Go to _last file'
);
$menu_file->append($menu_item_file_last);
$menu_item_file_last->signal_connect(
    'activate' => \&on_menu_file_last_activate
);
$menu_item_file_last->add_accelerator(
        'activate',
        $accelerators,
        0x006c, # 'GDK_l' did not work
        'GDK_CONTROL_MASK',
        'GTK_ACCEL_VISIBLE'
);

my $menu_item_view = Gtk3::MenuItem->new_with_mnemonic('_View');
$menubar->append($menu_item_view);

my $menu_view = Gtk3::Menu->new();
$menu_item_view->set_submenu($menu_view);

my $menu_item_view_fullscreen
    = Gtk3::MenuItem->new_with_mnemonic('Toggle _Fullscreen');
$menu_view->append($menu_item_view_fullscreen);
$menu_item_view_fullscreen->signal_connect(
    'activate' => \&on_menu_view_fullscreen_activate
);
$menu_item_view_fullscreen->add_accelerator(
    'activate',
    $accelerators,
    0xffc8, # 'GDK_F11' did not work
    'GDK_CONTROL_MASK', # TODO How can we use only F11, without Ctrl?
    'GTK_ACCEL_VISIBLE'
);

my $menu_item_help = Gtk3::MenuItem->new_with_mnemonic('_Help');
$menubar->append($menu_item_help);

my $menu_help = Gtk3::Menu->new();
$menu_item_help->set_submenu($menu_help);

my $menu_item_help_about = Gtk3::MenuItem->new_with_mnemonic('_About');
$menu_help->append($menu_item_help_about);
$menu_item_help_about->signal_connect(
    'activate' => \&on_menu_help_about_activate
);

## Build GUI: workspace pt. 1 (general layout, image display). ##

my $paned = Gtk3::Paned->new('GTK_ORIENTATION_VERTICAL');
$paned->set_margin_top(5);
$paned->set_margin_bottom(5);
$paned->set_margin_left(5);
$paned->set_margin_right(5);
$paned->set_hexpand(1);
$paned->set_vexpand(1);
$grid1->attach($paned, 1, 2, 1, 1);

my $scrolled = Gtk3::ScrolledWindow->new();
$scrolled->set_hexpand(1);
$scrolled->set_vexpand(1);
$scrolled->set_margin_bottom(10);
$paned->pack1($scrolled, 1, 1);

my $image = Gtk3::Image->new();
$scrolled->add_with_viewport($image);

my $grid2 = Gtk3::Grid->new();
$grid2->set_margin_top(10);
$grid2->set_row_spacing(5);
$grid2->set_column_spacing(5);
$paned->pack2($grid2, 0, 0);

## Build GUI: workspace pt. 2 (metadata entry fields). ##

# Every metadata field we want to be able to edit needs an entry in the array
# @fields. Every entry consists of a label for the text entry field (label),
# the metadata field's full tag name (tag), the metadata field's short tag
# name (key, the part after the tag's last (or only?) colon), a tooltip
# describing the metadata field (tooltip), a boolean value whether the text
# entry will be editable (editable) and a place for the entry widget (widget,
# always initialized undef). The reason we need both tag and key is that
# apparently ExifTool needs either of these sometimes... For the most part,
# the array @fields is populated from the array referenced by $config{field},
# but the entries key and widget have to be added since they are not contained
# in the config. Default values are provided where sensible, so the minimum
# config entry for a field definition consists of just tag and label.

# Allow a one-field-only config.
my @fields
    = ref $config{field} eq 'ARRAY'
    ? @{$config{field}}
    : ($config{field})
    ;

# Add fields from --field command line option.
push @fields, map { { tag => $_, label => $_} } @opt_fields;

for my $f (@fields) {
    my @tag_parts = split /:/, $f->{tag};
    $f->{key} = $tag_parts[$#tag_parts];
    $f->{widget} = undef;
    if (!exists $f->{tooltip}) {
        $f->{tooltip} = '';
    }
    if (!exists $f->{editable}) {
        $f->{editable} = 1;
    }
    if ($opt_readonly) {
        $f->{editable} = 0;
    }
}

for my $i (0..$#fields) {
    my $label = Gtk3::Label->new($fields[$i]{'label'});
    $label->set_alignment(0, 0.5);
    $label->set_tooltip_text($fields[$i]{'tooltip'});
    $grid2->attach($label, 1, $i+1, 1, 1);

    my $entry = Gtk3::Entry->new();
    $entry->set_hexpand(1);
    $entry->set_editable($fields[$i]{'editable'});
    $entry->set_tooltip_text($fields[$i]{'tooltip'});
    $grid2->attach($entry, 2, $i+1, 4, 1);

    $fields[$i]{'widget'} = $entry;
}

## Build GUI: workspace pt. 3 (buttons). ##

my $button_line_offset = 1 + scalar @fields;

my $file_counter_label = Gtk3::Label->new('0/0');
$grid2->attach($file_counter_label, 1, $button_line_offset, 1, 1);

my $save_button = Gtk3::Button->new('Save');
$save_button->signal_connect('clicked' => \&on_save_button_clicked);
$grid2->attach($save_button, 2, $button_line_offset, 1, 1);

my $undo_button = Gtk3::Button->new('Undo');
$undo_button->signal_connect('clicked' => \&on_undo_button_clicked);
$grid2->attach($undo_button, 3, $button_line_offset, 1, 1);

my $previous_button = Gtk3::Button->new('Previous');
$previous_button->signal_connect('clicked' => \&on_previous_button_clicked);
$grid2->attach($previous_button, 4, $button_line_offset, 1, 1);

my $next_button = Gtk3::Button->new('Next');
$next_button->signal_connect('clicked' => \&on_next_button_clicked);
$grid2->attach($next_button, 5, $button_line_offset, 1, 1);

$window->show_all();

if (@ARGV) {
    init_files(shift) and load_current_file();
}

Gtk3::main();

## Menu callback routines. ##

sub on_menu_file_open_activate {
    my $dialog = Gtk3::FileChooserDialog->new(
        'Open file',
        $window,
        'GTK_FILE_CHOOSER_ACTION_OPEN',
        Gtk3::STOCK_CANCEL, 'GTK_RESPONSE_CANCEL',
        Gtk3::STOCK_OPEN, 'GTK_RESPONSE_ACCEPT'
    );
    if ($dialog->run() eq 'accept') {
        init_files($dialog->get_filename()) and load_current_file();
    }
    $dialog->destroy();
    return;
}

sub on_menu_file_save_activate {
    on_save_button_clicked();
    return;
}

sub on_menu_file_undo_activate {
    on_undo_button_clicked();
    return;
}

sub on_menu_file_view_external_activate {
    system "$config{viewer} $files[$index]";

    return;
}

sub on_menu_file_first_activate {
    if (@files) {
        $index = 0;
        load_current_file();
    }

    return;
}

sub on_menu_file_previous_activate {
    on_previous_button_clicked();
    return;
}

sub on_menu_file_next_activate {
    on_next_button_clicked();
    return;
}

sub on_menu_file_last_activate {
    if (@files) {
        $index = $#files;
        load_current_file();
    }

    return;
}

sub on_menu_view_fullscreen_activate {
    state $fullscreen = 0;
    $fullscreen ? $window->unfullscreen() : $window->fullscreen();
    $fullscreen = !$fullscreen;
}

sub on_menu_help_about_activate {
    my $dialog = Gtk3::AboutDialog->new();
    $dialog->set_transient_for($window);
    $dialog->set_program_name($app_name);
    $dialog->set_version($app_version);
    $dialog->set_copyright($app_copyright);
    $dialog->set_comments($app_description);
    $dialog->set_license_type('GTK_LICENSE_GPL_3_0');
    $dialog->set_website($app_website);
    $dialog->run();
    $dialog->destroy();
    return;
}

## Button callback routines. ##

sub on_save_button_clicked {
    write_current_metadata();
    return;
}

sub on_undo_button_clicked {
    load_current_metadata();
    return;
}

sub on_next_button_clicked {
    $index++;

    if (scalar @files > $index) {
        load_current_file();
    }
    else {
        $index--;
    }

    return;
}

sub on_previous_button_clicked {
    $index--;

    if ($index >= 0) {
        load_current_file();
    }
    else {
        $index++;
    }

    return;
}

## Other subroutines. ##

sub init_files {
    my $path = decode 'utf8', shift;
    state $ext
        = ref $config{extension} eq 'ARRAY'
        ? join ',', @{$config{extension}}
        : $config{extension}
        ;
    if (-e $path) {
        $path = normalize_file_path($path);
        (undef, $directory, undef) = fileparse($path);
        @files = sort map { decode 'utf8', $_ }
            grep { ! -d } glob "'$directory'*.{$ext}";
        if (@files) {
            $index = -d $path ? 0 : first_index($path, @files);
        }
        else {
            create_error("No files with extension $ext found in $directory");
        }
    }
    else {
        create_error("Could not find file $path");
    }
    # True if there are @files, else false.
    return scalar @files;
}

sub first_index {
    my ($string, @strings) = @_;
    for my $i (0..$#strings) {
        return $i if $string eq $strings[$i];
    }
    return -1;
}

sub normalize_file_path {
    my $path = shift;
    # Prepend './' to simple file names without full path, otherwise the
    # first_index function won't work correctly with globbed files.
    $path =~ s{^(?!(/|\./|\.\./|\.$))}{./};
    # Make sure a directory path ends with '/', otherwise the fileparse
    # function won't work correctly.
    $path =~ s{/?$}{/} if -d $path;
    return $path;
}

sub load_current_file {
    load_current_image();
    load_current_metadata();
    $window->set_title(
        basename($files[$index]) . " ($directory) - Verso"
    );
    $file_counter_label->set_text($index + 1 . '/' . scalar @files);
    return;
}

sub load_current_image {
    eval {
        my $w = $scrolled->get_allocation()->{width};
        my $h = $scrolled->get_allocation()->{height};
        my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($files[$index]);
        my $pixbuf_rotated = $pixbuf->apply_embedded_orientation();
        my $pixbuf_rotated_scaled = scale_pixbuf($pixbuf_rotated, $w, $h);
        $image->set_from_pixbuf($pixbuf_rotated_scaled);
    };
    if ($@) {
        if (is_unsupported_format_error($@)) {
            $image->set_from_icon_name('image-missing', 'GTK_ICON_SIZE_DIALOG');
        }
        else {
            die $@;
        }
    }
    return;
}

sub scale_pixbuf {
    my ($pixbuf, $max_w, $max_h) = @_;
    my $pixb_w = $pixbuf->get_width();
    my $pixb_h = $pixbuf->get_height();

    if (($pixb_w > $max_w) || ($pixb_h > $max_h)) {
        my $sc_factor_w = $max_w / $pixb_w;
        my $sc_factor_h = $max_h / $pixb_h;
        # Choose the smallest scaling factor, so the longest side will fit.
        my $sc_factor = min $sc_factor_w, $sc_factor_h;
        my $sc_w = int($pixb_w * $sc_factor);
        my $sc_h = int($pixb_h * $sc_factor);
        my $scaled = $pixbuf->scale_simple($sc_w, $sc_h, 'GDK_INTERP_HYPER');
        return $scaled;
    }

    return $pixbuf;
}

sub is_unsupported_format_error {
    my $err = shift;
    return Glib::Error::matches($err, 'Gtk3::Gdk::PixbufError', 'unknown-type');
}

sub load_current_metadata {
    my @tags = map { $_->{'tag'} } @fields;
    my $info = $exiftool->ImageInfo($files[$index], \@tags);

    for my $field (@fields) {
        my $entry_widget = $field->{'widget'};
        my $metadata_key = $field->{'key'};

        if (defined $info->{$metadata_key}) {
            my $entry_original_encoding = $info->{$metadata_key};
            my $entry_perl_encoding = decode 'utf8', $entry_original_encoding;
            
            $entry_widget->set_text($entry_perl_encoding);
        }
        else {
            $entry_widget->set_text('');
        }
    }

    $fields[0]{'widget'}->grab_focus();

    return;
}

sub write_current_metadata {
    for my $field (@fields) {
        my $entry_widget = $field->{'widget'};
        my $new_value    = $entry_widget->get_text();
        my $metadata_tag = $field->{'tag'};
        $exiftool->SetNewValue($metadata_tag, $new_value, Replace => 1);
    }

    my $tmpfile = File::Temp->new(SUFFIX => '-verso')->filename();
    my $success = $exiftool->WriteInfo($files[$index], $tmpfile);
    if ($success) {
        copy($tmpfile, $files[$index]);
    }
    else {
        my $e = $exiftool->GetValue('Error');
        create_error("Error writing metadata, no changes were made. $e");
    }
    unlink $tmpfile;

    return;
}

sub create_info {
    my $msg = shift;

    my $dialog = Gtk3::MessageDialog->new(
        $window,
        'GTK_DIALOG_DESTROY_WITH_PARENT',
        'GTK_MESSAGE_INFO',
        'GTK_BUTTONS_CLOSE',
        $msg
    );

    $dialog->run();
    $dialog->destroy();

    return;
}

sub create_warning {
    my $msg = shift;

    my $dialog = Gtk3::MessageDialog->new(
        $window,
        'GTK_DIALOG_DESTROY_WITH_PARENT',
        'GTK_MESSAGE_WARNING',
        'GTK_BUTTONS_CLOSE',
        $msg
    );

    $dialog->run();
    $dialog->destroy();

    return;
}

sub create_error {
    my $msg = shift;

    my $dialog = Gtk3::MessageDialog->new(
        $window,
        'GTK_DIALOG_DESTROY_WITH_PARENT',
        'GTK_MESSAGE_ERROR',
        'GTK_BUTTONS_CLOSE',
        $msg
    );

    $dialog->run();
    $dialog->destroy();

    say $msg;

    return;
}

__END__

=head1 NAME

verso - editor for embedded image metadata

=head1 SYNOPSIS

B<verso> [options] [file|directory]

=head1 DESCRIPTION

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

=head1 OPTIONS

=over 4

=item B<-h>, B<--help>

Print a short help message.

=item B<-c> FILE, B<--config> FILE

Use custom configuration file FILE instead of the default path.

=item B<-f> TAG, B<--field> TAG

Add a metadata field specified by the ExifTool tag TAG to the GUI. Example:

    $ verso -f DateTimeOriginal -f ImageWidth

=item B<-r>, B<--readonly>

Readonly mode. Make all metadata fields readonly regardless of settings in the
configuration file.

=back

=head1 CONFIGURATION

The default configuration file F</etc/verso.conf> contains all configurable
options together with their default values and some descriptive comments.

=head1 FILES

F</etc/verso.conf>

System wide configuration file.

F<~/.verso.conf>

User specific configuration file.

A user specific configuration file takes precedence over a system wide
configuration file.

=head1 SEE ALSO

exiftool(1p)

=head1 WHAT ABOUT THE NAME?

Recto and verso are the "front" and "back" sides of a leaf of paper. The
metadata that can be edited with Verso is the same one might have written on
the back (aka verso) side of a photo, back in the olden days of non-digital
photography.

=head1 AUTHOR

Martin Hoppenheit L<https://martin.hoppenheit.info/code/verso/>

=head1 COPYRIGHT

Copyright 2013-2019 Martin Hoppenheit <martin@hoppenheit.info>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

