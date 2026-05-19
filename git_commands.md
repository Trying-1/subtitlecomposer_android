# 🛠️ Git Commands Cheat Sheet

A comprehensive, categorized guide to the most essential and advanced Git commands for developers.

---

## 📌 Table of Contents
1. [Configuration & Setup](#1-configuration--setup)
2. [Starting a Repository](#2-starting-a-repository)
3. [Making & Tracking Changes](#3-making--tracking-changes)
4. [Branching & Merging](#4-branching--merging)
5. [Working with Remotes](#5-working-with-remotes)
6. [Undoing & Resetting Changes](#6-undoing--resetting-changes)
7. [Inspecting & Debugging](#7-inspecting--debugging)
8. [Stashing Temporary Changes](#8-stashing-temporary-changes)
9. [Advanced & Pro Tips](#9-advanced--pro-tips)

---

## 1. Configuration & Setup

Configure your identity, default settings, and global behaviors.

| Command | Description |
| :--- | :--- |
| `git config --global user.name "Your Name"` | Set your global username. |
| `git config --global user.email "email@example.com"` | Set your global email. |
| `git config --global core.editor "code --wait"` | Set VS Code (or any editor) as the default editor. |
| `git config --global init.defaultBranch main` | Set `main` as the default branch name for new repos. |
| `git config --list` | List all active Git configurations. |

---

## 2. Starting a Repository

Initialize new local projects or import existing ones.

| Command | Description |
| :--- | :--- |
| `git init` | Initialize a new, empty local Git repository. |
| `git clone <repo-url>` | Clone an existing remote repository to your machine. |
| `git clone --depth 1 <repo-url>` | Shallow clone (fetches only the latest commit to save bandwidth/space). |

---

## 3. Making & Tracking Changes

Manage your working directory, staging area, and commit history.

| Command | Description |
| :--- | :--- |
| `git status` | Show the status of files (untracked, modified, staged). |
| `git add <file>` | Stage a specific file for the next commit. |
| `git add .` or `git add -A` | Stage **all** changes (new, modified, and deleted files). |
| `git diff` | Show changes in unstaged files compared to the last commit. |
| `git diff --staged` | Show staged changes ready for commit. |
| `git commit -m "Commit message"` | Record staged changes with a descriptive message. |
| `git commit -am "Commit message"` | Stage all modified tracked files and commit in one step. |
| `git commit --amend` | Modify the last commit (allows changing message or adding missed files). |

---

## 4. Branching & Merging

Isolate and organize parallel lines of development.

| Command | Description |
| :--- | :--- |
| `git branch` | List all local branches. |
| `git branch -r` | List all remote branches. |
| `git branch -a` | List all branches (both local and remote). |
| `git branch --show` or `git branch --show-current` | Show only the name of the current active branch. |
| `git branch <branch-name>` | Create a new local branch. |
| `git switch <branch-name>` | Switch to an existing branch (modern alternative to `checkout`). |
| `git switch -c <branch-name>` | Create a new branch and switch to it immediately. |
| `git merge <branch-name>` | Merge the specified branch into your current active branch. |
| `git branch -d <branch-name>` | Delete a local branch (only if it has been fully merged). |
| `git branch -D <branch-name>` | Force delete a local branch (even if unmerged). |

---

## 5. Working with Remotes

Synchronize your local repository with a remote hosting service (GitHub, GitLab, etc.).

| Command | Description |
| :--- | :--- |
| `git remote -v` | List all configured remote repositories and their URLs. |
| `git remote add origin <repo-url>` | Link a local repository to a remote URL. |
| `git fetch origin` | Download updates and new branches from the remote without merging them. |
| `git pull origin <branch>` | Fetch updates from the remote and merge them into your current branch. |
| `git push origin <branch>` | Upload your local commits to the remote repository. |
| `git push -u origin <branch>` | Push and set the upstream tracking branch (so you can just use `git push` next time). |
| `git remote prune origin` | Clean up stale tracking branches for remotes that no longer exist on the server. |

---

## 6. Undoing & Resetting Changes

Safely recover from mistakes, discard edits, or revert history.

> [!WARNING]
> Be extremely cautious with commands using `--hard`, as they discard work permanently.

| Command | Description |
| :--- | :--- |
| `git restore <file>` | Discard unstaged changes in your working directory. |
| `git restore --staged <file>` | Unstage a file, keeping its modifications in your working directory. |
| `git reset --soft HEAD~1` | Undo the last commit, keeping your changes staged. |
| `git reset HEAD~1` | Undo the last commit, unstaging the changes but keeping files modified. |
| `git reset --hard HEAD~1` | Completely obliterate the last commit and all changes (destructive). |
| `git revert <commit-hash>` | Create a new commit that safely rolls back/undoes the changes of a previous commit. |

---

## 7. Inspecting & Debugging

Explore your commit history, blame contributors, or find bugs.

| Command | Description |
| :--- | :--- |
| `git log` | Show the commit history. |
| `git log --oneline` | Show a highly condensed, single-line version of commit history. |
| `git log --graph --oneline --all` | Draw a text-based visual branch representation tree of history. |
| `git show <commit-hash>` | View detailed modifications made in a specific commit. |
| `git blame <file>` | Show line-by-line who modified what and when in a file. |
| `git reflog` | Record of every single action/checkout in your local repository (great for saving "lost" commits). |

---

## 8. Stashing Temporary Changes

Quickly save your dirty working directory state so you can work on something else.

| Command | Description |
| :--- | :--- |
| `git stash` | Save current modified, tracked files into a temporary holding area. |
| `git stash -u` | Stash both tracked **and** untracked files. |
| `git stash list` | View all stashed collections. |
| `git stash pop` | Apply the latest stashed modifications and remove them from the stash stack. |
| `git stash apply` | Apply the latest stash but keep it in the stash stack. |
| `git stash drop` | Discard the latest stashed change without applying it. |
| `git stash clear` | Obliterate all stashed changes. |

---

## 9. Advanced & Pro Tips

Optimize your workflow with higher-tier commands.

| Command | Description |
| :--- | :--- |
| `git cherry-pick <commit-hash>` | Grab a specific commit from another branch and apply it to your current branch. |
| `git rebase -i HEAD~<n>` | Open interactive rebase for the last `n` commits (allows squashing, editing, and deleting history). |
| `git clean -fd` | Forcefully remove all untracked files and directories in your repository. |
| `git shortlog -sn` | Display a summary list of contributors and their total commit counts. |
| `git config --global alias.<shortcut> "<command>"` | Create custom shortcuts (e.g., `git config --global alias.co checkout` lets you run `git co`). |
