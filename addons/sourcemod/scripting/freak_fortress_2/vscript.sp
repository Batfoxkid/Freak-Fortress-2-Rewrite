#tryinclude <vscript>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"

#if defined _vscript_included
static Handle SDKGetAttribute;
static Handle SDKGetCustomAttribute;
static bool Loaded;
#endif

void VScript_PluginStart()
{
	#if defined _vscript_included
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
	if(Loaded && VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
	#endif
}

public void VScript_LibraryAdded(const char[] name)
{
	#if defined _vscript_included
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		Loaded = true;
		
		if(VScript_IsScriptVMInitialized())
			VScript_OnScriptVMInitialized();
	}
	#endif
}

public void VScript_LibraryRemoved(const char[] name)
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

#if defined _vscript_included
public void VScript_OnScriptVMInitialized()
{
	VScriptFunction func = VScript_GetClassFunction("CEconEntity", "GetAttribute");
	if(func)
	{
		SDKGetAttribute = func.CreateSDKCall();
		if(!SDKGetAttribute)
			LogError("[VScript] Could not call CEconEntity::GetAttribute");
	}
	else
	{
		LogError("[VScript] Could not find CEconEntity::GetAttribute");
	}

	func = VScript_GetClassFunction("CTFPlayer", "GetCustomAttribute");
	if(func)
	{
		SDKGetCustomAttribute = func.CreateSDKCall();
		if(!SDKGetCustomAttribute)
			LogError("[VScript] Could not call CTFPlayer::GetCustomAttribute");
	}
	else
	{
		LogError("[VScript] Could not find CTFPlayer::GetCustomAttribute");
	}
}
#endif

public bool VScript_GetAttribute(int entity, const char[] name, float &value)
{
	#if defined _vscript_included
	if(SDKGetAttribute && SDKGetCustomAttribute)
	{
		value = SDKCall(entity > MaxClients ? SDKGetAttribute : SDKGetCustomAttribute, entity, name, value);
		return true;
	}
	#endif

	return false;
}