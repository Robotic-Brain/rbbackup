#!/bin/bash

### Basic configuration
# These can/should be overridden in config file

config_file='/etc/rbbackup.conf'    # path to configuration file
target_conf='/etc/rbbackup.d/'      # prefix for target specific configuration
filter_file='/etc/rbbackup/filter f'   # path to rsync filter file (read from config)
target='localhost'                  # backup target name (defaults to localhost)
backup_src='/'                      # rsync source URL (defaults to /)
backup_dst='/backups'               # root of backup filesystem
batch_name=                         # name of batch file or empty if not used

### DO NOT EDIT BELOW THIS LINE ###

#curr_backup=                        # absolute path to new backup (gets linked against prev_backup)

# this function prints a quick usage screen
function usage() {
    cat <<EOF
Usage: $0 [-nhq] [-c <config>] [-a|-m <reason>] [<target>]

EOF
}

# this function prints the help screen
function fullhelp() {
    usage
    cat <<EOF
Options:
    -a    Automatic Mode
              Use this in automated scripts for daily backups. The base backup is automatically determined.
              Backups are saved in '$backup_dst/$target/daily/%Y/%m/%d'

    -m <reason>
          Manual Mode
              This creates a manual backup. The given <reason> is included in the backup path.
              Backups are saved in '$backup_dst/$target/manual/%Y/%m/%d/<reason>'

    -c <config>
              Manually specify configuration file. This file gets sourced before any processing
              Default is: "/etc/rbbackup.conf"

    -n    Dry run
              Do not actually perform backup. Calls rsync with "-nvi"

    -h    Help
              Show this help screen

    -q    Quiet
              Don't output anything

    <target>
          Backup target
              This is the name of the backup root directory.
              Only one backup can run on each target simultaneously.
              The url given to rsync can be configured in the config file.

Exit codes:
     0    Success

     1    Generic error

     2    Backup in progress. Could not acquire lock.

EOF
    exit 0;
}

# lock backup target or exit if not possible
function lockme() {
    log "Try to aquire lock on target..."
    echo "TODO: LOCK"
    echo "Target: " $target
    echo "Mode: " $mode
    echo "Reason: " $reason
    echo "Quiet? " $quiet
    log "...target locked!"
}

# unlock backup target
function unlockme() {
    log "Unlocking target"
    echo "TODO: UNLOCK"
}

# log helper to enforce quiet mode
function log() {
    if [ $quiet -eq 0 ]; then
        echo $1
    fi
}

# actual backup logic
function do_backup() {
    date_stamp=(`date +"%Y"` `date +"%m"` `date +"%d"`)
    newest_file="$backup_dst/$target/newest"
    prev_backup=`cat $newest_file`                        # absolute path to base backup
    
    # these variables get passed as rsync options
    partial_dir="$backup_dst/$target/.temp/rpart"   # directory to save partial transfers in (--partial-dir)
    temp_dir="$backup_dst/$target/.temp/rtmp"       # temp dir for rsync (--temp-dir)
    log_file="$backup_dst/$target/.temp/rlog.log"       # rsync log file (--log-file)
    link_dest_dir="$prev_backup/snapshot"           # previous backup path
    src_url="$backup_src"
    dst_url="$backup_dst/$target"

    snapshot_base=
    
    if [ $mode -eq 1 ]; then
        # automatic mode
        snapshot_base="$dst_url/daily/${date_stamp[0]}/${date_stamp[1]}/${date_stamp[2]}"
    else
        # manual mode
        snapshot_base="$dst_url/manual/${date_stamp[0]}/${date_stamp[1]}/${date_stamp[2]}/$reason"
    fi

    dst_url="$snapshot_base/snapshot"
    info_file="$snapshot_base/info.txt"
    package_file="$snapshot_base/packages.txt"
    usrHashes="$snapshot_base/usrHashes.txt"
    
    # remove --write-batch if not needed
    batch_option=
    if [ ! -z "$batch_name" ]; then
        batch_option=--write-batch=$batch_name
    fi

    # remove --link-dest if not needed (initial snapshot)
    link_dest_option=
    if [ ! -z "$prev_backup" ]; then
        link_dest_option="--link-dest=$link_dest_dir"
    fi
    
    # add --filter - error if not given
    filter_option=
    if [ ! -z "$filter_file" ]; then
        filter_option="--filter=. $filter_file"
    fi
    if [ -z "$filter_option" ]; then
        echo "Error: No filter supplied! Might cause infinite loop... Aborting!" >&2
        exit 1;
    fi

    # add dry run options
    dryrun_option=
    if [ $dry_run -ne 0 ]; then
        log "Performing dry run!"
        dryrun_option=-nvi
    else
        echo $snapshot_base > $newest_file
        mkdir -p $snapshot_base $partial_dir $temp_dir
        echo "Based on: $link_dest_dir" >> $info_file
        echo "Start: $(date +%s)" >> $info_file
    fi

    # add quiet flag
    quiet_option=
    if [ $quiet -ne 0 ]; then
        quiet_option=-q
    fi
    
    # call rsync
    log "Calling rsync..."
    ./a.out rsync $quiet_option $dryrun_option -s --delete-delay --partial --partial-dir="$partial_dir" --numeric-ids -SaHAXcyy --temp-dir="$temp_dir" --log-file="$log_file" $batch_option "$filter_option" "$link_dest_option" "$src_url" "$dst_url"
    
    if [ ! $dry_run -ne 0 ]; then
        # calculate md5s of /usr
        md5 `find $src_url` > $usrHashes

        # writing end time
        echo "End: $(date +%s)">> $info_file
    fi
}

### Main script starts here

mode=0     # backup mode: 0=none, 1=daily, 2=manual
code=0     # return code
reason=    # reason for manual mode
dry_run=0
quiet=0

OPTIND=1
while getopts ":am:c:nhq" opt; do
    case $opt in
        h)
            fullhelp
            exit 0
            ;;
        q)
            quiet=1
            ;;
        c)
            config_file=$OPTARG
            ;;
        n)
            dry_run=1
            ;;
        a)
            mode=1
            ;;
        m)
            mode=2
            reason=$OPTARG
            ;;
        :)
            echo "SYNTAX: Required argument missing!" >&2
            code=1
            ;;
        \?)
            echo "SYNTAX: Unknown argument: " $OPTARG >&2
            code=1
            ;;
        *)
            echo "BUG: TODO CASE: " $OPTIND $OPTARG $opt >&2
            ;;
    esac
done

if [ $code -ne 0 ]; then
    usage
    exit $code
fi

shift $(($OPTIND -1))

# load default configuration
source $config_file
if [ $? -ne 0 ]; then
    echo "Error: Configuration could not be loaded! Aborting." >&2
    exit 1;
fi

if [ $# -eq 1 ]; then
    target=$1
elif [ $# -ne 0 ]; then
    echo "SYNTAX: Too many arguments!" >&2
    usage
    exit 1
fi

# load target configuration
source "$target_conf/$target" 2> /dev/null
if [ ! $? -ne 0 ]; then
    log "Loading configuration for target: $target";
fi

if [ $mode -eq 0 ]; then
    echo "SYNTAX: No mode given!" >&2
    usage
    exit 1
fi

lockme
do_backup
unlockme
log "Done"
