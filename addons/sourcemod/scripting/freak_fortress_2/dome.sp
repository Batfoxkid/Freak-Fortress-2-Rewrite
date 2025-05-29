/*
	Dome from Versus Saxton Hale: Rewrite
*/

#pragma semicolon 1
#pragma newdecls required

#define DOME_PROP_RADIUS	10000.0	//Dome prop radius, exactly 10k weeeeeeeeeeee

#define DOME_START_RADIUS		5000.0
#define DOME_FADE_START_MULTIPLIER	0.7
#define DOME_FADE_ALPHA_MAX		64

#define DOME_START_SOUND	"mvm/mvm_warning.wav"
#define DOME_NEARBY_SOUND	"ui/medc_alert.wav"
#define DOME_PERPARE_DURATION	4.5

static const char Downloads[][] =
{
	"models/kirillian/brsphere_huge.dx80.vtx",
	"models/kirillian/brsphere_huge.dx90.vtx",
	"models/kirillian/brsphere_huge.mdl",
	"models/kirillian/brsphere_huge.vvd",

	"materials/models/kirillian/brsphere/br_fog.vmt",
	"materials/models/kirillian/brsphere/br_fog.vtf"
};

static bool DomeAssets;

//CP
static float DomeCP[3];	//Pos of CP

//Dome prop
static int DomeEntRef;
static int DomeTeamOwner = TFTeam_Unassigned;
static int DomeColor[4];

static float DomeStart = 0.0;
static float DomeRadius = 0.0;
static float DomePreviousGameTime = 0.0;
static float DomePlayerTime[MAXTF2PLAYERS] = {0.0, ...};
static bool DomePlayerOutside[MAXTF2PLAYERS] = {false, ...};
static Handle DomeTimerBleed = null;

void Dome_PluginStart()
{
	HookEntityOutput("tf_logic_arena", "OnCapEnabled", Dome_OnCapEnabled);

	HookEntityOutput("team_control_point", "OnOwnerChangedToTeam1", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnOwnerChangedToTeam2", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapReset", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapTeam1", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapTeam2", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnCapTeam1", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnCapTeam2", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnEndCap", Dome_BlockOutput);
}

void Dome_MapStart()
{
	DomeAssets = true;

	for(int i; i < sizeof(Downloads); i++)
	{
		if(!FileExists(Downloads[i], true))
		{
			DomeAssets = false;

			if(Cvar[CaptureDome].FloatValue > 0.0)
				LogError("[Dome] File '%s' does not exist", Downloads[i]);
			
			break;
		}

		AddFileToDownloadsTable(Downloads[i]);
	}

	if(DomeAssets)
	{
		PrecacheSound(DOME_START_SOUND);
		PrecacheSound(DOME_NEARBY_SOUND);
	}
}

bool Dome_Enabled()
{
	return (DomeAssets && Cvar[CaptureDome].FloatValue > 0.0);
}

void Dome_EntityCreated(int entity, const char[] classname)
{
	if(!Dome_Enabled())
		return;
	
	if(StrEqual(classname, "team_control_point_master"))
	{
		SDKHook(entity, SDKHook_Spawn, Dome_MasterSpawn);
	}
	else if(StrEqual(classname, "trigger_capture_area"))
	{
		SDKHook(entity, SDKHook_Spawn, Dome_TriggerSpawn);
	}
	else if(StrEqual(classname, "game_end"))
	{
		//Superceding SetWinningTeam causes some maps to force a map change on capture
		AcceptEntityInput(entity, "Kill");
	}
}

static void Dome_MasterSpawn(int master)
{
	//Prevent round win from capture
	DispatchKeyValue(master, "cpm_restrict_team_cap_win", "1");
}

static void Dome_TriggerSpawn(int trigger)
{
	//If mp_capstyle is set to 1, team_numcap_ keyvalues are used in the captime calculations
	DispatchKeyValue(trigger, "team_numcap_2", "1");
	DispatchKeyValue(trigger, "team_numcap_3", "1");
}

static Action Dome_OnCapEnabled(const char[] output, int caller, int activator, float delay)
{
	if(Dome_Enabled())
		Dome_Start();
	
	return Plugin_Continue;
}

static Action Dome_BlockOutput(const char[] output, int caller, int activator, float delay)
{
	if(!Dome_Enabled())
		return Plugin_Continue;

	//Always block this function, maps may assume round ended
	return Plugin_Handled;
}

void Dome_RoundSetup()
{
	if(!Dome_Enabled())
		return;
	
	int dome = EntRefToEntIndex(DomeEntRef);
	if(IsValidEntity(DomeEntRef))
	{
		if(dome>MaxClients)
			RemoveEntity(dome);
	}

	DomeEntRef = 0;
	Dome_SetTeam(TFTeam_Unassigned);
	
	DomeStart = 0.0;
	DomeRadius = 0.0;
	DomePreviousGameTime = 0.0;
	DomeTimerBleed = null;
	
	for(int client = 1; client <= MaxClients; client++)
		DomePlayerOutside[client] = false;
}

static bool Dome_Start(int entity = 0)
{
	if(!Dome_Enabled())
		return false;
	
	if(DomeStart != 0.0)	//Check if we already have dome enabled, if so return false
		return false;

	if(entity <= MaxClients)
	{
		entity = FindEntityByClassname(-1, "team_control_point");
		if(entity <= MaxClients)
			return false;
	}
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", DomeCP);
	
	//Create dome prop
	int dome = CreateEntityByName("prop_dynamic");
	if(dome == -1)
		return false;
	
	DomeRadius = DOME_START_RADIUS;
	
	DispatchKeyValueVector(dome, "origin", DomeCP);						//Set origin to CP
	DispatchKeyValue(dome, "model", "models/kirillian/brsphere_huge.mdl");	//Set model
	DispatchKeyValue(dome, "disableshadows", "1");							//Disable shadow
	SetEntPropFloat(dome, Prop_Send, "m_flModelScale", SquareRoot(DomeRadius / DOME_PROP_RADIUS));	//Calculate model scale
	
	DispatchSpawn(dome);
	
	SetEntityRenderMode(dome, RENDER_TRANSCOLOR);
	SetEntityRenderColor(dome, DomeColor[0], DomeColor[1], DomeColor[2], 0);
	DHook_SetAlwaysTransmit(dome);
	
	GameRules_SetPropFloat("m_flCapturePointEnableTime", 0.0);
	DomeStart = GetGameTime();
	
	DomeEntRef = EntIndexToEntRef(dome);
	RequestFrame(Dome_Frame_Prepare);
	return true;
}

void Dome_SetTeam(int team)
{
	DomeTeamOwner = team;
	
	//Get new dome color
	switch(team)
	{
		case TFTeam_Red: DomeColor = {255, 0, 0, 255};
		case TFTeam_Blue: DomeColor = {0, 0, 255, 255};
		default: DomeColor = {192, 192, 192, 255};
	}
	
	//Set dome ent to new color
	int entity = EntRefToEntIndex(DomeEntRef);
	if(entity != -1)
	{
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, DomeColor[0], DomeColor[1], DomeColor[2], DomeColor[3]);
	}
	
	//Update CP to new owner
	entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "team_control_point")) > MaxClients)
	{
		SetVariantInt(team);
		AcceptEntityInput(entity, "SetOwner", 0, 0);
	}
	
	//Update CP model skin
	int prop = MaxClients+1;
	while((prop = FindEntityByClassname(prop, "prop_dynamic")) > MaxClients)
	{
		if(Dome_IsDomeProp(prop))
		{
			switch(team)
			{
				case TFTeam_Red: SetEntProp(prop, Prop_Send, "m_nSkin", 1);
				case TFTeam_Blue: SetEntProp(prop, Prop_Send, "m_nSkin", 2);
				default: SetEntProp(prop, Prop_Send, "m_nSkin", 0);
			}
		}
	}
	
	//Reset time player in dome
	for(int client = 1; client <= MaxClients; client++)
		DomePlayerTime[client] = 0.0;
}

