#!/usr/bin/env bash
#
# Build ZIP archives for claude.ai web upload from the plugin skills.
# Output goes to dist/ (gitignored).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/plugins/improvs/skills"
DIST_DIR="$SCRIPT_DIR/dist"

# Clean and recreate dist directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

count=0

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"

  # Skip if no SKILL.md
  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    echo "SKIP: $skill_name (no SKILL.md)"
    continue
  fi

  # Create temp dir, copy with Skill.md name (claude.ai web expects Skill.md)
  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/$skill_name"
  cp "$skill_dir/SKILL.md" "$tmp_dir/$skill_name/Skill.md"

  # Copy any supporting files (templates, scripts, etc.)
  for item in "$skill_dir"/*; do
    base="$(basename "$item")"
    if [[ "$base" != "SKILL.md" ]]; then
      cp -r "$item" "$tmp_dir/$skill_name/"
    fi
  done

  (cd "$tmp_dir" && zip -r "$DIST_DIR/${skill_name}.zip" "$skill_name/" -x "*/.DS_Store")
  rm -rf "$tmp_dir"

  echo "  OK: ${skill_name}.zip"
  ((count++))
done

echo ""
echo "Done. $count skills packaged in $DIST_DIR/"
ls -lh "$DIST_DIR/"
