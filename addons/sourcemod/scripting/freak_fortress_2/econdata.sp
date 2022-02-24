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

stock void TFED_LibraryAdded(const char[] name)
{
	#if defined __tf_econ_data_included
	if(!Loaded)
		Loaded = StrEqual(name, TFED_LIBRARY);
	#endif
}

stock void TFED_LibraryRemoved(const char[] name)
{
	#if defined __tf_econ_data_included
	if(Loaded)
		Loaded = !StrEqual(name, TFED_LIBRARY);
	#endif
}

bool TFED_GetItemDefinitionString(int itemdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue="")
{
	//TODO: Find a way to use m_pszItemIconClassname instead
	
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_GetItemDefinitionString(itemdef, key, buffer, maxlen, defaultValue);
	#endif
	
	buffer[0] = 0;
	return false;
}

bool TF2ED_GetLocalizedItemName(int itemdef, char[] name, int maxlen, const char[] classname="")
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
			strcopy(name, maxlen, SlotNames[slot]);
	}
	return false;
}

bool TF2ED_GetAttributeDefinitionString(int attrdef, const char[] key, char[] buffer, int maxlen, const char[] defaultValue="")
{
	#if defined __tf_econ_data_included
	if(Loaded)
		return TF2Econ_GetAttributeDefinitionString(attrdef, key, buffer, maxlen, defaultValue);
	#endif
	
	buffer[0] = 0;
	return false;
}
