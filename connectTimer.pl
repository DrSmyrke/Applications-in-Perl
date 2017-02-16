#!/usr/bin/perl
# connectTime, a view time connect to server, based on DrSmyrke
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
use Time::HiRes;
use IO::Socket;
$serv=$ARGV[0];
print "Соединение с сервером [$serv]... ";
$time1=Time::HiRes::time;
$socket=IO::Socket::INET->new($serv);
defined $socket or die "ERROR: $!\n";
$time2=Time::HiRes::time;
$socket->close();
$time=($time2-$time1)*1000;
$time=substr($time,0,6);
print "OK	$time мс\n";
