# sd-fuse_h5
Create bootable SD card for FriendlyELEC series board, NanoPi-K1-Plus/NanoPi-NEO2/NanoPi-NEO-Core2/NanoPi-NEO-Plus2 etc..

## How to find the /dev name of my SD Card
Unplug all usb devices:
```
ls -1 /dev > ~/before.txt
```
plug it in, then
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```

## Build friendlycore-xenial_4.14_arm64 bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_h5.git
cd sd-fuse_h5
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_arm64
```
You can build the following OS: friendlycore-xenial_4.14_arm64, friendlywrt_4.14_arm64.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_h5
tar xvzf ../images-for-eflasher/friendlycore-xenial_4.14_arm64.tgz
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_h5.git
cd sd-fuse_h5
wget http://112.124.9.243/dvdfiles/H5/images-for-eflasher/friendlycore-xenial_4.14_arm64.tgz
tar xvzf friendlycore-xenial_4.14_arm64.tgz
```
Now,  Change something under the friendlycore-xenial_4.14_arm64 directory, 
for example, replace the file you compiled, then build friendlycore-xenial_4.14_arm64 bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_arm64
```
or build an sd card image:
```
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_arm64 h5-sd-friendlycore.img
```
The following file will be generated:  
```
out/h5-sd-friendlycore.img
```
You can use dd to burn this file into an sd card:
```
sudo dd if=out/h5-sd-friendlycore.img bs=1M of=/dev/sdX
```

## Build an sdcard-to-emmc image (eflasher rom)
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore-xenial_4.14_arm64 image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_h5.git
cd sd-fuse_h5
wget http://112.124.9.243/dvdfiles/H5/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
sudo ./mk-emmc-image.sh friendlycore-xenial_4.14_arm64 h5-eflasher-friendlycore.img
```
The following file will be generated:  
```
out/h5-eflasher-friendlycore.img
```
You can use dd to burn this file into an sd card:
```
sudo dd if=out/h5-eflasher-friendlycore.img bs=1M of=/dev/sdX
```

## Replace the file you compiled

### Install cross compiler and tools

Install the package:
```
apt install liblz4-tool android-tools-fsutils
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git
sudo mkdir -p /opt/FriendlyARM/toolchain
sudo tar xf prebuilts/gcc-x64/arm-cortexa9-linux-gnueabihf-4.9.3.tar.xz -C /opt/FriendlyARM/toolchain/
```

### Build U-boot and Kernel for FriendlyCore
Download image files:
```
cd sd-fuse_h5
wget http://112.124.9.243/dvdfiles/H5/images-for-eflasher/friendlycore-xenial_4.14_arm64.tgz
tar xzf friendlycore-xenial_4.14_arm64.tgz
```
Build kernel:
```
cd sd-fuse_h5
./build-kernel.sh friendlycore-xenial_4.14_arm64
```
Build uboot:
```
cd sd-fuse_h5
./build-uboot.sh friendlywrt_4.14_arm64
```

### Custom rootfs for FriendlyCore
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_h5.git
cd sd-fuse_h5
wget http://112.124.9.243/dvdfiles/H5/images-for-eflasher/friendlycore-xenial_4.14_arm64.tgz
tar xzf friendlycore-xenial_4.14_arm64.tgz
wget http://112.124.9.243/dvdfiles/H5/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
```
Download rootfs package:
```
wget http://112.124.9.243/dvdfiles/H5/rootfs/rootfs_friendlycore_4.14.tgz
tar xzf rootfs_friendlycore_4.14.tgz -C friendlycore-xenial_4.14_arm64
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore-xenial_4.14_arm64/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore-xenial_4.14_arm64/rootfs friendlycore-xenial_4.14_arm64
```
Make sdboot image:
```
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_arm64
```
or make sd-to-emmc image (eflasher rom):
```
sudo ./mk-emmc-image.sh friendlycore-xenial_4.14_arm64
```
  
