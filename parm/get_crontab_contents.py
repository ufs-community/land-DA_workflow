#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
from logging import getLogger
from datetime import datetime

def get_crontab_contents(called_from_cron, machine, debug):
    """
    This function returns the contents of the user's cron table, as well as the command used to
    manipulate the cron table. Typically this latter value will be `crontab`, but on some 
    platforms the version or location of this may change depending on other circumstances, e.g. on
    Cheyenne, this depends on whether a script that wants to call `crontab` is itself being called
    from a cron job.

    Args:
        called_from_cron  (bool): Set this to True if script is called from within a crontab
        machine           (str) : The name of the current machine
        debug             (bool): True will give more verbose output
    Returns:
        crontab_cmd       (str) : String containing the "crontab" command for this machine
        crontab_contents  (str) : String containing the contents of the user's cron table.
    """

    crontab_cmd = "crontab"

    print(
        f"""
        Getting crontab content with command:
        =========================================================
          {crontab_cmd} -l
        ========================================================="""
    )

    (_, crontab_contents, _) = run_command(f"{crontab_cmd} -l")

    if crontab_contents.startswith('no crontab for'):
        crontab_contents=''

    print(
        f"""
        Crontab contents:
        =========================================================
          {crontab_contents}
        ========================================================="""
    )

    # replace single quotes (hopefully in comments) with double quotes
    crontab_contents = crontab_contents.replace("'", '"')

    return crontab_cmd, crontab_contents


def add_crontab_line(called_from_cron, machine, crontab_line, debug):
    """Add crontab line to cron table"""

    # Get crontab contents
    crontab_cmd, crontab_contents = get_crontab_contents(called_from_cron, machine, debug)

    # Need to omit commented crontab entries for later logic
    lines = crontab_contents.split('\n')
    cronlines = []
    for line in lines:
        comment = False
        for char in line:
            if char == "#":
                comment = True
                break
            elif char.isspace():
                continue
            else:
                # If we find a character that isn't blank or comment, then this is a normal line
                break
        if not comment:
            cronlines.append(line)
    # Re-join all the separate lines into a multiline string again
    crontab_no_comments = """{}""".format("\n".join(cronlines))
    if crontab_line in crontab_no_comments:
        log_info(
            f"""
            The following line already exists in the cron table and thus will not be
            added:
              crontab_line = '{crontab_line}'"""
        )
    else:
        log_info(
            f"""
            Adding the following line to the user's cron table in order to automatically
            resubmit SRW workflow:
              crontab_line = '{crontab_line}'""",
            verbose=debug,
        )

        # add new line to crontab contents if it doesn't have one
        newline_char = ""
        if crontab_contents and crontab_contents[-1] != "\n":
            newline_char = "\n"

        # add the crontab line
        run_command(
            f"""printf "%s%b%s\n" '{crontab_contents}' '{newline_char}' '{crontab_line}' | {crontab_cmd}"""
        )


def delete_crontab_line(called_from_cron, machine, crontab_line, debug):
    """Delete crontab line after job is complete i.e. either SUCCESS/FAILURE
    but not IN PROGRESS status"""

    #
    # Get the full contents of the user's cron table.
    #
    (crontab_cmd, crontab_contents) = get_crontab_contents(called_from_cron, machine, debug)
    #
    # Remove the line in the contents of the cron table corresponding to the
    # current forecast experiment (if that line is part of the contents).
    # Then record the results back into the user's cron table.
    #
    print(
        f"""
        Crontab contents before delete:
        =========================================================
          {crontab_contents}
        ========================================================="""
    )

    if crontab_line in crontab_contents:
        #Try removing with a newline first, then fall back to without newline
        crontab_contents = crontab_contents.replace(crontab_line + "\n", "")
        crontab_contents = crontab_contents.replace(crontab_line, "")
    else:
        print(f"\nWARNING: line not found in crontab, nothing to remove:\n {crontab_line}\n")

    run_command(f"""echo '{crontab_contents}' | {crontab_cmd}""")

    print(
        f"""
        Crontab contents after delete:
        =========================================================
          {crontab_contents}
        ========================================================="""
    )


def parse_args(argv):
    """Parse command line arguments for deleting crontab line.
    This is needed because it is called from shell script.
    If 'delete' argument is not passed, print the crontab contents
    """
    parser = argparse.ArgumentParser(description="Crontab job manipulation program.")

    parser.add_argument(
        "-c",
        "--called_from_cron",
        action="store_true",
        help="Called from cron.",
    )

    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        help="Print debug output",
    )

    parser.add_argument(
        "-a",
        "--add",
        action="store_true",
        help="Add specified crontab line.",
    )

    parser.add_argument(
        "-r",
        "--remove",
        action="store_true",
        help="Remove specified crontab line.",
    )

    parser.add_argument(
        "-l",
        "--line",
        help="Line to remove from crontab. If --remove/add not specified, has no effect",
    )

    parser.add_argument(
        "-m",
        "--machine",
        help="Machine name",
        required=True
    )

    # Check that inputs are correct and consistent
    args = parser.parse_args(argv)

    if args.remove or args.add:
        if args.line is None:
            raise argparse.ArgumentTypeError("--line is a required argument if --remove/add is specified")

    return args

def run_command(cmd):
    """Run system command in a subprocess

    Args:
        cmd: command to execute
    Returns:
        Tuple of (exit code, std_out, std_err)
    """
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        universal_newlines=True,
    )

    std_out, std_err = proc.communicate()

    # strip trailing newline character
    return (proc.returncode, std_out.rstrip("\n"), std_err.rstrip("\n"))

def log_info(info_msg, verbose=True, dedent_=True):
    """Function to print information message using the logging module. This function
    should not be used if python logging has not been initialized.

    Args:
        info_msg : info message to print
        verbose : set to False to silence printing
        dedent_ : set to False to disable "dedenting" (print string as-is)
    Returns:
        None
    """

    # "sys._getframe().f_back.f_code.co_name" returns the name of the calling function
    logger = getLogger(sys._getframe().f_back.f_code.co_name)

    if verbose:
        if dedent_:
            logger.info(indent(dedent(info_msg), "  "))
        else:
            logger.info(info_msg)

if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    if args.remove:
        delete_crontab_line(args.called_from_cron,args.machine,args.line,args.debug)
    elif args.add:
        add_crontab_line(args.called_from_cron,args.machine,args.line,args.debug)
    else:
        _,out = get_crontab_contents(args.called_from_cron,args.machine,args.debug)
        print_info_msg(out)
