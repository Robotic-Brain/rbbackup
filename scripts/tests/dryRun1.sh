#!/bin/sh

# This fixture tests a complete dry run

testInitialDryRun() {
    # First generate dummy configuration
    # 1) /tmp/globconf
    # 2) /tmp/targetdir
    # 3) /tmp/targetdir/localhost.conf
    # 4) /tmp/destdir

    # 2)
    readonly targetdir=`mktemp -d`
    if [ $? -ne 0 ]; then
	fail "Creating temporary directory failed!"
    fi

    # 1)
    readonly globconf=`mktemp`
    if [ $? -ne 0 ]; then
	fail "Creating temporary file failed!"
    fi
    echo "conf_target_confdir='$targetdir'" >> "$globconf"
    if [ $? -ne 0 ]; then
	fail "Writing to temporary file failed!"
    fi

    # 4)
    readonly destdir=`mktemp -d`
    if [ $? -ne 0 ]; then
	fail "Creating temporary directory failed!"
    fi
    mkdir -vp "$destdir/output/"
    if [ $? -ne 0 ]; then
	fail "Creating temporary directory failed!"
    fi

    # 3)
    readonly -a FncTags=($RANDOM $RANDOM $RANDOM)
    echo "conf_backup_path='$destdir'
conf_pre_backup_f() {
    echo \"${FncTags[0]}\"
    "'
    if [ $1 != "localhost" ]; then
        # target
        echo "TEST ERROR: ${FUNCNAME[0]} 1 $1" >&2
        return 1
    fi
    if [ $2 != "testing" ]; then
        # reason
        echo "TEST ERROR: ${FUNCNAME[0]} 2 $2" >&2
        return 1
    fi
    if [ $3 -ne 1 ]; then
        # dryRun
        echo "TEST ERROR: ${FUNCNAME[0]} 3 $3" >&2
        return 1
    fi
    if [ $4 -ne 0 ]; then
        # quiet
        echo "TEST ERROR: ${FUNCNAME[0]} 4 $4" >&2
        return 1
    fi
    #if [ $5 ... ]; then
    #    # last snapshot
    #    echo "TEST ERROR: ${FUNCNAME[0]} 5 $5" >&2
    #    return 1
    #fi
    if [ $6 != "'$destdir/`date +"%Y"`/`date +"%m"`/`date +"%d"`/testing'" ]; then
        # backup path
        echo "TEST ERROR: ${FUNCNAME[0]} 6 $6" >&2
        return 1
    fi
    #if [ $7 ... ]; then
    #    # start time
    #    echo "TEST ERROR: ${FUNCNAME[0]} 7 $7" >&2
    #    return 1
    #fi
    '"
}
conf_do_backup_f() {
    echo \"${FncTags[1]}\"
    "'
    if [ $1 != "localhost" ]; then
        # target
        echo "TEST ERROR: ${FUNCNAME[0]} 1 $1" >&2
        return 1
    fi
    if [ $2 != "testing" ]; then
        # reason
        echo "TEST ERROR: ${FUNCNAME[0]} 2 $2" >&2
        return 1
    fi
    if [ $3 -ne 1 ]; then
        # dryRun
        echo "TEST ERROR: ${FUNCNAME[0]} 3 $3" >&2
        return 1
    fi
    if [ $4 -ne 0 ]; then
        # quiet
        echo "TEST ERROR: ${FUNCNAME[0]} 4 $4" >&2
        return 1
    fi
    #if [ $5 ... ]; then
    #    # last snapshot
    #    echo "TEST ERROR: ${FUNCNAME[0]} 5 $5" >&2
    #    return 1
    #fi
    if [ $6 != "'$destdir/`date +"%Y"`/`date +"%m"`/`date +"%d"`/testing'" ]; then
        # backup path
        echo "TEST ERROR: ${FUNCNAME[0]} 6 $6" >&2
        return 1
    fi
    #if [ $7 ... ]; then
    #    # start time
    #    echo "TEST ERROR: ${FUNCNAME[0]} 7 $7" >&2
    #    return 1
    #fi
    '"
}
conf_post_backup_f() {
    echo \"${FncTags[2]}\"
    "'
    if [ $1 != "localhost" ]; then
        # target
        echo "TEST ERROR: ${FUNCNAME[0]} 1 $1" >&2
        return 1
    fi
    if [ $2 != "testing" ]; then
        # reason
        echo "TEST ERROR: ${FUNCNAME[0]} 2 $2" >&2
        return 1
    fi
    if [ $3 -ne 1 ]; then
        # dryRun
        echo "TEST ERROR: ${FUNCNAME[0]} 3 $3" >&2
        return 1
    fi
    if [ $4 -ne 0 ]; then
        # quiet
        echo "TEST ERROR: ${FUNCNAME[0]} 4 $4" >&2
        return 1
    fi
    #if [ $5 ... ]; then
    #    # last snapshot
    #    echo "TEST ERROR: ${FUNCNAME[0]} 5 $5" >&2
    #    return 1
    #fi
    if [ $6 != "'$destdir/`date +"%Y"`/`date +"%m"`/`date +"%d"`/testing'" ]; then
        # backup path
        echo "TEST ERROR: ${FUNCNAME[0]} 6 $6" >&2
        return 1
    fi
    #if [ $7 ... ]; then
    #    # start time
    #    echo "TEST ERROR: ${FUNCNAME[0]} 7 $7" >&2
    #    return 1
    #fi
    '"
}
" >> "$targetdir/localhost.conf"
    if [ $? -ne 0 ]; then
	fail "Creating target configuration file failed!"
    fi

    # Actual test
    ./rbbackup.sh -ni -c "$globconf" localhost testing >"$destdir/output/out1.log" 2>"$destdir/output/out2.log"
    assertEquals "Exit code" 0 $?
    grep "$globconf" <"$destdir/output/out1.log" | grep "global"
    assertEquals "global config" 0 $?
    grep "$targetdir/localhost.conf" <"$destdir/output/out1.log" | grep "target"
    assertEquals "target config" 0 $?
    
    cat "$destdir/output/out1.log" | awk '
        BEGIN {seen=-1}
        /'${FncTags[0]}'/ {
            if (seen != -1) exit 1
            seen++
        }
        /'${FncTags[1]}'/ {
            if (seen != 0) exit 2
            seen++
        }
        /'${FncTags[2]}'/ {
            if (seen != 1) exit 3
            seen++
        }
        END {
            if (seen != 2) {
                print "seen is:", seen
                exit 4
            }
        }'
    assertEquals "hook functions" 0 $?
    assertTrue "Lock exists?" "[ -f $destdir/target.lck ]"
    ls -l "$destdir" | wc -l | grep "3" >/dev/null
    assertEquals "Empty destination" 0 $?

    # Cleanup
    echo "$destdir"
    echo "TARGET CONF"
    cat "$targetdir/localhost.conf"
    echo "OUT1"
    cat "$destdir/output/out1.log"
    echo "OUT2"
    cat "$destdir/output/out2.log"
    rm -rvf "$targetdir"
    rm -vf "$globconf"
    rm -rvf "$destdir"
}


. $SHUNIT
