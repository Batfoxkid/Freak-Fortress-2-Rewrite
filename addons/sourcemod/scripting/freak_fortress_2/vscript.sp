#tryinclude <vscript>
#tryinclude <sm_vscript_comms>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"
#define VCOMMS_LIBRARY	"sm_vscript_comms"

#if defined _vscript_included
static Handle SDKGetAttribute;
static Handle SDKGetCustomAttribute;
static bool VSLoaded;
#endif

#if defined _sm_vscript_comms_included_
static VScriptHandle VCGetAttribute;
static VScriptHandle VCGetCustomAttribute;
static bool VCLoaded;
#endif

void VScript_PluginLoad()
{
	#if defined _sm_vscript_comms_included_
	MarkNativeAsOptional("StartPrepVScriptCall");
	MarkNativeAsOptional("PrepVScriptCall_SetFunction");
	MarkNativeAsOptional("PrepVScriptCall_SetReturnType");
	MarkNativeAsOptional("PrepVScriptCall_AddParameter");
	MarkNativeAsOptional("EndPrepVScriptCall");
	MarkNativeAsOptional("StartVScriptFunc");
	MarkNativeAsOptional("VScriptFunc_PushEntity");
	MarkNativeAsOptional("VScriptFunc_PushString");
	MarkNativeAsOptional("VScriptFunc_PushFloat");
	MarkNativeAsOptional("FireVScriptFunc_ReturnAny");
	#endif
}

void VScript_PluginStart()
{
	#if defined _vscript_included
	VSLoaded = LibraryExists(VSCRIPT_LIBRARY);
	if(VSLoaded && VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
	#endif
	
	#if defined _sm_vscript_comms_included_
	VCLoaded = LibraryExists(VCOMMS_LIBRARY);
	if(VCLoaded)
		RequestFrame(VCommsLoaded);
	#endif
}

public void VScript_LibraryAdded(const char[] name)
{
	#if defined _vscript_included
	if(!VSLoaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		VSLoaded = true;
		
		if(VScript_IsScriptVMInitialized())
			VScript_OnScriptVMInitialized();
	}
	#endif
	
	#if defined _sm_vscript_comms_included_
	if(!VCLoaded && StrEqual(name, VCOMMS_LIBRARY))
	{
		VCLoaded = true;
		RequestFrame(VCommsLoaded);
	}
	#endif
}

public void VScript_LibraryRemoved(const char[] name)
{
	#if defined _vscript_included
	if(VSLoaded && StrEqual(name, VSCRIPT_LIBRARY))
		VSLoaded = false;
	#endif

	#if defined _sm_vscript_comms_included_
	if(VCLoaded && StrEqual(name, VSCRIPT_LIBRARY))
		VCLoaded = false;
	#endif
}

stock bool VScript_Loaded()
{
	#if defined _vscript_included
	if(VSLoaded)
		return VSLoaded;
	#endif

	#if defined _sm_vscript_comms_included_
	if(VCLoaded)
		return VCLoaded;
	#endif
	
	return false;
}

stock void VScript_PrintStatus(bool error = false)
{
	if(error)
	{
		#if defined _vscript_included
		LogError("'%s' is %sloaded", VSCRIPT_LIBRARY, VSLoaded ? "" : "not ");
		#else
		LogError("'%s' not compiled", VSCRIPT_LIBRARY);
		#endif

		#if defined _sm_vscript_comms_included_
		LogError("'%s' is %sloaded", VCOMMS_LIBRARY, VCLoaded ? "" : "not ");
		#else
		LogError("'%s' not compiled", VCOMMS_LIBRARY);
		#endif
	}
	else
	{
		#if defined _vscript_included
		PrintToServer("'%s' is %sloaded", VSCRIPT_LIBRARY, VSLoaded ? "" : "not ");
		#else
		PrintToServer("'%s' not compiled", VSCRIPT_LIBRARY);
		#endif

		#if defined _sm_vscript_comms_included_
		PrintToServer("'%s' is %sloaded", VCOMMS_LIBRARY, VCLoaded ? "" : "not ");
		#else
		PrintToServer("'%s' not compiled", VCOMMS_LIBRARY);
		#endif
	}
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

#if defined _sm_vscript_comms_included_
static void VCommsLoaded()
{
    StartPrepVScriptCall(VScriptScope_EntityInstance);
    PrepVScriptCall_SetFunction("GetAttribute");
    PrepVScriptCall_SetReturnType(VScriptReturnType_Float);
    PrepVScriptCall_AddParameter(VScriptParamType_Entity);
    PrepVScriptCall_AddParameter(VScriptParamType_String);
    PrepVScriptCall_AddParameter(VScriptParamType_Float);
	VCGetAttribute = EndPrepVScriptCall();

    StartPrepVScriptCall(VScriptScope_EntityInstance);
    PrepVScriptCall_SetFunction("GetCustomAttribute");
    PrepVScriptCall_SetReturnType(VScriptReturnType_Float);
    PrepVScriptCall_AddParameter(VScriptParamType_Entity);
    PrepVScriptCall_AddParameter(VScriptParamType_String);
    PrepVScriptCall_AddParameter(VScriptParamType_Float);
	VCGetCustomAttribute = EndPrepVScriptCall();
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

	#if defined _sm_vscript_comms_included_
	if(VCLoaded && VCGetAttribute && VCGetCustomAttribute)
	{
		char name2[64];
		strcopy(name2, sizeof(name2), name);

		StartVScriptFunc(entity > MaxClients ? VCGetAttribute : VCGetCustomAttribute);
		VScriptFunc_PushEntity(entity);
		VScriptFunc_PushString(name2);
		VScriptFunc_PushFloat(value);
		value = FireVScriptFunc_ReturnAny();
		return true;
	}
	#endif

	return false;
}