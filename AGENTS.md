# AGENTS.md

This document defines the conventions and expectations for anyone (human) contributing code to this repository.

---

# Project Overview

This repository contains practical PowerShell utilities intended primarily for Windows system administration, maintenance, cleanup, troubleshooting, and automation.

The emphasis is on:

* Reliability
* Readability
* Safety
* Maintainability

Performance matters, but clarity is preferred over unnecessary optimization.

---

# Target Environment

Unless otherwise specified:

* PowerShell 7+
* Windows 10
* Windows 11

Do not intentionally introduce Windows PowerShell 5.1 compatibility requirements unless a script explicitly targets it.

---

# General Coding Style

Follow standard PowerShell conventions.

## Naming

Use approved PowerShell verbs.

Examples:

* `Get-SystemInfo`
* `Remove-VisualStudio`
* `Set-RegistryValue`
* `Start-ServiceRepair`

Avoid names such as:

* `DeleteStuff`
* `FixEverything`
* `CleanupScript`

---

## Functions

Prefer small, focused functions.

A function should ideally perform one well-defined task.

---

## Variables

Use descriptive names.

Prefer:

```powershell
$InstalledPackages
$RegistryKey
$ServiceName
```

Avoid:

```powershell
$a
$tmp
$x
```

---

## Aliases

Do not use aliases.

Avoid:

* `ls`
* `cp`
* `mv`
* `%`
* `?`
* `cat`

Always use the full cmdlet names.

---

## Output

Use:

* `Write-Verbose`
* `Write-Warning`
* `Write-Error`

Reserve `Write-Host` for user-facing progress or status messages.

---

## Error Handling

Handle expected failures gracefully.

Prefer:

* `try/catch`
* `-ErrorAction Stop` where appropriate

Do not silently ignore important failures.

---

## Safety

Safety is a priority.

Destructive scripts should:

* Explain their purpose.
* Warn users before irreversible actions.
* Support `-WhatIf` whenever practical.
* Validate paths before deleting data.
* Avoid deleting files outside their intended scope.

---

## Dependencies

Prefer built-in PowerShell functionality.

Avoid introducing external dependencies unless they provide a substantial benefit that cannot reasonably be achieved otherwise.

---

## Documentation

Public scripts should include:

* Purpose
* Requirements
* Administrator requirements (if applicable)
* Usage examples when helpful

Complex logic should include concise comments explaining *why*, not merely *what*.

---

## Repository Philosophy

Every script should strive to be:

* Easy to read
* Easy to modify
* Easy to debug
* Safe to execute
* Useful in real-world scenarios

If there are multiple valid implementations, prefer the one that is easier for someone else to understand six months from now.

Consistency across the repository is more valuable than cleverness in any individual script.
