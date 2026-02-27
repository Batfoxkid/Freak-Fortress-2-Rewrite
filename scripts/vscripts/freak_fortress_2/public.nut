/*
	Public functions for other VScript scripts to use.

	Boss config is a table of entries from the config, containing only string and table values.
	VScript gets it's own snapshot of the config, seperated from SourcePawn's.
	Use FF2_GetBossConfig whenever you need to get the config snapshot while
	other config functions are there if you need to send updated keys to SourcePawn.


	Script hooks, read docs about how RegisterScriptHookListener works:

	OnScriptHook_FF2_OnAbility
	Called when a boss uses an ability
	client	| handle	| the boss player
	name	| string	| the name of the ability
	ability		| table		| config data of the ability

	OnScriptHook_FF2_OnBossCreated
	Called when a boss is created
	client	| handle	| the boss player
	boss	| table		| config data of the boss

	OnScriptHook_FF2_OnBossEquipped
	Called when a boss has their weapons equipped
	client	| handle	| the boss player
	boss	| table		| config data of the boss

	OnScriptHook_FF2_OnBossRemoved
	Called when a boss is removed
	client	| handle	| the boss player
*/

/*
	Gets the player's boss config, null if the player is not a boss
*/
function FF2_GetBossConfig(hPlayer)
{
	local m = hPlayer.GetScriptScope()
	if(m != null && ("ff2boss" in m))
		return m.ff2boss

	return null
}

/*
	Updates a value in the player's boss config FROM the SourcePawn layer.
	Only needed if you need to get a key that may have been updated on the
	SourcePawn layer such as internal FF2 keys or SourcePawn subplugins.

	For key trees, use "." for each tree eg. "rage_weapon.attributes"
*/
function FF2_PullBossKey(hPlayer, strFullKey)
{
	local m = hPlayer.GetScriptScope()
	if(m != null && ("ff2boss" in m))
	{
		_FF2_CallPawn("pullkey", {client = hPlayer.entindex(), key = strFullKey})
	}
}

/*
	Updates a value in the player's boss config TO the SourcePawn layer.
	Only needed if you need to have a key on the SourcePawn layer updated
	such as internal FF2 keys or SourcePawn subplugins.

	For key trees, use "." for each tree eg. "rage_weapon.attributes"

	If strValue is null, will delete the key instead.
*/
function FF2_PushBossKey(hPlayer, strFullKey, strValue, bCallPawn = true)
{
	local m = hPlayer.GetScriptScope()
	if(m != null && ("ff2boss" in m))
	{
		local tTable = m
		local strRestKey = strFullKey
		for(;;)
		{
			local iPos = strRestKey.find(".")
			if(iPos == null)
			{
				if(strValue == null)
				{
					delete tTable[strRestKey]
				}
				else
				{
					tTable[strRestKey] <- strValue
				}
				break
			}

			strKey = strRestKey.slice(0, iPos)
			strRestKey = strRestKey.slice(iPos)

			if(!(strKey in tTable))
			{
				if(strValue == null)
					break

				tTable[strKey] <- {}
			}

			tTable = tTable[strKey]
		}

		if(bCallPawn)
		{
			if(strValue == null)
			{
				_FF2_CallPawn("deletekey", {client = hPlayer.entindex(), key = strFullKey})
			}
			else
			{
				_FF2_CallPawn("pushkey", {client = hPlayer.entindex(), key = strFullKey})
			}
		}
	}
}

/*
	Updates the player's boss config TO SourcePawn layer.
	Expensive as this requires writing to disk.
	Only needed if you have to do a full update to the SourcePawn layer.
*/
function FF2_PushBossConfig(hPlayer)
{
	local tTable = null

	local m = hPlayer.GetScriptScope()
	if(m != null && ("ff2boss" in m))
		tTable = m.ff2boss

	if(tTable != null)
	{
		_FF2_SaveBossToCache(tTable)
		_FF2_CallPawn("pushconfig", {client = hPlayer.entindex()})
	}
}

/*
	Updates the player's boss config FROM SourcePawn layer.
	Expensive as this requires writing to disk.
	Not recommended for use, players that become
	a boss automatically fetch their config anyways.
*/
function FF2_PullBossConfig(hPlayer)
{
	_FF2_CallPawn("pullconfig", {client = hPlayer.entindex()})
	local tTable = _FF2_LoadBossFromCache()

	hPlayer.ValidateScriptScope()
	local m = hPlayer.GetScriptScope()
	if(tTable == null)
	{
		if("ff2boss" in m)
			delete m.ff2boss
	}
	else
	{
		m.ff2boss <- tTable
	}

	return tTable
}

/*
	Gets an attribute, either TF2's list or custom list by FF2 weapons config.
	Returns null if no attribute is found.
*/
function FF2_GetAttribute(hEntity, strName)
{
	local flDefault = -999.9;
	local flResult = ("GetCustomAttribute" in hEntity) ? hEntity.GetCustomAttribute(strName, flDefault) : hEntity.GetAttribute(strName, flDefault)

	if(flResult == flDefault)
	{
		local m = activator.GetScriptScope()
		if(m == null || !("ff2attributes" in m) || !(strName in m.ff2attributes))
			return null

		flResult = m.ff2attributes[strName]
	}

	return flResult
}

/*
	Sets an attribute, adds to TF2 attribute list if it exists and to FF2 attribute list.
*/
function FF2_SetAttribute(hEntity, strName, flValue)
{
	if("AddCustomAttribute" in hEntity)
	{
		hEntity.AddCustomAttribute(strName, flValue, -1.0)
	}
	else
	{
		hEntity.AddAttribute(strName, flValue, -1.0)
	}

	hEntity.ValidateScriptScope()
	local m = hEntity.GetScriptScope()
	if(!("ff2attributes" in m))
		m.ff2attributes <- {}

	m.ff2attributes[strName] <- flValue
}

/*
	Removes an attribute, from TF2 and FF2 attribute list.
*/
function FF2_RemoveAttribute(hEntity, strName)
{
	if("RemoveCustomAttribute" in activator)
	{
		activator.RemoveCustomAttribute(strName)
	}
	else
	{
		activator.RemoveAttribute(strName)
	}

	local m = activator.GetScriptScope()
	if(m != null && ("ff2attributes" in m) && (strName in m.ff2attributes))
		delete m.ff2attributes[strName]
}