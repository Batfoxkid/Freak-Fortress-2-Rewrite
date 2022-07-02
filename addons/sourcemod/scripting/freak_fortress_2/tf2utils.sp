/*
	void TF2U_PluginLoad()
	void TF2U_PluginStart()
	void TF2U_LibraryAdded(const char[] name)
	void TF2U_LibraryRemoved(const char[] name)
	bool TF2U_GetWearable(int client, int &entity, int &index)
	int TF2U_GetMaxOverheal(int client)
	void TF2U_EquipPlayerWearable(int client, int entity)
*/

#tryinclude <tf2utils>

#pragma semicolon 1

#define TF2U_LIBRARY	"nosoop_tf2utils"

#if defined __nosoop_tf2_utils_included
static bool Loaded;
#endif

void TF2U_PluginLoad()
{
	#if defined __nosoop_tf2_utils_included
	MarkNativeAsOptional("TF2Util_GetPlayerWearableCount");
	MarkNativeAsOptional("TF2Util_GetPlayerWearable");
	MarkNativeAsOptional("TF2Util_GetPlayerMaxHealthBoost");
	MarkNativeAsOptional("TF2Util_EquipPlayerWearable");
	#endif
}

void TF2U_PluginStart()
{
	#if defined __nosoop_tf2_utils_included
	Loaded = LibraryExists(TF2U_LIBRARY);
	#endif
}

stock void TF2U_LibraryAdded(const char[] name)
{
	#if defined __nosoop_tf2_utils_included
	if(!Loaded && StrEqual(name, TF2U_LIBRARY))
		Loaded = true;
	#endif
}

stock void TF2U_LibraryRemoved(const char[] name)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded && StrEqual(name, TF2U_LIBRARY))
		Loaded = false;
	#endif
}

stock bool TF2U_GetWearable(int client, int &entity, int &index)
{
	/*#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		int length = TF2Util_GetPlayerWearableCount(client);
		while(index < length)
		{
			entity = TF2Util_GetPlayerWearable(client, index++);
			if(entity != -1)
				return true;
		}
	}
	else
	#endif*/
	{
		if(index >= -1 && index <= MaxClients)
			index = MaxClients + 1;
		
		if(index > -2)
		{
			while((index = FindEntityByClassname(index, "tf_wear*")) != -1)
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
		while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
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

stock int TF2U_GetMaxOverheal(int client)
{
	if(Client(client).IsBoss)
		return Client(client).MaxHealth * Client(client).MaxLives;
	
	// 75% overheal from 50%
	#if defined __nosoop_tf2_utils_included
	if(Loaded)
		return TF2Util_GetPlayerMaxHealthBoost(client, true) / 8 * 6;
	#endif
	
	int maxhealth = SDKCall_GetMaxHealth(client);
	float maxoverheal = float(SDKCall_GetMaxHealth(client)) * 0.75;
	maxoverheal *= Attributes_FindOnPlayer(client, 800, true, 1.0);
	maxoverheal *= Attributes_FindOnWeapon(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), 853, true, 1.0);
	return maxhealth + (RoundFloat(maxoverheal / 5.0) * 5);
}

void TF2U_EquipPlayerWearable(int client, int entity)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		TF2Util_EquipPlayerWearable(client, entity);
	}
	else
	#endif
	{
		SDKCall_EquipWearable(client, entity);
	}
}