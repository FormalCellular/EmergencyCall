import os

import config


def remove_multi_line_comments(src):
    rnt = []
    cnt = 0
    for i, ch in enumerate(src):
        if ch == '(' and i < len(src) - 1 and src[i + 1] == '*':
            cnt += 1
        if ch == ')' and i > 0 and src[i - 1] == '*':
            cnt -= 1
            continue
        if cnt > 0:
            continue
        rnt.append(ch)

    return ''.join(rnt)


def remove_comments(src):
    src = remove_multi_line_comments(src)
    import re
    return re.sub(r'\\\*.*?\n', '', src)


def get_source_with_comments(file_path):
    with open(file_path, 'r') as f:
        return f.read()


def get_source_without_comments(file_path):
    return remove_comments(get_source_with_comments(file_path))


def get_kv_dict(src):
    ans = {}
    keys = ['vars']

    for k in keys:
        start = src.index(k + ' ==')
        v_str = ''
        for i in range(start + len(k) + len(' =='), len(src)):
            if src[i] == '>':
                break
            if src[i] == '<':
                continue
            v_str = v_str + src[i]

        v = [i.strip() for i in v_str.split(',')]
        ans[k] = v
    return ans


def handle_unchanged(src):
    kv_dict = get_kv_dict(src)

    replace_set = []
    nxt = 0
    while 'UNCHANGED' in src[nxt:]:
        start = src.index('UNCHANGED', nxt)
        to_replace = ''
        for i in range(start + len('UNCHANGED'), len(src)):
            if src[i] == '>':
                break
            if src[i] == '<':
                continue
            to_replace += src[i]
        to_replace = to_replace.strip()
        k = to_replace.split('\\')[0].strip()
        vs = [i.strip() for i in to_replace.split('\\')[1].strip()[1:-1].split(',')]
        new_v = []
        for v in kv_dict[k]:
            if v not in vs:
                new_v.append(v)
        replace_set.append((to_replace, ', '.join(new_v)))
        nxt = start + len('UNCHANGED')

    for item in replace_set:
        src = src.replace(item[0], item[1])

    return src


def push_source(src, output_file, module_name):
    with open(output_file, 'w') as f:
        ans = src.replace(module_name, module_name + '_auto')
        f.write(ans)


def handle_constraint(src, constraint):
    ret = ''
    for line in src.splitlines():
        if not line.startswith('Constraint_auto == '):
            ret += line
            ret += '\n'
        else:
            ret += 'Constraint_auto == '
            ret += constraint
            ret += '\n'
    return ret


def parse_tla(model, constraint='TRUE', tla_file=config.TLA_FILE):
    """
    The EmergencyCall_Model.tla cannot be used by TLC directly.
    Because we used a nonstandard UNCHANGED syntax: "UNCHANGED << vars \\ { list_of_changed_vars } >> "".
    This parser will convert this nonstandard syntax to the standard TLA+ syntax.

    We hard coded the keyword "vars" in the function of get_kv_dict(src).

    :return
        The parsed file is name EmergencyCall_Model_auto.tla.
        This auto file can be used by TLA toolbox directly.
    """

    src = get_source_with_comments(tla_file)
    model.vars = get_kv_dict(src)['vars']

    src = handle_constraint(src, constraint)
    src = handle_unchanged(src)
    src = remove_comments(src)

    auto_tla_file = tla_file[:-4] + '_auto.tla'
    model_name = tla_file.split(os.sep)[-1][:-4]
    push_source(src, auto_tla_file, model_name)

    return auto_tla_file


def parser_options(tla_file=config.TLA_FILE):

    src = get_source_with_comments(tla_file)
    begin = src.index('(* design space options *)') + len('(* design space options *)')
    src = src[begin:]
    end = src.index('(* design space options *)')
    src = src[:end]
    src = remove_comments(src)
    options = list(map(lambda x: x.strip(), src.split(',')))
    return options


if __name__ == '__main__':
    file = config.TLA_FILE
    from elf.Model import Model
    m = Model()
    m.options = parser_options(tla_file=file)
    parse_tla(model=m, tla_file=file, constraint="TRUE")
