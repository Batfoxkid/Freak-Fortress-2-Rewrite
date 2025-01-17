#pragma semicolon 1
#pragma newdecls required

#define FILE_DIFF	"data/freak_fortress_2/modifiers.cfg"

static ConfigMap Difficulties;
static int BossOverride = -1;
static int ViewingPack[MAXTF2PLAYERS];
static int ViewingPage[MAXTF2PLAYERS];
static int ViewingBoss[MAXTF2PLAYERS];
static int PartyLeader[MAXTF2PLAYERS];
static int PartyChoice[MAXTF2PLAYERS];
static int PartyMainBoss[MAXTF2PLAYERS];
static int PartyInvite[MAXTF2PLAYERS][MAXTF2PLAYERS];
static bool UpdateDataBase[MAXTF2PLAYERS];
static char DiffOverride[MAXTF2PLAYERS][64];
static ArrayList BossListing[MAXTF2PLAYERS];
static ArrayList DiffListing[MAXTF2PLAYERS];

void Preference_PluginStart()
{
	RegFreakCmd("boss", Preference_BossMenuCmd, "Freak Fortress 2 Boss Selection");
	RegFreakCmd("party", Preference_BossMenuCmd, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	RegConsoleCmd("sm_boss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	RegConsoleCmd("sm_setboss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	RegFreakCmd("modifier", Preference_DifficultyMenuCmd, "Freak Fortress 2 Boss Modifiers");
	RegFreakCmd("modifiers", Preference_DifficultyMenuCmd, "Freak Fortress 2 Boss Modifiers", FCVAR_HIDDEN);
	RegFreakCmd("difficulty", Preference_DifficultyMenuCmd, "Freak Fortress 2 Boss Modifiers", FCVAR_HIDDEN);
	RegFreakCmd("special", Preference_DifficultyMenuCmd, "Freak Fortress 2 Boss Modifiers", FCVAR_HIDDEN);
	
	RegAdminCmd("ff2_override", Preference_ForceBossCmd, ADMFLAG_CHEATS, "Force a specific boss to appear");
	
	for(int a; a < sizeof(PartyInvite); a++)
	{
		for(int b; b < sizeof(PartyInvite[]); b++)
		{
			PartyInvite[a][b] = -1;
		}
	}
}

void Preference_ConfigsExecuted()
{
	if(Difficulties)
		DeleteCfg(Difficulties);
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FILE_DIFF);
	if(FileExists(buffer))
	{
		Difficulties = new ConfigMap(FILE_DIFF);
		
		StringMapSnapshot snap = Difficulties.Snapshot();
		
		if(!snap.Length)
		{
			DeleteCfg(Difficulties);
			Difficulties = null;
		}
		
		delete snap;
	}
	else
	{
		Difficulties = null;
	}
}

void Preference_MapEnd()
{
	BossOverride = -1;
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

void Preference_AddDifficulty(int client, const char[] name)
{
	if(!DiffListing[client])
		DiffListing[client] = new ArrayList(ByteCountToCells(64));
	
	DiffListing[client].PushString(name);
}

bool Preference_ShouldUpdate(int client)
{
	return UpdateDataBase[client];
}

bool Preference_GetBoss(int client, int index, char[] buffer, int length)
{
	if(!BossListing[client] || index >= BossListing[client].Length)
		return false;
	
	int special = BossListing[client].Get(index);
	if(special < 0)
	{
		Format(buffer, length, "#%d", -1-special);
	}
	else
	{
		Bosses_GetBossName(special, buffer, length, _, "filename");
	}
	return true;
}

bool Preference_GetDifficulty(int client, int index, char[] buffer, int length)
{
	if(!DiffListing[client] || index >= DiffListing[client].Length)
		return false;
	
	DiffListing[client].GetString(index, buffer, length);
	return true;
}

void Preference_ClearArrays(int client)
{
	UpdateDataBase[client] = false;
	DiffOverride[client][0] = 0;
	
	delete BossListing[client];
	delete DiffListing[client];
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

int Preference_PickBoss(int client, int team = -1)
{
	int special = BossOverride;
	if(special == -1)
	{
		if(PartyLeader[client])
		{
			special = PartyMainBoss[PartyLeader[client]];
		}
		else
		{
			ArrayList list = new ArrayList();
			int length = Bosses_GetConfigLength();
			for(int i; i < length; i++)
			{
				if(Bosses_CanAccessBoss(client, i, true, team))
					list.Push(i);
			}
			
			char buffer[64];
			length = list.Length;
			if(length)
			{
				int count = Cvar[PrefBlacklist].IntValue;
				if(BossListing[client] && count != 0)
				{
					ArrayList list2 = count > 0 ? list.Clone() : new ArrayList();
					
					bool found;
					int length2 = BossListing[client].Length;
					for(int i; i < length2; i++)
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
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != client && Client(i).IsBoss)
						bosses[count++] = i;
				}
				
				if(length > count)
				{
					for(int i; i < count; i++)
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
				ForwardOld_OnSpecialSelected(Client(client).Index, special, false);
			}
			else
			{
				Bosses_GetCharset(Charset, buffer, sizeof(buffer));
				LogError("[!!!] Could not find a valid boss in %s (#%d)", buffer, Charset);
			}
			
			delete list;
			return special;
		}
	}
	
	ForwardOld_OnSpecialSelected(Client(client).Index, special, true);
	return special;
}

static Action Preference_BossMenuLegacy(int client, int args)
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

static Action Preference_BossMenuCmd(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		int blacklist = Cvar[PrefBlacklist].IntValue;
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
				
				Bosses_GetBossName(special, buffer, sizeof(buffer), GetClientLanguage(client));
				ConfigMap cfg = Bosses_GetConfig(special);
				
				int index;
				if(BossListing[client] && (index = BossListing[client].FindValue(special)) != -1)
				{
					UpdateDataBase[client] = true;
					BossListing[client].Erase(index);
					
					if(blacklist > 0)
					{
						cfg.GetInt("charset", index);
						index = GetBlacklistCount(client, index);
						FReplyToCommand(client, "%t (%d / %d)", "Boss Whitelisted", buffer, index, blacklist);
					}
					else
					{
						FReplyToCommand(client, "%t", "Boss Blacklisted", buffer);
					}
				}
				else if(cfg.GetInt("companion", index))
				{
					bool enabled;
					if(blacklist > 0 || !cfg.GetBool("enabled", enabled) || !enabled)
					{
						FReplyToCommand(client, "%t", "Boss No View");
					}
					else
					{
						ViewingBoss[client] = special;
						CreateParty(client);
					}
				}
				else if(blacklist > 0)
				{
					cfg.GetInt("charset", index);
					index = GetBlacklistCount(client, index);
					if(index < blacklist)
					{
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						UpdateDataBase[client] = true;
						BossListing[client].Push(special);
						FReplyToCommand(client, "%t (%d / %d)", "Boss Blacklisted", buffer, index+1, blacklist);
					}
					else
					{
						FReplyToCommand(client, "%t", "Boss Blacklist Full", index);
					}
				}
				else
				{
					if(!BossListing[client])
						BossListing[client] = new ArrayList();
					
					UpdateDataBase[client] = true;
					BossListing[client].Push(special);
					FReplyToCommand(client, "%t", "Boss Whitelisted", buffer);
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
		if(!PartyMenu(client))
			BossMenu(client);
	}
	return Plugin_Handled;
}

void Preference_BossMenu(int client)
{
	ViewingPack[client] = Bosses_GetCharsetLength() > 1 ? -1 : 0;
	ViewingPage[client] = 0;
	ViewingBoss[client] = -1;
	
	if(!PartyMenu(client))
		BossMenu(client);
}

static void BossMenu(int client)
{
	int blacklist = Cvar[PrefBlacklist].IntValue;
	Menu menu = new Menu(Preference_BossMenuH);
	
	SetGlobalTransTarget(client);
	int lang = GetClientLanguage(client);
	
	char data[64], buffer[512];
	if(ViewingBoss[client] >= 0)
	{
		bool preview;
		bool access = Bosses_CanAccessBoss(client, ViewingBoss[client], false, _, false, preview);
		if(access || preview)
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
					menu.SetTitle("%t%s\n \n%t\n ", "Boss Selection Command", data, "No Description");
				}
			}
			else if(Bosses_GetBossName(ViewingBoss[client], buffer, sizeof(buffer), lang, "description"))
			{
				menu.SetTitle("%t\n%s\n ", "Boss Selection Command", buffer);
			}
			else
			{
				menu.SetTitle("%t\n%t\n ", "Boss Selection Command", "No Description");
			}
			
			if(access && blacklist != 0)
			{
				int count;
				ConfigMap cfg = Bosses_GetConfig(ViewingBoss[client]);
				if(BossListing[client] && BossListing[client].FindValue(ViewingBoss[client]) != -1)
				{
					if(blacklist > 0)
					{
						int charset = ViewingPack[client];
						if(charset < 0)
							cfg.GetInt("charset", charset);
						
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
				else if(cfg.GetInt("companion", count))
				{
					if(blacklist > 0 || !cfg.GetBool("enabled", preview) || !preview)
					{
						menu.AddItem("0", NULL_STRING, ITEMDRAW_NOTEXT);
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
						cfg.GetInt("charset", charset);
					
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
				menu.AddItem("0", NULL_STRING, ITEMDRAW_NOTEXT);
			}
			
			menu.ExitBackButton = true;
		}
		else if(ViewingPack[client] >= 0)
		{
			Bosses_GetCharset(ViewingPack[client], data, sizeof(data));
			menu.SetTitle("%t%s\n%t", "Boss Selection Command", data, "Boss No View");
			menu.AddItem("0", NULL_STRING, ITEMDRAW_NOTEXT);
		}
		else
		{
			menu.SetTitle("%t%t", "Boss Selection Command", "Boss No View");
			menu.AddItem("0", NULL_STRING, ITEMDRAW_NOTEXT);
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
				if(cfg.GetInt("charset", index) && index == ViewingPack[client])
				{
					bool preview;
					bool access = Bosses_CanAccessBoss(client, i, false, _, false, preview);
					if(access || preview)
					{
						Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
						if(blacklist != 0)
						{
							if(PartyLeader[client] && PartyMainBoss[PartyLeader[client]] == i)
							{
								Format(buffer, sizeof(buffer), "[&] %s", buffer);
							}
							else if(BossListing[client] && BossListing[client].FindValue(i) != -1)
							{
								found = true;
								Format(buffer, sizeof(buffer), "[X] %s", buffer);
							}
							else if(access)
							{
								Format(buffer, sizeof(buffer), "[ ] %s", buffer);
							}
						}
						
						IntToString(i, data, sizeof(data));
						menu.AddItem(data, buffer);
					}
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
			else if(Cvar[PrefToggle].BoolValue)
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
		for(int i; i < length; i++)
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
		if(enables && Cvar[PrefToggle].BoolValue)
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
		
		for(int i; i < length; i++)
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

static int Preference_BossMenuH(Menu menu, MenuAction action, int client, int choice)
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
					case 2:
					{
						CreateParty(client);
					}
					case 1:
					{
						UpdateDataBase[client] = true;
						
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						BossListing[client].Push(ViewingBoss[client]);
						ViewingBoss[client] = -1;
						BossMenu(client);
					}
					default:
					{
						if(BossListing[client])
						{
							value = BossListing[client].FindValue(ViewingBoss[client]);
							if(value != -1)
							{
								UpdateDataBase[client] = true;
								BossListing[client].Erase(value);
							}
						}
						
						ViewingBoss[client] = -1;
						BossMenu(client);
					}
				}
				
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
							{
								UpdateDataBase[client] = true;
								BossListing[client].Erase(value);
							}
						}
					}
					case -2:
					{
						UpdateDataBase[client] = true;
						
						if(!BossListing[client])
							BossListing[client] = new ArrayList();
						
						BossListing[client].Push(-1-ViewingPack[client]);
					}
					case -1:
					{
						if(BossListing[client])
						{
							int length = BossListing[client].Length;
							for(int i; i < length; i++)
							{
								ConfigMap cfg = Bosses_GetConfig(BossListing[client].Get(i));
								if(cfg && cfg.GetInt("charset", value) && value == ViewingPack[client])
								{
									UpdateDataBase[client] = true;
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
							for(int i; i < length; i++)
							{
								if(BossListing[client].Get(i) < 0)
								{
									UpdateDataBase[client] = true;
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
							{
								UpdateDataBase[client] = true;
								BossListing[client].Push(i);
							}
						}
					}
					case -1:
					{
						if(BossListing[client])
						{
							UpdateDataBase[client] = true;
							delete BossListing[client];
						}
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
	return 0;
}

bool Preference_ClientDisconnect(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		PartyInvite[client][i] = -1;
	}
	
	if(!PartyLeader[client])
		return false;
	
	int newLeader;
	char buffer[64];
	for(int target = 1; target <= MaxClients; target++)
	{
		PartyInvite[target][client] = -1;
		
		if(target != client && PartyLeader[client] == PartyLeader[target])
		{
			if(PartyLeader[client] == client)
			{
				if(!newLeader)
					newLeader = target;
				
				PartyLeader[target] = newLeader;
			}
			
			if(newLeader)
			{
				Bosses_GetBossName(PartyChoice[client], buffer, sizeof(buffer), GetClientLanguage(target));
				FPrintToChat(target, "%t", "Party Leader Left", client, buffer, newLeader);
			}
			else
			{
				Bosses_GetBossName(PartyChoice[client], buffer, sizeof(buffer), GetClientLanguage(target));
				FPrintToChat(target, "%t", "Party Member Left", client, buffer);
			}
		}
	}
	
	PartyLeader[client] = 0;
	return true;
}

static void CreateParty(int client)
{
	if(PartyLeader[client] && PartyMainBoss[PartyLeader[client]] == ViewingBoss[client])
	{
		PartyMenu(client);
		return;
	}
	
	Preference_ClientDisconnect(client);
	
	Menu menu = new Menu(Preference_CreatePartyH);
	
	SetGlobalTransTarget(client);
	int lang = GetClientLanguage(client);
	
	int special = ViewingBoss[client];
	
	char data[12], buffer[64];
	if(!Bosses_GetBossName(special, buffer, sizeof(buffer), lang, "group"))
		Bosses_GetBossName(special, buffer, sizeof(buffer), lang);
	
	menu.SetTitle("%t", "Boss Party Menu", buffer);
	
	for(int i; i<MAXTF2PLAYERS; i++)	// In case someone made an infinite loop boss
	{
		ConfigMap cfg = Bosses_GetConfig(special);
		Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
		
		IntToString(special, data, sizeof(data));
		menu.AddItem(data, buffer);
		
		if(!cfg.GetInt("companion", special))
			break;
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

static int Preference_CreatePartyH(Menu menu, MenuAction action, int client, int choice)
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
				BossMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			PartyChoice[client] = StringToInt(buffer);
			PartyLeader[client] = client;
			
			menu.GetItem(0, buffer, sizeof(buffer));
			PartyMainBoss[client] = StringToInt(buffer);
			
			PartyMenu(client);
		}
	}
	return 0;
}

static bool PartyMenu(int client)
{
	if(!PartyLeader[client])
		return InviteMenu(client);
	
	Menu menu = new Menu(Preference_PartyMenuH);
	
	SetGlobalTransTarget(client);
	int lang = GetClientLanguage(client);
	
	int special = PartyMainBoss[PartyLeader[client]];
	
	char data[16], buffer[128];
	if(!Bosses_GetBossName(special, buffer, sizeof(buffer), lang, "group"))
		Bosses_GetBossName(special, buffer, sizeof(buffer), lang);
	
	menu.SetTitle("%t", "Boss Party Menu", buffer);
	
	bool leader = PartyLeader[client] == client;
	for(int i; i<MAXTF2PLAYERS; i++)	// In case someone made an infinite loop boss
	{
		ConfigMap cfg = Bosses_GetConfig(special);
		Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
		
		int target = FindPartyMember(PartyLeader[client], special);
		if(target)
		{
			Format(buffer, sizeof(buffer), "%t", (leader && client != target) ? "Boss Party Kick" : "Boss Party Member", buffer, target);
		}
		else
		{
			if(leader)
				target = FindPartyInvitee(PartyLeader[client], special);
			
			if(target)
			{
				Format(buffer, sizeof(buffer), "%t", "Boss Party Pending", buffer, target);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%t", leader ? "Boss Party Invite" : "Boss Party Blank", buffer);
			}
		}
		
		IntToString(special, data, sizeof(data));
		menu.AddItem(data, buffer, (leader && client == target) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		if(!cfg.GetInt("companion", special))
			break;
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "Boss Party Leave");
	menu.AddItem("-1", buffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return true;
}

static int Preference_PartyMenuH(Menu menu, MenuAction action, int client, int choice)
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
				BossMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			int special = StringToInt(buffer);
			
			if(special == -1)
			{
				Preference_ClientDisconnect(client);
				Bosses_GetBossName(PartyChoice[client], buffer, sizeof(buffer), GetClientLanguage(client));
				FPrintToChat(client, "%t", "Party You Left", buffer);
				BossMenu(client);
			}
			else if(PartyLeader[client] == client)
			{
				int target = FindPartyMember(PartyLeader[client], special);
				if(target)
				{
					PartyLeader[target] = 0;
					Bosses_GetBossName(PartyChoice[target], buffer, sizeof(buffer), GetClientLanguage(target));
					FPrintToChat(target, "%t", "Party You Kicked", buffer);
					
					for(int other = 1; other <= MaxClients; other++)
					{
						if(target != other && PartyLeader[client] == PartyLeader[other])
						{
							Bosses_GetBossName(PartyChoice[target], buffer, sizeof(buffer), GetClientLanguage(other));
							FPrintToChat(other, "%t", "Party Member Kicked", target, buffer);
						}
					}
					
					PartyMenu(client);
				}
				else
				{
					target = FindPartyInvitee(PartyLeader[client], special);
					if(target)
					{
						PartyInvite[target][client] = -1;
						PartyMenu(client);
					}
					else
					{
						SetGlobalTransTarget(client);
						
						PartyInvite[client][client] = special;
						
						Menu menu2 = new Menu(Preference_PartyInviteH);
						
						Bosses_GetBossName(special, buffer, sizeof(buffer), GetClientLanguage(client));
						menu2.SetTitle("%t\n ", "Boss Party Menu", buffer);
						
						char buffer2[16];
						for(target = 1; target <= MaxClients; target++)
						{
							if(IsClientInGame(target) && CanInviteMember(client, target))
							{
								IntToString(GetClientUserId(target), buffer2, sizeof(buffer2));
								GetClientName(target, buffer, sizeof(buffer));
								menu2.AddItem(buffer2, buffer);
							}
						}
						
						if(!buffer2[0])
							menu2.AddItem("-1", "N/A", ITEMDRAW_DISABLED);
						
						menu2.ExitBackButton = true;
						menu2.Display(client, MENU_TIME_FOREVER);
					}
				}
			}
			else
			{
				SetGlobalTransTarget(client);
				
				Menu menu2 = new Menu(Preference_PartyInviteH);
				if(Bosses_GetBossName(special, buffer, sizeof(buffer), GetClientLanguage(client), "description"))
				{
					menu2.SetTitle("%t\n%s\n ", "Boss Party Menu", NULL_STRING, buffer);
				}
				else
				{
					menu2.SetTitle("%t\n%t\n ", "Boss Party Menu", NULL_STRING, "No Description");
				}
				
				menu2.AddItem("-1", NULL_STRING, ITEMDRAW_NOTEXT);
				
				menu2.ExitBackButton = true;
				menu2.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

static int Preference_PartyInviteH(Menu menu, MenuAction action, int client, int choice)
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
				PartyMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			
			int target = GetClientOfUserId(StringToInt(buffer));
			if(target && CanInviteMember(client, target))
			{
				if(IsFakeClient(target))
				{
					PartyLeader[target] = client;
					PartyChoice[target] = PartyInvite[client][client];
					
					for(int other = 1; other <= MaxClients; other++)
					{
						if(target != other && PartyLeader[other] == client)
						{
							Bosses_GetBossName(PartyChoice[target], buffer, sizeof(buffer), GetClientLanguage(other));
							FPrintToChat(other, "%t", "Party Member Joined", target, buffer);
						}
					}
				}
				else
				{
					PartyInvite[target][client] = PartyInvite[client][client];
					
					Bosses_GetBossName(PartyInvite[client][client], buffer, sizeof(buffer), GetClientLanguage(target));
					FPrintToChat(target, "%t", "Party Member Invited", client, buffer);
				}
			}
			else
			{
				FPrintToChat(client, "%t", "Player no longer available");
			}
			
			PartyMenu(client);
		}
	}
	return 0;
}

static bool InviteMenu(int client)
{
	for(int target = 1; target <= MaxClients; target++)
	{
		if(client != target && PartyInvite[client][target] != -1)
		{
			Menu menu = new Menu(Preference_InviteMenuH);
			
			SetGlobalTransTarget(client);
			int lang = GetClientLanguage(client);
			
			int special = PartyMainBoss[PartyLeader[client]];
			
			char buffer1[64], buffer2[128];
			if(!Bosses_GetBossName(special, buffer1, sizeof(buffer1), lang, "group"))
				Bosses_GetBossName(special, buffer1, sizeof(buffer1), lang);
			
			Bosses_GetBossName(PartyInvite[client][target], buffer2, sizeof(buffer2), lang);
			
			menu.SetTitle("%t%t", "Boss Party Menu", buffer1, "Boss Party Invited", target, buffer2);
			
			IntToString(GetClientUserId(target), buffer2, sizeof(buffer2));
			FormatEx(buffer1, sizeof(buffer1), "%t", "Boss Party Accept");
			menu.AddItem(buffer2, buffer1);
			
			FormatEx(buffer1, sizeof(buffer1), "%t", "Boss Party Decline");
			menu.AddItem(buffer2, buffer1);
			
			FormatEx(buffer1, sizeof(buffer1), "%t", "Boss Party Block");
			menu.AddItem(buffer2, buffer1, ITEMDRAW_DISABLED);
			
			menu.Display(client, MENU_TIME_FOREVER);
			return true;
		}
	}
	return false;
}

static int Preference_InviteMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_Exit)
				BossMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			
			int target = GetClientOfUserId(StringToInt(buffer));
			if(target && PartyLeader[target] == target && PartyInvite[client][target] != -1)
			{
				if(choice)
				{
					Bosses_GetBossName(PartyInvite[client][target], buffer, sizeof(buffer), GetClientLanguage(target));
					FPrintToChat(target, "%t", "Party Member Left", client, buffer);
					
					PartyInvite[client][target] = -1;
				}
				else
				{
					PartyLeader[client] = target;
					PartyChoice[client] = PartyInvite[client][target];
					PartyInvite[client][target] = -1;
					
					for(int other = 1; other <= MaxClients; other++)
					{
						if(PartyInvite[client][other] != -1)
						{
							Bosses_GetBossName(PartyInvite[client][other], buffer, sizeof(buffer), GetClientLanguage(other));
							FPrintToChat(other, "%t", "Party Member Left", client, buffer);
							
							PartyInvite[client][other] = -1;
						}
						else if(client != other && PartyLeader[other] == target)
						{
							Bosses_GetBossName(PartyChoice[client], buffer, sizeof(buffer), GetClientLanguage(other));
							FPrintToChat(other, "%t", "Party Member Joined", client, buffer);
						}
					}
				}
			}
			else if(!choice)
			{
				FPrintToChat(client, "%t", "Player no longer available");
			}
			
			if(!PartyMenu(client))
				BossMenu(client);
		}
	}
	return 0;
}

static int FindPartyMember(int leader, int special)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(PartyLeader[client] == leader && PartyChoice[client] == special)
			return client;
	}
	return 0;
}

static int FindPartyInvitee(int leader, int special)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(leader != client && PartyInvite[client][leader] == special)
			return client;
	}
	return 0;
}

