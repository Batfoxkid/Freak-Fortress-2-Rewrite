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
	bool Equip;
	bool Forumla;

	void Setup(const char[] classname, int index, const char[] attributes = "", bool preserve = false, bool show = true, bool equip = true)
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
		this.Equip = equip;
		this.Forumla = false;
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

stock int TF2Items_CreateFromCfg(int client, const char[] classname, ConfigMap cfg, bool &equip = false, bool forumla = false)
{
	static char classname2[36], netclass[32], buffer[PLATFORM_MAX_PATH];
	strcopy(classname2, sizeof(classname2), classname);
	
	if(StrContains(classname2, "tf_") != 0 &&
		!StrEqual(classname2, "saxxy"))
	{
		if(!cfg.Get("name", classname2, sizeof(classname2)))
			strcopy(classname2, sizeof(classname2), "tf_wearable");
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	GetClassWeaponClassname(class, classname2, sizeof(classname2));
	bool wearable = StrContains(classname2, "tf_weap") != 0;
	
	int index = 0;
	cfg.GetInt("index", index);
	
	int level = -1;
	cfg.GetInt("level", level);
	
	int quality = 5;
	cfg.GetInt("quality", quality);
	
	bool preserve;
	cfg.GetBool("preserve", preserve, false);
	
#if defined IS_MAIN_FF2
	bool override = false;
#else
	bool override = true;
#endif
	cfg.GetBool("override", override, false);
	
	int kills = -1;
	if(!cfg.GetInt("rank", kills) && level == -1 && !override)
		kills = GetURandomInt() % 21;
	
	if(kills >= 0)
		kills = wearable ? GetKillsOfCosmeticRank(kills, index) : GetKillsOfWeaponRank(kills, index);
	
	if(level < 0 || level > 127)
		level = 101;
	
	TFClassType forceClass;
	if(cfg.Get("class", buffer, sizeof(buffer)))
		forceClass = GetClassOfName(buffer);
	
	if(forceClass != TFClass_Unknown)
		TF2_SetPlayerClass(client, forceClass, _, false);
	
	bool found = (cfg.GetKeyValType("attributes") == KeyValType_Value && cfg.Get("attributes", buffer, sizeof(buffer)) && buffer[0]);
	int slot = wearable ? -1 : TF2_GetClassnameSlot(classname2);

	if(!wearable && !override)
	{
		if(slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee && equip)
		{
			if(found)
			{
				Format(buffer, sizeof(buffer), "2 ; 3.1 ; 275 ; 1 ; %s", buffer);
			}
			else
			{
				strcopy(buffer, sizeof(buffer), "2 ; 3.1 ; 275 ; 1");
			}
		}
		else if(found)
		{
			Format(buffer, sizeof(buffer), "2 ; 3.1 ; %s", buffer);
		}
		else
		{
			strcopy(buffer, sizeof(buffer), "2 ; 3.1");
		}
	}
	else if(!found)
	{
		buffer[0] = 0;
	}
	
	static char buffers[40][16];
	int count = ExplodeString(buffer, " ; ", buffers, sizeof(buffers), sizeof(buffers));
	
	if(count % 2)
		count--;
	
	int attribs;
	int entity = -1;

#if defined IS_MAIN_FF2
	int alive = TotalPlayersAliveEnemy(Cvar[FriendlyFire].BoolValue ? -1 : GetClientTeam(client));
#else
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
#endif

	#if defined _tf2items_included
	if(wearable || GetFeatureStatus(FeatureType_Native, "TF2Items_CreateItem") != FeatureStatus_Available)
	#endif
	{
		entity = CreateEntityByName(classname2);
		if(IsValidEntity(entity))
		{
			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
			SetEntProp(entity, Prop_Send, "m_bInitialized", true);

			GetEntityNetClass(entity, netclass, sizeof(netclass));
			SetEntData(entity, FindSendPropInfo(netclass, "m_iEntityQuality"), quality);
			SetEntData(entity, FindSendPropInfo(netclass, "m_iEntityLevel"), level);

			SetEntProp(entity, Prop_Send, "m_iEntityQuality", quality);
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", level);
			
			DispatchSpawn(entity);

			if(!preserve)
				SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
		}
		else
		{
			#if defined IS_MAIN_FF2
			Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
			#else
			FF2R_GetBossData(client).GetString("filename", buffer, sizeof(buffer));
			#endif
			LogError("[Boss] Invalid classname '%s' for '%s'", classname2, buffer);
		}
	}
	#if defined _tf2items_included
	else
	{
		Handle item = TF2Items_CreateItem(preserve ? (OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES) : (OVERRIDE_ALL|FORCE_GENERATION));
		TF2Items_SetClassname(item, classname2);
		TF2Items_SetItemIndex(item, index);
		TF2Items_SetLevel(item, level);
		TF2Items_SetQuality(item, quality);
		TF2Items_SetNumAttributes(item, count/2 > 14 ? 15 : count/2);
		for(int a; attribs < count && a < 16; attribs += 2)
		{
			int attrib = StringToInt(buffers[attribs]);
			if(attrib)
			{
				TF2Items_SetAttribute(item, a++, attrib, ParseFormula(buffers[attribs+1], alive));
			}
			else
			{
				#if defined IS_MAIN_FF2
				Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
				#else
				FF2R_GetBossData(client).GetString("filename", buffer, sizeof(buffer));
				#endif
				LogError("[Boss] Bad weapon attribute passed for '%s' on '%s': %s ; %s", buffer, classname2, buffers[attribs], buffers[attribs+1]);
			}
		}
		
		entity = TF2Items_GiveNamedItem(client, item);
		delete item;

		GetEntityNetClass(entity, netclass, sizeof(netclass));
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
		
		if(forceClass != TFClass_Unknown)
			TF2_SetPlayerClass(client, class, _, false);
		
		for(; attribs < count; attribs += 2)
		{
			int attrib = StringToInt(buffers[attribs]);
			if(attrib)
			{
				if(forumla)
				{
					Attrib_Set(entity, _, attrib, ParseFormula(buffers[attribs+1], alive));
				}
				else
				{
					Attrib_SetString(entity, _, attrib, buffers[attribs+1]);
				}
			}
			else
			{
				#if defined IS_MAIN_FF2
				Client(client).Cfg.Get("filename", buffer, sizeof(buffer));
				#else
				FF2R_GetBossData(client).GetString("filename", buffer, sizeof(buffer));
				#endif
				LogError("[Boss] Bad weapon attribute passed for '%s' on '%s': %s ; %s", buffer, classname2, buffers[attribs], buffers[attribs+1]);
			}
		}

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
					if(forumla)
					{
						Attrib_Set(entity, key, _, ParseFormula(val.data, alive));
					}
					else
					{
						Attrib_SetString(entity, key, _, val.data);
					}
				}
			}

			delete snap;
		}
		
		#if defined CUSTOMATTRIBFF2_INCLUDED
		ConfigMap custom = cfg.GetSection("custom");
		if(custom)
			CustomAttrib_ApplyFromCfg(entity, custom);
		#endif

		if(kills >= 0)
		{
			Attrib_SetInt(entity, "kill eater", 214, kills);
			if(wearable)
				Attrib_SetInt(entity, "strange restriction type 1", 454, 64);
		}
		
		if(!wearable)
		{
			if(cfg.Get("clip", buffer, sizeof(buffer)))
			{
				level = RoundFloat(ParseFormula(buffer, alive));
				if(level >= 0)
					SetEntProp(entity, Prop_Data, "m_iClip1", level);
			}
			
			level = 0;
			if(cfg.GetInt("ammotype", level) && level > 0 && level < 7)
				SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", level);
			
			if(cfg.Get("ammo", buffer, sizeof(buffer)))
			{
				quality = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				if(quality >= 0)
				{
					level = RoundFloat(ParseFormula(buffer, alive));

					if(cfg.Get("max", buffer, sizeof(buffer)))
					{
						int limit = RoundFloat(ParseFormula(buffer, alive));
						if(limit >= 0 && level > limit)
							level = limit;
					}

					SetEntProp(client, Prop_Data, "m_iAmmo", level, _, quality);
				}
			}
			
			if(index != 735 && StrEqual(classname2, "tf_weapon_builder"))
			{
				for(level = 0; level < 4; level++)
				{
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", level != 3, _, level);
				}
			}
			else if(index == 735 || StrEqual(classname2, "tf_weapon_sapper"))
			{
				SetEntProp(entity, Prop_Send, "m_iObjectType", TFObject_Sapper);
				SetEntProp(entity, Prop_Data, "m_iSubType", TFObject_Sapper);
				
				for(level = 0; level < 4; level++)
				{
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", level == 3, _, level);
				}
			}
		}

		override = wearable;
		cfg.GetBool("show", override, false);
		if(override)
		{
			if(cfg.GetInt("worldmodel", index) && index)
			{
				if(!wearable)
					SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", index);
				
				for(level = 0; level < 4; level++)
				{
					SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", index, _, level);
				}
			}
			
			float scale = 1.0;
			if(cfg.GetFloat("scale", scale) && scale != 1.0)
				SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
			
			int offset = FindSendPropInfo(netclass, "m_iItemIDHigh");
			
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
		
		level = 255;
		index = 255;
		kills = 255;
		count = 255;
		
		override = view_as<bool>(cfg.GetInt("alpha", level));
		override = (cfg.GetInt("red", index) || override);
		override = (cfg.GetInt("green", kills) || override);
		override = (cfg.GetInt("blue", count) || override);
		
		if(override)
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, index, kills, count, level);
		}
		
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		
		if(!wearable && equip && slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
		{
			equip = false;
			TF2U_SetPlayerActiveWeapon(client, entity);
		}
	}
	else if(forceClass != TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, class, _, false);
	}

	Event event = CreateEvent("localplayer_pickup_weapon", true);
	event.FireToClient(client);
	event.Cancel();

	return entity;
}

