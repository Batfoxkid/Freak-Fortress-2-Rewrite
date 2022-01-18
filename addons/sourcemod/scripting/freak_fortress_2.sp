/*
	Here we go again
		-Batfoxkid
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <clientprefs>
#include <cfgmap>
#include <morecolors>
#include <dhooks>
#include <tf2items>
#include <tf2attributes>
#undef REQUIRE_PLUGIN
//#tryinclude <goomba>

#pragma newdecls required

#define PLUGIN_VERSION	"2.0.0"

#define FILE_CHARACTERS	"data/freak_fortress_2/characters.cfg"
#define FOLDER_CONFIGS	"configs/freak_fortress_2"

#define MAJOR_REVISION	1
#define MINOR_REVISION	11
#define STABLE_REVISION	0

#define CHANGELOG_URL	"https://batfoxkid.github.io/Freak-Fortress-2-Rewrite"

#define FAR_FUTURE	100000000.0
#define MAXENTITIES	2048
#define MAXTF2PLAYERS	36

#define HEALTHBAR_CLASS		"monster_resource"
#define HEALTHBAR_PROPERTY	"m_iBossHealthPercentageByte"
#define HEALTHBAR_COLOR		"m_iBossState"
#define HEALTHBAR_MAX		255
#define MONOCULUS		"eyeball_boss"

enum SectionType
{
	Section_Unknown = 0,
	Section_Ability,	// ability | Ability Name
	Section_Map,	// map_
	Section_Weapon,	// weapon | wearable | tf_ | saxxy
	Section_Sound,	// sound_ | catch_
	Section_ModCache,	// mod_precache
	Section_Precache,	// precache
	Section_Download,	// download
	Section_Model,	// mod_download
	Section_Material	// mat_download
};

enum struct SoundEnum
{
	char Sound[PLATFORM_MAX_PATH];
	char Name[64];
	char Artist[64];
	float Time;
	
	char Overlay[PLATFORM_MAX_PATH];
	float Duration;
	
	int Entity;
	int Channel;
	int Level;
	int Flags;
	float Volume;
	int Pitch;
	
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

enum struct WeaponEnum
{
	int Crit;
	int Shield;
	int Stale;
	float Stun;
	float Uber;
	float Stab;
	float Fall;
	float Special;
	float Outline;
	float Damage[3];
	bool HealthKit;
	bool NoForce;
}

ConVar CvarVersion;
ConVar CvarCharset;
ConVar CvarDebug;
ConVar CvarSpecTeam;
ConVar CvarBossVsBoss;
ConVar CvarBossSewer;
ConVar CvarBossTriple;
ConVar CvarBossCrits;
ConVar CvarBossKnockback;

ConVar CvarAllowSpectators;
ConVar CvarMovementFreeze;
ConVar CvarTournament;

int PlayersAlive[4];
int Charset;
bool Enabled;
bool RoundActive;
bool PluginsEnabled;
Handle PlayerHud;
Handle ThisPlugin;

#include "freak_fortress_2/client.sp"
#include "freak_fortress_2/stocks.sp"

#include "freak_fortress_2/attributes.sp"
#include "freak_fortress_2/bosses.sp"
#include "freak_fortress_2/commands.sp"
#include "freak_fortress_2/convars.sp"
#include "freak_fortress_2/database.sp"
#include "freak_fortress_2/dhooks.sp"
#include "freak_fortress_2/events.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/forwards_old.sp"
#include "freak_fortress_2/gamemode.sp"
#include "freak_fortress_2/menu.sp"
#include "freak_fortress_2/music.sp"
#include "freak_fortress_2/natives_old.sp"
#include "freak_fortress_2/preference.sp"
#include "freak_fortress_2/sdkcalls.sp"
#include "freak_fortress_2/sdkhooks.sp"

public Plugin myinfo =
{
	name	=	"Freak Fortress 2: Rewrite",
	author	=	"Batfoxkid based on the original done by many others",
	description	=	"It's like Christmas Morning",
	version	=	PLUGIN_VERSION,
	url	=	"https://forums.alliedmods.net/forumdisplay.php?f=154",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks", false))
		return APLRes_SilentFailure;
	
	ThisPlugin = myself;
	
	ForwardOld_PluginLoad();
	NativeOld_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	PlayerHud = CreateHudSynchronizer();
	
	Attributes_PluginStart();
	Bosses_PluginStart();
	Command_PluginStart();
	ConVar_PluginStart();
	Events_PluginStart();
	Menu_PluginStart();
	Music_PluginStart();
	Preference_PluginStart();
	SDKHook_PluginStart();
	
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientAuthorized(i))
			OnClientAuthorized(i, NULL_STRING);
		
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnAllPluginsLoaded()
{
	Database_Setup();
	DHook_Setup();
	SDKCall_Setup();
}

public void OnMapStart()
{
	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav");
	}
	
	DHook_MapStart();
}

public void OnConfigsExecuted()
{
	Charset = CvarCharset.IntValue;
	
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	Bosses_BuildPacks(Charset, mapname);
	
	if(Enabled)
		ConVar_Enable();
}

public void OnMapEnd()
{
	Bosses_MapEnd();
}

public void OnPluginEnd()
{
	OnMapEnd();
	
	ConVar_Disable();
	Database_PluginEnd();
	DHook_PluginEnd();
	Music_PlaySongToAll();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	Database_ClientAuthorized(client);
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	SDKHook_HookClient(client);
}

public void OnClientDisconnect(int client)
{
	Bosses_ClientDisconnect(client);
	Database_ClientDisconnect(client);
	Events_CheckAlivePlayers(client);
	
	Client(client).ResetByAll();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	Bosses_PlayerRunCmd(client, buttons);
	Music_PlayerRunCmd(client);
	return Plugin_Continue;
}

#file "freak_fortress_2.sp"