static bool CanInviteMember(int client, int target)
{
	// If they are already in a party or has an invite
	if(PartyLeader[target] || PartyInvite[target][client] != -1)
		return false;
	
	// If they have the client muted
	if(IsClientMuted(target, client))
		return false;
	
	// If their spectating
	if(GetClientTeam(target) <= TFTeam_Spectator && !IsPlayerAlive(target))
		return false;
	
	return true;
}

int Preference_IsInParty(int client)
{
	return PartyLeader[client];
}

void Preference_FinishParty(int client)
{
	PartyLeader[client] = 0;
	Client(client).Queue = 0;
}

int Preference_GetCompanion(int client, int special, int team, bool &disband)
{
	int count;
	int[] players = new int[MaxClients];
	for(int player = 1; player <= MaxClients; player++)
	{
		if(player != client && IsClientInGame(player) && !Client(player).IsBoss)
		{
			if(Enabled)
			{
				if(GetClientTeam(player) <= TFTeam_Spectator && !IsPlayerAlive(player))
					continue;
			}
			else if(GetClientTeam(player) != team)
			{
				continue;
			}
			
			players[count++] = player;
		}
	}
	
	if(count < (Enabled ? 2 : 1))	// Prevent arena mode softlock when one-sided
		return 0;
	
	if(Enabled && PartyLeader[client])
	{
		int player = FindPartyMember(PartyLeader[client], special);
		if(player && !Client(player).IsBoss)
		{
			disband = true;
			return player;
		}
	}
	
	return players[GetURandomInt() % count];
}

