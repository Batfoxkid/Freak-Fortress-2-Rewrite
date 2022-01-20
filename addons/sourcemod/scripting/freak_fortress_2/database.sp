/*
	void Database_Setup()
	void Database_PluginEnd()
	void Database_ClientAuthorized(int client)
	void Database_ClientDisconnect(int client, DBPriority prioity=DBPrio_Normal)
*/

#define DATABASE			"ff2"
#define DATATABLE_GENERAL	"ff2_data"

static Database DataBase;

void Database_Setup()
{
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
	... "toggle_music INTEGER NOT NULL DEFAULT 1, "
	... "toggle_voice INTEGER NOT NULL DEFAULT 1);");
	
	db.Execute(tr, Database_SetupCallback, Database_FailHandle, db);
}

public void Database_SetupCallback(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	DataBase = data;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientAuthorized(client))
			Database_ClientAuthorized(client);
	}
}

void Database_PluginEnd()
{
	if(DataBase)
	{
		for(int client=1; client<=MaxClients; client++)
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
			Transaction tr = new Transaction();
			
			char buffer[256];
			FormatEx(buffer, sizeof(buffer), "SELECT * FROM " ... DATATABLE_GENERAL ... " WHERE steamid = %d;", id);
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_ClientSetup, Database_ClientRetry, GetClientUserId(client));
		}
	}
}

public void Database_ClientSetup(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if(client)
	{
		Transaction tr;
		if(results[0].RowCount)
		{
			results[0].FetchRow();
			Client(client).Queue = results[0].FetchInt(1);
			Client(client).NoMusic = !results[0].FetchInt(2);
			Client(client).NoVoice = !results[0].FetchInt(3);
		}
		else
		{
			if(!tr)
				tr = new Transaction();
			
			char buffer[256];
			FormatEx(buffer, sizeof(buffer), "INSERT INTO " ... DATATABLE_GENERAL ... " (steamid) VALUES (%d)", GetSteamAccountID(client));
			tr.AddQuery(buffer);	
		}
		
		if(tr)
		{
			DataBase.Execute(tr, Database_Success, Database_Fail);
		}
		//else if(GetClientTime(client) > 300.0)	// Slow databases, notify the player
		//{
		//	FPrintToChat(client, "%t", "Preference Updated");
		//}
	}
}

public void Database_ClientRetry(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if(client)
		Database_ClientAuthorized(client);
}

void Database_ClientDisconnect(int client, DBPriority priority=DBPrio_Normal)
{
	if(DataBase && !IsFakeClient(client))
	{
		int id = GetSteamAccountID(client);
		if(id)
		{
			Transaction tr = new Transaction();
			
			char buffer[256];
			FormatEx(buffer, sizeof(buffer), "UPDATE " ... DATATABLE_GENERAL ... " SET "
			... "queue = %d, "
			... "toggle_music = %d, "
			... "toggle_voice = %d "
			... "WHERE steamid = %d;",
			Client(client).Queue,
			Client(client).NoMusic,
			Client(client).NoVoice,
			id);
			
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_Success, Database_Fail, _, priority);
		}
	}
	
	Client(client).Queue = 0;
	Client(client).NoMusic = false;
	Client(client).NoVoice = false;
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