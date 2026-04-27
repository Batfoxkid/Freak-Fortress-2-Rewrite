#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define TF2TOOLS_LIBRARY	"tf2"

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red		2
#define TFTeam_Blue		3
#define TFTeam_Green	4
#define TFTeam_Yellow	5
#define TFTeam_MAXLimit	6

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

public int TFTeam_MAX = 4;

static bool Loaded;
static ArrayList ClassNames;
static ArrayList TeamColors;

void TF2Tools_PluginStart()
{
	Loaded = LibraryExists(TF2TOOLS_LIBRARY);
	
	ClassNames = new ArrayList(ByteCountToCells(16));
	ClassNames.PushString("custom");
	ClassNames.PushString("scout");
	ClassNames.PushString("sniper");
	ClassNames.PushString("soldier");
	ClassNames.PushString("demoman");
	ClassNames.PushString("medic");
	ClassNames.PushString("heavy");
	ClassNames.PushString("pyro");
	ClassNames.PushString("spy");
	ClassNames.PushString("engineer");

	TeamColors = new ArrayList(3);
	TeamColors.PushArray({255, 255, 100});
	TeamColors.PushArray({100, 255, 100});
	TeamColors.PushArray({255, 100, 100});
	TeamColors.PushArray({100, 100, 255});

	char folder[16];
	GetGameFolderName(folder, sizeof(folder));
	if(StrEqual(folder, "tf2classified"))
	{
		ClassNames.PushString("civilian");
		TeamColors.PushArray({100, 255, 100});
		TeamColors.PushArray({255, 255, 100});
		TFTeam_MAX = 6;
	}
}

void TF2Tools_LibraryAdded(const char[] name)
{
	if(!Loaded && StrEqual(name, TF2TOOLS_LIBRARY))
		Loaded = true;
}

void TF2Tools_LibraryRemoved(const char[] name)
{
	if(!Loaded && StrEqual(name, TF2TOOLS_LIBRARY))
		Loaded = true;
}

stock bool TF2Tools_Loaded()
{
	return Loaded;
}

stock void TF2Tools_GetTeamColor(int team, int color[3])
{
	int team2 = team;
	if(team2 < 0 || team2 >= TeamColors.Length)
		team2 = 0;
	
	TeamColors.GetArray(team2, color);
}

stock void TF2Tools_GetTeamColor4(int team, int color4[4])
{
	int color3[3];
	TF2Tools_GetTeamColor(team, color3);

	for(int i; i < 3; i++)
	{
		color4[i] = color3[i];
	}

	color4[3] = 255;
}

stock void TF2Tools_RespawnPlayer(int client)
{
	if(Loaded)
	{
		TF2_RespawnPlayer(client);
	}
	else
	{
		SetVariantString("self.ForceRespawn()");
		AcceptEntityInput(client, "RunScriptCode");
	}
}

stock void TF2Tools_RegeneratePlayer(int client, bool refill = true)
{
	if(Loaded && refill)
	{
		TF2_RegeneratePlayer(client);
	}
	else
	{
		SetVariantString(refill ? "self.Regenerate(true)" : "self.Regenerate(false)");
		AcceptEntityInput(client, "RunScriptCode");
	}
}

stock void TF2Tools_AddCondition(int client, TFCond condition, float duration = TFCondDuration_Infinite, int inflictor = 0)
{
	if(Loaded)
	{
		TF2_AddCondition(client, condition, duration, inflictor);
	}
	else if(duration == TFCondDuration_Infinite)
	{
		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "self.AddCond(%d)", condition);
		SetVariantString(buffer);
		AcceptEntityInput(client, "RunScriptCode");
	}
	else
	{
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "self.AddCondEx(%d, %f, %s)", condition, duration, inflictor < 1 ? "null" : "activator");
		SetVariantString(buffer);
		AcceptEntityInput(client, "RunScriptCode", inflictor);
	}
}

stock void TF2Tools_RemoveCondition(int client, TFCond condition)
{
	if(Loaded)
	{
		TF2_RemoveCondition(client, condition);
	}
	else
	{
		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "self.RemoveCond(%d)", condition);
		SetVariantString(buffer);
		AcceptEntityInput(client, "RunScriptCode");
	}
}

stock void TF2Tools_RemovePlayerDisguise(int client)
{
	if(Loaded)
	{
		TF2_RemovePlayerDisguise(client);
	}
	else
	{
		SetVariantString("self.RemoveDisguise()");
		AcceptEntityInput(client, "RunScriptCode");
	}
}

stock void TF2Tools_StunPlayer(int client, float duration, float slowdown = 0.0, int stunflags, int attacker = 0)
{
	if(Loaded)
	{
		TF2_StunPlayer(client, duration, slowdown, stunflags, attacker);
	}
	else
	{
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "self.StunPlayer(%f, %f, %d, %s)", duration, slowdown, stunflags, attacker < 1 ? "null" : "activator");
		SetVariantString(buffer);
		AcceptEntityInput(client, "RunScriptCode", attacker);
	}
}

stock void TF2Tools_MakeBleed(int client, int attacker, float duration)
{
	if(Loaded)
	{
		TF2_MakeBleed(client, attacker, duration);
	}
	else
	{
		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "self.BleedPlayer(%f)", duration);
		SetVariantString(buffer);
		AcceptEntityInput(client, "RunScriptCode");
	}
}

stock TFClassType TF2Tools_GetClass(const char[] classname)
{
	char buffer[16];
	int length = ClassNames.Length;
	for(int i; i < length; i++)
	{
		ClassNames.GetString(i, buffer, sizeof(buffer));
		if(StrEqual(buffer, classname, false))
			return view_as<TFClassType>(i);
	}

	for(int i; i < length; i++)
	{
		ClassNames.GetString(i, buffer, sizeof(buffer));
		if(StrContains(buffer, classname, false) != -1)
			return view_as<TFClassType>(i);
	}

	return view_as<TFClassType>(StringToInt(classname));
}

stock int TF2Tools_GetClassName(TFClassType class, char[] classname, int length)
{
	int choosen = view_as<int>(class);
	if(choosen < 0 || choosen >= ClassNames.Length)
		choosen = 0;
	
	return ClassNames.GetString(choosen, classname, length);
}

stock void TF2Tools_RemoveWearable(int client, int wearable)
{
	if(Loaded)
	{
		TF2_RemoveWearable(client, wearable);
	}
	else
	{
		RemoveEntity(wearable);
	}
}

stock void TF2Tools_RemoveWeaponSlot(int client, int slot)
{
	int weaponIndex;
	while((weaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		int extraWearable = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearable");
		if(extraWearable != -1)
		{
			TF2Tools_RemoveWearable(client, extraWearable);
		}

		extraWearable = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearableViewModel");
		if(extraWearable != -1)
		{
			TF2Tools_RemoveWearable(client, extraWearable);
		}

		RemovePlayerItem(client, weaponIndex);
		AcceptEntityInput(weaponIndex, "Kill");
	}
}
