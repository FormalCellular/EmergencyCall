import subprocess
import os

import config


def tlc(tla_file, cfg_file, deadlock=False, workers=config.WORKERS_DEFAULT, memory=config.MEMORY_DEFAULT, output=config.OUTPUT_DEFAULT, cleanup=True, fp=0.9):
    cmd = []

    cmd.append('java')
    cmd.append('-Xms%dm -Xmx%dm' % (memory // 2, memory))

    cmd.append('-cp %s' % (os.getcwd() + os.sep + config.TLA_TOOLS))
    cmd.append('tlc2.TLC')

    cmd.append('-config %s' % (config.CFG_FOLDER + cfg_file))

    if not deadlock:
        cmd.append('-deadlock')

    cmd.append('-workers %d' % workers)

    cmd.append('-fpmem %.2f' % fp)

    if cleanup:
        cmd.append('-cleanup')

    assert tla_file.endswith('.tla')

    cmd.append(tla_file)

    cmd_str = " ".join(cmd)
    print(cmd_str)

    with open(output, "w") as out_file:
        proc = subprocess.Popen(cmd_str, shell=True, stdout=subprocess.PIPE)
        for line in proc.stdout:
            line = line.decode('utf-8')
            print(line, end='')
            if line.endswith('\r\n'):
                line = line[:-2] + '\n'
            out_file.write(line)

    return output


if __name__ == '__main__':
    print(tlc(tla_file='../model/EmergencyCall_Model_auto.tla', cfg_file='attack_1.cfg'))
