#!/usr/bin/perl
# application based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2015 Prokofiev Y. <Smyrke2005@yandex.ru>
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer -init;

sub my_bus_callback {
  my ($bus, $message, $loop) = @_;

  if ($message -> type & "tag") {
    my $tags = $message -> tag_list;
    foreach (qw(artist title album track-number)) {
      if (exists $tags -> { $_ }) {
        printf "  %12s: %s\n", ucfirst GStreamer::Tag::get_nick($_),
                               $tags -> { $_ } -> [0];
      }
    }
  }

  elsif ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  elsif ($message -> type & "eos") {
    $loop -> quit();
  }

  # remove message from the queue
  return TRUE;
}

foreach my $file (@ARGV) {
  my $loop = Glib::MainLoop -> new(undef, FALSE);

  my $player = GStreamer::ElementFactory -> make(playbin => "player");

  $player -> set(uri => Glib::filename_to_uri $file, "localhost");
  $player -> get_bus() -> add_watch(\&my_bus_callback, $loop);

  print "Playing: $file\n";

  $player -> set_state("playing") or die "Could not start playing";
  $loop -> run();
  $player -> set_state("null");
}
