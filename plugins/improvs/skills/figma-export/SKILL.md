---
name: figma-export
description: Export Figma design to local JSON and SVG assets via REST API using a shared PAT.
---

# Figma Export

Exports a Figma frame to the project's `design/` folder so that other skills
(`figma-ui`, `figma-check`) can work from local files without hitting Figma API.

## Usage

```
/improvs:figma-export <FIGMA_URL>
```

`<FIGMA_URL>` is a Figma frame link, e.g.:
`https://www.figma.com/design/ABC123/FileName?node-id=12:34`

If no argument given, ask: "Paste the Figma frame URL to export:"

## Prerequisites

The environment variable `FIGMA_API_KEY` must be set with a Figma Personal
Access Token that has read access to the file. This is typically a designer's
PAT shared with the team. The token owner must have at least a Full or Dev seat
on a paid Figma plan (Professional or higher) for the file's workspace.

If `FIGMA_API_KEY` is not set, tell the developer:
```
FIGMA_API_KEY is not configured.
Ask your designer or lead for the shared Figma API key, then set it:

  export FIGMA_API_KEY=figd_xxxxx

Or add it permanently to your shell profile (~/.zshrc or ~/.bashrc).
```

## Step 1 — Parse the Figma URL

Extract `FILE_KEY` and `NODE_ID` from the URL.

URL formats to handle:
- `https://www.figma.com/design/FILE_KEY/Name?node-id=NODE_ID`
- `https://www.figma.com/file/FILE_KEY/Name?node-id=NODE_ID`
- `https://www.figma.com/design/FILE_KEY/Name?node-id=NODE_ID&...`

The `NODE_ID` in the URL uses `-` (e.g., `12-34`). The API uses `:` (e.g., `12:34`).
Convert `-` to `:` for API calls.

If the URL has no `node-id` parameter, export ALL screens from the file's
first page (usually "Design"). Fetch the file structure at depth=2:
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/files/$FILE_KEY?depth=2"
```
Find the first page, collect all top-level FRAME children as screens.
Skip non-screen frames: names starting with "Tools/", "Components", "label".

If `node-id` IS present, export only that single screen.

## Step 2 — Fetch the design data

**Single screen** (node-id present):
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_ID&geometry=paths"
```

**All screens** (no node-id): fetch screen nodes in batches of 15 IDs per request:
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$ID1,$ID2,...,$ID15"
```

If the response contains `"err"` or `"status": 403`, report:
- 403: "Access denied. The PAT owner may not have access to this file, or the token expired."
- 404: "File or node not found. Check the URL."
- 429: "Rate limited. Wait a minute and try again."

Parse the response. The node data is at `nodes["NODE_ID"].document`.
Process each screen through Steps 3-6 individually, merging tokens across all screens.

## Step 3 — Extract design tokens

From the node tree, collect unique values into a tokens structure:

**Colors:** Walk all `fills` and `strokes` arrays. Convert RGBA (0-1 floats) to hex:
```
hex = #RRGGBB where R = round(r * 255)
```
Group by usage: backgrounds, text colors, borders, accents.

**Typography:** Walk all TEXT nodes. Collect unique combinations of:
- fontFamily, fontSize, fontWeight, letterSpacing, lineHeightPx
- Name them by Figma node name or generate: `heading1`, `body`, `caption`, etc.

**Spacing:** Walk all frames with `layoutMode != "NONE"`. Collect unique values of:
- paddingTop, paddingRight, paddingBottom, paddingLeft, itemSpacing
- Sort and deduplicate.

**Border radii:** Collect unique `cornerRadius` values.

Also fetch the file's published styles for richer token data:
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/files/$FILE_KEY/styles"
```

## Step 4 — Export icons as SVG

Find nodes that are icons:
- Nodes of type VECTOR, BOOLEAN_OPERATION, or LINE
- Nodes whose name contains `icon` (case-insensitive)
- Nodes of type INSTANCE whose component name suggests an icon

