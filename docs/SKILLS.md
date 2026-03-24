# CORET — Installed Skills

Skills are auto-detected by Claude Code from `.agents/skills/` and `.claude/skills/`.
After cloning, they work on any machine — no reinstall needed.

## Security
| Skill | Path | Usage |
|-------|------|-------|
| security-review | `.agents/skills/security-review/` | Sentry security audit — triggered on PR review or manual |
| owasp-security | `.claude/skills/owasp-security/` | OWASP top 10 vulnerability checks |

## UI/UX & Design
| Skill | Path | Usage |
|-------|------|-------|
| ui-ux-pro-max | `.agents/skills/ui-ux-pro-max/` | UI/UX best practices, auto-activates on view work |
| ckm-design | `.agents/skills/ckm-design/` | Design patterns |
| ckm-design-system | `.agents/skills/ckm-design-system/` | Design system enforcement |
| ckm-ui-styling | `.agents/skills/ckm-ui-styling/` | UI styling guidance |
| ckm-brand | `.agents/skills/ckm-brand/` | Brand consistency |
| ckm-banner-design | `.agents/skills/ckm-banner-design/` | Banner/hero design |
| ckm-slides | `.agents/skills/ckm-slides/` | Presentation slides |

## How to Use
Skills activate automatically when relevant. No need to reference them explicitly.

To run security review on any machine:
```bash
cd CORET
claude  # skills auto-detected
# Then: "run security review on backend"
```

To install new skills:
```bash
npx skills install <org/repo>@<skill-name> --yes
# or manually:
curl -sL <url> -o .claude/skills/<name>/SKILL.md --create-dirs
```

## Note for CORET
CORET's design system is **locked** (see DesignSystem.swift + moodboards).
Use UI/UX skills for iOS UX checklists and accessibility — not to override colors/typography.
