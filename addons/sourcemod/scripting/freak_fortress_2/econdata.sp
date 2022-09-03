/*
	void TFED_PluginLoad()
	void TFED_PluginStart()
	void TFED_LibraryAdded(const char[] name)
	void TFED_LibraryRemoved(const char[] name)
	bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
	bool TF2ED_GetLocalizedItemName(int itemdef, char[] name, int maxlen, const char[] classname = "")
	bool TF2ED_GetAttributeDefinitionString(int attrdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
	int TF2ED_TranslateAttributeNameToDefinitionIndex(const char[] name)
*/

#tryinclude <tf_econ_data> 

#pragma semicolon 1

#define TFED_LIBRARY	"tf_econ_data"

#if defined __tf_econ_data_included
static bool Loaded;
#endif

void TFED_PluginLoad()
{
	#if defined __tf_econ_data_included
	MarkNativeAsOptional("TF2Econ_GetItemDefinitionString");
	MarkNativeAsOptional("TF2Econ_GetLocalizedItemName");
	MarkNativeAsOptional("TF2Econ_GetAttributeDefinitionString");
	MarkNativeAsOptional("TF2Econ_TranslateAttributeNameToDefinitionIndex");
	#endif
}

void TFED_PluginStart()
{
	#if defined __tf_econ_data_included
	Loaded = LibraryExists(TFED_LIBRARY);
	#endif
}

stock void TFED_LibraryAdded(const char[] name)
{
	#if defined __tf_econ_data_included
	if(!Loaded && StrEqual(name, TFED_LIBRARY))
		Loaded = true;
	#endif
}

stock void TFED_LibraryRemoved(const char[] name)
{
	#if defined __tf_econ_data_included
	if(Loaded && StrEqual(name, TFED_LIBRARY))
		Loaded = false;
	#endif
}

stock bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
{
	//TODO: Find a way to use m_pszItemIconClassname instead
	
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_GetItemDefinitionString(itemdef, key, buffer, maxlen, defaultValue);
	#endif
	
	buffer[0] = 0;
	return false;
}

stock bool TF2ED_GetLocalizedItemName(int itemdef, char[] name, int maxlen, const char[] classname = "")
{
	#if defined __tf_econ_data_included
	if(Loaded && TF2Econ_GetLocalizedItemName(itemdef, name, maxlen))
		return true;
	#endif
	
	if(classname[0])
	{
		static const char SlotNames[][] = { "#TR_Primary", "#TR_Secondary", "#TR_Melee", "#TF_Weapon_PDA_Engineer", "#LoadoutSlot_Utility", "#LoadoutSlot_Building", "#LoadoutSlot_Action" };
		int slot = TF2_GetClassnameSlot(classname);
		if(slot >= 0 && slot < sizeof(SlotNames))
			return view_as<bool>(strcopy(name, maxlen, SlotNames[slot]));
	}
	
	return false;
}

stock bool TF2ED_GetAttributeDefinitionString(int attrdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue = "")
{
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_GetAttributeDefinitionString(attrdef, key, buffer, maxlen, defaultValue);
	#endif
	
	buffer[0] = 0;
	return false;
}

stock int TF2ED_TranslateAttributeNameToDefinitionIndex(const char[] key)
{
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_TranslateAttributeNameToDefinitionIndex(key);
	#endif
	
	return -1;
}
