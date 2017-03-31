#!/bin/bash
tar -xf Gtk2-WebKit-0.09.tar.gz
cd Gtk2-WebKit-0.09
sudo apt-get install -y libextutils-pkgconfig-perl libextutils-depends-perl libwebkit-dev
perl Makefile.PL
make test
make
sudo make install
cd ..
rm -rf Gtk2-WebKit-0.09
read
