#!/usr/bin/perl
# findBadLinks, a simple script for find bad links in html page, based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2016 Prokofiev Y. <Smyrke2005@yandex.ru>
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
die "Usage: $0 <url>" unless @ARGV == 1;
my $url=shift;
if(substr($url,-1) eq "/"){$url=substr($url,0,-1);}

use LWP::Simple;
use LWP 5.64;
my $browser=LWP::UserAgent->new;
$browser->agent('Mozilla/4.76 [en] (Win98; U)');
$browser->cookie_jar({});
use utf8;
use strict;
my $i=0;
my $bad=0;
my $checked=0;
my @badLinks;
my $name;
my $data=get $url;
foreach my $str(split('</a>',$data)){
	chomp $str;
	(undef,$str)=split("<a",$str);
	(undef,$str)=split('href="',$str);
	($str)=split('"',$str);
	if(substr($str,0,1) eq "#"){next;}
	if($str eq "javascript:void(0)"){next;}
	if($str eq ""){next;}
	if(substr($str,0,2) eq "//"){$str=~s/\/\//http:\/\//g;}
	print "[$str] ... ";
	if(substr($str,0,1) eq "/"){
		my $response=$browser->get("$url$str");
		my $status=$response->status_line;
		(my $stat)=split(" ",$status);
		if($stat ne "200"){$bad++;push(@badLinks,"$str	$status");}
		print $status;
		$checked++;
	}else{
		my $response=$browser->get("$str");
		my $status=$response->status_line;
		(my $stat)=split(" ",$status);
		if($stat ne "200"){$bad++;push(@badLinks,"$str	$status");}
		print $status;
		$checked++;
	}
	print "\n";
	$i++;
}
print "Total links: $i	Bad Links: $bad	Checked Links: $checked\n=================\n";
foreach my $str(@badLinks){
	(my $link,my $status)=split("	",$str);
	print "[$link]	$status\n";
}
