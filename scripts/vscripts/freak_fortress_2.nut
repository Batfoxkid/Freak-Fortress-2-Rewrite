SCRIPT_VERSION <- 2
/*
	VScript script for calling special functions for Freak Fortress 2: Rewrite
*/

function _FF2_GetAttribute(strName)
{
	local flDefault = -999.9;
	local flResult = ("GetCustomAttribute" in activator) ? activator.GetCustomAttribute(strName, flDefault) : activator.GetAttribute(strName, flDefault)

	if(flResult == flDefault)
	{
		local m = activator.GetScriptScope()
		if(m == null || !("ff2attributes" in m) || !(strName in m.ff2attributes))
			return

		flResult = m.ff2attributes[strName]
	}

	FF2R_CallPawn("returning", {returnfloat = flResult})
}

function _FF2_SetAttribute(strName, flValue)
{
	if("AddCustomAttribute" in activator)
	{
		activator.AddCustomAttribute(strName, flValue, -1.0)
	}
	else
	{
		activator.AddAttribute(strName, flValue, -1.0)
	}

	activator.ValidateScriptScope()
	local m = activator.GetScriptScope()
	if(!("ff2attributes" in m))
		m.ff2attributes <- {}

	m.ff2attributes[strName] <- flValue
}

function _FF2_RemoveAttribute(strName)
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

function _FF2_CallPawn(strEvent, tTable)
{
	tTable.id <- "freak_fortress_2"
	tTable.event <- strEvent
	SendGlobalGameEvent("tf_map_time_remaining", tTable)
}