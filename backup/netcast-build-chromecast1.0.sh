#!/bin/bash -
TARGET_BRANCH="${TARGET_BRANCH-infthink-firefly2.0}"
SRC_DIR=~/$TARGET_BRANCH
DEBUG_INFO=chromecast1.0
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
ERROR_LOG_FILE=$TARGET_BRANCH-build-error-$DATE_TIME.log
export USER=it
export PATH=/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/android/android-ndk-r9d:/opt/android/adt/sdk/tools:/opt/android/adt/sdk/platform-tools:/opt/android/adt/sdk/build-tools/android-4.4.2:/opt/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

error_log()
{
echo -e "Full log address:\n" >> $PART_LOG
echo "smb://10.0.0.201/public/cm/log/$ERROR_LOG_FILE" >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> last 100 lines\n" >> $PART_LOG

tail -n 100 $FULL_LOG >> $PART_LOG

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter without warning\n" >> $PART_LOG
cat $FULL_LOG | grep -v -i warning | grep -v "?" | grep -v "\^" | grep -B 50 [\ ][Ee]rror[:\ ] >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter end\n" >> $PART_LOG

sudo cp $FULL_LOG /mnt/public/cm/log/$ERROR_LOG_FILE
}

cd $SRC_DIR && rm -rf * || mkdir -p $SRC_DIR
cd $SRC_DIR/.repo && rm -rf manifest* project.list
cd $SRC_DIR

repo init -u appler:netcast/manifests.git -b $TARGET_BRANCH --repo-url=appler:tools/repo.git >> repo.log 2>&1
repo sync -d >> repo.log 2>&1

# Swtich to debug branch 
cd $SRC_DIR/netcast/os/frameworks/base; git checkout origin/infthink/sandbox/chromecast1.0

cd $SRC_DIR/netcast/os
PLATFORM_ID=Firefly VERSION_CODE=$DATE_TIME ./rkst/mkimageota.sh 8 -j8 >> $FULL_LOG 2>&1

if [[ $? -ne 0 ]]; then
    error_log
    exit 1 
fi

cd $SRC_DIR
repo manifest -r -o manifest.xml

[[ -z $IS_DEBUG ]] && sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/$DEBUG_INFO/$DATE_TIME/ &&
    cd $SRC_DIR/netcast/os/rockdev && zip -r image.zip Image/* &&
    sudo cp -r $SRC_DIR/manifest.xml $SRC_DIR/netcast/os/rockdev/*.zip /mnt/public/cm/$TARGET_BRANCH/$DEBUG_INFO/$DATE_TIME/
