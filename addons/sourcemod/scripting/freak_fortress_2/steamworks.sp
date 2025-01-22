#tryinclude <SteamWorks> 

#pragma semicolon 1
#pragma newdecls required

#define STEAMWORKS_LIBRARY	"SteamWorks"

#if defined _SteamWorks_Included
static bool Loaded;
static char Pack[64];
#endif

void SteamWorks_PluginStart()
{
	#if defined _SteamWorks_Included
	Loaded = LibraryExists(STEAMWORKS_LIBRARY);
	#endif
}

public void SteamWorks_LibraryAdded(const char[] name)
{
	#if defined _SteamWorks_Included
	if(!Loaded && StrEqual(name, STEAMWORKS_LIBRARY))
	{
		Loaded = true;
		SteamWorks_SetGameTitle(Pack);
	}
	#endif
}

public void SteamWorks_LibraryRemoved(const char[] name)
{
	#if defined _SteamWorks_Included
	if(Loaded && StrEqual(name, STEAMWORKS_LIBRARY))
		Loaded = false;
	#endif
}

void SteamWorks_PrintStatus()
{
	#if defined _SteamWorks_Included
	PrintToServer("'%s' is %sloaded", STEAMWORKS_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", STEAMWORKS_LIBRARY);
	#endif
}

stock void SteamWorks_SetGameTitle(const char[] pack = NULL_STRING)
{
	_SteamWorks_SetGameTitle(pack);
}
public void _SteamWorks_SetGameTitle(const char[] pack)
{
	#if defined _SteamWorks_Included
	strcopy(Pack, sizeof(Pack), pack);
	
	if(Loaded)
	{
		if(pack[0])
		{
			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "Freak Fortress 2: Rewrite (%s)", pack);
			SteamWorks_SetGameDescription(buffer);
		}
		else
		{
			SteamWorks_SetGameDescription("Freak Fortress 2: Rewrite (" ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION ... ")");
		}
	}
	#endif
}