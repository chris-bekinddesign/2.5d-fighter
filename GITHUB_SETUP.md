# GitHub Setup Guide

This guide will help you set up GitHub for your 2.5D Fighter project.

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the `+` icon in the top right corner
3. Select `New repository`
4. Fill in the repository details:
   - **Repository name:** `2.5d-fighter` (or your preferred name)
   - **Description:** `2.5D Fighter game built with Godot`
   - **Visibility:** Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click `Create repository`

## Step 2: Connect Local Repository to GitHub

After creating the repository on GitHub, you'll see instructions. Run these commands in your project directory:

```bash
# Add the remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/2.5d-fighter.git

# Rename branch to main (if needed)
git branch -M main

# Push your code to GitHub
git push -u origin main
```

## Step 3: Set Up GitHub MCP in Cursor (Optional)

To enable GitHub integration in Cursor's AI assistant:

1. Open Cursor Settings:
   - Press `Ctrl+,` (or `Cmd+,` on Mac)
   - Navigate to `Settings → Features → MCP`

2. Add GitHub MCP Server:
   - Click on `+ Add New MCP Server`
   - Fill in the following:
     - **Name:** `github`
     - **Type:** `SSE` (Server-Sent Events)
     - **URL:** `https://gitmcp.io/Github`
   
   **Note:** You may need to authenticate with GitHub. Follow the prompts to authorize Cursor to access your GitHub account.

3. Save and verify the integration.

## Step 4: Initial Commit (If Not Done)

If you haven't made your initial commit yet:

```bash
# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: 2.5D Fighter project setup"

# Push to GitHub
git push -u origin main
```

## Useful Git Commands

```bash
# Check status
git status

# Add files
git add .
git add <specific-file>

# Commit changes
git commit -m "Your commit message"

# Push to GitHub
git push

# Pull from GitHub
git pull

# View commit history
git log

# Create a new branch
git checkout -b feature/your-feature-name

# Switch branches
git checkout main
```

## GitHub Best Practices

1. **Commit frequently**: Make small, focused commits
2. **Write clear commit messages**: Describe what and why, not how
3. **Use branches**: Create branches for features, fixes, and experiments
4. **Pull before push**: Always pull latest changes before pushing
5. **Review changes**: Use `git diff` to review changes before committing

## Project Structure

Your project structure should look like this:
```
2.5d-fighter/
├── .git/
├── .gitignore
├── .godot/          (ignored by git)
├── icon.svg
├── icon.svg.import
├── project.godot
├── GODOTMCP_SETUP.md
└── GITHUB_SETUP.md
```

## Next Steps

- Set up GitHub Actions for CI/CD (optional)
- Configure branch protection rules (optional)
- Add collaborators (if working in a team)
- Create issues and project boards for task management

