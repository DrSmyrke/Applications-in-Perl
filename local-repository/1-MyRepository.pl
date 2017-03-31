#!/usr/bin/perl
# MYREPOSITORY, a backup app based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2013 Prokofiev Y. <Smyrke2005@yandex.ru>
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
############## Данные ##################
$pwd=$0;$pwd=~s#(.*)/.*#$1#;
if(-l $0){$pwd=readlink $0;$pwd=~s#(.*)/.*#$1#;}
unlink "$pwd/log";
@distrs=("katya","natty");
@types=("binary-i386","binary-amd64","source");
if(-f "$pwd/repdir"){open fs,"<$pwd/repdir";$repdir=<fs>;chomp $repdir;close fs;}else{$repdir="";}
############ Инициализация ###############
if(!-d "$repdir"){print "Directory local repository not found\n";exit;}
use LWP 5.64;
$browser=LWP::UserAgent->new;
$browser->cookie_jar({});
$browser->agent('Mozilla/5.0 (X11; Linux i686; rv:5.0) Gecko/20100101 Firefox/5.0');
open fs,"<$pwd/repList";@repurls=<fs>;close fs;chomp @repurls;
foreach $repurl(@repurls){
	if(substr($repurl,0,1) eq "#"){next;}
	$response=$browser->get("$repurl/dists");
	print "[$repurl]\n";
	foreach $distr(parsHtml($response->content)){
		foreach $ldistr(@distrs){
			($nam)=split("-",$distr);
			if($nam eq $ldistr){
				$response=$browser->get("$repurl/dists/$distr");
				foreach $dir(parsHtml($response->content)){
					$response=$browser->get("$repurl/dists/$distr/$dir");
					foreach $type(parsHtml($response->content)){
						foreach $ttype(@types){
							if($ttype eq $type){
								print "\nDISTR: [$distr] DIR: [$dir] TYPE: [$type]\n";
								$nam=($type eq "source")?"Sources":"Packages";
								$response=$browser->get("$repurl/dists/$distr/$dir/$type/$nam.gz");
								 if($response->is_success){Packages($type);}else{
									logs("Download [$repurl/dists/$distr/$dir/$type/$nam.gz] NO");
								}
							}
						}
					}
				}
			}
		}
	}
}

############## Процедуры ################
sub logs{
	ltime();
	($mess)=@_;
	open fs,">>$pwd/log";
	print fs "$year $mon $day [$hour:$min:$sek] > $mess\n";
	close fs;
}
sub ltime{
	@m=("Января","Февраля","Марта","Апреля","Мая","Июня","Июля","Августа","Сентября",
"Октября","Ноября","Декабря");
	($sek,$min,$hour,$day,$mon,$year)=localtime;
	if($sek<10){$sek="0$sek";}
	if($min<10){$min="0$min";}
	if($hour<10){$hour="0$hour";}
	$mon=$m[$mon];
	$year+=1900;
	return $year,$mon,$day,$hour,$min,$sek;
}
sub parsHtml{
	@tmp=undef;shift @tmp;
	foreach $str(split("<a href=\"",shift @_)){
		if($str=~/">/){
			($str,$name)=split(">",$str);
			($name)=split("<",$name);
			$str=~s/"//g;
			$type=(substr($str,-1) eq "/")?"DIR":"OTHER";
#			print "[$str] [$type] [$name]\n";
			$str=~s/\///g;
			chomp $name;
			if($type eq "DIR" and $name ne "Parent Directory"){push @tmp,$str;}
		}
	}
	return @tmp;
}
sub Packages{
	$type=shift @_;
	open fs,">$pwd/Packages.gz";
	print fs $response->content;
	close fs;
	system "gzip -d $pwd/Packages.gz";
	unlink "$pwd/Packages.gz";
	if($type eq "binary-i386"){parsPackages();}
	if($type eq "binary-amd64"){parsPackages();}
	if($type eq "source"){parsSourcesPackages();}
	unlink "$pwd/Packages";
}
sub parsPackages{
	open fs,"<$pwd/Packages";
	while($str=<fs>){
		$get=0;
		chomp $str;
		($param,$val)=split(": ",$str);
		if($param eq "Filename"){$fname=$val;}
		if($param eq "Size"){$size=$val;}
		if($param eq "" and $size ne "" and $fname ne ""){
			@tmp=split "/",$fname;
			delete $tmp[1];
			$file=join "/",@tmp;
			$file=~s/\/\//\//g;
			if(-f "$repdir/$file"){
				($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$sz,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$repdir/$file");
				if($size ne $sz){$get=1;}
			}else{$get=1;}
			if($get){getFile("$repurl/$fname","$repdir/$file",$size);}
			$fname=$size=$sum="";
		}
	}
	close fs;
}
sub parsSourcesPackages{
	open fs,"<$pwd/Packages";
	while($str=<fs>){
		($param,$val)=split(":",$str);
		if($param eq "Directory"){chomp $val;$sdir=substr($val,1);}
		if($param eq "Files"){$files=1;}
		if($param eq "Homepage"){$files=0;}
		if($param eq "Checksums-Sha1"){$files=0;}
		if($files and substr($str,0,1) eq " "){
			chomp $str;
			($tmp,$size,$file)=split(" ",$str);
				if($size ne "" and $file ne ""){
				$fname="$sdir/$file";
				@tmp=split "/",$fname;
				delete $tmp[1];
				$file=join "/",@tmp;
				$file=~s/\/\//\//g;
				if(-f "$repdir/$file"){
					($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$sz,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$repdir/$file");
					if($size ne $sz){$get=1;}
				}else{$get=1;}
				if($get){getFile("$repurl/$fname","$repdir/$file",$size);}
			}
		}
	}
	close fs;
}
sub getFile{
	$url=shift @_;
	$lfile=shift @_;
	$fsize=shift @_;
	if(-d $lfile){rmdir $lfile;}
	make_path($lfile);
	if(-f $lfile){unlink $lfile;}
	#print "Download [$url] ... ";
	$browser->show_progress(1);
	$browser->mirror($url,$lfile);
	$browser->show_progress(0);
	#system "wget -c -q '$url' -O '$lfile'";
	if(-f $lfile){
		($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$sz,$atime,$mtime,$ctime,$blksize,$blocks)=stat($lfile);
		if($fsize ne $sz){
			logs("ERROR size file	[$url]\n[$lfile] [$fsize != $sz]");
			#print "ERROR\n";
		}#else{print "OK\n";}
	}else{print "ERROR\n";logs("ERROR get file	[$url]\n[$lfile]");}
}
sub make_path{
	$path=shift @_;
	@path=split("/",$path);
	pop @path;
	$str="";
	foreach $directory(@path){
		$str.="$directory/";
		if(!-d $str){mkdir $str;}
	}
}
