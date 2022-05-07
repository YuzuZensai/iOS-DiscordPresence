# 🎮 iOS-DiscordPresence
Jailbreak tweak that implements Discord Playing Presence like Samsung Game Launcher. [How does this tweak work?](https://github.com/YuzuZensai/DiscordMobilePlayingCLI)

This is my first jailbreak tweak <3, so it might not be perfect

![Preview](https://user-images.githubusercontent.com/84713269/167249578-41f97c06-756c-4610-a94e-2a259a9171fb.gif)

## 📃 TODOs

- [ ] Make preference menu, and some basic settings
- [ ] Make the tweak send ``UPDATE`` request every x interval, to keep the status active
- [ ] Better way storing the token (Preference?) / Fetching the discord token (Somehow hooking the Discord app too? No idea yet)
- [ ] Make rate limits to prevent spamming the API

## 🔧 Installation

Prerequisites: [Theos](https://theos.dev/)

1. Clone this repository ``git clone https://github.com/YuzuZensai/iOS-DiscordPresence.git``
2. Edit ``Makefile`` if needed
3. Run ``make do`` to build and install on your device, or ``make package`` to build
4. After installing the tweak, create a new file ``/var/mobile/Documents/DiscordToken.txt`` and put your Discord token there

## ⚠️ Disclaimer

iOS-DiscordPresence utilizes Discord API that is outside OAuth2/bot API scope.

``/api/v6/presences``

Automating normal user accounts (generally called "self-bots") outside of the OAuth2/bot API is a **violation** of Discord [Terms Of service](https://discord.com/terms) & [Community Guidelines](https://discord.com/guidelines), and can result in account termination if found. **I do not take any responsibility, liability, or anything that happened on your Discord Account.**
