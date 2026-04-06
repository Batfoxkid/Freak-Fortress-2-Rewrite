#tryinclude <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define ATTRIB_LIBRARY	"tf2attributes"

#if !defined DEFAULT_VALUE_TEST
#define DEFAULT_VALUE_TEST	-69420.69
#endif

#if defined _tf2attributes_included
static bool Loaded;
#endif

void Attrib_PluginLoad()
{
	MarkNativeAsOptional("TF2Attrib_SetFromStringValue");
	MarkNativeAsOptional("TF2Attrib_UnsafeGetStringValue");
}

void Attrib_PluginStart()
{
	#if defined _tf2attributes_included
	Loaded = LibraryExists(ATTRIB_LIBRARY);
	#endif
}

public void Attrib_LibraryAdded(const char[] name)
{
	#if defined _tf2attributes_included
	if(!Loaded && StrEqual(name, ATTRIB_LIBRARY))
		Loaded = true;
	#endif
}

public void Attrib_LibraryRemoved(const char[] name)
{
	#if defined _tf2attributes_included
	if(Loaded && StrEqual(name, ATTRIB_LIBRARY))
		Loaded = false;
	#endif
}

stock bool Attrib_Loaded()
{
	#if defined _tf2attributes_included
	return Loaded;
	#else
	return false;
	#endif
}

stock void Attrib_PrintStatus(bool error = false)
{
	if(error)
	{
		#if defined _tf2attributes_included
		LogError("'%s' is %sloaded", ATTRIB_LIBRARY, Loaded ? "" : "not ");
		#else
		LogError("'%s' not compiled", ATTRIB_LIBRARY);
		#endif
	}
	else
	{
		#if defined _tf2attributes_included
		PrintToServer("'%s' is %sloaded", ATTRIB_LIBRARY, Loaded ? "" : "not ");
		#else
		PrintToServer("'%s' not compiled", ATTRIB_LIBRARY);
		#endif
	}
}

