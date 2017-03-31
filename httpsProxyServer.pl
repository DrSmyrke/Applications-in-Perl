#!/usr/bin/perl
# httpsProxyServer, a simple HTTPS Proxy server, based on DrSmyrke
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
my $port=7303;
my $version="0.1";
my $pidfile="$ENV{HOME}/.run/httpsproxyserver.pid";
my ($datadir,$statMode);
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-pidfile"){$pidfile=$ARGV[$i+1];}
	if($str eq "-datadir"){$datadir=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
if($datadir and !-d $datadir){mkdir $datadir;}
if($datadir and -d $datadir){$statMode=1;}
if($statMode){
	if(!-d "$datadir/ip"){mkdir "$datadir/ip";}
	if(!-d "$datadir/users"){mkdir "$datadir/users";}
}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use IO::Select;
use MIME::Base64;
print "HTTPS PROXY SERVER [ ";
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER,sockaddr_in($port, INADDR_ANY)) or die " I can not bind port! ]\n"; 
listen(SERVER, SOMAXCONN);
print "ACTIVATED ] PID: [$$] PORT: [$port]\n";
open F,">$pidfile";print F $$;close F;
print "Waiting for connection...\n";
while(my $client_addr=accept(BROWSER, SERVER)){
	my($client_port,$client_ip) = sockaddr_in($client_addr);
	my $clientip=inet_ntoa($client_ip);
	if(fork==0){
		print ">: [$clientip] Connected PID: [$$]\n";
		BROWSER->autoflush(1);
		my $ioset=IO::Select->new;
		$ioset->add(\*BROWSER);
		my ($data,$browserHead,$tunnel,%stats,%browserHeadData);
		while (my @ready=$ioset->can_read){
			foreach my $socket(@ready){
				my $read=$socket->sysread($data,4096);
				if(!$read){
					$tunnel=0;
					$browserHead=undef;
					disconnect($clientip,$socket,$ioset);
				}
				if($socket==\*BROWSER){
#					print "BROWSER: [READ DATA]\n";
#					print ">[$data]\n";
					if(!$browserHead){
						($browserHead)=split("\r\n\r\n",$data);
						%browserHeadData=parsHead($browserHead);
						if(!$browserHeadData{"url"} or !$browserHeadData{"host"}){
							genError("400 Bad Request");
							$browserHead=undef;
							disconnect($clientip,$socket,$ioset);
						}
						my @tmp=glob("$datadir/users/*");my $users=@tmp;
						if($users){
							if(!exists($stats{"PAuth"}) and exists($browserHeadData{"PAuth"})){
								my $auth=parsAuth(%browserHeadData);
								if($auth){
									$stats{"PAuth"}=$browserHeadData{"PAuth"};
									$stats{"PAuthType"}=$browserHeadData{"PAuthType"};
									$stats{"PAuthL"}=$browserHeadData{"PAuthL"};
									$stats{"PAuthP"}=$browserHeadData{"PAuthP"};
								}
							}
							if(!exists($stats{"PAuth"})){
								sndNoAuth();
								$browserHead=undef;
								disconnect($clientip,$socket,$ioset);
							}
						}
						my ($host,$oport)=split(":",$browserHeadData{"host"});
						if(!$oport){$oport=($browserHeadData{"hport"})?$browserHeadData{"hport"}:443;}
						my $loginDir=($stats{"PAuthL"})?"$datadir/users/$stats{PAuthL}":"$datadir/ip/$clientip";
						my $block=parsFilter($loginDir,%browserHeadData);
						if($block){
							genBlock();
							$browserHead=undef;
							disconnect($clientip,$socket,$ioset);
						}
						my $ip=Socket::inet_ntoa((gethostbyname($host))[4]);
						socket(SOCK,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
						print ">: [$clientip] Connect to $host:$oport...";
						if(connect(SOCK,sockaddr_in($oport,inet_aton($ip)))){
							print " OK\n";
							$tunnel=1;
							$ioset->add(\*SOCK);
							print BROWSER "HTTP/1.1 200 Connection established\r\n\r\n";
							$data=undef;
						}else{
							print " ERROR\n";
							genError("502 Bad Gateway");
							$browserHead=undef;
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
				if($statMode){
					my $loginDir=($stats{"PAuthL"})?"$datadir/users/$stats{PAuthL}":"$datadir/ip/$clientip";
					if(!-d $loginDir){mkdir $loginDir;}
				}
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
sub sndNoAuth{
	print BROWSER "HTTP/1.1 407 Unauthorized\r\nContent-Length: 21\r\nProxy-Authenticate: Basic realm=ProxyAuth\r\nConnection: Close\r\n\r\n<h1>Unauthorized</h1>\r\n";
}
sub genBlock{
	my $text='<h1>Content is bocked</h1><b>Call to unblock from 3009</b>';
	print BROWSER "HTTP/1.1 404 OK\r\nContent-Length: ".length($text)."\r\nConnection: Close\r\n\r\n$text\r\n";
}
sub genError{
	my $text=shift @_;
	print BROWSER "HTTP/1.1 $text\r\nContent-Length: ".length($text)."\r\nConnection: Close\r\n\r\n$text\r\n";
}
sub parsAuth{
	my %hdata=@_;
	if($datadir and -f "$datadir/users/$hdata{PAuthL}/password"){
		open F,"<$datadir/users/$hdata{PAuthL}/password";my $pass=<F>;close F;chomp $pass;
		if($pass eq $hdata{"PAuthP"}){return 1;}
	}
	return 0;
}
sub parsHead{
	my $data=shift @_;
	my %hdata;
	foreach my $str(split("\r\n",$data)){
		(my $param,my $val)=split(": ",$str);
		if($param eq "Proxy-Authorization"){
			(undef,$hdata{"PAuthType"},$hdata{"PAuth"})=split(" ",$str);
			($hdata{"PAuthL"},$hdata{"PAuthP"})=split(":",decode_base64($hdata{"PAuth"}));
			next;
		}
		if($param eq "Host"){$hdata{"host"}=$val;}
		if(substr($str,0,7) eq "CONNECT"){
			($hdata{"method"},$hdata{"url"},$hdata{"http"})=split(" ",$str);
			$hdata{"url"}=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			($hdata{"hurl"},$hdata{"hport"})=split(":",$hdata{"url"});
			next;
		}
	}
	return %hdata;
}
sub parsFilter{
	my ($loginDir,%data)=@_;
	
	my $return=0;
	if(-f "$loginDir/filterHosts"){
		open F,"<$loginDir/filterHosts";
		while(my $str=<F>){
			if(substr($str,0,1) eq "#"){next;}
			chomp $str;
			my($type,$value)=split("	",$str);
			if(exists($data{"host"})){
				if($type eq "MATCH"){if($data{"host"} eq $value){$return=1;last;}}
				if($type eq "FIND"){if($data{"host"}=~/$value/){$return=1;last;}}
			}
		}
		close F;
	}
	if(-f "$datadir/filterHosts" and !$return){
		open F,"<$datadir/filterHosts";
		while(my $str=<F>){
			if(substr($str,0,1) eq "#"){next;}
			chomp $str;
			my($type,$value)=split("	",$str);
			if(exists($data{"host"})){
				if($type eq "MATCH"){if($data{"host"} eq $value){$return=1;last;}}
				if($type eq "FIND"){if($data{"host"}=~/$value/){$return=1;last;}}
			}
		}
		close F;
	}
	return $return;
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Гб";}}}}return $sz;}
sub sigExit{
	close SERVER;
	unlink $pidfile;
	print "\nHTTPS PROXY SERVER [ DEACTIVATED ]\n";
	unlink $pidfile;
	exit;
}
sub getHelp{
	print "=== Help Page for HttpsProxyServer by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-pidfile <FILE>			Determining PID file (default: ~/.run/httpsproxyserver.pid)
-datadir <DIR>			Catalog Data (If defined, the system automatically activates the reports and the distribution of access rights)
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($0);
	my $i=0;
	open FS,"<$0";while(my $tmp=<FS>){$i++;}close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
