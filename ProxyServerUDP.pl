#!/usr/bin/perl
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
my $port=26900;
my (%ipTable);
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
#$SIG{CHILD}="IGNORE";
$SIG{TERM}="sigExit";
#####	MAIN	######
use strict;
use IO::Socket;
use IO::Select;
my $ioset=IO::Select->new;
print "SERVER [ ";
my $serverUDP=IO::Socket::INET->new(LocalPort=>$port,Proto=>'udp') or die "socket: $@";
socket(SERVER,PF_INET,SOCK_STREAM,getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER,SOL_SOCKET,SO_REUSEADDR,1);
bind(SERVER,sockaddr_in($port,INADDR_ANY)) or die " I can not bind port! ]\n";
listen(SERVER,SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
$serverUDP->autoflush(1);
$ioset->add($serverUDP);
$ioset->add(\*SERVER);
while(1){
	for my $socket($ioset->can_read){
		if($socket eq \*SERVER){
			my $nc=accept(my $client,SERVER);
			$client->autoflush(1);
			$ioset->add($client);
			$ipTable{$client}{"ip"}=client_ip($nc);
			$ipTable{$client}{"type"}="work";
			print "[$ipTable{$client}{ip}] $ipTable{$client}{type} >: conneted\n";
			next;
		}
		if($socket eq $serverUDP){
			my $read=$serverUDP->recv(my $buff,32768);
			#my($iport,$ipaddr)=sockaddr_in($serverUDP->peername);
			#$ipaddr=inet_ntoa($ipaddr);
			foreach my $str($ioset->handles()){
				if($str eq \*SERVER or $str eq $serverUDP){next;}
				if($ipTable{$str}{"type"} eq "work"){
					$str->syswrite($buff);
					last;
				}
			}
			next;
		}
		my $read=$socket->sysread(my $buff,32768);
		if(!$read){	# DISCONNECT
			print "[$ipTable{$socket}{ip}] $ipTable{$socket}{type} >: disconneted\n";
			delete $ipTable{$socket};
			$ioset->remove($socket);
			close $socket;
			next;
		}
		$serverUDP->send($buff);
	}
}
sigExit();
## FUNCTIONS ###
sub stop{
	print "SHUTDOWN ... \n";
	foreach my $str($ioset->handles()){$ioset->remove($str);close $str;}
	sigExit();
}
sub client_ip {
	my $client=shift @_;
	my ($client_port,$client_ip)=sockaddr_in($client);
	return inet_ntoa($client_ip);
}
sub sigExit{
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER){next;}
		close $str;
	}
	close SERVER;
	print "\nSERVER [ DEACTIVATED ]\n";
	exit;
}
