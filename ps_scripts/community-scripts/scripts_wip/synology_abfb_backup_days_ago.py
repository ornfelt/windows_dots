#!/usr/bin/env python3
# Copyright 2022, Nice Guy IT, LLC. All rights reserved.
# SPDX-License-Identifier: MIT
# Source: https://github.com/NiceGuyIT/synology_abfb_log_parser
"""
**IMPORTANT**
This script will install the "synology_abfb_log_parser" Python modules in the TRMM Python distribution.
Use at your own risk. Existing modules are not upgraded.

The '--auto-upgrade' parameter will upgrade the "synology_abfb_log_parser" module on every run. This switch is disabled
by default because applications should not auto-update in production unless specifically authorized.
If you're lazy and don't mind an occasional hiccup, create a script check with '--auto-upgrade' and schedule it
to run daily or weekly.

*Note*: When adding arguments to the script in TRMM, use an equals sign "=" to separate the parameter from the value.
For example, use this:
  --ago-unit=hours --ago-value=3
Do not use this as it generate an error:
  --ago-unit hours --ago-value 3


This example will return logs where the "last_backup_status" is "complete" and "last_success_time" was more than
'--complete-days-ago'. For example:
    --ago-unit=hours --ago-value=12 --complete-days-ago=3 -> Search the logs for the past 12 hours and return entries
        where the "backup_result.last_backup_status" is "complete" and "backup_result.last_success_time" was more than
        3 days ago.

$ python3 trmm-synology_abfb_backup_days_ago.py --help
usage: trmm-synology_abfb_backup_days_ago.py [-h]
                                             [--log-level {debug,info,warning,error,critical}]
                                             [--log-path LOG_PATH]
                                             [--log-glob LOG_GLOB]
                                             [--ago-unit AGO_UNIT]
                                             [--ago-value AGO_VALUE]
                                             [--complete-days-ago COMPLETE_DAYS_AGO]
                                             [--auto-upgrade]

Parse the Synology Active Backup for Business logs.

optional arguments:
  -h, --help            show this help message and exit
  --log-level {debug,info,warning,error,critical}
                        set log level for the Synology Active Backup for
                        Business module
  --log-path LOG_PATH   path to the Synology log files
  --log-glob LOG_GLOB   filename glob for the log files
  --ago-unit AGO_UNIT   time span unit, one of [seconds, minutes, hours, days,
                        weeks]
  --ago-value AGO_VALUE
                        time span value
  --complete-days-ago COMPLETE_DAYS_AGO
                        days ago that a complete backup indicates failure
  --auto-upgrade        auto-upgrade the synology_abfb_log_parser module

"""
import argparse
import logging
import pkg_resources
import subprocess
import sys
import traceback


def pip_install_upgrade(modules, logger=logging.getLogger(), upgrade=False):
    """
    Install or upgrade the specified Python modules using 'pip install'.
    :param modules: set of modules to install/upgrade
    :param logger: logging instance of the root logger
    :param upgrade: Bool If True, upgrade the modules.
    :return: None
    """
    if not modules:
        return
    required_modules = set(modules)
    try:
        python = sys.executable
        logger.info(f'Installing/upgrading modules: {required_modules}')
        if upgrade:
            subprocess.check_call([python, '-m', 'pip', 'install', '--upgrade', *required_modules], stdout=subprocess.DEVNULL)
        else:
            subprocess.check_call([python, '-m', 'pip', 'install', *required_modules], stdout=subprocess.DEVNULL)
    except subprocess.CalledProcessError as err:
        logger.error(f'Failed to install/upgrade the required modules: {required_modules}')
        logger.error(err)
        exit(1)


# Check if the modules are installed
try:
    import datetime
    import glob
    import synology_abfb_log_parser
except ModuleNotFoundError:
    required = {'synology_abfb_log_parser'}
    installed = {pkg.key for pkg in pkg_resources.working_set}
    missing = required - installed
    if missing:
        pip_install_upgrade(**{
            'modules': missing
        })
        # Import the modules if they were just installed. Duplicate imports are ignored.
        import datetime
        import glob
        import synology_abfb_log_parser


