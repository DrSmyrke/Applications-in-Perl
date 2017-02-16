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
$if=$ARGV[0];
$of=$ARGV[1];
if($if ne "" and $of ne ""){
	open fs,"<$if";
	open fs2,">$of";
	while($str=<fs>){
		$str=~s/\n//g;
		if($str=~/"/){
			$str=~s/\'/\\'/g;
			print fs2 "'$str',\n";
		}else{
			$str=~s/\"/\\"/g;
			print fs2 "\"$str\",\n";
		}
	}
	close fs;
	close fs2;
}
