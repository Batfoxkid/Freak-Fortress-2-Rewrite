/*
	void Preference_PluginStart()
	void Preference_AddBoss(int client, const char[] name)
	bool Preference_GetBoss(int client, int index, char[] buffer, int length)
	void Preference_ClearBosses(int client)
	bool Preference_DisabledBoss(int client, int charset)
	int Preference_PickBoss(int client, int team)
	void Preference_BossMenu(int client)
*/

static int BossOverride = -1;
static int ViewingPack[MAXTF2PLAYERS];
static int ViewingPage[MAXTF2PLAYERS];
static int ViewingBoss[MAXTF2PLAYERS];
static ArrayList BossListing[MAXTF2PLAYERS];

void Preference_PluginStart()
{
	//TODO: Rewrite to a Whitelist/Blacklist type system using Databases for per-map stuff
	RegFreakCmd("boss", Preference_BossMenuCmd, "Freak Fortress 2 Boss Selection");
	RegConsoleCmd("sm_boss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	RegConsoleCmd("sm_setboss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);

	RegAdminCmd("ff2_special", Preference_ForceBossCmd, ADMFLAG_CHEATS, "Force a specific boss to appear");
}

void Preference_AddBoss(int client, const char[] name)
{
	if(!BossListing[client])
		BossListing[client] = new ArrayList();
	
	if(name[0] == '#')
	{
		BossListing[client].Push(-1-StringToInt(name[1]));
	}
	else
	{
		int special = Bosses_GetByName(name, true, false, _, "filename");
		if(special != -1 && Bosses_CanAccessBoss(client, special, false, _, false))
			BossListing[client].Push(special);
	}
}

void Preference_ClearGroups(int client)
{
	// TODO: When Party Menu is added, don't add group bosses to the arraylist
	if(BossListing[client])
	{
		int value;
		int length = BossListing[client].Length;
		for(int i; i<length; i++)
		{
			ConfigMap cfg = Bosses_GetConfig(BossListing[client].Get(i));
			if(cfg && cfg.GetInt("companion", value))
			{
				BossListing[client].Erase(i);
				i--;
				length--;
			}
		}
	}
}

bool Preference_GetBoss(int client, int index, char[] buffer, int length)
{
	if(!BossListing[client] || index >= BossListing[client].Length)
		return false;
	
	int special = BossListing[client].Get(index);
	if(special < 0)
	{
		FormatEx(buffer, length, "#%d", -1-special);
	}
	else
	{
		Bosses_GetBossName(special, buffer, length, _, "filename");
	}
	return true;
}

void Preference_ClearBosses(int client)
{
	delete BossListing[client];
}

bool Preference_DisabledBoss(int client, int charset)
{
	if(BossListing[client])
	{
		if(BossListing[client].FindValue(-1-charset) != -1)
			return true;
	}
	return false;
}

int Preference_PickBoss(int client, int team=-1)
{
	int special = BossOverride;
	if(special == -1)
	{
		ArrayList list = new ArrayList();
		int length = Bosses_GetConfigLength();
		for(int i; i<length; i++)
		{
			if(Bosses_CanAccessBoss(client, i, true, team))
				list.Push(i);
		}
		
		char buffer[64];
		length = list.Length;
		if(length)
		{
			int count = CvarPrefBlacklist.IntValue;
			if(BossListing[client] && count != 0)
			{
				ArrayList list2 = count > 0 ? list.Clone() : new ArrayList();
				
				bool found;
				int length2 = BossListing[client].Length;
				for(int i; i<length2; i++)
				{
					special = BossListing[client].Get(i);
					int index = count > 0 ? list2.FindValue(special) : list.FindValue(special);
					if(index != -1)
					{
						if(count > 0)
						{
							list2.Erase(index);
						}
						else
						{
							list2.Push(special);
						}
						
						found = true;
					}
				}
				
				if(found)
				{
					delete list;
					list = list2;
					length = list2.Length;
				}
				else
				{
					delete list2;
				}
			}
			
			if(length > 1 && Client(client).GetLastPlayed(buffer, sizeof(buffer)))
			{
				count = list.FindValue(Bosses_GetByName(buffer, true, _, _, "filename"));
				if(count != -1)
				{
					list.Erase(count);
					length--;
				}
			}
			
			count = 0;
			int[] bosses = new int[MaxClients];
			for(int i=1; i<=MaxClients; i++)
			{
				if(i != client && Client(i).IsBoss)
					bosses[count++] = i;
			}
			
			if(length > count)
			{
				for(int i; i<count; i++)
				{
					if(Client(bosses[i]).Cfg.GetInt("special", special))
					{
						special = list.FindValue(special);
						if(special != -1)
						{
							list.Erase(special);
							length--;
						}
					}
				}
			}
			
			if(Client(client).Index < 0)
			{
				for(int i; ; i++)
				{
					if(FindClientOfBossIndex(i) == -1)
					{
						Client(client).Index = i;
						break;
					}
				}
			}
			
			special = list.Get((GetTime() + client) % length);
			delete list;
			
			ForwardOld_OnSpecialSelected(Client(client).Index, special, false);
		}
		else
		{
			delete list;
			Bosses_GetCharset(Charset, buffer, sizeof(buffer));
			LogError("[!!!] Could not find a valid boss in %s (#%d)", buffer, Charset);
			return special;
		}
	}
	else
	{
		ForwardOld_OnSpecialSelected(Client(client).Index, special, true);
	}
	
	return special;
}

