# Ｆｒｅａｋ　Ｆｏｒｔｒｅｓｓ　２：　Ｒｅｗｒｉｔｅ

### A base for making custom bosses in Team Fortress 2 and another generation of the Vs. Saxton Hale gamemode.

## Installation:

**[Lastest Release](https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite/releases/latest)** or [Other Releases](https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite/releases)  
Contains plugin and boss assets separately.

Required:

- [SourceMod 1.11+](https://www.sourcemod.net/downloads.php)
- [TF2Attributes 1.7.0+](https://github.com/nosoop/tf2attributes)
- [TF2Items](https://github.com/asherkin/TF2Items)


Recommended:

- [SM-TFUtils 0.19.0.2+](https://github.com/nosoop/SM-TFUtils)
- [TFEconData](https://github.com/nosoop/SM-TFEconData)
- [TFOnTakeDamage](https://github.com/nosoop/SM-TFOnTakeDamage)

Supported:

- [TFCustAttr](https://github.com/nosoop/SM-TFCustAttr)
- [SM-TFCustomWeaponsX](https://github.com/nosoop/SM-TFCustomWeaponsX)
- [Goomba](https://github.com/Flyflo/SM-Goomba-Stomp-Addons)
- [SteamWorks](https://github.com/ExperimentFailed/SteamWorks)

## Breaking Changes

- Any plugins or includes that rely on the .ff2 file extension will no longer function correctly. (Such as Epic Scout's AMS)
- Abilities are no longer activated in a set order.
- Bosses can not have the multiple abilities with the same name.
- FF2_GetSpecialKV no longer can modify boss stats.
- Less restrictions on when natives or forwards can be used. (Such as FF2_StartMusic)

## Credits

- [VSH2](https://github.com/VSH2-Devs/Vs-Saxton-Hale-2) - ConfigMap system which this now uses
- [Artvin](https://github.com/artvin01) - Boss vs Boss testing and support
- [Marxvee](https://github.com/Marxvee) - HUD layout, score, early disguise port
- Contributors to the [classic](https://github.com/Steell/Freak-Fortress-2), [better](https://github.com/50DKP/FF2-Official), [spicy](https://github.com/shadow93/FreakFortressBBG), and [crazy](https://github.com/Batfoxkid/FreakFortressBat) versions of FF2.
