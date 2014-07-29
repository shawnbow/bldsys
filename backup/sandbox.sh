#!/bin/bash -
echo $(pwd)
DATE_TIME=$(date +%Y%m%d.%H%M%S)
export LOG_FILE=build-error-$DATE_TIME.log
echo $LOG_FILE
echo $DATE_TIME
echo $DATE_TIME

test_exit()
{
echo 'test_exit entry!'

asdfasd

if [ $? -ne 0 ]; then
  echo 'error'
fi
}

test_exit

[ -z $1 ] && echo 'aaaaaa'

echo 'end of'
