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

stock void Attrib_PrintStatus()
{
	#if defined _tf2attributes_included
	PrintToServer("'%s' is %sloaded", ATTRIB_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", ATTRIB_LIBRARY);
	#endif
}

stock float Attrib_FindOnPlayer(int client, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
	{
		if(Attrib_Get(entity, name, value))
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
		if(!provideActive && active != entity && Attrib_Get(entity, "provide on active", value) && value)
			continue;
		
		if(Attrib_Get(entity, name, value))
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

stock float Attrib_FindOnWeapon(int client, int entity, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
	{
		if(Attrib_Get(wear, name, value))
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
			if(Attrib_Get(entity, name, value))
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

stock bool Attrib_Get(int entity, const char[] name, float &value = 0.0)
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
	if(Loaded && TF2Attrib_IsValidAttributeName(name))
	{
		Address attrib = TF2Attrib_GetByName(entity, name);
		if(attrib != Address_Null)
		{
			value = TF2Attrib_GetValue(attrib);
			return true;
		}
		
		// Players
		if(entity <= MaxClients)
			return false;
		
		int index = TF2ED_TranslateAttributeNameToDefinitionIndex(name);
		if(index == -1)
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
	}
	#endif
	
	return false;
}

public bool Attrib_GetString(int entity, const char[] name, char[] buffer, int length)
{
	#if defined _tf2attributes_included
	if(Loaded && TF2Attrib_IsValidAttributeName(name))
	{
		Address address = TF2Attrib_GetByName(entity, name);
		if(address != Address_Null)
			return view_as<bool>(TF2Attrib_UnsafeGetStringValue(address, buffer, length));
	}
	#endif

	return false;
}

stock void Attrib_Set(int entity, const char[] name, float value, float duration = -1.0, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded)
	{
		if(!TF2Attrib_IsValidAttributeName(name))
			return;
		
		if(custom && 0 < entity <= MaxClients)
		{
			TF2Attrib_AddCustomPlayerAttribute(entity, name, value, duration);
		}
		else
		{
			TF2Attrib_SetByName(entity, name, value);
		}
		
		return;
	}
	#endif
	
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", %f, %f)", (!custom || entity > MaxClients) ? "" : "Custom", name, value, duration);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}

stock void Attrib_SetInt(int entity, const char[] name, int value, float duration = -1.0, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded)
	{
		if(!TF2Attrib_IsValidAttributeName(name))
			return;
		
		if(custom && 0 < entity <= MaxClients)
		{
			TF2Attrib_AddCustomPlayerAttribute(entity, name, float(value), duration);
		}
		else
		{
			TF2Attrib_SetByName(entity, name, float(value));
		}
		
		return;
	}
	#endif
	
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", casti2f(%d), %f)", (!custom || entity > MaxClients) ? "" : "Custom", name, value, duration);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}

stock bool Attrib_SetString(int entity, const char[] name, const char[] value)
{
	#if defined _tf2attributes_included
	if(Loaded)
	{
		if(!TF2Attrib_IsValidAttributeName(name))
			return false;
		
		return TF2Attrib_SetFromStringValue(entity, name, value);
	}
	#endif

	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", %f, -1)", entity > MaxClients ? "" : "Custom", name, StringToFloat(value));
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
	return true;
}

stock void Attrib_Remove(int entity, const char[] name, bool custom = false)
{
	#if defined _tf2attributes_included
	if(Loaded)
	{
		if(!TF2Attrib_IsValidAttributeName(name))
			return;
		
		if(custom && 0 < entity <= MaxClients)
		{
			TF2Attrib_RemoveCustomPlayerAttribute(entity, name);
		}
		else
		{
			TF2Attrib_RemoveByName(entity, name);
		}
		
		return;
	}
	#endif
	
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Remove%sAttribute(\"%s\")", (!custom || entity > MaxClients) ? "" : "Custom", name);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}
