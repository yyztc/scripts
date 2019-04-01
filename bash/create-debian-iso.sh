#!/bin/bash

# variables
source="http://mirror.xmission.com/debian-cd/current/amd64/iso-cd/"
shatxt="${source}/SHA512SUMS"
build="$HOME/tmp/debian-iso"
shaname=$(basename ${shatxt})

# we need command-line options
while getopts "p:f:" opt; do
	case $opt in
		p)
			preseed=$OPTARG
			;;
		f)
			outfile=$OPTARG
			;;
	esac
done

# validate arguments...
if [ -z "${preseed}" ]; then
	echo "You must specify the location of a Debian preseed file with the -p option!"
	exit 255
fi

if [ -z "$outfile" ]; then
	echo "You must specify the base output file name with -f"
	echo "example: $(basename $0) -f vbox -- output file: debian-vbox-$(date +%Y%m%d).iso"
	exit 255
fi

# make sure the preseed file exists
if [ -f "${preseed}" ]; then
    echo "Using preseed file: ${preseed}"
else
    echo "Error: file not found: ${preseed}"
    exit 255
fi

# name of output file
output="debian-${outfile}-$(date +%Y%m%d).iso"

# create the build directory
if [ ! -d "${build}" ]; then
    mkdir -p "${build}"
fi

pushd "${build}"

# download the SHA512SUMS file
wget -q ${shatxt}
if [ $? -eq 0 ]; then
    cat ${shaname} | grep amd64.*netinst | grep -v mac > sha.txt
else
    echo "Error: Unable to download ${shatxt}. Exiting."
    exit 255
fi

# download the netinst ISO
isoname=$(cat sha.txt | awk '{ print $2 }')
if [ -f ${isoname} ]; then
    echo "${isoname} has already been downloaded."
else
    echo "Downloading ${source}/${isoname}..."
    wget --no-clobber --show-progress -q ${source}/${isoname}
fi

# check hash
if [ $? -eq 0 ]; then
    sha512sum -c sha.txt
    if [ $? -ne 0 ]; then
        echo "Failed to verify SHA512SUM of ${isoname} -- exiting."
        exit 255
    fi
else
    echo "Unable to download ISO."
    exit 255
fi

# extract the ISO
7z -ox x ${isoname}
if [ $? -ne 0 ]; then
    echo "Failed to extract ${isoname} -- exiting."
    exit 255
fi

# replace isolinux.cfg
cat << EOF > x/isolinux/isolinux.cfg 
default linux
timeout 200

SAY This ISO will DELETE ALL DATA ON THIS MACHINE!!!
SAY It is designed to automatically install Debian
SAY if this isn't what you want to do - power off your machine immediately!!
SAY ==||==||==||==||==
SAY Installation will begin in 20 seconds...

label linux
	menu label ^Install
	kernel /install.amd/vmlinuz
	append vga=788 initrd=/install.amd/initrd.gz --- quiet priority=high locale=en_US.UTF-8 keymap=us file=/cdrom/preseed.cfg
EOF

# inject preseed.cfg
cp ${preseed} x/preseed.cfg
if [ $? -ne 0 ]; then
    echo "Error copying ${preseed} -- exiting."
    exit 255
fi

# generate ISO
echo "Generating ISO: ${build}/${output}"
genisoimage -quiet -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat  -no-emul-boot -boot-load-size 4 -boot-info-table -o ${build}/${output} x
if [ $? -eq 0 ]; then
    # cleanup
    rm -rf x ${shaname} sha.txt
else
    echo "Error generating ISO."
fi

popd
exit 0