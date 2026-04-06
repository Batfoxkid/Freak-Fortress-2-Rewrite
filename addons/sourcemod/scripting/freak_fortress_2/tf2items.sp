#tryinclude <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define TF2ITEMS_LIBRARY	"tf2items"

enum struct WeaponData
{
	char Classname[36];
	int Index;
	int Level;
	int Quality;
	int Rank;
	bool Preserve;
	bool Override;
	TFClassType ForceClass;
	char AttributeString[256];
	char Clip[64];
	char Ammo[64];
	char MaxAmmo[64];
	bool Show;
	int Worldmodel;
	int Alpha;
	int Red;
	int Green;
	int Blue;
	int Skin;
	bool Equip;
	int Forumla;

	void Setup(const char[] classname, int index = 0, const char[] attributes = "", bool preserve = false, bool show = true, bool equip = true)
	{
		strcopy(this.Classname, sizeof(this.Classname), classname);
		this.Index = index;
		this.Level = -1;
		this.Quality = 0;
		this.Rank = -1;
		this.Preserve = preserve;
		this.Override = true;
		this.ForceClass = TFClass_Unknown;
		strcopy(this.AttributeString, sizeof(this.AttributeString), attributes);
		this.Clip[0] = 0;
		this.Ammo[0] = 0;
		this.MaxAmmo[0] = 0;
		this.Show = show;
		this.Worldmodel = 0;
		this.Alpha = 255;
		this.Red = 255;
		this.Green = 255;
		this.Blue = 255;
		this.Skin = -1;
		this.Equip = equip;
		this.Forumla = -99;
	}
}

void TF2Items_PluginLoad()
{
	#if defined _tf2items_included
	MarkNativeAsOptional("TF2Items_CreateItem");
	MarkNativeAsOptional("TF2Items_SetClassname");
	MarkNativeAsOptional("TF2Items_SetItemIndex");
	MarkNativeAsOptional("TF2Items_SetLevel");
	MarkNativeAsOptional("TF2Items_SetQuality");
	MarkNativeAsOptional("TF2Items_SetNumAttributes");
	MarkNativeAsOptional("TF2Items_SetAttribute");
	MarkNativeAsOptional("TF2Items_GiveNamedItem");
	#endif
}

stock void TF2Items_PrintStatus()
{
	#if defined _tf2items_included
	PrintToServer("'%s' is %sloaded", TF2ITEMS_LIBRARY, GetFeatureStatus(FeatureType_Native, "TF2Items_CreateItem") == FeatureStatus_Available ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TF2ITEMS_LIBRARY);
	#endif
}

stock void TF2Items_StructFromCfg(WeaponData data, const char[] classname, ConfigMap cfg, bool reset = true, bool equip = true, int formula = -99)
{
	char buffer[36];
	strcopy(buffer, sizeof(buffer), classname);
	
	if(StrContains(buffer, "tf_") != 0 &&
		StrContains(buffer, "tf2c_") != 0 &&
		!StrEqual(buffer, "saxxy"))
	{
		if(!cfg.Get("name", buffer, sizeof(buffer)) && reset)
			strcopy(buffer, sizeof(buffer), "tf_wearable");
	}

	if(reset)
	{
		data.Setup(buffer);

		#if defined IS_MAIN_FF2
		data.Override = false;
		#endif
	}
	else if(buffer[0])
	{
		strcopy(buffer, sizeof(buffer), classname);
	}

	cfg.GetInt("index", data.Index);
	cfg.GetInt("level", data.Level);
	cfg.GetInt("quality", data.Quality);
	cfg.GetBool("preserve", data.Preserve, false);
	cfg.GetBool("override", data.Override, false);
	cfg.GetInt("rank", data.Rank);

	if(cfg.Get("class", buffer, sizeof(buffer)))
		data.ForceClass = TF2Tools_GetClass(buffer);
	
	if(cfg.GetKeyValType("attributes") == KeyValType_Value)
		cfg.Get("attributes", data.AttributeString, sizeof(data.AttributeString));

	cfg.Get("clip", data.Clip, sizeof(data.Clip));
	cfg.Get("ammo", data.Ammo, sizeof(data.Ammo));
	cfg.Get("maxammo", data.MaxAmmo, sizeof(data.MaxAmmo));
	cfg.GetBool("show", data.Show, false);
	cfg.GetInt("worldmodel", data.Worldmodel);
	cfg.GetInt("alpha", data.Alpha);
	cfg.GetInt("red", data.Red);
	cfg.GetInt("green", data.Green);
	cfg.GetInt("blue", data.Blue);
	cfg.GetInt("skin", data.Skin);
	data.Equip = equip;
	data.Forumla = formula;
}

stock int TF2Items_CreateFromCfg(int client, const char[] classname, ConfigMap cfg, bool &equip = false, int formula = -99)
{
	ArrayList cfgs = new ArrayList();
	cfgs.Push(cfg);
	int weapon = TF2Items_CreateFromMultiCfg(client, classname, cfgs, equip, formula);
	delete cfgs;

	return weapon;
}

