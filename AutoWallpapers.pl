#!/usr/bin/perl
@data=`find $ENV{HOME}/Images/ОБОИ -type f`;
find:
$i=int rand($#data);
$pf=@data[$i];chomp $pf;
if(!-f $pf){goto find;}
sleep 3;
### gnome2 ##############################
$key="/desktop/gnome/background/picture_filename";
$check=`gconftool-2 -T $key || gconftool -T $key`;chomp $check;
if($check eq "string"){system "gconftool-2 -t string -s $key $pf || gconftool -t string -s $key $pf";}
### gnome3 ##############################
$key="/org/gnome/desktop/background/picture-uri";
$key2="org.gnome.desktop.background picture-uri";
$check=`dconf read $key`;chomp $check;
if($check ne ""){system "dconf write $key \"'$pf'\"";}
$check2=`gsettings range $key2`;chomp $check2;
if($check2 eq "type s"){system "gsettings set $key2 \"'file://$pf'\"";}
### MATE ################################
$key="org.mate.background picture-filename";
$check=`gsettings range $key`;chomp $check;
if($check eq "type s"){system "gsettings set $key \"'$pf'\"";}
### XFCE ################################
$cmd=`xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $pf`;
$cmd=`xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s $pf`;
### LXDE ################################
$cmd=`pcmanfm -w $pf`;
open fs,">$ENV{HOME}/.autowallpapers";print fs "'$pf'";close fs;
