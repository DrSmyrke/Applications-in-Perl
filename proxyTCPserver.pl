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
my $port=26900;
my $work="192.168.1.19";
my (%ipTable);
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
$SIG{TERM}="sigExit";
#$SIG{CHLD}="IGNORE";
#####	MAIN	######
use strict;
use IO::Socket;
use IO::Select;
my $ioset=IO::Select->new;
print "SERVER [ ";
socket(SERVER,PF_INET,SOCK_STREAM,getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER,SOL_SOCKET,SO_REUSEADDR,1);
bind(SERVER,sockaddr_in($port,INADDR_ANY)) or die " I can not bind port! ]\n";
listen(SERVER,SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
$ioset->add(\*SERVER);
$ioset->add(\*STDIN);
while(1){
	for my $socket($ioset->can_read){
		if($socket eq \*SERVER){
			my $nc=accept(my $client,SERVER);
			$client->autoflush(1);
			$ioset->add($client);
			$ipTable{$client}{"ip"}=client_ip($nc);
			$ipTable{$client}{"type"}="home";
			$ipTable{$client}{"tunnel"}=0;
			if($ipTable{$client}{"ip"} eq $work){
				$ipTable{$client}{"type"}="work";
			}
			print "[$ipTable{$client}{ip}] $ipTable{$client}{type} >: conneted\n";
			next;
		}
		my $read=$socket->sysread(my $buff,65536);
		if(!$read){	# DISCONNECT
			print "[$ipTable{$socket}{ip}] $ipTable{$socket}{type} >: disconneted\n";
			disconnect($socket);
			next;
		}
		if($socket eq \*STDIN){
			chomp $buff;
			$buff=~tr/[A-Z]/[a-z]/;
			if($buff eq "stop"){sigExit();}
			next;
		}
		if(!$ipTable{$socket}{"tunnel"}){
			foreach my $str($ioset->handles()){
				if($str eq \*SERVER or $str eq \*STDIN){next;}
				if($ipTable{$str}{"type"} eq "work"){
					if(!$ipTable{$str}{"tunnel"}){
						$ipTable{$str}{"tunnel"}=$socket;
						$ipTable{$socket}{"tunnel"}=$str;
						last;
					}
				}
			}
		}
		if($ipTable{$socket}{"tunnel"}){
			my $host=$ipTable{$socket}{"tunnel"};
			$host->syswrite($buff);
		}else{
			disconnect($socket);
		}
		#print "[$ipTable{$socket}{ip}] [$ipTable{$socket}{user}] >: [$buff]\n";
	}
}
sigExit();
## FUNCTIONS ###
sub disconnect{
	my $socket=shift @_;
	if(exists($ipTable{$socket}{"tunnel"})){
		my $host=$ipTable{$socket}{"tunnel"};
		delete $ipTable{$host};
		$ioset->remove($host);
		close $host;
	}
	delete $ipTable{$socket};
	$ioset->remove($socket);
	close $socket;
}
sub client_ip {
	my $client=shift @_;
	my ($client_port,$client_ip)=sockaddr_in($client);
	return inet_ntoa($client_ip);
}
sub sigExit{
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		close $str;
		delete $ipTable{$str};
	}
	close SERVER;
	print "\nSERVER [ DEACTIVATED ]\n";
	exit;
}
