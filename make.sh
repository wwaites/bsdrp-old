#!/bin/sh
#
# Make script for BSD Router Project 
#
# Copyright (c) 2009, The BSDRP Development Team 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

#############################################
############ Variables definition ###########
#############################################

# Uncomment for enable debug: 
#set -x

NANOBSD_DIR=/usr/src/tools/tools/nanobsd

#Compact flash database needed for NanoBSD ?
#cp $NANOBSD_DIR/FlashDevice.sub .

#TO DO: get actual pwd, and use it for NANOBSD variables
SYSTEM_REQUIRED='8.0-CURRENT'
SYSTEM_RELEASE=`uname -r`

# Progress Print level
PPLEVEL=3

#############################################
########### Function definition #############
#############################################

# Progress Print
#       Print $2 at level $1.
pprint() {
    if [ "$1" -le $PPLEVEL ]; then
        printf "%.${1}s %s\n" "#####" "$2"
    fi
}

check_current_dir() {
#### Check current dir

if [ "$NANOBSD_DIR/BSDRP" != `pwd` ]
then
	pprint 1 "You need to install source code of BSDRP in $NANOBSD_DIR/BSDRP"
	pprint 1 "Download BSDRP source with this command:"
	pprint 1 "cd /usr/src/tools/tools/nanobsd"
	pprint 1 "svn co https://bsdrp.svn.sourceforge.net/svnroot/bsdrp/trunk BSDRP"
	exit 1
fi
}

check_system() {
#### Check prerequisites

pprint 3 "Checking if FreeBSD-current sources are installed..."

if [ ! -f /usr/src/sys/sys/vimage.h  ]
then
	pprint 1 "BSDRP need up-to-date sources for FreeBSD-current"
	pprint 1 "And source file vimage.h (introduce in FreeBSD-current) not found"
	pprint 1 "You can install FreeBSP sources using these steps:"
	pprint 1 "cp /usr/share/examples/cvsup/standard-supfile /etc"
	pprint 1 "Edit /etc/standard-supfile and replace the line:"
	pprint 1 "*default host=CHANGE_THIS.FreeBSD.org"
	pprint 1 "by, for example:"
	pprint 1 "*default host=cvsup2.FreeBSD.org"
	pprint 1 "(you can found other cvsup mirrors here: http://www.freebsd.org/doc/handbook/cvsup.html) "
	pprint 1 "cvsup -g -L 2 /etc/standard-supfile"
	exit 1
fi

pprint 3 "Checking if ports sources are installed…"

if [ ! -d /usr/ports/net/quagga ]
then
	pprint 1 "BSDRP need up-to-date FreeBSD ports sources tree"
	pprint 1 "And it seems that you didn't install the ports source tree"
	pprint 1 "You need to download/extract the ports source tree with this command"
	pprint 1 "portsnap fetch extract update"
	pprint 1 "Then update the ports index with this command"
	pprint 1 "portsdb -F"
	exit 1
fi
}

system_patch() {
###### Adding patch to NanoBSD if needed
if [ "$TARGET_ARCH" = "amd64"  ]
then
	pprint 3 "Checking in NanoBSD allready patched"
	grep -q 'amd64' $NANOBSD_DIR/nanobsd.sh
	if [ $? -eq 0 ] 
	then
		pprint 3 "NanoBSD allready patched"
	else
		pprint 3 "Patching NanoBSD with target amd64 support"
		patch $NANOBSD_DIR/nanobsd.sh nanobsd.patch
	fi
fi
}
#############################################
############ Main code ######################
#############################################

pprint 1 "BSD Router Project image generator"

check_current_dir
check_system

pprint 1 "BSDRP build script"
pprint 1 ""
pprint 1 "What type of target architecture ( i386 / amd64 ) ? "
while [ "$TARGET_ARCH" != "i386" -a "$TARGET_ARCH" != "amd64" ]
do
	read TARGET_ARCH <&1
done

pprint 1 "What type of default console ( vga / serial ) ? "
while [ "$INPUT_CONSOLE" != "vga" -a "$INPUT_CONSOLE" != "serial" ]
do
	read INPUT_CONSOLE <&1
done

pprint 1 "If you had allready build an BSDRP image, you can skip the build process." 
pprint 1 "Do you want to SKIP build world ( y / n ) ? "

while [ "$SKIP_REBUILD" != "y" -a "$SKIP_REBUILD" != "n" ]
do
	read SKIP_REBUILD <&1
done

system_patch

# Copy the common nanobsd configuration file to /tmp
cp -v BSDRP.nano /tmp/BSDRP.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by make.sh) ###########" >> /tmp/BSDRP.nano
echo "# Kernel config file to use" >> /tmp/BSDRP.nano

case $TARGET_ARCH in
	"amd64") echo "NANO_KERNEL=BSDRP-AMD64" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=amd64"  >> /tmp/BSDRP.nano
		pprint 3 "Copying amd64 Kernel configuration file"
		cp -v BSDRP-AMD64 /usr/src/sys/amd64/conf
		;;
	"i386") echo "NANO_KERNEL=BSDRP-I386" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=i386"  >> /tmp/BSDRP.nano
		pprint 3 "Copying amd64 Kernel configuration file"
		cp -v BSDRP-I386 /usr/src/sys/i386/conf
		;;
esac

echo "# Bootloader type"  >> /tmp/BSDRP.nano

case $INPUT_CONSOLE in
	"vga") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/BSDRP.nano 
;;
	"serial") echo "NANO_BOOTLOADER=\"boot/boot0sio\"" >> /tmp/BSDRP.nano
	echo "#Configure console port" >> /tmp/BSDRP.nano
	echo "customize_cmd cust_comconsole" >> /tmp/BSDRP.nano
;;
esac

# Start nanobsd using the BSDRP configuration file
pprint 1 "Launching NanoBSD build process..."
if [ "$SKIP_REBUILD" = "y" ]
then
	sh ../nanobsd.sh -b -c /tmp/BSDRP.nano
else
	sh ../nanobsd.sh -c /tmp/BSDRP.nano
fi

# Testing exit code of NanoBSD:

if [ $? -eq 0 ] 
then
	pprint 1 "NanoBSD build finish, BSDRP image file is here"
	pprint 1 "/usr/obj/nanobsd.BSDRP/BSDRP.img"
else
	pprint 1 "NanoBSD meet an error, check the log files here:"
	pprint 1 "/usr/obj/nanobsd.BSDRP/"		
fi



exit 0
