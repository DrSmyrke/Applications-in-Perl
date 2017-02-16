#!/usr/bin/perl
# mailSender, a simple smtp client, based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2012 Prokofiev Y. <Smyrke2005@yandex.ru>
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
# along with this program.  If not, see <http://www.gnu.org/licenses>.
#
#
#
#use utf8;
#use encoding 'utf8';
use MIME::Base64;
use IO::Socket;
use Text::Iconv;
$serv="smtp.yandex.ru:25";
$mailusr="";
$mailpwd="";
$mailfrom="";
$subj=@ARGV[0];
$mailrcpt=@ARGV[1];
$mail=@ARGV[2];
$cnv=Text::Iconv->new('UTF8','CP1251');
$socket=IO::Socket::INET->new($serv);defined $socket or die "ERROR: $!\n";
if(ReadReply() ne 220){
	print "Ошибка установки связи=$message";
	$socket->close();
}
$socket->print ("helo lo\n");
if(ReadReply() != 250){
	print "Ошибка приветствия сервера=$message";
	$socket->close();
}
$socket->print("AUTH LOGIN\n");
if(ReadReply() ne 334){
	print "Ошибка авторизации=$message";
	$socket->close();
}
$socket->print(encode_base64($mailusr).encode_base64($mailpwd));
ReadReply();
if(ReadReply() ne 235){
	print "Ошибка авторизации=$message";
	$socket->close();
}
$socket->print('mail from: '."$mailfrom\n");
if(ReadReply() ne 250){
	print "Ошибка в почтовом ящике отправителя=$message";
	$socket->close();
}
$socket->print("rcpt to: $mailrcpt\n");
if(ReadReply() ne 250){
	print "Ошибка в почтовом ящике получателя=$message";
	$socket->close();
}
$socket->print("data\n");
if(ReadReply() ne 354){
	print "Ошибка в начале формирования письма=$message";
	$socket->close();
}
$subj=encode_base64($cnv->convert($subj));
$subj=~ s/\n//ig;
$subj=~ s/\r//ig;
$subj='=?Windows-1251?B?'.$subj.'?=';
$msg=encode_base64($cnv->convert($mail));
$body="Mime-Version: 1.0\n";
$body .= "Content-Type: multipart/mixed; boundary=\"-\"\n\n";
$body .= "---\nContent-Type: text/plain;\n\tcharset=\"Windows-1251\"\nContent-Transfer-Encoding: base64\n\n$msg\n---\n";
$mailmessage="From:$mailfrom\nTo:$mailrcpt\nSubject:$subj\n$body\n.\n";
$socket->print($mailmessage);
if(ReadReply() ne 250){
	print "Ошибка при отправке письма=$message";
	$socket->close();
}else{
	print "OK";
}
$socket->close();
sub ReadReply{$val=1;while($val eq 1){$r=<$socket>;$val=$r =~ m/^\d{3}-/g;}($reply,$message)=split(/ /,$r,2);return $reply;}
