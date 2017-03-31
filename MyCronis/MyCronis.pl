#!/usr/bin/perl
# MYCRONIS, a backup app based on DrSmyrke
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
#if(!-f "$pwd/backup.dat"){
#	print "Списка данных для синхронизации не обнаружено!!!\n";
#	exit;
#}
$nazist="N/A";
$disk="N/A";
$part="N/A";
$obraz="N/A";
$user="N/A";
$method="N/A";
require "$pwd/config";
open fs,"</etc/passwd";@tmp=<fs>;close fs;chomp @tmp;
foreach $str(@tmp){
	($name,$tmp,$id)=split(":",$str);
	if($id eq $<){$user=$name;last;}
}
if(-f "$ENV{HOME}/bin/data/libs/size.pl"){
	require "$ENV{HOME}/bin/data/libs/size.pl";
}else{
	if(-f "$pwd/libs/size.pl"){
		require "$pwd/libs/size.pl";
	}else{
		print "lib SIZE not found\n";
		die;
	}
}
############ Инициализация ###############
use Gtk2 '-init';
use utf8;
# меню типов сжатия данных
$typemenu=Gtk2::Menu->new;
	$menuitem=Gtk2::ImageMenuItem->new_with_label("7z");
	$menuitem->signal_connect(activate=>sub{$method="7z";upd();});
	$typemenu->append($menuitem);
	$menuitem=Gtk2::ImageMenuItem->new_with_label("gZip");
	$menuitem->signal_connect(activate=>sub{$method="gz";upd();});
	$typemenu->append($menuitem);
	$menuitem=Gtk2::ImageMenuItem->new_with_label("Tar + gZip");
	$menuitem->signal_connect(activate=>sub{$method="tgz";upd();});
	$typemenu->append($menuitem);
	$menuitem=Gtk2::ImageMenuItem->new_with_label("Tar + Lzma");
	$menuitem->signal_connect(activate=>sub{$method="tlz";upd();});
	$typemenu->append($menuitem);
	$menuitem=Gtk2::ImageMenuItem->new_with_label("cpio");
	$menuitem->signal_connect(activate=>sub{$method="cpio";upd();});
	$typemenu->append($menuitem);
	$menuitem=Gtk2::ImageMenuItem->new_with_label("initramfs");
	$menuitem->signal_connect(activate=>sub{$method="initramfs";upd();});
	$typemenu->append($menuitem);
