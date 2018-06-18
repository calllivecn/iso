# mini linux救援iso生成工具

- - -

`生成一个linux liveCD，用作救援mini linux iso，带有一些修复工具（无GUI）。可以通过编写项目下的mini-linux.debs文件定制liveCD里的工具，生成时还可以通过手动操作将要生成的LIveCD的内容。可以直接dd到U盘启动，也可以参考项目内的grub2-uefi-bios.txt制作多引导。

- 备一个liveCD关键时刻会很有用 -

- - -

## make-mini-linux.sh:
* 创建 mini-linux.iso

```bash
sudo make-mini-linux.sh -h

Using: make-mini-linux.sh [-dlo] [-c <Codename>] [-m <mirros>]
-d      work directory (default:./)
-l      new iso volume label name
-o      new iso filename
-i      read deb list for file
-c      Distribution Codename
-m      mirror

```

### example
* sudo make-mini-linux.sh -c bionic -l 'Mini linux v1.0' -i mini-linux.debs -m https://mirrors.ustc.edu.cn/ubuntu -o Mini-Linux.iso

## update-mini-linux.sh:
* 更新 mini-linux.iso

```bash
sudo update-mini-linux.sh -h

Using: update-mini-linux.sh [-dlo] <-i>
-d              work directory (default:./)
-i              old iso
-l              new iso volume label name
-o              new iso filename

```

### example
* sudo update-mini-linux.sh -i Mini-linux.iso -o Mini-linux-update.iso -l 'Mini linux v2.0'

# *make和update 中间会有chroot后手动操作步骤。*

# *如果不需要手动操作exit或Ctrl+D退出。*
