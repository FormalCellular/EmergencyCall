import os
import sys
import multiprocessing as mp

import config
import elf_parser as parser
import tla_wrapper as wrapper
import trace_analyzer as analyzer
from Model import Model
import elf_gui as elf_gui


def main(tlc_config, verbose=False, no_gui=False):
    tla_file = os.getcwd() + os.sep + config.TLA_FILE

    model = Model()
    model.options = parser.parser_options(tla_file=tla_file)
    auto_tla_file = parser.parse_tla(model=model, tla_file=tla_file, constraint='TRUE')

    if tlc_config.cfg_file is not None or tlc_config.raw_file is not None:
        if tlc_config.cfg_file is not None:  # verify predefined config file, within model/config folder
            output_file = wrapper.tlc(tla_file=auto_tla_file,
                                      cfg_file=tlc_config.cfg_file,
                                      memory=tlc_config.memory,
                                      workers=tlc_config.worker,
                                      output=tlc_config.output,
                                      cleanup=False)
        else:  # skip verification, load pre-generated TLC output
            output_file = config.RAW_OUTPUT_FOLDER + tlc_config.raw_file
            if verbose:
                print(parser.get_source_without_comments(output_file))

        analyzer.trace_analyzer(model=model, trace_file=output_file, verbose=verbose)
        if not no_gui:
            mp.Process(target=elf_gui.main, args=(model,)).start()


def run_in_elf_folder():
    return os.getcwd().split(os.sep)[-1] == 'elf'


if __name__ == '__main__':
    if run_in_elf_folder():
        os.chdir(os.sep.join(os.getcwd().split(os.sep)[:-1]))

    try:
        if '-h' in sys.argv:
            print(config.USAGE)

        assert not ('-cfg' in sys.argv and '-raw' in sys.argv), "'-cfg' and '-raw' are both used"

        tlc_config = config.TLC_Config()
        verbose = False
        no_gui = False

        for i, cmd in enumerate(sys.argv):
            if cmd == '-cfg':
                tlc_config.cfg_file = sys.argv[i + 1]
                assert tlc_config.cfg_file.endswith('cfg'), 'config_fig should end with .cfg'
            elif cmd == '-raw':
                tlc_config.raw_file = sys.argv[i + 1]
            elif cmd == '-no-gui':
                no_gui = True
            elif cmd == '-v':
                verbose = True
            elif cmd == '-worker':
                tlc_config.worker = int(sys.argv[i + 1])
            elif cmd == '-memory':
                tlc_config.memory = int(sys.argv[i + 1])
            elif cmd == '-output':
                tlc_config.output = sys.argv[i + 1]

    except Exception as e:
        print(e)
        print(config.USAGE)

    else:
        main(tlc_config=tlc_config, verbose=verbose, no_gui=no_gui)