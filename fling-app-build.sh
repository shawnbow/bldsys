#!/bin/bash
TARGET_BRANCH="${TARGET_BRANCH-fling-app-master}"
SRC_DIR=~/build/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
APP_FULL_LOG=$SRC_DIR/build_app.log
APP_PART_LOG=$SRC_DIR/build_app_part.log
APP_ERROR_LOG_FILE=$TARGET_BRANCH-build-app-error-$DATE_TIME.log

export USER=it
export PATH=/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/android/android-ndk-r9d:/opt/android/adt/sdk/tools:/opt/android/adt/sdk/platform-tools:/opt/android/adt/sdk/build-tools/android-4.4.2:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

cd $SRC_DIR && rm -rf * || mkdir -p $SRC_DIR
cd $SRC_DIR/.repo && rm -rf manifest* project.list
cd $SRC_DIR

repo init -u appler:fling/app/manifests.git -b master --repo-url=appler:tools/repo.git >> repo.log 2>&1
repo sync -d >> repo.log 2>&1

repo manifest -r -o manifest.xml

[ -z $IS_DEBUG ] && sudo mkdir -p /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/ &&
    sudo cp -r $SRC_DIR/manifest.xml /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/

app_error_log()
{
echo -e "Full log address:\n" >> $APP_PART_LOG
echo "http://office.infthink.com/cm/log/$APP_ERROR_LOG_FILE" >> $APP_PART_LOG
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

if [ $? -ne 0 ]; then
    app_error_log
    [ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build failed" "Full log address: http://office.infthink.com/cm/log/$APP_ERROR_LOG_FILE" "$APP_PART_LOG"
    exit 1
fi

[ -z $IS_DEBUG ] && sudo cp $PROJECT_PATH/bin/$PROJECT_NAME-$BUILD_TYPE.apk /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/

}

# Library project build
android_app_build "android-v7-appcompat" "$SRC_DIR/fling_sdk_android/lib_source/appcompat" "release"
android_app_build "android-v7-mediarouter" "$SRC_DIR/fling_sdk_android/lib_source/mediarouter" "release"
android_app_build "fling_sdk_android" "$SRC_DIR/fling_sdk_android" "release"
android_app_build "CastCompanionLibrary" "$SRC_DIR/fling_videos_sender_android/lib_source/CastCompanionLibrary-android" "release"
android_app_build "it-base" "$SRC_DIR/it-base" "release"

# app build
android_app_build "matchstick" "$SRC_DIR/fling_setting_android" "release"
android_app_build "fling_videos_sender_android" "$SRC_DIR/fling_videos_sender_android" "debug"

# Javascript compile
#cd $SRC_DIR && python closure-library/closure/bin/build/closurebuilder.py --root=closure-library/ --root=fling_sdk_receiver_js/project/ --namespace="fling.receiver" --output_mode=compiled --compiler_jar=fling_sdk_receiver_js/compiler.jar --output_file=fling_sdk_receiver_js/project/out/fling_receiver.js && sudo cp $SRC_DIR/fling_sdk_receiver_js/project/out/fling_receiver.js /mnt/public/cm/$TARGET_BRANCH/$DATE_TIME/

[ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build successfully" "Please get build from http://office.infthink.com/cm/$TARGET_BRANCH/$DATE_TIME/"
