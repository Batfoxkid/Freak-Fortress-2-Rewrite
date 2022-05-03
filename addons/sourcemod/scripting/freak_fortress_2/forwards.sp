/*
	void Forward_PluginLoad()
	void Forward_OnBossCreated(int client, ConfigMap cfg)
	void Forward_OnBossRemoved(int client)
	bool Forward_OnAbilityPre(int client, const char[] ability, ConfigMap cfg, bool &result)
	void Forward_OnAbility(int client, const char[] ability, ConfigMap cfg, const char[] plugin)
	void Forward_OnAbilityPost(int client, const char[] ability, ConfigMap cfg)
	Action Forward_OnAliveChange()
	Action Forward_OnBossPrecache(ConfigMap cfg, bool &precache)
	void Forward_OnBossPrecached(ConfigMap cfg, bool precache, int index)
*/

#pragma semicolon 1

static GlobalForward BossCreated;
static GlobalForward BossRemoved;
static GlobalForward AbilityPre;
static GlobalForward AbilityAll;
static GlobalForward AbilityPost;
static GlobalForward AliveChangePre;
static GlobalForward AliveChangePost;
static GlobalForward BossPrecachePre;
static GlobalForward BossPrecachePost;

void Forward_PluginLoad()
{
	BossCreated = new GlobalForward("FF2R_OnBossCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	BossRemoved = new GlobalForward("FF2R_OnBossRemoved", ET_Ignore, Param_Cell);
	AbilityPre = new GlobalForward("FF2R_OnAbilityPre", ET_Event, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
	AbilityAll = new GlobalForward("FF2R_OnAbility", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	AbilityPost = new GlobalForward("FF2R_OnAbilityPost", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	AliveChangePre = new GlobalForward("FF2R_OnAliveChange", ET_Event, Param_Array, Param_Array);
	AliveChangePost = new GlobalForward("FF2R_OnAliveChanged", ET_Ignore, Param_Array, Param_Array);
	BossPrecachePre = new GlobalForward("FF2R_OnBossPrecache", ET_Event, Param_Cell, Param_CellByRef);
	BossPrecachePost = new GlobalForward("FF2R_OnBossPrecached", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

void Forward_OnBossCreated(int client, ConfigMap cfg, bool setup)
{
	Call_StartForward(BossCreated);
	Call_PushCell(client);
	Call_PushCell(cfg);
	Call_PushCell(setup);
	Call_Finish();
}

void Forward_OnBossRemoved(int client)
{
	Call_StartForward(BossRemoved);
	Call_PushCell(client);
	Call_Finish();
}

bool Forward_OnAbilityPre(int client, const char[] ability, ConfigMap cfg, bool &result)
{
	bool result2 = result;
	
	Action action;
	Call_StartForward(AbilityPre);
	Call_PushCell(client);
	Call_PushString(ability);
	Call_PushCell(cfg);
	Call_PushCellRef(result2);
	Call_Finish(action);
	
	switch(action)
	{
		case Plugin_Changed, Plugin_Handled:
			result = result2;
		
		case Plugin_Stop:
			result = false;
	}
	
	return action < Plugin_Handled;
}

void Forward_OnAbility(int client, const char[] ability, ConfigMap cfg, const char[] plugin)
{
	if(plugin[0])
	{
		char buffer[PLATFORM_MAX_PATH];
		Handle iter = GetPluginIterator();
		while(MorePlugins(iter))
		{
			Handle plugi = ReadPlugin(iter);
			GetPluginFilename(plugi, buffer, sizeof(buffer));
			
			int highest = -1;
			for(int i = strlen(buffer)-1; i > 0; i--)
			{
				if(buffer[i] == '/' || buffer[i] == '\\')
				{
					highest = i;
					break;
				}
			}
			
			if(StrEqual(buffer[highest+1], plugin))
			{
				Function func = GetFunctionByName(plugi, "FF2R_OnAbility");
				if(func != INVALID_FUNCTION)
				{
					Call_StartFunction(plugi, func);
					Call_PushCell(client);
					Call_PushString(ability);
					Call_PushCell(cfg);
					Call_Finish();
				}
				
				delete iter;
				return;
			}
		}
		
		delete iter;
		
		if(Client(client).Cfg.Get("filename", buffer, sizeof(buffer)))
			LogError("[Boss] Plugin '%s' is missing for '%s' '%s'", plugin, buffer, ability);
	}
	
	Call_StartForward(AbilityAll);
	Call_PushCell(client);
	Call_PushString(ability);
	Call_PushCell(cfg);
	Call_Finish();
}

void Forward_OnAbilityPost(int client, const char[] ability, ConfigMap cfg)
{
	Call_StartForward(AbilityPost);
	Call_PushCell(client);
	Call_PushString(ability);
	Call_PushCell(cfg);
	Call_Finish();
}

Action Forward_OnAliveChange()
{
	int alive[TFTeam_MAX], maxalive[TFTeam_MAX];
	for(int i; i < TFTeam_MAX; i++)
	{
		alive[i] = PlayersAlive[i];
		maxalive[i] = MaxPlayersAlive[i];
	}
	
	Action action;
	Call_StartForward(AliveChangePre);
	Call_PushArrayEx(alive, sizeof(alive), SM_PARAM_COPYBACK);
	Call_PushArrayEx(maxalive, sizeof(maxalive), SM_PARAM_COPYBACK);
	Call_Finish(action);
	
	if(action >= Plugin_Changed)
	{
		for(int i; i < TFTeam_MAX; i++)
		{
			PlayersAlive[i] = alive[i];
			MaxPlayersAlive[i] = maxalive[i];
		}
	}
	
	if(action < Plugin_Stop)
	{
		Call_StartForward(AliveChangePost);
		Call_PushArray(PlayersAlive, sizeof(PlayersAlive));
		Call_PushArray(MaxPlayersAlive, sizeof(MaxPlayersAlive));
		Call_Finish();
	}
	return action;
}

Action Forward_OnBossPrecache(ConfigMap cfg, bool &precache)
{
	bool precache2 = precache;
	
	Action action;
	Call_StartForward(BossPrecachePre);
	Call_PushCell(cfg);
	Call_PushCellRef(precache2);
	Call_Finish(action);
	
	if(action >= Plugin_Changed)
		precache = precache2;
	
	return action;
}

void Forward_OnBossPrecached(ConfigMap cfg, bool precache, int index)
{
	Call_StartForward(BossPrecachePost);
	Call_PushCell(cfg);
	Call_PushCell(precache);
	Call_PushCell(index);
	Call_Finish();
}