#!/usr/bin/perl
# proxyServer, a simple Proxy server, based on DrSmyrke
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
my $maxConn=2;
my ($homeIP,$homePort,$rhostIP,$rhostPort)=("localhost",7300,"192.168.1.19",26900);
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
my (%ipTable);
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
my $ioset=IO::Select->new;
my $clientUDP=IO::Socket::INET->new(PeerAddr=>$rhostIP,PeerPort=>$rhostPort,Proto=>'udp') or die "UDP client: $@";
$ioset->add($clientUDP);
print "UDP PROXY DAEMON [ ACTIVATED ]\n";
while(1){
	chkHomeCon();
	for my $socket($ioset->can_read(3)){
		if($socket eq $clientUDP){
			my $read=$clientUDP->recv(my $buff,32768);
			foreach my $str($ioset->handles()){
				if(exists($ipTable{$str})){
					if($ipTable{$str}{"type"} eq "home"){
						$str->syswrite($buff);
						last;
					}
				}
			}
			next;
		}
		my $read=$socket->sysread(my $buff,32768);
		if(!$read){	# DISCONNECT
			$ioset->remove($socket);
			delete $ipTable{$socket};
			close $socket;
			next;
		}
		$clientUDP->send($buff);
	}
}
sigExit();
## FUNCTIONS ###
sub chkHomeCon{
	my $con=0;
	foreach my $str($ioset->handles()){
		if(exists($ipTable{$str})){
			if($ipTable{$str}{"type"} eq "home"){$con++;}
		}
	}
	for(my $i=$con;$i<$maxConn;$i++){
		my $rhost=IO::Socket::INET->new(PeerAddr=>$homeIP,PeerPort=>$homePort) || 0;
		if($rhost){
			$ioset->add($rhost);
			$ipTable{$rhost}{"type"}="home";
		}
	}
	print "Con: $con\n";
}
sub sigExit{
	#snd("KILL");
	close SERVER;
	print "\nDAEMON [ DEACTIVATED ]\n";
	exit;
}
