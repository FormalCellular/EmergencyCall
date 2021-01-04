import collections
import time
"""
Model:
    rounds: List of Round
Round:
    trace: List of Trace
Trace:
    states: List of state
State:
    dict:{variable: value} for variable in Model.vars
"""


class Model:
    def __init__(self):
        self.vars = []
        self.options = []
        self.rounds = []

    def __str__(self):
        ans = "Model:\n"
        ans += '\tOptions: ' + str(self.options) + '\n'
        if len(self.rounds) > 0:
            ans += '\tRound 0: \n' + str(self.rounds[0])
        else:
            ans += '\tRound 0: None'
        return ans

    def get_variables(self, round_index=0):
        _round = self.rounds[round_index]
        state = _round.trace.states[0]
        ans = list(state.keys())
        ans.sort()
        return ans

    def get_state(self, state_index=0, round_index=0):
        _round = self.rounds[round_index]
        trace = _round.trace
        return dict(trace.states[state_index])

    def get_state_values(self, state_index=0, round_index=0):
        _round = self.rounds[round_index]
        trace = _round.trace
        state = trace.states[state_index]
        vars = self.get_variables(round_index=round_index)
        ans = []
        for v in vars:
            ans.append(state[v])
        return ans

    def get_diff_vars_of_states(self, state_1, state_2, round_index=0):
        if state_1 == -1 or state_2 == -1:
            return ['action']

        _round = self.rounds[round_index]
        trace = _round.trace
        ans = []
        for k in _round.trace.states[0].keys():
            if trace.states[state_1][k] != trace.states[state_2][k]:
                ans.append(k)
        if 'action' not in ans:
            ans.append('action')
        return ans


class Trace:
    def __init__(self):
        self.states = []


class State(dict):
    pass


class Round:
    def __init__(self, model: Model):
        self.properties = []
        self.is_violated = False
        self.error_msg = ''
        self.option_vals = {}
        self.__trace = Trace()
        self.__model = model

    def __str__(self):
        ans = ''
        ans += 'round error_msa: ' + str(self.error_msg) + '\n'
        ans += 'round is_violated: ' + str(self.is_violated) + '\n'
        for state in self.trace.states:
            ans += str(state) + '\n'
        ans += 'Option values: \n'
        ans += str(self.option_vals)
        return ans

    @property
    def trace(self):
        return self.__trace

    @trace.setter
    def trace(self, trace: Trace):
        self.__trace = trace
        self.load_option_vals()

    def load_option_vals(self):
        if not self.is_violated:
            return

        for option in self.__model.options:
            self.option_vals[option] = self.trace.states[0][option]

        assert self.__options_unchanged()

    def __options_unchanged(self):
        if not self.is_violated:
            return len(self.trace.states) == 0

        for i in range(1, len(self.trace.states)):
            for option in self.__model.options:
                if self.trace.states[i][option] != self.option_vals[option]:
                    return False

        return True


class Config_File:
    INIT_NEXT_KEY = {
        'INIT': ['Init'],
        'NEXT': ['Next'],
        'CONSTRAINT': ['Constraint_auto'],
        'INVARIANT': ['TypeInvariant',
                      'SetInvariant', ],
    }

    SPEC_KEY = {
        'SPECIFICATION': ['Spec_auto'],
        'CONSTRAINT': ['Constraint_auto'],
        'INVARIANT': ['TypeInvariant',
                      'SetInvariant', ],
        'PROPERTY': ['TP'],
    }

    def __init__(self):
        self.KEY = {}

    def generate_config_file(self, module, file_name, config={}, spec_key=False):
        ans = ''

        if spec_key:
            self.KEY = self.SPEC_KEY
        else:
            self.KEY = self.INIT_NEXT_KEY

        for k, v in self.KEY.items():
            ans += k + '\n'
            for item in v:
                ans += item + '\n'
            if k not in config.keys():
                continue
            for item in config[k]:
                ans += item + '\n'
        ans += '\\* Generated on ' + time.strftime("%c")
        with open(module+file_name, "w") as out_file:
            out_file.write(ans)






