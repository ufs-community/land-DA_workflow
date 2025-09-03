#!/usr/bin/env python3

import argparse
import logging
import sys
import yaml
from jcb import render

# =================================================================== CHJ =====
def jedi_config_yaml(input_yaml_fn, output_yaml_fn, jedi_algorithm, jedi_type, frac_grid):

    try:
        with open(input_yaml_fn, 'r') as f:
            input_yaml_dict = yaml.safe_load(f)
        f.close()
        logging.info(f''' Input YAML file: {input_yaml_dict}''')
    except FileNotFoundError:
        logging.error(f''' Input YAML file {input_yaml_file} does not exist!''')

    jedi_config_dict = render(input_yaml_dict)
    logging.debug(f''' JEDI CONFIG: {jedi_config_dict}''')

    if frac_grid.upper() == "NO":
        if jedi_type == "snow" and jedi_algorithm == "3dvar":
            jedi_config_dict["cost function"]["background"]["state variables"][0] = 'snwdph'
            jedi_config_dict["final"]["increment"]["output"]["state component"]["state variables"][0] = 'snwdph'
#    else:
#        if jedi_algorithm == "3dvar":
#            jedi_config_dict["cost function"]["background"]["state variables"][3] = 'weasdl'

    with open(output_yaml_fn, 'w') as f:
        yaml.dump(jedi_config_dict, f, default_flow_style=False, sort_keys=False)
    f.close()


# =================================================================== CHJ =====
def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Create JEDI configuration YAML file.")
    parser.add_argument(
            "-i",
            "--input_yaml_fn",
            dest="input_yaml_fn",
            required=True,
            help="Input YAML file name.",
            )
    parser.add_argument(
            "-o",
            "--output_yaml_fn",
            dest="output_yaml_fn",
            required=True,
            help="Output YAML file name.",
            )
    parser.add_argument(
            "-a",
            "--jedi_algorithm",
            dest="jedi_algorithm",
            required=True,
            help="JEDI ALGORITHM.",
            )
    parser.add_argument(
            "-t",
            "--jedi_type",
            dest="jedi_type",
            required=True,
            help="Type of JEDI analysis.",
            )
    parser.add_argument(
            "-g",
            "--frac_grid",
            dest="frac_grid",
            required=True,
            help="Flag for fractional grid.",
            )
    parser.add_argument(
            "-l",
            "--loglevel",
            dest="PY_LOG_LEVEL",
            default="INFO",
            help="Python logging option only for this script. For other scripts, set it in config.yaml",
            )

    return parser.parse_args(argv)


# Main call ========================================================= CHJ =====
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    log_level_str = args.PY_LOG_LEVEL.upper()
    try:
        log_level = getattr(logging, log_level_str)
    except AttributeError:
        log_level_str = "INFO"
        log_level = logging.INFO
        print(f''' WARNING: Invalid log level "{args.PY_LOG_LEVEL.upper()}", set to INFO.''')
    print(f''' Python Log Level= str: {log_level_str}, attr: {log_level}''')
    logging.basicConfig(format='%(levelname)s::%(pathname)s::L%(lineno)d::%(message)s', level=log_level)
    jedi_config_yaml(
        input_yaml_fn=args.input_yaml_fn,
        output_yaml_fn=args.output_yaml_fn,
        jedi_algorithm=args.jedi_algorithm,
        jedi_type=args.jedi_type,
        frac_grid=args.frac_grid,
    )