int Preference_GetFullQueuePoints(int client)
{
	int queue = Client(client).Queue;
	
	if(PartyLeader[client])
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && PartyLeader[client] == PartyLeader[target])
				queue += Client(target).Queue;
		}
		
		int special = PartyMainBoss[PartyLeader[client]];
		
		int i = 1;
		while(Bosses_GetConfig(special).GetInt("companion", special))
		{
			if(++i > MAXTF2PLAYERS)
				break;
		}
		
		queue /= i;
	}
	
	return queue;
}

int Preference_GetBossQueue(int[] players, int maxsize, bool display, int team = -1)
{
	int size;
	int[][] queue = new int[MaxClients][2];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!Client(client).IsBoss && IsClientInGame(client))
		{
			if(team == -1)
			{
				if(GetClientTeam(client) <= TFTeam_Spectator && !IsPlayerAlive(client))
					continue;
			}
			else if(GetClientTeam(client) != team)
			{
				continue;
			}
			
			if(PartyLeader[client])
			{
				if(!display && PartyMainBoss[PartyLeader[client]] != PartyChoice[client])
					continue;
			}
			else if(Preference_DisabledBoss(client, Charset))
			{
				continue;
			}
			
			queue[size][1] = Preference_GetFullQueuePoints(client);
			queue[size++][0] = client;
		}
	}
	
	SortCustom2D(queue, size, Preference_BossQueueSort);
	
	if(size > maxsize)
		size = maxsize;
	
	for(int i; i < size; i++)
	{
		players[i] = queue[i][0];
	}
	return size;
}

