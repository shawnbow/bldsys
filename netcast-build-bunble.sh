#!/bin/bash -
TARGET_BRANCH="${TARGET_BRANCH-infthink-firefly2.0}"
SRC_DIR=~/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d.%H%M%S)
ERROR_LOG_FILE=$TARGET_BRANCH-build-error-$DATE_TIME.log
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

cd $SRC_DIR/netcast/os
./rkst/mkimage.sh 8 -j8 >> $FULL_LOG 2>&1

if [[ $? -ne 0 ]]; then
    error_log
    [[ -z $IS_DEBUG ]] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH os build failed" "Full log address: smb://10.0.0.201/public/cm/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1 
fi

cd $SRC_DIR
repo manifest -r -o manifest.xml

[[ -z $IS_DEBUG ]] && sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/ &&
    cd $SRC_DIR/netcast/os/rockdev && zip -r image.zip Image/* &&
    sudo cp -r $SRC_DIR/manifest.xml $SRC_DIR/netcast/os/rockdev/image.zip /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/

## Build Apps
APP_FULL_LOG=$SRC_DIR/build_app.log
APP_PART_LOG=$SRC_DIR/build_app_part.log
APP_ERROR_LOG_FILE=$TARGET_BRANCH-build-app-error-$DATE_TIME.log

app_error_log()
{
echo -e "Full log address:\n" >> $APP_PART_LOG
echo "smb://10.0.0.201/public/cm/log/$APP_ERROR_LOG_FILE" >> $APP_PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> last 100 lines\n" >> $APP_PART_LOG

tail -n 100 $APP_FULL_LOG >> $APP_PART_LOG

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter without warning\n" >> $APP_PART_LOG
cat $APP_FULL_LOG | grep -v -i warning | grep -v "?" | grep -v "\^" | grep -B 50 [\ ][Ee]rror[:\ ] >> $APP_PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter end\n" >> $APP_PART_LOG

sudo cp $APP_FULL_LOG /mnt/public/cm/log/$APP_ERROR_LOG_FILE
}

android_app_build()
{
PROJECT_NAME=$1
PROJECT_PATH=$2
BUILD_TYPE=$3
echo -e "Project $PROJECT_NAME located in $PROJECT_PATH\n" >> $APP_FULL_LOG
cd $PROJECT_PATH
echo -e "Setup ant build property...\n" >> $APP_FULL_LOG
android update project -n $PROJECT_NAME -p . -t 1 >> $APP_FULL_LOG
ant $BUILD_TYPE >> $APP_FULL_LOG

if [[ $? -ne 0 ]]; then
    app_error_log
    [[ -z $IS_DEBUG ]] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH app build failed" "Full log address: smb://10.0.0.201/public/cm/log/$APP_ERROR_LOG_FILE" "$APP_PART_LOG"
    exit 1
fi

sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/app/
sudo cp $PROJECT_PATH/bin/$PROJECT_NAME-$BUILD_TYPE.apk /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/app/
}

$(android_app_build "cast_sdk_android" "$SRC_DIR/netcast/app/cast_sdk_android" "release")
$(android_app_build "it-base" "$SRC_DIR/netcast/app/it-base" "release")
$(android_app_build "vitamio" "$SRC_DIR/netcast/app/itmc/lib_source/vitamio" "release")
$(android_app_build "PullToRefresh" "$SRC_DIR/netcast/app/itmc/lib_source/PullToRefresh-library" "release")

$(android_app_build "cast_videos_sender_android" "$SRC_DIR/netcast/app/cast_videos_sender_android" "debug")
$(android_app_build "itmc" "$SRC_DIR/netcast/app/itmc" "release")
$(android_app_build "cast_sender_sample_ts" "$SRC_DIR/netcast/sw/android/android-sample-sender" "debug")
$(android_app_build "fireflycast" "$SRC_DIR/netcast/sw/android/trails/WifiSetup/WifiSetting" "release")
$(android_app_build "super_cast_player" "$SRC_DIR/netcast/app/super_cast_player" "debug")

[[ -z $IS_DEBUG ]] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH full build successfully" "Please get build from smb://10.0.0.202/cm/$TARGET_BRANCH/$DATE_TIME/"
