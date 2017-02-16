#!/usr/bin/perl
# socketClient, a simple Socket client, based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2016 Prokofiev Y. <Smyrke2005@yandex.ru>
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
use IO::Select;
my $ioset=IO::Select->new;
die "Usage: $0 <remote_host:remote_port>" unless @ARGV == 1;
my($remote_host,$remote_port)=split ':', shift();
print "Connetcion to $remote_host:$remote_port ... ";
socket(SOCK,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
if(connect(SOCK,sockaddr_in($remote_port,inet_aton($remote_host)))){
	print " OK\n";
	$ioset->add(\*SOCK);
	$ioset->add(\*STDIN);
	SOCK->autoflush(1);
}else{
	print " ERROR\n";
	exit 0;
}
while(1){
	for my $socket($ioset->can_read){
		my $read=$socket->sysread(my $buff,4096);
		if(!$read){	# DISCONNECT
			$ioset->remove($socket);
			close $socket;
			print "\n[SERVER CLOSED]\n";
			exit 0;
		}
		if($socket eq \*STDIN){
			chomp $buff;
			print SOCK $buff;
			next;
		}
		if($socket eq \*SOCK){
			print ">: $buff\n";
		}
	}
}
