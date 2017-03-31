#!/usr/bin/perl
# httpProxyServer, a simple HTTP Proxy server, based on DrSmyrke
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
my $port=7302;
my $version="0.1";
my $pidfile="$ENV{HOME}/.run/httpproxyserver.pid";
my ($datadir,$anonym,$statMode);
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-anonym"){$anonym=1;}
	if($str eq "-pidfile"){$pidfile=$ARGV[$i+1];}
	if($str eq "-datadir"){$datadir=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
if($datadir and !-d $datadir){mkdir $datadir;}
if($datadir and -d $datadir){$statMode=1;}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use MIME::Base64;
print "PROXY SERVER [ ";
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
		my ($data,$browserHead,$serverHead,%PAuth,$tunnel,%browserHeadData,%serverHeadData,%stats);
		while(1){
			my $count=sysread(BROWSER,$data,4096);
			if(!$count){disconnect($clientip,%stats,%PAuth);}
			if(!$browserHead){
				($browserHead)=split("\r\n\r\n",$data);
				$data=substr($data,length($browserHead));
				%browserHeadData=parsHead($browserHead);
				if(!$browserHeadData{"url"} or !$browserHeadData{"host"}){
					genError("400 Bad Request");
					$browserHead=undef;
					disconnect($clientip,%stats,%PAuth);
				}
				my $loginDir=(exists($PAuth{"PAuthL"}))?"$datadir/users/$PAuth{PAuthL}":"$datadir/ip/$clientip";
				my $block=parsFilter($loginDir,%browserHeadData);
				if($block){genBlock();$browserHead=undef;disconnect($clientip,%stats,%PAuth);}
				$data="$browserHeadData{head}$data";
				$tunnel=1;
			}
			if($statMode){
				$stats{"outputData"}+=$count;
				my @tmp=glob("$datadir/users/*");my $users=@tmp;
				if($users){
					if(!exists($PAuth{"PAuth"}) and exists($browserHeadData{"PAuth"})){
						my $auth=parsAuth(%browserHeadData);
						if($auth){
							$PAuth{"PAuth"}=$browserHeadData{"PAuth"};
							$PAuth{"PAuthType"}=$browserHeadData{"PAuthType"};
							$PAuth{"PAuthL"}=$browserHeadData{"PAuthL"};
							$PAuth{"PAuthP"}=$browserHeadData{"PAuthP"};
						}
					}
					if(!exists($PAuth{"PAuth"})){sndNoAuth();$browserHead=undef;disconnect($clientip,%stats,%PAuth);}
					my $loginDir=(exists($PAuth{"PAuthL"}))?"$datadir/users/$PAuth{PAuthL}":"$datadir/ip/$clientip";
					my $block=parsFilter($loginDir,%browserHeadData);
					if($block){genBlock();$browserHead=undef;disconnect($clientip,%stats,%PAuth);}
				}
			}
			if($tunnel){
				my ($host,$oport)=split(":",$browserHeadData{"host"});
				if(!$oport){$oport=80;}
				my $ip=Socket::inet_ntoa((gethostbyname($host))[4]);
				if(!$ip){$ip=$host;}
				socket(SOCK,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
				print ">: [$clientip] Connect to $ip:$oport...";
				if(connect(SOCK,sockaddr_in($oport,inet_aton($ip)))){
					print " OK\n";
				}else{
					print " ERROR\n";
					genError("502 Bad Gateway");
					$browserHead=undef;
					disconnect($clientip,%stats,%PAuth);
				}
				$tunnel=0;
			}
			if(fileno SOCK){send(SOCK,$data,0);}
			if($count<4096){# recieve data from server
				while(my $rcount=sysread(SOCK,my $rdata,4096)){
					if(!$serverHead){
						($serverHead)=split("\r\n\r\n",$rdata);
						$rdata=substr($rdata,length($serverHead));
						%serverHeadData=parsHead($serverHead);
						if(substr($rdata,0,2) eq "\r\n"){$rdata=substr($rdata,2);}
						my $loginDir=(exists($PAuth{"PAuthL"}))?"$datadir/users/$PAuth{PAuthL}":"$datadir/ip/$clientip";
						my $block=parsFilter($loginDir,%serverHeadData);
						if($block){genBlock();last;}
						$rdata="$serverHeadData{head}$rdata";
						my ($sek,$min,$hour,$day,$mon,$year)=getTime();
						$stats{"history"}.="[$hour:$min:$sek]	$browserHeadData{method}	$browserHeadData{host}	$browserHeadData{url}	$serverHeadData{code}\n";
					}
					if($statMode){
						$stats{"inputData"}+=$rcount;
						if($serverHeadData{"ContentType"}){
							$stats{"mimeStat"}{$serverHeadData{"ContentType"}}+=$rcount;
						}
						$stats{"hostStat"}{$browserHeadData{"host"}}+=$rcount;
					}
					print BROWSER $rdata;
				}
				$browserHead=$serverHead=undef;
				if($browserHeadData{"Conn"} eq "close" or $serverHeadData{"Conn"} eq "close"){close SOCK;}
				if($browserHeadData{"PConn"} eq "close"){
					disconnect($clientip,%stats,%PAuth);
				}
			}
		}
	}
}
sigExit();
### FUNCTIONS ###
sub parsFilter{
	my ($loginDir,%data)=@_;
	my $return=0;
	if(-f "$loginDir/filter"){
		open F,"<$loginDir/filter";
		while(my $str=<F>){
			if(substr($str,0,1) eq "#"){next;}
			chomp $str;
			my($param,$type,$value)=split("	",$str);
			if(exists($data{$param})){
				if($param eq "ContentType"){$value=~s/\//"zzz"/eg;}
				if($type eq "MATCH"){if($data{$param} eq $value){$return=1;last;}}
				if($type eq "FIND"){if($data{$param}=~/$value/){$return=1;last;}}
			}
		}
		close F;
	}
	if(-f "$datadir/filter" and !$return){
		open F,"<$datadir/filter";
		while(my $str=<F>){
			if(substr($str,0,1) eq "#"){next;}
			chomp $str;
			my($param,$type,$value)=split("	",$str);
			if(exists($data{$param})){
				if($param eq "ContentType"){$value=~s/\//"zzz"/eg;}
				if($type eq "MATCH"){if($data{$param} eq $value){$return=1;last;}}
				if($type eq "FIND"){if($data{$param}=~/$value/){$return=1;last;}}
			}
		}
		close F;
	}
	return $return;
}
sub disconnect{
	my ($ip,%stats)=@_;
	print ">: [$ip] Disconnected PID: [$$]\n";
	if($statMode){
		my ($sek,$min,$hour,$day,$mon,$year)=getTime();
		if(!-d "$datadir/ip"){mkdir "$datadir/ip";}
		if(!-d "$datadir/users"){mkdir "$datadir/users";}
		my $loginDir=($stats{"PAuthL"})?"$datadir/users/$stats{PAuthL}":"$datadir/ip/$ip";
		if(!-d $loginDir){mkdir $loginDir;}
		if(!-d "$loginDir/stats"){mkdir "$loginDir/stats";}
		if(!-d "$loginDir/stats/$year"){mkdir "$loginDir/stats/$year";}
		if(!-d "$loginDir/stats/$year/$mon"){mkdir "$loginDir/stats/$year/$mon";}
		if(!-d "$loginDir/stats/$year/$mon/$day"){mkdir "$loginDir/stats/$year/$mon/$day";}
		my $workDir="$loginDir/stats/$year/$mon/$day";
		if(-f "$workDir/inputData"){
			open F,"<$workDir/inputData";my $v=<F>;close F;chomp $v;
			$stats{"inputData"}+=$v;
		}
		open F,">$workDir/inputData";print F $stats{"inputData"};close F;
		if(-f "$workDir/outputData"){
			open F,"<$workDir/outputData";my $v=<F>;close F;chomp $v;
			$stats{"outputData"}+=$v;
		}
		open F,">$workDir/outputData";print F $stats{"outputData"};close F;
		if(-f "$workDir/mimeStat"){
			open F,"<$workDir/mimeStat";
			while(my $v=<F>){
				chomp $v;
				my ($val,$data)=split("	",$v);
				$stats{"mimeStat"}{$val}+=$data;
			}
			close F;
		}
		open F,">$workDir/mimeStat";
		foreach my $str(keys $stats{"mimeStat"}){my $nam=$str;$nam=~s/zzz/\//;print F "$nam	$stats{mimeStat}{$str}\n";}
		close F;
		if(-f "$workDir/hostStat"){
			open F,"<$workDir/hostStat";
			while(my $v=<F>){
				chomp $v;
				my ($val,$data)=split("	",$v);
				$stats{"hostStat"}{$val}+=$data;
			}
			close F;
		}
		open F,">$workDir/hostStat";
		foreach my $str(keys $stats{"hostStat"}){print F "$str	$stats{hostStat}{$str}\n";}
		close F;
		open F,">>$workDir/history";print F $stats{"history"};close F;
	}
	if(fileno SOCK){close BROWSER;}
	close BROWSER;kill 'TERM',$$;
}
sub getTime{
	my ($sek,$min,$hour,$day,$mon,$year)=localtime;
	$mon++;
	$year+=1900;
	if($day<10){$day="0$day";}
	if($mon<10){$mon="0$mon";}
	if($hour<10){$hour="0$hour";}
	if($min<10){$min="0$min";}
	if($sek<10){$sek="0$sek";}
	return ($sek,$min,$hour,$day,$mon,$year);
}
sub sndNoAuth{
	print BROWSER "HTTP/1.1 407 Unauthorized\r\nContent-Length: 21\r\nProxy-Authenticate: Basic realm=ProxyAuth\r\nConnection: Close\r\n\r\n<h1>Unauthorized</h1>\r\n";
}
sub genBlock{
	my $text='<h1>Content is bocked</h1><b>Call to unblock from 3009</b>';
	print BROWSER "HTTP/1.1 200 OK\r\nContent-Length: ".length($text)."\r\nConnection: Close\r\n\r\n$text\r\n";
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
		if($param eq "Proxy-Connection"){$val=~tr/A-Z/a-z/;$hdata{"PConn"}=$val;next;}
		if($param eq "Connection"){$val=~tr/A-Z/a-z/;$hdata{"Conn"}=$val;}
		if($param eq "Content-Type"){$val=~s/\//"zzz"/eg;($hdata{"ContentType"})=split(";",$val);}
		if($anonym and $param eq "User-Agent"){next;}
#		if($anonym and $param eq "Referer"){next;}
		if($param eq "Proxy-Authorization"){
			(undef,$hdata{"PAuthType"},$hdata{"PAuth"})=split(" ",$str);
			($hdata{"PAuthL"},$hdata{"PAuthP"})=split(":",decode_base64($hdata{"PAuth"}));
			next;
		}
		if($param eq "Host"){$val=~s/\///eg;$hdata{"host"}=$val;}
		if(substr($str,0,4) eq "HTTP"){
			(undef,$hdata{"code"},$hdata{"mess"})=split(" ",$str);
		}
		if(substr($str,0,3) eq "GET" or substr($str,0,4) eq "POST"){
			($hdata{"method"},$hdata{"url"},$hdata{"http"})=split(" ",$str);
			$hdata{"url"}=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			(my $tmp)=split("://",$hdata{"url"});
			$hdata{"url"}=substr($hdata{"url"},(length($tmp)+3));
			next;
		}
		$hdata{"head"}.="$str\r\n";
	}
	if($hdata{"host"}){$hdata{"url"}=~s/$hdata{host}//eg;$hdata{"hurl"}=$hdata{"host"};}
	if($hdata{"url"}){$hdata{"hurl"}.=$hdata{"url"};$hdata{"head"}="$hdata{method} $hdata{url} $hdata{http}\r\n".$hdata{"head"};}	
	return %hdata;
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Гб";}}}}return $sz;}
sub sigExit{
	close SERVER;
	unlink $pidfile;
	print "\nHTTP PROXY SERVER [ DEACTIVATED ]\n";
	unlink $pidfile;
	exit;
}
sub getHelp{
	print "=== Help Page for HttpProxyServer by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-pidfile <FILE>			Determining PID file (default: ~/.run/httpproxyserver.pid)
-anonym				Anonymous mode
-datadir <DIR>			Catalog Data (If defined, the system automatically activates the reports and the distribution of access rights)
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($0);
	my $i=0;
	open FS,"<$0";while(my $tmp=<FS>){$i++;}close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
