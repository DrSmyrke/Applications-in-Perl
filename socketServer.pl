#!/usr/bin/perl
# socketServer, a simple Socket server, based on DrSmyrke
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
exit if ($^O eq 'MSWin32'); # windows must die;



### init data ###
my $mode=0;
my %ipTable;
my %settings;
$settings{"serverPort"}=25;
$settings{"pidfile"}="server.pid";




### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "--daemon"){$mode=1;}
	if($str eq "--stop"){stopApp();}
	if($str eq "-pidfile"){$settings{"pidfile"}=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();}
	$i++;
}



#####	MAIN	######
$SIG{INT}="sigExit";
$SIG{KILL}="sigExit";
#$SIG{CHILD}="IGNORE";
$SIG{TERM}="sigExit";
use Carp;
use Fcntl qw(:DEFAULT :flock);
use strict;
use IO::Socket;
use IO::Select;
my $ioset=IO::Select->new;

my $pid = check_proc($settings{"pidfile"});
if($pid){die "Proccess #$pid is running, NO EXECUTE DUBLICATE APPS!\n";exit;}
if($mode eq 0){mainLoop();}
if($mode eq 1){daemon();}
sigExit();



### FUNCTIONS ###
sub check_proc {
	my ($file) = @_;
	my $result;
    sysopen LOCK, $file, O_RDWR|O_CREAT or croak "Don`t open file $file: $!";
    if ( flock LOCK, LOCK_EX|LOCK_NB  ) {
        truncate LOCK, 0 or croak "Don`t lock file $file: $!";
        my $old_fh = select LOCK;
        $| = 1;
        select $old_fh;
        print LOCK $$;
    }
    else {
        $result = <LOCK>;
        if (defined $result) {
            chomp $result;
        }else{
            carp "PID not found in file $file";
            $result = '0 but true';
        }
    }
    return $result;
}
sub sendAllWithMe{
	my $socket=shift @_;
	my $mess=shift @_;
	foreach my $str($ioset->handles()){
		if($str eq \*SERVER or $str eq \*STDIN or $str eq $socket){next;}
		print $str $mess;
	}
}
sub mainLoop{
	print "SERVER [ ";
	socket(SERVER,PF_INET,SOCK_STREAM,getprotobyname('tcp')) or print " ERROR]\n" and die "I could not create socket! ]\n";
	setsockopt(SERVER,SOL_SOCKET,SO_REUSEADDR,1);
	bind(SERVER,sockaddr_in($settings{"serverPort"},INADDR_ANY)) or die " I can not bind port! ]\n";
	listen(SERVER,SOMAXCONN);
	print "ACTIVATED ] PID: [$$] PORT: [$settings{serverPort}]\n";
	$ioset->add(\*SERVER);
	$ioset->add(\*STDIN);
	while(1){
		for my $socket($ioset->can_read){
			if($socket eq \*SERVER){
				my $nc=accept(my $client,SERVER);
				$client->autoflush(1);
				$ioset->add($client);
				$ipTable{$client}{"ip"}=client_ip($nc);
				next;
			}
			my $read=$socket->sysread(my $buff,1024);
			if($socket eq \*STDIN){
				chomp $buff;
				if($buff eq "/stop"){stop();next;}
				if($buff eq "/list"){clients();next;}
				sendAllWithMe($socket,$buff);
			}
			if(!$read){	# DISCONNECT
				print "[$ipTable{$socket}{ip}] [$ipTable{$socket}{user}] >: disconneted\n";
				delete $ipTable{$socket};
				$ioset->remove($socket);
				close $socket;
				next;
			}
			print "[$ipTable{$socket}{ip}] [$ipTable{$socket}{user}] >: [$buff]\n";
			#tolog("$ipTable{$socket}{ip} $ipTable{$socket}{user} >: [$buff]");
		}
	}
	close SERVER;
}
sub daemon{
	print "DAEMON ... ";
	use POSIX qw(setsid);
	defined(my $rootPid = fork)   or die "Can't fork: $!";
	if($rootPid==0){
		setsid or die "Can't start a new session: $!";
		chdir '/' or die "Can't chdir to /: $!";
#		open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
#		open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
#		open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
		close STDIN;
		close STDOUT;
		close STDERR;
		mainLoop();
	}
	if($rootPid==-1){print " [ ERROR ]\n";}
	if($rootPid){print " [ STARTING A NEW SESSION ]\n";}
#	exit if $pid; # я родитель, если получен id дочернего процесса
	exit;
}
sub stopApp{
	open FS,"<$settings{pidfile}";my $pid=<FS>;close FS;chomp $pid;
	if($pid){
		print "KILLING [$pid]\n";
		kill 'TERM',$pid;
	}
	exit;
}
sub sigExit{
	close SERVER;
	print "\nSERVER [ DEACTIVATED ]\n";
	unlink $settings{"pidfile"};
	exit;
}
sub getHelp{
	print "=== Help Page for Server by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
--daemon			Run application as a daemon
--stop				Stopping the application
-pidfile <FILE>			Determining PID file (default: $settings{pidfile})
-p,--port <PORT>		Determination of the port which will be run a web server (default: $settings{serverPort})
";
	print "\n=== Thank you for choosing my application ===\n";
	my ($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($0);
	my $i=0;
	open FS,"<$0";
	while(my $tmp=<FS>){$i++;}
	close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
	exit 0;
}
sub getSize{my $st;my ($sz)=@_;if($sz<1024){$st="$sz  bytes";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Kb";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mb";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Gb";}}}}return $st;}
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
	#foreach my $val (keys %ipTable){$ioset->remove($val);close $val;}
	sigExit();
}
sub client_ip {
	my $client=shift @_;
	my ($client_port,$client_ip)=sockaddr_in($client);
	return inet_ntoa($client_ip);
}



=dsfdfg
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
sub tolog{
	my $mess=shift @_;
	if(!-d "logs"){mkdir "logs";}
	my ($sek,$min,$hour,$day,$mon,$year)=getTime();
	open fs,">>logs/$year-$mon-$day.log";
	print fs "[$hour:$min:$sek]	$mess\n";
	close fs;
}
sub http_headers{
my ($status,$cont,$size,$ctype,$conn)=@_;
if($ctype eq ""){$ctype="text/html; charset=UTF-8";}
if($size eq ""){$size=length($cont)}
if($conn eq ""){$conn="close";}
return <<RESPONSE;
HTTP/1.0 $status
Server: DrSmyrke Server
Content-type: $ctype
Content-Length: $size
Accept-Ranges: bytes
Connection: $conn


RESPONSE
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
