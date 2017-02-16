#!/usr/bin/env perl
# app, a system monitor, based on DrSmyrke
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
use strict; use GD;
my $res = 16000;
my $outres = 1000;
my $format = 2.0;
for my $z(0..20) {
    my ($c1, $c2, $c3, $c4);
    my $img = new GD::Image($res, $res);
    $img->fill($res, $res => $img->colorAllocate(0, 0, 0));

    for (0..1200) {
        $c1 = $img->colorAllocate(rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32);
        $c2 = $img->colorAllocate(rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32);
        $c3 = $img->colorAllocate(rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32);
        $c4 = $img->colorAllocate(rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32, rand(0xFF-0x32)+0x32);
        $img->setStyle($c1, $c1, $c2, $c2, $c3, $c3, $c4, $c4, gdTransparent, gdTransparent);
        (rand(10)>2) ? ($img->line(rand($res), rand($res), rand($res), rand($res), gdStyled)):
        ((rand(10)>2) ? $img->rectangle(rand($res), rand($res), rand($res), rand($res), gdStyled):
        $img->ellipse(rand($res), rand($res), rand($res), rand($res), gdStyled)) if (rand(10)>2);
    }

    print "processing $z.png...\n";
    my $m = new GD::Image($outres*$format, $outres);
    $m->copyResized($img, 0, 0, 0, 0, $outres*$format, $outres, $res, $res);

    open F => '>'.$z.'.png';
    binmode F;
    print F $m->png;
    close F;
}
