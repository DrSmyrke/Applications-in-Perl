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
my ($rhostIP,$rhostPort)=("localhost",26900);
my @home=("192.168.1.145:26900:1","IP:26900:1","IP:26900:1");
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
$SIG{TERM}="sigExit";
#$SIG{CHLD}="IGNORE";
my (%ipTable);
### MAIN ###
$|=1;
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
my $ioset=IO::Select->new;
print "PROXY DAEMON [ ACTIVATED ]\n";
while(1){
	chkHomeCon();
	for my $socket($ioset->can_read(5)){	
		my $read=$socket->sysread(my $buff,65536);
		if(!$read){	# DISCONNECT
			disconnect($socket);
			next;
		}
		if(!$ipTable{$socket}{"tunnel"}){
			if($ipTable{$socket}{"type"} eq "home"){
				my $rhost=IO::Socket::INET->new(PeerAddr=>$rhostIP,PeerPort=>$rhostPort) || 0;
				if($rhost){
					$ioset->add($rhost);
					$ipTable{$rhost}{"type"}="rserver";
					$ipTable{$rhost}{"tunnel"}=$socket;
					$ipTable{$socket}{"tunnel"}=$rhost;
				}
			}
		}
		if($ipTable{$socket}{"tunnel"}){
			$ipTable{$socket}{"tunnel"}->syswrite($buff);
		}else{
			disconnect($socket);
		}
	}
}
sigExit();
## FUNCTIONS ###
sub disconnect{
	my $socket=shift @_;
	if($ipTable{$socket}{"tunnel"}){
		$ioset->remove($ipTable{$socket}{"tunnel"});
		close $ipTable{$socket}{"tunnel"};
		delete $ipTable{$ipTable{$socket}{"tunnel"}};
	}
	$ioset->remove($socket);
	delete $ipTable{$socket};
	close $socket;
}
sub chkHomeCon{
	print "======================================\n";
	foreach my $line(@home){
		my ($host,$port,$count)=split(":",$line);
		print "[$line]		";
		my $find=0;
		foreach my $key(keys %ipTable){
			if($ipTable{$key}{"port"} eq $port and $ipTable{$key}{"host"} eq $host){$find++;}
		}
		for(my $i=$find;$i<$count;$i++){
			my $rhost=IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port,Timeout=>1) || 0;
			if($rhost){
				$ioset->add($rhost);
				$ipTable{$rhost}{"host"}=$host;
				$ipTable{$rhost}{"port"}=$port;
				$ipTable{$rhost}{"type"}="home";
				$ipTable{$rhost}{"tunnel"}=0;
			}
		}
		print $find."\n";
	}
}
sub sigExit{
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER){next;}
		close $str;
	}
	close SERVER;
	print "\nDAEMON [ DEACTIVATED ]\n";
	exit;
}
