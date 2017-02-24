#!/usr/bin/perl
# BACKUP, a backup app based on DrSmyrke
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
use Gtk2 '-init';
use Encode;
use utf8;
############## Данные ##################
$pwd=$0;$pwd=~s#(.*)/.*#$1#;
if(-l $0){$pwd=readlink $0;$pwd=~s#(.*)/.*#$1#;}
$find=0;
if(-f "$pwd/backup.dat" and !$find){require "$pwd/config";$find=1;}
if(!$find){
	print "[$pwd]\n";
	print "Списка данных для синхронизации не обнаружено!!!\n";
	exit;
}
sub getSize{($sz)=@_;if($sz<1024){$st="$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Гб";}}}}return $st;}
############ Инициализация ###############
open fs,"<$pwd/backup.dat";@list=<fs>;close fs;chomp @list;



# создаем главное окно
$main=Gtk2::Window->new('toplevel');
$main->set_title("Backup v1.0");
$main->set_default_size("650","480");
$main->set_position("GTK_WIN_POS_CENTER_ALWAYS");
$main->set_resizable(1);
# Обрабочики сигналов окна
$main->signal_connect("destroy"=>sub{Gtk2->main_quit;});
# Построение окна
$vbox=Gtk2::VBox->new;
	$pbox=Gtk2::HBox->new;
		$hfreebar=Gtk2::ProgressBar->new;
	$pbox->pack_start($hfreebar,1,1,0);
		$bfreebar=Gtk2::ProgressBar->new;
	$pbox->pack_start($bfreebar,1,1,0);
$vbox->pack_start($pbox,0,1,0);
$tmp=Gtk2::ScrolledWindow->new;
$tmp->set_policy("automatic","automatic");
	$windbackup=Gtk2::Viewport->new;
		$tablekont=Gtk2::VBox->new;
			$table=Gtk2::Table->new(1,7,FALSE);
				$table->attach_defaults(Gtk2::Label->new("HOME"),0,4,0,1);
				$table->attach_defaults(Gtk2::VSeparator->new,4,5,0,1);
				$table->attach_defaults(Gtk2::Label->new("BACKUP"),5,9,0,1);
		$tablekont->pack_start($table,0,0,0);
		$i=0;
		backupBuild();
	$windbackup->add($tablekont);
$tmp->add($windbackup);
$vbox->add($tmp);
$vbox->pack_start(Gtk2::HSeparator->new,0,1,0);
	$hbox=Gtk2::HBox->new;
		$butbackupupd=Gtk2::Button->new;
		$butbackupupd->set_image(Gtk2::Image->new_from_stock("gtk-refresh",button));
		$butbackupupd->set_tooltip_text("Обновить данные");
		$butbackupupd->signal_connect("clicked"=>sub{backupUPD();});
	$hbox->pack_start($butbackupupd,0,0,0);
		$butbackupgohome=Gtk2::Button->new;
		$butbackupgohome->set_image(Gtk2::Image->new_from_stock("gtk-go-back",button));
		$butbackupgohome->set_tooltip_text("Извлечь из бэкапа");
		$butbackupgohome->signal_connect("clicked"=>sub{backupEx();});
	$hbox->pack_start($butbackupgohome,0,0,0);
		$butbackupgobackup=Gtk2::Button->new;
		$butbackupgobackup->set_image(Gtk2::Image->new_from_stock("gtk-go-forward",button));
		$butbackupgobackup->set_tooltip_text("В бэкап");
		$butbackupgobackup->signal_connect("clicked"=>sub{backupBack();});
	$hbox->pack_start($butbackupgobackup,0,0,0);
$vbox->pack_start($hbox,0,0,0);
	$backupstat=Gtk2::Label->new;
	$backupstat->set_alignment(0,0.5);
$vbox->pack_start($backupstat,0,1,0);
$main->add($vbox);
$main->show_all;
# инициализация
backupUPD();
Gtk2->main;

