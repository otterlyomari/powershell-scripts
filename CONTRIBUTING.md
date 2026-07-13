# Contributing

First of all, thank you for taking the time to contribute.

This repository exists as a collection of practical PowerShell utilities for Windows. Whether you're fixing a bug, improving a script, or adding a new utility, your contributions are appreciated.

---

## Before You Begin

Please take a moment to:

* Search existing issues before opening a new one.
* Keep pull requests focused on a single change whenever possible.
* Test your changes before submitting them.

---

## Repository Goals

The primary goals of this project are:

* Practical automation
* Readable code
* Safe execution
* Minimal dependencies
* Long-term maintainability

Not every script needs to be feature-rich. Simplicity is preferred whenever it accomplishes the same task.

---

## Coding Standards

Scripts should:

* Target **PowerShell 7** unless otherwise noted.
* Use approved PowerShell verbs (`Get`, `Set`, `Remove`, `New`, `Start`, etc.).
* Follow standard `Verb-Noun` naming conventions.
* Avoid aliases (`ls`, `cp`, `%`, `?`, etc.).
* Use descriptive variable names.
* Include comments where logic may not be immediately obvious.
* Prefer built-in PowerShell functionality over external executables whenever practical.

---

## Safety

Some scripts perform destructive operations.

When writing or modifying these scripts:

* Clearly document what the script removes or changes.
* Include confirmation prompts where appropriate.
* Support `-WhatIf` for destructive operations whenever practical.
* Never intentionally hide potentially destructive behavior.

Users should always understand what a script is going to do before they execute it.

---

## Folder Organization

Place new scripts into the most appropriate category.

For example:

* `Windows/`
* `Development/`
* `Networking/`
* `Utilities/`

If a script doesn't clearly fit an existing category, open an issue before creating a new one.

---

## Pull Requests

A good pull request should:

* Have a clear title.
* Explain *why* the change is being made.
* Keep unrelated changes separate.
* Preserve existing formatting and style.

---

## Reporting Issues

If you discover a bug, please include:

* Windows version
* PowerShell version
* Steps to reproduce
* Expected behavior
* Actual behavior
* Any relevant error output

---

## Final Note

The goal of this repository isn't to create the biggest collection of PowerShell scripts—it is to create a collection of scripts that are reliable, understandable, and genuinely useful.

Thank you for helping improve it.
