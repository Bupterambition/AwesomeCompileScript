#!/bin/sh
function confound() {
    cd $1
    # echo $1
    filelist=`ls`
    for file in $filelist
    do
        # echo $file
        if test -f $file 
        then
            FILE=$file;
            if [ "$FILE" == "Podfile" ] || [ "$FILE" == "podfile" ]
            then
                # echo $file
                workspace=`find *.xcworkspace -depth 0`
                searchspace=${workspace%.*}
                exist=`echo $ALL_Open_XCWorkSpace|egrep -m 1 -o "DerivedData/$searchspace"`
                if [[ -z "$exist" ]]; then
                    osascript -e 'display notification "begin pod update" with title "Warning:⚠️ pod update"'
                    #防止在编写代码时进行pod update
                    pod update > /dev/null
                fi
                #找出Scheme，临时方案，后面可以通过XcodeProj自动新建一个Scheme
                schemelist=`xcodebuild -list`
                schemeline=`echo $schemelist|xargs -n 1|egrep -n -i 'schemes'|awk -F ':' '{print $1}'`
                echo $schemelist|xargs -n 1 > schemes.txt
                schemeline=`expr $schemeline + 1`
                schemeName=`sed -n "$schemeline p" schemes.txt`
                rm -rf schemes.txt
                xcodebuild clean
                xcodebuild build -workspace $workspace -scheme $schemeName -destination 'platform=iOS Simulator,name=iPhone 7'
            fi
        fi
        if test -d $file
        then
            FILE=$file;
            if [ "${FILE#*.}" != "framework" ] && [ "${FILE#*.}" != "xcworkspace" ] && [ "${FILE#*.}" != "xcodeproj" ] && [ "$FILE" != "Pods" ]
                then
                # echo $file
                confound $file
            fi
        fi
    done
    cd ..
}
function eachPull() {
    cd $1
    filelist=`ls`
    for file in $filelist
    do
        if test -d $file
        then
            FILE=$file;
            cd $file
            if [ "${FILE#*.}" != "framework" ] && [ "${FILE#*.}" != "xcworkspace" ] && [ "${FILE#*.}" != "xcodeproj" ] && [ "$FILE" != "Pods" ]
                then
                currentBranch=`git branch|egrep -n '\*'|awk -F ':' '{print $1}'`
                git pull origin $currentBranch > /dev/null
            fi
            cd ..
        fi
    done
    cd ..
}
osascript -e 'display notification "Compiler Begin" with title "AwesomeXcodeComplierScript"'
declare -x ALL_Open_XCWorkSpace=`lsof -c com.apple`
eachPull $1

confound $1
osascript -e 'display notification "Compiler Done" with title "AwesomeXcodeComplierScript"'
