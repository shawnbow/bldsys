#!/bin/bash -
test_exit()
{
echo 'want to seee'
#exit 1
echo 'exit ...'
}

$(test_exit)
$(test_exit)

echo 'end of'

android_app_build()
{
echo 'ls -'
exit 1
}

android_app_build
android_app_build
android_app_build
