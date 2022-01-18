/*
	
*/

static Cookie CookiePref;
static Cookie CookieBosses;

static int Selection[MAXTF2PLAYERS] = {-1, ...};
static bool NoMusic[MAXTF2PLAYERS];
static bool NoVoice[MAXTF2PLAYERS];
static int InCharset[MAXTF2PLAYERS];

void Preference_PluginStart()
{
	RegFreakCommand("boss", Preference_BossMenuCmd, "Freak Fortress 2 Boss Selection");
	RegConsoleCmd("sm_boss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	RegConsoleCmd("sm_setboss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	
	RegFreakCommand("voice", Preference_VoiceToggle, "Freak Fortress 2 Voices Preference");
	
	RegFreakCommand("queue", Preference_QueueMenu, "Freak Fortress 2 Queue Menu");
	RegFreakCommand("next", Preference_QueueMenu, "Freak Fortress 2 Queue Menu", FCVAR_HIDDEN);
	
	CookiePref = new Cookie("ff2_cookies_mk2", "Player's Preferences", CookieAccess_Protected);
	CookieBosses = new Cookie("ff2_boss_selection", "Player's Boss Selection", CookieAccess_Protected);
	
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && AreClientCookiesCached(client))
			Preference_ClientCookiesCached(client);
	}
}

void Preference_CharsetUpdate()
{
	char buffer[64];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(!Preference_GetBossSelections(client, Charset, buffer, sizeof(buffer)))
			{
				Selection[client] = -1;
			}
			else if(buffer[0] == '-')
			{
				Selection[client] = StringToInt(buffer);
			}
			else
			{
				int special = Bosses_GetByName(buffer);
				if(special==-1 && Bosses_CanAccessBoss(client, special))
					Selection[client] = special;
			}
		}
	}
}

void Preference_ClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		NoMusic[client] = true;
		NoVoice[client] = true;
	}
	else
	{
		if(GetClientTime(client) > 300.0)	// Seen slow databases, notify the player
			FPrintToChat(client, "%t", "Preference Updated");	// "Your preferences and queue points were updated."
		
		static char buffer[512];
		CookiePref.Get(client, buffer, sizeof(buffer));
		
		int reloc_idx, idx, total;
		static char buffer2[64];
		while((idx = SplitString(buffer[reloc_idx], " ", buffer2, sizeof(buffer2))) != -1)
		{
			reloc_idx += idx;
			switch(total++)
			{
				case 0:
					QueuePoints[client] += StringToInt(buffer2);
				
				case 1:
					NoMusic[client] = !StringToInt(buffer2);
				
				case 2:
					NoVoice[client] = !StringToInt(buffer2);
			}
			
			if(total > 3)	// They got more settings then we have now, assume that the player was on a different version last
			{
				FPrintToChat(client, "%t", "FF2 Was Updated");	//This server's Freak Fortress version has been updated since you last came on. Use /ff2 command to see what's changed.
				break;
			}
		}
		
		CookieBosses.Get(client, buffer, sizeof(buffer));
		if(!buffer[0])
			strcopy(buffer, sizeof(buffer), "Saxton Hale;");
		
		reloc_idx = 0;
		total = 0;
		while((idx = SplitString(buffer[reloc_idx], ";", buffer2, sizeof(buffer2))) != -1)
		{
			if(total == Charset)
			{
				if(buffer2[0] == '-')
				{
					Selection[client] = StringToInt(buffer2);
					if(Selection[client] < -2)
						Selection[client] = -1;
				}
				else
				{
					int special = Bosses_GetByName(buffer2);
					if(special==-1 && Bosses_CanAccessBoss(client, special))
						Selection[client] = special;
				}
				break;
			}
			
			reloc_idx += idx;
		}
	}
}

void Preference_Disconnect(int client)
{
	if(AreClientCookiesCached(client))
	{
		char buffer[48];
		FormatEx(buffer, sizeof(buffer), "%d %d %d ", QueuePoints[client], NoMusic[client] ? 0 : 1, NoVoice[client] ? 0 : 1);
		CookiePref.Set(client, buffer);
	}
	
	QueuePoints[client] = 0;
	Selection[client] = -1;
	NoMusic[client] = false;
	NoVoice[client] = false;
}

int Preference_GetBossSelection(int client)
{
	return Selection[client];
}

void Preference_SetBossSelection(int client, int special, const char[] name)
{
	Selection[client] = special;
	if(special < 0)
	{
		char buffer[4];
		IntToString(special, buffer, sizeof(buffer));
		Preference_SetBossSelections(client, Charset, buffer);
	}
	else
	{
		Preference_SetBossSelections(client, Charset, name);
	}
}

