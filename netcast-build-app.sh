#!/bin/bash -
TARGET_BRANCH="${TARGET_BRANCH-infthink-firefly2.0-bunble}"
SRC_DIR=~/$TARGET_BRANCH
DATE_TIME=$(date +%Y%m%d%H%M)

APP_FULL_LOG=$SRC_DIR/build_app.log
APP_PART_LOG=$SRC_DIR/build_app_part.log
APP_ERROR_LOG_FILE=$TARGET_BRANCH-build-app-error-$DATE_TIME.log

export PATH=/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/android/android-ndk-r9d:/opt/android/adt/sdk/tools:/opt/android/adt/sdk/platform-tools:/opt/android/adt/sdk/build-tools/android-4.4.2:/opt/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

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
    exit 1
fi

sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/debug/$DATE_TIME/app/
sudo cp $PROJECT_PATH/bin/$PROJECT_NAME-$BUILD_TYPE.apk /mnt/public/cm/$TARGET_BRANCH/debug/$DATE_TIME/app/
}

# Library project build
$(android_app_build "android-v7-appcompat" "$SRC_DIR/netcast/app/cast_sdk_android/lib_source/appcompat" "release")
$(android_app_build "android-v7-mediarouter" "$SRC_DIR/netcast/app/cast_sdk_android/lib_source/mediarouter" "release")
$(android_app_build "cast_sdk_android" "$SRC_DIR/netcast/app/cast_sdk_android" "release")
$(android_app_build "CastCompanionLibrary" "$SRC_DIR/netcast/app/cast_videos_sender_android/lib_source/CastCompanionLibrary-android" "release")
$(android_app_build "it-base" "$SRC_DIR/netcast/app/it-base" "release")
$(android_app_build "vitamio" "$SRC_DIR/netcast/app/itmc/lib_source/vitamio" "release")
$(android_app_build "PullToRefresh" "$SRC_DIR/netcast/app/itmc/lib_source/PullToRefresh-library" "release")
$(android_app_build "netcast_sdk_android" "$SRC_DIR/netcast/sw/android/cast_sdk_android" "release")

# netcast1.0 app build
$(android_app_build "firefly" "$SRC_DIR/netcast/sw/android/trails/WifiSetup/WifiSetting" "release")
$(android_app_build "cast_sender_sample_ts" "$SRC_DIR/netcast/sw/android/android-sample-sender" "debug")
$(android_app_build "super_cast_player" "$SRC_DIR/netcast/app/super_cast_player" "debug")

# firefly2.0 app build
$(android_app_build "itmc" "$SRC_DIR/netcast/app/itmc" "release")
$(android_app_build "cast_videos_sender_android" "$SRC_DIR/netcast/app/cast_videos_sender_android" "debug")
$(android_app_build "cast_tictactoe_android" "$SRC_DIR/netcast/app/cast_tictactoe_android" "debug")

