#!/bin/bash
# date 2018-06-17 14:14:20
# author calllivecn <c-all@qq.com>

#######################
#
# inint area
#
#######################

export LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

if [ "$(id -u)" -ne 0 ];then
	echo must be root user
	echo or sudo -i 
	exit 1
fi

work_dir=
old_iso=
new_iso="$(date +%F-%H%M%S).iso"
iso_label="ISO $(date +%F-%H%M%S)"

LIBPATH=$(dirname ${0})
PROGRAM="${0##*/}"

########################
#
# update-mini-linux function define area, begin
#
#######################


init_iso(){
	mkdir "$work_dir"/old_iso
	mkdir "$work_dir"/root
	mount -o loop "$old_iso" "$work_dir"/old_iso
	cp -a "$work_dir"/old_iso "$work_dir"/iso
	unsquashfs -f -d "$work_dir/root" "$work_dir/iso/casper/filesystem.squashfs" 
	mv "$work_dir"/iso/casper/vmlinuz.efi "$work_dir"/root/$(readlink "$work_dir"/root/vmlinuz)
	mv "$work_dir"/iso/casper/initrd.lz "$work_dir"/root/$(readlink "$work_dir"/root/initrd.img)
	umount "$work_dir"/old_iso/
}

__mount_sh(){
	mount -vt devtmpfs none "$work_dir"/root/dev
	mount -vt devpts none "$work_dir"/root/dev/pts
	mount -vt proc none "$work_dir"/root/proc
	mount -vt sysfs none "$work_dir"/root/sys
	mount -vt tmpfs none "$work_dir"/root/run
}

__umount_sh(){
	umount -v $work_dir/root/proc
	umount -v $work_dir/root/dev/pts
	umount -v $work_dir/root/dev
	umount -v $work_dir/root/run
	umount -v $work_dir/root/sys
}

__resolv(){
	mv -v $work_dir/root/etc/resolv.conf{,.bak}
	cp -v /etc/resolv.conf $work_dir/root/etc/
}

__unresolv(){
	mv -vf $work_dir/root/etc/resolv.conf{.bak,}
}

rm_var_lib_apt_lists(){

	rm -rf $work_dir/root/var/lib/apt/lists

}

chroot_sh(){
	local yesno=n flag=1

	__resolv
	__mount_sh

	echo "Countdown 10 seconds."
	while [ $flag = "1" ];
	do
		echo -n "Need a custom action?[y/N]"
		echo
		read -n 1 -t 10 yesno
		yesno=${yesno:-n}

		if [ "$yesno"x = "y"x ] || [ "$yesno"x = "n"x ];then
			flag=0
		fi

	done

	if [ "$yesno"x = "y"x ];then

		echo "already chroot ."
		echo "Please proceed with your operation."
		echo "if not operation, exit or Ctrl+D exit."
		chroot "$work_dir"/root
	fi

	__umount_sh
	__unresolv
}

# 退出 chroot 后的工作

root_autologin(){

	# 这是之前的老方法了。
	local agetty_service="$work_dir"/root/lib/systemd/system/getty@.service
	sed -ri '/ExecStart=/s#(ExecStart)=.*#\1=\-/sbin/agetty \-a root -o "\-p -- \\\\u" -J \%I \$TERM#' $agetty_service

	#local agetty_conf_d="$work_dir"/root/etc/systemd/system/getty@.service.d/

	#mkdir -p "$agetty_conf_d"

	#local autologin="$agetty_conf_d"/autologin.conf

	#echo "[Service]" > "$autologin"
	#echo "ExecStart=" >> "$autologin"
	#echo "ExecStart=-/sbin/agetty -a root --nocelar %I \$TERM" >> "$autologin"
}

rebuild_iso(){
	rm -v "$work_dir"/iso/casper/filesystem.squashfs
	mv -v "$work_dir"/root/$(readlink "$work_dir"/root/vmlinuz) "$work_dir"/iso/casper/vmlinuz.efi
	mv -v "$work_dir"/root/$(readlink "$work_dir"/root/initrd.img) "$work_dir"/iso/casper/initrd.lz
	mksquashfs "$work_dir"/root "$work_dir"/iso/casper/filesystem.squashfs -comp xz -b 1M
}

mkiso(){

mkisofs -V "$iso_label" \
-J -b isolinux/isolinux.bin \
-c isolinux/boot.cat \
-boot-load-size 4 -boot-info-table -no-emul-boot \
-eltorito-alt-boot -e efi.img -no-emul-boot \
-o "$new_iso" \
-R "$work_dir"/iso

isohybrid "$new_iso"

echo "iso file --> ${new_iso}"
}

mkiso_v2(){
xorriso -as genisoimage -o "$new_iso" -no-pad \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-eltorito-alt-boot -e efi.img -no-emul-boot \
	-isohybrid-gpt-basdat \
	-publisher "author: calllivecn <https://github.com/calllivecn/iso>" \
	-V "$iso_label" "$work_dir"/iso

echo "iso file --> ${new_iso}"
}

clear_workspace(){

	rm -rf "$work_dir"

}

signal_exit(){
	set +e
	umount "$work_dir"/old_iso/
	__umount_sh
	set -e
	clear_workspace
	exit 1
}