bool Preference_GetBossSelections(int client, int charset, char[] buffer, int length)
{
	if(AreClientCookiesCached(client))
	{
		static char buffer[512];
		CookieBosses.Get(client, buffer, sizeof(buffer));
		
		int idx, reloc_idx, total;
		while((idx = SplitString(buffer[reloc_idx], ";", buffer, length)) != -1)
		{
			if(total++ == charset)
				return true;
			
			reloc_idx += idx;
		}
	}
	return false;
}

void Preference_SetBossSelections(int client, int charset, const char[] name)
{
	if(AreClientCookiesCached(client))
	{
		static char buffer[512];
		CookieBosses.Get(client, buffer, sizeof(buffer));
		
		static char buffer2[64];
		ArrayList list = new ArrayList(sizeof(buffer2));
		
		int idx, reloc_idx, total;
		while((idx = SplitString(buffer[reloc_idx], ";", buffer2, sizeof(buffer2))) != -1)
		{
			reloc_idx += idx;
			list.PushString(buffer2);
		}
		
		buffer[0] = 0;
		int length = list.Length;
		for(int i; i<charset; i++)
		{
			if(i == charset)
			{
				strcopy(buffer2, sizeof(buffer2), name);
			}
			else if(i < length)
			{
				list.GetString(i, buffer2, sizeof(buffer2));
			}
			else if(i == length)
			{
				strcopy(buffer2, sizeof(buffer2), "-1");
			}
			
			Format(buffer, sizeof(buffer), "%s%s;", buffer, buffer2);
		}
		
		delete list;
	}
}

bool Preference_GetMusicStatus(int client)
{
	return !NoMusic[client];
}

void Preference_SetMusicStatus(int client, bool status)
{
	NoMusic[client] = !status;
}

bool Preference_GetVoiceStatus(int client)
{
	return !NoVoice[client];
}

public Action Preference_BossMenuCmd(int client, int args)
{
	static char buffer[64];
	if(args > 0 && client)
	{
		GetCmdArgString(buffer, sizeof(buffer));
		
		int lang = GetClientLanguage(client);
		int special = -1;
		if(buffer[0] == '#')
		{
			special = StringToInt(buffer[1]);
		}
		else
		{
			special = Bosses_GetByName(buffer, false, _, lang);
		}
		
		if(special==-1 || !Bosses_CanAccessBoss(client, special))
		{
			FReplyToCommand(client, "%T", "Boss Not Found", client);
		}
		else
		{
			Bosses_GetBossName(special, buffer, sizeof(buffer), lang);
			FReplyToCommand(client, "%T", "Boss Selected", client, buffer);
		}
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		bool enabled;
		int amount;
		int lang = client ? GetClientLanguage(client) : GetServerLanguage();
		ConfigMap cfg;
		while((cfg = Bosses_GetConfig(amount)))
		{
			if(cfg.GetBool("enabled", enabled) && enabled && Bosses_GetBossName(special, buffer, sizeof(buffer), lang))
				ReplyToCommand(client, "%s (#%d)", buffer, amount);
			
			amount++;
		}
	}
	else
	{
		InCharset[client] = Charset;
		Menu_Command(client);
		Preference_BossMenu(client);
	}
	return Plugin_Handled;
}

public Action Preference_BossMenuLegacy(int client, int args)
{
	FReplyToCommand(client, "%t", "Legacy Boss Menu Command");
	
	if(client)
	{
		Preference_BossMenuCmd(client, 0);
	}
	else
	{
		Preference_BossMenuCmd(client, args);
	}
	return Plugin_Handled;
}

