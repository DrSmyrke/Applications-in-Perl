#!/usr/bin/perl
# tree, Application for viewing sub-directories and files in a tree, based on DrSmyrke
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
my $cat=$ARGV[0];
getCat($cat);
sub getCat{
	my $url=shift @_;
	if(-d $url){
		my @tmp=split("/",$url);
		my $count=@tmp-1;
		my $catname=pop @tmp;
		for(1..$count){
			print "  ";
		}
		print "[$catname]\n";
		foreach my $str(glob("$url/*")){
			if(-f $str){
				my @file=split("/",$str);
				my $file=pop @file;
				for(1..$count+1){print "  ";}
				print "| ";
				print "$file\n";
			}
			if(-d $str){
				getCat($str);
			}
		}
	}
}
