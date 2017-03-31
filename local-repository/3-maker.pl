#!/usr/bin/perl
$fd=`zenity --file-selection --directory --title='Выберите папку репозитория'`;
$fd=substr($fd,0,-1);
$fd=~s/[ ]/\\ /g;
$rpath=$fd;
open fs,">local-repository.list";print fs "deb file://$rpath/ bin/\ndeb-src file://$rpath/ source/\n\n";close fs;
open fs,">local-repository.list.save";print fs "deb file://$rpath/ bin/\ndeb-src file://$rpath/ source/\n\n";close fs;
system "sudo cp local-repository.list /etc/apt/sources.list.d";
system "sudo cp local-repository.list.save /etc/apt/sources.list.d";
unlink "local-repository.list";
unlink "local-repository.list.save";
