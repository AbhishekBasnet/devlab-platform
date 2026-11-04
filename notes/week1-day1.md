# Week 1, Day 1: Filesystem, navigation, file ops, vim, apt

> Skeleton only. Do each task yourself from memory and `man`/docs, then write the answers in your own words.
> Use `command ls` on Fedora (ls is aliased to eza). Run everything on devlab inside `tmux`.

## Goal
Move around an Ubuntu server and manage files and packages without Googling the basics.

## Tasks
- [ ] Walk `/`: for `/etc`, `/var/log`, `/var/lib`, `/home`, `/opt`, `/usr/bin`, `/tmp`, `/proc`, `/sys`, write one line on what lives there
- [ ] Navigation and file ops: `pwd`, `cd -`, `ls -lah`, `cp -r`, `mv`, `rm`, `mkdir -p`, `touch`, `stat`, `file`, `tree`
- [ ] Find things: `find / -name ... 2>/dev/null`, `locate`, `which`, `type`
- [ ] Read files: `cat`, `less`, `head`, `tail -f`, `wc`
- [ ] Edit with `nano`, then with `vim`: open, insert, save, quit, search, delete line, undo (`i Esc :wq :q! /text dd u`)
- [ ] `apt`: `update` vs `upgrade`, `search`, `show`, `install`, `remove` vs `purge`, `autoremove`, `apt-cache policy`, `dpkg -l`, `dpkg -L`
- [ ] Hard link vs soft link: create both with `ln` / `ln -s`, compare with `ls -li`, delete the target and see what breaks

## Notes (your words)
### Filesystem hierarchy

### update vs upgrade

### Hard link vs soft link

## Questions I got wrong / want to revisit

## Done when
I can navigate, create/move/delete files, edit with vim, and install/remove packages with apt without notes.
