#!/bin/awk -f

BEGIN {
    seen=-1
}
/###FNCTAGS_0###/ {
    if (seen != -1) exit 1
    seen++
}
/###FNCTAGS_1###/ {
    if (seen != 0) exit 2
    seen++
}
/###FNCTAGS_2###/ {
    if (seen != 1) exit 3
    seen++
}
END {
    if (seen != 2) {
        print "seen is:", seen
        exit 4
    }
}
