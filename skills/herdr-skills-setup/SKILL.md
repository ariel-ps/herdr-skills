---
name: herdr-skills-setup
description: Install or update all open-source Herdr agent skills from ariel-ps/herdr-skills. Use when the user asks to install herdr-skills, set up Herdr skills, refresh Herdr skills, or sync the herdr-skills catalog.
disable-model-invocation: true
---

# herdr-skills setup

Install the full **herdr-skills** catalog into global agent skill directories, and ensure the upstream **herdr** CLI skill is present.

## Run

From this repository checkout (plugin root or clone):

```bash
sh skills/herdr-skills-setup/scripts/install-all.sh
```

From anywhere (uses GitHub + `npx skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ariel-ps/herdr-skills/main/skills/herdr-skills-setup/scripts/install-all.sh | sh
```

Or run the script via an absolute path after locating the repo.

## After install

- Confirm with `npx skills list -g` when the skills CLI is available.
- Skills require a Herdr pane for live control (`HERDR_ENV=1`); the **herdr** skill from `herdrdev/herdr` documents the CLI.

## Options (environment)

| Variable | Default | Meaning |
| --- | --- | --- |
| `HERDR_SKILLS_REPO` | `ariel-ps/herdr-skills` | GitHub `owner/repo` |
| `HERDR_SKILLS_REF` | `main` | Branch or tag for remote install |
| `HERDR_SKILLS_SUBPATH` | `skills` | Subdirectory containing skill folders |

Pass `--local` to `install-all.sh` when syncing from a git checkout without `npx`.
