#!/usr/bin/perl
$SIG{INT}="sigExit";
$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
$pidfile="$ENV{HOME}/.run/daemon.pid";
$rootPid=$$;
$size=$oldSize=$ch=0;
### Parsing arguments ###
foreach $str(@ARGV){
	if($str eq "--stop"){stop(getMyPID($webserverpidfile));stop(getMyPID($pidfile));sigExit();}
}
sub sigExit{
	if($$ eq $rootPid){
		print "\nremove [$pidfile]";
		unlink $pidfile;
		print "\nExit\n";
		unlink $pidfile;
	}
	exit;
}
sub getDirSize{
	my $dir=shift @_;
	my $sz=0;
	$dir=~s/ /\\ /g;
	foreach my $elem(glob("$dir/*")){
		if(-d "$elem"){$sz+=getDirSize($elem);}
		if(-f "$elem"){(undef,undef,undef,undef,undef,undef,undef,my $fs)=stat($elem);$sz+=$fs;}
	}
	return $sz;
}
sub stop{
	$pid=shift @_;
	if($pid){
		print "KILLING [$pid]\n";
		kill 'TERM',$pid;
	}
}
print "DAEMON ... ";
use POSIX qw(setsid);
defined(my $rootPid = fork)   or die "Can't fork: $!";
if($rootPid==0){
	if(getMyPID($pidfile)){print "NO EXECUTE DUBLICATE APPS\n";exit;}
	setsid or die "Can't start a new session: $!";
#	chdir '/' or die "Can't chdir to /: $!";
#	open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
#	open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
#	open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
	close STDIN;
	close STDOUT;
	close STDERR;
	mainLoop();
}
if($rootPid==-1){print " [ ERROR ]\n";}
if($rootPid){print " [ STARTING A NEW SESSION ]\n";}
#system "$ENV{'HOME'}/bin/play.Зефште $ENV{'HOME'}/bin/data/sounds/Основные_системы_в_норме.wav";
sub getMyPID{
	$pidf=shift @_;
	$pid=0;
	if(!-d "$ENV{HOME}/.run"){mkdir "$ENV{HOME}/.run";}	
	if(!-f $pidf){
		print "\nCreate [$pidf] for [$$]\n";
		open fs,">$pidf";print fs "$$";close fs;
	}else{
		open fs,"<$pidf";$pid=<fs>;close fs;
	}
	return $pid;
}
sub mainLoop{
	while(1){
		# работа с мышью
		$cmd=`mouse`;chomp $cmd;
		($tmp,$tmp,$mx,$my,$tmp,$dx,$dy)=split(" ",$cmd);
		# запуск панели
		$r=($dx/2)-170;
		$tmp=($dx/2)+170;
		if($mx>=$r and $mx<=$tmp and $my<20){
			if(getPID2("MyPanel")=="N/A"){
				if(fork==0){exec "MyPanel";kill 'TERM',$$;}
			}
		}else{
			$pid=getPID2("MyPanel");
			if($pid!="N/A"){kill 'TERM',$pid;}
		}
		# запуск браузера
		#$r=$dx-$mx;
		#print getPID("/usr/bin/perl","confirm");
		#print "[$mx,$my,$dx,$dy]$r\n";
		#if($r<3 and $my < 3){
		#	if(getPID("/usr/bin/perl","confirm")=="N/A"){
		#		$cmd=`confirm Запустить браузер?`;chomp $cmd;
		#		if($cmd eq "true"){
		#			if(fork==0){exec "myBrowser http://ya.ru";kill 'TERM',$$;}
		#		}
		#	}
		#}
#		if($ch>15){
#			$size=getDirSize("$ENV{HOME}/.local/share/Trash");
#			if($size ne $oldSize){
#				$oldSize=$size;
#				if(fork==0){exec "trashSize.3eфште -size $size";kill 'TERM',$$;}
#			}
#			$ch=0;
#		}else{$ch++;}
		sleep 1;
	}
}
sub getPID3{
	$pid="N/A";
	$app=shift @_;
	@tmp=split("/",$app);
	$name=pop @tmp;
	$name=~s/[.]/_/g;
	$tmp="$ENV{HOME}/.run/$name.pid";
	if(-f $tmp){
		open fs,"<$tmp";
		$pid=<fs>;
		chomp($pid);
		close fs;
	}
	return $pid;
}
sub getPID2{
	($prg)=@_;
	@cmd=`ps -eo pid,cmd | grep "$prg"`;chomp @cmd;
	$find=0;
	foreach $str(@cmd){
		$str=~s/  / /g;$str=~s/  / /g;$str=~s/  / /g;$str=~s/  / /g;
		($pid,$cmd,$arg1,$arg2,$arg3,$arg4)=split(" ",$str);
		if($cmd=~/$prg/){
			$find=1;
			last;
		}
	}
	if($find eq 1){return  $pid;}else{return "N/A";}
}
sub getPID{
	($prg,$prg2)=@_;
	@cmd=`ps -eo pid,cmd | grep "$prg2"`;chomp @cmd;
	$find=0;
	foreach $str(@cmd){
		$str=~s/  / /g;$str=~s/  / /g;$str=~s/  / /g;$str=~s/  / /g;
		($pid,$cmd,$arg1,$arg2,$arg3,$arg4)=split(" ",$str);
		if($arg1=~/$prg2/){
			if($prg ne"" and $cmd=~/$prg/){
				$find=1;
				last;
			}
		}
	}
	if($find eq 1){return  $pid;}else{return "N/A";}
}
