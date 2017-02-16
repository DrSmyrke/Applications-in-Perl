#!/usr/bin/perl
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
use LWP::Simple;
use LWP 5.64;
$browser=LWP::UserAgent->new;
$browser->agent('Mozilla/4.76 [en] (Win98; U)');
$browser->cookie_jar({});
use utf8;
die "Usage: $0 <URL> (http://url/pic=I=.jpg) <min> <max> [0|1] ved nuls" unless @ARGV > 2;
my $url=shift;
my $min=shift;
my $max=shift;
my $null=shift;
for($i=$min;$i<=$max;$i++){
	if($null){
		if($i<10){$i="0$i";}
	}
	$img=$url;
	$img=~s/=I=/$i/g;
	$browser->show_progress(1);
	$browser->mirror($img,"$i.jpg");
	$browser->show_progress(0);
}
