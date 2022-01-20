/*
	bool Configs_CheckMap(const char[] mapname)
*/

#define FILE_MAPS	"data/freak_fortress_2/maps.cfg"

bool Configs_CheckMap(const char[] mapname)
{
	int enableResult;
	
	ConfigMap cfg = new ConfigMap(FILE_MAPS);
	if(cfg)
	{	
		StringMapSnapshot snap = cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				enableResult = -1;
				
				PackVal val;
				for(int i; i<entries; i++)
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] buffer = new char[length];
					snap.GetKey(i, buffer, length);
					cfg.GetArray(buffer, val, sizeof(val));
					if(val.tag != KeyValType_Section)
						continue;
					
					switch(ReplaceString(buffer, length, "*", ""))
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
					
					val.data.Reset();
					ConfigMap cfgsub = val.data.ReadCell();	
					
					int current = -1;
					if(cfgsub.GetInt("enable", current) && current > enableResult)
						enableResult = current;
				}
			}
			
			delete snap;
		}
		
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