public Action Preference_BossMenuLegacy(int client, int args)
{
	FReplyToCommand(client, "%t", "Legacy Boss Menu Command");
	
	if(client)
	{
		ViewingPack[client] = Enabled ? Charset : -1;
		ViewingPage[client] = 0;
		ViewingBoss[client] = -1;
		BossMenu(client);
	}
	return Plugin_Handled;
}

public Action Preference_BossMenuCmd(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		int blacklist = CvarPrefBlacklist.IntValue;
		if(args && blacklist != 0)
		{
			char buffer[64];
			GetCmdArgString(buffer, sizeof(buffer));
			
			int special = -1;
			if(buffer[0] == '#')
			{
				special = StringToInt(buffer[1]);
			}
			else
			{
				special = Bosses_GetByName(buffer, false, false, GetClientLanguage(client));
			}
			
			if(Bosses_CanAccessBoss(client, special, false, _, false))
			{
				// Needed to avoid duel selecting
				if(GetClientMenu(client) != MenuSource_None)
					CancelClientMenu(client);
				
				int index;
				if(BossListing[client] && (index=BossListing[client].FindValue(special)) != -1)
				{
					BossListing[client].Erase(index);
					
					if(blacklist > 0)
					{
						Bosses_GetConfig(special).GetInt("charset", index);
						index = GetBlacklistCount(client, index);
						FReplyToCommand(client, "%t (%d / %d)", "Boss Whitelisted", index, blacklist);
					}
					else
					{
						FReplyToCommand(client, "%t", "Boss Blacklisted");
					}
				}
				else if(blacklist > 0)
				{
					Bosses_GetConfig(special).GetInt("charset", index);
					index = GetBlacklistCount(client, index);
					if(index < blacklist)
					{
						BossListing[client].Push(special);
						FReplyToCommand(client, "%t (%d / %d)", "Boss Blacklisted", index+1, blacklist);
					}
					else
					{
						FReplyToCommand(client, "%t", "Boss Blacklist Full", index);
					}
				}
				else
				{
					BossListing[client].Push(special);
					ReplyToCommand(client, "%t", "Boss Whitelisted");
				}
			}
			else
			{
				FReplyToCommand(client, "%t", "Boss No View");
			}
		}
		else if(client)
		{
			DataPack pack = new DataPack();
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(0);
			RequestFrame(Preference_DisplayBosses, pack);
		}
		else
		{
			char buffer[64];
			
			ConfigMap cfg;
			for(int i; (cfg = Bosses_GetConfig(i)); i++)
			{
				Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer));
				PrintToServer("#%d %s", i, buffer);
			}
		}
	}
	else if(args)
	{
		char buffer[64];
		GetCmdArgString(buffer, sizeof(buffer));
		
		if(buffer[0] == '#')
		{
			ViewingBoss[client] = StringToInt(buffer[1]);
		}
		else
		{
			ViewingBoss[client] = Bosses_GetByName(buffer, false, false, GetClientLanguage(client));
		}
		
		Menu_Command(client);
		BossMenu(client);
	}
	else
	{
		ViewingPack[client] = Enabled ? Charset : -1;
		ViewingPage[client] = 0;
		ViewingBoss[client] = -1;
		
		Menu_Command(client);
		BossMenu(client);
	}
	return Plugin_Handled;
}

void Preference_BossMenu(int client)
{
	ViewingPack[client] = Bosses_GetCharsetLength() > 1 ? -1 : 0;
	ViewingPage[client] = 0;
	ViewingBoss[client] = -1;
	BossMenu(client);
}

