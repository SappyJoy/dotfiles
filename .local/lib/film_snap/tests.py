"""Tests: PYTHONPATH=~/.local/lib python3 -m unittest film_snap.tests"""
import unittest

from . import core, i3, monitors, tmux

HOME = [1200, 2400]  # 3 portrait monitors, FILM 3600 wide
WORK = [1080]  # 2 portrait monitors, FILM 2160 wide


class Targets(unittest.TestCase):
    def test_two_columns_tie_gives_the_right_one_one_monitor(self):
        self.assertEqual(core.targets([1800], HOME, 3600, 150), [2400])

    def test_two_columns_nearest_border(self):
        self.assertEqual(core.targets([1500], HOME, 3600, 150), [1200])

    def test_three_columns_one_per_monitor(self):
        self.assertEqual(core.targets([1000, 2500], HOME, 3600, 150), [1200, 2400])

    def test_new_window_next_to_a_wide_one(self):
        # browser 2400 | terminal 1200, the terminal splits: 2400 | 600 | 600
        self.assertEqual(core.targets([2400, 3000], HOME, 3600, 150), [1200, 2400])

    def test_four_columns_split_one_monitor(self):
        self.assertEqual(core.targets([600, 1200, 2400], HOME, 3600, 150), [600, 1200, 2400])
        self.assertEqual(core.targets([900, 1800, 2700], HOME, 3600, 150), [1200, 1800, 2400])

    def test_work_two_monitors(self):
        self.assertEqual(core.targets([1080], WORK, 2160, 150), [1080])
        self.assertEqual(core.targets([720, 1440], WORK, 2160, 150), [1080, 1620])

    def test_no_borders_inside_leaves_cuts_alone(self):
        self.assertEqual(core.targets([400], [1200], 1000, 150), [400])
        self.assertEqual(core.targets([], HOME, 3600, 150), [])

    def test_too_narrow_is_none(self):
        self.assertIsNone(core.targets([10, 20, 30, 40], HOME, 3600, 1000))


class Moves(unittest.TestCase):
    def test_order_keeps_columns_positive(self):
        self.assertEqual(core.moves([100, 200], [250, 350], 400), [(1, 150), (0, 150)])

    def test_tolerance_skips_small_moves(self):
        self.assertEqual(core.moves([1201, 2000], [1200, 2400], 3600, 2), [(1, 400)])


class Monitors(unittest.TestCase):
    def test_inner_edges(self):
        out = "DP-4 0 0 1200 1920 324 518\nDP-0 1200 0 1200 1920 324 518\nDP-2 2400 0 1200 1920 324 518\n"
        self.assertEqual(monitors.borders_from(out), HOME)
        self.assertEqual(monitors.borders_from("eDP-1 0 0 1920 1080 344 194\n"), [])


def window(con_id, x, width):
    return {"id": con_id, "rect": {"x": x, "width": width}, "nodes": []}


class I3Plan(unittest.TestCase):
    # Gaps: outer 3, inner 5 -> workspace x=3 w=3594, columns inset by 5 px
    def workspace(self, *cols, layout="splith"):
        return {"type": "workspace", "layout": layout, "rect": {"x": 3, "width": 3594},
                "nodes": list(cols)}

    def test_two_even_windows_snap(self):
        ws = self.workspace(window(1, 8, 1787), window(2, 1805, 1787))
        self.assertEqual(i3.plan(ws, HOME), "[con_id=1] resize grow right 600 px")

    def test_already_snapped(self):
        ws = self.workspace(window(1, 8, 2387), window(2, 2405, 1187))
        self.assertEqual(i3.plan(ws, HOME), "")

    def test_vertical_workspace_has_no_columns(self):
        ws = self.workspace(window(1, 8, 3584), window(2, 8, 3584), layout="splitv")
        self.assertEqual(i3.plan(ws, HOME), "")

    def test_single_child_container_is_descended(self):
        inner = {"id": 9, "layout": "splith", "rect": {"x": 3, "width": 3594},
                 "nodes": [window(1, 8, 1787), window(2, 1805, 1787)]}
        self.assertIn("con_id=1", i3.plan(self.workspace(inner, layout="splitv"), HOME))

    def test_relevant_events(self):
        self.assertTrue(i3.relevant({"change": "new", "container": {}}))
        self.assertFalse(i3.relevant({"change": "focus", "container": {}}))
        self.assertTrue(i3.relevant({"change": "default", "pango_markup": False}))
        self.assertTrue(i3.relevant({"first": False, "payload": "film-snap"}))


class TmuxPlan(unittest.TestCase):
    LAYOUT = "89c3,511x115,0,0{173x115,0,0,0,337x115,174,0[337x57,174,0,3,337x57,174,58,5]}"

    def test_parse(self):
        root = tmux.parse_layout(self.LAYOUT)
        self.assertEqual(root["split"], "{")
        self.assertEqual([c["w"] for c in root["children"]], [173, 337])
        self.assertEqual(tmux.first_pane(root["children"][1]), 3)

    def test_plan_moves_separator_to_the_border(self):
        # kitty text area x=10, 3584 px, 511 cells -> 7 px per cell; border 1200 -> cell 170
        self.assertEqual(tmux.plan(self.LAYOUT, 511, 10, 3584, HOME),
                         [["resize-pane", "-t", "%0", "-L", "3"]])

    def test_single_pane_and_stacks_are_left_alone(self):
        self.assertEqual(tmux.plan("abcd,511x115,0,0,0", 511, 10, 3584, HOME), [])
        self.assertEqual(tmux.plan("abcd,511x115,0,0[511x57,0,0,1,511x57,0,58,2]", 511, 10, 3584, HOME), [])


if __name__ == "__main__":
    unittest.main()
