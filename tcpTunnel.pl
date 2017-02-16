#!/usr/bin/perl
# tcpTunnel, a simple TCP Tunnel, based on DrSmyrke
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
my $port=7304;
my $version="0.1";
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
my ($server,$sport);
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-s" or $str eq "--server"){$server=$ARGV[$i+1];}
	if($str eq "-sp" or $str eq "--serverport"){$sport=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
if(!$port or !$server or !$sport){getHelp();exit;}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
print "TCP TUNNEL [ ";
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER,sockaddr_in($port, INADDR_ANY)) or die " I can not bind port! ]\n"; 
listen(SERVER, SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
my $ioset=IO::Select->new;
print "Waiting for connection...\n";
while(my $client_addr=accept(CLIENT,SERVER)){
	my ($client_port,$client_ip) = sockaddr_in($client_addr);
	my $clientip=inet_ntoa($client_ip);
	if(fork==0){
		print ">: [$clientip] Connected PID: [$$]\n";
		CLIENT->autoflush(1);
		$ioset->add(\*CLIENT);
		print ">: [$clientip] PID: [$$] Connecting to $server:$sport ...";
		socket(RSERVER,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
		if(connect(RSERVER,sockaddr_in($sport,inet_aton($server)))){
			print " OK\n";
			RSERVER->autoflush(1);
			$ioset->add(\*RSERVER);
		}else{
			print " ERROR\n";
			disconnect($clientip,\*CLIENT,$ioset);
		}
		while (my @ready=$ioset->can_read){
			foreach my $socket(@ready){
				my $read=$socket->sysread(my $data,4096);
				if(!$read){disconnect($clientip,$socket,$ioset);}
				my $remote=($socket==\*RSERVER)?\*CLIENT:\*RSERVER;
				$remote->syswrite($data);
			}
		}
	}
}
sigExit();
### FUNCTIONS ###
sub disconnect{
	my $ip=shift @_;
	my $socket=shift @_;
	my $ioset=shift @_;
	print ">: [$ip] Disconnected PID: [$$]\n";
	$ioset->remove($socket);$socket->close;
	if($socket==\*CLIENT){kill 'TERM',$$;}
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Гб";}}}}return $sz;}
sub sigExit{
	close RSERVER;
	close SERVER;
	print "\nTCP TUNNEL [ DEACTIVATED ]\n";
	exit;
}
sub getHelp{
	print "=== Help Page for tcpTunnel by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-s, --server <IP>		Remote server IP
-sp, --serverport <PORT>	Remote server PORT
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($0);
	my $i=0;
	open FS,"<$0";while(my $tmp=<FS>){$i++;}close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
