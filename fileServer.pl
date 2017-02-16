#!/usr/bin/perl
# FileServer, a simple HTTP server for transfer file, based on DrSmyrke
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
# Абсолютный путь для рабочей директории
my $dataFolder="$ENV{'HOME'}/Desktop";
# Порт приема входящих подключений
my $port=7301;
# Объем передаваемых данных сервером (в байтах)
my $sendfpaket=4096;
# Объем принимаемых данных сервером (в байтах)
my $inputfpaket=4096;
my $version="2.0";
my $pidfile="$ENV{HOME}/.run/fileserver.pid";
our $serverPid=$$;
$SIG{INT}="sigExit";
#$SIG{TERM}="sigExit";
$SIG{KILL}="sigExit";
$SIG{CHLD}="IGNORE";
### Parsing arguments ###
$i=0;
foreach $str(@ARGV){
	if($str eq "-folder"){$dataFolder=$ARGV[$i+1];}
	if($str eq "-pidfile"){$pidfile=$ARGV[$i+1];}
	if($str eq "-p" or $str eq "--port"){$port=$ARGV[$i+1];}
	if($str eq "-h" or $str eq "--help"){getHelp();exit;}
	$i++;
}
### MAIN ###
use strict;
use IO::Socket;
use IO::Handle;
use MIME::Base64;
print "WEB SERVER [";
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or print " ERROR ]\n" and die "I could not create socket!\n";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
my $myaddr=sockaddr_in($port, INADDR_ANY);
bind(SERVER, $myaddr) or die "I can not bind port!\n"; 
listen(SERVER, SOMAXCONN);
print " ACTIVATED ] PID: [$$] PORT: [$port]\n";
open F,">$pidfile";print F $$;close F;
print "Waiting for connection...\n";
while(my $client_addr=accept(CLIENT, SERVER)){
	my ($client_port,$client_ip) = sockaddr_in($client_addr);
	our $client_ipnum = inet_ntoa($client_ip);
#	my $client_host = gethostbyaddr($client_ip, PF_INET);
	if(fork==0){
		my $input=my $inputSize=0;my $content=0;
		my ($boundary,$head,$url,$aurl,$postCmd,$postFile);
		print ">: [${client_ipnum}] Connected PID: [$$]\n";
		CLIENT->autoflush(1);
		while(1){
			my $count=sysread(CLIENT,my $data,$inputfpaket);
			if($count eq 0 or $count eq ""){
				print ">: [${client_ipnum}] Disconnected PID: [$$]\n";close CLIENT;kill 'TERM',$$;
			}
			print "[${client_ipnum}]	PID:[$$],".getSize($count)."\n";
			# pars data
			if(!$input){
				($head)=split("\r\n\r\n",$data);
				($url,$input,$inputSize,$boundary,my $auth)=parsHead($head);
				# no input data
				if(!$input){
					$aurl="$dataFolder$url";
					my @tmp=split("/",$url);my $file=pop(@tmp);
					if($file eq ".htpasswd" or $file eq ".htaccess"){e404($url);}
					if(!-e $aurl){e404($url);}
					my ($status,$htfile)=chkAccess($url);
					my $authStatus;
					if($status and !$auth){eAuth($htfile);}
					if($status and $auth){$authStatus=pAuth($auth,$htfile);}
					if($status and !$authStatus){eAuth($htfile);}
					if(-e $aurl and -r $aurl){
						if(-d $aurl){getFileList($aurl,$url);}
						if(-f $aurl){getFile($aurl);}
					}
					if(-e $aurl and !-r $aurl){e403($url);}
				}
			}
			if($input){
				if(!$aurl){$aurl="$dataFolder$url";}
				if($head){$data=substr($data,(length($head)+4));$head=undef;}
				# input post data
				if($input and !$boundary){
					$content+=length($data);
					if(!$postCmd and !$postFile){
						($postCmd,$postFile)=split("&",$data);
						(undef,$postCmd)=split("=",$postCmd);
						(undef,$postFile)=split("=",$postFile);
						$postFile=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
						if($postCmd eq "saveFile" and -e "$dataFolder$postFile"){
							if(-w "$dataFolder$postFile"){unlink "$dataFolder$postFile";}
						}
						(my $param)=split("&data=",$data);
						$data=substr($data,length($param)+6);
					}
					if($postCmd eq "saveFile" and $postCmd and $postFile){
						$data=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
						$data=~s/===SPACE===/ /g;
						open F,">>$dataFolder$postFile";print F $data;close F;
					}
				}
				# input FILE data
				if($input and $boundary){
					select(undef,undef,undef,0.0000025);
					$content+=length($data);
					if(!-e "$aurl/$boundary"){
						print "[${client_ipnum}] >>> PID:[$$] INPUT FILE: [$aurl$boundary]\n";
						open F,">$aurl/$boundary";binmode F;print F $data;close F;
					}else{
						open F,">>$aurl/$boundary";binmode F;print F $data;close F;
					}
				}
				print "[${client_ipnum}] >>> PID:[$$] receiving the data: [".getSize($content)." / ".getSize($inputSize)."] ".substr($content/$inputSize*100,0,5)."%\n";
				if($content>=$inputSize){
					if($input and !$boundary){
						$input=undef;
						print "[${client_ipnum}] >>> PID:[$$] $postCmd: [$postFile] complete\n";
						if($postCmd){$postCmd=undef;}
						if($postFile){$postFile=undef;}
					}
					print "[${client_ipnum}] >>> PID:[$$] PARSING FILE: [$aurl/$boundary]\n";
					open TF,"<$aurl/$boundary";
					binmode TF;
					my $filename;
					my $rnSkip=0;
					my $tData;
					while($data=<TF>){
						if($data=~/$boundary/){
							open F,">>$aurl/$filename";binmode F;print F substr($tData,0,-2);close F;
							$tData=undef;
							$filename=undef;$rnSkip=1;next;
						}
						if($data=~/Content-Disposition: form-data;/ and $rnSkip){
							$filename=getFilename($data);
							next;
						}
						if($data=~/Content-Type:/ and $rnSkip){next;}
						if($data eq "\r\n" and $rnSkip){$rnSkip=0;next;}
						#print "[$filename] [$tData] [$data]\n";
						if($filename){open F,">>$aurl/$filename";binmode F;print F $tData;close F;}
						$tData=$data;
						select(undef,undef,undef,0.000002);
					}
					close TF;
					unlink "$aurl/$boundary";
					$input=$inputSize=$content=0;$boundary=undef;
					getFileList($aurl,$url);
				}
			}
		}
	}
}

