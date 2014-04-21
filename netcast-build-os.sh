#!/bin/bash -
TARGET_BRANCH="${TARGET_BRANCH-infthink-netcast1.0-bunble}"
SRC_DIR=~/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d.%H%M%S)
LOG_FILE=build-error-$DATE_TIME.log
export PATH=/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

error_log()
{
echo -e "full log address:\n" >> $PART_LOG
echo "smb://10.0.0.201/cm/log/$LOG_FILE" >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> last 100 lines\n" >> $PART_LOG

tail -n 100 $FULL_LOG >> $PART_LOG

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter without warning\n" >> $PART_LOG
cat $FULL_LOG | grep -v -i warning | grep -v "?" | grep -v "\^" | grep -B 50 [\ ][Ee]rror[:\ ] >> $PART_LOG
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> error filter end\n" >> $PART_LOG

sudo cp $FULL_LOG /mnt/public/cm/log/$LOG_FILE
}

cd $SRC_DIR && rm -rf * || mkdir -p $SRC_DIR
cd $SRC_DIR/.repo && rm -rf manifest* project.list
cd $SRC_DIR

repo init -u appler:netcast/manifests.git -b $TARGET_BRANCH --repo-url=appler:tools/repo.git >> repo.log 2>&1
repo sync >> repo.log 2>&1

cd $SRC_DIR/netcast/os
./rkst/mkimage.sh 8 -j8 >> $FULL_LOG 2>&1

if [[ $? -ne 0 ]]; then
    error_log
    #[[ -z $IS_DEBUG ]] && /opt/tools/bldsys/mailto_jteam "$TARGET_BRANCH build failed" "`cat $SRC_DIR/build_part.log`"
    exit 1 
fi

cd $SRC_DIR
repo manifest -r -o manifest.xml

[[ -z $IS_DEBUG ]] && sudo mkdir -p /mnt/public/cm/netcast/$DATE_TIME/ &&
    cd $SRC_DIR &&
    sudo cp -r manifest.xml $SRC_DIR/netcast/os/rockdev/* /mnt/public/cm/netcast/$DATE_TIME/
#/opt/tools/bldsys/mailto_jteam "$TARGET_BRANCH build successfully" "Please get build from smb://10.0.0.202/cm/"

