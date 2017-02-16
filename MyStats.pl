#!/usr/bin/perl
# MyStats, a system monitor, based on DrSmyrke
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
exit if ($^O eq 'MSWin32'); # под виндой мы не работаем, мы там играем
use utf8;
use Encode;
$SIG{INT}="sigExit";
$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$fmanager="caja";
$port=7300;
$mode=0;
$logs=0;
$webserver=$webservermode=0;
$dirs=0;
$logsdir="$ENV{HOME}/.mystats";
#%lookdirs=("HOME"=>"~");
$pidfile="$ENV{HOME}/.run/mystats.pid";
$webserverpidfile="$ENV{HOME}/.run/mystats_webserver.pid";
$rootPid=$$;
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "--daemon"){$mode=1;}
	if($str eq "--savelogs"){$logs=1;}
	if($str eq "--nologs"){$logs=0;}
	if($str eq "--nowebserver"){$nowebserver=1;}
	if($str eq "--drawlogs"){$mode=2;$logfile=$ARGV[$i+1];}
	if($str eq "--stop"){stop(getMyPID($webserverpidfile));stop(getMyPID($pidfile));sigExit();}
	if($str eq "-logs"){$logsdir=$ARGV[$i+1];}
	if($str eq "-pidfile"){$pidfile=$ARGV[$i+1];}
	if($str eq "-webserverpidfile"){$webserverpidfile=$ARGV[$i+1];}
	if($str eq "-drawiface"){$drawIface=$ARGV[$i+1];}
	if($str eq "-drawdisk"){$drawDisk=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){$mode=3;}
	$i++;
}
### mode ###
print "STARTING ";
if($mode eq 0){gui();}
if($mode eq 1){daemon();}
if($mode eq 2){if(drawLog($logfile)){print "OK\n";}else{print "ERROR\n";}exit;}
if($mode eq 3){getHelp();exit;}
### Functions ###
sub stop{
	$pid=shift @_;
	if($pid){
		print "KILLING [$pid]\n";
		kill 'TERM',$pid;
	}
}
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
sub sigExit{
	if($$ eq $rootPid){
		print "\nremove [$pidfile]";
		unlink $pidfile;
		print "\nExit\n";
		unlink $pidfile;
		if(-f $webserverpidfile){
			print "\nremove [$webserverpidfile]";
			unlink $webserverpidfile;
		}
	}
	exit;
}
sub monsize{
	($tmp)=split(" ",`xrandr | grep '*'`);
	@mon=split("x",$tmp);
	return @mon;
}
sub mainLoop{
	while(1){
		if($xupd>0){$xupd=0;upd();}else{$xupd++;}
		if($logs){if($xupdl>120){$xupdl=0;logs();}else{$xupdl++;}}
		if($webserver and !$webservermode){startWebServer();}
		if(!$webserver and $webservermode){stopWebServer();}
		if($mode eq 0){
			@pointer=$win->window->get_pointer;
			#@pointer=(null,mouseX,mouseY,mouseState);
			if($pointer[3]=~/mod1-mask/ and $enter){$altMode=1;}else{$altMode=0;}
			if($pointer[3]=~/control-mask/ and $enter){$controlMode=1;}else{$controlMode=0;}
			if($pointer[3]=~/button1-mask/ and $enter and $controlMode){
				$vismode=(!$vismode)?1:0;
			}
			if($pointer[3]=~/button3-mask/ and $enter and $controlMode){
				$logs=(!$logs)?1:0;
			}
			if($pointer[3]=~/button3-mask/ and $enter and !$controlMode){
				$about=(!$about)?1:0;
			}
			if($pointer[3]=~/button2-mask/ and $enter and $controlMode){
				$webserver=(!$webserver)?1:0;
			}
			if($vismode){$vis=1;}
			if(!$vis){
				$win->move($mon[0]-4,0);
			}else{
				$win->move($mon[0]-$winwidth,0);
			}
			if($vis){
				draw($win);
				$widget->resize($winwidth,$contHeight+10);
			}
			Gtk2->main_iteration while Gtk2->events_pending;
		}
		select(undef,undef,undef,0.5);
	}
}
sub daemon{
	print "DAEMON ... ";
	use POSIX qw(setsid);
	defined(my $rootPid = fork)   or die "Can't fork: $!";
	if($rootPid==0){
		if(getMyPID($pidfile)){print "NO EXECUTE DUBLICATE APPS\n";exit;}
		setsid or die "Can't start a new session: $!";
		chdir '/' or die "Can't chdir to /: $!";
#		open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
#		open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
#		open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
		close STDIN;
		close STDOUT;
		close STDERR;
		if(!$nowebserver){$webserver=1;}
		if(!$nologs){$logs=1;}
		mainLoop();
	}
	if($rootPid==-1){print " [ ERROR ]\n";}
	if($rootPid){print " [ STARTING A NEW SESSION ]\n";}
#	exit if $pid; # я родитель, если получен id дочернего процесса
#	if(fork==0){
#	
#	$logs=1;
	exit;
}
sub gui{
	$vis=0;
	$vismode=0;
	$controlMode=0;
	$winwidth=270;							# Ширина окна
	$winheight=450;							# Высота окна
	@value=(parsRGB(138,186,56),0.9);		# Стандартный цвет значения
	@param=(parsRGB(255,175,0),0.9);		# Стандартный цвет параметра
	@foncol=(parsRGB(0,0,0),0.8);			# Цвет параметра фона
	$yi=15;									# Расстояние между строчками
	$cx=5;									# Сдвиг контента по X
	@textDS=("Sans","normal","normal",12);	# Стандартный стиль текста
	$prev_idle=$prev_total=0;
	$about=0;
	print "...";
	if(getMyPID($pidfile)){print "NO EXECUTE DUBLICATE APPS\n";exit;}
	unlink $webserverpidfile;
	eval "use Gtk2 '-init';";
	eval "use Cairo;";
	$win=Gtk2::Window->new('popup');
	$win->set_decorated(0);
	$win->set_resizable(1);
	$win->set_keep_above('TRUE');
	$win->set_skip_taskbar_hint('TRUE');
	$win->set_skip_pager_hint('TRUE');
	$win->stick();
	$win->set_app_paintable('TRUE');
	$win->set_default_size($winwidth,$winheight);
	screen_changed($win);
	$win->show_all();
	$win->signal_connect("delete_event"=>sub{Gtk2->main_quit;});
	$win->signal_connect("destroy"=>sub{Gtk2->main_quit;});
	$win->signal_connect('screen_changed',\&screen_changed,$win);
	$win->signal_connect("enter-notify-event"=>sub{
		if(!$vis){$vis=1;}
		$enter=1;
	});
	$win->signal_connect("leave-notify-event"=>sub{
		if($vis){$vis=0;}
		$enter=0;
	});
	mainLoop();
}
sub parsRGB{
	($r,$g,$b)=@_;
	if($r ne 0){$r=($r/2.55)/100;}else{$r=0;}
	if($g ne 0){$g=($g/2.55)/100;}else{$g=0;}
	if($b ne 0){$b=($b/2.55)/100;}else{$b=0;}
	$r=~s/,/./g;$g=~s/,/./g;$b=~s/,/./g;
	return $r,$g,$b;
}
sub screen_changed{
	($widget)=@_;
	$tmp=$widget->get_screen();
	$tmp2=$tmp->get_rgba_colormap();
	print "SCREEN CHANGED [";
	if(!$tmp2){
		print "Your screen does not support alpha channel";
		$supports_alpha=0;
		$tmp2=$tmp->get_rgb_colormap();
	}else{
		$supports_alpha=1;
		print "Your screen supports alpha channel";
	}
	$widget->set_colormap($tmp2);
	print "]\n";
	monsize();
}
sub draw{
	($widget)=@_;
	$cr=Gtk2::Gdk::Cairo::Context->create($widget->window());
	$cr->set_operator('source');
	if($supports_alpha eq 1){
		$cr->set_source_rgba(@foncol);
	}else{
		$cr->set_source_rgb($foncol[0],$foncol[1],$foncol[2]);
	}
	$cr->rectangle(0,0,$winwidth,$contHeight+$yi);
	$cr->fill();
	$cr->stroke();
	$contHeight=0;
	$cr=Gtk2::Gdk::Cairo::Context->create($widget->window());
	# about
	if($about){
		$contHeight+=15;
		setText("Sans","normal","bold",14,$cx,$contHeight,parsRGB(255,168,0),1,"MyStats by Dr.Smyrke");
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,parsRGB(130,130,130),1,'smyrke2005@yandex.ru');
		$contHeight+=$yi;
		setText("Sans","normal","bold",14,$cx,$contHeight,parsRGB(255,168,0),1,"--- KEY MAPS ------------");
		$contHeight+=$yi;
		setText("Sans","normal","bold",14,$cx,$contHeight,parsRGB(255,168,0),1,"CTRL: ");
		setText(@textDS,70,$contHeight,parsRGB(130,130,130),1,'change mode');
		$contHeight+=$yi;
		setText("Sans","normal","bold",14,$cx,$contHeight,parsRGB(255,168,0),1,"ALT: ");
		setText(@textDS,70,$contHeight,parsRGB(130,130,130),1,'part eject mode');
	}
	if($controlMode){
		$contHeight+=$yi;
		setText("Sans","normal","bold",14,$cx,$contHeight,parsRGB(255,168,0),1,"--- MODES ------------");
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"Ctrl+MouseLeft");
		if($vismode){setText(@textDS,$cx+110,$contHeight,parsRGB(229,191,14),1,"V");}
		setText(@textDS,$cx+130,$contHeight,@value,"Закрепить окно");
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"Ctrl+MouseRight");
		if($logs){setText(@textDS,$cx+110,$contHeight,parsRGB(229,191,14),1,"V");}
		setText(@textDS,$cx+130,$contHeight,@value,"Запись логов");
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"Ctrl+MouseWell");
		if($webserver){setText(@textDS,$cx+110,$contHeight,parsRGB(229,191,14),1,"V");}
		setText(@textDS,$cx+130,$contHeight,@value,"Вэб сервер");
	}
	# clock
	$contHeight+=30;
	setText("Sans","normal","bold",30,$cx,$contHeight,parsRGB(229,191,14),1,$time);
	if($controlMode){
		setText("Sans","normal","bold",15,$cx+160,$contHeight-4,parsRGB(255,0,0),1,"CONTROL");
		$cr->move_to(157,$contHeight);$cr->line_to(157,$contHeight-20);
		$cr->move_to(157,$contHeight-20);$cr->line_to(265,$contHeight-20);
		$cr->move_to(265,$contHeight-20);$cr->line_to(265,$contHeight);
		$cr->move_to(265,$contHeight);$cr->line_to(157,$contHeight);
		$cr->stroke();
	}
	# uptime
	$contHeight+=$yi;
	setText(@textDS,$cx,$contHeight,@param,"Uptime:");
	setText(@textDS,$cx+60,$contHeight,@value,$uptime);
	setText(@textDS,$cx+150,$contHeight,$value[0],$value[1]+0.5,$value[2],$value[3],$date);
	$contHeight+=$yi;
	setText(@textDS,$cx,$contHeight,@param,"Cpu:");
	getBar($cx+60,$contHeight-10,$cpu,50,12,3,1,0.5,parsRGB(50,50,50));
	setText(@textDS,$cx+150,$contHeight,parsRGB(229,191,14),1,"$cpu %");
	$contHeight+=$yi;
	setText(@textDS,$cx,$contHeight,@param,"Mem:");
	getBar($cx+60,$contHeight-10,$mem,15,12,3,1,0.5,parsRGB(50,50,50));
	setText(@textDS,$cx+125,$contHeight,@value,"$mem_used / $mem_total");
	setText(@textDS,$cx+75,$contHeight,parsRGB(229,191,14),1,"$mem %");
	$contHeight+=$yi;
	setText(@textDS,$cx,$contHeight,@param,"Swap:");
	getBar($cx+60,$contHeight-10,$swap,15,12,3,1,0.5,parsRGB(50,50,50));
	setText(@textDS,$cx+125,$contHeight,@value,"$swap_used / $swap_total");
	setText(@textDS,$cx+75,$contHeight,parsRGB(229,191,14),1,"$swap %");
	$contHeight+=$yi;
	setText(@textDS,$cx,$contHeight,@param,"Apps:");
	setText(@textDS,$cx+60,$contHeight,@value,$proc);
	getIface(@ifaces);
	getDf(@df);
	if($dirs){getDirs(@lds);}
};
sub getSize{($sz)=@_;if($sz<1024){$st="$sz  bytes";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Kb";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mb";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Gb";}}}}return $st;}
sub upd{
	($time,$date)=date();
	$uptime=uptime();
	$cpu=cpu();
	$cpu=~s/,/./g;
	($mem,$mem_total,$mem_used,$swap,$swap_total,$swap_used)=mem();
	$mem=~s/,/./g;
	$proc=proc();
	@ifaces=ifaces();
	@df=df();
	@lds=undef;
	shift @lds;
	foreach $key(keys %lookdirs){
		$dirs=1;
		$dir=$lookdirs{$key};
		@size=`if [ -e $dir ]; then du -abc $dir | grep "итого" || du -abc $dir | grep "total"; fi`;chomp @size;
		$tmp=@size;($size)=split(" ",$size[$tmp-1]);
		push @lds,"$key:$dir:$size";
	}
}
sub date{
	($sek,$min,$hour,$day,$mon,$year,$wday)=localtime;
	if($wday eq 1){$wday="Пн";}
	if($wday eq 2){$wday="Вт";}
	if($wday eq 3){$wday="Ср";}
	if($wday eq 4){$wday="Чт";}
	if($wday eq 5){$wday="Пт";}
	if($wday eq 6){$wday="Сб";}
	if($wday eq 0){$wday="Вс";}
	$mon++;
	$year+=1900;
	if($day<10){$day="0$day";}
	if($mon<10){$mon="0$mon";}
	if($hour<10){$hour="0$hour";}
	if($min<10){$min="0$min";}
	if($sek<10){$sek="0$sek";}
	return "$hour:$min:$sek","$wday $day.$mon.$year";
}
sub uptime{
	open FS,"</proc/uptime";($uptime)=split(" ",<FS>);close FS;
	$h=int $uptime/60/60;
	$m=int (($uptime-($h*60*60))/60);
	$s=int ($uptime-($h*60*60)-($m*60));
	if($h<10){$h="0$h";}
	if($m<10){$m="0$m";}
	if($s<10){$s="0$s";}
	return "$h:$m:$s";
}
sub cpu{
	open FS,"</proc/stat";
	while($str=<FS>){
		chomp $str;
		@tmp=split(" ",$str);
		shift @tmp;
		$idle=$tmp[3];
		$total=0;
		foreach $tmp2(@tmp){$total+=$tmp2;}
		$diff_idle=$idle-$prev_idle;
		$diff_total=$total-$prev_total;
		$cpu=int(1000*($diff_total-$diff_idle)/$diff_total+5)/10;
		$prev_total=$total;
		$prev_idle=$idle;
		last;
	}
	close FS;
	return $cpu;
}
sub mem{
	$mem="";
	@tmp=`free -b`;
	($tmp2,$mem_t,$mem_u)=split(" ",$tmp[1]);
	#($tmp2,$tmp2,$mem_u)=split(" ",$tmp[2]);
	$mem=substr(($mem_u*100/$mem_t),0,4);
 	($tmp,$swap_t,$swap_u)=split(" ",$tmp[2]);
	#if($swap_t eq 0){
	#	$swap=$swap_t=$swap_u=0;
	#}else{
	#	$swap=int($swap_u*100/$swap_t);
	#}
	$swap=($swap_t>0)?int(($swap_t-$swap_f)/$swap_t/100):0;
	return $mem,getSize($mem_t),getSize($mem_u),$swap,getSize($swap_t),getSize($swap_u);
}
sub proc{
	$i=0;
	foreach $str(glob("/proc/*")){
		@tmp=split("/",$str);
		$tmp=pop @tmp;
		if($tmp>0){$i++;}
	}
	return $i;
}
sub ifaces{
	@ifaces=undef;
	open FS,"</proc/net/dev";
	$i=0;
	while($str=<FS>){
		if($str=~/:/){
			($iface,$traffd,undef,undef,undef,undef,undef,undef,undef,$traffu)=split(" ",$str);
			$iface=~s/://g;
			if($iface eq "lo"){next;}
			$tmp2=`ifconfig $iface | grep "inet addr"`;chomp $tmp2;
			if($tmp2=~/Устройство не обнаружено/){next;}
			if($tmp2 eq ""){
				$ip="No Address";
			}else{
				($tmp2,$tmp)=split("inet addr:",$tmp2);
				($ip)=split(" ",$tmp);
			}
			$tdown=$traffd-$ifd[$i];
			$tupl=$traffu-$ifu[$i];
			$ttot=$traffd+$traffu;
			$ifaces[$i]="$iface:$ip:$ttot:$tdown:$tupl:$traffd:$traffu";
			$ifd[$i]=$traffd;
			$ifu[$i]=$traffu;
			$i++;
		}
	}
	close FS;
	return @ifaces;
}
sub setText{
	($font,$style,$type,$size,$xpos,$ypos,$colr,$colg,$colb,$cola,$text)=@_;
	$cr->select_font_face($font,$style,$type);
	$cr->set_font_size($size);
	$cr->move_to($xpos,$ypos);
	$cr->set_source_rgba($colr,$colg,$colb,$cola);
	$cr->show_text($text);
}
sub getBar{($x,$y,$c,$baraddblocks,$blockheight,$blockwidth,$blockintery,$baralpha,$pr,$pg,$pb)=@_;$c=~s/,/./g;$baralpha=~s/,/./g;$pbar_w=($blockwidth*$baraddblocks)+($blockintery*($baraddblocks-1));$pbar=($pbar_w/100)*$c;$cr->set_source_rgba(0.45,0.45,0.45,0.4);$tmp=$x;for($i=0;$i<$baraddblocks;$i++){$cr->rectangle($tmp,$y,$blockwidth,$blockheight);$cr->fill();$tmp=$tmp+$blockintery+$blockwidth;}$pattern=Cairo::LinearGradient->create($x,$y+($blockheight/2),$x+$pbar_w,$y+($blockheight/2));$pattern->add_color_stop_rgba(0,0,0.7,0,$baralpha);$pattern->add_color_stop_rgba(1,0.7,0,0,$baralpha);$cr->set_source($pattern);$tmp=$x;for($i=0;$i<$baraddblocks;$i++){if($tmp-$x<$pbar){$cr->rectangle($tmp,$y,$blockwidth,$blockheight);$cr->fill();$tmp=$tmp+$blockintery+$blockwidth;}}}
sub getIface{
	(@context)=@_;
	foreach $str(@context){
		$contHeight+=$yi;
		$cr->set_source_rgba(0.9,0.9,0.9,0.8);
		$cr->move_to($cx,$contHeight);
		$cr->line_to($cx+10,$contHeight);
		$cr->move_to($cx+70,$contHeight);
		$cr->line_to($winwidth-$cx,$contHeight);
		$cr->stroke();
		($iface,$ip,$ttot,$tdown,$tupl,$traffd,$traffu)=split(":",$str);
		setText(@textDS,$cx+15,$contHeight,parsRGB(229,191,14),1,$iface);
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"DOWN:");
		setText(@textDS,$cx+60,$contHeight,@value,getSize($tdown)." / s");
		setText(@textDS,$cx+180,$contHeight,@value,"+ ".getSize($traffd));
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"UP:");
		setText(@textDS,$cx+60,$contHeight,@value,getSize($tupl)." / s");
		setText(@textDS,$cx+180,$contHeight,@value,"+ ".getSize($traffu));
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"IP:");
		setText(@textDS,$cx+60,$contHeight,@value,$ip);
		setText(@textDS,$cx+180,$contHeight,@value,"= ".getSize($ttot));
	}	
}
sub df{
	@df=();
	@tmp=`df -B 1`;shift @tmp;chomp @tmp;
	foreach $str(@tmp){
		($fs,$tsize,$usize,$dsize,$dprz,$mount)=split(" ",$str);
		if($fs eq "none" or $fs eq "udev" or $fs eq "tmpfs" or $fs eq "cgmfs"){next;}
		$dprz=($tsize-$dsize)/($tsize/100);
		$dprz=substr($dprz,0,4);
		if($mount ne "/"){
			@tmp2=split("/",$mount);
			$nazv=$tmp2[@tmp2-1];
		}else{$nazv=$mount;}
		$dprz=~s/,/./g;
		push @df,"$nazv:$mount:$fs:$dprz:$tsize:$usize:$dsize";
	}
	return @df;
}
sub getDf{
	(@context)=@_;
	foreach $str(@context){
		($nazv,$mount,$fs,$dprz,$tsize,$usize,$dsize)=split(":",$str);
		if($mount=~"/media"){
			if($pointer[2]>$contHeight and $pointer[2]<$contHeight+$yi*2){
				if($altMode){$cr->set_source_rgba(1,0,0,0.1);}else{$cr->set_source_rgba(0.9,0.9,0.9,0.1);}
				$cr->rectangle(0,$contHeight+3,$winwidth,$yi*2);
				$cr->fill();
				$cr->stroke();
				if($pointer[3]=~/button1-mask/){
					if(!$altMode){
						if(fork==0){exec "$fmanager $mount || xdg-open $mount";kill 'TERM',$$;}
					}else{
						$fs2=substr($fs,0,-1);if(fork==0){exec "udisks --unmount $fs && udisks --detach $fs2 && notify-send -i gnome-terminal 'Операции с устройствами' 'Устройство успешно извлечено!' || udisksctl unmount -b $fs && udisksctl power-off -b $fs2 && notify-send -i gnome-terminal 'Операции с устройствами' 'Устройство успешно извлечено!'";kill 'TERM',$$;}
					}
				}
			}
		}
		$contHeight+=$yi;
		if(length($nazv)>4){$nazv=substr($nazv,0,4);$nazv="$nazv...";}
		setText(@textDS,$cx,$contHeight,@param,"[$nazv]:");
		getBar($cx+60,$contHeight-10,$dprz,50,12,3,1,0.5,parsRGB(50,50,50));
		setText(@textDS,$cx+150,$contHeight,parsRGB(229,191,14),1,"$dprz %");
		$contHeight+=$yi;
		setText(@textDS,$cx,$contHeight,@param,"Free:");
		setText(@textDS,$cx+60,$contHeight,@value,getSize($dsize)." / ".getSize($tsize));
	}
}
sub getDirs{
	(@context)=@_;
	$contHeight+=$yi;
	$cr->set_source_rgba(0.9,0.9,0.9,0.8);
	$cr->move_to($cx,$contHeight);
	$cr->line_to($cx+10,$contHeight);
	$cr->move_to($cx+100,$contHeight);
	$cr->line_to($winwidth-$cx,$contHeight);
	$cr->stroke();
	setText(@textDS,$cx+15,$contHeight,parsRGB(229,191,14),1,"Directories");
	foreach $string(@context){
		$contHeight+=$yi;
		($dname,$durl,$dsize)=split(":",$string);
		setText(@textDS,$cx,$contHeight,@param,"$dname:");
		setText(@textDS,$cx+60,$contHeight,@value,getSize($dsize));
	}
}
sub logs{
	if(!-d $logsdir){mkdir $logsdir;}
	if(!-d $logsdir){print "[Can not find the log directory]\n";return 1;}
	open LFS,">>$logsdir/$year-$mon-$day.log";
	print LFS "$hour:$min	cpu:$cpu	ram:$mem:$mem_t:$mem_u	swap:$swap:$swap_t:".$swap_u."	apps:$proc	".join("===",@ifaces)."	".join("===",@df)."	".join("===",@lds)."\n";
	close LFS;
}
sub drawLog{
	print "DRAWING MODE ... ";
	$file=shift @_;
	if(!-f "$logsdir/$file"){print "[Can not find the log file]\n";return 0;}
	$imgwidth=1024;				# Размер изображения по горизонтали
	$imgheight=768;				# Размер изображения по вертикали
	$setka=7;					# Резмер сетки в пикселях
	use Cairo;
	open FSL,"<$logsdir/$file";@data=<FSL>;close FSL;chomp @data;
	$chas=($imgwidth-25)/24;
	# DRAW CPU
	$surface=Cairo::ImageSurface->create('argb32',$imgwidth,$imgheight);
	$cr=Cairo::Context->create($surface);
	setka();
	$cr->select_font_face ('Play', 'normal', 'normal');
	$cr->set_font_size(10);
	$cr->set_source_rgba(0,0,0,0.8);
	$cr->set_line_width(1);
	OY(20,5);
	OX(24,1);
	$cr->stroke;
	$cr->set_source_rgba(parsRGB(254,75,0),1);
	$cr->set_line_width(2);
	$i=0;
	foreach $string(@data){
		($time,$cpu)=split("	",$string);
		($hour,$min)=split(":",$time);
		($cpu,$cpu)=split(":",$cpu);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$cpu);
		$cr->move_to ($x,$y);
		if($data[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($time,$cpu)=split("	",$data[$i+1]);
		($hour,$min)=split(":",$time);
		($cpu,$cpu)=split(":",$cpu);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$cpu);
		$cr->line_to($x,$y);
		$i++;
	}
	$cr->stroke;
	$surface->write_to_png ("$logsdir/cpu.png");
	# DRAW RAM
	$surface=Cairo::ImageSurface->create('argb32',$imgwidth,$imgheight);
	$cr=Cairo::Context->create($surface);
	setka();
	$cr->select_font_face ('Play', 'normal', 'normal');
	$cr->set_font_size(10);
	$cr->set_source_rgba(0,0,0,0.8);
	$cr->set_line_width(1);
	OY(20,5);
	OX(24,1);
	$cr->stroke;
	$cr->set_source_rgba(parsRGB(56,252,7),1);
	$cr->set_line_width(2);
	$i=0;
	foreach $string(@data){
		($time,$ram,$ram)=split("	",$string);
		($hour,$min)=split(":",$time);
		($ram,$ram)=split(":",$ram);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$ram);
		$cr->move_to ($x,$y);
		if($data[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($time,$ram,$ram)=split("	",$data[$i+1]);
		($hour,$min)=split(":",$time);
		($ram,$ram)=split(":",$ram);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$ram);
		$cr->line_to($x,$y);
		$i++;
	}
	$cr->stroke;
	$surface->write_to_png ("$logsdir/ram.png");
	# DRAW SWAP
	$surface=Cairo::ImageSurface->create('argb32',$imgwidth,$imgheight);
	$cr=Cairo::Context->create($surface);
	setka();
	$cr->select_font_face ('Play', 'normal', 'normal');
	$cr->set_font_size(10);
	$cr->set_source_rgba(0,0,0,0.8);
	$cr->set_line_width(1);
	OY(20,5);
	OX(24,1);
	$cr->stroke;
	$cr->set_source_rgba(parsRGB(248,252,7),1);
	$cr->set_line_width(2);
	$i=0;
	foreach $string(@data){
		($time,$swap,$swap,$swap)=split("	",$string);
		($hour,$min)=split(":",$time);
		($swap,$swap)=split(":",$swap);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$swap);
		$cr->move_to ($x,$y);
		if($data[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($time,$swap,$swap,$swap)=split("	",$data[$i+1]);
		($hour,$min)=split(":",$time);
		($swap,$swap)=split(":",$swap);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$swap);
		$cr->line_to($x,$y);
		$i++;
	}
	$cr->stroke;
	$surface->write_to_png ("$logsdir/swap.png");
	# DRAW IFACE
	@ifaced=@ifaceu=undef;
	shift @ifaced;
	shift @ifaceu;
	foreach $string(@data){
		if(!$drawIface){last;}
		($time,$tmp,$tmp,$tmp,$tmp,$interfaces)=split("	",$string);
		foreach $string(split("===",$interfaces)){
			($iface,$ip,$ttot,$tdown,$tupl,$traffd,$traffu)=split(":",$string);
			if($iface eq $drawIface){
				push @ifaced,$time.":".($tdown/1024);
				push @ifaceu,$time.":".($tupl/1024);
				last;
			}
		}
	}
	if($drawIface){
		$surface=Cairo::ImageSurface->create('argb32',$imgwidth,$imgheight);
		$cr=Cairo::Context->create($surface);
		setka();
		$cr->select_font_face ('Play', 'normal', 'normal');
		$cr->set_font_size(10);
		$cr->set_source_rgba(0,0,0,0.8);
		$cr->set_line_width(1);
		$chagTraf=200;
		$chagPx=70;
		OY($chagPx,$chagTraf);
		OX(24,1);
		$h=($imgheight-25)/$chagPx;
	}
	if($drawIface){
		$cr->stroke;
		$cr->set_source_rgba(parsRGB(41,167,2),1);
		$cr->set_line_width(2);
	}
	$i=0;
	foreach $str(@ifaced){
		if(!$drawIface){last;}
		($hour,$min,$val)=split(":",$str);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-(($h/$chagTraf)*$val);
		$cr->move_to ($x,$y);
		if($ifaced[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($hour,$min,$val)=split(":",$ifaced[$i+1]);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-(($h/$chagTraf)*$val);
		$cr->line_to($x,$y);
		$i++;
	}
	if($drawIface){
		$cr->stroke;
		$cr->set_source_rgba(parsRGB(169,0,202),1);
		$cr->set_line_width(2);
	}
	$i=0;
	foreach $str(@ifaceu){
		if(!$drawIface){last;}
		($hour,$min,$val)=split(":",$str);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-(($h/$chagTraf)*$val);
		$cr->move_to ($x,$y);
		if($ifaceu[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($hour,$min,$val)=split(":",$ifaceu[$i+1]);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-(($h/$chagTraf)*$val);
		$cr->line_to($x,$y);
		$i++;
	}
	if($drawIface){
		$cr->stroke;
		$surface->write_to_png ("$logsdir/iface.png");
	}
	# DRAW DISKS
	@diskp==undef;
	shift @diskp;
	foreach $string(@data){
		if(!$drawDisk){last;}
		($time,$tmp,$tmp,$tmp,$tmp,$tmp,$disks)=split("	",$string);
		foreach $string(split("===",$disks)){
			($nazv,$mount,$fs,$dprz,$tsize,$usize,$dsize)=split(":",$string);
			if($fs eq $drawDisk){
				push @diskp,"$time:$dprz";
				last;
			}
		}
	}
	if($drawDisk){
		$surface=Cairo::ImageSurface->create('argb32',$imgwidth,$imgheight);
		$cr=Cairo::Context->create($surface);
		setka();
		$cr->select_font_face ('Play', 'normal', 'normal');
		$cr->set_font_size(10);
		$cr->set_source_rgba(0,0,0,0.8);
		$cr->set_line_width(1);
		OY(20,5);
		OX(24,1);
		$cr->stroke;
		$cr->set_source_rgba(parsRGB(248,252,7),1);
		$cr->set_line_width(2);
	}
	$i=0;
	foreach $str(@diskp){
		if(!$drawDisk){last;}
		($hour,$min,$val)=split(":",$str);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$val);
		$cr->move_to ($x,$y);
		if($diskp[$i+1] eq undef){$cr->line_to($x,$y);last;}
		($hour,$min,$val)=split(":",$diskp[$i+1]);
		$x=25+($chas*$hour)+(($chas/60)*$min);
		$y=($imgheight-25)-((($imgheight-25)/100)*$val);
		$cr->line_to($x,$y);
		$i++;
	}
	if($drawDisk){
		$cr->stroke;
		$surface->write_to_png ("$logsdir/disk.png");
	}
	return 1;
}
sub setka{$cr->set_source_rgba(0,0,0,0.3);for($i=0;$i<$imgwidth;$i+=$setka){$cr->move_to ($i,0);$cr->line_to($i,$imgheight);}for($i=0;$i<$imgheight;$i+=$setka){$cr->move_to (0,$i);$cr->line_to($imgwidth,$i);}$cr->set_line_width(0.5);$cr->stroke;}
sub OY{($chagY,$chagChis)=@_;$tmp=($imgheight-25)/$chagY;$ch=0;for($i=$imgheight-25;$i>0;$i-=$tmp){$cr->move_to(5,$i+5);$cr->show_text("$ch");$cr->move_to(25,$i);$cr->line_to($imgwidth,$i);$ch+=$chagChis;}}
sub OX{($chagX,$chagChis)=@_;$tmp=($imgwidth-25)/$chagX;$ch=0;for($i=25;$i<$imgwidth-25;$i+=$tmp){$cr->move_to ($i-5,$imgheight-15);$cr->show_text ("$ch");	$cr->move_to ($i,$imgheight-25);$cr->line_to($i,0);$ch+=$chagChis;}}
sub startWebServer{
	$SIG{CHLD}="IGNORE";
	$webservermode=1;
	print "WEB SERVER [";
	use IO::Socket;
	use IO::Handle;
	socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket!\n";
	setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
	$myaddr=sockaddr_in($port, INADDR_ANY);
	bind(SERVER, $myaddr) or die "I can not bind port!\n"; 
	listen(SERVER, SOMAXCONN);
	if(fork==0){
		print " ACTIVATED ] PID: [$$] PORT: [$port]\n";
		if(getMyPID($webserverpidfile)){print "NO EXECUTE DUBLICATE APPS\n";exit;}
		print "Waiting for connection...\n";
		while($client_addr=accept(CLIENT,SERVER)){
			($client_port, $client_ip) = sockaddr_in($client_addr);
			$client_ipnum = inet_ntoa($client_ip);
#			$client_host = gethostbyaddr($client_ip, PF_INET);
			if(fork==0){
				print "WEB SERVER [${client_ipnum}] Connected PID: [$$]\n";
				CLIENT->autoflush(1);
				while(1){
					$count=sysread(CLIENT,$wwwData,1024);
					if($count eq 0 or $count eq "" or !-f $webserverpidfile){
						print "WEB SERVER [${client_ipnum}] Disconnected PID: [$$]\n";
						close CLIENT;
						kill 'TERM',$$;
					}
					parsHead();
					reUrl();
				}
			}
		}
		close SERVER;
		print "WEB SERVER [ DEACTIVATED ]\n";
		exit;
	}
}
sub parsHead{
	@wwwData=split("\r\n",$wwwData);
	($httpType,$url,$httpVersion)=split(" ",$wwwData[0]);
	$url=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	print "WEB SERVER [${client_ipnum}] >>> [$url]\n";
}
sub reUrl{
$head="<!DOCTYPE html>\n<html lang=\"ru\">\n<head><meta charset=\"utf-8\"/>
<style>
body{font-family:Arial,Sans,Microsoft Sans Serif,consolas;font-size:10pt;text-shadow: 0px 1px 0px black;color:white;background-image:url(data:image/gif;base64,R0lGODlhPABCANUAACssLiYnKSMlJiUmJyUnKCEiJCAhIiQlJi8xMyIkJSgpKx8gIT9BQzM1Nx4fITU3OTs9PyIjJSEhIygqLD0/QiAhIx4fICcoKiosLUBCRCgqKzAyNC0uLyEjJC8wMjo7Pi0uMDk7PSkqLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAA8AEIAAAb/QIBwKDwIBoGkcqlhEJ9QI5LJdEKvAKoWAcFetVSu9zsFhx7jaFl7vloMB4Ua3KAgiMY3XP4k+Ld2eAZ6Dh18fWEZDUMEg4ULj4d4iYtFjpASFZAYTwh3F6AbH4GWmAWnmgacRJ5ZoaOVWaaoCagenQ8QDLsPn7JwtUfCcLesubsQvYyZtGuqvmm/ws7P0csR00vCaNbSf9oFAdzW2NngCV3dzdrf6eTB7EtW72vx89Hh9ez3aVLx8t1c6Vsipts/bQXpHVTQJuBCJA0NDvRTB1oePZKKfENIytWlOHPYVbz2KBIZJiNLlSyUEcSEbwBEdWw0i5mqTtBkxqKZitZN/1afkCkbYjObLVy6eFkEZpQYUiz+okqpZpCpPqoKN/4JNw5fPq1IuAZc98+dV6ngzPYzZ28s27QO31aJO3EKvzEPkSSMllfAXr51GXYFvDAiEYwhRc68uCcxx6WEDJ0kqIjkrJYvFe/8aHPVkFagYsKy7PPn55yjVRY9aixpMsjwhvlFKhQ2W6x8rVLjAG1tuavi3MrdJrwuuuIHj6uLXRb5wbtevi6EDnW4XbrJ/+K17lft9sCGCR8M7/tfSo+IHVOGnH5SvPM8L09WAv+SKcwwdZL26VkI6Fcz1dQZTlnUtp9ss7VmIFG6yVbMZ7lU99tuvX03HG/OsSPWctwNNtMGWed4Fx1zIWaoIXVucKdcVs9hN52L5okoYXYyzliWhxbemCJIiMTIXmM9vreYfZKpV99KLM1HUWWq8UdgaPo16SRQrogWoICsQejaUN40laCWC3bZFIZVTegMmSzWs2Ga5+Bo43gmwsUhWADNmRyK6rUlkXFNwCikn4oBygR5OcZDqBcPHdmee0L+yCOjKDH5C5L4abZfkiFZuRmWpvmH2pU9DUjlBWEqsBqCD/p3jFIHOvjUFw2WgVt5aGGD5lngxblVcHbC2auGK+J6p651PhEEADs=);background-attachment:fixed;}
a{outline:none;-webkit-transition-property:color;-webkit-transition-duration:1s;-moz-transition-property:color;-o-transition-property:color;-ms-transition-property:color;transition-property:color;-moz-transition-duration:1s;-o-transition-duration:1s;-ms-transition-duration:1s;transition-duration:1s;}a:active{position:relative;top:1px;left:1px;}b{text-shadow:0px 0px 5px #FFCF7D;}a:link,a:visited,a:active{color:#999999;text-decoration:none;font-size:14pt;}a:hover{COLOR:#ff9900;text-shadow: 0 0 3px #FFCC80;}
.fieldset{border-left-width:0px;border-right-width:0px;border-bottom-width:0px;font-size:12pt;margin-bottom:0px;padding-bottom:0px;}
legend{color:#fca04c;font-weight:bold;text-shadow:1px 1px 0px black;}
.graph{background:rgba(255,255,255,0.7);display:inline-block;vertical-align:top;}
#clock{color:#20BF01;font-size:30pt;}
.param{color:#FFAF00;text-shadow:0px 0px 5px #FFCA55;}
.val{color:#999;}
.valgreen{text-shadow:0px 0px 5px #61FF62;color:#00FF03;}
.pbar{width:150px;background:#c6c6c6;border:1px solid #9c9c9c;height:12px;}
.bar{
	border:1px solid #901814;
	background-color:#ee281f;
	height:12px;
	top:0;
	left:0;
	background:#ee281f;background:-moz-linear-gradient(top,rgba(238,40,31,1) 0,rgba(238,40,31,1) 49%,rgba(218,26,20,1) 49%,rgba(218,26,20,1) 100%);background:-webkit-gradient(linear,left top,left bottom,color-stop(0%,rgba(238,40,31,1)),color-stop(49%,rgba(238,40,31,1)),color-stop(49%,rgba(218,26,20,1)),color-stop(100%,rgba(218,26,20,1)));background:-webkit-linear-gradient(top,rgba(238,40,31,1) 0,rgba(238,40,31,1) 49%,rgba(218,26,20,1) 49%,rgba(218,26,20,1) 100%);background:-o-linear-gradient(top,rgba(238,40,31,1) 0,rgba(238,40,31,1) 49%,rgba(218,26,20,1) 49%,rgba(218,26,20,1) 100%);background:-ms-linear-gradient(top,rgba(238,40,31,1) 0,rgba(238,40,31,1) 49%,rgba(218,26,20,1) 49%,rgba(218,26,20,1) 100%);background:linear-gradient(to bottom,rgba(238,40,31,1) 0,rgba(238,40,31,1) 49%,rgba(218,26,20,1) 49%,rgba(218,26,20,1) 100%);filter:progid:DXImageTransform.Microsoft.gradient(startColorstr = '#ee281f',endColorstr = '#da1a14',GradientType = 0)}
</style><title>-= Simple Web Server for MyStats =-</title></head><body>";
$bottom='<center><text style="font-size:9pt;" class="val">-= Simple Web Server for MyStats by Dr.Smyrke =-</text></center></body></html>';
	($url,$args)=split("[?]",$url);
	$findUrl=0;
	if($url eq "/"){
		$cont=startWwwCont(0);
		print CLIENT http_headers('200 OK').$cont;
		$findUrl=1;
	}
	if($url eq "/UPD"){
		$cont=startWwwCont(1);
		print CLIENT http_headers('200 OK').$cont;
		$findUrl=1;
	}
	if($url eq "/DRAW"){
		($lf,$if,$dsk)=split(":",$args);
		if($if ne undef){$drawIface=$if;}
		if($dsk ne undef){$drawDisk=$dsk;}
		if(drawLog($lf)){$dstat="OK";}else{$dstat="ERROR";}
		$cont="$head<meta http-equiv=\"Refresh\" content=\"0; URL=/\"><script>alert('DRAWING ... [ $dstat ]');</script>$bottom";
		print CLIENT http_headers('200 OK').$cont;
		$findUrl=1;
		sleep 15;
	}
	if($url eq "/cpu.png"){sendFile("$logsdir/cpu.png");$findUrl=1;}
	if($url eq "/ram.png"){sendFile("$logsdir/ram.png");$findUrl=1;}
	if($url eq "/swap.png"){sendFile("$logsdir/swap.png");$findUrl=1;}
	if($url eq "/iface.png"){sendFile("$logsdir/iface.png");$findUrl=1;}
	if($url eq "/disk.png"){sendFile("$logsdir/disk.png");$findUrl=1;}
	if(!$findUrl){
		$cont="$head<br>$url<hr>ERROR 404 (File not Found/Файл не найден)$bottom";
		print CLIENT http_headers('404 Forbidden')."$cont";
	}
	sleep 5;
}
sub http_headers{
($status,$ctype,$size,$conn)=@_;
if($ctype eq ""){$ctype="text/html; charset=UTF-8";}
if($size eq ""){$size=length(Encode::encode_utf8($cont));}
if($url eq ""){$url="/";}
if($conn eq ""){$conn="close";}
print "WEB SERVER [${client_ipnum}] <<< $status,$url,$ctype \n";
return <<RESPONSE;
HTTP/1.1 $status
Server: DrSmyrke Web Server
Content-type: $ctype
Content-Length: $size
Accept-Ranges: bytes
Connection: $conn

RESPONSE
}
sub startWwwCont{
	$cmd=shift @_;
	($time,$date)=date();
	$uptime=uptime();
	open LFS,"<$logsdir/$year-$mon-$day.log";
	while($str=<LFS>){$i=$str;}
	close LFS;
	($tmp,$cpu,$ram,$swap,$apps,$ifaces,$df,$lds)=split("	",$i);
	($tmp,$cpu)=split(":",$cpu);
	($tmp,$mem,$mem_t,$mem_u)=split(":",$ram);
	($tmp,$swap,$swap_t,$swap_u)=split(":",$swap);
	($tmp,$apps)=split(":",$apps);
	$tmpc=$head;
	if($cmd eq 0){$tmpc.='<a href="/UPD">UPDATE MODE</a> | ';}
	if($cmd eq 1){$tmpc.='<a href="/">NO UPDATE MODE</a> | ';}
	$tmpc.='Drawing <select id="logselect">';
	foreach $str(glob("$logsdir/*.log")){
		@tmp=split("/",$str);
		$name=pop @tmp;
		$add=($name eq "$year-$mon-$day.log")?" selected":"";
		$tmpc.='<option value="'.$name.'"'.$add.'>'.$name.'</option>';
	}
	$tmpc.='</select> Interface: <input type="text" id="iface" name="iface"> Disk: <input type="text" id="disk" name="disk"> <input type="button" value="OK" onClick="draw();">';
	$tmpc.='<hr><div style="display:inline-block;vertical-align:top;">
	<table>
		<tr><td colspan="3"><span id="clock">'.$time.'</span></td></tr>
		<tr><td class="param" width="70px"><b>Uptime:</b></td><td class="val" width="100px">'.$uptime.'</td><td class="valgreen" align="right">'.$date.'</td></tr>
		<tr><td class="param"><b>Cpu:</b></td><td class="pbar" colspan="2"><div class="bar" style="width:'.$cpu.'%;" id="cpu_bar"></div></td><td>'.$cpu.'%</td></tr>
		<tr><td class="param"><b>Mem:</b></td><td class="pbar"><div class="bar" style="width:'.$mem.'%;" id="mem_bar"></div></td><td>'.$mem.'%</td><td class="val">'.getSize($mem_u).' / '.getSize($mem_t).'</td></tr>
		<tr><td class="param"><b>Swap:</b></td><td class="pbar"><div class="bar" style="width:'.$swap.'%;" id="swap_bar"></div></td><td>'.$swap.'%</td><td class="val">'.getSize($swap_u).' / '.getSize($swap_t).'</td></tr>
		<tr><td class="param"><b>Apps:</b></td><td colspan="3" class="val">'.$apps.'</td></tr>';
	foreach $str(split("===",$ifaces)){
		($iface,$ip,$ttot,$tdown,$tupl,$traffd,$traffu)=split(":",$str);
		$tmpc.='<tr><td class="param" colspan="4"><fieldset class="fieldset"><legend>'.$iface.'</legend></fieldset></td></tr><tr><td class="param">DOWN:</td><td class="val">'.getSize($tdown).' / s</td><td></td><td class="val">+ '.getSize($traffd).'</td></tr><tr><td class="param">UP:</td><td class="val">'.getSize($tupl).' / s</td><td></td><td class="val">+ '.getSize($traffu).'</td></tr><tr><td class="param">IP:</td><td class="val">'.$ip.'</td><td></td><td class="val">= '.getSize($ttot).'</td></tr>';
	}
	$i=0;
	foreach $str(split("===",$df)){
		if($i eq 0){$tmpc.='<tr><td class="param" colspan="4"><fieldset class="fieldset"><legend>Mount disks</legend></fieldset></td></tr>';}
		($nazv,$mount,$fs,$dprz,$tsize,$usize,$dsize)=split(":",$str);
		if(length($nazv)>7){$nazv=substr($nazv,0,7);$nazv="$nazv...";}
		$tmpc.='<tr><td class="param">['.$nazv.']:</td><td colspan="3" class="pbar"><div class="bar" style="width:'.$dprz.'%;" id="df'.$i.'_bar"></div></td><td>'.$dprz.'%</td></tr><tr><td class="param">Free:</td><td class="val">'.getSize($dsize).' / '.getSize($tsize).'</td><td colspan="2"><i>'.$fs.'</i></td></tr>';
		$i++;
	}
	$i=0;
	foreach $str(split("===",$lds)){
		if($i eq 0){$tmpc.='<tr><td class="param" colspan="4"><fieldset class="fieldset"><legend>Directories</legend></fieldset></td></tr>';}
		($nazv,$dir,$size)=split(":",$str);
		$tmpc.='<tr><td class="param">'.$nazv.':</td><td class="val">'.getSize($size).'</td><td colspan="3"><i>'.$dir.'</i></td></tr>';
		$i++;
	}
	$tmpc.='</table></div><div style="display:inline-block;vertical-align:top;">';
	$tmpc.='<fieldset class="graph"><legend>CPU</legend><a href="/cpu.png" target="_blank"><img src="/cpu.png" width="240px"></a></fieldset><fieldset class="graph"><legend>RAM</legend><a href="/ram.png" target="_blank"><img src="/ram.png" width="240px"></a></fieldset>';
	$tmpc.='<fieldset class="graph"><legend>SWAP</legend><a href="/swap.png" target="_blank"><img src="/swap.png" width="240px"></a></fieldset><fieldset class="graph"><legend>INET</legend><a href="/iface.png" target="_blank"><img src="/iface.png" width="240px"></a></fieldset>';
	$tmpc.='<fieldset class="graph"><legend>DISK</legend><a href="/disk.png" target="_blank"><img src="/disk.png" width="240px"></a></fieldset>';
	$tmpc.='</div><script>';
	$tmpc.="function draw(){
		lf=document.getElementById('logselect').value;
		ifac=document.getElementById('iface').value;
		df=document.getElementById('disk').value;
		document.location.href='/DRAW?'+lf+':'+ifac+':'+df;
	}";
	$tmpc.='</script>';
	if($cmd eq 1){$tmpc.='<meta http-equiv="Refresh" content="60; URL=/UPD">';}
	$tmpc.=$bottom;
	return $tmpc;
}
sub stopWebServer{
	$pid=getMyPID($webserverpidfile);
	print "STOPPING WEB SERVER PID: [$pid] ... \n";
	close SERVER;
	unlink $webserverpidfile;
	kill 'TERM',$pid;
	$webservermode=0;
	print "WEB SERVER [ DEACTIVATED ]\n";
}
sub sendFile{
	$file=shift @_;
	($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($file);
	print CLIENT http_headers('200 OK',"image/png",$size);
	open fs,"<$file";
	while(read fs,$buffer,1024){print CLIENT $buffer;}
	close fs;
}
sub getHelp{
	print "=== Help Page for MyStats by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
--daemon			Run application as a daemon
--savelogs			Activation Log Saver
--nologs			Deactivating save logs
--nowebserver			Deactivating the Web server
--drawlogs <LOGFILE>		Activation drawing graphs specified log
-drawiface <INTERFACE>		Defining the network interface for rendering graphics (optional)
-drawdisk <DISK>		Defining a local drive for rendering graphics (optional)
--stop				Stopping the application
-logs <DIR>			Determination log storage directory (default: ~/.mystats)
-pidfile <FILE>			Determining PID file (default: ~/.run/mystats.pid)
-webserverpidfile <FILE>	Determining PID file for the Web server (default: ~/.run/mystats_webserver.pid)
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($0);
	$i=0;
	open FS,"<$0";
	while($tmp=<FS>){$i++;}
	close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
