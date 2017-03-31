#!/usr/bin/perl
# httpProxyServer, a simple HTTP(S) Proxy server, based on DrSmyrke
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
# Порт приема входящих подключений
my $port=7300;
my $version="0.2";
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
my (%ipTable);
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
use MIME::Base64;
my $ioset=IO::Select->new;
print "HTTP(S) PROXY SERVER [ ";
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER,sockaddr_in($port, INADDR_ANY)) or die " I can not bind port! ]\n"; 
listen(SERVER, SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
print "Waiting for connection...\n";
$ioset->add(\*SERVER);
$ioset->add(\*STDIN);
while(1){
	for my $socket($ioset->can_read){
		if($socket eq \*SERVER){
			my $nc=accept(my $client,SERVER);
			$client->autoflush(1);
			$ioset->add($client);
			$ipTable{$client}{"ip"}=client_ip($nc);
			$ipTable{$client}{"port"}=client_port($nc);
			$ipTable{$client}{"tunnel"}=0;
			$ipTable{$client}{"host"}=0;
			$ipTable{$client}{"tunnelType"}=0;
			next;
		}
		my $read=$socket->sysread(my $buff,1024);
		if(!$read){	# DISCONNECT
			$ioset->remove($socket);
			if($ipTable{$socket}{"host"}){$ioset->remove($ipTable{$socket}{"host"});close $ipTable{$socket}{"host"};}
			delete $ipTable{$socket};
			close $socket;
			next;
		}
		if($socket eq \*STDIN){
			chomp $buff;
			if($buff eq "/stop"){stop();}
			if($buff eq "/list"){clients();}
			next;
		}
		if(!$ipTable{$socket}{"tunnel"}){
			my $data=unpack("H*",$buff);
			my $ver=substr($data,1,1);
			my $cmd=substr($data,2,2);
			my $rport=sprintf("%d",hex(substr($data,4,4)));
			my $rserver=substr($data,8,8);
			my @ip;
			$ip[0]=sprintf("%d",hex(substr($rserver,0,2)));
			$ip[1]=sprintf("%d",hex(substr($rserver,2,2)));
			$ip[2]=sprintf("%d",hex(substr($rserver,4,2)));
			$ip[3]=sprintf("%d",hex(substr($rserver,6,2)));
			$rserver=join(".",@ip);
			print ">: [$ipTable{$socket}{ip}] V.$ver Connect to $rserver:$rport ...";
			my $rhost=IO::Socket::INET->new(PeerAddr => $rserver,PeerPort => $rport) || 0;
			if($rhost){
				$rhost->autoflush(1);
				print " OK\n";
				$ipTable{$socket}{"tunnel"}=1;
				$ipTable{$socket}{"host"}=$rhost;
				$ipTable{$rhost}{"tunnel"}=1;
				$ipTable{$rhost}{"host"}=$socket;
				$ioset->add($rhost);
				$buff=undef;
				print $socket "\x00\x5a\x00\x00\x00\x00\x00\x00";
				next;
			}else{
				print " ERROR\n";
				print $socket "\x00\x5b\x00\x00\x00\x00\x00\x00";
				$ioset->remove($socket);
				delete $ipTable{$socket};
				close $socket;
				next;
			}
		}
		if($ipTable{$socket}{"tunnel"}){
			#if($ipTable{$socket}{"tunnelType"} eq "https"){
				#print $ipTable{$socket}{"host"} $buff;
				$ipTable{$socket}{"host"}->syswrite($buff);
				$buff=undef;
			#}
		}
		#print "[$buff]\n";
	}
}
sigExit();
## FUNCTIONS ###
sub genError{
	my $socket=shift @_;
	my $text=shift @_;
	print $socket "HTTP/1.1 $text\r\nContent-Length: ".length($text)."\r\nConnection: Close\r\n\r\n$text\r\n";
	$ioset->remove($socket);
	delete $ipTable{$socket};
	close $socket;
}
sub clients{
	print "\033[0;35m=====================: \033[0;37mClients \033[0;35m:======================\n";
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		print "\033[0;37m[$ipTable{$str}{ip}:$ipTable{$str}{port}]	\033[1;32m$ipTable{$str}{user}\n";
	}
	print "\033[0;37mTotal: \033[1;32m".($ioset->count()-2)."\n";
	print "\033[0;35m======================================================\033[m\n";
}
sub client_ip{
	my $client=shift @_;
	my ($client_port,$client_ip)=sockaddr_in($client);
	return inet_ntoa($client_ip);
}
sub client_port{
	my $client=shift @_;
	my ($client_port,$client_ip)=sockaddr_in($client);
	return $client_port;
}
sub stop{
	print "SHUTDOWN ... \n";
	foreach my $str($ioset->handles()){$ioset->remove($str);close $str;}
	sigExit();
}
sub sigExit{
	#snd("KILL");
	close SERVER;
	print "\nSERVER [ DEACTIVATED ]\n";
	exit;
}
