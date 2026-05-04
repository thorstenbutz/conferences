# PowerShell Course Design — Prompt

## Mode
Plan mode → produce deliverables.

## Role
You are a PowerShell expert and IT instructor.

## Objective
Design a **4-day instructor-led course** on PowerShell for IT administrators.

## Audience & scope
- **Audience:** IT admins, PowerShell beginners
- **Primary tooling:** VSCode + PowerShell 7
- **Legacy context:** explain Windows PowerShell 5.1 and ISE briefly, but
  do not use them as the daily driver
- **Hands-on labs are the primary driver of the course** (~55% lab / 45% lecture)
- Content must align with current common practice
- **Cloud scope:** Azure cost-free services only — focus on Entra ID
- **On-prem scope:** Active Directory as the example server role
- **Functions:** keep short and simple — advanced functions are saved for a follow-on course
- **No agentic / AI-assisted content** — saved for a separate course

## Deliverables (all downloadable, prefer Markdown)
1. **Detailed 4-day schedule**
2. **Lab catalogue** — high-level descriptions, then full lab write-ups as
   `.md` files with `powershell` code fences. Optimize for **F8 usage in VSCode**.
   Labs should run correctly on first try; check existing AZ-040 examples for
   reference patterns.
3. **MARP slide decks** — one `.md` file per chapter
4. **Custom MARP theme** — minimal, modern, code-friendly, fork an existing theme.
   Use the canonical PowerShell **Noble Blue** as primary color: `rgb(1, 36, 86)` / `#012456`.
5. **Build chain** — `marp.config.js` + a PowerShell `build.ps1` that
   renders every deck to PPTX/PDF/HTML in one command
6. **Daily cheat sheets** — one condensed 2-page Markdown handout per day
7. **Domain-swap utility** — a parametric PowerShell script so the default
   `adatum.com` topology can be replaced with any classroom domain
8. **Student pre-flight check** — a `Test-LabEnvironment.ps1` that validates
   PS 7, VSCode + extension, RSAT, Graph SDK, and internet reachability

## Cloud module specifics
- Use **Microsoft.Graph PowerShell SDK exclusively**
- Do **not** use `AzureAD` or `MSOnline` modules (retired)
- Mention **Az** only for awareness — note that `Az.Resources` uses Graph
  internally for identity operations

## Imagery
- Include portraits of the PowerShell creators where natural:
  **Jeffrey Snover** (inventor) and **Bruce Payette** (language co-designer).
  If real photos cannot be bundled for licensing reasons, generate clearly-
  labelled neutral placeholders and document where instructors can drop in
  licensed copies.
- Include an original course mascot inspired by the retired Microsoft
  "PowerShell Hero" comic — generate it as an SVG, never reproduce the
  Microsoft original.

## Reference sources
- https://learn.microsoft.com/en-us/training/courses/az-040t00
- https://microsoftlearning.github.io/AZ-040T00-Automating-Administration-with-PowerShell/
- https://github.com/MicrosoftLearning/AZ-040T00-Automating-Administration-with-PowerShell/tree/master/Allfiles/Mod02/Democode

Use these as structural inspiration; the final course is your own design.

## Output requirements
- One coherent, well-structured deliverable package
- All artefacts in a downloadable archive
- Markdown preferred for prose; `.md` for slides (MARP); `.ps1` for scripts;
  `.css` for the theme
- Plan first; ask one round of clarifying questions before generating