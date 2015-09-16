#!/bin/sh

# This fixture tests a complete real run

DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

createConfiguration() {
    # First generate dummy configuration
    # 1) <TMP>/gconf.conf
    # 2) <TMP>/tconf
    # 3) <TMP>/tconf/testRun.conf
    # 4) <TMP>/destdir

    # 0)
    TMP=`mktemp -d` || return 1
    echo "mktmp created directory: '$TMP'"

    # 1)
    echo "conf_target_confdir='$TMP/tconf'" >> "$TMP/gconf.conf"
    
    # 2)
    mkdir -v "$TMP/tconf" || return 1

    # 3)
    # Build substitution list
    local -A l_replaceMe=(
	['H']='#'
	['DEST_DIR']="$TMP/destdir"
	['BACKUP_PATH']="$TMP/destdir/"`date +"%Y"`/`date +"%m"`/`date +"%d"`"/testing"
	['FNCTAGS_0']=$RANDOM
	['FNCTAGS_1']=$RANDOM
#	['FNCTAGS_2']=$RANDOM
    )
    local l_sedSubs=''
    for i in "${!l_replaceMe[@]}"
    do
	l_sedSubs+="s:###$i###:${l_replaceMe[$i]}:g"$'\n'
    done
    # replace tags and write to file (or exit when tags missing)
    cat "$DIR/templates/realRun/testRun.conf" | sed -r -e "$l_sedSubs" -e '/###[^#]+###/ q 1' > "$TMP/tconf/testRun.conf"
    if [ $? -ne 0 ]; then
	echo "Missing substitution!"
	tail -n1 "$TMP/tconf/testRun.conf"
	return 1
    fi
    echo "wrote config file: $TMP/tconf/testRun.conf"

    # 4)
    mkdir -v "$TMP/destdir" || return 1
}

runtests() {
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
}

cleanupConfiguration() {
    # Cleanup
    rm -rvf "$TMP"
    #echo "$destdir"
    #echo "TARGET CONF"
    #cat "$targetdir/localhost.conf"
    #echo "OUT1"
    #cat "$destdir/output/out1.log"
    #echo "OUT2"
    #cat "$destdir/output/out2.log"
    #rm -rvf "$targetdir"
    #rm -vf "$globconf"
    #rm -rvf "$destdir"
}

testInitialRun() {
    createConfiguration || fail "Setup failed!" || exit 1
    echo "should not run!!!!!"
    #createExpectedStructure
    #runtests
    #cleanupExpectedStructure
    cleanupConfiguration
}


. $SHUNIT
