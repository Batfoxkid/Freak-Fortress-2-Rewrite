/*
	If Freak Fortress loads late, give it time in the frame to actually load
*/

#pragma semicolon 1
#pragma newdecls required

static bool FF2REnabled;

void Subplugin_PluginStart()
{
	FF2REnabled = LibraryExists("ff2r");
	if(FF2REnabled)
		FF2R_PluginLoaded();
}

void Subplugin_LibraryAdded(const char[] name)
{
	if(!FF2REnabled && StrEqual(name, "ff2r"))
	{
		FF2REnabled = true;
		FF2R_PluginLoaded();
	}
}

void Subplugin_LibraryRemoved(const char[] name)
{
	if(FF2REnabled && StrEqual(name, "ff2r"))
	{
		char buffer[PLATFORM_MAX_PATH];
		GetPluginFilename(null, buffer, sizeof(buffer));
		ServerCommand("sm plugins unload %s", buffer);
	}
}

stock bool Subplugin_Enabled()
{
	return FF2REnabled;
}