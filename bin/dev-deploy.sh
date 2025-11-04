#!/bin/sh
# =========================================
#  Safe deploy helper script
#  - Ensures a clean working tree
#  - Temporarily removes docs/CNAME, commits, pushes, then restores
# =========================================

set -e  # Exit immediately on error

REMOTE="development"
CNAME_PATH="docs/CNAME"
DRY_RUN=${1:-false}

# --- Check for uncommitted changes ---
if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes detected. Please commit or stash before running this script."
  exit 1
else
  echo "✅ Working tree is clean."
fi

# --- Check that remote exists ---
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Remote '$REMOTE' not found. Please add it with:"
  echo "   git remote add $REMOTE <url>"
  exit 1
fi

# --- Handle CNAME removal ---
if [ -f "$CNAME_PATH" ]; then
  echo "Removing $CNAME_PATH..."
  rm "$CNAME_PATH"
  git add -A

  COMMIT_MSG="deploy: $(git rev-parse --short HEAD)"
  echo "Creating temporary commit: '$COMMIT_MSG'..."
  git commit -m "$COMMIT_MSG"

  if [ "$DRY_RUN" = "true" ]; then
    echo "Dry run enabled — skipping push."
  else
    echo "Pushing to '$REMOTE'..."
    git push "$REMOTE" HEAD
  fi

  echo "Reverting to previous commit..."
  git reset --hard HEAD~1

  echo "Remote '$REMOTE' URL: $(git remote get-url "$REMOTE")"
  echo "Done."
else
  echo "$CNAME_PATH not found — nothing to remove."
fi
