#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define DHOOKS_LIBRARY	"dhooks"

enum struct RawHooks
{
	int Ref;
	int Pre;
	int Post;
}

static DynamicHook ChangeTeam;
static DynamicHook ForceRespawn;
static DynamicHook RoundRespawn;
static DynamicHook SetWinningTeam;
static DynamicHook GetCaptureValue;
static DynamicHook ApplyOnInjured;
static DynamicHook ApplyPostHit;
static ArrayList RawEntityHooks;
static Address CTFGameStats;
static Address CLagCompensationManager;
static int DamageTypeOffset = -1;

static int ChangeTeamPreHook[MAXTF2PLAYERS];
static int ChangeTeamPostHook[MAXTF2PLAYERS];
static int ForceRespawnPreHook[MAXTF2PLAYERS];
static int ForceRespawnPostHook[MAXTF2PLAYERS];

static int PrefClass;
static int EffectClass;
static int KnifeWasChanged = -1;

void DHook_PluginStart()
{
	if(LibraryExists(DHOOKS_LIBRARY))
		SetupDHook();
}

void DHook_LibraryAdded(const char[] name)
{
	if(!RawEntityHooks && StrEqual(name, DHOOKS_LIBRARY))
		SetupDHook();
}

void DHook_LibraryRemoved(const char[] name)
{
	if(RawEntityHooks && StrEqual(name, DHOOKS_LIBRARY))
	{
		delete RawEntityHooks;
		ChangeTeam = null;
		ForceRespawn = null;
		RoundRespawn = null;
		SetWinningTeam = null;
		GetCaptureValue = null;
		ApplyOnInjured = null;
		ApplyPostHit = null;
	}
}

void DHook_PrintStatus()
{
	PrintToServer("'%s' is %sloaded", DHOOKS_LIBRARY, RawEntityHooks ? "" : "not ");
}

static void SetupDHook()
{
	GameData gamedata = new GameData("ff2");
	
	DamageTypeOffset = gamedata.GetOffset("m_bitsDamageType");
	if(DamageTypeOffset == -1)
		LogError("[Gamedata] Could not find m_bitsDamageType");
	
	CreateDetour(gamedata, "CLagCompensationManager::StartLagCompensation", _, DHook_StartLagCompensation);
	CreateDetour(gamedata, "CTFGameStats::ResetRoundStats", _, DHook_ResetRoundStats);
	// CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", DHook_CanPickupDroppedWeaponPre);
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre);
	CreateDetour(gamedata, "CTFPlayer::RegenThink", DHook_RegenThinkPre, DHook_RegenThinkPost);
	
	// Sorry, we can't use CreateDetour to handle clone function.
	DynamicDetour detour_CanPickupDroppedWeapon = DynamicDetour.FromConf(gamedata, "CTFPlayer::CanPickupDroppedWeapon");
	if(detour_CanPickupDroppedWeapon)
	{
		detour_CanPickupDroppedWeapon.Enable(Hook_Pre, DHook_CanPickupDroppedWeaponPre);
	}
	else
	{
		detour_CanPickupDroppedWeapon = DynamicDetour.FromConf(gamedata, "CTFPlayer::CanPickupDroppedWeapon.part.0");
		detour_CanPickupDroppedWeapon.Enable(Hook_Pre, DHook_CanPickupDroppedWeaponInlinePre);
	}
	
	ChangeTeam = CreateHook(gamedata, "CBaseEntity::ChangeTeam");
	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	RoundRespawn = CreateHook(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
	SetWinningTeam = CreateHook(gamedata, "CTeamplayRules::SetWinningTeam");
	GetCaptureValue = CreateHook(gamedata, "CTFGameRules::GetCaptureValueForPlayer");
	ApplyOnInjured = CreateHook(gamedata, "CTFWeaponBase::ApplyOnInjuredAttributes");
	ApplyPostHit = CreateHook(gamedata, "CTFWeaponBase::ApplyPostHitEffects");
	
	delete gamedata;
	
	RawEntityHooks = new ArrayList(sizeof(RawHooks));
}

static DynamicHook CreateHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if(!hook)
		LogError("[Gamedata] Could not find %s", name);
	
	return hook;
}

