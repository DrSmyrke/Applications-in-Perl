#!/usr/bin/perl -w 
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
use strict; 
use IO::Socket; 
my($server, $newmsg, $max_len, $server_port); 
$max_len = 1024; 
$server_port = 20044; 
$server = IO::Socket::INET->new(LocalPort=>$server_port, Broadcast=>1, Proto=>"udp") or die "Невозможно запустить udp сервер на порту $server_port: $@\n"; 
print "UDP Сервер стартовал на порту: $server_port\n"; 
$newmsg = ""; 
while($server->recv($newmsg,$max_len)){ 
    if($newmsg){ 
        my($port, $ipaddr) = sockaddr_in($server->peername); 
        print "Client $ipaddr said $newmsg \n"; 
        open (F, ">>udp.log"); 
        print F "$ipaddr : $newmsg\n"; 
        close F; 
    } 
} 
die "recv: $!";
