#!/bin/bash
TARGET_BUILD="${TARGET_BUILD-vision}"
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

cd $SRC_DIR && rm -rf * || git clone https://github.com/flingone/B2G-FlingOne.git $SRC_DIR
cd $SRC_DIR && git reset --hard && git fetch origin && git checkout origin/master
BRANCH=vision REPO_INIT_FLAGS='--repo-url=git://github.com/flingone/git-repo.git' ./config.sh -d rk30sdk-kk >> repo.log 2>&1

./build.sh >> $FULL_LOG 2>&1 && ./flash.sh >> $FULL_LOG 2>&1

if [ $? -ne 0 ]; then
    error_log
    [ -z $IS_DEBUG ] && ~/data/build/bldsys/mailto.py "$TARGET_BUILD build failed" "Full log address: smb://share/Public/user/shawn/build/log/$ERROR_LOG_FILE" "$PART_LOG"
    exit 1
fi

cd $SRC_DIR && repo manifest -r -o manifest.xml
cd $SRC_DIR && zip -r $TARGET_BUILD-$DATE_TIME.zip rockdev/* && cd $SRC_DIR

[ -z $IS_DEBUG ] && mkdir -p /mnt/public/$DEST_DIR/ && 
cp -r $SRC_DIR/manifest.xml $SRC_DIR/$TARGET_BUILD-$DATE_TIME.zip /mnt/public/$DEST_DIR/

[ -z $IS_DEBUG ] && ~/data/build/bldsys/mailto.py "$TARGET_BUILD build successfully" "Please get build from smb://share/Public/$DEST_DIR/"

