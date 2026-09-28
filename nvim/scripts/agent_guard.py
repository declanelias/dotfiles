#!/usr/bin/env python3
"""Shared Codex/Claude guard for the Neovim configuration.

The lifecycle adapters pass hook JSON on stdin. Persistent state lives under
the current worktree's private Git directory so it is shared by agents without
dirtying the checkout.
"""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable, Iterable


STATE_VERSION = 1
AUDIT_INTERVAL = 10
AUDITOR_NAMES = {"nvim_auditor", "nvim-auditor"}


def run(command: list[str], cwd: Path, timeout: int = 60) -> subprocess.CompletedProcess[str]:
	return subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=timeout, check=False)


def git_path(cwd: Path, *args: str) -> Path:
	result = run(["git", "rev-parse", "--path-format=absolute", *args], cwd)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip() or "not inside a Git worktree")
	return Path(result.stdout.strip()).resolve()


def repo_root(cwd: Path) -> Path:
	return git_path(cwd, "--show-toplevel")


def private_git_dir(root: Path) -> Path:
	return git_path(root, "--git-dir")


def qualifying_files(root: Path) -> list[Path]:
	nvim = root / "nvim"
	files = [nvim / "init.lua", nvim / "lazy-lock.json", nvim / ".stylua.toml"]
	for directory in (nvim / "lua", nvim / "after"):
		if directory.exists():
			files.extend(directory.rglob("*.lua"))
	return sorted({path for path in files if path.is_file()})


def hash_files(root: Path, paths: Iterable[Path]) -> tuple[str, dict[str, str]]:
	digest = hashlib.sha256()
	entries: dict[str, str] = {}
	for path in sorted(paths):
		relative = path.relative_to(root).as_posix()
		content = path.read_bytes()
		file_hash = hashlib.sha256(content).hexdigest()
		entries[relative] = file_hash
		digest.update(relative.encode())
		digest.update(b"\0")
		digest.update(content)
		digest.update(b"\0")
	return digest.hexdigest(), entries


def hash_file(path: Path) -> str:
	if not path.is_file():
		return "missing"
	return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_lhs(lhs: str) -> str:
	lhs = lhs.replace("\\\\", "\\")
	lhs = re.sub(r"<([^>]+)>", lambda match: "<" + match.group(1).lower() + ">", lhs)
	return lhs


def looks_like_lhs(value: str) -> bool:
	if not value or "/" in value or value.startswith("actions."):
		return False
	if value in {"n", "v", "x", "o", "i", "c", "s", "t", "!"}:
		return False
	return len(value) <= 40


def binding_occurrences(root: Path) -> list[tuple[str, str, str]]:
	"""Return (lhs, source, nearby text) for locally declared mappings."""
	patterns = [
		re.compile(
			r"vim\.keymap\.set\s*\(\s*(?:\{[^}]*\}|[\"'][^\"']+[\"'])\s*,\s*[\"']([^\"']+)[\"']",
			re.S,
		),
		re.compile(
			r"(?<!function )\bmap\s*\(\s*(?:(?:\{[^}]*\}|[\"'][nvisxoct!]+[\"'])\s*,\s*)?[\"']([^\"']+)[\"']",
			re.S,
		),
		re.compile(r"\{\s*[\"']((?:<leader>|<F\d+>|-)[^\"']*)[\"']\s*,", re.I),
		re.compile(r"[\"'](<leader>[^\"']+)[\"']\s*,", re.I),
	]
	oil_pattern = re.compile(r"\[\s*[\"']([^\"']+)[\"']\s*\]\s*=\s*(?:\{|[\"']actions\.)")
	results: dict[tuple[str, str], str] = {}
	for path in qualifying_files(root):
		if path.suffix != ".lua":
			continue
		text = path.read_text(errors="replace")
		lines = text.splitlines()
		line_starts = [0]
		for match in re.finditer("\n", text):
			line_starts.append(match.end())
		for pattern in patterns + ([oil_pattern] if path.name == "oil.lua" else []):
			for match in pattern.finditer(text):
				lhs = canonical_lhs(match.group(1))
				if not looks_like_lhs(lhs):
					continue
				line_number = max(0, len([start for start in line_starts if start <= match.start()]) - 1)
				nearby = " ".join(line.strip() for line in lines[line_number : line_number + 7])
				nearby = re.sub(r"\s+", " ", nearby)[:800]
				source = path.relative_to(root).as_posix()
				# nvim-dap uses this prefix only as a Lazy load trigger; the actual
				# mappings are declared below it and are discovered independently.
				if path.name == "dap.lua" and lhs == "<leader>d" and "keys =" in nearby:
					continue
				results[(lhs, source)] = nearby
	return [(lhs, source, nearby) for (lhs, source), nearby in sorted(results.items())]


