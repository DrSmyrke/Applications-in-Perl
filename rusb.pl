#!/usr/bin/perl
# rUSB, a eject mount devices, based on DrSmyrke
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
$SIG{INT}="sigExit";
$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$find=1;
if(!-d "$ENV{HOME}/.run"){mkdir "$ENV{HOME}/.run";}
@tmp=split("/",$0);
$name=pop @tmp;
$name=~s/[.]/_/g;
$pidfile="$ENV{HOME}/.run/$name.pid";
if(!-f $pidfile){
	print "\nCreate [$pidfile]\n";
	$find=0;
	open fs,">$pidfile";
	print fs "$$";
	close fs;
}else{
	open fs,"<$pidfile";
	$pid=<fs>;
	close fs;
}
sub sigExit{
	print "\nremove [$pidfile]";
	unlink $pidfile;
	print "\nExit\n";
	unlink $pidfile;
	exit;
}
sub getSize{($sz)=@_;if($sz<1024){$st="$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Гб";}}}}return $st;}
use utf8;
use Gtk2 '-init';
# определение разрешения монитора
$cmd=`xrandr | grep \\*`;
($tmp,$t1)=split("   ",$cmd);
($widthmon,$heightmon)=split("x",$t1);
$status=0;
$dir=$0;$dir=~s#(.*)/.*#$1#;
if(-l $0){$dir=readlink $0;$dir=~s#(.*)/.*#$1#;}
$SIG{CHLD}="IGNORE";
#$pix{offline} = Gtk2::Gdk::Pixbuf::new_from_file(undef,"$dir/data/icon.svg");
#$pix{offline} = $pix{offline}->scale_simple(16,16, 'GDK_INTERP_BILINEAR');
#$statusicon = Gtk2::StatusIcon->new_from_pixbuf($pix{offline});
$statusicon = Gtk2::StatusIcon->new_from_stock("gtk-harddisk");
$statusicon->signal_connect("activate"=>sub{show_hide();});
$main=Gtk2::Window->new('popup');
#$main->signal_connect("leave-notify-event"=>sub{show_hide();});
#$main->set_position("GTK_WIN_POS_CENTER_ON_PARENT");
$main->set_default_size(350,400);
$vbox=Gtk2::VBox->new;
$main->add($vbox);
Gtk2->main;

sub show_hide{
	if($status eq 0){$main->show;$status=1;genData();}else{$main->hide;$status=0;}
}
sub genData{
	$count=0;
	$vbox->destroy;
	$vbox=Gtk2::VBox->new;
		$title=Gtk2::Label->new;
		$title->set_alignment(0,0.5);
	$vbox->pack_start($title,0,1,0);
	$vbox->pack_start(Gtk2::HSeparator->new,0,1,0);
	@cmd=`df -x tmpfs -x devtmpfs -B 1`;chomp @cmd;shift @cmd;
	foreach $str(@cmd){
		($dev,$tot,$isp,$free,$prz,$mount)=split(" ",$str);
		if($mount eq "/" or $mount eq "/home"){next;}
			$hbox=Gtk2::HBox->new;
			$butopen=Gtk2::Button->new;
			$butopen->set_relief("none");
				$vboxb=Gtk2::VBox->new;
					@tmp=split("/",$mount);$name=pop @tmp;
					$prz=$free/($tot/100);
					if(length($name)>7){$name=substr($name,0,6)."...";}
					$titleb=Gtk2::Label->new("[$name] Free: ".int($prz)."% [".getSize($free)." / ".getSize($tot)."]");
					$titleb->set_alignment(0,0.5);
				$vboxb->pack_start($titleb,0,1,0);
					$pb=Gtk2::ProgressBar->new;
					$prz=100-$prz;
					$prz/=100;
					$pb->set_fraction($prz);
				$vboxb->add($pb);
			$butopen->add($vboxb);
			$butopen->set_tooltip_text($mount);
			$butopen->signal_connect(clicked=>sub{
				$elem=shift @_;
				$tmp=$elem->get_tooltip_text;
				if(fork==0){exec "xdg-open $tmp";kill 'TERM',$$;}
				show_hide();
			});
			$buteject=Gtk2::Button->new;
			$buteject->set_image(Gtk2::Image->new_from_stock("gtk-disconnect","button"));
			$buteject->set_relief("none");
			$buteject->set_tooltip_text($dev);
			$buteject->signal_connect(clicked=>sub{
				$elem=shift @_;
				$tmp=$elem->get_tooltip_text;
				$tmp2=substr($tmp,0,-1);
				#if($count eq 1){$add=" && kill $$";}else{$add="";}
				#system "udisks --unmount $dev && udisks --detach $dev2$add";
				if(fork==0){exec "udisks --unmount $tmp && udisks --detach $tmp2 && notify-send -i gnome-terminal 'Операции с устройствами' 'Устройство успешно извлечено!' || udisksctl unmount -b $tmp && udisksctl power-off -b $tmp2 && notify-send -i gnome-terminal 'Операции с устройствами' 'Устройство успешно извлечено!'";kill 'TERM',$$;}
				show_hide();
			});
		$hbox->add($butopen);
		$hbox->pack_start($buteject,0,1,0);
	$vbox->pack_start($hbox,0,1,0);
	$vbox->pack_start(Gtk2::HSeparator->new,0,1,0);
		$count++;
	}
	$title->set_text("Устройств: $count");
	$vbox->show_all;
	$main->add($vbox);
	($width,$height)=$main->get_size;
	$main->move($widthmon-$width-5,$heightmon-30-$height);
}
