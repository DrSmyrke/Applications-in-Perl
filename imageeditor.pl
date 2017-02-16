#!/usr/bin/perl
# IMAGEEDITOR, a app based on DrSmyrke
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
#
#sudo apt-get install libimage-magick-perl
#
#
#
#use package PERLMAGICK
use Gtk2 '-init';
########## Переменные ##########
@glibs=("Image::Magick");#,"Cairo");
$fmode="in place";
$pref="";
$smode="N/A";
$files=@ARGV;
$lib="N/A";
# Поиск библиотек для работы с изображениями
foreach $dir(@INC){
	foreach $str(@glibs){
		if($str=~/:/){
			($ldir,$module)=split("::",$str);
			if(-f "$dir/$module.pm" or -f "$dir/$ldir/$module.pm"){$lib=$str;}
		}else{
			if(-f "$dir/$str.pm" or -f "$dir/$str/$str.pm"){$lib=$str;}
		}
		if($lib ne "N/A"){last;}
	}
	if($lib ne "N/A"){last;}
}
if($lib ne "N/A"){eval "use $lib;";}
# создаем всплывающее окно
$main=Gtk2::Window->new('toplevel');
$main->set_title("imageeditor");
$main->set_position("GTK_WIN_POS_CENTER_ALWAYS");
$main->set_resizable(0);
####################
$vbox=Gtk2::VBox->new;
	$tmp=Gtk2::Label->new;
	$tmp->set_markup("<b>Filename</b>");
	$tmp->set_alignment(0,0.5);
