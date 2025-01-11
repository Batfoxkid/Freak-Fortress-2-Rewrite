#tryinclude <vscript>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"

#if defined _vscript_included
static bool Loaded;
#endif

void VScript_PluginStart()
{
	#if defined _vscript_included
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
	#endif
}

stock void VScript_LibraryAdded(const char[] name)
{
	#if defined _vscript_included
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = true;
	#endif
}

stock void VScript_LibraryRemoved(const char[] name)
{
	#if defined _vscript_included
	if(Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = false;
	#endif
}

stock bool VScript_Loaded()
{
	#if defined _vscript_included
	return Loaded;
	#else
	return false;
	#endif
}

stock void VScript_PrintStatus()
{
	#if defined _vscript_included
	PrintToServer("'%s' is %sloaded", VSCRIPT_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", VSCRIPT_LIBRARY);
	#endif
}

// Check VScript_Loaded()
stock any VScript_RunScriptFunction(int entity, const char[] name)
{
	#if defined _vscript_included
	if(Loaded)
	{
		VScriptExecute execute = new VScriptExecute(HSCRIPT_RootTable.GetValue(name));
		execute.Execute();
		any value = execute.ReturnValue;
		delete execute;

		return value;
	}
	#endif

	ThrowError("VScript library is not loaded");
	return 0;
}

// Check VScript_Loaded()
stock float VScript_GetAttribute(int entity, const char[] name, float defaul = 0.0)
{
	#if defined _vscript_included
	if(Loaded)
	{
		VScriptExecute execute = new VScriptExecute(HSCRIPT_RootTable.GetValue(entity > MaxClients ? "GetAttribute" : "GetCustomAttribute"));
		execute.SetParamString(1, FIELD_CSTRING, name);
		execute.SetParam(2, FIELD_FLOAT, defaul);
		execute.Execute();
		float value = execute.ReturnValue;
		delete execute;

		return value;
	}
	#endif

	ThrowError("VScript library is not loaded");
	return 0.0;
}