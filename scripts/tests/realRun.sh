#!/bin/bash

# This fixture tests a complete real run

# All paths relative to this directory
DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi; DIR=`readlink -m "$DIR"`

# Scratch area
TMP=

# Template root
TEMPLATE="$DIR/templates/realRun"

# Timestamp info
declare -a TIME=(`date +"%Y"` `date +"%m"` `date +"%d"`)
declare TUNC_TIME=`date +"%s" | head -c -3`

createConfiguration() {
    # Magic var: DBG_OPEN_TMP
    #            set to 1 to prevent deletion of <TMP> and open in Thunar
    # Magic folders:
    # <TMP>/output     # temporary stdout and stderr for later parsing
    # <TMP>/destdir    # backup storage destination root
    # <TMP>/parsed     # almost exact copy of <TEMPLATE> dir (see substitutions below)
    
    TMP=`mktemp -d` || return 1
    if [ "$DBG_OPEN_TMP" -ne 0 ]; then
        xdg-open "$TMP"
    fi
    echo "INFO: mktmp created directory: '$TMP'"

    # Build substitution list
    local -A l_replaceMe=(
	    ['H']='#'
	    ['TARGET_ROOT_PATH']="$TMP/destdir"
	    ['BACKUP_PATH']="$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing"
	    ['FNCTAGS_0']=$RANDOM
	    ['FNCTAGS_1']=$RANDOM
	    ['FNCTAGS_2']=$RANDOM
        ['TMP']="$TMP"
        ['PARSED_ROOT']="$TMP/parsed"
        ['RANDOM']=$RANDOM
        ['START_TIME']=$TUNC_TIME
    )
    local l_sedSubs=''
    for i in "${!l_replaceMe[@]}"
    do
	    l_sedSubs+="s:###$i###:${l_replaceMe[$i]}:g"$'\n'
    done

    mkdir -v "$TMP/parsed" | sed -r 's/.*/INFO: &/' || return 1
    (
        cd "$TEMPLATE"
        # for each directory in template directory...
        find . -type d | while IFS= read -r file; do
            mkdir -vp "$TMP/parsed/$file" | sed -r 's/.*/INFO: &/' || return 1
        done
        # for each file in template directory...
        find . -type f | while IFS= read -r file; do
            # ...replace tags and write to scratch dir (or exit when tags missing)
            cp -a "$TEMPLATE/$file" "$TMP/parsed/$file"
            cat "$TEMPLATE/$file" | sed -r -e "$l_sedSubs" -e '/###[^#]+###/ q 1' > "$TMP/parsed/$file"
            if [ $? -ne 0 ]; then
	            fail "Missing substitution!"
	            tail -n1 "$TMP/parsed/$file"
	            return 1
            fi
            echo "INFO: wrote parsed file: $TMP/parsed/$file"
        done
    )

    mkdir -v "$TMP/destdir" | sed -r 's/.*/INFO: &/' || return 1
    mkdir -v "$TMP/output" | sed -r 's/.*/INFO: &/' || return 1
}

cleanupConfiguration() {
    # Cleanup
    if [ "$DBG_OPEN_TMP" -eq 0 ]; then
        rm -rvf "$TMP" | sed -r 's/.*/INFO: &/'
    fi
}

runtests() {
    # Actual test
    ./rbbackup.sh -i -c "$TMP/parsed/config/rbbackup.conf" testRun testing >"$TMP/output/out1.log" 2>"$TMP/output/out2.log"
    assertEquals "Exit code" 0 $?       # check exit == 0
    tail -n1 "$TMP/output/out1.log" | grep -i "done" >/dev/null
    assertEquals "last line contains 'Done'" 0 $? # check that it ran till the end
    grep "$TMP/parsed/config/rbbackup.conf" <"$TMP/output/out1.log" | grep "global" >/dev/null
    assertEquals "global config" 0 $?   # check used global configuration
    grep "$TMP/parsed/config/targets/testRun.conf" <"$TMP/output/out1.log" | grep "target" >/dev/null
    assertEquals "target config" 0 $?   # check used target configuration

    # check base snapshot
    grep "NONE" <"$TMP/output/out1.log" | grep "base" >/dev/null
    assertEquals "base snapshot" 0 $?   # check used base snapshot
    
    cat "$TMP/output/out1.log" | awk -f "$TMP/parsed/testSupport/check1.awk"
    assertEquals "hook functions" 0 $?  # check hooks were called in order
    assertTrue "Lock exists?" "[ -f $TMP/destdir/target.lck ]"

    # remove excluded files from pattern before comparing
    rm -rvf "$TMP/parsed/target_live/exclude_me" | sed -r 's/.*/INFO: &/'
    
    # compare directory structure and permissions
    ls -lARn --time-style=+ "$TMP/parsed/target_live" | grep -v "$TMP" > "$TMP/output/ls1.log" || fail "Ls 1 failed"
    ls -lARn --time-style=+ "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing/fs" | grep -v "$TMP" > "$TMP/output/ls2.log" || fail "Ls 2 failed"
    diff -qN "$TMP/output/ls1.log" "$TMP/output/ls2.log" >/dev/null
    assertEquals "Backup structure" 0 $?
    
    # compare file contents
    diff -qrN "$TMP/parsed/target_live" "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing/fs" >/dev/null
    assertEquals "Backup contents" 0 $?

    # check snapshot info file
    cat "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing/info.txt" | grep -e '^start_time: [0-9]*' | grep "$TUNC_TIME"
    assertEquals "snapshot info: start_time" 0 $?
    cat "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing/info.txt" | grep -e '^end_time: [0-9]*'
    assertEquals "snapshot info: end_time" 0 $?

    # check lastPath file
    cat "$TMP/destdir/lastPath" | grep -e '^'"$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing"'$'
    assertEquals "Last path writen" 0 $?
}

testInitialRun() {
    createConfiguration || fail "Config setup failed!" || exit 1
    runtests
    cleanupConfiguration
}


. $SHUNIT
