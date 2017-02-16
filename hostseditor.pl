#!/usr/bin/perl
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
use Gtk2 '-init';
use Encode;
$title="HOSTSeditor";
$file="/etc/hosts";
open fs,"<$file";@fdata=<fs>;close fs;$fdata=join("",@fdata);
$fdata=decode("utf8",$fdata);
$mode=1;
if($< ne 0){$title.=" (Только для чтения)";$mode=0;} # проверка юзера
# создаем всплывающее окно
$main=Gtk2::Window->new('toplevel');
$main->set_title($title);
$main->set_position("GTK_WIN_POS_CENTER_ALWAYS");
$main->set_size_request(640,480);
$main->set_resizable(0);
####################
$vbox=Gtk2::VBox->new;
	$tmp=Gtk2::ScrolledWindow->new;
	$tmp->set_policy("automatic","automatic");
		$textbody=Gtk2::TextBuffer->new;
		$TextView=Gtk2::TextView->new;
			$TextView->set_buffer($textbody);
				$textbody->set_text("$fdata");
			$TextView->set_editable(1);
	$tmp->add($TextView);
$vbox->add($tmp);
	# Подсказка
	$hbox=Gtk2::HBox->new;
		$tmp=Gtk2::Label->new;
		$tmp->set_markup("<b>Пример блокировки домена:</b>");
		$tmp->set_alignment(0,0.5);
	$hbox->pack_start($tmp,0,1,0);
		$filepath0=Gtk2::Label->new("0.0.0.0	vk.com	# blocked by HOSTSeditor");
		$filepath0->set_alignment(0,0.5);
	$hbox->add($filepath0);
$vbox->pack_start($hbox,0,1,0);
	# Форма выбора файла
	$hbox=Gtk2::HBox->new;
		$tmp=Gtk2::Label->new;
		$tmp->set_markup("<b>Файл:</b>");
		$tmp->set_alignment(0,0.5);
	$hbox->pack_start($tmp,0,1,0);
		$tmp=Gtk2::Label->new("[$file]");
		$tmp->set_alignment(0,0.5);
	$hbox->add($tmp);
		$but=Gtk2::Button->new("Сохранить");
		$but->signal_connect("clicked"=>sub{
			$start=$textbody->get_start_iter;
			$end=$textbody->get_end_iter;
			$text=$textbody->get_text($start,$end,true);
			open fs,">$file";print fs $text;close fs;
		});
	$hbox->pack_start($but,0,1,0);
		$butc0=Gtk2::Button->new("Х");
		$butc0->signal_connect("clicked"=>sub{Gtk2->main_quit;});
	$hbox->pack_start($butc0,0,1,0);
$vbox->pack_start($hbox,0,1,0);
$main->add($vbox);
# Устанавливаем обработчики
$main->signal_connect("destroy"=>sub{Gtk2->main_quit;});
# инициализация
$main->show_all;
Gtk2->main;
