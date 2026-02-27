/*
	Internal functions for SourcePawn <--> VScript
*/

// Clear and create the folder we need
StringToFile("ff2bosscache.dat", "hello")

function _FF2_GetAttribute(strName)
{
	local flResult = FF2_GetAttribute(activator, strName)
	if(flResult != null)
		_FF2_CallPawn("returning", {returnfloat = flResult})
}

function _FF2_SetAttribute(strName, flValue)
{
	FF2_SetAttribute(activator, strName, flValue)
}

function _FF2_RemoveAttribute(strName)
{
	FF2_RemoveAttribute(activator, strName)
}

function _FF2_CallPawn(strEvent, tTable)
{
	tTable.id <- "freak_fortress_2"
	tTable.event <- strEvent
	SendGlobalGameEvent("tf_map_time_remaining", tTable)
}

function _FF2_UseAbility(strName)
{
	local tBoss = FF2_GetBossConfig(activator)
	local tAbility = null

	if(tBoss != null && (strName in tBoss))
		tAbility = tBoss[strName]

	FireScriptHook("FF2_OnAbility", {client = activator, name = strName, ability = tAbility})
}

function _FF2_BossCreated()
{
	local tTable = _FF2_LoadBossFromCache()

	activator.ValidateScriptScope()
	local m = activator.GetScriptScope()
	m.ff2boss <- tTable

	FireScriptHook("FF2_OnBossCreated", {client = activator, boss = FF2_GetBossConfig(activator)})
}

function _FF2_BossEquipped()
{
	FireScriptHook("FF2_OnBossEquipped", {client = activator, boss = FF2_GetBossConfig(activator)})
}

function _FF2_BossRemoved()
{
	FireScriptHook("FF2_OnBossRemoved", {client = activator})

	local m = activator.GetScriptScope()
	if(m != null && ("ff2boss" in m))
		delete m.ff2boss
}

function _FF2_UpdateKey(strFullKey, strValue)
{
	FF2_UpdateBossConfig(activator, strFullKey, strValue, false)
}

function _FF2_DeleteKey(strFullKey)
{
	FF2_UpdateBossConfig(activator, strFullKey, null, false)
}

/*
	weapon
		classnamegoop
		index57
		attributes
			damage53.0
		
	
*/

function _FF2_SaveBossToCache(tTable)
{
	local strData = _FF2_TableToString(tTable)
	StringToFile("ff2bosscache.dat", strData)
}

function _FF2_LoadBossFromCache()
{
	local strData = FileToString("ff2bosscache.dat")
	if(strData == null)
		return null

	local aData = _FF2_StringToTable(strData, 0)
	return aData[0]
}

function _FF2_TableToString(tTable)
{
	local aKeys = tTable.keys()
	local iLength = aKeys.len()
	local strData = ""

	for(local i = 0; i < iLength; i++)
	{
		local strKey = aKeys[i]
		local data = tTable[strKey]
		local strType = typeof(data)

		strData += strKey + _FF2_DataToString(data)
	}

	return strData
}

function _FF2_ArrayToString(aArray)
{
	local iLength = aArray.len()
	local strData = ""

	for(local i = 0; i < iLength; i++)
	{
		local data = aArray[i]
		local strType = typeof(data)

		strData += (i + 1).tostring() + _FF2_DataToString(data)
	}

	return strData
}

function _FF2_DataToString(data)
{
	local strType = typeof(data)
	local strData = ""

	if(strType == "Vector" || strType == "QAngle")
	{
		strData = "" + format("%.2f %.2f %.2f", data.x, data.y, data.z)
	}
	else if(strType == "Vector2D")
	{
		strData = "" + format("%.2f %.2f", data.x, data.y)
	}
	else if(strType == "Vector4D" || strType == "Quaternion")
	{
		strData = "" + format("%.2f %.2f %.2f %.2f", data.x, data.y, data.z, data.w)
	}
	else if(strType == "table")
	{
		strData = "" + _FF2_TableToString(data)
	}
	else if(strType == "array")
	{
		strData = "" + _FF2_ArrayToString(data)
	}
	else if(strType == "integer")
	{
		strData = "" + data.tostring()
	}
	else if(strType == "float")
	{
		strData = "" + format("%.2f", data)
	}
	else if(strType == "string")
	{
		strData = "" + data
	}
	else
	{
		throw "Class '" + strType + "' not programmed for cfgs"
	}

	strData += ""
	return strData
}

function _FF2_StringToTable(strString, iStartPos)
{
	local iPos = iStartPos
	local tTable = {}

	for(;;)
	{
		local iValueEnd = strString.find("", iPos)
		if(iValueEnd == null)
			break

		// End of tree
		if(iValueEnd == iPos)
		{
			iPos++
			break
		}

		local bTable = true
		local iEnd = strString.find("", iPos)
		if(iEnd == null || iEnd > iValueEnd)
		{
			// If "" is closer, assume that's it's key:value
			iEnd = iValueEnd
			bTable = false
		}

		local strKey = strString.slice(iPos, iEnd)
		iPos = iEnd + 1

		local aData = []
		if(bTable)
		{
			aData = _FF2_StringToTable(strString, iPos)
		}
		else
		{
			aData = _FF2_StringToData(strString, iPos)
		}

		tTable[strKey] <- aData[0]
		iPos = aData[1]
	}

	return [tTable, iPos]
}

function _FF2_StringToData(strString, iStartPos)
{
	local iEnd = strString.find("", iStartPos)
	if(iEnd == null)
		return [null, iStartPos]

	local strData = strString.slice(iStartPos, iEnd)
	local iPos = iEnd + 1
	return [strData, iPos]
}