stock int TF2Items_CreateFromMultiCfg(int client, const char[] classname, ArrayList cfgs, bool &equip = false, int formula = -99)
{
	static WeaponData data;

	int length = cfgs.Length;
	for(int i; i < length; i++)
	{
		ConfigMap cfg = cfgs.Get(i);
		TF2Items_StructFromCfg(data, classname, cfg, i == 0, equip, formula);
	}

	int weapon = TF2Items_CreateFromStruct(client, data, cfgs);
	equip = data.Equip;
	return weapon;
}

stock int TF2Items_CreateFromStruct(int client, WeaponData data, ArrayList cfgs = null)
{
	static char buffer[64];
	
	TFClassType class = TF2_GetPlayerClass(client);
	GetClassWeaponClassname(class, data.Classname, sizeof(data.Classname));
	bool wearable = StrContains(data.Classname, "tf_weap") != 0 && StrContains(data.Classname, "tf2c_weap") != 0;
	
	int kills = -1;
	if(data.Rank < 0 && data.Level == -1 && !data.Override)
		kills = GetURandomInt() % 21;
	
	if(kills >= 0)
		kills = wearable ? GetKillsOfCosmeticRank(kills, data.Index) : GetKillsOfWeaponRank(kills, data.Index);
	
	if(data.Level < 0 || data.Level > 127)
		data.Level = 101;
	
	if(data.ForceClass != TFClass_Unknown)
		TF2_SetPlayerClass(client, data.ForceClass, _, false);
	
	int slot = wearable ? -1 : TF2_GetClassnameSlot(data.Classname);

	if(!wearable && !data.Override)
	{
		if(slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee && data.Equip)
		{
			if(data.AttributeString[0])
			{
				Format(data.AttributeString, sizeof(data.AttributeString), "2 ; 3.1 ; 275 ; 1 ; %s", data.AttributeString);
			}
			else
			{
				strcopy(data.AttributeString, sizeof(data.AttributeString), "2 ; 3.1 ; 275 ; 1");
			}
		}
		else if(data.AttributeString[0])
		{
			Format(data.AttributeString, sizeof(data.AttributeString), "2 ; 3.1 ; %s", data.AttributeString);
		}
		else
		{
			strcopy(data.AttributeString, sizeof(data.AttributeString), "2 ; 3.1");
		}
	}
	
	static char buffers[40][16];
	int count = ExplodeString(data.AttributeString[0], " ; ", buffers, sizeof(buffers), sizeof(buffers));
	
	if(count % 2)
		count--;
	
	int attribs;
	int entity = -1;

	#if defined _tf2items_included
	if(wearable || GetFeatureStatus(FeatureType_Native, "TF2Items_CreateItem") != FeatureStatus_Available)
	#endif
	{
		entity = CreateEntityByName(data.Classname);
		if(IsValidEntity(entity))
		{
			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", data.Index);
			SetEntProp(entity, Prop_Send, "m_bInitialized", true);

			GetEntityNetClass(entity, buffer, sizeof(buffer));
			SetEntData(entity, FindSendPropInfo(buffer, "m_iEntityQuality"), data.Quality);
			SetEntData(entity, FindSendPropInfo(buffer, "m_iEntityLevel"), data.Level);

			SetEntProp(entity, Prop_Send, "m_iEntityQuality", data.Quality);
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", data.Level);
			
			DispatchSpawn(entity);

			if(!data.Preserve)
				SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
		}
		else
		{
			ThrowError("Invalid classname '%s'", data.Classname);
		}
	}
	#if defined _tf2items_included
	else
	{
		Handle item = TF2Items_CreateItem(data.Preserve ? (OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES) : (OVERRIDE_ALL|FORCE_GENERATION));
		TF2Items_SetClassname(item, data.Classname);
		TF2Items_SetItemIndex(item, data.Index);
		TF2Items_SetLevel(item, data.Level);
		TF2Items_SetQuality(item, data.Quality);
		TF2Items_SetNumAttributes(item, count/2 > 14 ? 15 : count/2);
		for(int a; attribs < count && a < 16; attribs += 2)
		{
			int attrib = StringToInt(buffers[attribs]);
			if(attrib)
			{
				TF2Items_SetAttribute(item, a++, attrib, data.Forumla == -99 ? StringToFloat(buffers[attribs+1]) : ParseFormula(buffers[attribs+1], data.Forumla));
			}
			else
			{
				ThrowError("Bad weapon attribute passed for '%s': %s ; %s", data.Classname, buffers[attribs], buffers[attribs+1]);
			}
		}
		
		entity = TF2Items_GiveNamedItem(client, item);
		delete item;

		GetEntityNetClass(entity, buffer, sizeof(buffer));
	}
	#endif
	
	if(entity != -1)
	{
		if(wearable)
		{
			TF2U_EquipPlayerWearable(client, entity);
		}
		else
		{
			EquipPlayerWeapon(client, entity);
		}
		
		if(data.ForceClass != TFClass_Unknown)
			TF2_SetPlayerClass(client, class, _, false);
		
		for(; attribs < count; attribs += 2)
		{
			int attrib = StringToInt(buffers[attribs]);
			if(attrib)
			{
				if(data.Forumla == -99)
				{
					Attrib_SetString(entity, _, attrib, buffers[attribs+1]);
				}
				else
				{
					Attrib_Set(entity, _, attrib, ParseFormula(buffers[attribs+1], data.Forumla));
				}
			}
			else
			{
				ThrowError("Bad weapon attribute passed for '%s' : %s ; %s", data.Classname, buffers[attribs], buffers[attribs+1]);
			}
		}

		if(cfgs)
		{
			int lengt = cfgs.Length;
			for(int i; i < lengt; i++)
			{
				ConfigMap cfg = cfgs.Get(i);

				if(cfg.GetKeyValType("attributes") == KeyValType_Section)
				{
					ConfigMap attributes = cfg.GetSection("attributes");

					StringMapSnapshot snap = attributes.Snapshot();
					int snapLength = snap.Length;

					PackVal val;

					for(attribs = 0; attribs < snapLength; attribs++)
					{
						int length = snap.KeyBufferSize(attribs) + 1;
						char[] key = new char[length];

						snap.GetKey(attribs, key, length);
						
						attributes.GetArray(key, val, sizeof(val));

						if(val.tag == KeyValType_Value)
						{
							if(data.Forumla == -99)
							{
								Attrib_SetString(entity, key, _, val.data);
							}
							else
							{
								Attrib_Set(entity, key, _, ParseFormula(val.data, data.Forumla));
							}
						}
					}

					delete snap;
				}
				
				#if defined CUSTOMATTRIBFF2_INCLUDED
				if(cfg)
				{
					ConfigMap custom = cfg.GetSection("custom");
					if(custom)
						CustomAttrib_ApplyFromCfg(entity, custom);
				}
				#endif
			}
		}

		if(kills >= 0)
		{
			Attrib_SetInt(entity, "kill eater", 214, kills);
			if(wearable)
				Attrib_SetInt(entity, "strange restriction type 1", 454, 64);
		}
		
		if(!wearable)
		{
			if(data.Clip[0])
			{
				kills = RoundFloat(data.Forumla == -99 ? StringToFloat(data.Clip) : ParseFormula(data.Clip, data.Forumla));
				if(kills >= 0)
					SetEntProp(entity, Prop_Data, "m_iClip1", kills);
			}
			
			if(data.Ammo[0])
			{
				int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				if(type >= 0)
				{
					kills = RoundFloat(data.Forumla == -99 ? StringToFloat(data.Ammo) : ParseFormula(data.Ammo, data.Forumla));

					if(data.MaxAmmo[0])
					{
						int limit = RoundFloat(data.Forumla == -99 ? StringToFloat(data.MaxAmmo) : ParseFormula(data.MaxAmmo, data.Forumla));
						if(limit >= 0 && kills > limit)
							kills = limit;
					}

					SetEntProp(client, Prop_Data, "m_iAmmo", kills, _, type);
				}
			}
			
			if(data.Index != 735 && StrEqual(data.Classname, "tf_weapon_builder"))
			{
				for(kills = 0; kills < 4; kills++)
				{
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", kills != 3, _, kills);
				}
			}
			else if(data.Index == 735 || StrEqual(data.Classname, "tf_weapon_sapper"))
			{
				SetEntProp(entity, Prop_Send, "m_iObjectType", TFObject_Sapper);
				SetEntProp(entity, Prop_Data, "m_iSubType", TFObject_Sapper);
				
				for(kills = 0; kills < 4; kills++)
				{
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", kills == 3, _, kills);
				}
			}
		}

		if(data.Show)
		{
			if(data.Worldmodel)
			{
				if(!wearable)
					SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", data.Worldmodel);
				
				for(kills = 0; kills < 4; kills++)
				{
					SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", data.Worldmodel, _, kills);
				}
			}
			
			GetEntityNetClass(entity, buffer, sizeof(buffer));
			int offset = FindSendPropInfo(buffer, "m_iItemIDHigh");
			
			SetEntData(entity, offset - 8, 0);	// m_iItemID
			SetEntData(entity, offset - 4, 0);	// m_iItemID
			SetEntData(entity, offset, 0);		// m_iItemIDHigh
			SetEntData(entity, offset + 4, 0);	// m_iItemIDLow
			
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		}
		else if(!wearable)
		{
			SetEntityRenderMode(entity, RENDER_ENVIRONMENTAL);
		}
		
		if(data.Alpha != 255 && data.Red != 255 && data.Green != 255 && data.Blue != 255)
		{
			if(data.Alpha != 255)
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			
			SetEntityRenderColor(entity, data.Red, data.Green, data.Blue, data.Alpha);
		}

		if(data.Skin >= 0)
			SetEntProp(entity, Prop_Send, "m_nSkin", data.Skin);
		
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		
		if(!wearable && data.Equip && slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
		{
			data.Equip = false;
			TF2U_SetPlayerActiveWeapon(client, entity);
		}
	}
	else if(data.ForceClass != TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, class, _, false);
	}

	Event event = CreateEvent("localplayer_pickup_weapon", true);
	event.FireToClient(client);
	event.Cancel();

	VScript_WeaponChanged(client, entity);

	return entity;
}