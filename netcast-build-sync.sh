#!/bin/bash -
TARGET_BRANCH="${TARGET_BRANCH-infthink-firefly2.0-bunble}"
SRC_DIR=~/build/$TARGET_BRANCH
FULL_LOG=$SRC_DIR/build.log
PART_LOG=$SRC_DIR/build_part.log
DATE_TIME=$(date +%Y%m%d%H%M)
ERROR_LOG_FILE=$TARGET_BRANCH-build-error-$DATE_TIME.log
export USER=it
export PATH=/opt/jdk1.6.0_45/bin:/home/it/scrapy/bin:/var/lib/gems/1.9.1/bin:/var/lib/gems/1.8/bin:/opt/android/android-ndk-r9d:/opt/android/adt/sdk/tools:/opt/android/adt/sdk/platform-tools:/opt/android/adt/sdk/build-tools/android-4.4.2:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
[[ $1 == -d ]] && export IS_DEBUG=yes

cd $SRC_DIR && rm -rf * || mkdir -p $SRC_DIR
cd $SRC_DIR/.repo && rm -rf manifest* project.list
cd $SRC_DIR

repo init -u appler:netcast/manifests.git -b $TARGET_BRANCH --repo-url=appler:tools/repo.git >> repo.log 2>&1
repo sync -d >> repo.log 2>&1
