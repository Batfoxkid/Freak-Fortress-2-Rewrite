/*
	void ConVar_PluginStart()
	void ConVar_ConfigsExecuted()
	void ConVar_Enable()
	void ConVar_Disable()
*/

#pragma semicolon 1
#pragma newdecls required

enum struct CvarInfo
{
	ConVar cvar;
	char value[16];
	char defaul[16];
	bool enforce;
}

static ArrayList CvarList;
static bool CvarHooked;

void ConVar_PluginStart()
{
	Cvar[Version] = CreateConVar("ff2_version", PLUGIN_VERSION_FULL, "Freak Fortress 2 Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar[NextCharset] = CreateConVar("ff2_current", "0", "Boss pack set for next load", FCVAR_DONTRECORD);
	Cvar[Debugging] = CreateConVar("ff2_debug", "0", "If to display debug outputs and keep full configs", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	Cvar[SpecTeam] = CreateConVar("ff2_game_spec", "1", "If to handle spectator teams as real fighting teams", _, true, 0.0, true, 1.0);
	Cvar[BossVsBoss] = CreateConVar("ff2_game_bvb", "0", "How many bosses per a team, 0 to disable", FCVAR_NOTIFY, true, 0.0, true, float(MaxClients/2));
	Cvar[BossSewer] = CreateConVar("ff2_game_suicide", "1", "If bosses can use kill binds during the round", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar[HealthBar] = CreateConVar("ff2_game_healthbar", "3", "If a health bar and/or text will be shown, 1 = Health Bar, 2 = Health Display, 3 = Both", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar[RefreshDmg] = CreateConVar("ff2_game_healthbar_refreshdmg", "1", "Refresh health display when damage or healing is done", _, true, 0.0, true, 1.0);
	Cvar[RefreshTime] = CreateConVar("ff2_game_healthbar_refreshtime", "2.8", "Refresh rate of the health display", _, true, 0.0);
	Cvar[BossTriple] = CreateConVar("ff2_boss_triple", "1", "If v1 bosses will deal extra damage versus players by default", _, true, 0.0, true, 1.0);
	Cvar[BossCrits] = CreateConVar("ff2_boss_crits", "0", "If v1 bosses can perform random crits by default", _, true, 0.0, true, 1.0);
	Cvar[BossHealing] = CreateConVar("ff2_boss_healing", "0", "If v1 bosses can be healed by default, 1 = Self Healing Only, 2 = Other Healing Only, 3 = Both", _, true, 0.0, true, 3.0);
	Cvar[BossKnockback] = CreateConVar("ff2_boss_knockback", "0", "If v1 bosses can perform self-knockback by default, 2 will also allow self-damage", _, true, 0.0, true, 2.0);
	Cvar[PrefBlacklist] = CreateConVar("ff2_pref_blacklist", "-1", "If boss selection whitelist is a blacklist instead with the limit being the value of this cvar", FCVAR_NOTIFY, true, -1.0);
	Cvar[PrefToggle] = CreateConVar("ff2_pref_toggle", "1", "If players can opt out playing bosses and reset queue points", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar[CaptureTime] = CreateConVar("ff2_game_capture_time", "n*15 + 60", "Amount of time until the control point unlocks, similar to tf_arena_override_cap_enable_time, can be a formula");
	Cvar[CaptureAlive] = CreateConVar("ff2_game_capture_alive", "n/5", "Amount of players left alive until the control point unlocks, can be a formula");
	Cvar[AggressiveSwap] = CreateConVar("ff2_aggressive_noswap", "0", "Block bosses changing teams, even from other plugins.\nOnly use if you have subplugin issues swapping teams, even then you should fix them anyways", _, true, 0.0, true, 1.0);
	Cvar[AggressiveOverlay] = CreateConVar("ff2_aggressive_overlay", "0", "Force clears overlays on death and round end.\nOnly use if you have subplugin issues not cleaing overlays, even then you should fix them anyways", _, true, 0.0, true, 1.0);
	Cvar[SoundType] = CreateConVar("ff2_boss_globalsounds", "0", "If default sounds are globally heard", _, true, 0.0, true, 1.0);
	Cvar[DisguiseModels] = CreateConVar("ff2_game_disguises", "1", "If to use rome vision to apply custom models to disguises.\nCan't modifiy cvar value while players are active.", _, true, 0.0, true, 1.0);
	Cvar[PlayerGlow] = CreateConVar("ff2_game_last_glow", "1", "If the final mercenary of a team will be highlighted.", _, true, 0.0, true, 1.0);
	Cvar[PrefSpecial] = CreateConVar("ff2_pref_special", "0.0", "If non-zero, difficulties will be randomly applied onto a boss based on the chance set.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar[Telefrags] = CreateConVar("ff2_game_telefrag", "5000", "How much damage telefrags do on bosses");
	Cvar[SubpluginFolder] = CreateConVar("ff2_plugin_subplugins", "freaks", "Folder to load/unload when bosses are at play relative to the plugins folder.");
	Cvar[FileCheck] = CreateConVar("ff2_plugin_checkfiles", "1", "If to check and warn about missing files from bosses. (Disabling this can help load times.)", _, true, 0.0, true, 1.0);
	
	CreateConVar("ff2_oldjump", "1", "Backwards Compatibility ConVar", FCVAR_DONTRECORD|FCVAR_HIDDEN, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Backwards Compatibility ConVar", FCVAR_DONTRECORD|FCVAR_HIDDEN, true, 0.0, true, 1.0);
	CreateConVar("ff2_solo_shame", "1", "Backwards Compatibility ConVar", FCVAR_DONTRECORD|FCVAR_HIDDEN, true, 0.0, true, 1.0);
	
	AutoExecConfig(false, "FF2Rewrite");
	
	Cvar[AllowSpectators] = FindConVar("mp_allowspectators");
	Cvar[MovementFreeze] = FindConVar("tf_player_movement_restart_freeze");
	Cvar[PreroundTime] = FindConVar("tf_arena_preround_time");
	//Cvar[BonusRoundTime] = FindConVar("mp_bonusroundtime");
	Cvar[Tournament] = FindConVar("mp_tournament");
	Cvar[WaitingTime] = FindConVar("mp_waitingforplayers_time");
	
	CvarList = new ArrayList(sizeof(CvarInfo));
	
	ConVar_Add("tf_arena_first_blood", "0");
	ConVar_Add("tf_arena_use_queue", "0");
	ConVar_Add("mp_forcecamera", "0");
	ConVar_Add("mp_humans_must_join_team", "any");
	ConVar_Add("mp_teams_unbalance_limit", "0");
	ConVar_Add("mp_waitingforplayers_time", "90.0", false);
}

void ConVar_ConfigsExecuted()
{
	bool generate = !FileExists("cfg/sourcemod/FF2Rewrite.cfg");
	
	if(!generate)
	{
		char buffer[512];
		Cvar[Version].GetString(buffer, sizeof(buffer));
		if(!StrEqual(buffer, PLUGIN_VERSION_FULL))
		{
			if(buffer[0])
				generate = true;
			
			Cvar[Version].SetString(PLUGIN_VERSION_FULL);
		}
	}
	
	if(generate)
		GenerateConfig();
	
	if(Enabled)
		ConVar_Enable();
}

static void GenerateConfig()
{
	File file = OpenFile("cfg/sourcemod/FF2Rewrite.cfg", "wt");
	if(file)
	{
		file.WriteLine("// Settings present are for Freak Fortress 2: Rewrite (" ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION ... ")");
		file.WriteLine("// Updating the plugin version will generate new cvars and any non-FF2 commands will be lost");
		file.WriteLine("ff2_version \"" ... PLUGIN_VERSION_FULL ... "\"");
		file.WriteLine(NULL_STRING);
		
		char buffer1[512], buffer2[256];
		for(int i; i < AllowSpectators; i++)
		{
			if(Cvar[i].Flags & FCVAR_DONTRECORD)
				continue;
			
			Cvar[i].GetDescription(buffer1, sizeof(buffer1));
			
			int current, split;
			do
			{
				split = SplitString(buffer1[current], "\n", buffer2, sizeof(buffer2));
				if(split == -1)
				{
					file.WriteLine("// %s", buffer1[current]);
					break;
				}
				
				file.WriteLine("// %s", buffer2);
				current += split;
			}
			while(split != -1);
			
			file.WriteLine("// -");
			
			Cvar[i].GetDefault(buffer2, sizeof(buffer2));
			file.WriteLine("// Default: \"%s\"", buffer2);
			
			float value;
			if(Cvar[i].GetBounds(ConVarBound_Lower, value))
				file.WriteLine("// Minimum: \"%.2f\"", value);
			
			if(Cvar[i].GetBounds(ConVarBound_Upper, value))
				file.WriteLine("// Maximum: \"%.2f\"", value);
			
			Cvar[i].GetName(buffer2, sizeof(buffer2));
			Cvar[i].GetString(buffer1, sizeof(buffer1));
			file.WriteLine("%s \"%s\"", buffer2, buffer1);
			file.WriteLine(NULL_STRING);
		}
		
		delete file;
	}
}

static void ConVar_Add(const char[] name, const char[] value, bool enforce = true)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;

	if(CvarHooked)
	{
		info.cvar.GetString(info.defaul, sizeof(info.defaul));

		bool setValue = true;
		if(!info.enforce)
		{
			char buffer[sizeof(info.defaul)];
			info.cvar.GetDefault(buffer, sizeof(buffer));
			if(!StrEqual(buffer, info.defaul))
				setValue = false;
		}

		if(setValue)
			info.cvar.SetString(info.value);
		
		info.cvar.AddChangeHook(ConVar_OnChanged);
	}

	CvarList.PushArray(info);
}

public void ConVar_OnlyChangeOnEmpty(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			cvar.SetString(oldValue);
			break;
		}
	}
}

stock void ConVar_Remove(const char[] name)
{
	ConVar cvar = FindConVar(name);
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);
		CvarList.Erase(index);

		if(CvarHooked)
		{
			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}
	}
}

void ConVar_Enable()
{
	if(!CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);
			info.cvar.GetString(info.defaul, sizeof(info.defaul));
			CvarList.SetArray(i, info);

			bool setValue = true;
			if(!info.enforce)
			{
				char buffer[sizeof(info.defaul)];
				info.cvar.GetDefault(buffer, sizeof(buffer));
				if(!StrEqual(buffer, info.defaul))
					setValue = false;
			}

			if(setValue)
				info.cvar.SetString(info.value);
			
			info.cvar.AddChangeHook(ConVar_OnChanged);
		}

		Cvar[Tournament].Flags &= ~(FCVAR_NOTIFY|FCVAR_REPLICATED);
		CvarHooked = true;
	}
}

void ConVar_Disable()
{
	if(CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);

			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}

		Cvar[Tournament].Flags |= (FCVAR_NOTIFY|FCVAR_REPLICATED);
		CvarHooked = false;
	}
}

public void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);

		if(!StrEqual(info.value, newValue))
		{
			strcopy(info.defaul, sizeof(info.defaul), newValue);
			CvarList.SetArray(index, info);

			if(info.enforce)
				info.cvar.SetString(info.value);
		}
	}
}
