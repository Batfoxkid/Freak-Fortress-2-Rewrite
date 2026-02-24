#pragma semicolon 1
#pragma newdecls required

static char ReturnString[128];
static float ReturnFloat;

void VScript_PluginStart()
{
	HookEvent("tf_map_time_remaining", VScriptEvent, EventHookMode_Pre);
	if(!FileExists("scripts/vscripts/ff2r.nut", true))
		SetFailState("VScript file \"ff2r.nut\" is outdated");
}

static Action VScriptEvent(Event event, const char[] name, bool dontBroadcast)
{
	char buffer[32];
	event.GetString("id", buffer, sizeof(buffer));
	if(StrEqual(buffer, "ff2r"))
	{
		event.GetString("event", buffer, sizeof(buffer));
		if(StrEqual(buffer, "returning"))
		{
			event.GetString("returnstring", ReturnString, sizeof(ReturnString));
			ReturnFloat = event.GetFloat("returnfloat");
		}
	}

	return Plugin_Continue;
}

stock bool VScript_GetAttribute(int entity, const char[] name, float &value)
{
	ReturnFloat = -999.9;	

	Format(ReturnString, sizeof(ReturnString), "FF2R_GetAttribute(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);

	if(ReturnFloat == -999.9)
		return false;
	
	value = ReturnFloat;
	return true;
}

stock void VScript_SetAttribute(int entity, const char[] name, float value)
{
	Format(ReturnString, sizeof(ReturnString), "FF2R_SetAttribute(\"%s\", %f)", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_SetAttributeInt(int entity, const char[] name, int value)
{
	Format(ReturnString, sizeof(ReturnString), "FF2R_SetAttribute(\"%s\", casti2f(%d))", name, value);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}

stock void VScript_RemoveAttribute(int entity, const char[] name)
{
	Format(ReturnString, sizeof(ReturnString), "FF2R_RemoveAttribute(\"%s\")", name);
	SetVariantString(ReturnString);
	AcceptEntityInput(0, "RunScriptCode", entity, entity);
}