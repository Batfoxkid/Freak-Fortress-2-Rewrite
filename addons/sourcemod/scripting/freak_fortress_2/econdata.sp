/*
	void TFED_PluginStart()
	void TFED_LibraryAdded(const char[] name)
	void TFED_LibraryRemoved(const char[] name)
	bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
*/

#tryinclude <tf_econ_data>

#define TFED_LIBRARY	"tf_econ_data"

static bool Loaded;

void TFED_PluginStart()
{
	#if defined __tf_econ_data_included
	Loaded = LibraryExists(TFED_LIBRARY);
	#endif
}

void TFED_LibraryAdded(const char[] name)
{
	#if defined __tf_econ_data_included
	if(!Loaded)
		Loaded = StrEqual(name, TFED_LIBRARY);
	#endif
}

void TFED_LibraryRemoved(const char[] name)
{
	#if defined __tf_econ_data_included
	if(Loaded)
		Loaded = !StrEqual(name, TFED_LIBRARY);
	#endif
}

bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
{
	//TODO: Use a config based system insteaad
	
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_GetItemDefinitionString(itemdef, key, buffer, maxlen, defaultValue);
	#endif
	
	buffer[0] = 0;
	return false;
}
