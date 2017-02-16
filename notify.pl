#!/usr/bin/perl
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2016 Prokofiev Y. <Smyrke2005@yandex.ru>
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
use Gtk2 '-init';
use utf8;
use Encode;
$win=Gtk2::Window->new("toplevel");
$win->set_resizable(1);
$win->set_position(GTK_WIN_POS_CENTER_ALWAYS);
$tmp=$ARGV[0];
$tmp=decode('utf8',$tmp);
$win->set_title($tmp);
$count=30;
$winwidth=300;
$winheight=100;
#$win->set_default_size($winwidth,$winheight);
$tmp=$ARGV[1];
$tmp=decode('utf8',$tmp);
$label=Gtk2::Label->new("$tmp");
$label->set_line_wrap(1);
$win->add($label);
$win->show_all;
$win->signal_connect("destroy"=>sub{exit;});
while(1){
	if($count){
		select(undef,undef,undef,0.5);
		Gtk2->main_iteration while Gtk2->events_pending;
		$count--;
	}else{
		exit;
	}
}
