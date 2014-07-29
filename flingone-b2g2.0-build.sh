#!/bin/bash
TARGET_BRANCH="${TARGET_BRANCH-infthink-flingone-b2g2.0}"
SRC_DIR=~/build/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
ERROR_LOG_FILE=$TARGET_BRANCH-build-error-$DATE_TIME.log
export USER=it
export PATH=/opt/jdk1.6.0_45/bin:/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/android/android-ndk-r9d:/opt/android/adt/sdk/tools:/opt/android/adt/sdk/platform-tools:/opt/android/adt/sdk/build-tools/android-4.4.2:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

error_log()
{
echo -e "Full log address:\n" >> $PART_LOG
echo "http://office.infthink.com/cm/log/$ERROR_LOG_FILE" >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> last 100 lines\n" >> $PART_LOG

tail -n 100 $FULL_LOG >> $PART_LOG

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter without warning\n" >> $PART_LOG
cat $FULL_LOG | grep -v -i warning | grep -v "?" | grep -v "\^" | grep -B 50 [\ ][Ee]rror[:\ ] >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter end\n" >> $PART_LOG

sudo cp $FULL_LOG /mnt/public/cm/log/$ERROR_LOG_FILE
}

modify_prop()
{
PROP_KEY=$1
PROP_VALUE=$2
PROP_FILE=$3
sed -i "s/\($PROP_KEY\).*$/\1 = $PROP_VALUE \\\/" $PROP_FILE
}

cd $SRC_DIR && rm -rf * || git clone appler:flingone/B2G-FlingOne $SRC_DIR
cd $SRC_DIR && git reset --hard && git fetch origin && git checkout master
cd $SRC_DIR/.repo && rm -rf manifest* project.list
cd $SRC_DIR
GITREPO='appler:flingone/b2g-manifest' BRANCH=infthink/flingone-b2g2.0 REPO_INIT_FLAGS='--repo-url=appler:tools/repo.git' ./config.sh -d rk30sdk >> repo.log 2>&1

#source load-config.sh
BUILD_PROP=$SRC_DIR/device/rockchip/rk30sdk/rk30sdk.mk
$(modify_prop "ro.product.platform" "MatchStick" $BUILD_PROP)
$(modify_prop "ro.product.version" $DATE_TIME $BUILD_PROP)

MAKE_OTAPACKAGE=1 ./build.sh >> $FULL_LOG 2>&1 && ./flash.sh >> $FULL_LOG 2>&1

if [ $? -ne 0 ]; then
    error_log
    [ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build failed" "Full log address: http://office.infthink.com/cm/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1
fi

cd $SRC_DIR && repo manifest -r -o manifest.xml
cd $SRC_DIR && zip -r $TARGET_BRANCH-$DATE_TIME.zip rockdev/* && cd $SRC_DIR

[ -z $IS_DEBUG ] && sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/ && 
sudo cp -r $SRC_DIR/manifest.xml $SRC_DIR/$TARGET_BRANCH-$DATE_TIME.zip $SRC_DIR/out/target/product/rk30sdk/obj/PACKAGING/target_files_intermediates/*.zip $SRC_DIR/out/target/product/rk30sdk/*.zip /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/

[ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build successfully" "Please get build from http://office.infthink.com/cm/$TARGET_BRANCH/$DATE_TIME/"