static int Preference_BossQueueSort(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[1] > elem2[1])
		return -1;
	
	if(elem1[1] < elem2[1])
		return 1;
	
	return (elem1[0] > elem2[0]) ? 1 : -1;
}

static Action Preference_ForceBossCmd(int client, int args)
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

		bool rcon = !client || CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON);
		
		if(special == -1)
		{
			FReplyToCommand(client, "%t", "Boss Not Found");
		}
		else if(rcon || Bosses_CanAccessBoss(client, special, false) || Bosses_CanAccessBoss(client, special, true))
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
	bool rcon = CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON);
	for(int i; i < length; i++)
	{
		if(rcon || Bosses_CanAccessBoss(client, i, false) || Bosses_CanAccessBoss(client, i, true))
		{
			IntToString(i, num, sizeof(num));
			Bosses_GetBossName(i, name, sizeof(name), lang);
			menu.AddItem(num, name, BossOverride == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
	}
	
	menu.DisplayAt(client, item/7*7, MENU_TIME_FOREVER);
}

static int Preference_ForceBossMenuH(Menu menu, MenuAction action, int client, int choice)
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
	return 0;
}

static int GetBlacklistCount(int client, int charset)
{
	int count = 0;
	if(BossListing[client])
	{
		int value;
		int length = BossListing[client].Length;
		for(int i; i < length; i++)
		{
			ConfigMap cfg = Bosses_GetConfig(BossListing[client].Get(i));
			if(cfg && cfg.GetInt("charset", value) && value == charset)
				count++;
		}
	}
	return count;
}

