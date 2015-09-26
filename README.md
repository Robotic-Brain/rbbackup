rbBackup
========

This script creates incremental backups using rsync
see ./rbbackup.sh -h for all options

This is my first bash schript and threfore is quite messy and should be considered a prototype!
Use at your own risk!

NOTES
=====

`./testRunner.sh` lists available test fixtures

`realRun.sh` is expected to return one failure: `ASSERT:base snapshot expected:<0> but was:<1>`
this is caused by the "tempdir workaround" used for initial backups and can be ignored for now.