void Preference_BossMenu(int client, int last=-1)
{
	Menu menu = new Menu(Preference_BossMenuH);
	
	SetGlobalTransTarget(client);
	
	int lang = GetClientLanguage(client);
	char buffer[64];
	static char buffer2[64];
	if(InCharset[client] == -1)
	{
		FormatEx(buffer2, sizeof(buffer2), "%t", "All Packs");
	}
	else
	{
		Bosses_GetCharset(InCharset[client], buffer2, sizeof(buffer2));
		switch(Selection[client])
		{
			case -3:
			{
				FormatEx(buffer, sizeof(buffer), "%t", "None For Map");
			}
			case -2:
			{
				FormatEx(buffer, sizeof(buffer), "%t", "None");
			}
			case -1:
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Random Boss");
			}
			default:
			{
				if(!Bosses_CanAccessBoss(client, Selection[client], _, Charset==InCharset[client]) || !Bosses_GetBossName(Selection[client], buffer, sizeof(buffer), lang))
					FormatEx(buffer, sizeof(buffer), "%t", "Random Boss");
			}
		}
	}
	
	menu.SetTitle("%t", "Boss Menu", buffer2, buffer);
	
	if(InCharset[client] == -1)
	{
		for(int i; Bosses_GetCharset(i, buffer2, sizeof(buffer2)); i++)
		{
			if(i!=Charset || Bosses_CanAccessBoss(client, Selection[client]))
			{
				if(!Preference_GetBossSelections(Selection[client], buffer, sizeof(buffer), lang))
					strcopy(buffer, sizeof(buffer), "-1");
				
				switch(StringToInt(buffer))
				{
					case -3:
					{
						FormatEx(buffer, sizeof(buffer), "%t", i==Charset ? "None For Map" : "Random Boss");
					}
					case -2:
					{
						FormatEx(buffer, sizeof(buffer), "%t", "None");
					}
					case -1:
					{
						FormatEx(buffer, sizeof(buffer), "%t", "Random Boss");
					}
				}
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Random Boss");
			}
			
			Format(buffer, sizeof(buffer), "%s: %s", buffer2, buffer);
			menu.AddItem("-5", buffer, ITEMDRAW_DISABLED);
			shown++;
		}
	}
	
	int shown;
	if(InCharset[client] == -1 && Charset != -1)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "This Pack");
		menu.AddItem("-5", buffer);
		shown++;
	}
	else if(InCharset[client] > 0 || Bosses_GetCharset(1, buffer, sizeof(buffer)))
	{
		FormatEx(buffer, sizeof(buffer), "%t", "View All");
		menu.AddItem("-4", buffer);
		shown++;
	}
	
	if(InCharset[client] != -1)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Random Boss");
		menu.AddItem("-1", buffer);
		
		FormatEx(buffer, sizeof(buffer), "%t", "No Boss");
		menu.AddItem("-2", buffer);
		
		shown += 2;
	}
	
	int amount, display;
	ConfigMap cfg;
	while((cfg = Bosses_GetConfig(amount)))
	{
		if(Bosses_CanAccessBoss(client, amount, _, false))
		{
			int pack = cfg.GetInt("charset");
			if((InCharset[client] == -1 || pack == InCharset[client]) && Bosses_GetBossName(amount, buffer, sizeof(buffer), lang))
			{
				if(InCharset[client] == -1)
				{
					Bosses_GetCharset(pack, buffer2, sizeof(buffer2));
					Format(buffer, sizeof(buffer), "%s (%s)", buffer, buffer2);
				}
					
				IntToString(amount, buffer2, sizeof(buffer2));
				menu.AddItem(buffer2, buffer);
				shown++;
				
				if(last == amount)
					display = shown / 7;
			}
		}
		
		amount++;
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = Menu_BackButton(client);
	menu.DisplayAt(client, display, MENU_TIME_FOREVER);
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
				Menu_MainMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[6];
			menu.GetItem(choice, buffer, sizeof(buffer));
			int special = StringToInt(buffer);
			switch(special)
			{
				case -5:
				{
					InCharset[client] = Charset;
				}
				case -4:
				{
					InCharset[client] = -1;
				}
				case -3, -2, -1:
				{
					if(InCharset[client] == Charset)
						Selection[client] = special;
					
					Preference_SetBossSelections(client, InCharset[client], buffer);
				}
				default:
				{
					BossSelect(client, special);
					return;
				}
			}
			
			Preference_BossMenu(client);
		}
	}
}

