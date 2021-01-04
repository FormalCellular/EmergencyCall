from elf_parser import get_source_without_comments
from Model import Round, Trace, State


def get_error_msg(src):
    ans = []
    for line in src.splitlines():
        if line.startswith('Error:'):
            ans.append(line)
    return ans


def get_is_violated(error_msg):
    for line in error_msg:
        if 'is violated' in line:
            return True
    return False


def _get_state_src(src):
    ans = []
    is_trace = False
    for line in src.splitlines():
        if 'states generated' in line or 'Finished in' in line:
            is_trace = False
        if line.startswith('State ') or 'is violated by the initial state' in line:
            is_trace = True
        if not is_trace: continue
        if not line:
            yield ans
            ans = []
        else:
            ans.append(line)


def _to_state(state_src):
    state = State()
    state['action'] = state_src[0].split(' ')[2].strip('<')
    for item in state_src[1:]:
        k, v = item.split('=')
        k = k.strip('/\\')
        k = k.strip()
        state[k] = v.strip()
    return state


def get_trace(src):
    trace = Trace()
    for state_src in _get_state_src(src):
        trace.states.append(_to_state(state_src))
    return trace


def trace_analyzer(model, trace_file, verbose=False, is_round=True):
    src = get_source_without_comments(trace_file)
    rnd = Round(model)
    rnd.error_msg = get_error_msg(src)
    rnd.is_violated = get_is_violated(rnd.error_msg)
    rnd.trace = get_trace(src)
    if is_round:
        model.rounds.append(rnd)
    if verbose:
        print(model)
    return rnd
