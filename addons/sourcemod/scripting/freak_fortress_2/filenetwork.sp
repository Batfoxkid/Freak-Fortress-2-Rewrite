#tryinclude <filenetwork>

#pragma semicolon 1
#pragma newdecls required

#define FILENET_LIBRARY	"filenetwork"

#if defined _filenetwork_included
static bool Loaded;

static bool StartedQueue[MAXTF2PLAYERS];
static bool Downloading[MAXTF2PLAYERS];

static ArrayList FileList;
static int FileProgress[MAXTF2PLAYERS];
#endif

void FileNet_PluginStart()
{
	#if defined _filenetwork_included
	Loaded = LibraryExists(FILENET_LIBRARY);
	FileList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	RegServerCmd("ff2_filenetwork", FileNet_Command, "View files to download via filenetwork");
	#endif
}

public void FileNet_LibraryAdded(const char[] name)
{
	#if defined _filenetwork_included
	if(!Loaded && StrEqual(name, FILENET_LIBRARY))
	{
		Loaded = true;

		for(int client = 1; client <= MaxClients; client++)
		{
			if(StartedQueue[client] && !Downloading[client])
				SendNextFile(client);
		}
	}
	#endif
}

public void FileNet_LibraryRemoved(const char[] name)
{
	#if defined _filenetwork_included
	if(Loaded && StrEqual(name, FILENET_LIBRARY))
		Loaded = false;
	#endif
}