static void BossSelect(int client, int special)
{
	int lang = GetClientLanguage(client);
	
	static char buffer[512];
	if(!Bosses_GetBossName(special, buffer, sizeof(buffer), lang, "description"))
		Format(buffer, sizeof(buffer), "%t", "No Description"):
	
	Menu menu = new Menu(Preference_BossMenuH);
	menu.SetTitle(buffer);
	
	Bosses_GetBossName(special, buffer, sizeof(buffer), lang);
	
	ConfigMap cfg = Bosses_GetConfig(special);
	
	static char buffer2[64];
	int charset;
	bool enabled = (cfg.GetInt("enabled", charset) && charset);
	bool companion = view_as<bool>(cfg.Get("companion", buffer2, sizeof(buffer2)));
	if(companion && charset!=Charset)
		enabled = false;
	
	if(!cfg.GetInt("charset", charset))
	{
		charset = -1;
		enabled = false;
	}
	
	SetGlobalTransTarget(client);
	
	if(companion)
	{
		Format(buffer, sizeof(buffer), "%t", "Select Partner", buffer);
	}
	else if(charset<0 || (charset==Charset && charset==InCharset[client]))
	{
		Format(buffer, sizeof(buffer), "%t", "Select Boss", buffer);
	}
	else
	{
		Bosses_GetCharset(charset, buffer2, sizeof(buffer2));
		Format(buffer, sizeof(buffer), "%t", "Select Boss In Pack", buffer, buffer2);
	}
	
	IntToString(special, buffer2, sizeof(buffer2));
	menu.AddItem(buffer2, buffer, enabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Preference_BossMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
			return;
		}
		case MenuAction_Cancel:
		{
			if(choice != MenuCancel_ExitBack)
				return;
		}
		case MenuAction_Select:
		{
		}
		default:
		{
			return;
		}
	}

	static char buffer[64];
	menu.GetItem(0, buffer, sizeof(buffer));
	int special = StringToInt(buffer);

	if(action == MenuAction_Select)
	{
		int charset = -1;
		ConfigMap cfg = Bosses_GetConfig(special);
		if(cfg.GetInt("charset", charset) && charset >= 0)
		{
			if(Charset == charset)
			{
				if(cfg.Get("companion", buffer, sizeof(buffer)))
				{
					CompanionSelect(client, special, client);
					return;
				}
				else
				{
					Selection[client] = special;
				}
			}
			
			if(!cfg.Get("companion", buffer, sizeof(buffer)) && cfg.Get("name", buffer, sizeof(buffer)))
				Preference_SetBossSelections(client, charset, buffer);
		}
	}
	
	Preference_BossMenu(client, special);
}

static void CompanionSelect(int client, int special, int leader)
{
	if(client == leader)
		Preference_BossMenu(client, special);
	
	//TODO: Choose your companion!
}

public Action Preference_VoiceToggle(int client, int args)
{
	if(client)
	{
		NoVoice[client] = !NoVoice[client];
		FReplyToCommand(client, NoVoice[client] ? "Boss Voices Disabled" : "Boss Voices Enabled");
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action Preference_QueueMenuCmd(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		bool specTeam = CvarSpecTeam.BoolValue;
		int amount;
		int[] clients = new int[MaxClients];
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) > 1 || (specTeam && IsPlayerAlive(i))) && Selection[client] > -2)
				clients[amount++] = i;
		}
		
		if(amount)
		{
			SortCustom1D(clients, amount, Preference_SortFunc);
			
			for(int i; i<amount; i++)
			{
				ReplyToCommand(client, "%s%d: %N", clients[i]==client ? " " : "", QueuePoints[clients[i]], clients[i]);
			}
		}
		else
		{
			ReplyToCommand(client, "N/A");
		}
	}
	else
	{
		Menu_Command(client);
		Preference_QueueMenu(client);
	}
}

public int Preference_SortFunc(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(QueuePoints[array[elem1]] > QueuePoints[array[elem2]] || (QueuePoints[array[elem1]] == QueuePoints[array[elem2]] && array[elem1] > array[elem2]))
		return -1;

	return 1;
}

void Preference_QueueMenu(int client)
{
	Menu menu = new Menu(Preference_QueueMenuH);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "Queue Menu");
	
	bool specTeam = CvarSpecTeam.BoolValue;
	int amount;
	int[] clients = new int[MaxClients];
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) > 1 || (specTeam && IsPlayerAlive(i))) && Selection[client] > -2)
			clients[amount++] = i;
	}
		
	if(amount)
		SortCustom1D(clients, amount, Preference_SortFunc);
	
	char buffer[64];
	bool exitButton = Menu_BackButton(client);
	for(int i; exitButton ? i<7 : i<8; i++)
	{
		FormatEx(buffer, sizeof(buffer), "%N - %d", clients[i], QueuePoints[clients[i]]);
		menu.AddItem("", buffer, clients[i]==client ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if(exitButton)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Back");
		menu.AddItem("", buffer, ITEMDRAW_DEFAULT);
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "Reset Queue Points", QueuePoints[clients]);
	menu.AddItem("", buffer, QueuePoints[clients[i]] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Preference_BossMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(choice == 7)
			{
				Menu_MainMenu(client);
			}
			else if(choice == 8)
			{
				ResetQueueMenu(client);
			}
			else
			{
				Preference_QueueMenu(client);
			}
		}
	}
}

static void ResetQueueMenu(int client)
{
	Menu menu = new Menu(ResetQueueMenuH);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "Reset Queue Points Confirm");
	
	char buffer[16];
	
	FormatEx(buffer, sizeof(buffer), "%t", "Yes");
	menu.AddItem("", buffer, QueuePoints[client] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(buffer, sizeof(buffer), "%t", "No");
	menu.AddItem("", buffer);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ResetQueueMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!choice && QueuePoints[client] > 0)
				QueuePoints[client] = 0;
			
			Preference_QueueMenu(client);
		}
	}
}