sub getElem{
	($conttype,$path,$backupPath)=@_;
	$path=~s/~/$home/eg;
	$ch=$cb=-1;
	if($conttype eq "DIR" or $conttype eq "ARJ"){
		if(-d "$path"){
			$c=`find $path/ -type l | wc -l`;chomp $c;$ch+=$c;
			$c=`find $path/ -type f | wc -l`;chomp $c;$ch+=$c;
			$ch++;
		}
		if(-d "$backup/$backupPath"){
			$c=`find $backup/$backupPath/ -type l | wc -l`;chomp $c;$cb+=$c;
			$c=`find $backup/$backupPath/ -type f | wc -l`;chomp $c;$cb+=$c;
			$cb++;
		}
		if(-f "$backup/$backupPath.7z"){
			@cmd=`7z l $backup/$backupPath.7z`;
			($cmd,$cmd,$cb)=split(" ",pop @cmd);
		}
	}
	if($conttype eq "FILE"){
		if(-f "$path"){$ch=1;}
		if(-f "$backup/$backupPath"){$cb=1;}
	}
	$clh=$clb="valblack";
	$t="";
	if($ch>=0){
		if($cb>=0){
			$t=($cb-$ch);
			if($cb<$ch){$clh="valgreen";$clb="valorange";}
			if($cb>$ch){$t="+$t";$clh="valorange";$clb="valgreen";}
		}
	}
	if($cb<0){$cb="N/A";$clb="valfiol";}
	if($ch<0){$ch="N/A";$clh="valfiol";}
	return (eval("\$$clh"),$ch,eval("\$$clb"),$cb,$t);
}
sub getSizeStr{
	($conttype,$path,$backupPath)=@_;
	$path=~s/~/$home/eg;
	$ch=-1;$cb=-1;
	if($conttype eq "DIR" or $conttype eq "ARJ"){
		if(-d "$path"){
			@cmd=`du -b -c $path`;($ch)=split(" ",pop @cmd);
			($device,$inode,$m,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$path");$mtimeh=$mtime;
		}
		if(-d "$backup/$backupPath"){
			@cmd=`du -b -c $backup/$backupPath`;($cb)=split(" ",pop @cmd);
			($device,$inode,$m,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$backup/$backupPath");$mtimeb=$mtime;
		}
		if(-f "$backup/$backupPath.7z"){
			($device,$inode,$m,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$backup/$backupPath.7z");$cb=$size;$mtimeb=$mtime;
		}
	}
	if($conttype eq "FILE"){
		if(-f "$path"){
			($device,$inode,$m,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$path");$ch=$size;$mtimeh=$mtime;
		}
		
		if(-f "$backup/$backupPath"){
			($device,$inode,$m,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$backup/$backupPath");$cb=$size;$mtimeb=$mtime;
		}
	}
	$clh=$clb=$clh2=$clb2="valblack";
	$t=$t2="";
	if($ch>=0){
		if($cb>=0){
			$t=($cb-$ch);
			if($cb<$ch){$clh="valgreen";$clb="valorange";}
			if($cb>$ch){$t="+$t";$clh="valorange";$clb="valgreen";}
		}
	}
	if($mtimeh>=0){
		if($mtimeb>=0){
			$t2=($mtimeb-$mtimeh);
			if($mtimeb<$mtimeh){$clh2="valgreen";$clb2="valorange";}
			if($mtimeb>$mtimeh){$t2="+$t2";$clh2="valorange";$clb2="valgreen";}
		}
	}
	if($cb<0){$cb="N/A";$clb="valfiol";}
	if($ch<0){$ch="N/A";$clh="valfiol";}
	if($ch!="N/A"){$ch=getSize($ch);}
	if($cb!="N/A"){$cb=getSize($cb);}
	@time=localtime($mtimeh);
	$year=1900+$time[5];$month=1+$time[4];$day=$time[3];
	$day=($day<10)?"0$day":$day;
	$month=($month<10)?"0$month":$month;
	$mtimeh="$day.$month.$year";
	@time=localtime($mtimeb);
	$year=1900+$time[5];$month=1+$time[4];$day=$time[3];
	$day=($day<10)?"0$day":$day;
	$month=($month<10)?"0$month":$month;
	$mtimeb="$day.$month.$year";
	if($mtimeb=="01.01.1970"){$mtimeb="N/A";$clb2="valfiol";if($mtimeh!="N/A"){$clh2="valblack";}}
	if($mtimeh=="01.01.1970"){$mtimeh="N/A";$clh2="valfiol";if($mtimeb!="N/A"){$clb2="valblack";}}
	return (eval("\$$clh"),$ch,eval("\$$clb"),$cb,eval("\$$clh2"),$mtimeh,eval("\$$clb2"),$mtimeb);
}
sub backupBackup{
	$backupstat->set_text(">: Backup ... ");
	$fd=$file_dialog->get_filename();
	system "rm -rf $fd/* & cp -r . $fd";
	$backupstat->set_text($backupstat->get_text." OK");
	system 'notify-send -i gnome-terminal "Резервное копирование завершено !!!"';
}
sub backupBuild{
	foreach $str(@list){
		($conttype,$path,$backupPath)=split("	",$str);
		$path=decode("utf8",$path);
		$backupPath=decode("utf8",$backupPath);
		$but=Gtk2::Button->new;
		eval "\$but->signal_connect(\"clicked\"=>sub{\$select=\"$path\";\$selectToBackup=\"$backupPath\";\$type=\"$conttype\";if(\$mode){\$butbackupgohome->show;\$butbackupgobackup->show;}\$backupstat->set_text(\">: Selected: [\$type->\$select]   \");});";
		$but->set_relief("none");
		$tablekont->pack_start($but,0,1,0);
		$butvbox=Gtk2::VBox->new;
			$hbox=Gtk2::HBox->new;
			$hbox->pack_start(Gtk2::Label->new($path),0,0,0);
			$hbox->add(Gtk2::HSeparator->new);
		$butvbox->pack_start($hbox,0,1,0);
			$table=Gtk2::Table->new(1,7,FALSE);
			$table->set_homogeneous(1);
			eval "\$labelhe$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelbe$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelhe$i->set_alignment(0,0.5);";
			eval "\$labelbe$i->set_alignment(0,0.5);";
			$table->attach_defaults(eval "\$labelhe$i",0,1,0,1);
			$table->attach_defaults(eval "\$labelbe$i",4,5,0,1);
			eval "\$labelhs$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelbs$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelhs$i->set_alignment(0,0.5);";
			eval "\$labelbs$i->set_alignment(0,0.5);";
			$table->attach_defaults(eval "\$labelhs$i",1,2,0,1);
			$table->attach_defaults(eval "\$labelbs$i",5,6,0,1);
			eval "\$labelhd$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelbd$i=Gtk2::Label->new(\"$i\");";
			eval "\$labelhd$i->set_alignment(0,0.5);";
			eval "\$labelbd$i->set_alignment(0,0.5);";
			$table->attach_defaults(eval "\$labelhd$i",2,3,0,1);
			$table->attach_defaults(eval "\$labelbd$i",6,7,0,1);
			$table->attach_defaults(Gtk2::VSeparator->new,3,4,0,1);
		$butvbox->pack_start($table,0,1,0);
	$but->add($butvbox);
	$i++;
	}
}
sub backupEx{
	$path=$select;
	$path=~s/~/$home/eg;
	if($type eq "ARJ"){
		if(-d "$path" or -f "$path"){system "rm -r $path";}
		@tmp=split("/",$path);
		pop @tmp;
		$path=join("/",@tmp);
		cmd("7z x $backup/$selectToBackup.7z -o$path");
	}
	if($type eq "FILE"){
		if(-f "$path"){system "rm $path";}
		cmd("cp -v $backup/$selectToBackup $path");
	}
	if($type eq "DIR"){
		if(-d "$path"){system "rm -r $path/*";}
		cmd("cp -r -v --parents $backup/$selectToBackup $path");
	}
}
sub backupBack{
	$path=$select;
	$path=~s/~/$home/eg;
	if($type eq "ARJ"){
		if(-f "$backup/$selectToBackup.7z"){unlink "$backup/$selectToBackup.7z";}
		cmd("7z a -mx=$backuppack $backup/$selectToBackup.7z $path");
	}
	if($type eq "FILE"){
		if(-f "$backup/$selectToBackup"){unlink "$backup/$selectToBackup";}
		cmd("cp -v --parents $path $backup/$selectToBackup");
	}
	if($type eq "DIR"){
		if(-d "$backup/$selectToBackup"){system "rm -r $backup/$selectToBackup/*";}
		if(!-d "$backup/$selectToBackup"){
			cmd("mkdir -p $backup/$selectToBackup");
		}
		cmd("cp -r -v $path/* $backup/$selectToBackup");
	}
}
sub backupUPD{
	$backup="N/A";
	$mode=0;
	if(!-d $backupdir){cmd($backupDirOpenCommand);}
	if(-d $backupdir){$backup=$backupdir;$mode=1;}
	$butbackupgohome->hide;
	$butbackupgobackup->hide;
	getFreeSpaceHDD($home,$hfreebar);
	if($mode){
		getFreeSpaceHDD($backup,$bfreebar);
	}else{
		$bfreebar->set_fraction(0);
		$bfreebar->set_text("N/A");
	}
	$i=0;
	foreach $str(@list){
		($conttype,$path,$backupPath)=split("	",$str);
		$path=decode("utf8",$path);
		$backupstat->set_text(">: Searching:  [$conttype->$path] ... ");Gtk2->main_iteration while Gtk2->events_pending;
		($colh,$filesh,$colb,$filesb,$rb)=getElem($conttype,$path,$backupPath);
		eval "\$labelhe$i->set_markup(\"<span color='$colh'>$filesh</span>\");";
		eval "\$labelbe$i->set_markup(\"<span color='$colb'>$filesb</span>\");";
		eval "\$labelhe$i->set_tooltip_text(\"$rb\");";
		eval "\$labelbe$i->set_tooltip_text(\"$rb\");";
		($colh,$sizeh,$colb,$sizeb,$colh2,$mtimeh,$colb2,$mtimeb)=getSizeStr($conttype,$path,$backupPath);
		eval "\$labelhs$i->set_markup(\"<span color='$colh'>$sizeh</span>\");";
		eval "\$labelbs$i->set_markup(\"<span color='$colb'>$sizeb</span>\");";
		eval "\$labelhs$i->set_tooltip_text(\"$rb\");";
		eval "\$labelbs$i->set_tooltip_text(\"$rb\");";

		eval "\$labelhd$i->set_markup(\"<span color='$colh2'>$mtimeh</span>\");";
		eval "\$labelbd$i->set_markup(\"<span color='$colb2'>$mtimeb</span>\");";
		eval "\$labelhd$i->set_tooltip_text(\"$rb\");";
		eval "\$labelbd$i->set_tooltip_text(\"$rb\");";
#		print "[$conttype,$name]\n";
		$i++;
	}
	$backupstat->set_text($backupstat->get_text."OK");Gtk2->main_iteration while Gtk2->events_pending;
}
sub getFreeSpaceHDD{
	($dir,$bar)=@_;
	@tmp=`df -x devtmpfs -x tmpfs -B 1 2>/dev/null`;
	shift @tmp;
	$find=$prz=0;
	foreach $str(@tmp){
		($dev,$tot,$isp,$dost,$mpoint,$mpoint)=split(" ",$str);
		@tmp2=split("/",$dir);
		$count=@tmp2;
		while($count>0){
			$str=join "/",@tmp2;
			if($str eq ""){$str="/";}
			if($str eq $mpoint){
				#$prz2=int(($dost)/($tot/100));
				$prz=int($isp/($tot/100));
				$prz2=100-$prz;
				$dost=getSize($dost);
				$tot=getSize($tot);
				$prz/=100;
				$bar->set_fraction($prz);
				$bar->set_text("[$dir] -> Free: $dost / $tot [$prz2%]");
				$find=1;
				break;
			}
			pop @tmp2;
			$count=@tmp2;
		}
		if($find eq 1){break;}
	}
}
sub cmd{$cmd=shift @_;system "$term '$cmd'";}
