#!/usr/bin/perl
$fd=`zenity --file-selection --directory --title='Выберите папку репозитория'`;
$fd=substr($fd,0,-1);
$fd=~s/[ ]/\\ /g;
$rpath=$fd;
chdir "$rpath";
system "dpkg-scanpackages pool /dev/null | gzip -9c > bin/Packages.gz";
system "dpkg-scansources pool /dev/null | gzip -9c > source/Sources.gz";
