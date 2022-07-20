# 🎮 iOS-DiscordPresence

Jailbreak tweak that implements Discord Playing Presence like Samsung Game Launcher. [How does this tweak work?](https://github.com/YuzuZensai/DiscordMobilePlayingCLI)

This is my first jailbreak tweak <3, so it might not be perfect

![Preview](https://user-images.githubusercontent.com/84713269/167249578-41f97c06-756c-4610-a94e-2a259a9171fb.gif)
![Preference](https://user-images.githubusercontent.com/84713269/179952103-1e851b56-14ce-4e48-8f51-ddb52aaf5d01.png)

## 🔧 Installation
1. Download .deb from [release](https://github.com/YuzuZensai/iOS-DiscordPresence/releases) page (for repo, soon?)
2. Install the .deb file (Using your package manager, or Filza)
3. Respring
4. Configure the tweak in the settings

## 👜 Prerequisites

- [Theos](https://theos.dev/)

## 🔧 Building

1. Clone this repository
2. Edit ``Makefile`` if needed
3. Run ``make do`` to build and install on your device, ``make package`` to build, or ``make package FINALPACKAGE=1`` for production build

## ⚠️ Disclaimer

Only tested on iOS 14.3, but it should work on other versions too

iOS-DiscordPresence utilizes Discord API that is outside OAuth2/bot API scope.

``/api/v6/presences``

Automating normal user accounts (generally called "self-bots") outside of the OAuth2/bot API is a **violation** of Discord [Terms Of service](https://discord.com/terms) & [Community Guidelines](https://discord.com/guidelines), and can result in account termination if found. **I do not take any responsibility, liability, or anything that happened on your Discord Account.**