static void Preference_DisplayBosses(DataPack pack)
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

void Preference_ApplyDifficulty(int client, int leader, bool delay)
{
	if(Preference_HasDifficulties())
	{
		char choosen[64];
		if(!delay && DiffOverride[client][0])
		{
			strcopy(choosen, sizeof(choosen), DiffOverride[client]);
			DiffOverride[client][0] = 0;
		}
		else if(Cvar[PrefSpecial].BoolValue && Cvar[PrefSpecial].FloatValue >= GetURandomFloat())
		{
			if(!DiffListing[leader])
			{
				StringMapSnapshot snap = Difficulties.Snapshot();
				
				snap.GetKey((GetTime() + leader) % snap.Length, choosen, sizeof(choosen));
				
				delete snap;
			}
		}
		else if(DiffListing[leader])
		{
			int lengt = DiffListing[leader].Length;
			if(lengt)
				DiffListing[leader].GetString((GetTime() + leader) % lengt, choosen, sizeof(choosen));
		}
		
		if(choosen[0])
		{
			if(delay)
			{
				strcopy(DiffOverride[client], sizeof(DiffOverride[]), choosen);
			}
			else
			{
				ConfigMap cfg = Difficulties.GetSection(choosen);
				if(cfg)
				{
					char buffer1[128];
					StringMapSnapshot snap = cfg.Snapshot();
					
					PackVal val;
					int entries = snap.Length;
					for(int i; i < entries; i++)
					{
						int length = snap.KeyBufferSize(i)+5;
						char[] section = new char[length];
						snap.GetKey(i, section, length);
						if(cfg.GetArray(section, val, sizeof(val)) && val.tag == KeyValType_Section && val.cfg)
						{
							Format(section, length, "%s.smx", section);
							
							length = -2;
							
							Handle iterator = GetPluginIterator();
							
							while(MorePlugins(iterator))
							{
								Handle plugin = ReadPlugin(iterator);
								GetPluginFilename(plugin, buffer1, sizeof(buffer1));
								if(StrContains(buffer1, section, false) != -1)
								{
									Function func = GetFunctionByName(plugin, "FF2R_OnBossModifier");
									if(func != INVALID_FUNCTION)
									{
										Call_StartFunction(plugin, func);
										Call_PushCell(client);
										Call_PushCell(val.cfg);
										length = Call_Finish();
									}
									else
									{
										length = -1;
									}
									break;
								}
							}
							
							delete iterator;
							
							switch(length)
							{
								case -2:
									LogError("[Modifier] Plugin '%s' is missing for '%s'", section, choosen);
								
								case -1:
									LogError("[Modifier] Plugin '%s' is does not have modifiers for '%s'", section, choosen);
							}
						}
					}
					
					delete snap;
					
					// Set "name_X" and "group_X" for any present on the boss
					snap = Client(client).Cfg.Snapshot();
					
					char buffer2[64], buffer3[64], buffer4[64];
					entries = snap.Length;
					for(int i; i < entries; i++)
					{
						snap.GetKey(i, buffer3, sizeof(buffer3));
						if((!StrContains(buffer3, "name_") || !StrContains(buffer3, "group_")) && Client(client).Cfg.Get(buffer3, buffer2, sizeof(buffer2)))
						{
							strcopy(buffer4, sizeof(buffer4), buffer3);
							ReplaceStringEx(buffer4, sizeof(buffer4), "group_", "name_");
							if(!cfg.Get(buffer4, buffer1, sizeof(buffer1)))
							{
								if(!cfg.Get("name", buffer1, sizeof(buffer1)))
									strcopy(buffer1, sizeof(buffer1), choosen);
							}
							
							Format(buffer2, sizeof(buffer2), "%s [%s]", buffer2, buffer1);
							Client(client).Cfg.Set(buffer3, buffer2);
						}
					}
					
					delete snap;
					
					snap = cfg.Snapshot();
					
					entries = snap.Length;
					for(int i; i < entries; i++)
					{
						snap.GetKey(i, buffer3, sizeof(buffer3));
						if(!StrContains(buffer3, "name_") && cfg.Get(buffer3, buffer2, sizeof(buffer2)))
						{
							// Set "name_X" for any present on the diff but not on the boss
							if(!Client(client).Cfg.Get(buffer3, buffer1, sizeof(buffer1)))
							{
								Client(client).Cfg.Get("name", buffer1, sizeof(buffer1));
								Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, buffer2);
								Client(client).Cfg.Set(buffer3, buffer2);
							}
							
							// Set "group_X" for any present on the diff but not on the boss but has a group
							if(ReplaceStringEx(buffer3, sizeof(buffer3), "name_", "group_") != -1 && !Client(client).Cfg.Get(buffer3, buffer1, sizeof(buffer1)) && Client(client).Cfg.Get("group", buffer1, sizeof(buffer1)))
							{
								Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, buffer2);
								Client(client).Cfg.Set(buffer3, buffer2);
							}
						}
					}
					
					delete snap;
					
					// Set "name"
					Client(client).Cfg.Get("name", buffer1, sizeof(buffer1));
					if(cfg.Get("name", buffer2, sizeof(buffer2)))
					{
						Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, buffer2);
					}
					else
					{
						Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, choosen);
					}
					
					Client(client).Cfg.Set("name", buffer2);
					
					// Set "group"
					if(Client(client).Cfg.Get("group", buffer1, sizeof(buffer1)))
					{
						if(cfg.Get("name", buffer2, sizeof(buffer2)))
						{
							Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, buffer2);
						}
						else
						{
							Format(buffer2, sizeof(buffer2), "%s [%s]", buffer1, choosen);
						}
						
						Client(client).Cfg.Set("group", buffer2);
					}
				}
			}
		}
	}
}