def binding_signature(root: Path) -> str:
	payload = json.dumps(binding_occurrences(root), separators=(",", ":"), ensure_ascii=True)
	return hashlib.sha256(payload.encode()).hexdigest()


def documented_tokens(root: Path) -> set[str]:
	bindings = root / "nvim" / "BINDINGS.md"
	if not bindings.is_file():
		return set()
	return {canonical_lhs(token) for token in re.findall(r"`([^`\n]+)`", bindings.read_text())}


def binding_errors(root: Path) -> list[str]:
	tokens = documented_tokens(root)
	missing: dict[str, set[str]] = {}
	for lhs, source, _ in binding_occurrences(root):
		if lhs not in tokens:
			missing.setdefault(lhs, set()).add(source)
	return [
		f"Undocumented mapping {lhs!r} declared in {', '.join(sorted(sources))}"
		for lhs, sources in sorted(missing.items())
	]


def plugin_index_errors(root: Path) -> list[str]:
	lockfile = root / "nvim" / "lazy-lock.json"
	readme = root / "nvim" / "README.md"
	try:
		lock = json.loads(lockfile.read_text())
	except (OSError, json.JSONDecodeError) as error:
		return [f"lazy-lock.json is invalid: {error}"]
	if not readme.is_file():
		return ["nvim/README.md is missing"]
	text = readme.read_text()
	return [f"Plugin {name!r} from lazy-lock.json is missing from README.md" for name in sorted(lock) if f"`{name}`" not in text]


def layout_errors(root: Path) -> list[str]:
	nvim = root / "nvim"
	errors: list[str] = []
	for path in nvim.glob("*.lua"):
		if path.name != "init.lua":
			errors.append(f"Unexpected root Lua file {path.relative_to(root)}; place it under lua/declan")
	for path in (nvim / "undo").rglob("*.lua") if (nvim / "undo").exists() else []:
		errors.append(f"Generated undo directory contains Lua configuration: {path.relative_to(root)}")
	after = nvim / "after"
	if after.exists():
		for child in after.iterdir():
			if child.name not in {"plugin", "ftplugin"}:
				errors.append(f"Unexpected after/ entry {child.relative_to(root)}")
	for path in (nvim / "lua" / "declan" / "lazy").glob("*.lua"):
		if "return {" not in path.read_text(errors="replace"):
			errors.append(f"Lazy spec {path.relative_to(root)} does not return a spec table")
	return errors


def format_failure(label: str, result: subprocess.CompletedProcess[str]) -> str:
	output = (result.stdout + result.stderr).strip()
	if len(output) > 4000:
		output = output[:4000] + "\n… output truncated"
	return f"{label} failed" + (f":\n{output}" if output else "")


def config_errors(root: Path, include_bindings: bool = True) -> list[str]:
	errors: list[str] = []
	stylua = run(["stylua", "--check", "nvim"], root, timeout=60)
	if stylua.returncode != 0:
		errors.append(format_failure("StyLua check", stylua))

	parse_lua = (
		"for _, f in ipairs(vim.fn.glob('nvim/**/*.lua', false, true)) do "
		"local chunk, err = loadfile(f); if not chunk then error(err) end end"
	)
	parsed = run(["nvim", "--clean", "--headless", "-u", "NONE", "-c", f"lua {parse_lua}", "-c", "qa"], root)
	if parsed.returncode != 0:
		errors.append(format_failure("Lua parse check", parsed))

	startup = run(
		["nvim", "--headless", "-u", str(root / "nvim" / "init.lua"), "-c", "lua vim.wait(500)", "-c", "qa"],
		root,
		timeout=30,
	)
	if startup.returncode != 0:
		errors.append(format_failure("Headless Neovim startup", startup))

	errors.extend(plugin_index_errors(root))
	errors.extend(layout_errors(root))
	if include_bindings:
		errors.extend(binding_errors(root))
	return errors


