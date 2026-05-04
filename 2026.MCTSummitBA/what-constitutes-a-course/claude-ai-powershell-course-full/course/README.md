# PowerShell 7 for IT Administrators — Hands-On Fundamentals

A 4-day instructor-led course. **Noble Blue** MARP theme, lab-driven, VSCode + PowerShell 7 first, with a light historical thread explaining Windows PowerShell 5.1 and ISE.

---

## Package contents

```
course/
├── README.md                  ← this file
├── build.ps1                  ← one-command deck renderer (PPTX / PDF / HTML)
├── marp.config.js             ← MARP defaults (theme, local-file access)
├── package.json               ← npm deps for marp-cli
├── Invoke-DomainSwap.ps1      ← swap adatum.com for your classroom domain
├── Test-LabEnvironment.ps1    ← student pre-flight check
├── themes/
│   └── noble-blue.css         ← custom MARP theme, PS Noble Blue (#012456)
├── decks/                     ← one MARP file per chapter
│   ├── day1-foundations.md
│   ├── day2-pipeline-providers.md
│   ├── day3-scripting-remoting.md
│   └── day4-ad-entraid.md
├── cheatsheets/               ← condensed 2-page instructor handouts
│   ├── day1-cheatsheet.md
│   ├── day2-cheatsheet.md
│   ├── day3-cheatsheet.md
│   └── day4-cheatsheet.md
├── labs/                      ← F8-first, every line runnable
│   ├── lab01-environment-setup.md
│   ├── lab02-discovery-help.md
│   ├── lab03-pipeline.md
│   ├── lab04-providers-cim.md
│   ├── lab05-scripting.md
│   ├── lab06-functions-remoting.md
│   ├── lab07-ad-bulk.md
│   └── lab08-capstone.md
└── images/
    ├── README.md              ← how to swap in licensed portraits
    ├── powershell-hero.svg    ← original mascot, CC0
    ├── monad-timeline.svg     ← 2002→today history visual
    ├── snover.jpg             ← placeholder — replace with licensed photo
    └── payette.jpg            ← placeholder — replace with licensed photo
```

---

## Quick start

### 1. Render the decks
```powershell
# one-time setup (per machine)
npm install

# render everything
.\build.ps1

# or just one format / one deck
.\build.ps1 -Format pptx -Deck day1
.\build.ps1 -Watch                 # live reload while editing
```

### 2. Adapt the domain (if not using adatum.com)
```powershell
.\Invoke-DomainSwap.ps1 -NewDnsDomain 'contoso.com'          # dry-run
.\Invoke-DomainSwap.ps1 -NewDnsDomain 'contoso.com' -Apply   # rewrite files
```
A timestamped `.backup-YYYYMMDD-HHMMSS` folder is created before any write.

### 3. Students — pre-flight check
Before Day 1, students run:
```powershell
.\Test-LabEnvironment.ps1
.\Test-LabEnvironment.ps1 -Fix     # try to auto-install missing pieces
```
Exit code 0 = ready, 1 = blocking issues.

---

## Build prerequisites

- Node.js ≥ 18
- `npm install` once in this folder (pulls `@marp-team/marp-cli` into `node_modules/.bin`)
- Chromium/Chrome automatically discovered by MARP — if your machine is offline, set `CHROME_PATH` to a local install

---

## Lab philosophy: F8-first

Every lab is a plain Markdown file with PowerShell fenced as `powershell`. In VSCode
with the **PowerShell** extension installed, the workflow is:

1. Open the lab `.md` next to an editor tab with a blank `.ps1` scratch file
2. Select any line or block inside a `powershell` fence and press **F8**
3. Each fenced block is self-contained — no hidden setup from previous blocks

Validated against **PowerShell 7.4+** on Windows 11 and Windows Server 2022.

---

## Lab environment

| Role   | Hostname  | OS                    | Roles / tooling                                     |
|--------|-----------|-----------------------|------------------------------------------------------|
| DC     | `LON-DC1` | Windows Server 2022   | AD DS, DNS, RSAT ActiveDirectory module              |
| Client | `LON-CL1` | Windows 11            | PowerShell 7.4+, VSCode + PowerShell extension, Git  |
| Cloud  | —         | Microsoft Entra ID    | Free tenant, one app registration, Graph PowerShell |

Default domain: `adatum.com` — Administrator: `Adatum\Administrator` / `Pa55w.rd`
(matches the AZ-040 topology so existing VM images can be reused; change with `Invoke-DomainSwap.ps1`).

**EntraID note:** all cloud exercises use the `Microsoft.Graph` module.
Legacy `AzureAD` and `MSOnline` are **not** installed. Where `Az` is mentioned,
it is only for context — `Az.Resources` uses Graph internally for identity.

---

## 4-day schedule summary

| Day | Theme                                   | Labs            | Cheat sheet                |
|-----|-----------------------------------------|-----------------|----------------------------|
| 1   | Foundations: shell, editor, objects     | Lab 1, Lab 2    | day1-cheatsheet.md         |
| 2   | Pipeline, providers, CIM/WMI            | Lab 3, Lab 4    | day2-cheatsheet.md         |
| 3   | Variables, scripting, remoting, jobs    | Lab 5, Lab 6    | day3-cheatsheet.md         |
| 4   | AD on-prem, EntraID via Graph, capstone | Lab 7, Lab 8    | day4-cheatsheet.md         |

Each day runs 09:00–16:30 with two coffee breaks and one lunch. Target mix: **~55 % hands-on / 45 % lecture + demo**.

---

## Out of scope (saved for follow-on courses)

- Advanced function authoring, parameter sets, `ShouldProcess`, dynamic parameters
- Module authoring, Pester, PSScriptAnalyzer, CI/CD pipelines
- DSC and configuration management
- AI-assisted / agentic PowerShell authoring

---

## Credits

- **Jeffrey Snover** — inventor of PowerShell, author of the *Monad Manifesto* (2002)
- **Bruce Payette** — co-designer of the language, author of *Windows PowerShell in Action*
- Microsoft Learn **AZ-040T00** — structural reference and lab-topology inspiration

Noble Blue (`rgb(1, 36, 86)` / `#012456`) is the classic PowerShell console background.
