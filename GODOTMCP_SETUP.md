# GodotMCP Setup Guide

This guide will help you set up GodotMCP in Cursor to enable AI assistance for your Godot project.

## Prerequisites

- Node.js installed (v16 or higher)
- Git installed
- Cursor IDE

## Step 1: Install GodotMCP

1. Clone the GodotMCP repository:
   ```bash
   git clone https://github.com/bradypp/godot-mcp.git
   cd godot-mcp
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the project:
   ```bash
   npm run build
   ```

4. Note the path to the built file. It will be at:
   ```
   <godot-mcp-directory>/build/index.js
   ```

## Step 2: Configure GodotMCP in Cursor

1. Open Cursor Settings:
   - Press `Ctrl+,` (or `Cmd+,` on Mac)
   - Or go to `File → Preferences → Settings`

2. Navigate to MCP Settings:
   - Search for "MCP" in the settings search bar
   - Or go to `Settings → Features → MCP`

3. Add GodotMCP Server:
   - Click on `+ Add New MCP Server`
   - Fill in the following details:
     - **Name:** `godot`
     - **Type:** `command`
     - **Command:** `node <absolute-path-to-godot-mcp>/build/index.js`
   
   Replace `<absolute-path-to-godot-mcp>` with the actual path where you cloned the repository.
   
   Example (Windows):
   ```
   node D:\tools\godot-mcp\build\index.js
   ```
   
   Example (Mac/Linux):
   ```
   node /home/user/tools/godot-mcp/build/index.js
   ```

4. Save the configuration and restart Cursor if needed.

5. Verify the setup:
   - The MCP server should appear in the MCP servers list
   - You should be able to see it as active/enabled

## Step 3: Verify Integration

Once configured, Cursor's AI assistant should be able to:
- Read and understand your Godot project structure
- Help with GDScript code
- Assist with Godot-specific tasks
- Understand project configuration files

## Troubleshooting

- **Server not starting**: Check that Node.js is in your PATH and the path to `index.js` is correct
- **Permission errors**: Ensure you have read/write permissions to the GodotMCP directory
- **Build errors**: Make sure all dependencies are installed with `npm install`

## Additional Resources

- GodotMCP GitHub: https://github.com/bradypp/godot-mcp
- Cursor MCP Documentation: Check Cursor's official documentation for MCP setup

