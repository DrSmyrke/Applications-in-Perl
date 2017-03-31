#!/usr/bin/perl
# application based on DrSmyrke
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
use utf8;
use Encode;
use Gtk2 '-init';
$SIG{CHLD}="IGNORE";
# определение разрешения монитора
#$cmd=`xrandr | grep "*"`;
#($t1)=split(" ",$cmd);
#($widthmon,$heightmon)=split("x",$t1);
$tmp=`mouse`;
($tmp,$tmp,$x,$y)=split(" ",$tmp);
# Пути
$hico="/home/drsmyrke/.icons/MyTheme";
$sico="/usr/share/icons/gnome/24x24";
# парсинг аргументов
if($ARGV[0] ne ""){$x=$ARGV[0];}
if($ARGV[1] ne ""){$y=$ARGV[1];}
# Определение данных
%cat=("Game"=>"Игры","AudioVideo"=>"Видео и Аудио","Graphics"=>"Графика",
"System"=>"Система","Office"=>"Офис","Network"=>"Сеть","Settings"=>"Настройки",
"Other"=>"Разное","Development"=>"Разработка","Utility"=>"Утилиты");
open fs,"</usr/share/applications/desktop.ru_RU.utf8.cache";@deskinf=<fs>;close fs;
$deskinf=join("",@deskinf);
@deskinf=split("\n\n",$deskinf);
# Генерация списка программ
$i=0;
foreach $tmp(@deskinf){
	@dt=split("\n",$tmp);
	if($dt[0]=~/screensavers\//){next;}
	$cmd=$category=$name=$title=$ico="";
	foreach $tmp(@dt){
		chomp $tmp;
		($nam,$val)=split("=",$tmp);
		if($nam eq "Name"and $name eq ""){$name=$val;}
		if($nam eq "GenericName" and $title eq ""){$title=$val;}
		if($nam eq "Comment" and $title eq ""){$title=$val;}
		if($nam eq "Exec" and $cmd eq ""){$cmd=$val;}
		if($nam eq "Icon" and $ico eq ""){$ico=$val;}
		if($nam eq "Categories"){
			@data=split(";",$val);
			foreach $nam(@data){
				foreach $val (keys %cat){
					if($val eq $nam){$category=$nam;break;}
				}
				if($category ne ""){break;}
			}
			if($category eq ""){$category="Other";}
		}
		if($cmd ne "" and $name ne "" and $category ne ""){break;}
	}
	$cmd=~s/ \%u//g;
	$cmd=~s/ \%U//g;
	$cmd=~s/ \%f//g;
	$cmd=~s/ \%F//g;
	@apps[$i]="$cmd===$category===$name===$title===$ico";
	$i++;
}
# Очистка переменных
$tmp=@deskinf=$nam=$val=$cmd=$category=$name=$title=$ico="";
#foreach $cat (keys %cat){
#print "[$cat/$opis]\n";
#}
#foreach $cat (values %cat){
#print "[$cat/$opis]\n";
#}
#print "[".$cat{'System'}."]";
# Генерируем главное меню
$menu=Gtk2::Menu->new;
foreach $val (keys %cat){
	$title=$cat{"$val"};
	$menuitem=Gtk2::ImageMenuItem->new_with_label($title);
	$menuitem->set_image(Gtk2::Image->new_from_stock("gtk-directory","menu"));
	# Генерация субменю
	$subm=0;
	foreach $tmp(@apps){
		if($subm eq 0){$m=Gtk2::Menu->new;$subm=1;}
		($cmd,$category,$name,$title,$icon)=split("===",$tmp);
		if($category ne $val){next;}
		if($icon=~/\//){$cm=$icon;}else{
			$cm="";
			if(-f "/usr/share/pixmaps/$icon"){$cm="/usr/share/pixmaps/$icon";}
			if(-f "/usr/share/pixmaps/$icon.xpm"){$cm="/usr/share/pixmaps/$icon.xpm";}
			if(-f "/usr/share/pixmaps/$icon.png"){$cm="/usr/share/pixmaps/$icon.png";}
			if(-f "/usr/share/pixmaps/$icon.svg"){$cm="/usr/share/pixmaps/$icon.svg";}
		}
		if($cm eq ""){$add="\$menuitem$i->set_image(Gtk2::Image->new_from_stock(\"gtk-execute\",\"menu\"));";}else{$add="\$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,'$cm');\$pix{close}=\$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');\$menuitem$i->set_image(Gtk2::Image->new_from_pixbuf(\$pix{close}));";}
		eval "\$menuitem$i=Gtk2::ImageMenuItem->new_with_label('$name');$add\$menuitem$i->set_tooltip_text('$title [$cmd]');\$menuitem$i->signal_connect('activate' => sub{if(fork==0){exec '$cmd';}});\$m->append(\$menuitem$i);\$menuitem$i->show;";
		if($subm eq 1){$m->show;$menuitem->set_submenu($m);}
	}
	$menu->append($menuitem);
	$menuitem->show;
}
# Сепаратор
$menuitem=Gtk2::SeparatorMenuItem->new;
$menu->append($menuitem);
$menuitem->show;
# Места
$menuitem=Gtk2::ImageMenuItem->new_with_label("Места");
	$m=Gtk2::Menu->new;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("SHARE");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus ~/SHARE";});
	$menuitem1->show;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("Компьютер");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus computer:";});
	$menuitem1->show;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("Сеть");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus network:";});
	$menuitem1->show;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("HOME");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus ~";});
	$menuitem1->show;
	# Сепаратор
	$tmp=Gtk2::SeparatorMenuItem->new;
	$m->append($tmp);
	$tmp->show;
	# END Сепаратор
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("ftp:Smyrke2005.narod2.ru");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus ftp://smyrke2005.ftp.narod.ru/";});
	$menuitem1->show;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("ssh:10.42.43.42");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus sftp://10.42.43.42/";});
	$menuitem1->show;
	$menuitem1=Gtk2::ImageMenuItem->new_with_label("ssh:192.168.1.16");
	$m->append($menuitem1);
	$menuitem1->signal_connect('activate' => sub{system "nautilus sftp://192.168.1.16/";});
	$menuitem1->show;
	# Сепаратор
	$tmp=Gtk2::SeparatorMenuItem->new;
	$m->append($tmp);
	$tmp->show;
	# Меню
	$menuitem2=Gtk2::ImageMenuItem->new_with_label("Соединение с сервером");
	$m->append($menuitem2);
	$menuitem2->signal_connect('activate' => sub{system "nautilus-connect-server";});
	$menuitem2->show;
	$m->show;
	$menuitem->set_submenu($m);
$menu->append($menuitem);
$menuitem->show;
# Центр управления
$menuitem=Gtk2::ImageMenuItem->new_with_label("Центр управления");
	$ico="gnome-control-center";$cat="categories";
	if(-f "$hico/$cat/$ico.svg"){$fileico="$hico/$cat/$ico.svg";}else{$fileico="$sico/$cat/$ico.png";}
	$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,$fileico);
	$pix{close}=$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
	$menuitem->set_image(Gtk2::Image->new_from_pixbuf($pix{close}));
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "gnome-control-center";});
$menuitem->show;
# Терминал
$menuitem=Gtk2::ImageMenuItem->new_with_label("Терминал");
	$ico="utilities-terminal";$cat="apps";
	if(-f "$hico/$cat/$ico.svg"){$fileico="$hico/$cat/$ico.svg";}else{$fileico="$sico/$cat/$ico.png";}
	$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,$fileico);
	$pix{close}=$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
	$menuitem->set_image(Gtk2::Image->new_from_pixbuf($pix{close}));
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "gnome-terminal";});
$menuitem->show;
# Календарь
$menuitem=Gtk2::ImageMenuItem->new_with_label("Календарь");
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "zenity --calendar";});
$menuitem->show;
# Сепаратор
$menuitem=Gtk2::SeparatorMenuItem->new;
$menu->append($menuitem);
$menuitem->show;
# Блокировка системы
$menuitem=Gtk2::ImageMenuItem->new_with_label("Заблокировать");
	$ico="system-lock-screen";$cat="actions";
	if(-f "$hico/$cat/$ico.svg"){$fileico="$hico/$cat/$ico.svg";}else{$fileico="$sico/$cat/$ico.png";}
	$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,$fileico);
	$pix{close}=$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
	$menuitem->set_image(Gtk2::Image->new_from_pixbuf($pix{close}));
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "xdg-screensaver lock";});
$menuitem->show;
# Выход из системы
$menuitem=Gtk2::ImageMenuItem->new_with_label("Выйти");
	$ico="system-log-out";$cat="actions";
	if(-f "$hico/$cat/$ico.svg"){$fileico="$hico/$cat/$ico.svg";}else{$fileico="$sico/$cat/$ico.png";}
	$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,$fileico);
	$pix{close}=$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
	$menuitem->set_image(Gtk2::Image->new_from_pixbuf($pix{close}));
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "gnome-session-save --logout-dialog";});
$menuitem->show;
# Выключение
$menuitem=Gtk2::ImageMenuItem->new_with_label("Выключить...");
	$ico="application-exit";$cat="actions";
	if(-f "$hico/$cat/$ico.svg"){$fileico="$hico/$cat/$ico.svg";}else{$fileico="$sico/$cat/$ico.png";}
	$pix{close}=Gtk2::Gdk::Pixbuf::new_from_file(undef,$fileico);
	$pix{close}=$pix{close}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
	$menuitem->set_image(Gtk2::Image->new_from_pixbuf($pix{close}));
$menu->append($menuitem);
$menuitem->signal_connect('activate' => sub{system "gnome-session-save --shutdown-dialog";});
$menuitem->show;
# Конец меню
$menu->show;
$menu->popup( undef, undef, sub{return ($x,$y,0)}, undef, 0, 0);
# Устанавливаем обработчики
$menu->signal_connect("hide" => sub{Gtk2->main_quit;});
Gtk2->main;
