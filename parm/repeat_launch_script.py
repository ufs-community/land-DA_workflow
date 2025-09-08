#!/usr/bin/env python3

import subprocess
import time
import sys
import re
from pathlib import Path
from typing import List, Tuple, Optional

# Launch script to run
SCRIPT = "./launch_rocoto_wflow.sh"
# Interval in seconds
INTERVAL = 10


# === Main part (will be called at the end) ==================================== CHJ =====
def main():
    logfile = extract_logfile(SCRIPT)
    if not logfile:
        print(f'''FATAL ERROR: Could not extract WFLOW_LOG_FN from {SCRIPT}.''')
        sys.exit(1)
    print(f'''Using log file: {logfile}''')

    try:
        while True:
            print(f'''Running {SCRIPT} ...''')

            # Run the script (append output to log file)
            with logfile.open("a") as log:
                subprocess.run(SCRIPT, shell=True, stdout=log, stderr=log, text=True)

            # Check log for status
            num_current, num_all, status = read_wflow_status(logfile)
            print(f''' Cycles: {num_current} out of {num_all} completed.''')
            print(f''' Detected wflow_status = {status}''')
            if status.upper() == "SUCCESS":
                print("\n !!! ===== Workflow completed successfully. Stopping ===== !!!")
                break

            print(f''' Waiting {INTERVAL} seconds before next run...\n''')
            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print("\n User interrupted the loop. Exiting gracefully.")
        sys.exit(0)


# === Extract log file name ===================================================== CHJ =====
def extract_logfile(script_path: str) -> Path | None:
    """Extract WFLOW_LOG_FN from the script file."""
    text = Path(script_path).read_text()
    match = re.search(r"WFLOW_LOG_FN\s*=\s*['\"]?([^'\"\n]+)['\"]?", text)
    if match:
        return Path(match.group(1).strip())
    return None


# === Read workflow status ===================================================== CHJ =====
def read_wflow_status(logfile: str) -> Tuple[Optional[str], Optional[str], List[str]]:
    """Read the log file and extract Workflow status."""
    if not logfile.exists():
        return None
    with logfile.open("r") as f:
        text = f.read()
    # Extract numbers before and after 'out of' as strings
    match = re.search(r"(\S+)\s+out of\s+(\S+)", text)
    num_current, num_all = (match.group(1), match.group(2)) if match else (None, None)
    # Extract workflow status
    matches = re.findall(r"Workflow status:\s{2}([^\n]+)", text)
    status =  matches[-1].strip()
    return num_current, num_all, status


# === Main call ================================================================ CHJ =====
if __name__ == "__main__":
    main()