sigExit();
### FUNCTIONS ###
sub getFilename{
	my $cont=shift @_;
	my $fname;
	(undef,$fname)=split('filename="',$cont);
	($fname)=split('"',$fname);
	return $fname;
}
sub getFile{
	my $url=shift @_;
	my $mimeType="application/octet-stream";
	my @tm=split("[.]",$url);my $rash=pop @tm;$rash=~tr/A-Z/a-z/;
	if($rash eq "jpeg" or $rash eq "jpg"){$mimeType="image/jpeg";}
	if($rash eq "txt" or $rash eq "log" or $rash eq "ini"){$mimeType="text/plain";}
	if($rash eq "html" or $rash eq "htm"){$mimeType="text/html";}
	if($rash eq "png"){$mimeType="image/png";}
	if($rash eq "gif"){$mimeType="image/gif";}
	if($rash eq "mpeg" or $rash eq "mp4" or $rash eq "mpg"){$mimeType="video/mpeg";}
	if($rash eq "avi"){$mimeType="video/avi";}
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($url);
	my $buffer;
	my $sztek=0;
	my $tmp=0;
	my $t=0;
	my $sp=0;
	my $prz=0;
	print CLIENT http_headers('200 OK',undef,$size,$mimeType,"close","Retry-After: 1");
	(my $sec)=localtime;
	open FS,"<$url";
	while(read FS,$buffer,$sendfpaket){
		(my $sec2)=localtime;
		if($sec2!=$sec){
			$prz=substr($sztek/$size*100,0,5);
			$sp=$sztek-$tmp;
			$t=substr(($size-$sztek)/$sp,0,5);
			print "<<<	PID:[$$]	FILE	$url,".getSize($sztek)." / ".getSize($size).",$prz%,[".getSize($sp)."/s],$t sec\n";
			$tmp=$sztek;
			$sec=$sec2;
		}
		$sztek+=$sendfpaket;
		print CLIENT $buffer;
	}
	close FS;
	print "<<<	PID:[$$]	FILE	$url,$mimeType,".getSize($size)." 100%\n";
}
sub getFileList{
	my $aurl=shift @_;
	my $url=shift @_;
#	my $adm=shift @_;
	my %edb=qw(txt log html php ini cfg sh pls pl htm);
	if($url eq "/"){$url="";}
	my $target;my $type;my @tmp;
	my $cont="";my $tmp2="";
	$cont.='<a href="/" style="font-size:18pt;"><b>/</b></a> ';
	my $i=0;
	foreach my $tmp(split("/",$url)){
		if($tmp eq ""){next;}
		$tmp2.="/$tmp";
		if($i eq 0){$cont.='<a href="/'.$tmp.'">'.$tmp.'</a> ';}else{$cont.='<a href="'.$tmp2.'">/'.$tmp.'</a> ';}
		$i++;
	}
	$cont.='<table width="100%"><tr><td><b>Name</b></td><td width="70px" align="center"><b>Size</b></td><td width="70px" align="center"><b>Created</b></td><td width="70px" align="center"><b>Access</b></td><td width="70px" align="center"><b>Modify</b></td><td width="30px"><b>Mod</b></td><td width="40px"></td></tr>';
	$aurl=~s/ /\\ /g;
	if(substr($aurl,-1) eq "/"){$aurl=substr($aurl,0,-1);}
	foreach my $file(glob("$aurl/*")){
		my @tm=split("[.]",$file);my $rash=pop @tm;$rash=~tr/A-Z/a-z/;
		my $editor=(exists $edb{$rash} and -w $file and -f $file)?1:0;
		#($device,$inode,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($file);
		(undef,undef,my $mode,undef,undef,undef,undef,my $size,my $atime,my $mtime,my $ctime)=stat($file);
		if(-f $file){$target=' target="_blank"';$type="[F]";}
		if(-d $file){$target='';$type="[D]";$size=getDirSize($file);}
		$mode=sprintf("%04o",$mode&07777);
		@tmp=localtime($ctime);my $ctime=$tmp[3].".".(1+$tmp[4]).".".(1900+$tmp[5]);
		@tmp=localtime($atime);my $atime=$tmp[3].".".(1+$tmp[4]).".".(1900+$tmp[5]);
		@tmp=localtime($mtime);my $mtime=$tmp[3].".".(1+$tmp[4]).".".(1900+$tmp[5]);
		@tmp=split("/",$file);my $name=pop @tmp;
		$cont.='<tr><td>'.$type.' <a href="'.$url.'/'.$name.'"'.$target.'>'.$name.'</a></td><td>'.getSize($size).'</td><td>'.$ctime.'</td><td>'.$atime.'</td><td>'.$mtime.'</td><td>'.$mode.'</td><td>';
		if($editor){$cont.='<a href="javascript:editF(\''.$url.'/'.$name.'\');">[EDIT]</a>';}
		$cont.='</td></tr>';
	}
	$cont.='</table><hr>';
	$aurl=~s/\\ / /g;
	if(-w $aurl){$cont.='<form action="'.$url.'/" method="POST" enctype="multipart/form-data"><input type="file" name="file" multiple> <input type="submit" value="Upload"></form>';}
	$cont.='<div style="background:rgba(0,0,0,0.7);width:100%;height:100%;position:fixed;top:0px;left:0px;display:none;text-align:center;vertical-align:center;color:white;" id="textEditor">
	<br><br>File: <b>[<span id="fname"></span>]</b><br>
	<form action="'.$url.'" method="POST" onSubmit="return chk(this);">
	<input type="hidden" name="cmd" value="saveFile">
	<input type="hidden" name="file" id="saveFile">
	<textarea id="text" name="data" cols="80" rows="20" wrap="off" onkeydown="insertTab(event,this);"></textarea><br><br>
	<input type="submit" value="SAVE"> &#160;&#160;&#160; | &#160;&#160;&#160; <input type="button" value="CLOSE" onClick="closeF();">
	</form></div>';
	$cont.='<script type="text/javascript">var request=makeHttpObject();
function makeHttpObject() {
	try {return new XMLHttpRequest();}
	catch (error) {}
	try {return new ActiveXObject("Msxml2.XMLHTTP");}
	catch (error) {}
	try {return new ActiveXObject("Microsoft.XMLHTTP");}
	catch (error) {}
	throw new Error("Could not create HTTP request object.");
}
function editF(file){
	request.open("GET",file,false);
	request.send(null);
	var text=request.responseText.replace(/	/g,"     ");
	document.getElementById("textEditor").style.display="block";
	document.getElementById("text").innerHTML=text;
	document.getElementById("text").focus();
	document.getElementById("fname").innerHTML=file;
	document.getElementById("saveFile").value=file;
	document.body.style.overflow="hidden";
}
function closeF(){
	document.getElementById("text").innerHTML="";
	document.getElementById("fname").innerHTML="";
	document.getElementById("saveFile").value="";
	document.getElementById("textEditor").style.display="none";
	document.body.style.overflow="";
}
function chk(obj){
	//obj.data.value=obj.data.value.replace(/     /g,"	");
	obj.data.value=obj.data.value.replace(/ /g,"===SPACE===");
	return true;
}
function insertTab(evt,obj){		
	evt=evt || window.event;
	var keyCode=evt.keyCode || evt.which || 0;
	if(keyCode==9){
		if(document.selection){
			document.selection.createRange().duplicate().text="\t";
		}else if(obj.setSelectionRange){
			var strFirst=obj.value.substr(0,obj.selectionStart);
			var strLast=obj.value.substr(obj.selectionEnd,obj.value.length);
			obj.value=strFirst+"\t"+strLast;
			var cursor=strFirst.length+"\t".length;
			obj.selectionStart = obj.selectionEnd = cursor;
		}
		if(evt.preventDefault && evt.stopPropagation){
			evt.preventDefault();
			evt.stopPropagation();
		}else{
			evt.returnValue = false;
			evt.cancelBubble = true;
		}
		return false;
	}
}
	</script>';
	$cont=getContext($cont);
	print CLIENT http_headers('200 OK',$cont).$cont;print "<<<	PID:[$$]	$url/,".getSize(length($cont))."\n";
}
sub getDirSize{
	my $dir=shift @_;
	my $size=0;
	$dir=~s/ /\\ /g;
	foreach my $elem(glob("$dir/*")){
		if(-d "$elem"){$size+=getDirSize($elem);}
		if(-f "$elem"){(undef,undef,undef,undef,undef,undef,undef,my $fs)=stat($elem);$size+=$fs;}
	}
	return $size;
}
sub http_headers{
(my $status,my $cont,my $size,my $ctype,my $conn,my $auth)=@_;
if($ctype eq ""){$ctype="text/html; charset=UTF-8";}
if($size eq ""){$size=length($cont)}
if($conn eq ""){$conn="keep-alive";}
return <<RESPONSE;
HTTP/1.0 $status
Server: DrSmyrke File Server $version
Content-type: $ctype
Content-Length: $size
Accept-Ranges: bytes
Connection: $conn
$auth

RESPONSE
}
# процедура обработки ошибки 404
sub e404{my $url=shift @_;my $cont=getContext("<br>$url<hr>ERROR 404 (File not Found/Файл не найден)");print CLIENT http_headers('404 Forbidden',$cont).$cont;print "PID:[$$]	<<<	404 ERROR\n";}
# процедура обработки ошибки 403
sub e403{my $url=shift @_;my $cont=getContext("<br>$url<hr>ERROR 403 (Access Denied/Нет доступа)");print CLIENT http_headers('403 Forbidden',$cont).$cont;print "PID:[$$]	<<<	403 ERROR\n";}
# процедура обработки авторизации
sub eAuth{
	my $file=shift @_;
	my $auth="WWW-Authenticate: TYPE realm=NAME";
	open F,"<$file";
	while(my $cont=<F>){
		(my $param,my $val)=split(" ",$cont);
		if($param eq "AuthType"){$auth=~s/TYPE/$val/g;}
		if($param eq "AuthName"){$auth=~s/NAME/$val/g;}
	}
	close F;
	my $cont=getContext("<h1>Unauthorized</h1>");
	print CLIENT http_headers('401 Unauthorized',$cont,length($cont),"","close",$auth).$cont;
	close CLIENT;kill 'TERM',$$;
}
sub pAuth{
	my ($auth,$htfile)=@_;
	my ($login,$pass)=split(":",decode_base64($auth));
	my $htaccess=undef;
	my @users=undef;
	open F,"<$htfile";
	while(my $str=<F>){
		chomp $str;
		if(substr($str,0,1) eq "#"){next;}
		(my $elem,my $val)=split(" ",$str);
		if($elem eq "AuthUserFile"){$htaccess=$val;}
		if($elem eq "Require" and $val eq "user"){
			(undef,my $val)=split("Require user ",$str);
			@users=split(" ",$val);
		}
	}
	close F;
	if(!$htaccess or !$users[0]){eAuth($htfile);return 0;}
	my $auth=0;
	open F,"<$dataFolder$htaccess";
	while(my $str=<F>){
		chomp $str;
		if(substr($str,0,1) eq "#"){next;}
		my ($l,$p)=split(":",$str);
		if($l eq $login and $p eq $pass){$auth=1;last;}
	}
	close F;
	return $auth;
}
sub parsHead{
	my $head=shift @_;
	my $url;
	my $type;
	my $input;
	my $inputSize;
	my $boundary;
	my $auth;
	foreach my $str(split("\r\n",$head)){
		(my $param,my $val,my $add)=split(" ",$str);
		if($param eq "GET" or $param eq "POST"){
			$url=$val;$url=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			$type=$param;
		}
		if($param eq "Content-Length:"){$input=1;$inputSize=$val;}
		if($param eq "Authorization:"){$auth=$add;}
		if($param eq "Content-Type:" and $val eq "multipart/form-data;"){
			(undef,$boundary)=split("boundary=",$str);
		}
	}
	print ">>>	PID:[$$]	$type	[$url]\n";
	return ($url,$input,$inputSize,$boundary,$auth);
}
sub getSize{(my $sz)=@_;if($sz<1024){return "$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);return "$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);return "$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);return "$sz Гб";}}}}return $sz;}
sub sigExit{
	close SERVER;
	unlink $pidfile;
	print "\nWEB SERVER [ DEACTIVATED ]\n";
	unlink $pidfile;
	exit;
}
sub getContext{
	my $content=shift @_;
	return "<!DOCTYPE html><html lang=\"ru\"><head><meta charset=\"utf-8\"/><title>-= DrSmyrke File Server v$version =-</title><style>body{font-family:Arial,Sans,Microsoft Sans Serif,consolas;font-size:10pt;}.form{margin:0px;display:inline-block;}</style></head><body><center><span style=\"font-size:20pt;color:gray;\">-= File Server v$version =-</span></center>$content</body></html>>";
}
sub chkAccess{
	my $url=shift @_;
	if(-f "$dataFolder$url"){my @t=split("/",$url);pop @t;$url=join("/",@t);}
	my $aurl="$dataFolder$url";
	if(-f "$aurl/.htaccess"){return (1,"$aurl/.htaccess");}else{
		my @t=split("/",$url);pop @t;$url=join("/",@t);
		return (0,undef) unless $url;
		return chkAccess($url);
	}
	return (0,undef);
}
sub getHelp{
	print "=== Help Page for FileServer by Dr.Smyrke ===\n";
	print "
-h,--help			To see the current page
-folder <DIR>			Directory for share (default: ~/Desktop)
-pidfile <FILE>			Determining PID file (default: ~/.run/fileserver.pid)
-p,--port <PORT>		Determination of the port which will be run a web server (default: $port)
";
	print "\n=== Thank you for choosing my application ===\n";
	(undef,undef,undef,undef,undef,undef,undef,my $size)=stat($0);
	my $i=0;
	open FS,"<$0";
	while(my $tmp=<FS>){$i++;}
	close FS;
	print "=== The app contains $i lines of code and takes ".getSize($size)." of disk space ===\n";
}
