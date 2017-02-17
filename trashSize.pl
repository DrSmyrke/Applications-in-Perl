#!/usr/bin/perl
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2012 Prokofiev Y. <Smyrke2005@yandex.ru>
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
# along with this program.  If not, see <http://www.gnu.org/licenses>.
#
#
#
use strict;
### Parsing arguments ###
my $size=0;
my $i=0;
foreach my $str(@ARGV){
	if($str eq "-size"){$size=$ARGV[$i+1];}
	$i++;
}
if(!$size){exit 0;}
my $file="$ENV{HOME}/.icons/MyTheme/places/user-trash-full.svg";
if(!-f $file){print "file not found\n";exit 0;}
drawIco(getSize($size));
### FUNCTIONS ###
sub drawIco{
	my $text=shift @_;
	open F,"<$file";my @data=<F>;close F;
	my ($find,$i)=0;
	foreach my $str(@data){
		if(substr($str,0,6) eq "	<text"){$find=1;last;}
		$i++;
	}
	if(!$find){
		$data[@data-1]='	<text x="55" y="57" font-family="Sans" font-size="7" fill="black">'.$text.'</text>'."\n".$data[@data-1];
	}else{
		$data[$i]='	<text x="15" y="57" font-family="Sans" font-size="7" fill="black">'.$text.'</text>'."\n";
	}
	open F,">$file";print F join("",@data);close F;
	system "gtk-update-icon-cache -f $ENV{HOME}/.icons/MyTheme || update-icon-caches -f $ENV{HOME}/.icons/MyTheme";
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz b";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Kb";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mb";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Gb";}}}}return $sz;}
