/*
	Here we go again
		-Batfoxkid
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <adt_trie_sort>
#include <cfgmap>
#include <morecolors>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"1.3"
#define PLUGIN_VERSION_REVISION	"custom"
#define PLUGIN_VERSION_FULL	"Rewrite " ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION
#define IS_MAIN_FF2

#define FILE_CHARACTERS	"data/freak_fortress_2/characters.cfg"
#define FOLDER_CONFIGS	"configs/freak_fortress_2"

#define GITHUB_URL	"github.com/Batfoxkid/Freak-Fortress-2-Rewrite"

#define FAR_FUTURE	100000000.0
#define MAXTF2PLAYERS	MAXPLAYERS+1

#define SNDVOL_BOSS	2.0

#include "freak_fortress_2/tf2tools.sp"

enum SectionType
{
	Section_Unknown = 0,
	Section_Ability,	// ability | Ability Name
	Section_Map,		// map_
	Section_Weapon,		// weapon | wearable | tf_ | saxxy
	Section_Sound,		// sound_ | catch_
	Section_ModCache,	// mod_precache
	Section_Precache,	// precache
	Section_Download,	// download
	Section_Model,		// mod_download
	Section_Material,	// mat_download
	Section_FileNet,	// filenetwork
	Section_Creator		// creator
};

enum struct SoundEnum
{
	char Sound[PLATFORM_MAX_PATH];
	char Name[64];
	char Artist[64];
	float Time;
	
	char Overlay[PLATFORM_MAX_PATH];
	float Duration;
	int OverlayFileNet;
	
	int Entity;
	int Channel;
	int Level;
	int Flags;
	float Volume;
	int Pitch;

	int FileNet;
	
	void Default()
	{
		this.Entity = SOUND_FROM_PLAYER;
		this.Channel = SNDCHAN_AUTO;
		this.Level = SNDLEVEL_NORMAL;
		this.Flags = SND_NOFLAGS;
		this.Volume = SNDVOL_NORMAL;
		this.Pitch = SNDPITCH_NORMAL;
	}
}

public const char SndExts[][] = { ".mp3", ".wav" };

enum
{
	Version,
	NextCharset,
	Debugging,
	
	AggressiveOverlay,
	AggressiveSwap,

	FileCheck,
	PackVotes,
	SubpluginFolder,
	
	BossTriple,
	BossCrits,
	BossHealing,
	BossKnockback,
	
	BossVsBoss,
	BossTeam,
	SpecTeam,
	CaptureTime,
	CaptureAlive,
	CaptureDome,
	CaptureDomeTime,
	CaptureDomeStyle,
	CaptureDomeRadius,
	HealthBar,
	RefreshDmg,
	RefreshTime,
	DisguiseModels,
	PlayerGlow,
	MusicPlaylist,
	RankingStats,
	RankingLose,
	RankingStyle,
	BossSewer,
	Telefrags,
	StreakDamage,
	Teutons,
	
	PrefBlacklist,
	PrefToggle,
	PrefSpecial,
	
	AllowSpectators,
	FriendlyFire,
	MovementFreeze,
	PreroundTime,
	BonusroundTime,
	Tournament,
	WaitingTime,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

int PlayersAlive[TFTeam_MAXLimit];
int MaxPlayersAlive[TFTeam_MAXLimit];
int Charset;
bool Enabled;
int RoundStatus;
bool PluginsEnabled;
Handle PlayerHud;
Handle ThisPlugin;

#include "freak_fortress_2/core/client.sp"
#include "freak_fortress_2/core/stocks.sp"

#include "freak_fortress_2/core/attributes.sp"
#include "freak_fortress_2/core/bosses.sp"
#include "freak_fortress_2/core/commands.sp"
#include "freak_fortress_2/core/configs.sp"
#include "freak_fortress_2/core/convars.sp"
#include "freak_fortress_2/customattrib.sp"
#include "freak_fortress_2/core/database.sp"
#include "freak_fortress_2/core/dhooks.sp"
#include "freak_fortress_2/core/dome.sp"
#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/core/events.sp"
#include "freak_fortress_2/core/filenetwork.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/core/forwards.sp"
#include "freak_fortress_2/core/forwards_old.sp"
#include "freak_fortress_2/core/gamemode.sp"
#include "freak_fortress_2/core/goomba.sp"
#include "freak_fortress_2/core/menu.sp"
#include "freak_fortress_2/core/music.sp"
#include "freak_fortress_2/core/natives.sp"
#include "freak_fortress_2/core/natives_old.sp"
#include "freak_fortress_2/core/preference.sp"
#include "freak_fortress_2/core/ranking.sp"
#include "freak_fortress_2/core/sdkcalls.sp"
#include "freak_fortress_2/core/sdkhooks.sp"
#include "freak_fortress_2/core/steamworks.sp"
#include "freak_fortress_2/core/teuton.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"
#include "freak_fortress_2/core/weapons.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite",
	author		=	"Batfoxkid based on the original done by many others",
	description	=	"It's like Christmas Morning",
	version		=	PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION,
	url		=	"https://forums.alliedmods.net/forumdisplay.php?f=154"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks", false))
		return APLRes_SilentFailure;
	
	ThisPlugin = myself;
	
	Attrib_PluginLoad();
	CustomAttrib_PluginLoad();
	Forward_PluginLoad();
	ForwardOld_PluginLoad();
	Native_PluginLoad();
	NativeOld_PluginLoad();
	TF2Items_PluginLoad();
	TF2U_PluginLoad();
	TFED_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Whitelist All"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	TF2Tools_PluginStart();
	SDKCall_Setup();

	PlayerHud = CreateHudSynchronizer();
	
	Attrib_PluginStart();
	Attributes_PluginStart();
	Bosses_PluginStart();
	Command_PluginStart();
	ConVar_PluginStart();
	CustomAttrib_PluginStart();
	Database_PluginStart();
	DHook_PluginStart();
	Dome_PluginStart();
	Events_PluginStart();
	FileNet_PluginStart();
	Gamemode_PluginStart();
	Menu_PluginStart();
	Music_PluginStart();
	Preference_PluginStart();
	SDKHook_PluginStart();
	SteamWorks_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();
	Weapons_PluginStart();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}

	char classname[64];
	if(GetCurrentMap(classname, sizeof(classname)))
	{
		int entity = -1;
		while((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			OnEntityCreated(entity, classname);
		}
	}
}

public void OnAllPluginsLoaded()
{
	Configs_AllPluginsLoaded();
	CustomAttrib_AllPluginsLoaded();
}

public void OnMapInit()
{
	Gamemode_MapInit();
}

public void OnMapStart()
{
	Configs_MapStart();
	DHook_MapStart();
	Dome_MapStart();
	Gamemode_MapStart();
	Teuton_MapStart();
	ServerCommand("script_execute freak_fortress_2");
}

public void OnConfigsExecuted()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	GetMapDisplayName(mapname, mapname, sizeof(mapname));
	if(Configs_SetMap(mapname))
	{
		Charset = Cvar[NextCharset].IntValue;
	}
	else
	{
		Charset = -1;
	}
	
	Bosses_BuildPacks(Charset, mapname);
	ConVar_ConfigsExecuted();
	Preference_ConfigsExecuted();
	Weapons_ConfigsExecuted();
}

public void OnMapEnd()
{
	Bosses_MapEnd();
	FileNet_MapEnd();
	Gamemode_MapEnd();
	Preference_MapEnd();
}

public void OnPluginEnd()
{
	Bosses_PluginEnd();
	ConVar_Disable();
	Database_PluginEnd();
	DHook_PluginEnd();
	Gamemode_PluginEnd();
	Music_PlaySongToAll();
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	CustomAttrib_LibraryAdded(name);
	DHook_LibraryAdded(name);
	FileNet_LibraryAdded(name);
	SDKHook_LibraryAdded(name);
	SteamWorks_LibraryAdded(name);
	TF2Tools_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	Weapons_LibraryAdded(name);
	VScript_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	CustomAttrib_LibraryRemoved(name);
	DHook_LibraryRemoved(name);
	FileNet_LibraryRemoved(name);
	SDKHook_LibraryRemoved(name);
	SteamWorks_LibraryRemoved(name);
	TF2Tools_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);
	VScript_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	FileNet_ClientPutInServer(client);
	SDKHook_HookClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	Database_ClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
	Bosses_ClientDisconnect(client);
	Database_ClientDisconnect(client);
	Events_CheckAlivePlayers(client);
	FileNet_ClientDisconnect(client);
	Music_ClientDisconnect(client);
	Preference_ClientDisconnect(client);
	
	Client(client).ResetByAll();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	Bosses_PlayerRunCmd(client, buttons);
	Gamemode_PlayerRunCmd(client, buttons);
	Music_PlayerRunCmd(client);
	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	CustomAttrib_CalcIsAttackCritical(client, weapon);
	
	if(!Client(client).IsBoss || Client(client).Crits || TF2_IsCritBoosted(client))
		return Plugin_Continue;
	
	result = false;
	return Plugin_Changed;
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	Bosses_OnConditonAdded(client, cond);
	Gamemode_ConditionAdded(client, cond);
}