static void CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !detour.Enable(Hook_Pre, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !detour.Enable(Hook_Post, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

void DHook_MapStart()
{
	if(GetCaptureValue)
		GetCaptureValue.HookGamerules(Hook_Post, DHook_GetCaptureValue);
	
	if(!RoundRespawn || RoundRespawn.HookGamerules(Hook_Pre, DHook_RoundRespawn) == INVALID_HOOK_ID)
		HookEvent("teamplay_round_start", DHook_RoundSetup, EventHookMode_PostNoCopy);
	
	if(SetWinningTeam)
		SetWinningTeam.HookGamerules(Hook_Pre, DHook_SetWinningTeam);
}

void DHook_HookClient(int client)
{
	if(ForceRespawn)
	{
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawnPre);
		ForceRespawnPostHook[client] = ForceRespawn.HookEntity(Hook_Post, client, DHook_ForceRespawnPost);
	}
	
	if(ChangeTeam && Cvar[DisguiseModels].BoolValue)
		ChangeTeamPostHook[client] = ChangeTeam.HookEntity(Hook_Post, client, DHook_ChangeTeamPost);
}

void DHook_HookBoss(int client)
{
	DHook_UnhookBoss(client);
	if(ChangeTeam && Cvar[AggressiveSwap].BoolValue)
		ChangeTeamPreHook[client] = ChangeTeam.HookEntity(Hook_Pre, client, DHook_ChangeTeamPre);
}

void DHook_EntityCreated(int entity, const char[] classname)
{
	if(ApplyOnInjured && !StrContains(classname, "tf_weapon_knife"))
	{
		ApplyOnInjured.HookEntity(Hook_Pre, entity, DHook_KnifeInjuredPre);
		ApplyOnInjured.HookEntity(Hook_Post, entity, DHook_KnifeInjuredPost);
	}
	
	if(ApplyPostHit && !StrContains(classname, "tf_weapon_drg_pomson"))
	{
		ApplyPostHit.HookEntity(Hook_Pre, entity, DHook_ApplyPostHitPre);
		ApplyPostHit.HookEntity(Hook_Post, entity, DHook_ApplyPostHitPost);
	}
}

void DHook_EntityDestoryed()
{
	if(RawEntityHooks)
		RequestFrame(DHook_EntityDestoryedFrame);
}

static void DHook_EntityDestoryedFrame()
{
	if(RawEntityHooks)
	{
		int length = RawEntityHooks.Length;
		if(length)
		{
			RawHooks raw;
			for(int i; i < length; i++)
			{
				RawEntityHooks.GetArray(i, raw);
				if(!IsValidEntity(raw.Ref))
				{
					if(raw.Pre != INVALID_HOOK_ID)
						DynamicHook.RemoveHook(raw.Pre);
					
					if(raw.Post != INVALID_HOOK_ID)
						DynamicHook.RemoveHook(raw.Post);
					
					RawEntityHooks.Erase(i--);
					length--;
				}
			}
		}
	}
}

void DHook_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			DHook_UnhookClient(client);
	}
}

void DHook_UnhookClient(int client)
{
	if(ForceRespawn)
	{
		DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
		DynamicHook.RemoveHook(ForceRespawnPostHook[client]);
	}
	
	if(ChangeTeamPostHook[client])
		DynamicHook.RemoveHook(ChangeTeamPostHook[client]);
}

void DHook_UnhookBoss(int client)
{
	if(ChangeTeamPreHook[client])
	{
		DynamicHook.RemoveHook(ChangeTeamPreHook[client]);
		ChangeTeamPreHook[client] = 0;
	}
}

Address DHook_GetGameStats()
{
	return CTFGameStats;
}

Address DHook_GetLagCompensationManager()
{
	return CLagCompensationManager;
}

static void DHook_RoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	DHook_RoundRespawn();	// Back up plan
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > TFTeam_Spectator)
			TF2_RespawnPlayer(client);
	}
}

