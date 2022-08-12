/*
	void Database_Setup()
	void Database_PluginEnd()
	void Database_ClientAuthorized(int client)
	void Database_ClientDisconnect(int client, DBPriority prioity = DBPrio_Normal)
*/

#pragma semicolon 1

#define DATABASE			"ff2"
#define DATATABLE_GENERAL	"ff2_data_v3"
#define DATATABLE_LISTING	"ff2_listing_v1"

static Database DataBase;
static int Cached[MAXTF2PLAYERS];
static float StartTime[MAXTF2PLAYERS];

void Database_Setup()
{
	RegServerCmd("ff2_query", Database_QueryCmd, "Query the database");
	RegServerCmd("ff2_steamid", Database_SteamIdCmd, "Get the account id");
	
	char error[512];
	Database db = SQLite_UseDatabase(DATABASE, error, sizeof(error));
	if(!db)
	{
		LogError("[Database] %s", error);
		return;
	}
	
	Transaction tr = new Transaction();
	
	tr.AddQuery("CREATE TABLE IF NOT EXISTS " ... DATATABLE_GENERAL ... " ("
	... "steamid INTEGER PRIMARY KEY, "
	... "queue INTEGER NOT NULL DEFAULT 0, "
	... "music_type INTEGER NOT NULL DEFAULT 1, "
	... "toggle_voice INTEGER NOT NULL DEFAULT 1, "
	... "weapon_changes INTEGER NOT NULL DEFAULT 1, "
	... "damage_hud INTEGER NOT NULL DEFAULT 1, "
	... "last_played TEXT NOT NULL DEFAULT '');");
	
	tr.AddQuery("CREATE TABLE IF NOT EXISTS " ... DATATABLE_LISTING ... " ("
	... "steamid INTEGER NOT NULL, "
	... "boss TEXT NOT NULL);");
	
	db.Execute(tr, Database_SetupCallback, Database_FailHandle, db);
}

public Action Database_SteamIdCmd(int args)
{
	if(args)
	{
		char buffer[64];
		GetCmdArgString(buffer, sizeof(buffer));
		
		bool isTrans;
		int targets;
		int[] target = new int[MaxClients];
		if((targets = ProcessTargetString(buffer, 0, target, MaxClients, 0, buffer, sizeof(buffer), isTrans)) > 0)
		{
			for(int i; i < targets; i++)
			{
				PrintToServer("%N: %d", target[i], GetSteamAccountID(target[i], false));
			}
		}
		else
		{
			ReplyToTargetError(0, targets);
		}
	}
	else
	{
		PrintToServer("[SM] Usage: ff2_steamid <client>");
	}
	return Plugin_Handled;
}

public Action Database_QueryCmd(int args)
{
	char buffer[1024];
	GetCmdArgString(buffer, sizeof(buffer));
	
	StripQuotes(buffer);
	
	Transaction tr = new Transaction();
	tr.AddQuery(buffer);
	DataBase.Execute(tr, Database_QueryCallback, Database_QueryFail);
	return Plugin_Handled;
}

public void Database_QueryCallback(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	PrintToServer("Success");
	
	char buffer[256];
	int length = results[0].RowCount;
	for(int i; i < length; i++)
	{
		results[0].FetchRow();
		
		int length2 = results[0].FieldCount;
		for(int a; a < length2; a++)
		{
			results[0].FetchString(1, buffer, sizeof(buffer));
			PrintToServer("%d-%d '%s'", i, a, buffer);
		}
	}
}

public void Database_QueryFail(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	PrintToServer(error);
}

public void Database_SetupCallback(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	DataBase = data;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientAuthorized(client))
			Database_ClientAuthorized(client);
	}
}

void Database_PluginEnd()
{
	if(DataBase)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				Database_ClientDisconnect(client, DBPrio_High);
		}
	}
}

void Database_ClientAuthorized(int client)
{
	if(DataBase && !IsFakeClient(client))
	{
		int id = GetSteamAccountID(client);
		if(id)
		{
			StartTime[client] = GetEngineTime();
			
			Transaction tr = new Transaction();
			
			char buffer[256];
			FormatEx(buffer, sizeof(buffer), "SELECT * FROM " ... DATATABLE_GENERAL ... " WHERE steamid = %d;", id);
			tr.AddQuery(buffer);
			
			FormatEx(buffer, sizeof(buffer), "SELECT * FROM " ... DATATABLE_LISTING ... " WHERE steamid = %d;", id);
			tr.AddQuery(buffer);
			
			DataPack pack = new DataPack();
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(id);
			
			DataBase.Execute(tr, Database_ClientSetup, Database_FailHandle, pack);
		}
	}
}

