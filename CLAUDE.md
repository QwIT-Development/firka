# Firka

Before you change code, write a comment or make a commit in this repo, get the style guide and read it. It is in a separate repo so it stays the same across all Firka projects.

## Get the style guide

Clone it next to this repo. If it is already there, update it.

```bash
[ -d ../style-guide ] && git -C ../style-guide pull --ff-only \
  || git clone https://git.firka.app/firka/style-guide.git ../style-guide
```

Then read `../style-guide/skills/firka-style/SKILL.md` and follow it. It covers how the code looks, comments, commit messages, adding a screen, string or setting, and how to branch, push and open a PR.

If the skills are not installed on this machine yet (`ls ~/.claude/skills`), follow the install steps in `../style-guide/CLAUDE.md`. That sets up `firka-style`, `anti-over-engineering` and `graphify`.

## If you cannot reach the style guide

Stick to these until you can:

- Match the code next to what you are changing. Reuse existing widgets, cubits and helpers. No new abstractions, no extra files, no refactors nobody asked for.
- Commits are `type(scope): lowercase subject`, no full stop. Types: `fix`, `feat`, `chore`, `ci`, `test`, `ref`.
- Never mention Claude or any AI in a commit message or PR description. No `Co-Authored-By`, no "Generated with".
- Comments only say why, never what. Most files need none.
- Do not commit, push or open a PR unless asked. Work branches are `fix/...` or `feat/...` and PRs go into `dev`.
