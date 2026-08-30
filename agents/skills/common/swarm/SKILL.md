---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use when explicitly invoked, for 'swarm this', or for parallel coverage, races, gauntlets, and exploration."
---

# Swarm

Fan out N parallel workers. They may cover separate slices, race the same brief, or mix both. The parent waits, aggregates, and returns one report.

## Start

Create a working checklist with one entry per phase before launching anything.
Use the host's plan or todo facility when available. Under Pi, use workflow
phases for a workflow or keep the checklist in chat.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Set N from the user or derive it from the shape. N is total workers, not the cloud concurrency limit.
4. Use the configured `swarm workers` role when the host exposes model selection. Otherwise let the host choose or inherit the parent model. For a model race, name each arm's model up front.
5. Give each worker its own writable output when it writes. Use a worktree, branch, or `/tmp/swarm-<slug>/worker-<n>/`.

## Phase B: Fan out

Spawn all N workers concurrently when supported, using the configured role. Choose local or remote execution from the task's actual data and tool needs. A worker that needs local files, credentials, application state, or hardware must stay local. A remote worker must receive an accessible branch or artifact instead of assuming access to the parent's workspace.

If the host has no subagents, run the briefs sequentially and preserve separate outputs. If a worker must start from a non-default branch, pass that branch through the host's supported mechanism.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

Keep a compact result table, one-line evidenced issues, and explicit gaps or dropouts.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.
