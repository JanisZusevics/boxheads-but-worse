# BrsSSS

Short one-line description of what the addon does.

> Example:  
> BrsSSS is a Godot 4.x editor addon that allows you to quickly enable, disable, and restart editor plugins from a custom dock.

---

## Features

- Enable / disable editor addons
- Restart addons without restarting the editor
- Supports Godot 4.4+
- No required project autoloads
- Works as an editor plugin

---

## Installation

### Option 1: Godot Asset Library
(Not yet published)  
Link will be added once available.

### Option 2: Manual installation

1. Download the latest release ZIP from **Releases**
2. Extract it into your project so you get:

res://addons/
├─ BrsSSS/
└─ BrsLib/


3. Open Godot
4. Go to **Project → Project Settings → Plugins**
5. Enable **BrsSSS**

---

## Usage

1. Enable the plugin
2. Open the **BrsSSS** dock in the editor
3. Enter addon names (comma-separated)
4. Disable / re-enable addons as needed

For full usage instructions, see the manual below.

---

## Documentation

📘 **Full manual (HTML):**  
- `docs/index.html` (local)  
or  
- https://yourusername.github.io/BrsSSS/

The manual includes:
- Full UI explanation
- Advanced usage
- Known limitations
- Screenshots

---

## Requirements

- Godot **4.4 or newer**
- Editor usage only (not runtime)

---

## Known Limitations

- Restarting addons relies on editor plugin reload behavior
- Some plugins may not re-initialize cleanly after reload

---

## Roadmap

- Asset Library release
- Better error reporting
- Presets for addon groups

---

## License

MIT (or whatever you use)

---

## Credits

Created by **YourName**  
Uses **BrsLib** (separate repository)

---

## Related Repositories

- BrsLib: https://github.com/BrahRah/BrsLib