def snapshot(root: Path) -> dict[str, Any]:
	config_hash, files = hash_files(root, qualifying_files(root))
	return {
		"config": config_hash,
		"files": files,
		"bindings": binding_signature(root),
		"bindings_doc": hash_file(root / "nvim" / "BINDINGS.md"),
		"readme": hash_file(root / "nvim" / "README.md"),
		"lock": hash_file(root / "nvim" / "lazy-lock.json"),
	}


def default_state() -> dict[str, Any]:
	return {
		"version": STATE_VERSION,
		"completed_edits": 0,
		"audit_due": False,
		"audit_reason": None,
		"audit": {},
		"sessions": {},
	}


class StateStore:
	def __init__(self, git_dir: Path):
		self.directory = git_dir / "nvim-agent-guard"
		self.path = self.directory / "state.json"
		self.lock_path = self.directory / "state.lock"

	@contextlib.contextmanager
	def locked(self):
		self.directory.mkdir(parents=True, exist_ok=True)
		with self.lock_path.open("a+") as lock:
			fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
			try:
				if self.path.exists():
					try:
						state = json.loads(self.path.read_text())
					except json.JSONDecodeError as error:
						raise RuntimeError(f"guard state is corrupt: {self.path}: {error}") from error
					if state.get("version") != STATE_VERSION:
						raise RuntimeError(f"unsupported guard state version in {self.path}")
				else:
					state = default_state()
				yield state
				temporary = self.path.with_suffix(".tmp")
				temporary.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
				os.replace(temporary, self.path)
			finally:
				fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def session_prefix(platform: str, payload: dict[str, Any]) -> str:
	return f"{platform}:{payload.get('session_id', 'unknown')}"


def requested_session_key(platform: str, payload: dict[str, Any]) -> str:
	prefix = session_prefix(platform, payload)
	turn = payload.get("turn_id")
	return f"{prefix}:{turn}" if turn else prefix


def active_session_key(state: dict[str, Any], platform: str, payload: dict[str, Any]) -> str:
	prefix = session_prefix(platform, payload)
	for key, value in state["sessions"].items():
		if key.startswith(prefix) and value.get("blocking"):
			return key
	return requested_session_key(platform, payload)


def post_context(message: str) -> dict[str, Any]:
	return {
		"hookSpecificOutput": {
			"hookEventName": "PostToolUse",
			"additionalContext": message,
		}
	}


def block(reason: str) -> dict[str, Any]:
	return {"decision": "block", "reason": reason}


def audit_instruction(platform: str, reason: str | None) -> str:
	why = reason or "the periodic Neovim audit is due"
	if platform == "claude":
		invocation = "Invoke @nvim-auditor in the foreground and wait for it."
	else:
		invocation = "Spawn the configured nvim_auditor subagent in read-only mode and wait for it."
	return (
		f"A full Neovim audit is required because {why}. {invocation} "
		"It must follow nvim/AUDIT.md. Fix every finding and rerun the auditor until its final line is "
		"NVIM_AUDIT: PASS, then try to finish again."
	)


