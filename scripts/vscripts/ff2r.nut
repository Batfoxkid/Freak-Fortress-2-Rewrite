/*
	VScript script for calling special functions for Freak Fortress 2: Rewrite
*/

function FF2R_GetAttribute(strName)
{
	local flDefault = -999.9;
	local flResult = ("GetCustomAttribute" in activator) ? activator.GetCustomAttribute(strName, flDefault) : activator.GetAttribute(strName, flDefault)

	if(flResult == flDefault)
	{
		local m = activator.GetScriptScope()
		if(m == null || !("attributes" in m) || !(strName in m.attributes))
			return

		flResult = m.attributes[strName]
	}

	FF2R_CallPawn("returning", {returnfloat = flResult})
}

function FF2R_SetAttribute(strName, flValue)
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
	if(!("attributes" in m))
		m.attributes <- {}

	m.attributes[strName] <- flValue
}

function FF2R_RemoveAttribute(strName)
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
	if(m != null && ("attributes" in m) && (strName in m.attributes))
		delete m.attributes[strName]
}

function FF2R_CallPawn(strEvent, tTable)
{
	tTable.id <- "ff2r"
	tTable.event <- strEvent
	SendGlobalGameEvent("tf_map_time_remaining", tTable)
}