#!/bin/bash
# 2017-10-19
# author calllivecn <c-all@qq.com>
#
#
#1.	mount -o loop $isofile /tmp/iso
#
#2.	cp -a /tmp/iso $work_dir/iso
#	mkdir $taget/root
#
#3.	unsquashfs $filesystem.squashfs -d $work_dir/root #
#4.	mv $work_dir/root/etc/resolv.conf{,.bak}
#	cp /etc/resolv.conf $work_dir/root/etc/
#
#5.	mount 必要的文件系统 --> mount_sh()
#
#6.	chroot $work_dir/root 
#	请开始你的操作～～～
#
#7. apt clean && unchroot
#	mv -f $work_dir/root/etc/resolv.conf{.bak,}
#	rm -rf /var/lib/apt/lists
#
#8.	查看 /lib/systemd/system/getty@.service 更新没有，
#	如果更新 修改之：
#		ExecStart=-/sbin/agetty --noclear %I $TERM
#		ExecStart=-/sbin/agetty --noclear %I $TERM -a root
#
#9. mksquahfs $work_dir/root $work_dir/iso/casper/filesystem.squashfs 
#
#10.移动vmlinuz.efi ,initrd.lz 到 $work_dir/iso/casper/
#
#11.mkisofs && isohybrid $new_iso;
# or xorriso;


VERSION='v1.0'

# 加载函数
. $(dirname $0)/libmini-linux.sh

######################
#
# 用户输入参数
#
#####################

using(){
	program=${0##*/}

	local str="Using: $program [-dlo] <-i>"
	str="$str"'
-d		work directory (default:./)
-i		old iso
-l		new iso volume label name
-o		new iso filename
'
	echo "$str"
	exit 0
}

flag_i=true
while getopts ':d:i:l:o:h' opt
do
	case "$opt" in
		d)
			if [ ! -d "$OPTARG" ];then
				echo "$OPTARG" directory not exists
				exit 1
			fi
			work_dir_suffix="$OPTARG"
			;;
		i)
			if [ ! -f "$OPTARG" ];then
				echo "$OPTARG not exists"
				exit 1
			fi
			old_iso="$OPTARG"
			flag_i=false
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
		h)
			using
			exit 1
			;;
		\:)
			echo "-${OPTARG} option requires an argument"
			exit 1
			;;
		\?)
			echo "invalid option : -${OPTARG}"
			exit 1
			;;
	esac
done

if $flag_i ;then
	echo "-i option requires"
	exit 1
fi

if [ -d "$work_dir_suffix" ];then
	work_dir=$(mktemp -d -p "${work_dir_suffix}" --suffix='_Mini-Linux')
else
	work_dir=$(mktemp -d -p "$(pwd -P)" --suffix='_Mini-Llinux')
fi

# testing being

#echo "$old_iso"
#echo $work_dir
#echo $iso_label
#echo $new_iso
#exit 0

# testing end

main(){

	init_iso

	apt_upgrade_y
	
	chroot_sh

	configure

	rm_var_lib_apt_lists

	rebuild_iso

	mkiso_v2

	clear_workspace

}

trap "signal_exit" SIGINT SIGTERM ERR

main
