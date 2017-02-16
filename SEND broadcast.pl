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
use warnings; 
use Socket; 
# BroadCast messager 
my $PORT = 20044; 
my $ADDR = '10.1.255.255'; 
socket(UDP, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket() failed: $@"; 
setsockopt(UDP, SOL_SOCKET, SO_BROADCAST, 1) or die "setsockopt() failed: $@"; 
my $dest = sockaddr_in($PORT,inet_aton($ADDR)); 
my $buff = undef; 
for(my $i = 1; $i <= 5; $i++) { 
    send(UDP, "Broadcast_packet_$i", 0, $dest) or die "send() failed: $@"; 
}
#tcpdump -i eth1 port 20044 -vvv
