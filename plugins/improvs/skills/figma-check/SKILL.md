---
name: Figma Check
description: Verify implemented UI matches Figma design. Compares spacing, colors, typography, layout against design tokens with smart tolerance.
---

# Figma Check

Figma node URL is provided as $ARGUMENTS. If no argument given, check if
a Figma URL was saved during `/start` in the current session. If not found,
ask: "Figma node URL for the screen to verify:"

## Step 1 — Read the design

Via Figma MCP, read the Figma node. Extract:
- Layout structure (flex direction, alignment, wrapping)
- Spacing values (padding, margin, gaps — all values in px)
- Colors (hex values, opacity)
- Typography (font family, size, weight, line height, letter spacing)
- Border radius, borders, shadows
- Component variants and states
- Icon sizes
- Image aspect ratios

## Step 2 — Read the design tokens

Look for the project's design tokens or theme file. Check in order:

**Flutter:**
- `lib/core/theme/` or `lib/core/theme.dart`
- Look for: ColorScheme, TextTheme, spacing constants, border radius values

**React/Next.js:**
- `tailwind.config.js` or `tailwind.config.ts` (Tailwind tokens)
- `src/theme/` or `styles/tokens/` (custom tokens)
- CSS variables in global stylesheet

**.NET (Blazor/Razor):**
- CSS variables or SCSS tokens
- `wwwroot/css/` theme files

If design tokens exist, build a token map:
```
Spacing: [4, 8, 12, 16, 20, 24, 32, 40, 48, 64]
Colors: { primary: #xxx, secondary: #xxx, ... }
Font sizes: [12, 14, 16, 18, 20, 24, 28, 32]
Radii: [4, 8, 12, 16, 9999]
```

If no design tokens found, note it and compare against raw Figma values.

## Step 3 — Read the implementation

Find the screen/component files that correspond to the Figma design.
Use the Figma node name to locate the matching file(s).

Read the implementation code and extract the same properties:
- Layout (Row/Column/Flex, alignment, wrapping)
- Spacing values used (padding, margin, gap)
- Colors referenced (hex, theme tokens, CSS variables)
- Typography (font, size, weight)
- Border radius, borders, shadows

## Step 4 — Compare with smart matching

For each property, compare Figma value vs implementation value.

**Snap to nearest token:** If design tokens exist, snap both Figma and
implementation values to the nearest token before comparing.

Example:
- Figma says 19px, nearest spacing token is 20px → treat as 20px
- Implementation uses 20px → MATCH (no flag)
- Implementation uses 16px → MISMATCH (flag it)

**Tolerance rules:**
- Spacing: ignore differences of 2px or less (Figma rounding, auto-layout math)
- Colors: ignore differences of <=2 in any RGB channel (rendering differences)
- Font size: must be exact match (or exact token match)
- Font weight: must be exact match
- Border radius: ignore differences of 1px or less
- Layout direction/alignment: must be exact match

**Token preference:** If the implementation uses a design token name
(e.g., `Theme.spacing.md` or `gap-4`) that maps to the correct value,
always prefer that over a hardcoded pixel value, even if the pixel value
is technically correct.

## Step 5 — Report results

Group findings into three categories:

### Matches (no action needed)
Properties that match the design within tolerance.
Show these briefly to confirm coverage.

### Mismatches (fix required)
Properties where implementation differs from design beyond tolerance.
Show each with:
- What: which property on which element
- Figma: the design value (snapped to token if applicable)
- Implementation: the current code value
- Suggestion: the correct token or value to use

### Designer inconsistencies (inform designer)
Values in Figma that don't match any design token.
These are likely designer mistakes, not implementation issues.
- Flag them so the developer can ask the designer to confirm
- Suggest the nearest token as the likely intended value

```
FIGMA CHECK
━━━━━━━━━━━
Screen: $SCREEN_NAME
Design: $FIGMA_URL

Matches: N properties correct
Mismatches: N to fix
Designer inconsistencies: N to confirm

MISMATCHES:
  1. LoginButton padding
     Figma: 16px vertical, 24px horizontal
     Code:  12px vertical, 24px horizontal
     Fix:   Change vertical padding to 16px (Theme.spacing.md)

  2. HeaderTitle color
     Figma: #1A1A2E
     Code:  #333333
     Fix:   Use Theme.colors.textPrimary (#1A1A2E)

DESIGNER INCONSISTENCIES:
  SubtitleText font-size: 15px — not a token value
    Nearest token: 14px (sm) or 16px (md)
    → Ask designer which they intended

All clear? Fix mismatches and commit.
```

## Rules

- NEVER silently change implementation to match Figma without showing the developer.
- NEVER flag differences within tolerance — these are noise.
- NEVER assume the designer is always right. Flag suspicious values
  that don't match tokens as potential designer mistakes.
- If no design tokens exist in the project, suggest creating them.
  A theme/token file prevents inconsistencies across the entire app.
- Compare layout STRUCTURE (flex direction, alignment), not just values.
  A wrong layout direction is worse than 2px spacing difference.
- If the Figma design has multiple states (hover, pressed, disabled),
  check that the implementation handles all states.
