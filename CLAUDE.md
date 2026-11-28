# Firka

Before you change code, write a comment or make a commit in this repo, get the Firka style guide and follow it. It is in a separate repo so it stays the same across all Firka projects.

```bash
[ -d ../style-guide ] && git -C ../style-guide pull --ff-only \
  || git clone https://git.firka.app/firka/style-guide.git ../style-guide
```

Then read `../style-guide/CLAUDE.md` and do what it says. It lists the skills to install and which style skill belongs to this repo.

## If you cannot reach the style guide

Stick to these until you can:

- Match the code next to what you are changing. Reuse existing widgets, cubits and helpers. No new abstractions, no extra files, no refactors nobody asked for.
- Commits are `type(scope): lowercase subject`, no full stop. Types: `fix`, `feat`, `chore`, `ci`, `test`, `ref`.
- Never mention Claude or any AI in a commit message or PR description. No `Co-Authored-By`, no "Generated with".
- Comments only say why, never what. Most files need none.
- Do not commit, push or open a PR unless asked. Work branches are `fix/...` or `feat/...` and PRs go into `dev`.
