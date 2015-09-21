#!/bin/bash

# This fixture tests a complete real run

# All paths relative to this directory
DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi; DIR=`readlink -m "$DIR"`

# Scratch area
TMP=

# Template root
TEMPLATE="$DIR/templates/realRun2"

# Timestamp info
declare -a TIME=(`date +"%Y"` `date +"%m"` `date +"%d"`)

createConfiguration() {
    TMP=`mktemp -d` || return 1
    echo "INFO: mktmp created directory: '$TMP'"

    # Build substitution list
    local -A l_replaceMe=(
	    ['H']='#'
	    ['DEST_DIR']="$TMP/destdir"
	    ['BACKUP_PATH']="$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing"
	    ['FNCTAGS_0']=$RANDOM
	    ['FNCTAGS_1']=$RANDOM
	    ['FNCTAGS_2']=$RANDOM
        ['TEMPLATE_ROOT']="$TEMPLATE"
        ['RANDOM']=$RANDOM
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
    rm -rvf "$TMP"
}

runtests() {
    # Actual test
    ./rbbackup.sh -i -c "$TMP/parsed/config/rbbackup.conf" testRun testing >"$TMP/output/out1.log" 2>"$TMP/output/out2.log"
    assertEquals "Exit code" 0 $?       # check exit == 0
    grep "$TMP/parsed/config/rbbackup.conf" <"$TMP/output/out1.log" | grep "global" >/dev/null
    assertEquals "global config" 0 $?   # check used global configuration
    grep "$TMP/parsed/config/targets/testRun.conf" <"$TMP/output/out1.log" | grep "target" >/dev/null
    assertEquals "target config" 0 $?   # check used target configuration
    
    cat "$TMP/output/out1.log" | awk -f "$TMP/parsed/testSupport/check1.awk"
    assertEquals "hook functions" 0 $?  # check hooks were called in order
    assertTrue "Lock exists?" "[ -f $TMP/destdir/target.lck ]"

    # compare directory structure and permissions
    ls -lARn --full-time "$TMP/parsed/target_live" > "$TMP/output/ls1.log" || fail "Ls 1 failed"
    ls -lARn --full-time "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing" > "$TMP/output/ls2.log" || fail "Ls 2 failed"
    diff -qN "$TMP/output/ls1.log" "$TMP/output/ls2.log" >/dev/null
    assertEquals "Backup structure" 0 $?
    
    # compare file contents
    diff -qrN "$TMP/parsed/target_live" "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing" >/dev/null
    assertEquals "Backup contents" 0 $?
}

testInitialRun() {
    createConfiguration || fail "Config setup failed!" || exit 1
    runtests
    #cleanupConfiguration
}


. $SHUNIT