void FileNet_PrintStatus()
{
	#if defined _filenetwork_included
	PrintToServer("'%s' is %sloaded", FILENET_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", FILENET_LIBRARY);
	#endif
}

void FileNet_MapEnd()
{
	#if defined _filenetwork_included
	for(int i; i < sizeof(FileProgress); i++)
	{
		FileProgress[i] = 0;
	}

	delete FileList;

	FileNet_PluginStart();
	#endif
}

public void FileNet_ClientPutInServer(int client)
{
	#if defined _filenetwork_included
	FileNet_ClientDisconnect(client);
	if(!IsFakeClient(client))
		SendNextFile(client);
	#endif
}

public void FileNet_ClientDisconnect(int client)
{
	#if defined _filenetwork_included
	StartedQueue[client] = false;
	Downloading[client] = false;
	FileProgress[client] = 0;
	#endif
}

void FileNet_AddFileToDownloads(const char[] raw)
{
	#if defined _filenetwork_included
	if(Loaded)
	{
		char file[PLATFORM_MAX_PATH];
		strcopy(file, sizeof(file), raw);
		FormatFile(file, sizeof(file));

		if(FileList.FindString(file) == -1)
		{
			FileList.PushString(file);
			
			for(int client = 1; client <= MaxClients; client++)
			{
				if(StartedQueue[client] && !Downloading[client])
					SendNextFile(client);
			}
		}

		return;
	}
	#endif

	AddFileToDownloadsTable(raw);
}

public bool FileNet_HasFile(int client, int progress)
{
	#if defined _filenetwork_included
	return FileProgress[client] >= progress;
	#else
	return true;
	#endif
}

public int FileNet_FileProgress(const char[] raw)
{
	#if defined _filenetwork_included
	char file[PLATFORM_MAX_PATH];
	strcopy(file, sizeof(file), raw);
	FormatFile(file, sizeof(file));

	return FileList.FindString(file) + 1;
	#else
	return 0;
	#endif
}

public int FileNet_SoundProgress(const char[] sound)
{
	#if defined _filenetwork_included
	char file[PLATFORM_MAX_PATH];
	FormatEx(file, sizeof(file), "sound/%s", sound);
	ReplaceString(file, sizeof(file), "*", "");
	ReplaceString(file, sizeof(file), "#", "");
	ReplaceString(file, sizeof(file), "@", "");
	ReplaceString(file, sizeof(file), ">", "");
	ReplaceString(file, sizeof(file), "<", "");
	ReplaceString(file, sizeof(file), "^", "");
	ReplaceString(file, sizeof(file), ")", "");
	ReplaceString(file, sizeof(file), "}", "");
	ReplaceString(file, sizeof(file), "!", "");
	ReplaceString(file, sizeof(file), "?", "");
	FormatFile(file, sizeof(file));

	return FileList.FindString(file) + 1;
	#else
	return 0;
	#endif
}

#if defined _filenetwork_included
static Action FileNet_Command(int args)
{
	int length = FileList.Length;
	PrintToServer("Listing %d files:", length);

	char file[PLATFORM_MAX_PATH];
	for(int i; i < length; i++)
	{
		FileList.GetString(i, file, sizeof(file));
		PrintToServer("\"%s\"", file);
	}
	return Plugin_Handled;
}

static void FormatFile(char[] file, int length)
{
	ReplaceString(file, length, "\\", "/");
}

static void FormatFileCheck(const char[] file, int client, char[] output, int length)
{
	strcopy(output, length, file);
	ReplaceString(output, length, ".", "");
	Format(output, length, "%s_%d.txt", output, GetSteamAccountID(client, false));
}

static void SendNextFile(int client)
{
	StartedQueue[client] = true;
	
	if(Loaded && FileProgress[client] < FileList.Length)
	{
		char file[PLATFORM_MAX_PATH];
		FileList.GetString(FileProgress[client], file, sizeof(file));

		DataPack pack = new DataPack();

		Downloading[client] = true;

		pack.WriteString(file);
		
		// First, request a dummy file to see if they have it downloaded before
		char filecheck[PLATFORM_MAX_PATH];
		FormatFileCheck(file, client, filecheck, sizeof(filecheck));
		FileNet_RequestFile(client, filecheck, FileNetwork_RequestResults, pack);

		// There may be some cases where we still have the file (Eg. plugin unload)
		if(!DeleteFile(filecheck, true))
		{
			Format(filecheck, sizeof(filecheck), "download/%s", filecheck);
			DeleteFile(filecheck);
		}
	}
	else
	{
		Downloading[client] = false;
	}
}

static void FileNetwork_RequestResults(int client, const char[] file, int id, bool success, DataPack pack)
{
	if(success)
	{
		// Delete the dummy file we downloaded
		if(!DeleteFile(file, true))
		{
			char filecheck[PLATFORM_MAX_PATH];
			Format(filecheck, sizeof(filecheck), "download/%s", file);
			DeleteFile(filecheck);
		}
	}

	if(!StartedQueue[client])
	{
		// Client has disconnected
		delete pack;
		return;
	}

	char download[PLATFORM_MAX_PATH];
	pack.Reset();
	pack.ReadString(download, sizeof(download));
	delete pack;

	if(success)
	{
		// Found, check the next file
		FileProgress[client]++;
		SendNextFile(client);
	}
	else
	{
		// Not found, send the actual file
		if(!FileNet_SendFile(client, download, FileNetwork_SendResults))
			LogError("Failed to queue file \"%s\" to client", download);
	}
}

static void FileNetwork_SendResults(int client, const char[] file, bool success)
{
	if(StartedQueue[client])
	{
		if(success)
		{
			// When done, send a dummy file
			char filecheck[PLATFORM_MAX_PATH];
			FormatFileCheck(file, client, filecheck, sizeof(filecheck));

			File check = OpenFile(filecheck, "wt");
			check.WriteLine("Used for file checks for FF2");
			check.Close();

			if(!FileNet_SendFile(client, filecheck, FileNetwork_SendFileCheck))
			{
				LogError("Failed to queue file \"%s\" to client", filecheck);
				DeleteFile(filecheck);
			}

			// Move on to the next file
			FileProgress[client]++;
			SendNextFile(client);
		}
		else
		{
			LogError("Failed to send file \"%s\" to client", file);
		}
	}
}

static void FileNetwork_SendFileCheck(int client, const char[] file, bool success)
{
	if(StartedQueue[client] && !success)
		LogError("Failed to send file \"%s\" to client", file);
	
	// Delete the dummy file left over
	DeleteFile(file);
}
#endif
