import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from tests import luau_parser
from tests._common import ROOT

import sys
sys.path.insert(0, str(ROOT / "tools"))
import rojo_build  # noqa: E402


class RojoBuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = Path(tempfile.mkdtemp())
        cls.out = cls.tmp / "WarState.rbxlx"
        cls.info = rojo_build.build_place(ROOT / "default.project.json", cls.out)
        cls.xml = ET.parse(cls.out).getroot()

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def items(self, cls_name):
        return [i for i in self.xml.iter("Item") if i.get("class") == cls_name]

    def name_of(self, item):
        for s in item.find("Properties").findall("string"):
            if s.get("name") == "Name":
                return s.text
        return None

    def test_place_file_is_valid_xml_with_scripts(self):
        self.assertEqual(len(self.items("Script")), 2)  # ServerMain + RuntimeSelfTest
        self.assertEqual(len(self.items("LocalScript")), 1)  # ClientMain
        self.assertGreater(len(self.items("ModuleScript")), 40)

    def test_remotes_built(self):
        names = {self.name_of(i) for i in self.items("RemoteFunction")}
        for n in ("CreateCountry", "ClaimPlot", "GetPlots", "PlaceRoadLine", "PlaceBuilding", "Demolish"):
            self.assertIn(n, names)
        events = {self.name_of(i) for i in self.items("RemoteEvent")}
        self.assertEqual(events, {"StateChanged", "PlotsChanged", "Notify"})

    def test_main_ui_properties(self):
        gui = self.items("ScreenGui")[0]
        bools = {b.get("name"): b.text for b in gui.find("Properties").findall("bool")}
        self.assertEqual(bools.get("ResetOnSpawn"), "false")

    def test_json_modules_are_valid_luau(self):
        root = self.info["root"]
        for node in root.walk():
            if node.class_name in ("ModuleScript", "Script", "LocalScript") and node.source is not None:
                self.assertEqual(luau_parser.parse_luau(node.source), [], node.name)

    def test_expected_paths(self):
        paths = set(rojo_build.instance_paths(self.info["root"]))
        for p in (
            "ReplicatedStorage/Shared/Config/GameConfig",
            "ReplicatedStorage/Shared/Modules/UtilityGrid",
            "ServerScriptService/Systems/Water/WaterService",
            "ServerScriptService/Systems/Power/PowerService",
            "StarterGui/MainUI/Screens/StatsPanel",
            "StarterGui/MainUI/Screens/PlotScreen",
            "StarterPlayer/StarterPlayerScripts/Controllers/ConstructionBars",
            "Workspace/Map",
        ):
            self.assertIn(p, paths)

    @unittest.skipUnless(shutil.which("rojo"), "rojo binary not installed")
    def test_real_rojo_build(self):
        out = self.tmp / "rojo.rbxlx"
        result = subprocess.run(["rojo", "build", str(ROOT / "default.project.json"), "-o", str(out)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