def main(logger=logging.getLogger(), ago_unit='days', ago_value=1, log_path=None, log_glob='log.txt*', complete_days_ago=3):
    """
    Main program
    :param logger: logging instance of the root logger
    :param ago_unit: string Units of datetime.timedelta. One of ['weeks', 'days', 'hours', 'minutes', 'seconds']
        Note: 'years' and 'months' is not valid.
        See timedelta docs for details: https://docs.python.org/3/library/datetime.html#timedelta-objects
    :param ago_value: int Value of datetime.timedelta
    :param log_path: string Path to the log files.
    :param log_glob: string Filename glob for the log files. Defaults to 'log.txt*'
    :param complete_days_ago: int Days ago that a complete backup log does not exist indicates a failure
    :return: None
    """
    after = datetime.timedelta(**{ago_unit: ago_value})

    # Since the package was imported, the syntax is package.subpackage.Class()
    synology = synology_abfb_log_parser.abfb_log_parser.ActiveBackupLogParser(
        # Search logs within the period specified.
        # timedelta() will be off by 1 minute because 1 minute is added to detect if the log entry is last year vs.
        # this year. This should be negligible.
        after=after,

        # Use different log location
        log_path=log_path,

        # Use different filename globbing
        filename_glob=log_glob,

        # Pass the logger
        logger=logger
    )

    # Load the log entries
    if log_path:
        logger.debug(f'Loading log files in "{log_path}"')
    else:
        logger.debug(f'Loading log files in the default location')
    synology.load()

    # Search for entries that match the criteria.
    find = {
        'method_name': 'server-requester.cpp',
        'json': {
            'backup_result': {
                'last_backup_status': {
                    # Find all records with backup_results
                }
            }
        },
    }
    logger.debug('Searching the log files')
    found = synology.search(find=find)
    ts = (datetime.datetime.now() - after).strftime('%Y-%m-%d %X')
    if not found:
        logger.info(f"No log entries found since {ts}")
        return

    # True if log entries were found
    errors_found = False

    # Print the log events
    logger.debug('Printing the results')
    print(f'Log entries were found since {ts}:')
    for event in found:

        try:
            # Need to check if the keys are in the event. An error is thrown if a key is accessed that does not exist.
            if 'json' not in event or event['json'] is None:
                continue
            if 'backup_result' not in event['json']:
                continue
            if 'last_success_time' not in event['json']['backup_result']:
                continue
            if 'last_backup_status' not in event['json']['backup_result']:
                continue

            # Nicely formatted timestamp
            ts = event['datetime'].strftime('%Y-%m-%d %X')
            ts_backup = datetime.datetime.fromtimestamp(event['json']['backup_result']['last_success_time'])
            delta_backup = datetime.datetime.now() - ts_backup
            # delta_backup.days is an integer and does not take into account hours.
            if event['json']['backup_result']['last_backup_status'] == 'complete' and delta_backup.days >= complete_days_ago:
                errors_found = True

                task_name = ''
                transferred = 0
                if 'running_task_result' in event['json']:
                    if 'task_name' in event['json']['running_task_result']:
                        task_name = event['json']['running_task_result']['task_name']
                    if 'transfered_bytes' in event['json']['running_task_result']:
                        transferred = event['json']['running_task_result']['transfered_bytes']

                # Always print the output, so it's visible to the users.
                print(f"{ts}: {event['json']['backup_result']}    Task name: '{task_name}'    Transferred: '{transferred}'    Days/Hours ago: {delta_backup}")

        except TypeError as err:
            logger.warning(f'Failed to check for key before using. Skipping this event. ERR: {err}')
            logger.warning(traceback.format_exc())
            logger.warning(f'Event: {event}')
            continue

    if errors_found:
        # Errors found. Exit with failure
        exit(1)
    else:
        # No errors found. Exit successful
        exit(0)


# Main entrance here...
if __name__ == '__main__':
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Parse the Synology Active Backup for Business logs.')
    parser.add_argument('--log-level', default='info', dest='log_level',
                        choices=['debug', 'info', 'warning', 'error', 'critical'],
                        help='set log level for the Synology Active Backup for Business module')
    parser.add_argument('--log-path', default='', type=str,
                        help='path to the Synology log files')
    parser.add_argument('--log-glob', default='log.txt*', type=str,
                        help='filename glob for the log files')
    parser.add_argument('--ago-unit', default='hours', type=str,
                        help='time span unit, one of [seconds, minutes, hours, days, weeks]')
    parser.add_argument('--ago-value', default='1', type=int,
                        help='time span value')
    parser.add_argument('--complete-days-ago', default='3', type=int,
                        help='days ago that a complete backup indicates failure')
    parser.add_argument('--auto-upgrade', default=False, action='store_true',
                        help='auto-upgrade the synology_abfb_log_parser module')
    args = parser.parse_args()

    # Change default log level to INFO
    default_log_level = 'INFO'
    if args.log_level:
        default_log_level = args.log_level.upper()
    log_format = '%(asctime)s %(funcName)s(%(lineno)d): %(message)s'
    logging.basicConfig(format=log_format, level=default_log_level)
    top_logger = logging.getLogger()
    top_logger.setLevel(default_log_level)

    if args.auto_upgrade:
        requirements = {'synology_abfb_log_parser'}
        pip_install_upgrade(**{
            'modules': requirements,
            'logger': top_logger,
            'upgrade': True,
        })

    main(**{
        'logger': top_logger,
        'log_path': args.log_path,
        'log_glob': args.log_glob,
        'ago_unit': args.ago_unit,
        'ago_value': args.ago_value,
        'complete_days_ago': args.complete_days_ago,
    })