static void BossMenu(int client)
{
	int blacklist = CvarPrefBlacklist.IntValue;
	Menu menu = new Menu(Preference_BossMenuH);
	
	SetGlobalTransTarget(client);
	int lang = GetClientLanguage(client);
	
	char data[64], buffer[512];
	if(ViewingBoss[client] >= 0)
	{
		if(Bosses_CanAccessBoss(client, ViewingBoss[client], false, _, false))
		{
			if(ViewingPack[client] >= 0)
			{
				Bosses_GetCharset(ViewingPack[client], data, sizeof(data));
				if(Bosses_GetBossName(ViewingBoss[client], buffer, sizeof(buffer), lang, "description"))
				{
					menu.SetTitle("%t%s\n \n%s\n ", "Boss Selection Command", data, buffer);
				}
				else
				{
					menu.SetTitle("%t%s\n \n%s\n ", "Boss Selection Command", data, buffer);
				}
			}
			else if(Bosses_GetBossName(ViewingBoss[client], buffer, sizeof(buffer), lang, "description"))
			{
					menu.SetTitle("%t\n%s\n ", "Boss Selection Command", buffer);
			}
			
			if(blacklist != 0)
			{
				int count;
				if(BossListing[client] && BossListing[client].FindValue(ViewingBoss[client]) != -1)
				{
					if(blacklist > 0)
					{
						int charset = ViewingPack[client];
						if(charset < 0)
							Bosses_GetConfig(ViewingBoss[client]).GetInt("charset", charset);
						
						count = GetBlacklistCount(client, charset);
						
						Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang);
						FormatEx(buffer, sizeof(buffer), "%t (%d / %d)", "Boss Whitelist", data, count, blacklist);
					}
					else
					{
						Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang);
						FormatEx(buffer, sizeof(buffer), "%t", "Boss Blacklist", data);
					}
					
					menu.AddItem("0", buffer);
				}
				else if(Bosses_GetConfig(ViewingBoss[client]).GetInt("companion", count))
				{
					if(blacklist > 0)
					{
						menu.AddItem("0", " ", ITEMDRAW_NOTEXT);
					}
					else
					{
						if(!Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang, "group"))
							Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang);
						
						FormatEx(buffer, sizeof(buffer), "%t", "Boss Party", data);
						menu.AddItem("2", buffer);
					}
				}
				else if(blacklist > 0)
				{
					int charset = ViewingPack[client];
					if(charset < 0)
						Bosses_GetConfig(ViewingBoss[client]).GetInt("charset", charset);
					
					count = GetBlacklistCount(client, charset);
					
					Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang);
					FormatEx(buffer, sizeof(buffer), "%t (%d / %d)", "Boss Blacklist", data, count, blacklist);
					menu.AddItem(count >= blacklist ? "0" : "1", buffer, count >= blacklist ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
				}
				else
				{
					Bosses_GetBossName(ViewingBoss[client], data, sizeof(data), lang);
					FormatEx(buffer, sizeof(buffer), "%t", "Boss Whitelist", data);
					menu.AddItem("1", buffer);
				}
			}
			else
			{
				menu.AddItem("0", " ", ITEMDRAW_NOTEXT);
			}
			
			menu.ExitBackButton = true;
		}
		else if(ViewingPack[client] >= 0)
		{
			Bosses_GetCharset(ViewingPack[client], data, sizeof(data));
			menu.SetTitle("%t%s\n%t", "Boss Selection Command", data, "Boss No View");
			menu.AddItem("0", " ", ITEMDRAW_NOTEXT);
		}
		else
		{
			menu.SetTitle("%t%t", "Boss Selection Command", "Boss No View");
			menu.AddItem("0", " ", ITEMDRAW_NOTEXT);
		}
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(ViewingPack[client] >= 0)
	{
		if(Bosses_GetCharset(ViewingPack[client], data, sizeof(data)))
		{
			menu.SetTitle("%t%s\n ", "Boss Selection Command", data);
			
			bool found;
			int index;
			ConfigMap cfg;
			for(int i; (cfg = Bosses_GetConfig(i)); i++)
			{
				if(cfg.GetInt("charset", index) && index == ViewingPack[client] && Bosses_CanAccessBoss(client, i, false, _, false))
				{
					Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
					if(blacklist != 0 && BossListing[client] && BossListing[client].FindValue(i) != -1)
					{
						found = true;
						Format(buffer, sizeof(buffer), "%s %s", buffer, blacklist > 0 ? "❎" : "☑");
					}
					
					IntToString(i, data, sizeof(data));
					menu.AddItem(data, buffer);
				}
			}
			
			if(Preference_DisabledBoss(client, ViewingPack[client]))
			{
				FormatEx(data, sizeof(data), "%t", "Enable Playing Boss");
				menu.InsertItem(0, "-3", data);
			}
			else if(found)
			{
				FormatEx(data, sizeof(data), "%t", blacklist > 0 ? "Clear Blacklist" : "Clear Whitelist");
				menu.InsertItem(0, "-1", data);
			}
			else
			{
				FormatEx(data, sizeof(data), "%t", "Disable Playing Boss");
				menu.InsertItem(0, "-2", data);
			}
		}
		else
		{
			menu.SetTitle("%t", "Boss Selection Command", data);
			
			FormatEx(buffer, sizeof(buffer), "%t", "Charset No View");
			menu.AddItem("-3", buffer, ITEMDRAW_RAWLINE);
		}
		
		menu.ExitBackButton = (Menu_BackButton(client) || Bosses_GetCharsetLength() > 1);
		menu.DisplayAt(client, ViewingPage[client], MENU_TIME_FOREVER);
	}
	else
	{
		menu.SetTitle("%t", "Boss Selection Command");
		
		int disables, enables;
		
		int length = Bosses_GetCharsetLength();
		for(int i; i<length; i++)
		{
			if(Preference_DisabledBoss(client, i))
			{
				disables++;
			}
			else
			{
				enables++;
			}
		}
		
		// Show if any boss pack has one disabled
		if(disables)
		{
			FormatEx(data, sizeof(data), "%t", "Enable Playing Boss All");
			menu.AddItem("-3", data);
		}
		
		// Show if any boss pack doesn't have one disaabled
		if(enables)
		{
			FormatEx(data, sizeof(data), "%t", "Disable Playing Boss All");
			menu.AddItem("-2", data);
		}
		
		// Show if boss pack has a listing that's not related to disables
		if(BossListing[client] && BossListing[client].Length > disables)
		{
			FormatEx(data, sizeof(data), "%t", "Clear All");
			menu.AddItem("-1", data);
		}
		
		for(int i; i<length; i++)
		{
			Bosses_GetCharset(i, buffer, sizeof(buffer));
			if(Enabled && i == Charset)
				Format(buffer, sizeof(buffer), "%s ✓", buffer);
			
			IntToString(i, data, sizeof(data));
			menu.AddItem(data, buffer);
		}
		
		menu.ExitBackButton = Menu_BackButton(client);
		menu.DisplayAt(client, ViewingPage[client], MENU_TIME_FOREVER);
	}
}