Collect their node IDs and request SVG export in batches of up to 50:
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=$IDS&format=svg"
```

Download each SVG to `design/assets/`:
```bash
curl -s -o "design/assets/$ICON_NAME.svg" "$SVG_URL"
```

### Export image fills (photos, avatars, backgrounds)

After building screen JSONs, scan all screen JSONs for `"type": "IMAGE"` fills.
Collect unique `imageRef` hashes across all screens (deduplicate).

Fetch the image fill URLs:
```bash
curl -s -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/files/$FILE_KEY/images"
```

This returns `meta.images` -- a map of `imageRef` hash to download URL.
Download only the refs that appear in screen JSONs:
```bash
curl -s -o "design/assets/images/$NAME.png" "$IMAGE_URL"
```

Save to `design/assets/images/`. Deduplicate by imageRef -- don't download
the same image twice.

#### Image naming rules (critical)

Generic Figma names like `image`, `image-13`, `Rectangle`, `Frame` are useless
for developers. Use smart naming with this priority:

1. **Semantic node name** -- if the node has a descriptive name (not generic),
   use it: `hero-banner`, `user-avatar`, `product-photo`.
2. **Parent node name** -- if the image node name is generic, walk up to the
   nearest parent with a semantic name and use `{parent}-image`:
   `onboarding-step1-image`, `profile-header-image`.
3. **Screen + position** -- if both node and parent names are generic, use
   the screen name + position index (top-to-bottom order within the screen):
   `onboarding-image-1`, `onboarding-image-2`, `onboarding-image-3`.

Generic names to reject (case-insensitive): `image`, `image-*`, `rectangle`,
`frame`, `group`, `vector`, `fill`, `mask`, `bitmap`, any name that is purely
numeric or matches `^(image|img|pic|photo|rect|frame|group)[-_]?\d*$`.

Also record the **purpose annotation** in the screen JSON for each image node.
Add a `"imageContext"` field with: the parent node name, sibling text nodes
(if any), and the image's position in the screen (e.g., "top", "center",
"bottom"). This helps the developer understand which image goes where:

```json
{
  "type": "IMAGE",
  "name": "onboarding-step1-image",
  "asset": "assets/images/onboarding-step1-image.png",
  "imageContext": {
    "parent": "OnboardingStep1",
    "nearbyText": ["Welcome to the app", "Get started"],
    "position": "center"
  }
}
```

Sanitize all filenames: lowercase, replace spaces with `-`, remove special chars.

## Step 5 — Build the screen JSON

Create a simplified, Claude-friendly JSON structure from the raw Figma data.
Strip unnecessary fields (like `id`, `absoluteBoundingBox`, `constraints` for
absolute positioning). Keep only what matters for code generation:

```json
{
  "exportedFrom": "https://www.figma.com/design/...",
  "exportedAt": "2026-04-09T20:00:00Z",
  "screenName": "LoginScreen",
  "node": {
    "type": "FRAME",
    "name": "LoginScreen",
    "layoutMode": "VERTICAL",
    "primaryAxisAlignItems": "CENTER",
    "counterAxisAlignItems": "CENTER",
    "padding": { "top": 24, "right": 16, "bottom": 24, "left": 16 },
    "itemSpacing": 16,
    "size": { "width": 375, "height": 812 },
    "fills": [{ "type": "SOLID", "hex": "#FFFFFF", "opacity": 1 }],
    "cornerRadius": 0,
    "children": [
      {
        "type": "TEXT",
        "name": "Title",
        "characters": "Welcome Back",
        "typography": {
          "fontFamily": "Inter",
          "fontSize": 32,
          "fontWeight": 700,
          "lineHeight": 40,
          "letterSpacing": -0.5
        },
        "fills": [{ "type": "SOLID", "hex": "#1A1A2E" }]
      },
      {
        "type": "FRAME",
        "name": "EmailField",
        "layoutMode": "HORIZONTAL",
        "...": "..."
      }
    ]
  }
}
```

Transformation rules:
- Convert `color.r/g/b/a` (0-1 floats) to `hex` + `opacity`
- Convert `absoluteBoundingBox` to `size: { width, height }`
- Flatten `paddingTop/Right/Bottom/Left` into `padding: { top, right, bottom, left }`
- Keep `layoutMode`, `primaryAxisAlignItems`, `counterAxisAlignItems`, `itemSpacing`
- Keep `cornerRadius`, `strokes`, `effects` (shadows)
- For TEXT: extract `characters` and flatten style into `typography` object
- For images: replace with `{ "type": "IMAGE", "name": "...", "asset": "assets/name.svg", "imageContext": {...} }`
- Recursively process `children`
- Preserve the node `name` — it drives widget/class naming
- For TEXT nodes: include `textAlignHorizontal` and `textAlignVertical` from Figma
- For all FRAME nodes: always include `primaryAxisAlignItems` and `counterAxisAlignItems` — these drive Flutter alignment (CENTER, MIN, MAX, SPACE_BETWEEN)

## Step 6 — Save to design/ folder

Create the folder structure:
```
design/
  tokens.json          -- design tokens (colors, typography, spacing, radii)
  screens/
    login_screen.json   -- screen structure (one file per exported frame)
  assets/
    icon-email.svg      -- exported SVG icons
    icon-lock.svg
    images/
      hero-image.png   -- photos, avatars, backgrounds from Figma
      avatar.png
```

The screen filename is derived from the Figma frame name:
- PascalCase → snake_case (e.g., `LoginScreen` → `login_screen`)
- Strip spaces and special characters

If `design/tokens.json` already exists, merge new tokens into it
(add new values, don't remove existing ones). This allows incremental
export across multiple screens.

If the screen JSON already exists, overwrite it (it's a re-export).

## Step 7 — Summary

Print a summary:

```
FIGMA EXPORT COMPLETE
━━━━━━━━━━━━━━━━━━━━
Source: $FIGMA_URL

Files created:
  design/screens/    N screen JSON files
  design/tokens.json (N colors, M text styles, K spacing values)
  design/assets/     N SVG icons exported

API calls used: N (daily budget: ~200/day shared)

Next steps:
  /improvs:figma-ui design/screens/<screen>.json   -- build Flutter from export
  /improvs:figma-check design/screens/<screen>.json -- verify implementation
```

## Rules

- NEVER hardcode a Figma PAT in the skill output, code, or files. Always read from `$FIGMA_API_KEY` env var.
- NEVER export the raw Figma API response as-is. Always transform to the simplified Claude-friendly format. Raw responses are 10-50x larger and waste context.
- When exporting all screens (no node-id), use a single Python script that batches all API calls efficiently. A full file export of ~70 screens should use ~10-12 API calls total.
- If `design/` folder doesn't exist, create it. Also create `.gitkeep` files if needed.
- If curl fails with a network error, suggest the developer check their internet connection and token validity.
- Keep SVG filenames consistent: lowercase, hyphens, no spaces. E.g., `icon-arrow-left.svg`.
- After export, do NOT automatically commit. The developer decides when to commit the design files.
- Minimize API calls. Batch node IDs in image export requests (up to 50 per call). A typical screen export should use 2-4 API calls total (1 node fetch, 1 styles fetch, 1-2 image exports).
