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
use Cairo;
use Term::ANSIColor;
$width=700;
$height=700;
$kv=10;
$surface=Cairo::ImageSurface->create('argb32',$width,$height);
$cr=Cairo::Context->create ($surface);
print color("yellow"),"Введите масштаб: ",color("reset");$mas=<>;
$mas=substr($mas,0,-1);
print color("green"),"Введите Подпись к оси Y: ",color("reset");$labely=<>;
$labely=substr($labely,0,-1);
print color("green"),"Введите Подпись к оси X: ",color("reset");$labelx=<>;
$labelx=substr($labelx,0,-1);
&osi;&setka;&vvodx;
$st=$kv/$mas;
$cr->set_source_rgb(255,0,0);
$x=$tx=$x0;
$i=0;while($x<=$xn){
$y=$x*$x;
@x[$i]=$x;@y[$i]=$y;$i++;
$cr->move_to ($obs+$x*$mas,$ord-$y*$mas);
$x+=$eps;$y=$x*$x;@x[$i]=$x;@y[$i]=$y;$i++;
$cr->line_to($obs+$x*$mas,$ord-$y*$mas);
}
$cr->set_line_width(1);
$cr->stroke;
&vvodx;
$cr->set_source_rgb(0,0,255);
$x=$tx=$x0;
$i=0;while($x<=$xn){
$y=sqrt($x);
@x[$i]=$x;@y[$i]=$y;$i++;
$cr->move_to ($obs+$x*$mas,$ord-$y*$mas);
$x+=$eps;$y=sqrt($x);@x[$i]=$x;@y[$i]=$y;$i++;
$cr->line_to($obs+$x*$mas,$ord-$y*$mas);
}
$cr->set_line_width(1);
$cr->stroke;
&podpisi;
$cr->show_page;
$surface->write_to_png ('output.png');
########################### Функции ############################
sub setka{
$cr->set_source_rgba(0,0,0,0.3);
while($tmp!=$ord){$tmp+=$kv;$cr->move_to (0,$ord-$tmp);$cr->line_to($width,$ord-$tmp);}$tmp=0;
while($tmp!=$ord){$tmp+=$kv;$cr->move_to (0,$ord+$tmp);$cr->line_to($width,$ord+$tmp);}$tmp=0;
while($tmp!=$obs){$tmp+=$kv;$cr->move_to ($obs-$tmp,0);$cr->line_to($obs-$tmp,$height);}$tmp=0;
while($tmp!=$obs){$tmp+=$kv;$cr->move_to ($obs+$tmp,0);$cr->line_to($obs+$tmp,$height);}
$cr->set_line_width(0.5);
$cr->stroke;
}
sub osi{
$cr->set_source_rgba(0,0,0,0.7);
$ord=$height/2;$obs=$width/2;
$cr->move_to ($obs,0);$cr->line_to($obs,$height);
$cr->move_to (0,$ord);$cr->line_to($width,$ord);
$cr->move_to ($obs,0);$cr->line_to($obs-5,20);
$cr->move_to ($obs,0);$cr->line_to($obs+5,20);
$cr->move_to ($width,$ord);$cr->line_to($width-20,$ord-5);
$cr->move_to ($width,$ord);$cr->line_to($width-20,$ord+5);
for($i=$obs-$kv;$i>=0;$i-=$kv*2){$cr->move_to ($i,$ord-3);$cr->line_to($i,$ord+3);}
for($i=$obs+$kv;$i<=$width-$kv*2;$i+=$kv*2){$cr->move_to ($i,$ord-3);$cr->line_to($i,$ord+3);}
for($i=$ord-$kv;$i>=20;$i-=$kv*2){$cr->move_to ($obs-3,$i);$cr->line_to($obs+3,$i);}
for($i=$ord+$kv;$i<=$height;$i+=$kv*2){$cr->move_to ($obs-3,$i);$cr->line_to($obs+3,$i);}
$cr->move_to ($obs+10,10);
$cr->select_font_face ('Arial', 'normal', 'normal');
$cr->set_font_size(10);
$cr->show_text ("$labely");
$cr->move_to ($width-25,$ord+20);
$cr->show_text ("$labelx");
$cr->set_line_width(1);
$cr->stroke;
}
sub vvodx{
print color("yellow"),"Введите X0: ",color("reset");$x0=<>;$x0=substr($x0,0,-1);
print color("green"),"Введите Xn: ",color("reset");$xn=<>;$xn=substr($xn,0,-1);
print color("red"),"Введите Точность: ",color("reset");$eps=<>;$eps=substr($eps,0,-1);
}
sub podpisi{
$cr->set_source_rgba(0,0,0,0.7);
$cr->select_font_face ('Consolas', 'normal', 'normal');
$cr->set_font_size(8);$it=$kv;$chagit=$st;
for($i=$obs-20;$i>=0;$i-=20){
$st=0-(($it/$kv)*$chagit);$st=substr($st,0,4);
$cr->move_to ($i,$ord-4);
$cr->show_text ("$st");
$it+=$kv*2;}
$it=$kv;
for($i=$obs+5;$i<=$width-20;$i+=20){
$st=($it/$kv)*$chagit;$st=substr($st,0,4);
$cr->move_to ($i,$ord+9);
$cr->show_text ("$st");
$it+=$kv*2;}
$it=$kv;
for($i=$ord-5;$i>=20;$i-=20){
$st=($it/$kv)*$chagit;$st=substr($st,0,4);
$cr->move_to ($obs+3,$i-3);
$cr->show_text ("$st");
$it+=$kv*2;}
$it=$kv;
for($i=$ord+5;$i<=$height;$i+=20){
$st=0-($it/$kv)*$chagit;$st=substr($st,0,4);
$cr->move_to ($obs-20,$i+7);
$cr->show_text ("$st");
$it+=$kv*2;}
}
