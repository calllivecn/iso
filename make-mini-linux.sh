#!/bin/bash
# date 2017-12-03 08:57:58
# author calllivecn <c-all@qq.com>


#1. init 
#	check所以需要的文件和软件包工具.
#	软件包: debootstrap, parted, genisoimage, isolinux, 
#	squashfs-tools, syslinux, syslinux-efi, syslinux-utils,
#	dpkg 
#
#2. build_workspace 创建好一个临时工作目录和需要的iso目录,
#	mktemp -d; mkdir boot; grub-install; make efi.img; mkdir casper; mkdir isolinux/;
#	cp isohdpfx_bin isolinux_bin vesamenu_c32 ldlinuxc32 isolinux/
#
#3. read_include_debs form mini-linux.debs
#
#4. debootstrap_as
#	debootstrap --include=<deb1,deb2,,,debs,> 
#
#5. configure_env
#	~/bashrc, /etc/tmux.conf, 
#
#5. chroot_sh()
#	chroot手动做一此操作.如不需要输入exit ro Ctrl+D退出.
#
#6. build_iso()
#	mksquashfs $work_dir/root/ $work_iso/casper/filesystem.squashfs -b 1M -comp xz
#
#7. xorriso_as_iso mkisofs_v2()


set -e



isohdpfx_bin=/usr/lib/ISOLINUX/isohdpfx.bin
isolinux_bin=/usr/lib/ISOLINUX/isolinux.bin
vesamenu_c32=/usr/lib/syslinux/modules/bios/vesamenu.c32
ldlinux_c32=/usr/lib/syslinux/modules/bios/ldlinux.c32


# 加载函数
. $(dirname $0)/libmini-linux.sh

mini_linux_debs="${LIBPATH}"/mini-linux.debs

mirror='http://mirrors.ustc.edu.cn/ubuntu'

using(){
	local str="Using: ${PROGRAM} [-dlo] [-c <Codename>] [-m <mirros>]"
	str="$str"'
-d      work directory (default:./)
-l      new iso volume label name
-o      new iso filename
-i      read deb list for file
-c      Distribution Codename
-m      mirror
'
	echo "$str"
	exit 0
}


while getopts ':d:l:o:i:c:m:h' opt
do
	case "$opt" in
		d)
			if [ ! -d "$OPTARG" ];then
				echo "$OPTARG" directory not exists
				exit 1
			fi
			work_dir_suffix="$OPTARG"
			;;
		l)
			if [ -n "$OPTARG" ];then
				iso_label="$OPTARG"
			fi
			;;
		o)
			if [ -f "$OPTARG" ];then
				echo "$OPTARG" already exists
				exit 1
			fi
			new_iso="$OPTARG"
			;;
		i)
			if [ -f "$OPTARG" ] && [ -r "$OPTARG" ];then
				mini_linux_debs="$OPTARG"
			fi
			;;
		c)
			codename="$OPTARG"
			;;
		m)
			mirror="$OPTARG"
			;;
		h)
			using
			;;
		\:)
			echo "-${OPTARG} option requires an argument"
			exit 1
			;;
		\?)
			echo "invalid option: -${OPTARG}"
			exit 1
			;;
	esac
done

if [ -z "$codename" ];then
	echo "-c codename option requires"
	exit 1
fi

if [ -d "$work_dir_suffix" ];then
	work_dir=$(mktemp -d -p "${work_dir_suffix}" --suffix='_Mini-Linux')
else
	work_dir=$(mktemp -d -p "$(pwd -P)" --suffix='_Mini-Llinux')
fi



# function define 

check_pkg_file(){
	local deb flag_lack=false
	
	echo "check packages ... "
	for deb in debootstrap parted genisoimage xorriso isolinux \
	squashfs-tools syslinux syslinux-utils;
	do
		dpkg -l $deb &> /dev/null
		if [ $? -ne 0 ];then
			echo "please install $deb, e.g: apt install $deb"
			flag_lack=true
		fi
	done
	echo "check packages ... done"
	
	echo "check files ... "
	for deb in $isohdpfx $isolinux_bin $vesamenu_c32 $ldlinux_c32;
	do
		if [ ! -f $deb ];then
			echo "Lack of $deb files."
			flag_lack=true
		fi
	done
	echo "check files ... done"
	
	if $flag_lack;then
		return 1
	fi
}
# test check_pkg_file
check_pkg_file
#echo "check running ... done"; exit 0



main(){

	build_workspace

	debootstrap_as

	install_debs

	install_required_debs

	apt_upgrade_y

	chroot_sh

	configure

	build_iso

	mkiso_v2

	clear_workspace
}

trap "signal_exit" SIGINT SIGTERM ERR

main
