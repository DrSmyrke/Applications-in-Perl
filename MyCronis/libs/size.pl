#!/usr/bin/perl
use utf8;
sub getSize{($sz)=@_;if($sz<1024){$st="$sz  байт(а)";}else{if($sz>1024 and $sz<1024000){$sz=substr($sz/1024,0,5);$st="$sz Кб";}else{if($sz>1024000 and  $sz<1024000000){$sz=substr($sz/1048576,0,5);$st="$sz Mб";}else{if($sz>1024000000){$sz=substr($sz/1048576000,0,5);$st="$sz Гб";}}}}return $st;}
return 1;
