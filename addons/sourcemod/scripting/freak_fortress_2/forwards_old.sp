/*
	void ForwardOld_Setup()
	bool ForwardOld_PreAbility(int client, const char[] plugin, const char[] ability, int slot)
	void ForwardOld_OnAbility(int client, const char[] plugin, const char[] ability)
	bool ForwardOld_OnMusic(char[] path, float &time, char[] name, char[] artist, int client)
	Action ForwardOld_OnTriggerHurt(int client, int entity, float &damage)
	bool ForwardOld_OnSpecialSelected(int client, int &special, char name[64], bool preset)
	bool ForwardOld_OnAddQueuePoints(int[] points, int size)
	bool ForwardOld_OnLoadCharacterSet(int &charset, char name[64])
	bool ForwardOld_OnLoseLife(int client)
	void ForwardOld_OnAlivePlayersChanged(int red, int blu)
	Action ForwardOld_OnBackstabbed(int client, int attacker)
	bool ForwardOld_OnMusicPerBoss(int client)
*/

#pragma semicolon 1

static GlobalForward PreAbility;
static GlobalForward OnAbility;
static GlobalForward OnMusic;
static GlobalForward OnMusic2;
static GlobalForward OnTriggerHurt;
static GlobalForward OnSpecialSelected;
static GlobalForward OnAddQueuePoints;
static GlobalForward OnLoadCharacterSet;
static GlobalForward OnLoseLife;
static GlobalForward OnAlivePlayersChanged;
static GlobalForward OnBackstabbed;
static GlobalForward OnMusicEx;
static GlobalForward OnMusicPerBoss;

void ForwardOld_PluginLoad()
{
	PreAbility = new GlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);
	OnAbility = new GlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);
	OnMusic = new GlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnMusic2 = new GlobalForward("FF2_OnMusic2", ET_Hook, Param_String, Param_FloatByRef, Param_String, Param_String);
	OnTriggerHurt = new GlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected = new GlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);
	OnAddQueuePoints = new GlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet = new GlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife = new GlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
	OnAlivePlayersChanged = new GlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);
	OnBackstabbed = new GlobalForward("FF2_OnBackStabbed", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
	OnMusicPerBoss = new GlobalForward("FF2_OnMusicPerBoss", ET_Single, Param_Cell);	// From DISC-FF Boss vs Boss
	OnMusicEx = new GlobalForward("FF2_OnMusicEx", ET_Hook, Param_String, Param_FloatByRef, Param_Cell);	// From Versus Ponyville Reborn
}

bool ForwardOld_PreAbility(int client, const char[] plugin, const char[] ability, int slot)
{
	bool result = true;
	Call_StartForward(PreAbility);
	Call_PushCell(Client(client).Index);
	Call_PushString(plugin);
	Call_PushString(ability);
	Call_PushCell(slot);
	Call_PushCellRef(result);
	Call_Finish();
	return result;
}

void ForwardOld_OnAbility(int client, const char[] plugin, const char[] ability, int status)
{
	Call_StartForward(OnAbility);
	Call_PushCell(Client(client).Index);
	Call_PushString(plugin);
	Call_PushString(ability);
	Call_PushCell(status);
	Call_Finish();
}

