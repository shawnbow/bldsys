#!/bin/bash
TARGET_BRANCH="${TARGET_BRANCH-gunpowder}"
SRC_DIR=~/build/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
ERROR_LOG_FILE=$TARGET_BRANCH-build-chromium-error-$DATE_TIME.log
DEST_DIR=cm/$TARGET_BRANCH/$DATE_TIME

export DEPOT_TOOLS_UPDATE=0
export PATH=/opt/bin:/opt/depot_tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

cd $SRC_DIR && rm -rf * || git clone appler:flint/chromium $SRC_DIR
cd $SRC_DIR && git reset --hard && git fetch origin && git checkout origin/$TARGET_BRANCH

git log > gitlog.txt

[ -z $IS_DEBUG ] && sudo mkdir -p /mnt/public/$DEST_DIR/ &&
    sudo cp -r $SRC_DIR/gitlog.txt /mnt/public/$DEST_DIR/

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

cd $SRC_DIR; gclient runhooks >> $FULL_LOG
if [ $? -ne 0 ]; then
    error_log
    [ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build failed" "Full log address: http://office.infthink.com/cm/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1
fi

cd $SRC_DIR/src; ninja -C out/Release chrome_shell_apk -j4 >> $FULL_LOG
if [ $? -ne 0 ]; then
    error_log
    [ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build failed" "Full log address: http://office.infthink.com/cm/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1
fi

[ -z $IS_DEBUG ] && sudo mkdir -p /mnt/public/$DEST_DIR/ &&
    sudo cp -r $SRC_DIR/src/out/Release/apks/ChromeShell.apk /mnt/public/$DEST_DIR/

[ -z $IS_DEBUG ] && /opt/tools/bldsys/mailto.py "$TARGET_BRANCH build successfully" "Please get build from http://office.infthink.com/$DEST_DIR/"
