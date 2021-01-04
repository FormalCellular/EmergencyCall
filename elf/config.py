import os
from multiprocessing import cpu_count

USAGE_RAW = '''Usage: python elf{0}main.py <command> 
                  [-no-gui]  [-v]  [-worker num_workers]  [-memory memory_size]  [-output output_file] [-h] 
    example:
        python elf{0}main.py -cfg attack1.cfg
    command:
        -cfg config_file.cfg    verify predefined config file, in model{0}config folder
        OR
        -raw raw_output.txt     skip verification, load pre-generated TLC output, in model{0}raw_output folder
    options:
        -no-gui                 use this option if wxPython in not installed
        -v                      verbose CLI output
        -worker num_workers     number of CPU threads for verification
        -memory memory_size     memory allocated to Java heap (MB)
        -output output_file     specify raw output file for TLC results
        -h                      print usage'''

USAGE = USAGE_RAW.format(os.sep)

WORKERS_DEFAULT = cpu_count() - 1

MEMORY_DEFAULT = 8192

MODULE = 'model{0}'.format(os.sep)

CFG_FOLDER = 'config{0}'.format(os.sep)  # TLC: cfg files must locate in the same folder/sub-folders of TLA file

RAW_OUTPUT_FOLDER = 'model{0}raw_output{0}'.format(os.sep)

TLA_FILE = MODULE + 'EmergencyCall_Model.tla'  # original model

# TLA_FILE = MODULE + 'solution{0}EmergencyCall_Model_sol.tla'.format(os.sep)  # solution verification

TLA_TOOLS = 'tlatools{0}tla2tools.jar'.format(os.sep)

OUTPUT_DEFAULT = MODULE + 'output.txt'


class TLC_Config():
    def __init__(self):
        self.cfg_file = None
        self.raw_file = None
        self.memory = MEMORY_DEFAULT
        self.worker = WORKERS_DEFAULT
        self.output = OUTPUT_DEFAULT

    def __str__(self):
        return '%s(%s)' % (type(self).__name__, ', '.join('%s=%s' % item for item in vars(self).items()))
