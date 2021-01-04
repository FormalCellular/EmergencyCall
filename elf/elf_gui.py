import wx
import wx.grid
import wx.lib.agw.gradientbutton as GB
import wx.lib.agw.aquabutton as AB
import wx.lib.scrolledpanel


class WindowClass(wx.Frame):

    def __init__(self, *args, **kwargs):
        super(WindowClass, self).__init__(*args, **kwargs)
        self.Show()

        # constants
        self.font = wx.Font(10, wx.SWISS, wx.NORMAL, wx.LIGHT)
        self.action_font = wx.Font(10, wx.DECORATIVE, wx.NORMAL, wx.BOLD)
        self.button_font = wx.Font(10, wx.SCRIPT, wx.NORMAL, wx.BOLD)

        self.button_width = 250
        self.button_height = 35
        self.state_button_height = 25

        self.panel_index = 265
        self.mid_panel_width = 430
        self.state_panel_width = 260
        self.panel_interval = 5

        # components
        self.last_button_id = -1
        self.model = None
        self.variables = None
        self.state_left = -1
        self.state_right = -1
        self.state_diff = -1
        self.panel_mid = None
        self.panel_left = None  # unused
        self.panel_right = None
        self.panel_diff = None
        self.buttons = []  # state buttons
        self.temp_diff_vars = []

    def get_right_index(self):
        return self.panel_index + self.mid_panel_width + self.panel_interval

    def get_diff_index(self):
        return self.panel_index + self.mid_panel_width + self.state_panel_width + self.panel_interval * 2

    def get_frame_width(self):
        return self.panel_index + self.mid_panel_width + self.state_panel_width * 2 + self.panel_interval * 6

    def get_frame_height(self):
        if self.variables is not None:
            height = min(max(len(self.variables) * 20 + 60, 660), 1080)
            return height
        return 660

    def show_model(self, model):
        self.model = model

        if len(model.rounds) <= 0:
            print("GUI: no rounds to show")
            return

        if model.rounds[0].is_violated is False:
            print("GUI: The property is verified to be safe.")
            panel = wx.Panel(self, pos=[0, 0], size=[300, 100])
            st = wx.StaticText(panel, pos=[5, 15], size=[290, 40],
                               label="The property is verified to be safe.\nNo traces to be showed here.",
                               style=wx.ALIGN_CENTER)
            st.SetFont(self.font)
            button = AB.AquaButton(panel, label='close', pos=[115, 65], size=[70, 32])
            button.SetForegroundColour("black")
            button.SetFont(self.button_font)
            self.Bind(wx.EVT_BUTTON, self.OnClick_close, button)
            self.SetSize(wx.Size(320, 150))
            return

        # clear button
        clear_button = AB.AquaButton(self, label='clear', pos=[6, 5], size=[self.button_width, self.button_height])
        clear_button.SetForegroundColour("black")
        clear_button.SetFont(self.button_font)
        self.Bind(wx.EVT_BUTTON, self.OnClick_clear, clear_button)

        # last button
        last_button = AB.AquaButton(self, label='last', pos=[6, 40], size=[self.button_width, self.button_height])
        last_button.SetForegroundColour("black")
        last_button.SetFont(self.button_font)
        self.Bind(wx.EVT_BUTTON, self.OnClick_last, last_button)

        # next button
        next_button = AB.AquaButton(self, label='next', pos=[6, 75], size=[self.button_width, self.button_height])
        next_button.SetForegroundColour("black")
        next_button.SetFont(self.button_font)
        self.Bind(wx.EVT_BUTTON, self.OnClick_next, next_button)

        # state buttons
        for i, state in enumerate(model.rounds[0].trace.states):
            self.buttons.append(GB.GradientButton(self, id=1000 + i, label=str(i - 0) + ': ' + state['action'],
                                                  pos=[6, 5 + i * 30 + 125],
                                                  size=[self.button_width, self.state_button_height]))

        # state button actions
        for i, button in enumerate(self.buttons):
            # i.SetBackgroundColour(wx.Colour(240, 240, 240))
            button.SetForegroundColour('white')
            button.SetFont(self.button_font)
            self.Bind(wx.EVT_BUTTON, self.OnClick, button)
            self.buttons[i].Bind(wx.EVT_ENTER_WINDOW, self.OnEnterWindow)
            self.buttons[i].Bind(wx.EVT_LEAVE_WINDOW, self.OnLeaveWindow)

        self.variables = model.get_variables(round_index=0)
        self.SetSize(wx.Size(self.get_frame_width(), self.get_frame_height()))
        self.draw_values()

    @staticmethod
    def variables_to_text(vars):
        return '\n'.join(vars)

    @staticmethod
    def state_to_text(state):
        ans = ''
        for k, v in state.items():
            if k == 'action':
                continue
            ans += k
            ans += ': '
            ans += v
            ans += '\n'
        return ans

    def OnClick(self, event: wx.Event):
        if self.panel_diff is not None:
            self.panel_diff.Destroy()
            self.panel_diff = None
        id = event.GetId() % 1000
        if self.last_button_id != -1:
            self.buttons[self.last_button_id].SetForegroundColour('white')
        self.buttons[id].SetForegroundColour('red')
        self.last_button_id = id

        if self.state_left == -1:
            self.state_left = id
        elif self.state_right == -1:
            self.state_right = id
        else:
            self.state_left, self.state_right = self.state_right, id

        self.draw_values()
        self.show_panel_diff_as_left()

    def OnClick_clear(self, event: wx.Event):
        if self.panel_mid is not None:
            self.panel_mid.Destroy()
            self.panel_mid = None
        if self.panel_left is not None:
            self.panel_left.Destroy()
            self.panel_left = None
        if self.panel_right is not None:
            self.panel_right.Destroy()
            self.panel_right = None
        if self.panel_diff is not None:
            self.panel_diff.Destroy()
            self.panel_diff = None

        self.state_left = -1
        self.state_right = -1
        self.state_diff = -1

        if self.last_button_id != -1:
            self.buttons[self.last_button_id].SetForegroundColour('white')
        self.last_button_id = -1

    def OnClick_last(self, event: wx.Event):
        if self.panel_diff is not None:
            self.panel_diff.Destroy()
            self.panel_diff = None
        if self.last_button_id == -1:
            id = len(self.buttons) - 1
        else:
            id = self.last_button_id - 1

        if id == -1:
            return

        if self.last_button_id != -1:
            self.buttons[self.last_button_id].SetForegroundColour('white')
        self.buttons[id].SetForegroundColour('red')
        self.last_button_id = id

        if self.state_left == -1:
            self.state_left = id
        elif self.state_right == -1:
            self.state_right = id
        else:
            self.state_left, self.state_right = self.state_right, id

        self.draw_values()
        self.show_panel_diff_as_left()

    def OnClick_next(self, event: wx.Event):
        if self.panel_diff is not None:
            self.panel_diff.Destroy()
            self.panel_diff = None
        id = self.last_button_id + 1
        if id == len(self.buttons):
            return

        if self.last_button_id != -1:
            self.buttons[self.last_button_id].SetForegroundColour('white')
        self.buttons[id].SetForegroundColour('red')
        self.last_button_id = id

        if self.state_left == -1:
            self.state_left = id
        elif self.state_right == -1:
            self.state_right = id
        else:
            self.state_left, self.state_right = self.state_right, id

        self.draw_values()
        self.show_panel_diff_as_left()

    def OnClick_close(self, event: wx.Event):
        self.Close()

    def show_panel_diff(self):
        # Panel Diff
        if self.state_right != -1 and self.state_diff != -1:
            self.panel_diff = wx.Panel(self, pos=[self.get_diff_index(), 5],
                                       size=[self.state_panel_width, 5 + len(self.variables) * 20 + 5])
            state = self.model.get_state(self.state_diff)
            for i, v in enumerate(self.variables):
                if v in self.temp_diff_vars:
                    if v == self.variables[0]:
                        st = wx.StaticText(self.panel_diff, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                           label=str(self.state_diff) + ': ' + self.simplify_text(state[v]),
                                           style=wx.ALIGN_CENTER)
                        st.SetFont(self.action_font)
                    else:
                        st = wx.StaticText(self.panel_diff, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                           label=self.simplify_text(state[v]),
                                           style=wx.ALIGN_CENTER)
                        st.SetFont(self.font)
                    st.SetBackgroundColour(wx.Colour(177, 177, 177))

    def show_panel_diff_as_left(self):
        # Panel Diff
        if self.state_left != -1:
            self.panel_diff = wx.Panel(self, pos=[self.get_diff_index(), 5],
                                       size=[self.state_panel_width, 5 + len(self.variables) * 20 + 5])
            state = self.model.get_state(self.state_left)
            for i, v in enumerate(self.variables):
                if v == self.variables[0]:
                    st = wx.StaticText(self.panel_diff, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                       label=str(self.state_left) + ': ' + self.simplify_text(state[v]),
                                       style=wx.ALIGN_CENTER)
                    st.SetFont(self.action_font)
                else:
                    st = wx.StaticText(self.panel_diff, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                       label=self.simplify_text(state[v]), style=wx.ALIGN_CENTER)
                    st.SetFont(self.font)

                if v in self.diff_vars:
                    st.SetBackgroundColour(wx.Colour(177, 177, 177))

    def OnEnterWindow(self, event: wx.Event):
        if self.panel_right == None:
            return

        if self.panel_diff != None:
            self.panel_diff.Destroy()

        self.state_diff = event.GetId() % 1000
        self.temp_diff_vars = self.model.get_diff_vars_of_states(self.state_diff, self.state_right)
        self.show_panel_diff()
        event.Skip()

    def OnLeaveWindow(self, event: wx.Event):
        if self.panel_diff != None:
            self.panel_diff.Destroy()
        self.show_panel_diff_as_left()
        event.Skip()

    def simplify_text(self, text):
        simply = {
            'emergency_number_list': 'ENL',
            'category': 'cat',
        }
        for k, v in simply.items():
            if k in text:
                text = text.replace(k, v)
        return text

    def show_panel_left(self):  # unused
        # Panel Left
        if self.state_left != -1:
            self.panel_left = wx.Panel(self, pos=[250, 5], size=[250, 5 + len(self.variables) * 20 + 5])
            state = self.model.get_state(self.state_left)
            for i, v in enumerate(self.variables):
                wx.StaticText(self.panel_left, pos=[5, 5 + i * 20], size=[240, 18], label=self.simplify_text(state[v]),
                              style=wx.ALIGN_CENTER)

                if v == self.variables[0]:
                    st = wx.StaticText(self.panel_left, pos=[5, 5 + i * 20], size=[240, 18],
                                       label=str(self.state_left) + ': ' + self.simplify_text(state[v]),
                                       style=wx.ALIGN_CENTER)
                    st.SetFont(self.action_font)
                else:
                    st = wx.StaticText(self.panel_left, pos=[5, 5 + i * 20], size=[240, 18],
                                       label=self.simplify_text(state[v]), style=wx.ALIGN_CENTER)
                    st.SetFont(self.font)

                if v in self.diff_vars:
                    st.SetBackgroundColour(wx.Colour(177, 177, 177))

    def draw_values(self):
        self.diff_vars = self.model.get_diff_vars_of_states(self.state_left, self.state_right)

        if self.panel_mid is not None:
            self.panel_mid.Destroy()
        if self.panel_left is not None:
            self.panel_left.Destroy()
        if self.panel_right is not None:
            self.panel_right.Destroy()

        # Panel Mid
        if self.state_left != -1:
            self.panel_mid = wx.Panel(self, pos=[self.panel_index, 5],
                                      size=[self.mid_panel_width, 5 + len(self.variables) * 20 + 5])
            for i, v in enumerate(self.variables):
                st = wx.StaticText(self.panel_mid, pos=[5, 5 + i * 20], size=[self.mid_panel_width - 10, 18], label=v,
                                   style=wx.ALIGN_CENTER)

                if v == self.diff_vars[0]:
                    st.SetFont(self.action_font)
                else:
                    st.SetFont(self.font)

                if v in self.diff_vars:
                    st.SetBackgroundColour(wx.Colour(177, 177, 177))

        # Panel Right
        if self.state_right != -1:
            self.panel_right = wx.Panel(self, pos=[self.get_right_index(), 5],
                                        size=[self.state_panel_width, 5 + len(self.variables) * 20 + 5])
            state = self.model.get_state(self.state_right)
            for i, v in enumerate(self.variables):
                if v == self.variables[0]:
                    st = wx.StaticText(self.panel_right, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                       label=str(self.state_right) + ': ' + self.simplify_text(state[v]),
                                       style=wx.ALIGN_CENTER)
                    st.SetFont(self.action_font)
                else:
                    st = wx.StaticText(self.panel_right, pos=[5, 5 + i * 20], size=[self.state_panel_width - 10, 18],
                                       label=self.simplify_text(state[v]), style=wx.ALIGN_CENTER)
                    st.SetFont(self.font)

                if v in self.diff_vars:
                    st.SetBackgroundColour(wx.Colour(177, 177, 177))


def main(model):
    wx.Log.SetLogLevel(0)
    app = wx.App()
    app.frame = WindowClass(None, title="TLA+ CEX Inspector")
    app.frame.show_model(model)
    app.MainLoop()
