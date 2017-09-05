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
use IO::Select;

my $ioset=IO::Select->new;
my $port = 23;
my $rport = 2323;
print "SERVER [ ";
my $server = IO::Socket::INET->new(LocalPort => $port, Proto => 'udp') or print " ERROR]\n" and die "I could not create socket! ]\n";
my $clientUDP=IO::Socket::INET->new(PeerAddr=>"localhost",PeerPort=>$rport,Proto=>'udp') or die "UDP client: $@";
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
$ioset->add($server);
while(1){
	for my $socket($ioset->can_read){
		my $read=$socket->recv(my $buff,32768);
		if(!$read){	# DISCONNECT
			$ioset->remove($socket);
			close $socket;
			next;
		}
		if($socket eq $server){ resend($buff); }
		if($socket eq $clientUDP){ cresend($buff); }
	}
}

sub resend{
	my $data = shift @_;
	#print ">: [".unpack('H*',$data)."]\n";
	$clientUDP->send($data);
}
sub cresend{
	my $data = shift @_;
	$server->send($data);
}
