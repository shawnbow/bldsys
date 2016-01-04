#!/bin/bash
TARGET_BUILD="${TARGET_BUILD-flame-f}"
SRC_DIR=~/data/build/$TARGET_BUILD
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
ERROR_LOG_FILE=$TARGET_BUILD-build-error-$DATE_TIME.log
DEST_DIR=user/shawn/build/nightly/$TARGET_BUILD/$DATE_TIME
export PATH=/home/shawn/bin:/opt/raid/android-sdk-linux/platform-tools:/opt/jdk/bin:/opt/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[[ $1 == -d ]] && export IS_DEBUG=yes

error_log()
{
echo -e "Full log address:\n" >> $PART_LOG
echo "smb://share/Public/user/shawn/build/log/$ERROR_LOG_FILE" >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> last 100 lines\n" >> $PART_LOG

tail -n 100 $FULL_LOG >> $PART_LOG

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter without warning\n" >> $PART_LOG
cat $FULL_LOG | grep -v -i warning | grep -v "?" | grep -v "\^" | grep -B 50 [\ ][Ee]rror[:\ ] >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter end\n" >> $PART_LOG

cp $FULL_LOG /mnt/public/user/shawn/build/log/$ERROR_LOG_FILE
}

#modify_prop()
#{
#PROP_KEY=$1
#PROP_VALUE=$2
#PROP_FILE=$3
#sed -i "s/\($PROP_KEY\).*$/\1 = $PROP_VALUE \\\/" $PROP_FILE
#}

cd $SRC_DIR && rm -rf * || git clone git@git.acadine.com:zhen-bao/h5os.git $SRC_DIR
cd $SRC_DIR && git reset --hard && git fetch origin && git checkout origin/master
BRANCH=v2.2 ./config-mirror.sh -d $TARGET_BUILD >> repo.log 2>&1

#BUILD_PROP=$SRC_DIR/device/rockchip/rk3066/rk3066.mk
#$(modify_prop "ro.product.platform" "MATCHSTICK-KK" $BUILD_PROP)
#$(modify_prop "ro.product.version" $DATE_TIME $BUILD_PROP)

./build.sh >> $FULL_LOG 2>&1

if [ $? -ne 0 ]; then
    error_log
    [ -z $IS_DEBUG ] && ~/data/build/bldsys/mailto.py "$TARGET_BUILD build failed" "Full log address: smb://10.240.18.16/Public/user/shawn/build/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1
fi

mkdir -p $SRC_DIR/flash_images
echo \
'adb kill-server
adb devices
adb reboot bootloader
fastboot devices

echo "Flash Apps..."
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash persist persist.img
fastboot flash recovery recovery.img
fastboot flash cache cache.img
fastboot flash userdata userdata.img

echo "Done..."
fastboot reboot

echo "Just close the windows as you wish."' > $SRC_DIR/flash_images/h5flash.sh

cd $SRC_DIR && repo manifest -r -o $SRC_DIR/flash_images/manifest.xml

cd $SRC_DIR && cp $SRC_DIR/out/target/product/*/*.img \
                  $SRC_DIR/out/target/product/*/android-info.txt \
                  $SRC_DIR/out/target/product/*/installed-files.txt \
                  $SRC_DIR/out/target/product/*/system/build.prop \
                  $SRC_DIR/flash_images/
cd $SRC_DIR && zip -r $TARGET_BUILD-$DATE_TIME.zip flash_images/*

[ -z $IS_DEBUG ] && mkdir -p /mnt/public/$DEST_DIR/ && 
cp -r $SRC_DIR/flash_images/manifest.xml $SRC_DIR/$TARGET_BUILD-$DATE_TIME.zip /mnt/public/$DEST_DIR/

[ -z $IS_DEBUG ] && ~/data/build/bldsys/mailto.py "$TARGET_BUILD build successfully" "Please get build from smb://10.240.18.16/Public/$DEST_DIR/"

