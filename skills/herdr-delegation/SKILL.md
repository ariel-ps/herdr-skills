---
name: herdr-delegation
description: Delegate work across Herdr panes—split layout, start another agent, prompt and wait, read output, run side processes. Use when the user asks to use Herdr to delegate, get a second opinion, plan then implement in another pane, run tests or a dev server on the side, or follow the Datalumina Herdr delegation workflow. Requires HERDR_ENV=1 and the herdr CLI skill or equivalent CLI knowledge.
---

# Herdr delegation

Playbook for **one agent handing work to another** (or to a shell pane) inside Herdr. Herdr exposes a local JSON CLI over a unix socket; agents in panes with `HERDR_ENV=1` are first-class clients alongside the UI.

Human-oriented walkthrough: [Agent delegation (Datalumina Learn)](https://learn.datalumina.com/docs/herdr/delegation).

For prompt delivery, blocked dialogs, stalls, and multi-agent fan-out, also follow **herdr-agent-talk** when those details matter.

## Prerequisites

```bash
test "${HERDR_ENV:-}" = 1
command -v herdr >/dev/null 2>&1
```

If `HERDR_ENV` is unset, you are not in a Herdr-managed pane—stop and say so.

Install the upstream CLI skill if it is missing:

```bash
npx skills add herdrdev/herdr --skill herdr -g -y
# or: herdr --skill
```

Your pane ids (examples):

```bash
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_TAB_ID" "$HERDR_PANE_ID"
```

## Two layers

| Layer | Use for |
| --- | --- |
| **Pane** (`herdr pane …`) | Shell commands, servers, tests, raw output |
| **Agent** (`herdr agent …`) | Coding agents with lifecycle: `idle`, `working`, `blocked`, `done` |

Cross-harness delegation works: any supported agent kind can drive any other via the CLI.

## Core delegate loop

Keep the user's focus on the caller unless they asked to switch panes.

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')

herdr agent start coder --kind codex --pane "$pane"

herdr agent prompt coder "Implement the plan in docs/plan.md" \
  --wait --timeout 600000

herdr agent read coder --source recent-unwrapped --lines 120
```

Pick `--kind` from what the user requested (`claude`, `codex`, `cursor`, `grok`, `opencode`, `copilot`, …). Run `herdr agent start --help` for the installed list.

List live agents before addressing by name:

```bash
herdr agent list
```

## Common patterns

**Plan → implement → review.** Caller keeps the plan; start an implementer in a split; when settled, read output and review the diff from the caller's cwd.

**Side process.** Split with `--no-focus`, run server or tests with `herdr pane run` / shell in the new pane, read with `herdr pane read` or agent read as appropriate.

**Second opinion.** Start a reviewer with a different `--kind` if useful; same prompt/wait/read loop; identify yourself in the prompt text (see herdr-agent-talk).

**Blocked on a question.** When `--wait` ends in `blocked`, read the pane; answer via `agent prompt` only when appropriate, or escalate to the user—never bypass `blocked` with `pane send-text` into approval dialogs.

## Safety

- Use `--no-focus` for background splits unless the user wants context switch.
- Do not close panes, agents, or workspaces you did not create.
- Do not stop the Herdr server.
- Confirm before fanning the same prompt to many agents (token and file cost).

## Verify

```bash
herdr agent list
```

The agent should report JSON that includes its own pane.
