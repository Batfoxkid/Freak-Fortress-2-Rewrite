/*
	"special_saxton_improved"
	{
		"plugin_name"	"ff2r_saxton_abilities"
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <cfgmap>
#include <ff2r>
#include <tf2items>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	36
#define FAR_FUTURE		100000000.0

#define TF2U_LIBRARY	"nosoop_tf2utils"
#define TCA_LIBRARY		"tf2custattr"

#if defined __nosoop_tf2_utils_included
bool TF2ULoaded;
#endif

#if defined __tf_custom_attributes_included
bool TCALoaded;
#endif

Handle SyncHud;
int PlayersAlive[4];
bool SpecTeam;

bool BraveJump[MAXTF2PLAYERS];
bool BraveJumping[MAXTF2PLAYERS];

bool ChargeJump[MAXTF2PLAYERS];
bool ChargeJumping[MAXTF2PLAYERS];

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Saxton 2023",
	author		=	"Batfoxkid",
	description	=	"Contains too much excitement!",
	version		=	PLUGIN_VERSION,
	url			=	"https://github.com/Batfoxkid/Freak-Fortress-2-Rewrite"
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	
	SyncHud = CreateHudSynchronizer();
	
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
			
			BossData cfg = FF2R_GetBossData(client);
			if(cfg)
			{
				FF2R_OnBossCreated(client, cfg, false);
				FF2R_OnBossEquipped(client, true);
			}
		}
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(FF2R_GetBossData(client))
				FF2R_OnBossRemoved(client);
		}
	}
}

public void FF2R_OnBossCreated(int client, BossData boss, bool setup)
{
	if(!setup || FF2R_GetGamemodeType() != 2)
	{
		if(!BraveJump[client])
		{
			AbilityData ability = boss.GetAbility("special_brave_jump");
			if(ability.IsMyPlugin())
			{
				BraveJump[client] = true;
			}
		}

		if(!ChargeJump[client])
		{
			AbilityData ability = boss.GetAbility("special_charge_jump");
			if(ability.IsMyPlugin())
			{
				ChargeJump[client] = true;
				ability.SetFloat("delay", GetGameTime() + ability.GetFloat("delay", 5.0));
			}
		}
	}
}

public void FF2R_OnBossRemoved(int client)
{
	BraveJump[client] = false;
	BraveJumping[client] = false;

	ChargeJump[client] = false;
	ChargeJumping[client] = false;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3])
{
	if(BraveJump[client])
	{
		if(!BraveJumping[client])
		{
			static bool holding[MAXTF2PLAYERS];
			if(holding[client])
			{
				if(!(buttons & IN_JUMP))
					holding[client] = false;
			}
			else if(buttons & IN_JUMP)
			{
				if(IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_ONGROUND))
				{
					BossData boss = FF2R_GetBossData(client);
					AbilityData ability;
					if(boss && (ability = boss.GetAbility("special_charge_jump")))
					{
						float gameTime = GetGameTime();
						float spam = ability.GetFloat("spam");
						float stale = spam - gameTime;
						if(stale > 10.0)
						{
							stale = 8.0 / stale;
						}
						else
						{
							stale = 1.0;
						}
						
						float velocity = ability.GetFloat("velocity", 300.0) * stale;

						float fwd[3], right[3];
						GetAngleVectors(angles, fwd, right, NULL_VECTOR);
						
						fwd[2] = 0.0;
						NormalizeVector(fwd, fwd);
						
						right[2] = 0.0;
						NormalizeVector(right, right);
						
						float newVel[3];
						newVel[0] = (fwd[0] * vel[0]) + (right[0] * vel[1]);
						newVel[1] = (fwd[1] * vel[0]) + (right[1] * vel[1]);
						NormalizeVector(newVel, newVel);
						ScaleVector(newVel, velocity);
						newVel[2] = ability.GetFloat("upward", 700.0) * stale;
						
						float curVel[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", curVel);
						if(curVel[2] < velocity)
							curVel[2] = 0.0;
						
						AddVectors(newVel, curVel, newVel);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newVel);
						
						BraveJumping[client] = true;

						if(spam < gameTime)
							spam = gameTime;

						ability.SetFloat("spam", spam + 3.0);
						
						FF2R_EmitBossSoundToAll("sound_brave_jump", client, _, client, _, SNDLEVEL_TRAFFIC);
					}
					else
					{
						BraveJump[client] = false;
					}
				}
			}
		}
	}
	
	if(ChargeJump[client])
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_charge_jump")))
		{
			if(IsPlayerAlive(client))
			{
				float gameTime = GetGameTime();
				bool cooldown = ability.GetBool("incooldown", true);
				float timeIn = ability.GetFloat("delay");
				bool hud;
				
				if(cooldown)
				{
					if(timeIn < gameTime)
					{
						cooldown = false;
						timeIn = 0.0;
						
						ability.SetBool("incooldown", cooldown);
						ability.SetFloat("delay", timeIn);
						
						hud = true;
					}
				}
				else
				{
					bool ground = view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);
					
					float charge = ability.GetFloat("charge", 1.5);
					if(charge < 0.001)
						charge = 0.001;
					
					if(timeIn)
						charge = (gameTime - timeIn) / charge * 100.0;
					
					if((ground || charge < 200.0) && ((buttons & IN_RELOAD) || (buttons & IN_ATTACK3)))
					{
						if(!timeIn)
						{
							timeIn = gameTime;
							ability.SetFloat("delay", timeIn);
							
							hud = true;
						}
						
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 0.0});
						if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							TF2_AddCondition(client, TFCond_Zoomed);
						
						int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(entity != -1)
						{
							int index = ability.GetInt("weapon_airindex", -1);
							if(index >= 0)
								SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
							
							TF2Attrib_SetByDefIndex(entity, 54, 0.25);
							TF2Attrib_SetByDefIndex(entity, 821, 1.0);
						}
					}
					else if(timeIn)
					{
						hud = true;

						int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(entity != -1)
						{
							int index = ability.GetInt("weapon_groundindex", -1);
							if(index >= 0)
								SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
							
							TF2Attrib_SetByDefIndex(entity, 54, 1.0);
							TF2Attrib_SetByDefIndex(entity, 821, 0.0);
						}

						if(charge > 100.0)
							charge = 100.0;
						
						float time = charge / 166.0 + 0.4;

						TF2_RemoveCondition(client, TFCond_Zoomed);
						TF2_AddCondition(client, TFCond_HalloweenKartDash, 0.1, client);
						TF2_AddCondition(client, TFCond_BlastJumping, _, client);
						TF2_AddCondition(client, TFCond_AirCurrent, time, client);
						
						float fwd[3];
						GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, ability.GetFloat("velocity", 800.0) * time);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fwd);
						SetEntityGravity(client, 0.3);

						CreateTimer(time, Timer_EndCharge, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

						char buffer[12];
						if(ability.GetString("slot", buffer, sizeof(buffer)))
							FF2R_EmitBossSoundToAll("sound_ability", client, buffer, client, _, SNDLEVEL_TRAFFIC);
						
						cooldown = true;
						ability.SetBool("incooldown", cooldown);
						
						timeIn = gameTime + time + ability.GetFloat("cooldown", 10.0);
						ability.SetFloat("delay", timeIn);
					}
					else
					{
						timeIn = 0.0;
						ability.SetFloat("delay", 0.0);
					}
				}
				
				if(!(buttons & IN_SCORE) && (hud || ability.GetFloat("hudin") < gameTime))
				{
					ability.SetFloat("hudin", gameTime + 0.09);
					
					SetGlobalTransTarget(client);
					if(cooldown)
					{
						SetHudTextParams(-1.0, 0.88, 0.1, 255, 64, 64, 255);
						ShowSyncHudText(client, SyncHud, "%t", "Boss Mobility Time", timeIn - gameTime + 0.09);
					}
					else
					{
						SetHudTextParams(-1.0, 0.88, 0.1, 255, 255, 255, 255);
						
						if(timeIn)
						{
							float charge = ability.GetFloat("charge", 1.5);
							if(charge > 100.0)
							{
								charge = 100.0;
							}
							else if(charge < 0.001)
							{
								charge = 0.001;
							}
							
							ShowSyncHudText(client, SyncHud, "%t", "Boss Mobility Charge", RoundToCeil((gameTime - timeIn) / charge * 100.0));
						}
						else
						{
							ShowSyncHudText(client, SyncHud, "%t%t", "Boss Mobility Charge", 0, "Boss Mobility 13");
						}
					}
				}
			}
		}
		else
		{
			MobilityEnabled[client] = false;
		}
	}
}

public Action Timer_EndCharge(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && !ChargeJumping[client])
	{
		ChargeJumping[client] = false;
		TF2_AddCondition(client, TFCond_GrapplingHookLatched);
		SetEntityGravity(client, 1.0);
	}
	return Plugin_Continue;
}

int GetTotalPlayersAlive(int team = -1)
{
	int amount;
	for(int i = SpecTeam ? 0 : 2; i < sizeof(PlayersAlive); i++)
	{
		if(i != team)
			amount += PlayersAlive[i];
	}
	
	return amount;
}

float GetFormula(ConfigData cfg, const char[] key, int players, float defaul = 0.0)
{
	static char buffer[1024];
	if(!cfg.GetString(key, buffer, sizeof(buffer)))
		return defaul;
	
	return ParseFormula(buffer, players);
}

float GetBossCharge(ConfigData cfg, const char[] slot, float defaul = 0.0)
{
	int length = strlen(slot)+7;
	char[] buffer = new char[length];
	Format(buffer, length, "charge%s", slot);
	return cfg.GetFloat(buffer, defaul);
}

void SetBossCharge(ConfigData cfg, const char[] slot, float amount)
{
	int length = strlen(slot)+7;
	char[] buffer = new char[length];
	Format(buffer, length, "charge%s", slot);
	cfg.SetFloat(buffer, amount);
}
