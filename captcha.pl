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
use Cairo;
my $surface = Cairo::ImageSurface->create ('argb32', 200,50);
my $cr = Cairo::Context->create ($surface);
$cr->move_to (0,40);
$cr->select_font_face ('Sans', 'normal', 'normal');
$cr->set_font_size (50);
$red=255;
$green=153;
$blue=0;
$cr->set_source_rgb ($red, $green, $blue);
$tmp=int rand(100000);
$cr->show_text ("$tmp");
$cr->show_page;
$surface->write_to_png ('output.png');
