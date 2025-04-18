#pragma semicolon 1
#pragma newdecls required

#define FILE_MAPS	"data/freak_fortress_2/maps.cfg"

static bool VotedPack;

void Configs_AllPluginsLoaded()
{
	ConVar cvar = FindConVar("sm_nextmap");
	if(cvar)
		cvar.AddChangeHook(Configs_StartVote);
}

void Configs_MapStart()
{
	VotedPack = false;
}

bool Configs_MapIsGamemode(const char[] mapname)
{
	int enableResult = 1;
	
	ConfigMap cfg = new ConfigMap(FILE_MAPS);
	if(cfg)
	{	
		StringMapSnapshot snap = cfg.Snapshot();
		
		int entries = snap.Length;
		if(entries)
		{
			enableResult = -1;
			
			PackVal val;
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] buffer = new char[length];
				snap.GetKey(i, buffer, length);
				cfg.GetArray(buffer, val, sizeof(val));
				if(val.tag != KeyValType_Section)
					continue;
				
				switch(ReplaceString(buffer, length, "*", NULL_STRING))
				{
					case 0:	// Exact
					{
						if(!StrEqual(mapname, buffer, false))
							continue;
					}
					case 1:	// Prefix
					{
						if(StrContains(mapname, buffer, false) != 0)
							continue;
					}
					default:	// Any Match
					{
						if(StrContains(mapname, buffer, false) == -1)
							continue;
					}
				}
				
				int current = -1;
				if(val.cfg.GetInt("enable", current) && current > enableResult)
					enableResult = current;
			}
		}
		
		delete snap;
		DeleteCfg(cfg);
	}
	
	return enableResult == 1;
}

bool Configs_SetMap(const char[] mapname)
{
	int enableResult = 1;
	
	ConfigMap cfg = new ConfigMap(FILE_MAPS);
	if(cfg)
	{	
		StringMapSnapshot snap = cfg.Snapshot();
		
		int entries = snap.Length;
		if(entries)
		{
			enableResult = -1;
			
			PackVal val;
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] buffer = new char[length];
				snap.GetKey(i, buffer, length);
				cfg.GetArray(buffer, val, sizeof(val));
				if(val.tag != KeyValType_Section)
					continue;
				
				switch(ReplaceString(buffer, length, "*", NULL_STRING))
				{
					case 0:	// Exact
					{
						if(!StrEqual(mapname, buffer, false))
							continue;
					}
					case 1:	// Prefix
					{
						if(StrContains(mapname, buffer, false) != 0)
							continue;
					}
					default:	// Any Match
					{
						if(StrContains(mapname, buffer, false) == -1)
							continue;
					}
				}
				
				int current = -1;
				if(val.cfg.GetInt("enable", current) && current > enableResult)
					enableResult = current;
			}
		}
		
		delete snap;
		DeleteCfg(cfg);
	}
	
	switch(enableResult)
	{
		case -1:
		{
			Enabled = false;
			return false;
		}
		case 1:
		{
			Enabled = true;
		}
		default:
		{
			Enabled = false;
		}
	}
	
	return true;
}

static void Configs_StartVote(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(!VotedPack && Cvar[PackVotes].BoolValue && Bosses_GetCharsetLength() > 1)
	{
		char mapname[64];
		GetMapDisplayName(newValue, mapname, sizeof(mapname));
		if(Configs_MapIsGamemode(mapname))
		{
			VotedPack = true;
			RequestFrame(Configs_PackVoteFrame);
		}
	}
}

static Action Configs_PackVote(Handle timer)
{
	Configs_PackVoteFrame();
	return Plugin_Continue;
}

static void Configs_PackVoteFrame()
{
	if(IsVoteInProgress())
	{
		CreateTimer(3.0, Configs_PackVote, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		Menu menu = new Menu(Configs_PackVoteH, view_as<MenuAction>(MENU_ACTIONS_ALL));
		
		int length = Bosses_GetCharsetLength();
		int start = Charset;
		if(start < 0)
			start = 0;
		
		char buffer[64], num[12];
		
		int i = start + 1;
		for(int a; a < 8; a++)
		{
			if(i >= length)
				i = 0;
			
			if(Bosses_GetCharset(i, buffer, sizeof(buffer)))
			{
				IntToString(i, num, sizeof(num));
				menu.AddItem(num, buffer);
			}
			
			if(i == start)
				break;
			
			i++;
		}
		
		menu.Pagination = 0;
		menu.ExitButton = false;
		menu.NoVoteButton = true;
		
		ConVar cvar = FindConVar("sm_mapvote_voteduration");
		menu.DisplayVoteToAll(cvar ? cvar.IntValue : 20);
	}
}

static int Configs_PackVoteH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Display:
		{
			menu.SetTitle("%t", "Next Pack Vote", param1);
		}
		case MenuAction_VoteCancel:
		{
			VotedPack = false;
		}
		case MenuAction_VoteEnd:
		{
			char buffer1[12], buffer2[64];
			menu.GetItem(param1, buffer1, sizeof(buffer1), _, buffer2, sizeof(buffer2));
			
			Cvar[NextCharset].SetString(buffer1);
			FPrintToChatAll("%t", "Next Pack Voted", buffer2);
		}
	}
	return 0;
}