# Git Workshop Toolkit

Two things for a hands-on Git workshop:

- **[`visualizer/`](visualizer/index.html)** — a single-page animated
  visualizer showing what 21 git commands actually do to your Working
  Directory, Staging Area, Local Repo, and Remote. Also published as a
  Claude Artifact for easy sharing/projecting:
  https://claude.ai/artifact/Xo76ztsw5spyxRPwxseNUd
- **[`speedrun/`](speedrun/README.md)** — a 38-task "Git Speedrun"
  competition kit: per-team starter repos with real seeded history, a
  guaranteed merge conflict, a guaranteed rebase conflict, a local fake
  "remote" (no GitHub accounts needed), and an optional auto-scoring script.
  Start with [`speedrun/README.md`](speedrun/README.md).
- **[`demo/`](demo/demo-script.md)** — a live teaching script for the
  instructor: a command-by-command walkthrough of all 21 visualizer commands
  against a real (resettable) demo repo, for presenting at the front of the
  room before teams start the speedrun. Run `demo/start-demo.sh` (or `.ps1`)
  to generate the demo repo, then follow `demo/demo-script.md`.

See [`handoff.md`](handoff.md) for the full design rationale behind the
speedrun kit's seed data (why each bug/branch/commit exists) — read it before
editing `speedrun/setup-team.sh` or `.ps1`, since the two must stay in sync
with each other.
