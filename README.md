# Switcheroo

**Quick page and keyboard preset switching for DaVinci Resolve.** Switcheroo uses Hammerspoon and Resolve’s scripting connection. Once it is set up, bring Resolve to the front and press a shortcut.

## Use it

The example shortcuts are:

- **F2** — Edit page with the `EditPreset` keyboard preset
- **F3** — Color page with the `ColorPreset` keyboard preset

Switcheroo changes both the page and the keyboard preset together. It only responds while Resolve is the frontmost app. It does not change clips, edits, grades, or other project content.

## Set it up

You need macOS, Hammerspoon, and a Resolve edition that provides external scripting. Resolve must be open when you use the shortcuts.

1. Install and open Hammerspoon. In **System Settings → General → Login Items**, add Hammerspoon so it starts when you log in. Hammerspoon also has a **Launch Hammerspoon at login** option in its own Preferences.
2. In Resolve, open **DaVinci Resolve → Preferences → System → General**. Set **External scripting using** to **Local**, then save the preferences.
3. Keep the `Switcheroo` folder somewhere that will stay on your Mac.
4. Tell Hammerspoon to use Switcheroo’s `init.lua` file. Open Terminal and enter this command, replacing the example path with the actual location of your Switcheroo folder:

   ```sh
   defaults write org.hammerspoon.Hammerspoon MJConfigFile "/path/to/Switcheroo/init.lua"
   ```

   For example, if the folder is in Downloads, the path might start with `/Users/your-name/Downloads/`. The quotes around the path are important when folder names contain spaces.

5. Quit and reopen Hammerspoon, or choose **Reload Config** from its menu bar menu. A “Switcheroo shortcuts loaded” alert means it started.
6. Bring Resolve to the front and press F2 or F3.

### If you already have a Hammerspoon setup

The command above tells Hammerspoon to load Switcheroo as its active configuration. It does not combine Switcheroo with another configuration. Keep a copy of your previous configuration so you can return to it. To return to Hammerspoon’s usual `~/.hammerspoon/init.lua` location, run:

```sh
defaults delete org.hammerspoon.Hammerspoon MJConfigFile
```

Then quit and reopen Hammerspoon. If your previous setup used a custom file location, set that location again instead of deleting the setting.

## Change the shortcuts or presets

Open `init.lua` in a text editor and edit the `bindings` section near the top. For example:

```lua
bindings = {
    { modifiers = {}, key = "F2", page = "edit", preset = "EditPreset", label = "Edit" },
    { modifiers = {}, key = "F3", page = "color", preset = "ColorPreset", label = "Color" },
}
```

Change `key` to the shortcut you want, `page` to a Resolve page name, and `preset` to a keyboard preset that exists in your Resolve installation. The example page names are `media`, `cut`, `edit`, `fusion`, `color`, `fairlight`, and `deliver`. You can add a modifier such as `shift` like this: `modifiers = { "shift" }`.

After saving changes, choose **Reload Config** from the Hammerspoon menu bar menu. Use shortcuts that do not conflict with macOS or another app.

## If it doesn’t work

- **No response:** Make sure Resolve is open and in front. Check for a shortcut conflict, then reload Hammerspoon’s config.
- **A “Resolve API error” alert:** Confirm **External scripting using** is set to **Local** in Resolve. Check that the configured keyboard preset name exists in Resolve.
- **Python or scripting module error:** Switcheroo uses the Python runtime and scripting module bundled with Resolve. Those locations can differ between custom installations.
- **Need help:** Open Hammerspoon’s menu bar menu and choose **Console**. Error details appear there.

## More detail

Switcheroo calls Resolve’s scripting API to load the requested keyboard preset and page. It checks the API results and confirms the active preset. Only one request runs at a time; extra shortcut presses are ignored until it finishes. Shortcuts are enabled only while Resolve is frontmost by default.

Resolve’s scripting availability, page names, and preset names can vary by version and edition. Switcheroo does not install or modify Resolve files. It has been tested with the Resolve and Hammerspoon setup used by its author; check it with your own installation before relying on it.

## License

MIT. See [`LICENSE`](LICENSE).
