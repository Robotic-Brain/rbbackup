#!/bin/bash

### Variable Naming Conventions
# conf_*     These variables can and should be changed in
#            configuration files. These get sourced later on.
#
# opt_*      These are local variables holding the command line options
#
# l_*        Local (private) variables

### Helper Functions
function print_version() {
    echo "rbBackup version 0.0.1"
}

function usage() {
    cat <<EOF
Usage: $0 [-nhqi] [-c <config_dir>] <target> [<reason>]
    -n    Dry-run
    -h    Help
    -q    Quiet mode
    -i    Initial backup (don't specify base)
    -V    Version information
    -c    Use <config_dir> for configuration files
    <target> Backup (remote) target
    <reason> Defaults to 'daily'

EOF
}

function fullhelp() {
    usage
    cat <<EOF
Options:
    -n    Dry run
              Do not actually perform backup. Calls rsync with "-nvi".

    -h    Help
              Show this help screen.

    -q    Quiet
              Don't output anything.

    -i    Initial
              Manually create initial backup.
              This removes the --link-dest option from rsync.

    -V    Version
              Print version information and exit normally.

    -c <config>
              Manually specify configuration file.
              This file gets sourced before any processing.
              Default is: "/etc/rbbackup.conf"

    <target>
          Backup target
              This is the name of the backup root directory.
              Only one backup can run on each target simultaneously.
              The url given to rsync can be configured in the config file.
              The base backup is automatically determined unless -i is used.

    <reason>
          Backup reason defaults to 'daily'
              The given <reason> is included in the backup path.
              Backups are saved in '<conf_backup_path>/<YYYY>/<MM>/<DD>/<reason>'

Configuration:
    General
        All configuration files are loaded with 'source <file>' therefore
          you can use any shell scripting you like.

    /etc/rbbackup.conf, rbbackup -c <conf_file>
        This is the global configuration file.
        It gets sourced directly after processing of the commandline
          arguments, and can be changed with the -c option.
        The most usefull option in this file is 'conf_target_confdir',
          since it can be used to change where the target specific
          configuration files are stored.
        See "Variables" section below for possible options.

    /etc/rbbackup.d/, <conf_target_confdir>
        This directory holds the target specific configuration files.
        Its exact path can be changed with the 'conf_target_confdir' variable.

    /etc/rbbackup.d/<target>.conf, <conf_target_confdir>/<target>.conf
        These files get sourced right before the actual backup runs.
        See "Variables" section below for possible options.

Variables:
    conf_target_confdir
        This variable holds the path of the configuration directory
          containing the target specific configuration files.
        Use this only in the global config file, since it has
          no effect after the target config file was already sourced.

    conf_backup_path
        This variable holds the path to the final backup.
        Its meaning changes between the global and target
          specific configuration files.
        Global: This path gets postfixed with the target name
                eg.: <conf_backup_path>/<target>
        Target: Before sourcing the target configuration, this
                  is already populated with the above value and
                  will not be changed again.
                This means you can choose your own backup root,
                  depending on target name.

    conf_rsync_source
        This is exactly the source passed to rsync,
          and can be anything rsync expects

    opt_dryRun (READONLY)
        1 if -n was specified. 0 otherwise.

    opt_quiet (READONLY)
        1 if -q was specified. 0 otherwise.

    opt_initial (READONLY)
        1 if -i was specified. 0 otherwise.

    opt_config (READONLY)
        Path to global configuration file.

    opt_target (READONLY)
        Value of <target>. Name of current target.

    opt_reason (READONLY)
        Value of <reason>. Reason for current invocation.

Exit codes:
     0    Success.

     1    Generic error.

     2    Backup in progress. Could not acquire lock.

     3    Usage Error.

EOF
}

if [[ "$-" == *x* ]]; then
    l_real_debug_mode=1
else
    l_real_debug_mode=0
fi

function log() {
    set +x
    if [ $opt_quiet -eq 0 ]; then
	    echo "$@"
    fi
    if [ $l_real_debug_mode -ne 0 ]; then
	    set -x
    fi
}

function lock_target() {
    log "Locking Target..."
    readonly conf_backup_path
    exec 200>"$conf_backup_path/target.lck"
    flock -en 200
    if [ $? -ne 0 ]; then
	    echo "Failed to aquire lock. Backup in progress?" >&2
	    exit 2
    fi
}

# args: <snapshot_path>
function check_backup_structure() {
    echo "TODO: function: ${FUNCNAME[0]}"
    false && conf_check_backup_structure_f $@
    return $?
}

# args: <last_snapshot_path> <this_snapshot_path> <time_start> <time_end> <target_root>
function write_backup_info() {
    echo "TODO: function: ${FUNCNAME[0]}"
    conf_write_backup_info_f $@
    return $?
}

# args: <target> <reason> <dry> <quiet> <last_snap_path> <this_snap_path> <time_start> <target_root>
function pre_backup() {
    local l_params='-p'
    if [ $opt_quiet -eq 0 ]; then
        l_params+='v'
    fi
    mkdir "$l_params" "$6" || return 1
    mkdir "$l_params" "$8/temp" || return 1
    conf_pre_backup_f $@
    return $?
}

# args: <target> <reason> <dry> <quiet> <last_snap_path> <this_snap_path> <time_start> <target_root>
function do_backup() {
    echo "TODO: function: ${FUNCNAME[0]}"
    conf_do_backup_f $@
    local l_rsync='rsync'
    if [ $3 -ne 0 ]; then  # add 'nvi' flags on dry run
        l_rsync+=' -ni'
        if [ $4 -eq 0 ]; then
            l_rsync+='v'
        fi
    else
        l_rsync+=' --log-file='"$6/rsync.log"
    fi
    $l_rsync -s --delete-delay --partial --partial-dir="$8/partial" --numeric-ids -SaHAXcyy --temp-dir="$8/temp" --write-batch="$6/rsbatch" --filter='. '"$conf_rsync_filter" --link-dest="$5" "$conf_rsync_source" "$6/fs"
    return $?
}

# args: <target> <reason> <dry> <quiet> <last_snap_path> <this_snap_path> <time_start> <target_root>
function post_backup() {
    echo "TODO: function: ${FUNCNAME[0]}"
    conf_post_backup_f $@
    if [ $3 -eq 0 ]; then
        gzip --best "$6/rsync.log"
    fi
    return $?
}

### Configuration options (can/should be overwritten in config files)
conf_target_confdir='/etc/rbbackup.d/'   # in this directory are the target specific config files
conf_backup_path='.'                     # this will be the backup destination
conf_pre_backup_f() {                    # hook function arguments:
    return                               # 1) $opt_target           # target name
}                                        # 2) $opt_reason           # reason
conf_do_backup_f() {                     # 3) $opt_dryRun           # 1 if dry-run
    return                               # 4) $opt_quiet            # 1 if quiet mode
}                                        # 5) $l_last_snapshot      # path to last snapshot (without fs fragment)
conf_post_backup_f() {                   # 6) $l_backup_files_path  # path to this snapshot (without fs fragment)
    return                               # 7) $l_time_start         # starttime of backup
}                                        # 8) $conf_backup_path     # target root location

conf_check_backup_structure_f() {        # 1) <snapshot_path_to_check>
    return
}
conf_write_backup_info_f() {             # args: <last_snapshot_path> <this_snapshot_path> <time_start> <time_end> <target_root>
    return
}

### Main script starts here
function main() {
    opt_dryRun=0
    opt_help=0
    opt_quiet=0
    opt_initial=0
    opt_version=0
    opt_config='/etc/rbbackup.conf'
    opt_config_set=0
    opt_target=
    opt_reason='daily'
    
    l_code=0    # Return code
    
    OPTIND=1
    while getopts ":nhqiVc:" l_opt; do
	    case $l_opt in
	        n)
		        opt_dryRun=1
		        ;;
	        h)
		        opt_help=1
		        ;;
	        q)
		        opt_quiet=1
		        ;;
	        i)
		        opt_initial=1
		        ;;
	        V)
		        opt_version=1
		        ;;
	        c)
		        opt_config=$OPTARG
		        opt_config_set=1
		        ;;
	        :)
		        echo "SYNTAX: Required argument missing!" >&2
		        l_code=3
		        ;;
	        \?)
		        echo "SYNTAX: Unknown argument: " $OPTARG >&2
		        l_code=3
		        ;;
	        *)
		        echo "BUG: TODO CASE: " $OPTIND $OPTARG $l_opt >&2
		        ;;
	    esac
    done
    
    # if code != 0 show usage and exit
    if [ $l_code -ne 0 ]; then
	    usage
	    exit $l_code
    fi
    
    # if help or version flag set, disply information and exit
    l_exitNow=0
    if [ $opt_version -ne 0 ]; then
	    print_version
	    l_exitNow=1
    fi
    if [ $opt_help -ne 0 ]; then
	    fullhelp
	    l_exitNow=1
    fi
    if [ $l_exitNow -ne 0 ]; then
	    exit 0
    fi
    
    shift $(($OPTIND -1))
    
    # 1st non option argument is the target. 2nd is the reason
    if [ $# -gt 0 ]; then
	    opt_target=$1
	    if [ $# -gt 1 ]; then
	        opt_reason=$2
	    fi
	    if [ $# -gt 2 ]; then
	        echo "SYNTAX: Too many arguments!" >&2
	        usage
	        exit 3
	    fi
    else
	    echo "SYNTAX: Required argument <target> missing!" >&2
	    usage
	    exit 3
    fi
    
    # Protect variables before sourcing configuration
    readonly opt_dryRun opt_help opt_quiet opt_initial opt_version opt_config opt_config_set opt_target opt_reason
    
    # Source global configuration
    source $opt_config 2> /dev/null
    if [ $? -ne 0 ]; then
	    if [ $opt_config_set -eq 0 ]; then
	        log "Failed loading default configuration file: $opt_config..."
	        log "...Using defaults"
	    else
	        echo "ERROR: Failed loading configuration file: $opt_config" >&2
	        exit 1
	    fi
    else
	    log "Loaded global configuration file: $opt_config"
    fi
    readonly conf_target_confdir
    
    # set default backup location before loading target specific configuration,
    # so we can change it in the config file
    conf_backup_path="$conf_backup_path/$opt_target"
    
    log "Loading configuration for target: $opt_target"
    l_target_conf_file="$conf_target_confdir/$opt_target.conf"

    # Source target configuration
    source "$l_target_conf_file" 2> /dev/null
    if [ $? -ne 0 ]; then
	    echo "ERROR: Failed loading target configuration file: $l_target_conf_file" >&2
	    exit 1
    else
	    log "Loaded target configuration file: $l_target_conf_file"
    fi

    # Check if rsync source was specified
    if [ -z "$conf_rsync_source" ]; then
        echo "ERROR: No rsync source specified! (Set with 'conf_rsync_source')" >&2
        exit 2
    fi
    # Check if rsync filter was specified
    if [ ! -r "$conf_rsync_filter" ]; then
        echo "ERROR: Rsync filter not specified or not readable! (Set with 'conf_rsync_filter')" >&2
        exit 2
    fi
    
    lock_target
    
    # get snapshot params:
    declare l_last_snapshot
    if [ $opt_initial -ne 0 ]; then
	    l_last_snapshot=`mktemp -d`
	    #l_last_snapshot=''
    else
	    if [ -r "$conf_backup_path/lastPath" ]; then
	        l_last_snapshot=`cat $conf_backup_path/lastPath`
	        if [ check_backup_structure "$l_last_snapshot" -ne 0 ]; then
		        echo "ERROR: $l_last_snapshot does not look like a backup!" >&2
		        exit 1
	        fi
	    else
	        echo "ERROR: could not read last snapshot location! Try adding -i to start from scratch" >&2
	        exit 1
	    fi
    fi
    
    readonly l_last_snapshot
    readonly l_backup_files_path=`date +"$conf_backup_path/%Y/%m/%d/$opt_reason"`
    log "Using '${l_last_snapshot:-NONE}' as base"
    readonly l_time_start=`date +"%s"`
    pre_backup  "$opt_target" "$opt_reason" "$opt_dryRun" "$opt_quiet" "$l_last_snapshot" "$l_backup_files_path" "$l_time_start" "$conf_backup_path" || exit 1
    do_backup   "$opt_target" "$opt_reason" "$opt_dryRun" "$opt_quiet" "$l_last_snapshot" "$l_backup_files_path" "$l_time_start" "$conf_backup_path" || exit 1
    post_backup "$opt_target" "$opt_reason" "$opt_dryRun" "$opt_quiet" "$l_last_snapshot" "$l_backup_files_path" "$l_time_start" "$conf_backup_path" || exit 1
    readonly l_time_end=`date +"%s"`
    write_backup_info "$l_last_snapshot" "$l_backup_files_path" "$l_time_start" "$l_time_end" "$conf_backup_path"
    log "Backup done."
}
main $@