static void Dome_Frame_Prepare()
{
	if(DomeStart == 0.0)
		return;

	int dome = EntRefToEntIndex(DomeEntRef);
	if(!IsValidEntity(dome))
		return;

	float time = GetGameTime() - DomeStart;

	if(time < DOME_PERPARE_DURATION)
	{
		//Calculate transparent to dome during prepare, i should also redo this
		float render = time;
		
		while(render > 1.0)
			render -= 1.0;
		
		if(render > 0.5)
			render = (1 - render);
		
		render *= 2 * float(DomeColor[3]);
		SetEntityRenderColor(dome, DomeColor[0], DomeColor[1], DomeColor[2], RoundToFloor(render));
		
		//Create fade to players near/outside of dome
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				if(team <= TFTeam_Spectator || team == DomeTeamOwner)
					continue;
				
				// 0.0 = centre of CP
				//<1.0 = inside dome
				// 1.0 = at border of dome
				//>1.0 = outside of dome 
				float distanceMultiplier = Dome_GetDistance(client) / DomeRadius;
				
				if(distanceMultiplier > DOME_FADE_START_MULTIPLIER)
				{
					float alpha;
					if(distanceMultiplier > 1.0)
						alpha = DOME_FADE_ALPHA_MAX * (render/255.0);
					else
						alpha = (distanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX * (render/255.0);
					
					CreateFade(client, _, DomeColor[0], DomeColor[1], DomeColor[2], RoundToNearest(alpha));
				}
			}
		}
		
		RequestFrame(Dome_Frame_Prepare);
	}
	else
	{
		//Start the shrink
		SetEntityRenderColor(dome, DomeColor[0], DomeColor[1], DomeColor[2], DomeColor[3]);
		DomeTimerBleed = CreateTimer(0.5, Dome_TimerBleed, _, TIMER_REPEAT);
		
		DomePreviousGameTime = GetGameTime();
		RequestFrame(Dome_Frame_Shrink);
	}
}