stock float Attrib_FindOnPlayer(int client, const char[] name = "", int index = -1, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, index, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
	{
		if(Attrib_Get(entity, name, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}

	bool provideActive = StrEqual(name, "provide on active");
	
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	while(TF2_GetItem(client, entity, i))
	{
		if(!provideActive && active != entity && Attrib_Get(entity, "provide on active", 128, value) && value)
			continue;
		
		if(Attrib_Get(entity, name, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

stock float Attrib_FindOnWeapon(int client, int entity, const char[] name = "", int index = -1, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, index, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
	{
		if(Attrib_Get(wear, name, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	if(entity != -1)
	{
		char classname[18];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "tf_wea") || !StrContains(classname, "tf2c_wea") || StrEqual(classname, "tf_powerup_bottle"))
		{
			if(Attrib_Get(entity, name, index, value))
			{
				if(!found)
				{
					total = value;
				}
				else if(multi)
				{
					total *= value;
				}
				else
				{
					total += value;
				}
			}
		}
	}
	
	return total;
}

stock bool Attrib_Get(int entity, const char[] name = "", int index = -1, float &value = 0.0)
{
	char buffer[64];
	if(name[0])
	{
		strcopy(buffer, sizeof(buffer), name);
	}
	else
	{
		#if defined TFED_LIBRARY
		TF2ED_GetAttributeName(index, buffer, sizeof(buffer));
		#elseif defined __tf_econ_data_included
		TF2Econ_GetAttributeName(index, buffer, sizeof(buffer));
		#endif
	}
	
	if(buffer[0])
		return VScript_GetAttribute(entity, buffer, value);

	#if defined _tf2attributes_included
	if(Loaded)
	{
		Address attrib = TF2Attrib_GetByDefIndex(entity, index);
		if(attrib != Address_Null)
		{
			value = TF2Attrib_GetValue(attrib);
			return true;
		}
		
		// Players
		if(entity <= MaxClients)
			return false;
		
		static int indexes[20];
		static float values[20];
		int count = TF2Attrib_GetSOCAttribs(entity, indexes, values, 20);
		for(int i; i < count; i++)
		{
			if(indexes[i] == index)
			{
				value = values[i];
				return true;
			}
		}
		
		if(!GetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", 1))
		{
			count = TF2Attrib_GetStaticAttribs(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), indexes, values, 20);
			for(int i; i < count; i++)
			{
				if(indexes[i] == index)
				{
					value = values[i];
					return true;
				}
			}
		}

		return false;
	}
	#endif
	
	static bool DoneWarning;
	if(!DoneWarning)
	{
		LogError("[!!!] Could not get attribute with definition index \"%d\", use named attributes or add missing dependencies", index);
		Attrib_PrintStatus(true);

		#if defined TFED_LIBRARY
		TFED_PrintStatus(true);
		#endif

		DoneWarning = true;
	}
	return false;
}

stock bool Attrib_GetString(int entity, const char[] name = "", int index = -1, char[] buffer, int length)
{
	#if defined _tf2attributes_included
	if(Loaded)
	{
		Address address = Address_Null;
		
		if(index != -1)
		{
			address = TF2Attrib_GetByDefIndex(entity, index);
		}
		else if(TF2Attrib_IsValidAttributeName(name))
		{
			address = TF2Attrib_GetByName(entity, name);
		}

		if(address == Address_Null)
			return false;
		
		return view_as<bool>(TF2Attrib_UnsafeGetStringValue(address, buffer, length));
	}
	#endif

	float value;
	if(!Attrib_Get(entity, name, index, value))
		return false;
	
	FloatToString(value, buffer, length);
	return true;
}

static void ErrorDefIndex(int index)
{
	static bool DoneWarning;
	if(!DoneWarning)
	{
		LogError("[!!!] Could not set attribute using definition index %d, use named attributes or add missing dependencies", index);
		Attrib_PrintStatus(true);
		
		#if defined TFED_LIBRARY
		TFED_PrintStatus(true);
		#endif

		DoneWarning = true;
	}
}

stock void Attrib_Set(int entity, const char[] name = "", int index = -1, float value)
{
	char buffer[64];
	if(name[0])
	{
		strcopy(buffer, sizeof(buffer), name);
	}
	else
	{
		#if defined TFED_LIBRARY
		TF2ED_GetAttributeName(index, buffer, sizeof(buffer));
		#elseif defined __tf_econ_data_included
		TF2Econ_GetAttributeName(index, buffer, sizeof(buffer));
		#endif
	}
	
	if(buffer[0])
	{
		VScript_SetAttribute(entity, buffer, value);
		return;
	}
	
	#if defined _tf2attributes_included
	if(Loaded && index != -1)
	{
		TF2Attrib_SetByDefIndex(entity, index, value);
		return;
	}
	#endif

	ErrorDefIndex(index);
}

stock void Attrib_SetInt(int entity, const char[] name = "", int index = -1, int value)
{
	char buffer[64];
	if(name[0])
	{
		strcopy(buffer, sizeof(buffer), name);
	}
	else
	{
		#if defined TFED_LIBRARY
		TF2ED_GetAttributeName(index, buffer, sizeof(buffer));
		#elseif defined __tf_econ_data_included
		TF2Econ_GetAttributeName(index, buffer, sizeof(buffer));
		#endif
	}
	
	if(buffer[0])
	{
		VScript_SetAttributeInt(entity, buffer, value);
		return;
	}
	
	#if defined _tf2attributes_included
	if(Loaded && index != -1)
	{
		TF2Attrib_SetByDefIndex(entity, index, view_as<float>(value));
		return;
	}
	#endif

	ErrorDefIndex(index);
}

stock void Attrib_SetString(int entity, const char[] name = "", int index = -1, const char[] value)
{
	#if defined _tf2attributes_included
	char buffer[64];
	if(name[0])
	{
		strcopy(buffer, sizeof(buffer), name);
	}
	else
	{
		#if defined TFED_LIBRARY
		TF2ED_GetAttributeName(index, buffer, sizeof(buffer));
		#elseif defined __tf_econ_data_included
		TF2Econ_GetAttributeName(index, buffer, sizeof(buffer));
		#endif
	}

	if(buffer[0])
	{
		if(Loaded)
		{
			if(TF2Attrib_SetFromStringValue(entity, buffer, value))
			{
				VScript_SetAttributeTable(entity, buffer, StringToFloat(value));
				return;
			}
		}
	}
	Attrib_Set(entity, buffer, index, StringToFloat(value));
	#else
	Attrib_Set(entity, name, index, StringToFloat(value));
	#endif
}

stock void Attrib_Remove(int entity, const char[] name = "", int index = -1)
{
	char buffer[64];
	if(name[0])
	{
		strcopy(buffer, sizeof(buffer), name);
	}
	else
	{
		#if defined TFED_LIBRARY
		TF2ED_GetAttributeName(index, buffer, sizeof(buffer));
		#elseif defined __tf_econ_data_included
		TF2Econ_GetAttributeName(index, buffer, sizeof(buffer));
		#endif
	}
	
	if(buffer[0])
	{
		VScript_RemoveAttribute(entity, buffer);
		return;
	}
	
	#if defined _tf2attributes_included
	if(Loaded && index != -1)
	{
		TF2Attrib_RemoveByDefIndex(entity, index);
		return;
	}
	#endif

	ErrorDefIndex(index);
}
