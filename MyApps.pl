#!/usr/bin/perl
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
# Please see COPYING for details
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
use utf8;
use Encode;
use Gtk2 '-init';
$SIG{CHLD}="IGNORE";
$tmp=`mouse`;
($tmp,$tmp,$x,$y)=split(" ",$tmp);
# парсинг аргументов
if($ARGV[0] ne ""){$x=$ARGV[0];}
if($ARGV[1] ne ""){$y=$ARGV[1];}
# Запускатор
$menu=Gtk2::Menu->new;
getCat("$ENV{HOME}/bin",$menu);
# Конец меню
$menu->show_all;
$menu->popup( undef, undef, sub{return ($x,$y,0)}, undef, 0, 0);
# Устанавливаем обработчики
$menu->signal_connect("hide" => sub{Gtk2->main_quit;});
Gtk2->main;
##########
sub getFiles{
	$uri=shift @_;
	if(-d $uri){
		foreach $pos(glob("$uri/*")){
			if(-f $pos){if(-x $pos){push @files,$pos;}}
			if(-d $pos){getFiles($pos);}
		}
	}
}
sub getCat{
	$url=shift @_;
	$m=shift @_;
	$p=shift @_;
	if(-d $url){
		foreach $str(glob("$url/*")){
			@tmp=split("/",$str);
			$name=pop @tmp;
			$name=decode('utf8',$name);
			if(-f $str and -x $str){
				$item=Gtk2::ImageMenuItem->new_with_label("$name");
				$item->set_image(Gtk2::Image->new_from_stock("gtk-execute","menu"));
					$men2=Gtk2::Menu->new;
						$item2=Gtk2::ImageMenuItem->new_with_label("Запустить");
						eval "\$item2->signal_connect('activate'=>sub{if(fork==0){exec \"$str\";}exit;});";
						$men2->append($item2);
						$item2=Gtk2::ImageMenuItem->new_with_label("В терминале");
						eval "\$item2->signal_connect('activate'=>sub{if(fork==0){exec \"xterm -e '$str'\";}exit;});";
						$men2->append($item2);
				$item->set_submenu($men2);
				$m->append($item);
			}
			if(-d $str){
				@files=();
				getFiles($str);
				$c=@files;
				#print "[$str][$c]\n";
			}
			if(-d $str and $c>0){
				$item=Gtk2::ImageMenuItem->new_with_label("$name");
				$item->set_image(Gtk2::Image->new_from_stock("gtk-directory","menu"));
				$men=Gtk2::Menu->new;
				eval "\$men->signal_connect(show=>sub{
					\$elem=shift \@_;
					getCat(\"$str\",\$elem,\$item);
					\$elem->show_all;
				});";
				eval "\$men->signal_connect(hide=>sub{
					\$elem=shift \@_;
					\$tmp=\$elem->get_children;
					while(\$tmp ne undef){
						Gtk2::Container::remove(\$elem,\$tmp);
						\$tmp=\$elem->get_children;
					}
				});";
				$item->set_submenu($men);
				$m->append($item);
				$m->show_all;
			}
		}
	}
}
