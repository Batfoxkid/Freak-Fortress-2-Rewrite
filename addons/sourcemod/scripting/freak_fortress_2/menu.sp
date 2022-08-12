/*
	void Menu_PluginStart()
	void Menu_Command(int client)
	bool Menu_BackButton(int client)
	void Menu_MainMenu(int client)
*/

#pragma semicolon 1

static bool InMainMenu[MAXTF2PLAYERS];

void Menu_PluginStart()
{
	RegConsoleCmd("ff2", Menu_MainMenuCmd, "Freak Fortress 2 Main Menu");
	RegConsoleCmd("hale", Menu_MainMenuCmd, "Freak Fortress 2 Main Menu", FCVAR_HIDDEN);
	RegConsoleCmd("vsh", Menu_MainMenuCmd, "Freak Fortress 2 Main Menu", FCVAR_HIDDEN);
	RegConsoleCmd("pony", Menu_MainMenuCmd, "Freak Fortress 2 Main Menu", FCVAR_HIDDEN);
	
	RegFreakCmd("voice", Menu_VoiceToggle, "Freak Fortress 2 Voices Preference");
	
	RegFreakCmd("queue", Menu_QueueMenuCmd, "Freak Fortress 2 Queue Menu");
	RegFreakCmd("next", Menu_QueueMenuCmd, "Freak Fortress 2 Queue Menu", FCVAR_HIDDEN);
	
	RegFreakCmd("hud", Menu_HudToggle, "Freak Fortress 2 HUD Preference");
	
	RegAdminCmd("ff2_addpoints", Menu_AddPointsCmd, ADMFLAG_CHEATS, "Add Queue Points to a Player");
}

void Menu_Command(int client)
{
	InMainMenu[client] = false;
}

bool Menu_BackButton(int client)
{
	return InMainMenu[client];
}

public Action Menu_MainMenuCmd(int client, int args)
{
	if(!client)
	{
		PrintToServer("Freak Fortress 2: Rewrite (%s.%s)", PLUGIN_VERSION, PLUGIN_VERSION_REVISION);
		
		if(CvarDebug.BoolValue)
			PrintToServer("Debug Mode Enabled");
		
		PrintToServer("Status: %s", Charset<0 ? "Disabled" : Enabled ? "Gamemode Running" : "Ready");
		
		if(Charset < 0)
		{
			PrintToServer("Boss Pack: N/A");
		}
		else
		{
			char buffer[48];
			Bosses_GetCharset(Charset, buffer, sizeof(buffer));
			PrintToServer("Boss Pack: %s (%d)", buffer, Charset);
		}
		
		int amount, ready;
		bool enabled;
		ConfigMap cfg;
		while((cfg = Bosses_GetConfig(amount++)))
		{
			if(cfg.GetBool("enabled", enabled) && enabled)
				ready++;
		}
		
		PrintToServer("%d bosses found", amount-1);
		PrintToServer("%d bosses precached", ready);
		
		ready = 0;
		for(amount = 1; amount<=MaxClients; amount++)
		{
			if(Client(amount).IsBoss)
				ready++;
		}
		
		PrintToServer("%d bosses in play", ready);
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		PrintToConsole(client, "Freak Fortress 2: Rewrite (%s.%s)", PLUGIN_VERSION, PLUGIN_VERSION_REVISION);
		PrintToConsole(client, "%T", "Available Commands", client);
	}
	else
	{
		InMainMenu[client] = true;
		Menu_MainMenu(client);
	}
	return Plugin_Handled;
}

void Menu_MainMenu(int client)
{
	Menu menu = new Menu(Menu_MainMenuH);
	menu.SetTitle("Freak Fortress 2: Rewrite (%s.%s)", PLUGIN_VERSION, PLUGIN_VERSION_REVISION);
	
	char buffer[64];
	SetGlobalTransTarget(client);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Selection");
	menu.AddItem("", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Queue");
	menu.AddItem("", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Music");
	menu.AddItem("", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Voice");
	menu.AddItem("", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Weapon");
	menu.AddItem("", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Hud");
	menu.AddItem("", buffer);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_MainMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Preference_BossMenu(client);
				}
				case 1:
				{
					QueueMenu(client);
				}
				case 2:
				{
					Music_MainMenu(client);
				}
				case 3:
				{
					Menu_VoiceToggle(client, 0);
					Menu_MainMenu(client);
				}
				case 4:
				{
					Weapons_ChangeMenu(client);
				}
				case 5:
				{
					Menu_HudToggle(client, 0);
					Menu_MainMenu(client);
				}
			}
		}
	}
	return 0;
}

public Action Menu_VoiceToggle(int client, int args)
{
	if(client)
	{
		Client(client).NoVoice = !Client(client).NoVoice;
		FReplyToCommand(client, "%t", Client(client).NoVoice ? "Boss Voices Disabled" : "Boss Voices Enabled");
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action Menu_QueueMenuCmd(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		int[] clients = new int[MaxClients];
		int amount = Preference_GetBossQueue(clients, MaxClients, true);
		if(amount)
		{
			for(int i; i < amount; i++)
			{
				ReplyToCommand(client, "%s%N - %d", clients[i]==client ? " " : "", clients[i], Preference_GetFullQueuePoints(clients[i]));
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
		QueueMenu(client);
	}
	return Plugin_Handled;
}

static void QueueMenu(int client)
{
	Menu menu = new Menu(Menu_QueueMenuH);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "Queue Menu");
	
	int[] clients = new int[MaxClients];
	int amount = Preference_GetBossQueue(clients, MaxClients, true);
	
	char buffer[64];
	bool exitButton = Menu_BackButton(client);
	for(int i; exitButton ? i < 7 : i < 8; i++)
	{
		if(i < amount)
		{
			FormatEx(buffer, sizeof(buffer), "%N - %d", clients[i], Preference_GetFullQueuePoints(clients[i]));
			menu.AddItem("", buffer, clients[i] == client ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem("", buffer, ITEMDRAW_SPACER);
		}
	}
	
	if(exitButton)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Back");
		menu.AddItem("", buffer, ITEMDRAW_DEFAULT);
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "Reset Queue Points", Client(client).Queue);
	menu.AddItem("", buffer, (!Preference_IsInParty(client) && Client(client).Queue > 0 && CvarPrefToggle.BoolValue) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.Pagination = 0;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_QueueMenuH(Menu menu, MenuAction action, int client, int choice)
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
				QueueMenu(client);
			}
		}
	}
	return 0;
}

static void ResetQueueMenu(int client)
{
	Menu menu = new Menu(ResetQueueMenuH);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "Reset Queue Points Confirm");
	
	char buffer[16];
	
	FormatEx(buffer, sizeof(buffer), "%t", "Yes");
	menu.AddItem("", buffer, Client(client).Queue > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
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
			if(!choice && Client(client).Queue > 0)
				Client(client).Queue = 0;
			
			QueueMenu(client);
		}
	}
	return 0;
}