$vbox->pack_start($tmp,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Append"),0,1,0);
		$append=Gtk2::Entry->new;
		$append->set_text(".resized");
	$hbox->pack_start($append,0,1,0);
		$appendb=Gtk2::Button->new("Select");
		$appendb->signal_connect("clicked"=>sub{
			$fmode="append";
			$pref=$append->get_text;
			$modelabel->set_text($fmode);
			$prefflabel->set_text($pref);
		});
	$hbox->pack_start($appendb,0,1,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,1,0);
		$resizefmb=Gtk2::Button->new("Resize in place");
		$resizefmb->signal_connect("clicked"=>sub{
			$fmode="in place";
			$pref="";
			$modelabel->set_text($fmode);
			$prefflabel->set_text($pref);
		});
	$hbox->pack_start($resizefmb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$tmp=Gtk2::Label->new;
	$tmp->set_markup("<b>Configurations</b>");
	$tmp->set_alignment(0,0.5);
$vbox->pack_start($tmp,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("MODE: "),0,1,0);
		$modelabel=Gtk2::Label->new($fmode);
		$modelabel->set_alignment(0,0.5);
	$hbox->pack_start($modelabel,0,1,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("PREFF: "),0,1,0);
		$prefflabel=Gtk2::Label->new($preff);
		$prefflabel->set_alignment(0,0.5);
	$hbox->pack_start($prefflabel,0,1,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("LIB: "),0,1,0);
		$liblabel=Gtk2::Label->new($lib);
		$liblabel->set_alignment(0,0.5);
	$hbox->pack_start($liblabel,0,1,0);
	$hbox->pack_start(Gtk2::VSeparator->new,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("FILES: "),0,1,0);
		$fileslabel=Gtk2::Label->new($files);
		$fileslabel->set_alignment(0,0.5);
	$hbox->pack_start($fileslabel,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$tmp=Gtk2::Label->new;
	$tmp->set_markup("<b>Image Size</b>");
	$tmp->set_alignment(0,0.5);
$vbox->pack_start($tmp,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Scale: "),0,1,0);
		$scale=Gtk2::Entry->new;
		$scale->set_text("50");
	$hbox->pack_start($scale,0,1,0);
		$scaleb=Gtk2::Button->new("Resize");
		$scaleb->signal_connect("clicked"=>sub{func("scale");});
	$hbox->pack_start($scaleb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Custom size: "),0,1,0);
		$width=Gtk2::Entry->new;
		$width->set_text("10000");
	$hbox->pack_start($width,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("X"),0,1,0);
		$height=Gtk2::Entry->new;
		$height->set_text("10000");
	$hbox->pack_start($height,0,1,0);
		$customb=Gtk2::Button->new("Resize");
		$customb->signal_connect("clicked"=>sub{func("custom");});
	$hbox->pack_start($customb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Fixed size: "),0,1,0);
		$widthf=Gtk2::Entry->new;
		$widthf->set_text("100");
	$hbox->pack_start($widthf,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("X"),0,1,0);
		$heightf=Gtk2::Entry->new;
		$heightf->set_text("100");
	$hbox->pack_start($heightf,0,1,0);
		$fixedb=Gtk2::Button->new("Resize");
		$fixedb->signal_connect("clicked"=>sub{func("fixed");});
	$hbox->pack_start($fixedb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$tmp=Gtk2::Label->new;
	$tmp->set_markup("<b>Image Rotation</b>");
	$tmp->set_alignment(0,0.5);
$vbox->pack_start($tmp,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Custom angle: "),0,1,0);
		$angle=Gtk2::Entry->new;
		$angle->set_text("90");
	$hbox->pack_start($angle,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("degrees clockwise"),0,1,0);
		$fixedb=Gtk2::Button->new("Rotate");
		$fixedb->signal_connect("clicked"=>sub{func("rotate");});
	$hbox->pack_start($fixedb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$tmp=Gtk2::Label->new;
	$tmp->set_markup("<b>Image Crop</b>");
	$tmp->set_alignment(0,0.5);
$vbox->pack_start($tmp,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Size: "),0,1,0);
		$widthc=Gtk2::Entry->new;
		$widthc->set_text("100%");
	$hbox->pack_start($widthc,0,1,0);
	$hbox->pack_start(Gtk2::Label->new("X"),0,1,0);
		$heightc=Gtk2::Entry->new;
		$heightc->set_text("50%");
	$hbox->pack_start($heightc,0,1,0);
$vbox->pack_start($hbox,0,1,0);
	$hbox=Gtk2::HBox->new;
	$hbox->pack_start(Gtk2::Label->new("Focus: "),0,1,0);
		$posxc=Gtk2::Entry->new;
		$posxc->set_text("0");
	$hbox->pack_start($posxc,0,1,0);
	$hbox->pack_start(Gtk2::Label->new(";"),0,1,0);
		$posyc=Gtk2::Entry->new;
		$posyc->set_text("0");
	$hbox->pack_start($posyc,0,1,0);
		$cropb=Gtk2::Button->new("Crop");
		$cropb->signal_connect("clicked"=>sub{func("crop");});
	$hbox->pack_start($cropb,0,1,0);
$vbox->pack_start($hbox,0,1,0);
$main->add($vbox);
# Устанавливаем обработчики
$main->signal_connect("destroy"=>sub{Gtk2->main_quit;});
# инициализация
$main->show_all;
Gtk2->main;
########## Процедуры ##########
sub func{
	$mode=shift @_;
	if($lib ne "N/A" and $files>0){
		if($lib eq "Image::Magick"){
			foreach $file(@ARGV){
				$image=Image::Magick->new;
				$image->Read($file);
				$w=$image->Get('columns');
				$h=$image->Get('rows');
				#$image->Crop(geometry=>'100x100+100+100'); 		# Обрезка изображения
				if($mode eq "scale"){
					$prz=$scale->get_text;
					$w=int(($w/100)*$prz);
					$h=int(($h/100)*$prz);
					$image->Resize(width=>$w,height=>$h);
				}
				if($mode eq "custom"){
					$w2=$width->get_text;
					$h2=$height->get_text;
					if($w2>=$w and $h2<$h){
						$r=int($h2/($h/100));
						$image->Resize(width=>int(($w/100)*$r),height=>$h2);
					}
					if($w2<$w and $h2>=$h){
						$r=int($w2/($w/100));
						$image->Resize(width=>$w2,height=>int(($h/100)*$r));
					}
				}
				if($mode eq "fixed"){
					$w=$widthf->get_text;
					$h=$heightf->get_text;
					$image->Resize(width=>$w,height=>$h);
				}
				if($mode eq "rotate"){
					$image->Rotate(degrees=>$angle->get_text);
				}
				if($mode eq "crop"){
					# ширина и высота будущей картинки
					$cw=$widthc->get_text;
					$ch=$heightc->get_text;
					# точка фокуса
					$cx=$posxc->get_text;
					$cy=$posyc->get_text;
					# обработка процентов
					if(substr($cw,-1,1) eq "%"){
						$cw=substr($cw,0,-1);
						$cw=($w/100)*$cw;
					}
					if(substr($ch,-1,1) eq "%"){
						$ch=substr($ch,0,-1);
						$ch=($h/100)*$ch;
					}
					# Вычисляем пропорции конечного изображения
					$r=$cw/$ch;
					# Определяем максимальный прямоугольник, который впишется в оригинальное изображение:
					#if($cw>=$ch){$wn=$w;$hm=$w/$r;}else{$hm=$h;$wm=$h*$r;}
					# где w, h — размеры оригинала, а wm, hw — размеры максимального прямоугольника.
					# Вычисляем новые координаты для точки фокуса:
					#$fx=$cx*$wn/$w;
					#$fy=$cy*$hn/$h;
					#$fx=$fy=0;
					#$image->Crop(width=>$wm,height=>$hm,x=>($cx-$fx),y=>($cy-$fy));
					if($h<$w){
						$image->Scale(width=>$w/$r,height=>$ch);
					}else{
						$image->Scale(width=>$cw,height=>$h*$r);
					}
					$image->Crop(width=>$cw,height=>$ch,x=>$cx,y=>$cy);
				}
				$image->Write($file);
			}
		}
	}
	Gtk2->main_quit;
}
