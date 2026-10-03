---
name: herdr-agent-talk
description: Send a prompt from this agent into another agent running in a herdr pane, and read its reply. Use when the user says "ask the codex session", "send this to winguard", "get a second opinion from another agent", "delegate this to a new agent", "what did the other agent say", "tell all the agents X", or wants two coding agents to work on the same problem. Requires herdr and HERDR_ENV=1.
---

# herdr agent-to-agent

herdr has no messaging primitive — no mailbox, no addressed message, no reply
channel. Its entire agent surface is twelve methods and none of them are
`send`. What it has is `agent prompt`, which **injects text into another
agent's input exactly as if the user typed it**.

Everything below follows from that. The receiving agent cannot tell your prompt
from a human's, so say who you are in the text. There is no queue, so the
recipient must be alive and able to receive right now. There is no reply
channel, so you read the answer off its screen.

For durable, addressed, replayable messaging between agents, that is what the
`channel` skill and the `chan` CLI are for. Use this skill when you want a live
agent to do something now and you want its answer back.

## Before anything

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails you are not inside a herdr pane. Say so and stop — do not try to
drive someone else's session from outside it.

## Find who you can talk to

```bash
herdr agent list | jq -r '.result.agents[] | [.pane_id, .agent, .agent_status, .terminal_title_stripped] | @tsv'
```

Address an agent by **pane id** (`w1:p6`) or by a **live agent name** if one was
assigned. Names match `[a-z][a-z0-9_-]{0,31}`, must be unique among live agents,
and are cleared when that agent exits or is replaced — a name is an alias for
whoever occupies the pane now, not a permanent handle. Assign one when you are
about to refer to the same agent repeatedly:

```bash
herdr agent rename w1:p6 reviewer
```

Never guess a pane id or name. Read them from the JSON.

## The five states, and which ones accept a prompt

| state | meaning | prompt it? |
| --- | --- | --- |
| `idle` | ready, and you have seen its last result | yes |
| `done` | ready, result not yet marked seen | yes |
| `working` | mid-turn | yes — herdr accepts it |
| `blocked` | sitting at an approval or question dialog | **no** |
| `unknown` | an agent is present, herdr cannot classify it | yes, but verify the reply |

`blocked` is the only refusal. `agent prompt` returns `agent_blocked` **without
sending any input**, which is the guardrail: it will not type your message into
a y/n dialog. Do not work around it with `pane send-text`. Inspect the dialog,
and ask the user before answering on their behalf.

`unknown` does not mean finished. Never read it as success.

## Send a prompt and get the answer

```bash
herdr agent prompt reviewer "[from $HERDR_PANE_ID] Does proxy_addon.py fail open on an unknown classification? One line." \
  --wait --timeout 120000
herdr agent read reviewer --source recent-unwrapped --lines 120
```

Lead the text with your own identity. herdr sends no sender field, so without
this the other agent has no idea a peer is talking to it and will answer as if
the user asked.

`--wait` returns on the first settled `idle`, `done`, or `blocked`. That is
enough for normal work; do not also pass `--until` to restate those defaults.
Use `--until` only for a state-specific wait, such as waiting for an agent that
is already running to come back and ask for input:

```bash
herdr agent wait reviewer --until blocked --timeout 120000
```

Read with `recent-unwrapped` for transcripts and logs — it joins soft wraps.
Use `--format ansi` only when colour is itself the evidence.

## Failures that are not what they look like

`agent_prompt_stalled` and `timeout` **do not prove your prompt was never
delivered**. herdr waits five seconds after submitting to observe real
`working` or `blocked` activity; an unrelated `idle` will not satisfy that gate.
Read the agent before retrying, or you will submit the same work twice.

If `--wait` returns `blocked`, your prompt landed and the agent is now asking
something. Read it before deciding what to send.

If a read is truncated, the agent is rendering on the alternate screen and rows
that scrolled off are gone from herdr's scrollback — a bigger `--lines` cannot
recover them. Ask the agent to write its full answer as Markdown to a temp file
and reply with only the path, then read the file. Use this as a fallback, not in
the first prompt.

## Delegate to a fresh agent

`agent start` needs an existing shell pane already at its prompt; it never
creates or splits layout. So make the pane first, and keep the user's focus
where it is:

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
herdr agent start reviewer --kind codex --pane "$pane"
herdr agent prompt reviewer "[from $HERDR_PANE_ID] Independent review of the current diff. Findings only." --wait --timeout 300000
```

Split a wide pane right and a narrow or tall one down; check with
`herdr pane layout --pane "$HERDR_PANE_ID"`. Pick the `--kind` the user asked
for — `herdr agent` lists what is installed. Native agent flags go after `--`.

A fresh worktree pane may pause at the harness's folder-trust dialog while
`agent list` still reports it running. That is the user's decision on a real
repo: ask before accepting it.

## Ask several agents the same question

Useful for a second opinion across vendors. Prompt each without `--wait`, then
collect:

```bash
for p in $(herdr agent list | jq -r '.result.agents[] | select(.agent_status != "blocked") | .pane_id'); do
  [ "$p" = "$HERDR_PANE_ID" ] && continue   # never prompt yourself
  herdr agent prompt "$p" "[from $HERDR_PANE_ID] One line: is this repo's retry logic sound?"
done
```

Skip your own pane, or you will prompt yourself into a loop. Then `agent wait`
and `agent read` each one.

## Rules

- Identify yourself in every prompt. There is no sender field.
- Never prompt a `blocked` agent, and never bypass the refusal with pane input.
- Read pane ids and names from JSON, never from sidebar order or an example.
- Use `--no-focus` for background work unless the user asked to switch context.
- Do not close panes, agents, or workspaces you did not create.
- A timeout is not proof of non-delivery. Read before you retry.
- Prompting another agent spends that agent's tokens and can change files under
  its cwd. Confirm with the user before fanning out to several at once.