public Action Menu_HudToggle(int client, int args)
{
	if(client)
	{
		Client(client).NoDmgHud = !Client(client).NoDmgHud;
		FReplyToCommand(client, "%t", Client(client).NoDmgHud ? "Damage Hud Disabled" : "Damage Hud Enabled");
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	return Plugin_Handled;
}

public Action Menu_AddPointsCmd(int client, int args)
{
	if(args == 2)
	{
		char name[MAX_TARGET_LENGTH];
		GetCmdArg(2, name, sizeof(name));
		int points = StringToInt(name);
		
		GetCmdArg(1, name, sizeof(name));
		
		bool lang;
		int matches;
		int[] target = new int[MaxClients];
		if((matches = ProcessTargetString(name, client, target, MaxClients, COMMAND_FILTER_CONNECTED, name, sizeof(name), lang)) > 0)
		{
			AddQueuePoints(client, points, target, matches, name, lang);
		}
		else
		{
			ReplyToTargetError(client, matches);
		}
	}
	else if(args || GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		ReplyToCommand(client, "[SM] Usage: ff2_addpoints <player> <points>");
	}
	else
	{
		AddPointsMenu(client);
	}
	return Plugin_Handled;
}

static void AddPointsMenu(int client, const char[] userid = NULL_STRING)
{
	int target = userid[0] ? GetClientOfUserId(StringToInt(userid)) : 0;
	if(target)
	{
		Menu menu = new Menu(Menu_AddPointsActionH);
		
		menu.SetTitle("%T%N\n ", "Queue Menu", client, target);
		
		menu.AddItem(userid, "1000");
		menu.AddItem(userid, "100");
		menu.AddItem(userid, "10");
		menu.AddItem(userid, "-10");
		menu.AddItem(userid, "-100");
		menu.AddItem(userid, "-1000");
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		Menu menu = new Menu(Menu_AddPointsTargetH);
		
		menu.SetTitle("%T", "Queue Menu", client);
		
		AddTargetsToMenu(menu, client);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int Menu_AddPointsTargetH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char userid[12];
			menu.GetItem(choice, userid, sizeof(userid));
			AddPointsMenu(client, userid);
		}
	}
	return 0;
}

public int Menu_AddPointsActionH(Menu menu, MenuAction action, int client, int choice)
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
				AddPointsMenu(client);
		}
		case MenuAction_Select:
		{
			char buffer[32];
			menu.GetItem(choice, buffer, sizeof(buffer));
			
			int target[1];
			target[0] = GetClientOfUserId(StringToInt(buffer));
			if(target[0])
			{
				int points;
				switch(choice)
				{
					case 0:
						points = -1000;
					
					case 1:
						points = -100;
					
					case 2:
						points = -10;
					
					case 3:
						points = 10;
					
					case 4:
						points = 100;
					
					case 5:
						points = 1000;
				}
				
				GetClientName(target[0], buffer, sizeof(buffer));
				AddQueuePoints(client, points, target, 1, buffer);
			}
			
			AddPointsMenu(client);
		}
	}
	return 0;
}

static void AddQueuePoints(int client, int points, int[] target, int matches, const char[] name, bool lang = false)
{
	for(int i; i < matches; i++)
	{
		Client(target[i]).Queue += points;
		if(points < 0)
		{
			LogAction(client, target[i], "\"%L\" removed %d queue points from \"%L\"", client, -points, target[i]);
		}
		else
		{
			LogAction(client, target[i], "\"%L\" added %d queue points to \"%L\"", client, points, target[i]);
		}
	}
	
	if(points < 0)
	{
		if(lang)
		{
			FShowActivity(client, "%t", "Remove Points From", -points, name);
		}
		else
		{
			FShowActivity(client, "%t", "Remove Points From", -points, "_s", name);
		}
	}
	else if(lang)
	{
		FShowActivity(client, "%t", "Add Points To", points, name);
	}
	else
	{
		FShowActivity(client, "%t", "Add Points To", points, "_s", name);
	}
}