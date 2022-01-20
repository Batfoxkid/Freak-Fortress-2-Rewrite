/*
	void Preference_PluginStart()
	int Preference_PickBoss(int client, int team)
*/

static int BossOverride = -1;

void Preference_PluginStart()
{
	//TODO: Rewrite to a Whitelist/Blacklist type system using Databases for per-map stuff
	//RegFreakCmd("boss", Preference_BossMenuCmd, "Freak Fortress 2 Boss Selection");
	//RegConsoleCmd("sm_boss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);
	//RegConsoleCmd("sm_setboss", Preference_BossMenuLegacy, "Freak Fortress 2 Boss Selection", FCVAR_HIDDEN);

	RegAdminCmd("ff2_special", Preference_ForceBoss, ADMFLAG_CHEATS, "Force a specific boss to appear");
}

public Action Preference_ForceBoss(int client, int args)
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
			
			ForwardOld_OnSpecialSelected(Client(client).Index, special, true);
		}
		else
		{
			delete list;
			Bosses_GetCharset(Charset, buffer, sizeof(buffer));
			LogError("[!!!] Could not find a valid boss in %s (#%d)", buffer, Charset);
			return special;
		}
	}
	
	return special;
}