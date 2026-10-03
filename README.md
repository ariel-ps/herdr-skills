# herdr-skills

Open-source [Agent Skills](https://cursor.com/docs/skills) for working inside [Herdr](https://herdr.dev) panes (`HERDR_ENV=1`). Complements the upstream core skill in [herdrdev/herdr](https://github.com/herdrdev/herdr).

## Install everything

**Recommended** (uses the [skills CLI](https://github.com/vercel-labs/skills)):

```sh
npx skills add ariel-ps/herdr-skills/skills --all -g -y \
  --agent cursor,claude-code,codex
```

Also install the official Herdr CLI skill (not duplicated in this repo):

```sh
npx skills add herdrdev/herdr --skill herdr -g -y
```

**From an agent:** invoke `/herdr-skills-setup` (after the setup skill is installed once) or ask to “install herdr-skills”; it runs `skills/herdr-skills-setup/scripts/install-all.sh`.

**Bootstrap only the setup skill:**

```sh
npx skills add ariel-ps/herdr-skills/skills/herdr-skills-setup -g -y --agent cursor
```

## Catalog

| Skill | Purpose |
| --- | --- |
| [herdr-skills-setup](skills/herdr-skills-setup/) | Install or refresh all skills in this repo |
| [herdr-delegation](skills/herdr-delegation/) | Split panes, start agents, delegate plan/implement/review ([Datalumina guide](https://learn.datalumina.com/docs/herdr/delegation)) |
| [herdr-agent-talk](skills/herdr-agent-talk/) | Prompt another pane’s agent and read its reply (blocked, stalls, fan-out) |

## Layout

```text
skills/<name>/SKILL.md    # one skill per directory (Agent Skills standard)
```

Add a skill by creating a new folder under `skills/` and opening a PR.

## Develop

When working in a clone, sync into global agent dirs without `npx`:

```sh
sh skills/herdr-skills-setup/scripts/install-all.sh --local
```

## License

MIT — see [LICENSE](LICENSE).
