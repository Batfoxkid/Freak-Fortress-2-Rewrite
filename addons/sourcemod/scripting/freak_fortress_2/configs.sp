/*
	bool Configs_CheckMap(const char[] mapname)
*/

#define FILE_MAPS	"data/freak_fortress_2/maps.cfg"

bool Configs_CheckMap(const char[] mapname)
{
	int result = 1;
	
	ConfigMap cfg = new ConfigMap(FILE_MAPS);
	if(cfg)
	{	
		StringMapSnapshot snap = cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				result = -1;
				
				PackVal val;
				for(int i; i<entries; i++)
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] buffer = new char[length];
					snap.GetKey(i, buffer, length);
					cfg.GetArray(buffer, val, sizeof(val));
					if(val.tag != KeyValType_Section)
						continue;
					
					int amount = ReplaceString(buffer, length, "*", "");
					switch(amount)
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
					if(cfg.GetInt("enable", current) && current > result)
						result = current;
				}
			}
			
			delete snap;
		}
		
		DeleteCfg(cfg);
	}
	
	switch(result)
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