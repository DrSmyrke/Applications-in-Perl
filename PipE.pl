#!/usr/bin/perl
# application based on DrSmyrke
#
# Any original DrSmyrke code is licensed under the BSD license
#
# All code written since the fork of DrSmyrke is licensed under the GPL
#
#
# Copyright (c) 2015 Prokofiev Y. <Smyrke2005@yandex.ru>
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

use IO::File;
use File::Spec;

use strict;

sub print_arr {
    my @t = @_;
    foreach my $l (@t) {
    print $l;
    }
}

pipe(CHILD, PARENT);
CHILD->autoflush(1);
my @arr=();
my $delim = '---------------------------------------------------------------------------'."\n";
print "Single process work\n";
my $pid=fork;

if($pid==0) {
    #Child work, children process read file, to arr, and send to parent
    close CHILD;
    print "Child process work: $$\n";
    #здесь формируется массив @arr
    open(F_IN, "<", 'arr.txt');
    while(my $t = <F_IN>) {
    push @arr, $t;
    }
    close(F_IN);
    print "Child Process: makes array:\n";
    print "Child Process:".$delim;
    print_arr(@arr);
    print "Child Process:".$delim;
    foreach my $send_msg (@arr){
    print PARENT $send_msg;
    }
    close PARENT;
    exit;
}
else {
    #Parent work, parent process read data from pipe child and make array, after all read print
    print "Parent process work: $$, child: $pid\n";
    $SIG{CHLD} = "IGNORE";
    close PARENT;
    while(my $recv_msg=<CHILD>) {
        push @arr,$recv_msg;
    }
    print "Parent Process:".$delim;
    print_arr(@arr);
    print "Parent Process:".$delim;

    #waitpid($pid,0);
}
