🤠 J0K3R-interactions
Credits & Inspiration:
This project was inspired by kibook/redm-interactions. A huge thanks to Kibook for the great groundwork and inspiration!

A free, highly configurable interaction script for RedM! Let your players sit on chairs 🪑, lie in beds 🛏️, take relaxing baths 🛁, and even play the piano 🎹. Everything from the menu to the language and keybinds is fully customizable via config.lua.

✨ Features
🪑 Take a Seat: Sit on chairs, benches, and barstools.

🛏️ Rest Up: Lie down in beds, bedrolls, and mattresses.

🛁 Stay Clean: Take baths at all major town locations.

🎹 Make Music: Play several different piano models.

🎨 Customizable UI: Fully configurable menu theme (colors, position, font, sizes).

🌍 Multi-Language Support: English and German included by default, and it's incredibly easy to add more.

⌨️ Dynamic Prompts: On-screen prompts powered by uiprompt with a configurable key hash.

⚡ Optimized Performance: Features an adaptive client thread that idles when nothing is happening.

📥 Installation
Drop the J0K3R-interactions folder into your server's resources directory.

Add ensure J0K3R-interactions to your server.cfg.

⚙️ Configuration
Open config.lua to tweak the script to your liking:

🗣️ Config.Locale – Set the language code ('en', 'de', or any custom locale you add).

🔑 Config.OpenKey – The key that opens the interaction picker, defined as a raw key hash (e.g., Config.Keys.U, Config.Keys.E). The on-screen uiprompt will automatically render the correct matching glyph!

🎮 Config.Controls – The input actions for in-menu navigation.

📍 Config.Marker – Change the appearance of the marker drawn on the selected object.

🖌️ Config.Theme – Control everything visual about the menu (colors, fonts, position).

⏱️ Config.NearbyCheckInterval – How often the script checks for nearby interactables (in milliseconds).

🖼️ Branding (Add Your Own Logo)
By default, the menu displays a logo above the title. You can easily customize this to fit your server:

Replace the image: Swap out ui/logo.png with your own file (a PNG with a transparent background works best). Square images render perfectly because the width and height scale together.

Advanced Tweaks:

Change the path by pointing Config.Theme.logoUrl to a different filename inside the ui/ folder.

Adjust the size by editing Config.Theme.logoSize (values like '6vw' or '10vw' work great).

Hide the logo entirely by setting Config.Theme.showLogo to false.

Note: You can independently toggle the text title beneath the logo using Config.Theme.showTitle.

🌍 Adding a New Language
Want to translate the script into another language? It's simple:

📄 Copy locales/en.lua and rename it to locales/yourlang.lua.

✍️ Translate the strings inside the new file.

🔄 Open config.lua and set Config.Locale = 'yourlang'.

📋 Make sure your new file is referenced in the fxmanifest.lua under client_scripts.

🛠️ Adding New Interactions
You can easily expand what players can interact with by editing shared/interactions.lua:

Object-bound entries: Require objects (a list of model names) and a radius.

Location-bound entries: Require specific coordinates (x, y, z) and a radius.

Actions: Each entry uses either scenarios or animations.

Display: The category field controls the translated prefix shown inside the menu.