public int Preference_BossMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
			{
				if(ViewingBoss[client] >= 0)
				{
					ViewingBoss[client] = -1;
					BossMenu(client);
					ViewingPage[client] = 0;
				}
				else if(ViewingPack[client] >= 0 && Bosses_GetCharsetLength() > 1)
				{
					ViewingPack[client] = -1;
					BossMenu(client);
					ViewingPage[client] = 0;
				}
				else
				{
					Menu_MainMenu(client);
				}
			}
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			int value = StringToInt(buffer);
			
			if(ViewingBoss[client] >= 0)
			{
				switch(value)
				{
					/*case 2:
					{
						// TODO: Party System Here
					}*/
					case 1, 2:
					{
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						BossListing[client].Push(ViewingBoss[client]);
						ViewingBoss[client] = -1;
					}
					default:
					{
						if(BossListing[client])
						{
							value = BossListing[client].FindValue(ViewingBoss[client]);
							if(value != -1)
								BossListing[client].Erase(value);
						}
						
						ViewingBoss[client] = -1;
					}
				}
				
				BossMenu(client);
				ViewingPage[client] = 0;
			}
			else if(ViewingPack[client] >= 0)
			{
				switch(value)
				{
					case -3:
					{
						if(BossListing[client])
						{
							value = BossListing[client].FindValue(-1-ViewingPack[client]);
							if(value != -1)
								BossListing[client].Erase(value);
						}
					}
					case -2:
					{
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						BossListing[client].Push(-1-ViewingPack[client]);
					}
					case -1:
					{
						if(BossListing[client])
						{
							int length = BossListing[client].Length;
							for(int i; i<length; i++)
							{
								ConfigMap cfg = Bosses_GetConfig(BossListing[client].Get(i));
								if(cfg && cfg.GetInt("charset", value) && value == ViewingPack[client])
								{
									BossListing[client].Erase(i);
									i--;
									length--;
								}
							}
						}
					}
					default:
					{
						ViewingBoss[client] = value;
					}
				}
				
				BossMenu(client);
				if(value >= 0)
					ViewingPage[client] = choice / 7 * 7;
			}
			else
			{
				switch(value)
				{
					case -3:
					{
						if(BossListing[client])
						{
							int length = BossListing[client].Length;
							for(int i; i<length; i++)
							{
								if(BossListing[client].FindValue(i) < 0)
								{
									BossListing[client].Erase(i);
									i--;
									length--;
								}
							}
						}
					}
					case -2:
					{
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						int length = -1-Bosses_GetCharsetLength();
						for(int i = -1; i > length; i--)
						{
							if(BossListing[client].FindValue(i) == -1)
								BossListing[client].Push(i);
						}
					}
					case -1:
					{
						delete BossListing[client];
						BossListing[client] = null;
					}
					default:
					{
						ViewingPack[client] = value;
					}
				}
				
				BossMenu(client);
				if(value >= 0)
					ViewingPage[client] = choice / 7 * 7;
			}
		}
	}
}