$typemenu->show_all;
# создаем главное окно
$main=Gtk2::Window->new('toplevel');
$main->set_title("MyCronis v1.0");
$main->set_default_size("650","480");
$main->set_position("GTK_WIN_POS_CENTER_ALWAYS");
$main->set_resizable(1);
# Обрабочики сигналов окна
$main->signal_connect("destroy"=>sub{Gtk2->main_quit;});
# Построение окна
$vbox=Gtk2::VBox->new;
	$hbox=Gtk2::HBox->new;
		$hbox->pack_start(Gtk2::Label->new("   Пользователь:"),0,1,0);
		$disklabel=Gtk2::Label->new;
		$val=($user eq "root")?$valgreen:$valfiol;
		$disklabel->set_markup("[<span color=\"$val\">$user</span>]");
		$disklabel->set_alignment(0,0.5);
	$hbox->pack_start($disklabel,0,0,0);
		$hbox->pack_start(Gtk2::Label->new("   Диск:"),0,1,0);
		$disklabel=Gtk2::Label->new;
		$disklabel->set_markup("[<span color=\"$valna\">$disk</span>]");
		$disklabel->set_alignment(0,0.5);
	$hbox->pack_start($disklabel,0,0,0);
		$hbox->pack_start(Gtk2::Label->new("   Раздел:"),0,1,0);
		$partlabel=Gtk2::Label->new;
		$partlabel->set_markup("[<span color=\"$valna\">$part</span>]");
		$partlabel->set_alignment(0,0.5);
	$hbox->pack_start($partlabel,0,0,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,0,0);
		$butinstallupd=Gtk2::Button->new;
		$butinstallupd->set_image(Gtk2::Image->new_from_stock("gtk-refresh",button));
		$butinstallupd->signal_connect(clicked=>sub{InstallerUPD();});
	$hbox->pack_start($butinstallupd,0,0,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,0,0);
		$butgeparted=Gtk2::Button->new("GPARTED");
		$butgeparted->signal_connect(clicked=>sub{cmd("sudo gparted");});
	$hbox->pack_start($butgeparted,0,0,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
		$hbox->pack_start(Gtk2::Label->new("   Назначение:"),0,1,0);
		$istlabel=Gtk2::Label->new;
		$istlabel->set_markup("[<span color=\"$valna\">$nazist</span>]");
		$istlabel->set_alignment(0,0.5);
	$hbox->pack_start($istlabel,0,0,0);
		$bvist=Gtk2::Button->new("Выбрать");
		$bvist->signal_connect(clicked=>sub{
			#Инициализация всплывающего меню
			if(-f "$pwd/ist"){
				open fs,"<$pwd/ist";@ist=<fs>;close fs;chomp @ist;
				$istmenu=Gtk2::Menu->new;
				foreach $str(@ist){
					$menuitem=Gtk2::ImageMenuItem->new_with_label($str);
					$menuitem->set_image(Gtk2::Image->new_from_stock("gtk-directory","menu"));
					$menuitem->set_tooltip_text("$str");
					$menuitem->signal_connect(activate=>sub{
						$elem=shift @_;
						$nazist=$elem->get_tooltip_text;
						upd();
					});
					$istmenu->append($menuitem);
				}
				$istmenu->append(Gtk2::SeparatorMenuItem->new);
				$menuitem=Gtk2::ImageMenuItem->new_with_label("Выбрать каталог");
				$menuitem->set_image(Gtk2::Image->new_from_stock("gtk-open","menu"));
				$menuitem->signal_connect(activate=>sub{
					$fd=Gtk2::FileChooserDialog->new("Выбор назначения",undef,"select-folder","gtk-ok","close");
					$fd->set_current_folder("/");
					$fd->signal_connect(response=>sub{
						$istname->set_text($fd->get_filename);
						$fd->destroy;
					});
					$fd->set_select_multiple(0);
					$fd->run;
				});
				$istmenu->append($menuitem);
				$istmenu->show_all;
				(undef,$mx,$my)=$main->window->get_pointer;
				($x,$y)=$main->get_position;
				$x+=$mx;
				$y+=$my;
				$istmenu->popup(undef,undef,sub{return($x+10,$y+40,0)},undef,0,0);
			}
		});
	$hbox->pack_start($bvist,0,0,0);
		$istname=Gtk2::Entry->new;
	$hbox->pack_start($istname,1,1,0);
		$bdist=Gtk2::Button->new("Добавить");
		$bdist->signal_connect(clicked=>sub{
			open fs,">>$pwd/ist";print fs $istname->get_text."\n";close fs;
			$istname->set_text("");
		});
	$hbox->pack_start($bdist,0,0,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,0,0);
		$buist=Gtk2::Button->new("Удалить");
		$buist->signal_connect(clicked=>sub{
			if($nazist ne "N/A"){
				open fs,"<$pwd/ist";@ist=<fs>;close fs;chomp @ist;
				$i=0;
				foreach $str(@ist){
					if($nazist eq $str){delete $ist[$i];last;}
					$i++;
				}
				$nazist="N/A";
				$ist=join("\n",@ist);
				$ist=~s/\n\n/\n/g;
				open fs,">$pwd/ist";print fs $ist;close fs;
				upd();
			}
		});
	$hbox->pack_start($buist,0,0,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
		$hbox->pack_start(Gtk2::Label->new("   Образ:"),0,1,0);
		$obrlabel=Gtk2::Label->new;
		$obrlabel->set_markup("[<span color=\"$valna\">$obraz</span>]");
		$obrlabel->set_alignment(0,0.5);
	$hbox->pack_start($obrlabel,0,0,0);
		$bvobr=Gtk2::Button->new("Выбрать");
		$bvobr->signal_connect(clicked=>sub{getObraz();});
	$hbox->pack_start($bvobr,0,0,0);
	$hbox->pack_start(Gtk2::Label->new("   Новый образ:"),0,1,0);
		$obrname=Gtk2::Entry->new;
	$hbox->pack_start($obrname,1,1,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,0,0);
		$buobr=Gtk2::Button->new("Удалить");
		$buobr->signal_connect(clicked=>sub{
			cmd("notify-send \"Пока не работает!!!\"");
		});
	$hbox->pack_start($buobr,0,0,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
		$hbox->pack_start(Gtk2::Label->new("   Метод сжатия данных:"),0,1,0);
		$methodlabel=Gtk2::Label->new;
		$methodlabel->set_markup("[<span color=\"$valna\">$method</span>]");
		$methodlabel->set_alignment(0,0.5);
	$hbox->pack_start($methodlabel,0,0,0);
		$bvmethod=Gtk2::Button->new("Выбрать");
		$bvmethod->signal_connect(clicked=>sub{
			(undef,$mx,$my)=$main->window->get_pointer;
			($x,$y)=$main->get_position;
			$x+=$mx;
			$y+=$my;
			$typemenu->popup(undef,undef,sub{return($x+10,$y+40,0)},undef,0,0);
		});
	$hbox->pack_start($bvmethod,0,0,0);
		$hbox->pack_start(Gtk2::Label->new("   Степень сжатия данных:"),0,1,0);
		$packlevellabel=Gtk2::Label->new;
		$packlevellabel->set_markup("[<span color=\"$valgreen\">$packlevel</span>]");
		$packlevellabel->set_alignment(0,0.5);
	$hbox->pack_start($packlevellabel,0,0,0);
$vbox->pack_start($hbox,0,1,0);
$vbox->pack_start(Gtk2::HSeparator->new,0,1,0);
	$vboxtemp=Gtk2::VBox->new;
		$viewkont=Gtk2::VBox->new;
			$labelstat=Gtk2::Label->new("no data");
		$viewkont->add($labelstat);
	$vboxtemp->add($viewkont);
$vbox->add($vboxtemp);
$vbox->pack_start(Gtk2::HSeparator->new,0,1,0);
	$hbox=Gtk2::HBox->new;
		$bsmbr=Gtk2::Button->new("Сохранить MBR");
		$bsmbr->signal_connect(clicked=>sub{
			$image=($obraz eq "N/A")?"noname.mbr":$obraz;
			if($obrname->get_text ne ""){$image=$obrname->get_text;}
			if($nazist ne "N/A"){
				($proto,$url)=split("://",$nazist);
				if(substr($proto,0,1) eq "/"){$url=$proto;$proto="root";}
				if($proto eq "root"){cmd("sudo $pwd/backupmbr $url $disk $image");}
				if($proto eq "smb"){
					cmd("$pwd/mount.smb mount $url $mountdir && sudo $pwd/backupmbr $mountdir $disk $image && $pwd/mount.smb umount $mountdir");
				}
			}
		});
	$hbox->pack_start($bsmbr,0,1,0);
		$brmbr=Gtk2::Button->new("Восстановить MBR");
		$brmbr->signal_connect(clicked=>sub{
			if($nazist ne "N/A" or $obraz eq "N/A"){
				$image=$obraz;
				($proto,$url)=split("://",$nazist);
				if(substr($proto,0,1) eq "/"){$url=$proto;$proto="root";}
				if($proto eq "root"){cmd("sudo $pwd/installmbr $url $disk $image");}
				if($proto eq "smb"){
					cmd("$pwd/mount.smb mount $url $mountdir && sudo $pwd/installmbr $mountdir $disk $image && $pwd/mount.smb umount $mountdir");
				}
			}
		});
	$hbox->pack_start($brmbr,0,1,0);
		$bsobr=Gtk2::Button->new("Сохранить Образ");
		$bsobr->signal_connect(clicked=>sub{});
	$hbox->pack_start($bsobr,0,1,0);
		$brobr=Gtk2::Button->new("Восстановить Образ");
		$brobr->signal_connect(clicked=>sub{});
	$hbox->pack_start($brobr,0,1,0);
$vbox->pack_start($hbox,0,1,0);
$main->add($vbox);
$main->show_all;
$bsmbr->hide;
$brmbr->hide;
$bsobr->hide;
$brobr->hide;
# инициализация
Gtk2->main;
############ Процедуры ###############
sub InstallerUPD{
	if($razdel eq ""){$razdel="N/A";}
	if($file eq ""){$file="N/A";}
	$viewkont->destroy;
	$viewkont=Gtk2::VBox->new;$vboxtemp->add($viewkont);
	@cmd=`xterm -e 'sudo fdisk -l | grep "/dev" > /tmp/tmp.log'`;
	open fs,"</tmp/tmp.log";@cmd=<fs>;close fs;
	chomp @cmd;
	foreach $str(@cmd){
		($val1,$val2,$val3,$size,$id,$sys)=split(" ",$str);
		($dev)=split(":",$val2);
		if($val2=~/dev/){
			$bhdd=Gtk2::Button->new;
			$bhdd->set_relief("none");
			$bhdd->set_tooltip_text($dev);
				$label=Gtk2::Label->new;
				$label->set_markup("<b>HDD: </b><span color=\"$valfiol\">$dev [".getSize($id)."]</span>");
				$label->set_alignment(0,0.5);
			$bhdd->add($label);
			$bhdd->signal_connect(clicked=>sub{
				$elem=shift @_;
				$disk=$elem->get_tooltip_text;
				upd();
			});
			$viewkont->pack_start($bhdd,0,1,0);
		}
		if($val1=~/dev/){
			if($val2 eq "*"){($val1,$val2,$val2,$val3,$size,$id,$sys)=split(" ",$str);}
			if($id eq 7){$id="NTFS";}
			if($id eq 83){$id="EXT4";}
			if($id eq 0){$id="NONE";}
			if($id eq 82){$id="SWAP";}
			$bpart=Gtk2::Button->new;
			$bpart->set_relief("none");
			$bpart->set_tooltip_text($val1);
				$label=Gtk2::Label->new;
				$label->set_markup("   <b>PART: </b>$val1   [".getSize($size*1000)."]   id:$id    system:$sys");
				$label->set_alignment(0,0.5);
			$bpart->add($label);
			$bpart->signal_connect(clicked=>sub{
				$elem=shift @_;
				$part=$elem->get_tooltip_text;
				$disk=substr($part,0,-1);
				upd();
			});
			$viewkont->pack_start($bpart,0,1,0);
		}
	}
	$viewkont->show_all();
}
sub cmd{$cmd=shift @_;system "$term '$cmd'";}
sub upd{
	if($disk ne "N/A"){
		$bsobr->show;
		$brobr->show;
		$bsmbr->show;
		$brmbr->show;
	}
	if($part ne "N/A"){
		$bsobr->show;
		$brobr->show;
	}
	$val=($disk eq "N/A")?$valna:$valgreen;
	$disklabel->set_markup("[<span color=\"$val\">$disk</span>]");
	$val=($part eq "N/A")?$valna:$valgreen;
	$partlabel->set_markup("[<span color=\"$val\">$part</span>]");
	$val=($nazist eq "N/A")?$valna:$valgreen;
	$istlabel->set_markup("[<span color=\"$val\">$nazist</span>]");
	$val=($obraz eq "N/A")?$valna:$valgreen;
	$obrlabel->set_markup("[<span color=\"$val\">$obraz</span>]");
	$val=($method eq "N/A")?$valna:$valgreen;
	$methodlabel->set_markup("[<span color=\"$val\">$method</span>]");
	$val=($method eq "7z")?$valgreen:$valna;
	$packlevellabel->set_markup("[<span color=\"$val\">$packlevel</span>]");
}
sub getObraz{
	($proto,$url)=split("://",$nazist);
	if(substr($proto,0,1) eq "/"){$url=$proto;$proto="root";}
	if($proto eq "root"){getFileDialog($url);}
	if($nazist eq "N/A"){getFileDialog("/");}
	if($proto eq "smb"){
		cmd("$pwd/mount.smb mount $url $mountdir");
		getFileDialog($mountdir,"smbumount");
	}
}
sub getFileDialog{
	$dir=shift @_;
	$cmd=shift @_;
	$fd=Gtk2::FileChooserDialog->new("Выбор образа",undef,"open");
	$fd->signal_connect(file_activated=>sub{
		$obraz=$fd->get_filename;
		@tmp=split("/",$fd->get_filename);
		$obraz=pop @tmp;
		if($nazist eq "N/A" or substr($nazist,0,1) eq "/"){$nazist=join("/",@tmp);}
		upd();
		if($cmd eq "smbumount"){cmd("$pwd/mount.smb umount $mountdir");}
		$fd->destroy;
	});
	$fd->set_select_multiple(0);
	$fd->set_current_folder($dir);
	$fd->run;
}
