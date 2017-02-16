#!/usr/bin/perl -w
# confirm, based on DrSmyrke
#
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
# Версия программы 1.0
use Gtk2 '-init';
use Cairo;
use utf8;
use Encode;
##################################
#				Начальные параметры			      #
##################################
$string=join " ",@ARGV;
$string=decode('utf8',$string);
$win=Gtk2::Window->new('popup');
$win->set_position("GTK_WIN_POS_CENTER_ALWAYS");
$win->set_decorated(0);					# Рамка окна
$win->set_resizable(1);						# Изменение размера окна
$winwidth=400;							# Ширина окна
$winheight=130;							# Высота окна
$win->set_app_paintable('TRUE');			# Отрисовка окна приложением
$winupdtime=0.05;						# Частота обновления окна в секундах
$contenttextcolor="255:175:0";				# Цвет текста контента (R:G:B)
$valtextcolor="138:186:56";				# Цвет текста значений (R:G:B)
$smech=0;
#Преобразование цветов
($r,$g,$b)=split(":",$contenttextcolor);if($r ne 0){$rt=$r/2.55;$rt/=100;}else{$rt=0;}if($g ne 0){$gt=$g/2.55;$gt/=100;}else{$gt=0;}if($b ne 0){$bt=$b/2.55;$bt/=100;}else{$bt=0;}$rt=~s/,/./g;$gt=~s/,/./g;$bt=~s/,/./g;($r,$g,$b)=split(":",$valtextcolor);if($r ne 0){$rv=$r/2.55;$rv/=100;}else{$rv=0;}if($g ne 0){$gv=$g/2.55;$gv/=100;}else{$gv=0;}if($b ne 0){$bv=$b/2.55;$bv/=100;}else{$bv=0;}$rv=~s/,/./g;$gv=~s/,/./g;$bv=~s/,/./g;
##################################
#				отрисовка окна					      #
##################################
$win->set_default_size($winwidth,$winheight);
screen_changed($win);
$win->show_all();
# обработка сигналов
$win->signal_connect("delete_event"=>sub{Gtk2->main_quit;});
$win->signal_connect("destroy"=>sub{Gtk2->main_quit;});
$win->signal_connect("enter-notify-event"=>sub{});
$win->signal_connect("leave-notify-event"=>sub{});
$win->signal_connect('screen_changed', \&screen_changed, $win);
#Gtk2->main;
use Time::HiRes;
$time1=Time::HiRes::time;
$time1+=$winupdtime;
while(1){
	select(undef,undef,undef,0.001);
	$time2=Time::HiRes::time;
	if($time2>$time1){
		(undef,$mx,$my,$mstate)=$win->window->get_pointer;
#		($winwidth,$winheight)=$win->get_size;
#		print "$mx,$my,$mstate \n";
		expose($win);
		Gtk2->main_iteration while Gtk2->events_pending;
		$time1=Time::HiRes::time;
		$time1+=$winupdtime;
	}
}
##################################
#				отрисовка рамки					      #
##################################
sub getRamka{($x,$y)=@_;$cr->set_source_rgba(0.9,0.9,0.9,0.8);$cr->move_to($x,$y);$cr->line_to($x,$y+55);$cr->move_to($x,$y+55);$cr->line_to($winwidth-10,$y+55);$cr->move_to($winwidth-10,$y+55);$cr->line_to($winwidth-10,$y);$cr->move_to($winwidth-10,$y);$cr->line_to($x+70,$y);$cr->move_to($x+20,$y);$cr->line_to($x,$y);$cr->stroke();}
##################################
#				отрисовка фона					      #
##################################
sub screen_changed{($widget)=@_;$tmp=$widget->get_screen();$tmp2=$tmp->get_rgba_colormap();if(!$tmp2){$print="Ваш экран НЕ поддерживает альфа канал\n";$supports_alpha=0;$tmp2=$tmp->get_rgb_colormap();}else{$supports_alpha=1;$print="Ваш экран поддерживает альфа канал\n";}$widget->set_colormap($tmp2);$widget=$tmp2=$tmp=undef;}
##################################
#			отрисовка контента					      #
##################################
sub expose{
($widget)=@_;
$cr=Gtk2::Gdk::Cairo::Context->create($widget->window());
if($supports_alpha){
	$cr->set_source_rgba(1.0,1.0,1.0,0.0);
}else{
	$cr->set_source_rgb(1.0,1.0,1.0);
}
$cr->set_operator('source');
$cr->paint();
$cr->set_source_rgba(1.0,0.2,0.2,0.6);
$cr->fill();
#вывод фона
$cr=Gtk2::Gdk::Cairo::Context->create($widget->window());
$cr->set_source_rgba(0,0,0,0.9);
$cr->rectangle(0,0,$winwidth,$winheight);
$cr->fill();
$cr->stroke();



if($mstate=~/control-mask/){
	$tmp="";
	$time=237;
	if($mstate=~/button3-mask/){
		$tmp="+B3";
		$time=265;
	}
	if($mstate=~/button1-mask/){
		$tmp="+B1";
		$time=265;
	}
	$cr->set_source_rgba(255,0,0,0.6);
	$cr->move_to(160,20);
	$cr->show_text("CONTROL$tmp");
	$posy=$winheight-40;
	$time=80;
	$cr->move_to(35,$posy-20);$cr->line_to(35,$posy+5);
	$cr->move_to(35,$posy+5);$cr->line_to($time,$posy+5);
	$cr->move_to($time,$posy+5);$cr->line_to($time,$posy-20);
	$cr->move_to($time,$posy-20);$cr->line_to(35,$posy-20);
	$cr->stroke();
}
$cr=Gtk2::Gdk::Cairo::Context->create($widget->window());
$cr->set_source_rgba(0.3,0.7,0.2,0.5);
$cr->set_line_width(15);
for($i=-40;$i<$winwidth;$i+=40){$cr->move_to($i+$smech,-10);$cr->line_to($i+30+$smech,20);}
for($i=40;$i<$winwidth+40;$i+=40){$cr->move_to($i-$smech,$winheight-20);$cr->line_to($i+30-$smech,$winheight+10);}
for($i=20;$i<$winheight+10;$i+=40){$cr->move_to(-10,$i-$smech);$cr->line_to(20,$i+30-$smech);}
for($i=-30;$i<$winheight+10;$i+=40){$cr->move_to($winwidth-20,$i+$smech);$cr->line_to($winwidth+10,$i+30+$smech);}
if($smech eq 40){$smech=0;}else{$smech++;}
$cr->stroke();
$cr->select_font_face("Play","normal","bold");$cr->set_font_size(15);
$cr->move_to(40,50);$cr->set_source_rgb($rt,$gt,$bt);$cr->show_text("$string");
$cr->select_font_face("Arial","normal","normal");$cr->set_font_size(20);
$cr->move_to(40,$winheight-40);$cr->set_source_rgb($rv,$gv,$bv);$cr->show_text("OK");
$cr->stroke();
if($mx>40 && $mx<70 && $my>$winheight-60 && $my<$winheight-30){
	$cr->set_line_width(2);
	$posy=$winheight-40;
	$time=80;
	$cr->move_to(35,$posy-20);$cr->line_to(35,$posy+5);
	$cr->move_to(35,$posy+5);$cr->line_to($time,$posy+5);
	$cr->move_to($time,$posy+5);$cr->line_to($time,$posy-20);
	$cr->move_to($time,$posy-20);$cr->line_to(35,$posy-20);
	$cr->stroke();
	if($mstate=~/button1-mask/){print "true";exit;}
}
$cr->move_to(90,$winheight-40);$cr->set_source_rgb($rv,$gv,$bv);$cr->show_text("Отмена");
if($mx>90 && $mx<170 && $my>$winheight-60 && $my<$winheight-30){
	$cr->set_line_width(2);
	$posy=$winheight-40;
	$time=170;
	$cr->move_to(85,$posy-20);$cr->line_to(85,$posy+5);
	$cr->move_to(85,$posy+5);$cr->line_to($time,$posy+5);
	$cr->move_to($time,$posy+5);$cr->line_to($time,$posy-20);
	$cr->move_to($time,$posy-20);$cr->line_to(85,$posy-20);
	$cr->stroke();
	if($mstate=~/button1-mask/){print "false";exit;}
}

$cr->stroke();
}
