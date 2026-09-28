#!/usr/bin/env python3

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "agent_guard.py"
SPEC = importlib.util.spec_from_file_location("agent_guard", SCRIPT)
assert SPEC and SPEC.loader
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)


class AgentGuardTest(unittest.TestCase):
	def setUp(self):
		self.temporary = tempfile.TemporaryDirectory()
		self.root = Path(self.temporary.name)
		subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
		(self.root / "nvim/lua/declan").mkdir(parents=True)
		(self.root / "nvim/init.lua").write_text('require("declan")\n')
		(self.root / "nvim/lua/declan/set.lua").write_text("vim.opt.number = true\n")
		(self.root / "nvim/lazy-lock.json").write_text("{}\n")
		(self.root / "nvim/.stylua.toml").write_text('indent_type = "Tabs"\n')
		(self.root / "nvim/BINDINGS.md").write_text("# Bindings\n")
		(self.root / "nvim/README.md").write_text("# Neovim\n")
		self.git_dir = guard.private_git_dir(self.root)

	def tearDown(self):
		self.temporary.cleanup()

	def event(self, name, platform="codex", **extra):
		payload = {"hook_event_name": name, "session_id": "session-1", "cwd": str(self.root)}
		payload.update(extra)
		return guard.process_hook(self.root, self.git_dir, platform, payload, check=lambda _: [])

	def state(self):
		path = self.git_dir / "nvim-agent-guard/state.json"
		return json.loads(path.read_text())

	def test_counts_one_completed_change_batch(self):
		self.event("UserPromptSubmit", turn_id="turn-1")
		with (self.root / "nvim/lua/declan/set.lua").open("a") as file:
			file.write("vim.opt.wrap = true\n")
		context = self.event("PostToolUse", turn_id="turn-1")
		self.assertIn("additionalContext", context["hookSpecificOutput"])
		self.assertIsNone(self.event("Stop", turn_id="turn-1"))
		self.assertEqual(self.state()["completed_edits"], 1)

	def test_mapping_change_requires_bindings_edit(self):
		self.event("UserPromptSubmit", turn_id="turn-2")
		with (self.root / "nvim/lua/declan/set.lua").open("a") as file:
			file.write('vim.keymap.set("n", "<leader>z", "zz", { desc = "Center" })\n')
		result = self.event("Stop", turn_id="turn-2")
		self.assertEqual(result["decision"], "block")
		self.assertIn("BINDINGS.md", result["reason"])

	def test_tenth_change_requires_and_accepts_auditor(self):
		store = guard.StateStore(self.git_dir)
		with store.locked() as state:
			state["completed_edits"] = 9
		self.event("UserPromptSubmit", turn_id="turn-3")
		with (self.root / "nvim/lua/declan/set.lua").open("a") as file:
			file.write("vim.opt.cursorline = true\n")
		result = self.event("Stop", turn_id="turn-3")
		self.assertEqual(result["decision"], "block")
		self.assertIn("nvim_auditor", result["reason"])

		self.event("SubagentStart", agent_type="nvim_auditor", agent_id="audit-1")
		self.event(
			"SubagentStop",
			agent_type="nvim_auditor",
			agent_id="audit-1",
			last_assistant_message="No findings.\nNVIM_AUDIT: PASS",
		)
		self.assertIsNone(self.event("Stop", turn_id="turn-3"))
		self.assertEqual(self.state()["completed_edits"], 0)

	def test_claude_uses_opus_agent_name_and_fail_does_not_clear_audit(self):
		store = guard.StateStore(self.git_dir)
		with store.locked() as state:
			state["completed_edits"] = 9
		self.event("UserPromptSubmit", platform="claude")
		with (self.root / "nvim/lua/declan/set.lua").open("a") as file:
			file.write("vim.opt.signcolumn = 'yes'\n")
		result = self.event("Stop", platform="claude")
		self.assertIn("@nvim-auditor", result["reason"])

		self.event("SubagentStart", platform="claude", agent_type="nvim-auditor", agent_id="audit-2")
		self.event(
			"SubagentStop",
			platform="claude",
			agent_type="nvim-auditor",
			agent_id="audit-2",
			last_assistant_message="One finding remains.\nNVIM_AUDIT: FAIL",
		)
		result = self.event("Stop", platform="claude")
		self.assertEqual(result["decision"], "block")
		self.assertTrue(self.state()["audit_due"])

	def test_lockfile_change_forces_immediate_audit(self):
		self.event("UserPromptSubmit", turn_id="turn-4")
		(self.root / "nvim/lazy-lock.json").write_text('{"plugin": {}}\n')
		(self.root / "nvim/README.md").write_text("# Neovim\n\n`plugin`\n")
		result = self.event("Stop", turn_id="turn-4")
		self.assertEqual(result["decision"], "block")
		self.assertIn("lazy-lock.json changed", result["reason"])


if __name__ == "__main__":
	unittest.main()
