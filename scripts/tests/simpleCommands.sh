#!/bin/sh

# This fixture tests the output of some generic commands

testBareCall() {
    result=$(./rbbackup.sh 1>/dev/null 2>&1)
    assertEquals 'Wrong exit code' 3 $?
    assertTrue "Output does not contain 'SYNTAX'" '[ $(echo $result | grep "SYNTAX") ]'
}

testBareVersion() {
    ./rbbackup.sh -V >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterVersion() {
    ./rbbackup.sh -Vnq >/dev/null 2>&1
    assertEquals 0 $?
}

testBareHelp() {
    ./rbbackup.sh -h >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterHelp() {
    ./rbbackup.sh -hnq >/dev/null 2>&1
    assertEquals 0 $?
}

testBareVersionHelp() {
    ./rbbackup.sh -hV >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterVersionHelp() {
    ./rbbackup.sh -hVnqi >/dev/null 2>&1
    assertEquals 0 $?
}

testMissingArgConfig() {
    ./rbbackup.sh -nc >/dev/null 2>&1
    assertEquals 3 $?
}

testPropperDryRun() {
    ./rbbackup.sh -nq localhost >/dev/null 2>&1
    assertEquals 0 $?
}

testPropperDryRunWithReason() {
    ./rbbackup.sh -nq localhost testing >/dev/null 2>&1
    assertEquals 0 $?
}

testTooManyArgs() {
    ./rbbackup.sh -nq localhost testing toomuch >/dev/null 2>&1
    assertEquals 3 $?
}


. $SHUNIT
