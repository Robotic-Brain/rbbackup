rsync --filter=._- --log-file=/tmp/tmp.vSJRleOLa4/destdir/2015/09/26/testing/rsync.log -s --delete-delay --partial --partial-dir=/tmp/tmp.vSJRleOLa4/destdir/partial --numeric-ids -SaHAXcyy --temp-dir=/tmp/tmp.vSJRleOLa4/destdir/temp --read-batch=/tmp/tmp.vSJRleOLa4/destdir/2015/09/26/testing/rsbatch --link-dest=/tmp/tmp.vSJRleOLa4/destdir/2015/09/20/testing ${1:-/tmp/tmp.vSJRleOLa4/destdir/2015/09/26/testing/fs} <<'#E#'
- /exclude_me
#E#
