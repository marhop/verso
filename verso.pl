#!/usr/bin/perl

# Verso - a simple XMP metadata editor for JPEG images
#
# Copyright 2013 Martin Hoppenheit <martin.hoppenheit@brhf.de>
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
use Encode qw(decode);
use File::Basename;
use File::Temp qw(tempfile);
use File::Copy;
use List::MoreUtils qw(first_index);


my $directory;  # full path of current directory (including ending '/')
my @files;      # full paths of all files in the current directory
my $index;      # index of current file in @files
my $exiftool = Image::ExifTool->new();


## Build GUI: basic stuff. ##

my $window = Gtk3::Window->new('toplevel');
$window->set_title('Verso');
$window->set_default_size(700, 600);
$window->maximize();
$window->signal_connect('delete-event' => sub { Gtk3::main_quit });

my $grid1 = Gtk3::Grid->new();
$window->add($grid1);


## Build GUI: menubar. Also keyboard shortcuts. ##

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
$paned->set_position(440);
$grid1->attach($paned, 1, 2, 1, 1);

my $scrolled = Gtk3::ScrolledWindow->new(100, 100);
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
$paned->pack2($grid2, 1, 1);


## Build GUI: workspace pt. 2 (metadata entry fields). ##

# Every metadata field we want to be able to edit needs an entry in this
# array. Every entry consists of a label for the text entry field (label), the
# metadata field's full tag name (tag), the metadata field's short tag name
# (key), a tooltip describing the metadata field (tooltip), a boolean value
# whether the text entry will be editable (editable) and a place for the entry
# widget (widget, always undef). The reason we need both tag and key is that
# apparently ExifTool needs either of these sometimes...
my @fields = (
    {
        label       => 'Description',
        tag         => 'XMP-dc:Description',
        key         => 'Description',
        tooltip     => 'Describe the content and context of the image.',
        editable    => 1,
        widget      => undef,
    },
    {
        label       => 'Date',
        tag         => 'XMP-dc:Date',
        key         => 'Date',
        tooltip     => 'Provide the date and time the image was taken.',
        editable    => 0,
        widget      => undef,
    },
    {
        label       => 'Creator',
        tag         => 'XMP-dc:Creator',
        key         => 'Creator',
        tooltip     => 'Name the photographer who created the image.',
        editable    => 1,
        widget      => undef,
    },
    {
        label       => 'Rights',
        tag         => 'XMP-dc:Rights',
        key         => 'Rights',
        tooltip     => 'State intellectual property rights or applicable '
                    .  'licenses.',
        editable    => 1,
        widget      => undef,
    },
    # {
    #     label       => 'Coverage',
    #     tag         => 'XMP-dc:Coverage',
    #     key         => 'Coverage',
    #     tooltip     => 'If relevant, name the location shown in the image.',
    #     editable    => 1,
    #     widget      => undef,
    # },
);

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


if (@ARGV) {
    load_file(shift);
}

$window->show_all();
Gtk3::main();


## Menu callback routines. ##

sub on_menu_file_open_activate {
    # TODO doesn't work
    # my $dialog = Gtk3::FileChooserDialog->new(
    #     'Open file',
    #     $window,
    #     'GTK_FILE_CHOOSER_ACTION_OPEN',
    #     'GTK_STOCK_CANCEL', 'GTK_RESPONSE_CANCEL',
    #     'GTK_STOCK_OPEN', 'GTK_RESPONSE_ACCEPT',
    #     'NULL'
    # );
    # $dialog->run();
    # $dialog->destroy();

    my $msg
        = "Not implemented yet.\n"
        . "Call 'verso <image directory or image file>' "
        . "on the command line.";

    create_warning($msg);

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
    system "eog $files[$index]";

    return;
}

sub on_menu_file_first_activate {
    if (@files) {
        $index = 0;
        load_file($files[$index]);
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
        load_file($files[$index]);
    }

    return;
}

sub on_menu_help_about_activate {
    my $dialog = Gtk3::AboutDialog->new();
    $dialog->set_program_name('Verso');
    $dialog->set_comments('A simple XMP metadata editor for JPEG images.');
    # $dialog->set_website();
    # $dialog->set_version();
    $dialog->set_copyright('Copyright 2013 Martin Hoppenheit');
    $dialog->set_license_type('GTK_LICENSE_GPL_3_0');

    $dialog->run();
    $dialog->destroy();

    return;
}


## Button callback routines. ##

sub on_save_button_clicked {
    write_metadata();
    return;
}

sub on_undo_button_clicked {
    load_metadata();
    return;
}

sub on_next_button_clicked {
    $index++;

    if (scalar @files > $index) {
        load_file($files[$index]);
    }
    else {
        $index--;
    }

    return;
}

sub on_previous_button_clicked {
    $index--;

    if ($index >= 0) {
        load_file($files[$index]);
    }
    else {
        $index++;
    }

    return;
}


## Other subroutines. ##

sub load_file {
    # TODO Check if files actually are JPEG files!

    my $path = shift;

    if (-e $path) {
        if (-d $path) {
            ($directory = $path) =~ s{/?$}{/};

            @files = grep { ! -d } glob "$directory*.jpg";

            if (@files) {
                $index = 0;
            }
            else {
                create_error("No jpeg files found in $directory");
                return;
            }
        }
        else {
            (undef, $directory, undef) = fileparse($path);

            @files = grep { ! -d } glob "$directory*.jpg";

            if (@files) {
                $index = first_index { $_ eq $path } @files;
            }
            else {
                create_error("Not a jpeg file ($path)");
                return;
            }
        }

        load_image();
        load_metadata();
        $window->set_title(
            basename($files[$index]) . " ($directory) - Verso"
        );
        $file_counter_label->set_text($index + 1 . '/' . scalar @files);
    }
    else {
        create_error("Could not find file $path");
    }

    return;
}

sub load_image {
    $image->set_from_file($files[$index]);

    return;
}

sub load_metadata {
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

sub write_metadata {
    for my $field (@fields) {
        my $entry_widget = $field->{'widget'};
        my $new_value    = $entry_widget->get_text();
        my $metadata_tag = $field->{'tag'};

        $exiftool->SetNewValue($metadata_tag, $new_value, Replace => 1);
    }

    my $tmpfile = File::Temp->new()->filename();
    my $success = $exiftool->WriteInfo($files[$index], $tmpfile);

    if ($success) {
        copy($tmpfile, $files[$index]);
    }
    else {
        create_warning("Error writing metadata. No changes were made.");
    }

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