bool Preference_HasDifficulties()
{
	return view_as<bool>(Difficulties);
}

static Action Preference_DifficultyMenuCmd(int client, int args)
{
	if(!Preference_HasDifficulties())
		return Plugin_Continue;
	
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		if(Cvar[PrefSpecial].BoolValue)
		{
			if(DiffListing[client])
			{
				delete DiffListing[client];
				FReplyToCommand(client, "%t", "Enabled Special Rounds");
			}
			else
			{
				Preference_AddDifficulty(client, "#");
				FReplyToCommand(client, "%t", "Disabled Special Rounds");
			}
			
			UpdateDataBase[client] = true;
		}
		else if(args && client)
		{
			int lang = GetClientLanguage(client);
			
			char buffer[64];
			GetCmdArgString(buffer, sizeof(buffer));
			if(GetDiffByName(buffer, buffer, sizeof(buffer), lang))
			{
				int index = -1;
				if(DiffListing[client])
					index = DiffListing[client].FindString(buffer);
				
				ConfigMap cfg = Difficulties.GetSection(buffer);
				if(!cfg)
				{
					FReplyToCommand(client, "%t", "Unknown Difficulty");
				}
				else if(index == -1)
				{
					Preference_AddDifficulty(client, buffer);
					UpdateDataBase[client] = true;
					
					Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
					FReplyToCommand(client, "%t", "Boss Whitelisted", buffer);
				}
				else
				{
					DiffListing[client].Erase(index);
					UpdateDataBase[client] = true;
					
					Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang);
					FReplyToCommand(client, "%t", "Boss Blacklisted", buffer);
				}
			}
			else
			{
				FReplyToCommand(client, "%t", "Unknown Difficulty");
			}
		}
		else
		{
			char buffer[64];
			int lang = client ? GetClientLanguage(client) : -1;
			SortedSnapshot snap = CreateSortedSnapshot(Difficulties);
			
			PackVal val;
			int entries = snap.Length;
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] section = new char[length];
				snap.GetKey(i, section, length);
				if(Difficulties.GetArray(section, val, sizeof(val)) && val.tag == KeyValType_Section && val.cfg)
				{
					if(!client)
					{
						PrintToServer(section);
					}
					else if(Bosses_GetBossNameCfg(val.cfg, buffer, sizeof(buffer), lang))
					{
						PrintToConsole(client, buffer);
					}
					else
					{
						PrintToConsole(client, section);
					}
				}
			}
			
			delete snap;
		}
	}
	else if(args)
	{
		Menu_Command(client);
		
		char buffer[64];
		GetCmdArgString(buffer, sizeof(buffer));
		if(GetDiffByName(buffer, buffer, sizeof(buffer), GetClientLanguage(client)))
		{
			ViewingPage[client] = 0;
			DifficultyMenu(client, buffer);
		}
		else
		{
			Preference_DifficultyMenu(client);
		}
	}
	else
	{
		Menu_Command(client);
		Preference_DifficultyMenu(client);
	}
	return Plugin_Handled;
}

