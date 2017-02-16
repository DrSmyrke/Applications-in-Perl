#!/usr/bin/perl
# findtext, a program to search for text within a file, based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2010 Prokofiev Y. <Smyrke2005@yandex.ru>
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
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-directory"){$fd=$ARGV[$i+1];}
	if($str eq "-string"){$slovo=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();}
	$i++;
}
if(!$fd or !$slovo){getHelp();}
use Term::ANSIColor;
$fnum=0;$sovp=0;$xf=0;
@cmd=`find $fd -type f`;
$przt=@cmd;
$przi=0;
foreach $puts (@cmd){
$prz=int $przi/($przt/100);
$put=substr($puts,-4);
#print "$put";
if($put=="tml" or $put=="txt" or $put=="mht" or $put=="htm" or $put=="css" or $put==".js" or $put=="xml" or $put=="=js" or $put=="cfg" or $put=="dof" or $put=="dpr" or $put=="pas" or $put=="hhc" or $put=="rtf"){open(fs,"<$puts");@dt=<fs>;close(fs);$i=1;foreach $fd (@dt){$slovo=~tr/A-Z/a-z/;$slovo=~tr/А-Я/а-я/;$fd=~tr/A-Z/a-z/;$fd=~tr/А-Я/а-я/;if($fd=~/$slovo/){$p=substr($puts,55,-1);print color("yellow"),"[$prz\%] ",color("reset");chomp $puts;print "[$puts]	Строка № $i\n";$sovp++;if($xf!=1){$fnum++;$xf=1;}}$i++;}$xf=0;}
$przi++;}
print "\n=== Поиск окончен ===\n";
print "Найдено совпадений: $sovp в $fnum файлах(е)\n";
sub getSize{($sz)=@_;if($sz<1024){$st="$sz  bytes";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Kb";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mb";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Gb";}}}}return $st;}
sub getHelp{
	print "=== Help Page for findText by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-directory			Directory search
-string				Search string
";
	print "\n=== Thank you for choosing my application ===\n";
	($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($0);
	$i=0;
	open FS,"<$0";
	while($tmp=<FS>){$i++;}
	close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
	exit 0;
}
