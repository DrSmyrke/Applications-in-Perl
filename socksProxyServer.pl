#!/usr/bin/perl
# socksProxyServer, a simple SOCKS4 Proxy server, based on DrSmyrke
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
my $port=7305;
my $version="0.1";
my $pidfile="$ENV{HOME}/.run/socksproxyserver.pid";
my ($datadir,$statMode);
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-pidfile"){$pidfile=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
print "SOCKS4 PROXY SERVER [ ";
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER,sockaddr_in($port, INADDR_ANY)) or die " I can not bind port! ]\n"; 
listen(SERVER, SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
open F,">$pidfile";print F $$;close F;
print "Waiting for connection...\n";
while(my $client_addr=accept(BROWSER, SERVER)){
	my ($client_port,$client_ip) = sockaddr_in($client_addr);
	my $clientip=inet_ntoa($client_ip);
	if(fork==0){
		print ">: [$clientip] Connected PID: [$$]\n";
		BROWSER->autoflush(1);
		my $ioset=IO::Select->new;
		$ioset->add(\*BROWSER);
		my ($tunnel,$cmd,$ver,$rport,$rserver,@ip);
		while (my @ready=$ioset->can_read){
			foreach my $socket(@ready){
				my $read=$socket->sysread(my $data,4096);
				if(!$read){$tunnel=0;disconnect($clientip,$socket,$ioset);}
				if($socket==\*BROWSER){
#					print "BROWSER: [READ DATA]\n";
#					print ">[$data]\n";
					if(!$cmd){
						$data=unpack("H*",$data);
						$ver=substr($data,1,1);
						$cmd=substr($data,2,2);
						$rport=sprintf("%d",hex(substr($data,4,4)));
						$rserver=substr($data,8,8);
						$ip[0]=sprintf("%d",hex(substr($rserver,0,2)));
						$ip[1]=sprintf("%d",hex(substr($rserver,2,2)));
						$ip[2]=sprintf("%d",hex(substr($rserver,4,2)));
						$ip[3]=sprintf("%d",hex(substr($rserver,6,2)));
						$rserver=join(".",@ip);
						print ">: [$clientip] V.$ver Connect to $rserver:$rport ...";
						socket(SOCK,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
						if(connect(SOCK,sockaddr_in($rport,inet_aton($rserver)))){
							print " OK\n";
							$tunnel=1;
							$ioset->add(\*SOCK);
							print BROWSER "\x00\x5a\x00\x00\x00\x00\x00\x00";
							$data=undef;
						}else{
							print " ERROR\n";
							print BROWSER "\x00\x5b\x00\x00\x00\x00\x00\x00";
							disconnect($clientip,$socket,$ioset);
						}
					}
				}
#				if(fileno SOCK){
#					if($socket==\*SOCK){
#						print "SOCK: [READ DATA]\n";
#						print "<[$data]\n";
#					}
#				}
				if($tunnel){
					my $remote=($socket==\*SOCK)?\*BROWSER:\*SOCK;
					$remote->syswrite($data);
				}
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
	if($socket==\*BROWSER){kill 'TERM',$$;}
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Гб";}}}}return $sz;}
sub sigExit{
	close SERVER;
	unlink $pidfile;
	print "\SOCKS4 PROXY SERVER [ DEACTIVATED ]\n";
	unlink $pidfile;
	exit;
}
sub getHelp{
	print "=== Help Page for SocksProxyServer by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-pidfile <FILE>			Determining PID file (default: ~/.run/httpsproxyserver.pid)
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($0);
	my $i=0;
	open FS,"<$0";while(my $tmp=<FS>){$i++;}close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
