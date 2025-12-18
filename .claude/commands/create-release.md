---
allowed-tools: Bash(gh release view:*), Bash(gh release list:*), Bash(gh release create:*), Bash(gh workflow run:*)
description: Create a release
---

Create $ARGUMENTS release

## Recent Releases
- Previous releases: !git tag --sort=-creatordate | head -n 10

- Current git status: !`git status`
- Current branch: !`git branch --show-current`

**ENSURE THERE ARE NO UNCOMMITTED CHANGES**
**ENSURE YOUR BRANCH IS UP TO DATE WITH UPSTREAM REMOTE**
**ENSURE `HEAD` EXISTS ON UPSTREAM REMOTE**

**IF ANY OF THESE CONDITIONS ARE NOT MET, EXIT NOW**

## Process

1. **Validate version format** (must be semantic versioning x.y.z)

2. **Review recent releases** to understand the format and style:
   - Use `gh release view` to check formatting conventions
   - Note emoji usage, section organization, and tone

3. **Analyze changes** since previous release:
   - Find previous version
   - Check diff between previous and current version
   - If release is minor or patch, research breaking changes

4. **Create release notes** in a temporary RELEASE_$ARGUMENTS.md file:
   - Match the style and formatting of recent releases
   - Include appropriate emoji headers (🚀, ✨, 🆕, etc.)
   - Organize sections consistently with previous releases
   - List changes with PR/commit references

5. **Ask user for confirmation** with RELEASE_$ARGUMENTS.md content
   - If user does not confirm, remove RELEASE_$ARGUMENTS.md and exit

6. **Determine target branch**:
   - Default: `main` for regular releases
   - Ask user if releasing from a different branch (e.g., hotfix from `release-1.x`)

7. **Create draft release**:
   ```bash
   gh release create $ARGUMENTS --draft --target <branch> --title "cggen $ARGUMENTS" --notes-file RELEASE_$ARGUMENTS.md --repo yandex/cggen
   ```

8. **Ask user** if they want to run the release workflow now

9. **Run release workflow** (if user confirms):
   ```bash
   gh workflow run release.yml --repo yandex/cggen
   ```
   - Workflow will: update podspecs, run tests, create tag, publish release
   - Link to monitor: https://github.com/yandex/cggen/actions/workflows/release.yml

10. **Clean up**: Remove RELEASE_$ARGUMENTS.md

**NOTE**: Do NOT manually update podspecs, create tags, or publish the release. The workflow handles all of this automatically.
