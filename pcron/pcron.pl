#!/usr/bin/perl
# pcron, a task Scheduler, based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2014 Prokofiev Y. <Smyrke2005@yandex.ru>
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
$SIG{INT}="sigExit";
$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
$pidfile="$ENV{HOME}/.run/pcron.pid";
$rootPid=$$;
### Parsing arguments ###
foreach $str(@ARGV){
	if($str eq "--stop"){stop(getMyPID($webserverpidfile));stop(getMyPID($pidfile));sigExit();}
}
sub sigExit{
	if($$ eq $rootPid){
		print "\nremove [$pidfile]";
		unlink $pidfile;
		print "\nExit\n";
		unlink $pidfile;
	}
	exit;
}
sub stop{
	$pid=shift @_;
	if($pid){
		print "KILLING [$pid]\n";
		kill 'TERM',$pid;
	}
}
print "DAEMON ... ";
use POSIX qw(setsid);
defined(my $rootPid = fork)   or die "Can't fork: $!";
if($rootPid==0){
	if(getMyPID($pidfile)){print "NO EXECUTE DUBLICATE APPS\n";exit;}
	setsid or die "Can't start a new session: $!";
#	chdir '/' or die "Can't chdir to /: $!";
#	open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
#	open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
#	open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
	close STDIN;
	close STDOUT;
	close STDERR;
	mainLoop();
}
if($rootPid==-1){print " [ ERROR ]\n";}
if($rootPid){print " [ STARTING A NEW SESSION ]\n";}
sub getMyPID{
	$pidf=shift @_;
	$pid=0;
	if(!-d "$ENV{HOME}/.run"){mkdir "$ENV{HOME}/.run";}	
	if(!-f $pidf){
		print "\nCreate [$pidf] for [$$]\n";
		open fs,">$pidf";print fs "$$";close fs;
	}else{
		open fs,"<$pidf";$pid=<fs>;close fs;
	}
	return $pid;
}
sub mainLoop{
	$pwd=$0;$pwd=~s#(.*)/.*#$1#;
	if(-l $0){$pwd=readlink $0;$pwd=~s#(.*)/.*#$1#;}
	$list="#wday=Пн=1\n#wday=Вт=2\n#wday=Ср=3\n#wday=Чт=4\n#wday=Пт=5\n#wday=Сб=6\n#wday=Вс=0\n#day	mon	year	hour	min	wday	command	workdir\n";
	if(!-f "$ENV{HOME}/.pcron.list"){open fs,">$ENV{HOME}/.pcron.list";print fs $list;close fs;}
	if(!-f "$pwd/list.txt"){open fs,">$pwd/list.txt";print fs $list;close fs;}
	while(1){
		ltime();
		parsFile("$pwd/list.txt");
		parsFile("$ENV{HOME}/.pcron.list");
		sleep 60;
	}
}
sub parsFile{
	$file=shift @_;
	open fs,"<$file";@data=<fs>;close fs;chomp @data;
	$i=1;
	foreach $str(@data){
		if(substr($str,0,1) eq "#"){$i++;next;}
		($d,$mes,$y,$h,$m,$wd,$cmd,$dir)=split("	",$str);
		if($m eq "-"){$m=~s/-/$min/g;}
		if($h eq "-"){$h=~s/-/$hour/g;}
		if($d eq "-"){$d=~s/-/$day/g;}
		if($mes eq "-"){$mes=~s/-/$mon/g;}
		if($y eq "-"){$y=~s/-/$year/g;}
		if($wd eq "-"){$wd=~s/-/$wday/g;}
		if($d eq $day and $mes eq $mon and $y eq $year and $h eq $hour and $m eq $min and $wd eq $wday){execute($cmd,$dir,$i);}
		$i++;
	}
}
sub execute{
	($cmd,$dir,$i)=@_;
	open fs,">>$ENV{HOME}/.pcron.log";
	print fs "$year $mon $day [$hour:$min]	$file	nExec job # $i ... ";
	if(fork==0){if($dir ne "-"){chdir "$dir";}exec "$cmd";}
	print fs "OK\n";
	close fs;
}
sub ltime{
	($sek,$min,$hour,$day,$mon,$year,$wday)=localtime;
	$mon++;
	if($mon<10){$mon="0$mon";}
	if($day<10){$day="0$day";}
	if($hour<10){$hour="0$hour";}
	if($min<10){$min="0$min";}
	if($sek<10){$sek="0$sek";}
	$year+=1900;
}