static void Dome_Frame_Shrink()
{
	if(DomeStart == 0.0)
		return;

	int dome = EntRefToEntIndex(DomeEntRef);
	if(!IsValidEntity(dome))
		return;
	
	Dome_UpdateRadius();
	SetEntPropFloat(dome, Prop_Send, "m_flModelScale", SquareRoot(DomeRadius / DOME_PROP_RADIUS));

	//Give client bleed if outside of dome
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			// 0.0 = centre of CP
			//<1.0 = inside dome
			// 1.0 = at border of dome
			//>1.0 = outside of dome
			int team = GetClientTeam(client);
			float distanceMultiplier = Dome_GetDistance(client) / DomeRadius;
			
			if(distanceMultiplier > 1.0 && team > TFTeam_Spectator && team != DomeTeamOwner)
			{
				//Client is outside of dome, state that player is outside of dome
				DomePlayerOutside[client] = true;
				
				//Add time on how long player have been outside of dome
				DomePlayerTime[client] += GetGameTime() - DomePreviousGameTime;
				
				//give bleed if havent been given one
				if(!TF2_IsPlayerInCondition(client, TFCond_Bleeding))
					TF2_MakeBleed(client, client, 9999.0);	//Does no damage, ty sourcemod
			}
			else if(DomePlayerOutside[client])
			{
				//Client is not outside of dome, remove bleed
				TF2_RemoveCondition(client, TFCond_Bleeding);
				DomePlayerOutside[client] = false;
			}
			
			//Create fade
			if(distanceMultiplier > DOME_FADE_START_MULTIPLIER && team > TFTeam_Spectator && team != DomeTeamOwner)
			{
				float alpha;
				if(distanceMultiplier > 1.0)
					alpha = float(DOME_FADE_ALPHA_MAX);
				else
					alpha = (distanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX;
				
				CreateFade(client, _, DomeColor[0], DomeColor[1], DomeColor[2], RoundToNearest(alpha));
			}
		}
	}

	DomePreviousGameTime = GetGameTime();

	RequestFrame(Dome_Frame_Shrink);
}

static Action Dome_TimerBleed(Handle timer)
{
	if(DomeTimerBleed != timer)
		return Plugin_Stop;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			int team = GetClientTeam(client);
			if(team <= TFTeam_Spectator || team == DomeTeamOwner)
				continue;
			
			StopSound(client, SNDCHAN_AUTO, DOME_NEARBY_SOUND);
			
			//Check if player is outside of dome
			if(DomePlayerOutside[client])
			{
				//Calculate damage, the longer the player is outside of the dome, the more damage it deals
				float fdamage = Pow(2.0, DomePlayerTime[client]);
				
				if(fdamage < 65.0)
					fdamage = 65.0;
				
				//Deal damage
				float health = float(GetClientHealth(client));
				if(health < fdamage)
				{
					SDKHooks_TakeDamage(client, 0, 0, fdamage, DMG_PREVENT_PHYSICS_FORCE);
				}
				else
				{
					SetEntityHealth(client, RoundToCeil(health-fdamage));
				}
				EmitSoundToClient(client, DOME_NEARBY_SOUND);
			}
		}
	}

	//Deal damage to engineer buildings
	
	int entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "obj_*")) > MaxClients)
	{
		if(Dome_GetDistance(entity) <= DomeRadius)
			continue;
		
		if(GetEntProp(entity, Prop_Send, "m_bCarried"))
			continue;
		
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == DomeTeamOwner)
			continue;
		
		SetVariantInt(15);
		AcceptEntityInput(entity, "RemoveHealth");
	}
	
	return Plugin_Continue;
}

static void Dome_UpdateRadius()
{
	//Get current game time
	float gameTime = GetGameTime();
	float gameTimeDifference = gameTime - DomePreviousGameTime;
	
	//Calculate speed dome should be
	float speed = DOME_START_RADIUS / Cvar[CaptureDome].FloatValue;
	
	//Calculate new radius from speed and time
	float radius = DomeRadius - (speed * gameTimeDifference);
	
	//Check if we already reached min value
	if(radius < 0.0)
		radius = 0.0;
	
	//Update global variable
	DomeRadius = radius;
}

static float Dome_GetDistance(int entity)
{
	float pos[3];
	
	//Client
	if(0 < entity <= MaxClients && IsClientInGame(entity) && IsPlayerAlive(entity))
		GetClientEyePosition(entity, pos);
	
	//Buildings
	else if(IsValidEntity(entity))
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
	else
		return -1.0;
	
	return GetVectorDistance(pos, DomeCP);
}

static bool Dome_IsDomeProp(int prop)
{
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(prop, Prop_Data, "m_ModelName", model, sizeof(model));
			
	return StrEqual(model, "models/props_gameplay/cap_point_base.mdl") || StrEqual(model, "models/props_doomsday/cap_point_small.mdl");
}