void Preference_DifficultyMenu(int client)
{
	ViewingPage[client] = 0;
	DifficultyMenu(client);
}

static void DifficultyMenu(int client, const char[] name = NULL_STRING)
{
	SetGlobalTransTarget(client);
	
	if(name[0])
	{
		ConfigMap cfg = Difficulties.GetSection(name);
		if(cfg)
		{
			Menu menu = new Menu(Preference_DifficultyMenuItemH);
			
			int lang = GetClientLanguage(client);
			
			char buffer[512];
			if(Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang, "description"))
			{
				menu.SetTitle("%t\n%s\n ", "Difficulty Menu", buffer);
			}
			else
			{
				menu.SetTitle("%t\n%t\n ", "Difficulty Menu", "No Description");
			}
			
			if(Cvar[PrefSpecial].BoolValue)
			{
				menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_NOTEXT);
			}
			else
			{
				if(!Bosses_GetBossNameCfg(cfg, buffer, sizeof(buffer), lang))
					strcopy(buffer, sizeof(buffer), name);
				
				Format(buffer, sizeof(buffer), "%t", (DiffListing[client] && DiffListing[client].FindString(name) != -1) ? "Boss Blacklist" : "Boss Whitelist", buffer);
				menu.AddItem(name, buffer);
			}
			
			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}
	}
	else
	{
		Menu menu = new Menu(Preference_DifficultyMenuH);
		
		menu.SetTitle("%t", "Difficulty Menu");
		
		bool random = Cvar[PrefSpecial].BoolValue;
		char buffer[64];
		if(random)
		{
			FormatEx(buffer, sizeof(buffer), "%t\n ", DiffListing[client] ? "Enable Special Rounds" : "Disable Special Rounds");
			menu.AddItem(NULL_STRING, buffer);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Clear Whitelist");
			menu.AddItem(NULL_STRING, buffer, DiffListing[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		
		int lang = GetClientLanguage(client);
		SortedSnapshot snap = CreateSortedSnapshot(Difficulties);
		
		PackVal val;
		int entries = snap.Length;
		for(int i; i < entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] section = new char[length];
			snap.GetKey(i, section, length);
			if(Difficulties.GetArray(section, val, sizeof(val)) && val.tag == KeyValType_Section && val.cfg)
			{
				if(!Bosses_GetBossNameCfg(val.cfg, buffer, sizeof(buffer), lang))
					strcopy(buffer, sizeof(buffer), section);
				
				if(!random)
					Format(buffer, sizeof(buffer), "[%s] %s", (DiffListing[client] && DiffListing[client].FindString(section) != -1) ? "X" : " ", buffer);
				
				menu.AddItem(section, buffer);
			}
		}
		
		delete snap;
		
		menu.ExitBackButton = Menu_BackButton(client);
		menu.DisplayAt(client, ViewingPage[client], MENU_TIME_FOREVER);
	}
}

static int Preference_DifficultyMenuH(Menu menu, MenuAction action, int client, int choice)
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
			ViewingPage[client] = choice / 7 * 7;
			
			if(choice)
			{
				char buffer[64];
				menu.GetItem(choice, buffer, sizeof(buffer));
				DifficultyMenu(client, buffer);
			}
			else if(DiffListing[client])
			{
				delete DiffListing[client];
				UpdateDataBase[client] = true;
				DifficultyMenu(client);
			}
			else
			{
				Preference_AddDifficulty(client, "#");
				UpdateDataBase[client] = true;
				DifficultyMenu(client);
			}
		}
	}
	return 0;
}

