# Week 3 Day 5: Git (undoing, reflog, stash, cherry-pick)

Topics 1 to 4 and 9 (model, branching, remotes, merge vs rebase, housekeeping) were skipped: the user already knows them. Topics 5 to 8 were taught below. The check questions at the end are still unanswered.

## Essentials
- Work lives in three places: **working tree** (files), **staging area** (what `git add` collected), **commits**. Each undo command works at a different level.
- `reset` rewrites history (don't use it on pushed commits). `revert` adds a new undo commit (safe on shared branches).
- `reset --hard` and `restore` destroy uncommitted work for good. Committed work can be recovered with the `reflog`.
- `commit --amend`, `reset` and `rebase` all rewrite commits: only before you push.

## 5. Undoing things

### `git restore` (uncommitted changes)

| Command | Effect |
|---|---|
| `git restore file` | discard edits in the working tree (no undo) |
| `git restore --staged file` | unstage a file, keep the edits |

### `git reset` (move the branch pointer back)

| Mode | Branch moves | Staging area | Working tree |
|---|---|---|---|
| `--soft` | yes | **kept** (still staged) | kept |
| `--mixed` (default) | yes | cleared | **kept** (unstaged) |
| `--hard` | yes | cleared | **discarded** |

- `git reset --soft HEAD~1` undoes the last commit and leaves everything ready to commit again (redo a message, squash).
- `--hard` is the dangerous one: it deletes uncommitted work.

### `git revert <commit>`
Adds a **new commit that does the opposite** of an old one. History stays intact.

| | `reset` | `revert` |
|---|---|---|
| History | rewritten (commits disappear) | kept (new undo commit added) |
| Use on pushed or shared commits | no | yes |

### `git commit --amend`
Replaces the last commit: fix the message, or add a forgotten file (`git add file && git commit --amend`). It creates a new hash, so it is a rewrite: do it before pushing.

## 6. `reflog`
Git records every move of `HEAD` (commits, resets, checkouts, rebases) in the reflog, a local history of where you have been. A commit "lost" by `reset --hard` still exists for about 90 days.

```bash
git reflog                       # abc1234 HEAD@{2}: commit: add feature
git reset --hard abc1234         # jump back to that state
git branch rescue abc1234        # or keep it safely on a new branch
```
Limits: local only (not pushed), and only **committed** work can be recovered. Uncommitted changes wiped by `reset --hard` are gone.

## 7. `stash`
Parks uncommitted changes so you get a clean working tree (for example to switch branches mid-task).

| Command | Meaning |
|---|---|
| `git stash` | shelve tracked changes |
| `git stash -u` | include untracked files too |
| `git stash list` | show the shelf |
| `git stash pop` | restore the latest stash and remove it from the shelf |
| `git stash apply` | restore it but keep it on the shelf |
| `git stash drop` | delete one |

## 8. `cherry-pick`
Copies **one commit** onto the current branch as a new commit (new hash, same change).

```bash
git switch main
git cherry-pick abc1234
```
Uses: a bugfix made on a feature branch that `main` needs now (hotfix), or taking one commit from a branch you do not want to merge fully. On conflict, resolve it like a merge conflict, then `git cherry-pick --continue`.

## Check questions (unanswered)
1. You committed, then realise the commit was wrong and you have not pushed. Which `reset` mode keeps your changes staged? Which one deletes them?
2. A bad commit is already on `main` and others pulled it. `reset` or `revert`, and why?
3. You ran `git reset --hard HEAD~3` by mistake. Can you get the commits back, and how?
4. You are halfway through editing and must fix a bug on another branch. What do you do?