err_exit(){
	echo "ERROR EXIT"
	signal_exit
	exit 1
}

########################
#
# update-mini-linux function define area, end
#
#######################


########################
#
# make-mini-linux function define area, begin
#
########################

build_iso(){
	mv -v "$work_dir"/root/$(readlink "$work_dir"/root/vmlinuz) "$work_dir"/iso/casper/vmlinuz.efi
	mv -v "$work_dir"/root/$(readlink "$work_dir"/root/initrd.img) "$work_dir"/iso/casper/initrd.lz
	mksquashfs "$work_dir"/root "$work_dir"/iso/casper/filesystem.squashfs -comp xz -b 1M
}

__mk_efi_img(){
	local efi="$work_dir"/iso/efi.img
	local efi_dir="$work_dir"/efi_img_mount_dir

	dd if=/dev/zero of="$efi" bs=1M count=8
	mkfs.fat "$efi"
	mkdir -vp "$efi_dir"
	mount -v -o loop "$efi" "$efi_dir"

	grub-install --target x86_64-efi --boot-directory "$work_dir"/iso/boot --efi-directory "$efi_dir" --removable

	sed -ri s#\''.*'\'#\'/boot/grub\'# "$efi_dir"/EFI/BOOT/grub.cfg

	umount -v "$efi_dir"
}

build_workspace(){
	mkdir -vp "${work_dir}"/iso/{boot,casper,isolinux}
	mkdir -vp "$work_dir"/root
	cp -v $isohdpfx_bin $isolinux_bin $vesamenu_c32 $ldlinux_c32 "$work_dir"/iso/isolinux/
	cp -v "$LIBPATH"/iso_cfg/syslinux.cfg "$work_dir"/iso/

	__mk_efi_img

	cp -v "$LIBPATH"/iso_cfg/grub.cfg "$work_dir"/iso/boot/grub/
}

__build_sources_list(){
	local sources_list="$work_dir"/root/etc/apt/sources.list

	if [ -f $sources_list ];then
		mv -v $sources_list{,.bak}
	fi

	echo "deb $mirror ${codename} main" >> $sources_list
	echo "deb $mirror ${codename}-updates main" >> $sources_list
	echo "deb $mirror ${codename} universe" >> $sources_list
	echo "deb $mirror ${codename}-updates universe" >> $sources_list
	echo "deb $mirror ${codename}-security main" >> $sources_list
	echo "deb $mirror ${codename}-security universe" >> $sources_list

	echo "deb $mirror ${codename} main >> $sources_list"
	echo "deb $mirror ${codename}-updates main >> $sources_list"
	echo "deb $mirror ${codename} universe >> $sources_list"
	echo "deb $mirror ${codename}-updates universe >> $sources_list"
	echo "deb $mirror ${codename}-security main >> $sources_list"
	echo "deb $mirror ${codename}-security universe >> $sources_list"
}

install_required_debs(){
	local debs
	 debs=$(grep -vE '^#|^$' "${LIBPATH}"/mini-linux-required.debs |tr '\n' ' ')
	__resolv
	__mount_sh
	chroot "$work_dir"/root/ apt update
	chroot "$work_dir"/root/ apt -y install $debs
	chroot "$work_dir"/root/ apt clean
	__umount_sh
	__unresolv
	 
}

apt_upgrade_y(){
	__resolv
	__mount_sh
	chroot "$work_dir"/root/ apt update
	chroot "$work_dir"/root/ apt upgrade -y
	chroot "$work_dir"/root/ apt clean
	__umount_sh
	__unresolv
}

install_debs(){

	__build_sources_list

	if [ -r "$mini_linux_debs" ];then
		include_debs=$(grep -vE '^$|^#' $mini_linux_debs |tr '\n' ' ')
		__resolv
		__mount_sh
		chroot "$work_dir"/root/ apt update
		chroot "$work_dir"/root/ apt install -y $include_debs
		chroot "$work_dir"/root/ apt clean
		__umount_sh
		__unresolv

		apt_upgrade_y
	else
		apt_upgrade_y
	fi
}

debootstrap_as(){
	set -x
	debootstrap --include="linux-image-generic" "$codename" "$work_dir"/root/ $mirror
	set +x
}

configure(){
	root_autologin
	
	ln -sf /usr/share/zoneinfo/Asia/Shanghai "$work_dir"/root/etc/localtime

	# locale-gen zh_CN
	sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' "$work_dir"/root/etc/locale.gen
	sed -i 's/^# zh_CN.UTF-8/zh_CN.UTF-8/' "$work_dir"/root/etc/locale.gen
	__mount_sh

	cp -v "${LIBPATH}"/root_cfg/10-ethX.network  "$work_dir"/root/etc/systemd/network/10-ethX.network
	chroot "$work_dir"/root systemctl enable systemd-networkd.service

	chroot "$work_dir"/root/ locale-gen

	__umount_sh

	cp -v "$LIBPATH"/root_cfg/mini-linux-bashrc "$work_dir"/root/root/.bashrc
	cp -v "$LIBPATH"/root_cfg/tmux.conf_v2.6 "$work_dir"/root/etc/tmux.conf

	sync
}


########################
#
# make-mini-linux function define area, end
#
########################
