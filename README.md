# Freak Fortress 2 Rewrite

**A gamemode where a group of mercenaries fight together against a boss ( or multiple ).**

A new version of Freak Fortress 2, rewritten from the ground up while keeping support for previous configs and subplugins. 

_Keep in mind that this is not fully finished yet. The gamemode itself and most of the other things will run fine, but there might bugs here and there. 
Please report the bugs you encounter in the [issues tab](/issues)_


## New Features

There'll eventually be a wiki page where all of the new features / changes ( also commands, convars etc... ) will be listed and explained. 

- You can now use bosses outside the gamemode, this of course requires subplugin changes.
- A new subplugin format that's available to use.
- A new boss config format that also allows mix matching old and new styles.
- A redesign of existing configs, weapons, and HUDs.
- Runs faster and easily takes on multiple bosses at once.
- A ton of Quality Of Life changes and additions.

### What's left to do?

- Test and Debug!
- New mobility-abilities subplugin.
- A party system for companion bosses.
- Boss difficulty system.
- New natives and forwards.


## What will be broken if I move from the old versions of FF2?

- **Dynamic Defaults**, **Drain Over Time** and other includes (Modifiy .ff2 extension with .smx extension).
- Abilities are no longer activated in a set order.
- Bosses can not have the multiple abilities with the same name.
- FF2_GetSpecialKV no longer can modify boss stats.
- Subplugins that do unintended things (such as starting music before a round starts).


## Installation

### Dependencies

Required:

- [DHooks2](https://github.com/peace-maker/DHooks2) - This is already included if you're using SM 1.11.
- [Nosoop's tf2attributes fork](https://github.com/nosoop/tf2attributes)
- [TF2Items](https://github.com/asherkin/TF2Items)


Recommended:

- [SM-TFUtils](https://github.com/nosoop/SM-TFUtils)
- [TFEconData](https://github.com/nosoop/SM-TFEconData)
- [TFOnTakeDamage](https://github.com/nosoop/SM-TFOnTakeDamage)

Supported:

- [TFCustAttr](https://github.com/nosoop/SM-TFCustAttr)
- [SM-TFCustomWeaponsX](https://github.com/nosoop/SM-TFCustomWeaponsX)


## Credits

- [VSH2](https://forums.alliedmods.net/showthread.php?t=286701) - ConfigMap system which this now uses
- [Artvin](https://forums.alliedmods.net/member.php?u=304206) - Boss vs Boss testing and support
- [Marxvee](https://forums.alliedmods.net/member.php?u=289257) - Ideas for new HUD layout and score
- Contributors to the [classic](https://forums.alliedmods.net/showthread.php?t=182108), [better](https://forums.alliedmods.net/showthread.php?t=229013), [spicy](https://github.com/shadow93/FreakFortressBBG), and [crazy](https://forums.alliedmods.net/showthread.php?t=313008) versions of FF2.