public Action Preference_ForceBossCmd(int client, int args)
{
	if(args)
	{
		char name[64];
		GetCmdArgString(name, sizeof(name));
		
		SetGlobalTransTarget(client);
		int lang = client ? GetClientLanguage(client) : GetServerLanguage();
		
		int special = -1;
		if(name[0] == '#')
		{
			special = StringToInt(name[1]);
		}
		else
		{
			special = Bosses_GetByName(name, false, _, lang);
		}
		
		if(special == -1)
		{
			FReplyToCommand(client, "%t", "Boss Not Found");
		}
		else if(!client || Bosses_CanAccessBoss(client, special, true))
		{
			BossOverride = special;
			Bosses_GetBossName(special, name, sizeof(name), lang);
			FReplyToCommand(client, "%t", "Boss Overriden", name);
		}
		else
		{
			Bosses_GetBossName(special, name, sizeof(name), lang);
			FReplyToCommand(client, "%t", "Boss No Access", name);
		}
	}
	else if(client)
	{
		ForceBossMenu(client, 0);
	}
	else if(BossOverride != -1)
	{
		BossOverride = -1;
		FReplyToCommand(client, "%t", "No Boss Overriden");
	}
	else
	{
		PrintToServer("[SM] Usage: ff2_special <name / #index>");
	}
	return Plugin_Handled;
}

static void ForceBossMenu(int client, int item)
{
	Menu menu = new Menu(Preference_ForceBossMenuH);
	
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Boss Override Command");
	
	char name[64];
	FormatEx(name, sizeof(name), "%t", "No Override");
	menu.AddItem("-1", name, BossOverride == -1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	char num[12];
	int lang = GetClientLanguage(client);
	int length = Bosses_GetConfigLength();
	for(int i; i<length; i++)
	{
		if(Bosses_CanAccessBoss(client, i, true))
		{
			IntToString(i, num, sizeof(num));
			Bosses_GetBossName(i, name, sizeof(name), lang);
			menu.AddItem(num, name, BossOverride == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
	}
	
	menu.DisplayAt(client, item/7*7, MENU_TIME_FOREVER);
}

public int Preference_ForceBossMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				Menu_MainMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[12];
			menu.GetItem(choice, buffer, sizeof(buffer));
			BossOverride = StringToInt(buffer);
			
			ForceBossMenu(client, choice);
		}
	}
}

static int GetBlacklistCount(int client, int charset)
{
	int count = 0;
	if(BossListing[client])
	{
		int value;
		int length = BossListing[client].Length;
		for(int i; i<length; i++)
		{
			ConfigMap cfg = Bosses_GetConfig(BossListing[client].Get(i));
			if(cfg && cfg.GetInt("charset", value) && value == charset)
				count++;
		}
	}
	return count;
}

public void Preference_DisplayBosses(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		int index = pack.ReadCell();
		ConfigMap cfg = Bosses_GetConfig(index);
		if(cfg)
		{
			char buffer[64];
			Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), GetClientLanguage(client));
			PrintToConsole(client, "#%d %s", index, buffer);
			
			pack.Position--;
			pack.WriteCell(index+1, false);
			RequestFrame(Preference_DisplayBosses, pack);
			return;
		}
	}
	
	delete pack;
}