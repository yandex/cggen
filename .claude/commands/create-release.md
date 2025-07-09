---
allowed-tools: Bash(gh release view:*), Bash(gh release list:*)
description: Create a release
---

Create $ARGUMENTS release

## Recent Releases
- Previous releases: !git tag --sort=-creatordate | head -n 10

- Current git status: !`git status`
- Current branch: !`git branch --show-current`

**ENSURE YOU ARE ON MAIN BRANCH AND THERE ARE NO UNCOMMITTED CHANGES**
**ENSURE MAIN BRANCH IS UP TO DATE WITH UPSTREAM REMOTE**
**ENSURE `HEAD` EXISTS ON UPSTREAM REMOTE**

**IF ANY OF THESE CONDITIONS ARE NOT MET, EXIT NOW**

- Validate version format (must be semantic versioning x.y.z)
- Review 3-4 recent releases to understand the format and style:
  - Use `gh release view` to check formatting conventions
  - Note emoji usage, section organization, and tone
- Find previous version of $ARGUMENTS
- Checkout diff between previous and current version:
  - If release is minor or patch, research the changes on the matter of breaking changes
- Run tests and build to ensure release readiness:
   - Run `swift test`
   - Run `swift build --configuration release`
- Create a temporary RELEASE_$ARGUMENTS.md file following the established format:
   - Match the style and formatting of recent releases
   - Include appropriate emoji headers (🚀, ✨, 🆕, etc.)
   - Organize sections consistently with previous releases
   - List changes with PR/commit references

- **VERY IMPORTANT**: Ask user for confirmation with RELEASE_$ARGUMENTS.md content
   - If user confirms, proceed to next steps
   - If user does not confirm, remove RELEASE_$ARGUMENTS.md and exit

- Create git tag `$ARGUMENTS` with a brief summary message
- Push the tag to the remote repository, ensure remote is an upstream, not a fork
- Create github release with the content of RELEASE_$ARGUMENTS.md
