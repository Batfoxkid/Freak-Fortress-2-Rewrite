/*
	Here we go again
		-Batfoxkid
*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <clientprefs>
#include <adt_trie_sort>
#include <cfgmap>
#include <morecolors>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION			"1.2"
#define PLUGIN_VERSION_REVISION	"custom"
#define PLUGIN_VERSION_FULL		"Rewrite " ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION
#define IS_MAIN_FF2

#define FILE_CHARACTERS	"data/freak_fortress_2/characters.cfg"
#define FOLDER_CONFIGS	"configs/freak_fortress_2"

#define GITHUB_URL	"github.com/Batfoxkid/Freak-Fortress-2-Rewrite"

#define FAR_FUTURE		100000000.0
#define MAXENTITIES		2048
#define MAXTF2PLAYERS	MAXPLAYERS+1

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red			2
#define TFTeam_Blue			3
#define TFTeam_MAX			4

enum TFStatType_t
{
	TFSTAT_UNDEFINED = 0,
	TFSTAT_SHOTS_HIT,
	TFSTAT_SHOTS_FIRED,
	TFSTAT_KILLS,
	TFSTAT_DEATHS,
	TFSTAT_DAMAGE,
	TFSTAT_CAPTURES,
	TFSTAT_DEFENSES,
	TFSTAT_DOMINATIONS,
	TFSTAT_REVENGE,
	TFSTAT_POINTSSCORED,
	TFSTAT_BUILDINGSDESTROYED,
	TFSTAT_HEADSHOTS,
	TFSTAT_PLAYTIME,
	TFSTAT_HEALING,
	TFSTAT_INVULNS,
	TFSTAT_KILLASSISTS,
	TFSTAT_BACKSTABS,
	TFSTAT_HEALTHLEACHED,
	TFSTAT_BUILDINGSBUILT,
	TFSTAT_MAXSENTRYKILLS,
	TFSTAT_TELEPORTS,
	TFSTAT_FIREDAMAGE,
	TFSTAT_BONUS_POINTS,
	TFSTAT_BLASTDAMAGE,
	TFSTAT_DAMAGETAKEN,
	TFSTAT_HEALTHKITS,
	TFSTAT_AMMOKITS,
	TFSTAT_CLASSCHANGES,
	TFSTAT_CRITS,
	TFSTAT_SUICIDES,
	TFSTAT_CURRENCY_COLLECTED,
	TFSTAT_DAMAGE_ASSIST,
	TFSTAT_HEALING_ASSIST,
	TFSTAT_DAMAGE_BOSS,
	TFSTAT_DAMAGE_BLOCKED,
	TFSTAT_DAMAGE_RANGED,
	TFSTAT_DAMAGE_RANGED_CRIT_RANDOM,
	TFSTAT_DAMAGE_RANGED_CRIT_BOOSTED,
	TFSTAT_REVIVED,
	TFSTAT_THROWABLEHIT,
	TFSTAT_THROWABLEKILL,
	TFSTAT_KILLSTREAK_MAX,
	TFSTAT_KILLS_RUNECARRIER,
	TFSTAT_FLAGRETURNS,
	TFSTAT_TOTAL
};

enum
{
	WINREASON_NONE = 0,
	WINREASON_ALL_POINTS_CAPTURED,
	WINREASON_OPPONENTS_DEAD,
	WINREASON_FLAG_CAPTURE_LIMIT,
	WINREASON_DEFEND_UNTIL_TIME_LIMIT,
	WINREASON_STALEMATE,
	WINREASON_TIMELIMIT,
	WINREASON_WINLIMIT,
	WINREASON_WINDIFFLIMIT,
	WINREASON_RD_REACTOR_CAPTURED,
	WINREASON_RD_CORES_COLLECTED,
	WINREASON_RD_REACTOR_RETURNED,
	WINREASON_PD_POINTS,
	WINREASON_SCORED,
	WINREASON_STOPWATCH_WATCHING_ROUNDS,
	WINREASON_STOPWATCH_WATCHING_FINAL_ROUND,
	WINREASON_STOPWATCH_PLAYING_ROUNDS,
	WINREASON_CUSTOM_OUT_OF_TIME
};

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
	Section_FileNet		// filenetwork
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

public const int TeamColors[][] =
{
	{255, 255, 100, 255},
	{100, 255, 100, 255},
	{255, 100, 100, 255},
	{100, 100, 255, 255}
};

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
	SpecTeam,
	CaptureTime,
	CaptureAlive,
	CaptureDome,
	HealthBar,
	RefreshDmg,
	RefreshTime,
	DisguiseModels,
	PlayerGlow,
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

int PlayersAlive[TFTeam_MAX];
int MaxPlayersAlive[TFTeam_MAX];
int Charset;
bool Enabled;
int RoundStatus;
bool PluginsEnabled;
Handle PlayerHud;
Handle ThisPlugin;

#include "freak_fortress_2/client.sp"
#include "freak_fortress_2/stocks.sp"

#include "freak_fortress_2/attributes.sp"
#include "freak_fortress_2/bosses.sp"
#include "freak_fortress_2/commands.sp"
#include "freak_fortress_2/configs.sp"
#include "freak_fortress_2/convars.sp"
#include "freak_fortress_2/customattrib.sp"
#include "freak_fortress_2/database.sp"
#include "freak_fortress_2/dhooks.sp"
#include "freak_fortress_2/dome.sp"
#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/events.sp"
#include "freak_fortress_2/filenetwork.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/forwards.sp"
#include "freak_fortress_2/forwards_old.sp"
#include "freak_fortress_2/gamemode.sp"
#include "freak_fortress_2/goomba.sp"
#include "freak_fortress_2/menu.sp"
#include "freak_fortress_2/music.sp"
#include "freak_fortress_2/natives.sp"
#include "freak_fortress_2/natives_old.sp"
#include "freak_fortress_2/preference.sp"
#include "freak_fortress_2/sdkcalls.sp"
#include "freak_fortress_2/sdkhooks.sp"
#include "freak_fortress_2/steamworks.sp"
#include "freak_fortress_2/teuton.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"
#include "freak_fortress_2/weapons.sp"

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
	if(!TranslationPhraseExists("Sapper Cooldown"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
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
	SDKCall_Setup();
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
}

public void OnAllPluginsLoaded()
{
	Configs_AllPluginsLoaded();

	if(!Attrib_Loaded() && !VScript_Loaded())
		LogError("[!!!] No attribute manager is loaded, make sure either TF2Attributes or VScript is loaded on the server and compiled into FF2");
	
	if(!TFED_Loaded() && !VScript_Loaded())
		LogError("[!!!] Static attribute and weapons config will have problems, make sure either TFEconData or VScript is loaded on the server and compiled into FF2");
	
	if(!CustomAttrib_Loaded())
		LogError("[!!!] No custom attribute manager is loaded, make sure either TFCustAttr or TFEconDynamic is loaded on the server and compiled into FF2");
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
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	VScript_LibraryAdded(name);
	Weapons_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	CustomAttrib_LibraryRemoved(name);
	DHook_LibraryRemoved(name);
	FileNet_LibraryRemoved(name);
	SDKHook_LibraryRemoved(name);
	SteamWorks_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	VScript_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);
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

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	Gamemode_ConditionRemoved(client, cond);
}
