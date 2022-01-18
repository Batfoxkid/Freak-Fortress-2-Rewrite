/*
	void TF2U_PluginStart()
	void TF2U_LibraryAdded(const char[] name)
	void TF2U_LibraryRemoved(const char[] name)
	bool TF2U_GetWearable(int client, int &index, int &entity)
	int TF2U_GetMaxOverheal(int client)
*/

#tryinclude <tf2utils>

#define TF2U_LIBRARY	"nosoop_tf2utils"

static bool Loaded;

void TF2U_PluginStart()
{
	Loaded = LibraryExists(TF2U_LIBRARY);
}

void TF2U_LibraryAdded(const char[] name)
{
	if(!Loaded)
		Loaded = StrEqual(name, TF2U_LIBRARY);
}

void TF2U_LibraryRemoved(const char[] name)
{
	if(Loaded)
		Loaded = !StrEqual(name, TF2U_LIBRARY);
}

bool TF2U_GetWearable(int client, int &index, int &entity)
{
	if(Loaded)
	{
		int length = TF2Util_GetPlayerWearableCount(client);
		while(index < length)
		{
			entity = TF2Util_GetPlayerWearable(client, index++);
			if(entity > MaxClients)
				return true;
		}
	}
	else
	{
		if(index <= MaxClients)
			index = MaxClients + 1;
		
		if(index > -2)
		{
			while((index=FindEntityByClassname(index, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
				{
					entity = index;
					return true;
				}
			}
			
			index = -(MaxClients + 1);
		}
		
		entity = -index;
		while((entity=FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				index = -entity;
				return true;
			}
		}
	}
	return false;
}

int TF2U_GetMaxOverheal(int client)
{
	if(Client(client).IsBoss)
		return Client(client).MaxHealth * Client(client).MaxLives;
	
	if(Loaded)
		return TF2Util_GetPlayerMaxHealthBoost(client);
	
	float maxhealth = float(SDKCall_GetMaxHealth(client));
	maxhealth *= Attributes_FindOnPlayer(client, 800, true, 1.0);
	maxhealth *= Attributes_FindOnWeapon(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), 853, true, 1.0);
	return RoundFloat(maxhealth);
}

float TF2U_GetClientCondDuration(int client, TFCond cond)
{
	if(Loaded)
		return TF2Util_GetPlayerConditionDuration(client, cond);
	
	return 0.0;
}

void TF2U_SetClientCondDuration(int client, TFCond cond, float duration)
{
	if(Loaded)
		TF2Util_SetPlayerConditionDuration(client, cond, duration);
}

int TF2U_GetClientCondProvider(int client, TFCond cond)
{
	if(Loaded)
		return TF2Util_GetPlayerConditionProvider(client, cond);
	
	return INVALID_ENT_REFERENCE;
}