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
my $maxConn=10;
my ($homeIP,$homePort,$rhostIP,$rhostPort)=("IP",26900,"localhost",26900);
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
my (%ipTable);
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-hip"){$homeIP=$ARGV[$i+1];}
	if($str eq "-hport"){$homePort=$ARGV[$i+1];}
	$i++;
}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
my $ioset=IO::Select->new;
print "7days to die PROXY DAEMON [ ACTIVATED ] to [$homeIP:$homePort]\n";
while(1){
	chkHomeCon();
	for my $socket($ioset->can_read(3)){	
		my $read=$socket->sysread(my $buff,4096);
		if(!$read){	# DISCONNECT
			if($ipTable{$socket}{"tunnel"}){
				$ioset->remove($ipTable{$socket}{"tunnel"});
				close $ipTable{$socket}{"tunnel"};
				delete $ipTable{$ipTable{$socket}{"tunnel"}};
			}
			$ioset->remove($socket);
			delete $ipTable{$socket};
			close $socket;
			next;
		}
		if(!$ipTable{$socket}{"tunnel"}){
			if($ipTable{$socket}{"type"} eq "home"){
				my $rhost=IO::Socket::INET->new(PeerAddr=>$rhostIP,PeerPort=>$rhostPort,Timeout=>1) || 0;
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
		}
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
		my $rhost=IO::Socket::INET->new(PeerAddr=>$homeIP,PeerPort=>$homePort,Timeout=>1) || 0;
		if($rhost){
			$ioset->add($rhost);
			$ipTable{$rhost}{"type"}="home";
			$ipTable{$rhost}{"tunnel"}=0;
		}
	}
	print "";
}
sub sigExit{
	#snd("KILL");
	close SERVER;
	print "\nDAEMON [ DEACTIVATED ]\n";
	exit;
}