bool ForwardOld_OnMusic(char path[PLATFORM_MAX_PATH], float &time, char name[64], char artist[64], int client)
{
	char path2[PLATFORM_MAX_PATH], name2[64], artist2[64];
	strcopy(path2, sizeof(path2), path);
	strcopy(name2, sizeof(name2), name);
	strcopy(artist2, sizeof(artist2), artist);
	
	float time2 = time;
	
	Action action;
	Call_StartForward(OnMusic2);
	Call_PushStringEx(path2, sizeof(path2), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushFloatRef(time2);
	Call_PushStringEx(name2, sizeof(name2), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(artist2, sizeof(artist2), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	
	if(action == Plugin_Changed)
	{
		strcopy(path, sizeof(path), path2);
		strcopy(name, sizeof(name), name2);
		strcopy(artist, sizeof(artist), artist2);
		time = time2;
	}
	else if(action == Plugin_Continue)
	{
		strcopy(path2, sizeof(path2), path);
		time2 = time;
		
		Call_StartForward(OnMusic);
		Call_PushStringEx(path2, sizeof(path2), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_Finish(action);
		
		if(action == Plugin_Changed)
		{
			strcopy(path, sizeof(path), path2);
			name[0] = 0;
			artist[0] = 0;
			time = time2;
		}
		else if(action == Plugin_Continue)
		{
			strcopy(path2, sizeof(path2), path);
			time2 = time;
			
			Call_StartForward(OnMusicEx);
			Call_PushStringEx(path2, sizeof(path2), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushFloatRef(time2);
			Call_PushCell(client);
			Call_Finish(action);
			
			if(action == Plugin_Changed)
			{
				strcopy(path, sizeof(path), path2);
				name[0] = 0;
				artist[0] = 0;
				time = time2;
			}
		}
	}
	
	return action > Plugin_Changed;
}

Action ForwardOld_OnTriggerHurt(int client, int entity, float &damage)
{
	float damage2 = damage;
	
	Action action;
	Call_StartForward(OnTriggerHurt);
	Call_PushCell(Client(client).Index);
	Call_PushCell(entity);
	Call_PushFloatRef(damage2);
	Call_Finish(action);
	
	if(action == Plugin_Changed)
		damage = damage2;
	
	return action;
}

void ForwardOld_OnSpecialSelected(int boss, int &special, bool preset)
{
	char name[64];
	Bosses_GetConfig(special).Get("name", name, sizeof(name));
	
	int special2 = special;
	
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(boss);
	Call_PushCellRef(special2);
	Call_PushStringEx(name, sizeof(name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(preset);
	Call_Finish(action);
	
	if(action == Plugin_Changed)
	{
		if(name[0])
		{
			special2 = Bosses_GetByName(name, false);
			if(special2 != -1)
				special = special2;
		}
		else
		{
			special = special2;
		}
	}
}

bool ForwardOld_OnAddQueuePoints(int[] points, int size)
{
	int points2[MAXPLAYERS + 1];
	for(int i = 1; i < size; i++)
	{
		points2[i] = points[i];
	}
	
	Action action;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(points2, sizeof(points2), SM_PARAM_COPYBACK);
	Call_Finish(action);
	
	if(action > Plugin_Changed)
		return false;
	
	if(action == Plugin_Changed)
	{
		for(int i = 1; i < size; i++)
		{
			points[i] = points2[i];
		}
	}
	
	return true;
}

bool ForwardOld_OnLoadCharacterSet(int &charset, char name[64])
{
	char name2[64];
	strcopy(name2, sizeof(name2), name);
	int charset2 = charset;
	
	Action action;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(charset2);
	Call_PushStringEx(name2, sizeof(name2), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	
	if(action != Plugin_Changed)
		return false;
	
	charset = charset2;
	return view_as<bool>(strcopy(name, sizeof(name), name2));
}

Action ForwardOld_OnLoseLife(int client, int &lives, int maxlives)
{
	int lives2 = lives;
	
	Action action;
	Call_StartForward(OnLoseLife);
	Call_PushCell(Client(client).Index);
	Call_PushCellRef(lives2);
	Call_PushCell(maxlives);
	Call_Finish(action);
	
	if(action == Plugin_Changed)
		lives = lives2;
	
	return action;
}

void ForwardOld_OnAlivePlayersChanged(int red, int blu)
{
	Call_StartForward(OnAlivePlayersChanged);
	Call_PushCell(red);
	Call_PushCell(blu);
	Call_Finish();
}

Action ForwardOld_OnBackstabbed(int client, int attacker)
{
	Action action;
	Call_StartForward(OnBackstabbed);
	Call_PushCell(Client(client).Index);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_Finish(action);
	return action;
}

bool ForwardOld_OnMusicPerBoss(int client)
{
	bool result = true;
	Call_StartForward(OnMusicPerBoss);
	Call_PushCell(Client(client).Index);
	Call_Finish(result);
	Debug("ForwardOld_OnMusicPerBoss::%d", result);
	return result;
}