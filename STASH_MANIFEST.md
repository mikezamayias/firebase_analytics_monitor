# famon stash archive — 2026-07-10

Stashes exported before workspace cleanup. Reapply: `git apply --3way <file>.patch` on the base commit (or current branch, resolving conflicts).

## stash@{0} — stash-0-On-main-Tower-Auto-Stash-2026-04-02-08-1.patch
- message: On main: Tower Auto-Stash: 2026-04-02 08:19:56 +0300
- created: 2026-04-02 08:19:56 +0300
- base: a273777 style: format issue_command and monitor_command
- patch lines: 270
```
 .gitignore                                         |  1 +
 lib/src/cli/commands/filtered_monitor_command.dart | 34 +++++++++++++---
 lib/src/command_runner.dart                        | 15 ++++---
 lib/src/commands/monitor_command.dart              | 47 +++++++++++++++++-----
 lib/src/utils/event_filter_utils.dart              | 37 +++++++++++++++++
 5 files changed, 114 insertions(+), 20 deletions(-)
```

