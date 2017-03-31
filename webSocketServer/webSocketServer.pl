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
my $port=7300;
my (%ipTable,%users);
my $password="123456";
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
#$SIG{CHILD}="IGNORE";
$SIG{TERM}="sigExit";
my $usersdb="users.db";
my $pidfile="server.pid";
loadUsers();
#####	MAIN	######
use strict;
use utf8;
use IO::Socket;
use IO::Select;
use Digest::SHA qw(sha1 sha1_hex);
use MIME::Base64 qw(encode_base64);
my $ioset=IO::Select->new;
open fs,">$pidfile";print fs "$$";close fs;
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
			$ipTable{$client}{"connect"}=0;
			next;
		}
		my $read=$socket->sysread(my $buff,1024);
		if($socket eq \*STDIN){
			chomp $buff;
			if($buff eq "/stop"){stop();next;}
			if($buff eq "/list"){clients();next;}
			if($buff eq "/users"){getUsers();next;}
			if($buff eq "/save"){saveUsers();next;}
			if($buff eq "/load"){loadUsers();next;}
		}
		if(!$read){	# DISCONNECT
			#print "[$ipTable{$socket}{ip}] [$ipTable{$socket}{user}] >: disconneted\n";
			if(exists($ipTable{$socket}{"user"})){
				my $user=$ipTable{$socket}{"user"};
				$users{$user}{"status"}="OffLine";
				saveUsers();
			}
			delete $ipTable{$socket};
			$ioset->remove($socket);
			close $socket;
			next;
		}
		if(!$ipTable{$socket}{"connect"}){
			my ($browserHead)=split("\r\n\r\n",$buff);
			my %browserHeadData=parsHead($browserHead);
			if($browserHeadData{"Connection"}=~/upgrade/){
				my $key=$browserHeadData{"Sec-WebSocket-Key"}."258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
				$key=encode_base64(sha1($key));
				print $socket "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: $key\r\n\r\n";
				$ipTable{$socket}{"connect"}=1;
				next;
			}
		}
		if($ipTable{$socket}{"connect"}){	# connected accepted
			my ($fin,$opcode,$mask,$playloadLength,$maskKey,$bin);
			$buff=unpack("H*",$buff);
			my ($fin,$opcode,$mask,$playloadLength,$maskKey);
			my $bin=sprintf("%b",hex(substr($buff,0,2)));$buff=substr($buff,2);
			$fin=substr($bin,0,1);
			$opcode=substr($bin,4,4);
			$opcode=sprintf("%x",oct("0b$opcode"));
			$bin=sprintf("%b",hex(substr($buff,0,2)));$buff=substr($buff,2);
			$mask=substr($bin,0,1);
			$playloadLength=substr($bin,1,7);
			if(oct("0b$playloadLength") eq 126){
				$playloadLength.=sprintf("%b",hex(substr($buff,0,2)));
				$buff=substr($buff,2);
			}
			if(oct("0b$playloadLength") eq 127){
				$playloadLength.=sprintf("%b",hex(substr($buff,0,16)));
				$buff=substr($buff,16);
			}
			$playloadLength=oct("0b$playloadLength");
			if($mask eq 1){
				$maskKey=substr($buff,0,8);$buff=substr($buff,8);
				my $tmp;
				$buff=hex2bin($buff);
				$maskKey=hex2bin($maskKey);
				my $playload;
				while(length $buff){
					$tmp=substr($buff,0,length($maskKey));
					$playload.=XOR($tmp,$maskKey);
					$buff=substr($buff,length($maskKey));
				}
				$buff=bin2hex($playload);
			}
			if($opcode eq 1){}	#text frame
			$ipTable{$socket}{"data"}.=$buff;
			if($fin eq 1){
				$buff=$ipTable{$socket}{"data"};
				$buff=pack("H*",$buff);
				$ipTable{$socket}{"data"}="";
			}
		}
		my ($cmd,$param,$val1,$val2,$val3,$val4);
		if($cmd eq "stop" && $param eq $password){stop();}
		if($cmd eq "saveUsers" && $param eq $password){saveUsers();}
		if($cmd eq "loadUsers" && $param eq $password){loadUsers();}
		if($cmd eq "users"){users($socket);}
		if($cmd eq "userinfo"){userInfo($socket,$param);}
		if($cmd eq "exectopc" && $param eq $password){execToPc($val1,$val2);}
		if($cmd eq "exittopc" && $param eq $password){exitToPc($val1);}
		if($cmd eq "logoutpc" && $param eq $password){logoutPc($val1);}
		if($cmd eq "logoutuser" && $param eq $password){logoutUser($val1);}
		if($cmd eq "set"){
			$param=~tr/A-Z/a-z/;
			$ipTable{$socket}{"user"}=$param;
			$ipTable{$socket}{"pc"}=$val1;
			$users{$param}{"pc"}=$val1;
			$users{$param}{"status"}="OnLine";
		}
		
		print "[$ipTable{$socket}{ip}] [$ipTable{$socket}{user}] >: [$buff]\n";
		tolog("$ipTable{$socket}{ip} $ipTable{$socket}{user} >: [$buff]");
	}
}
sigExit();
## FUNCTIONS ###
sub XOR{
	my $str=shift @_;
	my $key=shift @_;
	if(length $str ne length $key){return "N/A";}
	my $out;
	my @am=split("",$str);
	my @bm=split("",$key);
	for(my $i=0;$i<length $str;$i++){
		my $a=$am[$i];
		my $b=$bm[$i];
		my $c;
		if(!$a and !$b){$c=0;}
		if(!$a and $b){$c=1;}
		if($a and !$b){$c=1;}
		if($a and $b){$c=0;}
		$out.=$c;
	}
	return $out;
}
sub bin2hex{
	my $bin=shift @_;
	my ($out,$tmp,$tmp2);
	while(length $bin){
		$tmp=substr($bin,0,8);
		#print ">:[$tmp]	";
		$tmp=sprintf("%x",oct("0b$tmp"));
		$tmp2="";
		for(my $i=length($tmp);$i<2;$i++){$tmp2.="0";}
		$tmp=$tmp2.$tmp;
		$out.=$tmp;
		#print "[$tmp]";
		$bin=substr($bin,8);
		#print "\n";
	}
	return $out;
}
sub hex2bin{
	my $hex=shift @_;
	my ($out,$tmp,$tmp2);
	while(length $hex){
		$tmp=substr($hex,0,2);
		#print ">:[$tmp]	[";
		$tmp=sprintf("%b",hex($tmp));
		#print length($tmp)."]	";
		$tmp2="";
		for(my $i=length($tmp);$i<8;$i++){$tmp2.="0";}
		$tmp=$tmp2.$tmp;
		$out.=$tmp;
		#print "[$tmp]";
		$hex=substr($hex,2);
		#print "\n";
	}
	return $out;
}
sub parsHead{
	my $data=shift @_;
	my %hdata;
	foreach my $str(split("\r\n",$data)){
		my ($param,$val)=split(": ",$str);
		if($param ne "Sec-WebSocket-Key"){$val=~tr/A-Z/a-z/;}
		if(substr($str,0,3) eq "GET" or substr($str,0,4) eq "POST"){
			($hdata{"method"},$hdata{"url"},$hdata{"http"})=split(" ",$str);
			$hdata{"url"}=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			(my $tmp)=split("://",$hdata{"url"});
			$hdata{"url"}=substr($hdata{"url"},(length($tmp)+3));
			next;
		}
		$hdata{"$param"}=$val;
	}
	return %hdata;
}
sub getUsersHtml{
	my $cont='<table width="100%">';
	my $i=0;
	foreach my $val (sort keys %users){
		my $status=($users{$val}{"status"} eq "OnLine")?"valgreen":"valorange";
		$cont.='<tr><td><a href="javascript:openUserUi(\''.$val.'\');">'.$val.'</a></td><td class="'.$status.'">'.$users{$val}{"status"}.'</td><td>'.$users{$val}{"pc"}.'</td></tr>';
		$i++;
	}
	$cont.="</table>Total: ".$i;
	return $cont;
}
sub getContext{
	my $content=shift @_;
	return "<!DOCTYPE html><html lang=\"ru\"><head><meta charset=\"utf-8\"/><title>-= DrSmyrke Server =-</title><style>body{font-family:Arial,Sans,Microsoft Sans Serif,consolas;font-size:10pt;}.form{margin:0px;display:inline-block;}.valgreen{text-shadow:0px 0px 5px #61FF62;color:#00FF03;}.valorange{	text-shadow:0px 0px 5px #FFB67B;color:#FF7200;}.valyellow{text-shadow:0px 0px 5px #EEEE73;color:#F3F200;}.valfiol{text-shadow:0px 0px 5px #D197FF;color:#AD6BE1;}.valred{text-shadow:0px 0px 5px #FF6E6B;color:#FF0600;}</style></head><body><center><span style=\"font-size:20pt;color:gray;\">-= UFK Server =-</span></center>$content</body></html>";
}
sub messToAll{
	my $type=shift @_;
	my $title=shift @_;
	my $mess=shift @_;
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		if(exists($ipTable{$str}{"pc"})){print $str "$type	$title	$mess";}
	}
}
sub logoutUser{
	my $user=shift @_;
	$user=~tr/A-Z/a-z/;
	if(exists($users{$user})){
		foreach my $str($ioset->handles()){
			if($str eq \*SERVER or $str eq \*STDIN){next;}
			if($ipTable{$str}{"user"} eq $user){print $str "logout";}
		}
	}
}
sub logoutPc{
	my $pc=shift @_;
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		if($ipTable{$str}{"pc"} eq $pc){print $str "logout";}
	}
}
sub exitToPc{
	my $pc=shift @_;
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		if($ipTable{$str}{"pc"} eq $pc){print $str "die";}
	}
}
sub userInfo{
	my $socket=shift @_;
	my $user=shift @_;
	$user=~tr/A-Z/a-z/;
	if(exists($users{$user})){print $socket "user:$user:$users{$user}{status}:$users{$user}{pc}";}
}
sub users{
	my $socket=shift @_;
	my @tmp;
	foreach my $val (keys %users){
		my $status=($users{$val}{"status"} eq "OnLine")?1:0;
		$val="$val;$status";
		push(@tmp,$val);
	}
	print $socket "users:".join("	",@tmp);
}
sub tolog{
	my $mess=shift @_;
	if(!-d "logs"){mkdir "logs";}
	my ($sek,$min,$hour,$day,$mon,$year)=getTime();
	open fs,">>logs/$year-$mon-$day.log";
	print fs "[$hour:$min:$sek]	$mess\n";
	close fs;
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
sub execToPc{
	my $pc=shift @_;
	my $cmd=shift @_;
	$cmd=~tr/_/:/;
	$cmd=~s#%20# #g;
	$cmd=~s#%22#"#g;
	$cmd=~s#=SEPARATOR=#/#ig;
	print "exec to $pc [$cmd]\n";
	tolog("exec to $pc [$cmd]");
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		if($ipTable{$str}{"pc"} eq $pc){
			print $str "exec	$cmd";
			last;
		}
	}
}
sub messToPc{
	my $type=shift @_;
	my $pc=shift @_;
	my $title=shift @_;
	my $mess=shift @_;
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		if($ipTable{$str}{"pc"} eq $pc){
			print $str "$type	$title	$mess";
			last;
		}
	}
}
sub messToUser{
	my $type=shift @_;
	my $user=shift @_;
	my $title=shift @_;
	my $mess=shift @_;
	$user=~tr/A-Z/a-z/;
	if(exists($users{$user})){
		if($users{$user}{"status"} eq "OnLine"){
			foreach my $str($ioset->handles()){
				if($str eq \*SERVER or $str eq \*STDIN){next;}
				if($ipTable{$str}{"pc"} eq $users{$user}{"pc"}){
					print $str "$type	$title	$mess";
					last;
				}
			}
		}
	}
}
sub loadUsers{
	open fs,"<$usersdb";
	while(my $str=<fs>){
		chomp $str;
		my ($login,$pc,$status,$grp)=split("	",$str);
		$users{$login}{"pc"}=$pc;
		$users{$login}{"status"}=$status;
		$users{$login}{"groups"}=$grp;
	}
	close fs;
}
sub saveUsers{
	open fs,">$usersdb";
	foreach my $val (keys %users){
		print fs "$val	$users{$val}{pc}	$users{$val}{status}	$users{$val}{groups}\n";
	}
	close fs;
}
sub getUsers{
	print "\033[0;35m===========================: \033[0;37mUsers \033[0;35m:============================\n";
	my ($i,$online)=(0,0);
	foreach my $val (keys %users){
		my $status=$users{$val}{"status"};
		my $add=($status eq "OnLine")?"\e[1;32m":"\e[1;31m";
		if($status eq "OnLine"){$online++;}
		print "\033[0;37m[$val]	\033[1;32m$users{$val}{pc}	$add$status\n";
		$i++;
	}
	print "\033[0;37mOnLine: \033[1;32m".$online."/".$i."\n";
	print "\033[0;35m================================================================\033[m\n";
}
sub clients{
	print "\033[0;35m==========================: \033[0;37mClients \033[0;35m:===========================\n";
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN){next;}
		print "\033[0;37m[$ipTable{$str}{ip}]	\033[1;32m$ipTable{$str}{user}	$ipTable{$str}{pc}\n";
	}
	print "\033[0;37mTotal: \033[1;32m".($ioset->count()-2)."\n";
	print "\033[0;35m================================================================\033[m\n";
}
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
	#snd("KILL");
	saveUsers();
	close SERVER;
	print "\nSERVER [ DEACTIVATED ]\n";
	unlink $pidfile;
	exit;
}