def process_hook(
	root: Path,
	git_dir: Path,
	platform: str,
	payload: dict[str, Any],
	check: Callable[[Path], list[str]] = config_errors,
) -> dict[str, Any] | None:
	event = payload.get("hook_event_name", "")
	store = StateStore(git_dir)
	current = snapshot(root)

	with store.locked() as state:
		key = active_session_key(state, platform, payload)
		sessions = state["sessions"]

		if event == "UserPromptSubmit":
			existing = sessions.get(key)
			if not existing or not existing.get("blocking"):
				sessions[key] = {"baseline": current, "reminded": False, "blocking": False, "counted": False}
			return None

		if event == "PostToolUse":
			session = sessions.get(key)
			if not session:
				sessions[key] = {"baseline": current, "reminded": False, "blocking": False, "counted": False}
				return None
			if current["config"] != session["baseline"]["config"] and not session.get("reminded"):
				session["reminded"] = True
				return post_context(
					"Neovim configuration changed. Read nvim/STYLE.md, review BINDINGS.md, and run "
					"nvim/scripts/check-config plus nvim/scripts/check-bindings before finishing."
				)
			return None

		if event == "SubagentStart" and payload.get("agent_type") in AUDITOR_NAMES:
			state["audit"] = {
				"status": "running",
				"platform": platform,
				"session_id": payload.get("session_id"),
				"agent_id": payload.get("agent_id"),
				"fingerprint": current["config"],
			}
			return None

		if event == "SubagentStop" and payload.get("agent_type") in AUDITOR_NAMES:
			message = payload.get("last_assistant_message") or ""
			audit = state.get("audit", {})
			same_agent = not audit.get("agent_id") or audit.get("agent_id") == payload.get("agent_id")
			passed = "NVIM_AUDIT: PASS" in message and "NVIM_AUDIT: FAIL" not in message
			audit.update(
				{
					"status": "passed" if passed and same_agent else "failed",
					"result_fingerprint": current["config"],
					"last_message": message[-2000:],
				}
			)
			state["audit"] = audit
			return None

		if event != "Stop":
			return None

		# Settings hooks also run in subagents on Claude. The dedicated
		# SubagentStop event records auditor completion; a subagent does not own
		# the parent turn's completion gate.
		if payload.get("agent_id"):
			return None

		session = sessions.get(key)
		if not session:
			sessions[key] = {"baseline": current, "reminded": False, "blocking": False, "counted": False}
			return None

		changed = current["config"] != session["baseline"]["config"]
		if changed:
			errors = check(root)
			if errors:
				session["blocking"] = True
				return block(
					"Neovim validation failed. Fix these issues and rerun the checks before finishing:\n\n- "
					+ "\n- ".join(errors)
				)

			bindings_changed = current["bindings"] != session["baseline"]["bindings"]
			docs_changed = current["bindings_doc"] != session["baseline"]["bindings_doc"]
			if bindings_changed and not docs_changed:
				session["blocking"] = True
				return block(
					"The Neovim mapping signature changed, but nvim/BINDINGS.md did not. Review the changed key, "
					"mode, scope, description, and behavior; update BINDINGS.md, then rerun the checks."
				)

			if not session.get("counted"):
				state["completed_edits"] = int(state.get("completed_edits", 0)) + 1
				session["counted"] = True
				session["counted_fingerprint"] = current["config"]

			lock_changed = current["lock"] != session["baseline"]["lock"]
			if lock_changed:
				state["audit_due"] = True
				state["audit_reason"] = "lazy-lock.json changed, so plugin-provided default bindings need review"
			elif state["completed_edits"] >= AUDIT_INTERVAL:
				state["audit_due"] = True
				state["audit_reason"] = f"{AUDIT_INTERVAL} completed Neovim edit batches accumulated"

		if state.get("audit_due"):
			audit = state.get("audit", {})
			valid_pass = audit.get("status") == "passed" and audit.get("result_fingerprint") == current["config"]
			if not valid_pass:
				session["blocking"] = True
				return block(audit_instruction(platform, state.get("audit_reason")))
			state["completed_edits"] = 0
			state["audit_due"] = False
			state["audit_reason"] = None
			state["audit"] = {}

		sessions.pop(key, None)
	return None


def emit(result: dict[str, Any] | None) -> None:
	if result is not None:
		print(json.dumps(result, separators=(",", ":")))


def hook_command(platform: str) -> int:
	try:
		payload = json.load(sys.stdin)
		cwd = Path(payload.get("cwd") or os.getcwd()).resolve()
		root = repo_root(cwd)
		emit(process_hook(root, private_git_dir(root), platform, payload))
		return 0
	except Exception as error:  # A broken guard must be visible and blocking.
		print(f"Neovim lifecycle guard failed: {error}", file=sys.stderr)
		return 2


def check_command(root: Path, bindings_only: bool) -> int:
	errors = binding_errors(root) if bindings_only else config_errors(root)
	if errors:
		for error in errors:
			print(f"ERROR: {error}")
		return 1
	print("Neovim bindings are documented." if bindings_only else "Neovim configuration checks passed.")
	return 0


def status_command(root: Path) -> int:
	store = StateStore(private_git_dir(root))
	with store.locked() as state:
		print(json.dumps(state, indent=2, sort_keys=True))
	return 0


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	subparsers = parser.add_subparsers(dest="command", required=True)
	hook_parser = subparsers.add_parser("hook")
	hook_parser.add_argument("--platform", choices=("codex", "claude"), required=True)
	subparsers.add_parser("check")
	subparsers.add_parser("check-bindings")
	subparsers.add_parser("status")
	args = parser.parse_args()

	if args.command == "hook":
		return hook_command(args.platform)
	root = repo_root(Path.cwd())
	if args.command == "check":
		return check_command(root, bindings_only=False)
	if args.command == "check-bindings":
		return check_command(root, bindings_only=True)
	return status_command(root)


if __name__ == "__main__":
	raise SystemExit(main())
