/*
	void Forward_PluginLoad()
	void Forward_OnBossCreated(int client, ConfigMap cfg)
	void Forward_OnBossRemoved(int client)
	bool Forward_OnAbilityPre(int client, const char[] ability, const char[] plugin, ConfigMap cfg, bool &result)
	void Forward_OnAbility(int client, const char[] ability, const char[] plugin, ConfigMap cfg, const char[] pluginfull)
	void Forward_OnAbilityPost(int client, const char[] ability, const char[] plugin, ConfigMap cfg)
*/

static GlobalForward BossCreated;
static GlobalForward BossRemoved;
static GlobalForward AbilityPre;
static GlobalForward AbilityAll;
static GlobalForward AbilityPost;

void Forward_PluginLoad()
{
	BossCreated = new GlobalForward("FF2R_OnBossCreated", ET_Ignore, Param_Cell, Param_Cell);
	BossRemoved = new GlobalForward("FF2R_OnBossRemoved", ET_Ignore, Param_Cell);
	AbilityPre = new GlobalForward("FF2R_OnAbilityPre", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);
	AbilityAll = new GlobalForward("FF2R_OnAbility", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
	AbilityPost = new GlobalForward("FF2R_OnAbilityPost", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
}

void Forward_OnBossCreated(int client, ConfigMap cfg)
{
	Call_StartForward(BossCreated);
	Call_PushCell(client);
	Call_PushCell(cfg);
	Call_Finish();
}

void Forward_OnBossRemoved(int client)
{
	Call_StartForward(BossRemoved);
	Call_PushCell(client);
	Call_Finish();
}

bool Forward_OnAbilityPre(int client, const char[] ability, const char[] plugin, ConfigMap cfg, bool &result)
{
	bool result2 = result;
	
	Action action;
	Call_StartForward(AbilityPre);
	Call_PushCell(client);
	Call_PushString(ability);
	Call_PushString(plugin);
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

void Forward_OnAbility(int client, const char[] ability, const char[] plugin, ConfigMap cfg, const char[] pluginfull)
{
	if(plugin[0])
	{
		char buffer[PLATFORM_MAX_PATH];
		Handle iter = GetPluginIterator();
		while(MorePlugins(iter))
		{
			Handle plugi = ReadPlugin(iter);
			GetPluginFilename(plugi, buffer, sizeof(buffer));
			SplitString(buffer, ".smx", buffer, sizeof(buffer));
			
			int highest = -1;
			for(int i = strlen(buffer)-1; i>0; i--)
			{
				if(buffer[i] == '/' || buffer[i] == '\\')
				{
					highest = i;
					break;
				}
			}
			
			if(StrEqual(buffer[highest+1], pluginfull))
			{
				Function func = GetFunctionByName(plugi, "FF2R_OnAbility");
				if(func != INVALID_FUNCTION)
				{
					Call_StartFunction(plugi, func);
					Call_PushCell(client);
					Call_PushString(ability);
					Call_PushString(plugin);
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
	Call_PushString(plugin);
	Call_PushCell(cfg);
	Call_Finish();
}

void Forward_OnAbilityPost(int client, const char[] ability, const char[] plugin, ConfigMap cfg)
{
	Call_StartForward(AbilityPost);
	Call_PushCell(client);
	Call_PushString(ability);
	Call_PushString(plugin);
	Call_PushCell(cfg);
	Call_Finish();
}