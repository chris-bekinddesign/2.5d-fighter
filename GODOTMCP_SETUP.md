# GodotMCP Setup Guide

This guide will help you set up GodotMCP in Cursor to enable AI assistance for your Godot project.

## Prerequisites

- Node.js installed (v16 or higher)
- Git installed
- Cursor IDE

## Step 1: Install GodotMCP

✅ **Installation Complete!** GodotMCP has been automatically installed in this project.

The installation is located at:
```
D:\_LOCAL PROJECTS\Gadot\2.5d-fighter\godot-mcp\
```

The built file is ready at:
```
D:\_LOCAL PROJECTS\Gadot\2.5d-fighter\godot-mcp\build\index.js
```

If you need to reinstall or update GodotMCP manually:

1. Clone the GodotMCP repository:
   ```bash
   git clone https://github.com/bradypp/godot-mcp.git godot-mcp
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

## Step 2: Configure GodotMCP in Cursor

✅ **Configuration Complete!** GodotMCP has been automatically configured in your Cursor MCP settings.

The configuration has been added to:
```
C:\Users\chris\.cursor\mcp.json
```

**What was configured:**
- **Server Name:** `godot`
- **Type:** `command`
- **Command:** `node D:\_LOCAL PROJECTS\Gadot\2.5d-fighter\godot-mcp\build\index.js`

**Next Steps:**
1. **Restart Cursor** to load the new MCP configuration
2. Verify the setup:
   - Open Cursor Settings (`Ctrl+,`)
   - Navigate to `Settings → Features → MCP`
   - You should see the `godot` server listed and active/enabled

**Manual Configuration (if needed):**
If you need to configure manually or in a different location:
1. Open Cursor Settings (`Ctrl+,`)
2. Navigate to `Settings → Features → MCP`
3. Click `+ Add New MCP Server`
4. Fill in:
   - **Name:** `godot`
   - **Type:** `command`
   - **Command:** `node D:\_LOCAL PROJECTS\Gadot\2.5d-fighter\godot-mcp\build\index.js`

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