stock int TF2Items_CreateFromStruct(int client, const WeaponData data)
{
	static char buffer[64];
	
	TFClassType class = TF2_GetPlayerClass(client);
	GetClassWeaponClassname(class, data.Classname, sizeof(data.Classname));
	bool wearable = StrContains(data.Classname, "tf_weap") != 0;
	
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

#if defined IS_MAIN_FF2
	int alive = TotalPlayersAliveEnemy(Cvar[FriendlyFire].BoolValue ? -1 : GetClientTeam(client));
#else
	int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
#endif

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
				TF2Items_SetAttribute(item, a++, attrib, ParseFormula(buffers[attribs+1], alive));
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
				if(data.Forumla)
				{
					Attrib_Set(entity, _, attrib, ParseFormula(buffers[attribs+1], alive));
				}
				else
				{
					Attrib_SetString(entity, _, attrib, buffers[attribs+1]);
				}
			}
			else
			{
				ThrowError("Bad weapon attribute passed for '%s' : %s ; %s", data.Classname, buffers[attribs], buffers[attribs+1]);
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
				kills = RoundFloat(ParseFormula(data.Clip, alive));
				if(kills >= 0)
					SetEntProp(entity, Prop_Data, "m_iClip1", kills);
			}
			
			if(data.Ammo[0])
			{
				int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				if(type >= 0)
				{
					kills = RoundFloat(ParseFormula(data.Ammo, alive));

					if(data.MaxAmmo[0])
					{
						int limit = RoundFloat(ParseFormula(data.MaxAmmo, alive));
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
		
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		
		if(!wearable && data.Equip && slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
		{
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

	return entity;
}