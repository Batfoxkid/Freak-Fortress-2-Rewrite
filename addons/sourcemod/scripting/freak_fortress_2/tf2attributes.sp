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
		if(!StrContains(classname, "tf_w") || StrEqual(classname, "tf_powerup_bottle"))
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
	float result = DEFAULT_VALUE_TEST;
	if(VScript_GetAttribute(entity, name, result))
	{
		if(result == DEFAULT_VALUE_TEST)
			return false;
		
		value = result;
		return true;
	}

	#if defined _tf2attributes_included
	if(Loaded)
	{
		if(name[0] && !TF2Attrib_IsValidAttributeName(name))
			return false;
		
		Address attrib = name[0] ? TF2Attrib_GetByName(entity, name) : TF2Attrib_GetByDefIndex(entity, index);
		if(attrib != Address_Null)
		{
			value = TF2Attrib_GetValue(attrib);
			return true;
		}
		
		// Players
		if(entity <= MaxClients)
			return false;
		
		#if defined TFED_LIBRARY
		int defindex = index == -1 ? TF2ED_TranslateAttributeNameToDefinitionIndex(name) : index;
		#elseif defined __tf_econ_data_included
		int defindex = index == -1 ? TF2Econ_TranslateAttributeNameToDefinitionIndex(name) : index;
		#else
		int defindex = index;
		#endif
		if(defindex == -1)
			return false;
		
		static int indexes[20];
		static float values[20];
		int count = TF2Attrib_GetSOCAttribs(entity, indexes, values, 20);
		for(int i; i < count; i++)
		{
			if(indexes[i] == defindex)
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
				if(indexes[i] == defindex)
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
		LogError("[!!!] Could not get attribute value, missing dependencies");
		Attrib_PrintStatus(true);
		VScript_PrintStatus(true);
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

	static bool DoneWarning;
	if(!DoneWarning)
	{
		LogError("[!!!] Could not get attribute as a string value, missing dependencies");
		Attrib_PrintStatus(true);
		DoneWarning = true;
	}
	return false;
}

static void ErrorDefIndex(int index)
{
	static bool DoneWarning;
	if(!DoneWarning)
	{
		LogError("[!!!] Could not set attribute using definition index %d", index);
		Attrib_PrintStatus(true);
		
		#if defined TFED_LIBRARY
		TFED_PrintStatus(true);
		#endif

		DoneWarning = true;
	}
}

stock void Attrib_Set(int entity, const char[] name = "", int index = -1, float value, float duration = -1.0, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded && index != -1 && (entity > MaxClients || !custom) && duration < 0.0)
	{
		TF2Attrib_SetByDefIndex(entity, index, value);
		return;
	}
	#endif

	static char buffer[256];

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
		#if defined _tf2attributes_included
		if(Loaded)
		{
			if(!TF2Attrib_IsValidAttributeName(buffer))
				return;
			
			if(custom && entity <= MaxClients)
			{
				TF2Attrib_AddCustomPlayerAttribute(entity, buffer, value, duration);
				return;
			}
			
			if(duration < 0.0)
			{
				TF2Attrib_SetByName(entity, buffer, value);
				return;
			}
		}
		#endif

		Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", %f, %f)", entity > MaxClients ? "" : "Custom", buffer, value, duration);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "RunScriptCode");
		return;
	}

	ErrorDefIndex(index);
}

stock void Attrib_SetInt(int entity, const char[] name = "", int index = -1, int value, float duration = -1.0, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded && index != -1 && (entity > MaxClients || !custom) && duration < 0.0)
	{
		TF2Attrib_SetByDefIndex(entity, index, view_as<float>(value));
		return;
	}
	#endif

	static char buffer[256];

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
		#if defined _tf2attributes_included
		if(Loaded)
		{
			if(!TF2Attrib_IsValidAttributeName(buffer))
				return;
			
			if(custom && entity <= MaxClients)
			{
				TF2Attrib_AddCustomPlayerAttribute(entity, buffer, view_as<float>(value), duration);
				return;
			}
			
			if(duration < 0.0)
			{
				TF2Attrib_SetByName(entity, buffer, view_as<float>(value));
				return;
			}
		}
		#endif

		Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", casti2f(%d), %f)", entity > MaxClients ? "" : "Custom", buffer, value, duration);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "RunScriptCode");
		return;
	}

	ErrorDefIndex(index);
}

stock bool Attrib_SetString(int entity, const char[] name = "", int index = -1, const char[] value)
{
	static char buffer[256];

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
		#if defined _tf2attributes_included
		if(Loaded)
		{
			if(!TF2Attrib_IsValidAttributeName(buffer))
				return false;
			
			return TF2Attrib_SetFromStringValue(entity, buffer, value);
		}
		#endif

		Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", %f, -1)", entity > MaxClients ? "" : "Custom", buffer, StringToFloat(value));
		SetVariantString(buffer);
		AcceptEntityInput(entity, "RunScriptCode");
		return true;
	}

	ErrorDefIndex(index);
	return false;
}

stock void Attrib_Remove(int entity, const char[] name = "", int index = -1, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded && index != -1 && (entity > MaxClients || !custom))
	{
		TF2Attrib_RemoveByDefIndex(entity, index);
		return;
	}
	#endif

	static char buffer[256];

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
		#if defined _tf2attributes_included
		if(Loaded)
		{
			if(!TF2Attrib_IsValidAttributeName(buffer))
				return;
			
			if(custom && entity <= MaxClients)
			{
				TF2Attrib_RemoveCustomPlayerAttribute(entity, buffer);
				return;
			}
			
			TF2Attrib_RemoveByName(entity, buffer);
			return;
		}
		#endif

		Format(buffer, sizeof(buffer), "self.Remove%sAttribute(\"%s\")", entity > MaxClients ? "" : "Custom", buffer);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "RunScriptCode");
		return;
	}

	ErrorDefIndex(index);
}
