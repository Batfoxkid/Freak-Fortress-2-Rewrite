/*
	void TF2U_PluginStart()
	void TF2U_LibraryAdded(const char[] name)
	void TF2U_LibraryRemoved(const char[] name)
	bool TF2U_GetWearable(int client, int &index, int &entity)
	int TF2U_GetMaxOverheal(int client)
*/

#tryinclude <tf_econ_data>

#if !defined __tf_econ_data_included
	#endinput
#endif

#define TFED_LIBRARY	"tf_econ_data"

static bool Loaded;

void TFED_PluginStart()
{
	Loaded = LibraryExists(TFED_LIBRARY);
}

void TFED_LibraryAdded(const char[] name)
{
	if(!Loaded)
		Loaded = StrEqual(name, TFED_LIBRARY);
}

void TFED_LibraryRemoved(const char[] name)
{
	if(Loaded)
		Loaded = !StrEqual(name, TFED_LIBRARY);
}

bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
{
	if(Loaded)
		return TF2Econ_GetItemDefinitionString(itemdef, key, buffer, maxlen, defaultValue);
	
	buffer[0] = 0;
	return false;
}