public void Database_ClientSetup(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		char buffer[256];
		Transaction tr;
		if(results[0].FetchRow())
		{
			Client(client).Queue = results[0].FetchInt(1);
			Client(client).NoVoice = !results[0].FetchInt(3);
			Client(client).NoChanges = !results[0].FetchInt(4);
			Client(client).NoDmgHud = !results[0].FetchInt(5);
			results[0].FetchString(6, buffer, sizeof(buffer));
			Client(client).SetLastPlayed(buffer);
			
			int value = results[0].FetchInt(2);
			Client(client).MusicShuffle = value > 1;
			Client(client).NoMusic = value < 1;
		}
		else if(!results[0].MoreRows)
		{
			tr = new Transaction();
			
			FormatEx(buffer, sizeof(buffer), "INSERT INTO " ... DATATABLE_GENERAL ... " (steamid) VALUES (%d)", GetSteamAccountID(client));
			tr.AddQuery(buffer);	
		}
		
		Preference_ClearBosses(client);
		
		while(results[1].MoreRows)
		{
			if(results[1].FetchRow())
			{
				results[1].FetchString(1, buffer, sizeof(buffer));
				Preference_AddBoss(client, buffer);
			}
		}
		
		if(tr)
		{
			DataBase.Execute(tr, Database_Success, Database_Fail);
		}
		else if(IsClientInGame(client) && StartTime[client] > GetEngineTime() + 300.0)	// Slow databases, notify the player
		{
			FPrintToChat(client, "%t", "Preference Updated");
		}
		
		Cached[client] = pack.ReadCell();
	}
}

public void Database_ClientRetry(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if(client)
		Database_ClientAuthorized(client);
}

void Database_ClientDisconnect(int client, DBPriority priority = DBPrio_Normal)
{
	if(DataBase && !IsFakeClient(client) && Cached[client])
	{
		int id = GetSteamAccountID(client);
		if(Cached[client] != id)
		{
			// TODO: Remove this
			LogError("%N has different id from what was loaded (%d vs %d)", id, Cached[client]);
			return;
		}
		
		if(id)
		{
			Transaction tr = new Transaction();
			
			char buffer[256];
			Client(client).GetLastPlayed(buffer, sizeof(buffer));
			
			DataBase.Format(buffer, sizeof(buffer), "UPDATE " ... DATATABLE_GENERAL ... " SET "
			... "queue = %d, "
			... "music_type = %d, "
			... "toggle_voice = %d, "
			... "weapon_changes = %d, "
			... "damage_hud = %d, "
			... "last_played = '%s' "
			... "WHERE steamid = %d;",
			Client(client).Queue,
			!Client(client).NoMusic ? Client(client).MusicShuffle ? 2 : 1 : 0,
			!Client(client).NoVoice,
			!Client(client).NoChanges,
			!Client(client).NoDmgHud,
			buffer,
			id);
			
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_Success, Database_Fail, _, priority);
			
			if(Preference_ShouldUpdate(client))
			{
				tr = new Transaction();
				
				FormatEx(buffer, sizeof(buffer), "DELETE FROM " ... DATATABLE_LISTING ... " WHERE steamid = %d;", id);
				tr.AddQuery(buffer);
				
				for(int i; Preference_GetBoss(client, i, buffer, sizeof(buffer)); i++)
				{
					DataBase.Format(buffer, sizeof(buffer), "INSERT INTO " ... DATATABLE_LISTING ... " (steamid, boss) VALUES ('%d', '%s')", id, buffer);
					tr.AddQuery(buffer);
				}
				
				DataBase.Execute(tr, Database_Success, Database_Fail, _, priority);
			}
		}
	}
	
	Cached[client] = 0;
	Preference_ClearBosses(client);
}

public void Database_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
}

public void Database_Fail(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
}

public void Database_FailHandle(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
	CloseHandle(data);
}