static int Preference_DifficultyMenuItemH(Menu menu, MenuAction action, int client, int choice)
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
				DifficultyMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			if(buffer[0])
			{
				int index = -1;
				if(DiffListing[client])
					index = DiffListing[client].FindString(buffer);
				
				if(index == -1)
				{
					Preference_AddDifficulty(client, buffer);
				}
				else
				{
					DiffListing[client].Erase(index);
				}
				
				UpdateDataBase[client] = true;
			}
			
			DifficultyMenu(client);
		}
	}
	return 0;
}

static bool GetDiffByName(const char[] name, char[] buffer, int length, int lang = -1)
{
	int similarDiff = -1;
	int size1 = strlen(name);
	int similarChars;
	
	StringMapSnapshot snap = Difficulties.Snapshot();
	
	PackVal val;
	int entries = snap.Length;
	for(int i; i < entries; i++)
	{
		int lengt = snap.KeyBufferSize(i)+1;
		char[] section = new char[lengt];
		snap.GetKey(i, section, lengt);
		if(Difficulties.GetArray(section, val, sizeof(val)) && val.tag == KeyValType_Section && val.cfg)
		{
			if(!Bosses_GetBossNameCfg(val.cfg, buffer, length, lang))
				strcopy(buffer, length, section);
			
			if(StrEqual(name, buffer, false))
			{
				similarDiff = i;
				break;
			}
			
			int bump = StrContains(buffer, name, false);
			if(bump == -1)
				bump = 0;
			
			int size2 = strlen(buffer) - bump;
			if(size2 > size1)
				size2 = size1;
			
			int amount;
			for(int c; c < size2; c++)
			{
				if(CharToLower(name[c]) == CharToLower(buffer[c + bump]))
					amount++;
			}
			
			if(amount > similarChars)
			{
				similarChars = amount;
				similarDiff = i;
			}
		}
	}
	
	if(similarDiff != -1)
		snap.GetKey(similarDiff, buffer, length);
	
	delete snap;
	return similarDiff != -1;
}