static MRESReturn DHook_CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	switch(Forward_OnPickupDroppedWeapon(client, param.Get(1)))
	{
		case Plugin_Continue:
		{
			if(Client(client).IsBoss || Client(client).MinionType)
			{
				ret.Value = false;
				return MRES_Supercede;
			}
		}
		case Plugin_Handled:
		{
			ret.Value = true;
			return MRES_Supercede;
		}
		case Plugin_Stop:
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHook_CanPickupDroppedWeaponInlinePre(DHookReturn ret, DHookParam param)
{
	int client = param.Get(1);
	int weapon = param.Get(2);
	switch(Forward_OnPickupDroppedWeapon(client, weapon))
	{
		case Plugin_Continue:
		{
			if(Client(client).IsBoss || Client(client).MinionType)
			{
				ret.Value = false;
				return MRES_Supercede;
			}
		}
		case Plugin_Handled:
		{
			ret.Value = true;
			return MRES_Supercede;
		}
		case Plugin_Stop:
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHook_ChangeTeamPre(int client, DHookParam param)
{
	return MRES_Supercede;
}

static MRESReturn DHook_ChangeTeamPost(int client, DHookParam param)
{
	if(param.Get(1) % 2)
	{
		Attrib_Remove(client, "vision opt in flags");
	}
	else
	{
		Attrib_Set(client, "vision opt in flags", 4.0);
	}
	return MRES_Ignored;
}

static MRESReturn DHook_DropAmmoPackPre(int client, DHookParam param)
{
	return (Client(client).MinionType || Client(client).IsBoss) ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn DHook_ForceRespawnPre(int client)
{
	PrefClass = 0;
	if(Client(client).IsBoss)
	{
		int class;
		Client(client).Cfg.GetInt("class", class);
		if(class)
		{
			PrefClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
		}
	}

	return MRES_Ignored;
}

static MRESReturn DHook_ForceRespawnPost(int client)
{
	if(PrefClass)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PrefClass);
	
	return MRES_Ignored;
}

static MRESReturn DHook_GetCaptureValue(DHookReturn ret, DHookParam param)
{
	int client = param.Get(1);
	if(!Client(client).IsBoss || Attrib_FindOnPlayer(client, "increase player capture value"))
		return MRES_Ignored;
	
	ret.Value += TF2_GetPlayerClass(client) == TFClass_Scout ? 1 : 2;
	return MRES_Override;
}

static MRESReturn DHook_RegenThinkPre(int client, DHookParam param)
{
	if(Client(client).IsBoss && TF2_GetPlayerClass(client) == TFClass_Medic)
		TF2_SetPlayerClass(client, TFClass_Unknown, _, false);
	
	return MRES_Ignored;
}

static MRESReturn DHook_RegenThinkPost(int client, DHookParam param)
{
	if(Client(client).IsBoss && TF2_GetPlayerClass(client) == TFClass_Unknown)
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	
	return MRES_Ignored;
}

static MRESReturn DHook_ResetRoundStats(Address address)
{
	CTFGameStats = address;
	return MRES_Ignored;
}

static MRESReturn DHook_RoundRespawn()
{
	Gamemode_RoundSetup();
	return MRES_Ignored;
}

static MRESReturn DHook_StartLagCompensation(Address address)
{
	CLagCompensationManager = address;
	return MRES_Ignored;
}

static MRESReturn DHook_SetWinningTeam(DHookParam param)
{
	if(Enabled && RoundStatus == 1 && Cvar[SpecTeam].BoolValue && param.Get(2) == WINREASON_OPPONENTS_DEAD)
	{
		Events_CheckAlivePlayers();
		
		int found = -1;
		for(int i; i < TFTeam_MAX; i++)
		{
			if(PlayersAlive[i])
			{
				if(found != -1)
					return MRES_Supercede;
				
				found = i;
			}
		}
		
		if(found == -1)
		{
			found = 0;
		}
		else if(found < TFTeam_Red)
		{
			Gamemode_OverrideWinner(found);
			found += 2;
		}
		
		param.Set(1, found);

		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

static MRESReturn DHook_KnifeInjuredPre(int entity, DHookParam param)
{
	if(DamageTypeOffset != -1 && !param.IsNull(2) && Client(param.Get(2)).IsBoss)
	{
		Address address = view_as<Address>(param.Get(3) + DamageTypeOffset);
		int damagetype = LoadFromAddress(address, NumberType_Int32);
		if(!(damagetype & DMG_BURN))
		{
			KnifeWasChanged = damagetype;
			StoreToAddress(address, damagetype | DMG_BURN, NumberType_Int32);
		}
	}

	return MRES_Ignored;
}

static MRESReturn DHook_KnifeInjuredPost(int entity, DHookParam param)
{
	if(KnifeWasChanged != -1)
	{
		StoreToAddress(view_as<Address>(param.Get(3) + DamageTypeOffset), KnifeWasChanged, NumberType_Int32);
		KnifeWasChanged = -1;
	}

	return MRES_Ignored;
}

static MRESReturn DHook_ApplyPostHitPre(int entity, DHookParam param)
{
	int client = param.Get(2);
	if(Client(client).IsBoss)
	{
		EffectClass = GetEntProp(client, Prop_Send, "m_iClass");
		SetEntProp(client, Prop_Send, "m_iClass", TFClass_Spy);
	}

	return MRES_Ignored;
}

static MRESReturn DHook_ApplyPostHitPost(int entity, DHookParam param)
{
	if(EffectClass != -1)
	{
		SetEntProp(param.Get(2), Prop_Send, "m_iClass", EffectClass);
		EffectClass = -1;
	}

	return MRES_Ignored;
}
