#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
public Plugin myinfo =
{
    name        = "幻世纪反狗插件",
    author        = "1",
    description    = "2",
    version        = "1.0.0",
    url            = ""
}

bool anti_rool;
int clientnumber[32];

public void OnPluginStart()
{
    anti_rool = true;
    RegConsoleCmd("sm_anti_roll", Command_Anti_Roll);
    CreateTimer(5.0, CheckUntrusted, _, TIMER_REPEAT);
    HookEvent("round_start",Event_OnRoundStart);
}
public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        int warmupPeriod = GameRules_GetProp("m_bWarmupPeriod");
        if (warmupPeriod == 1)
            {
                clientnumber[i] = 0;
            }
    }
}

public Action Command_Anti_Roll(int client, int args)
{
    anti_rool = !anti_rool;
    if (anti_rool)
    {
        PrintToChat(client,"\x0E\x0B \x0F[SVS] \x05反roll插件已开启");
        return Plugin_Handled;
    }else{
        PrintToChat(client,"\x0E\x0B \x0F[SVS] \x05反roll插件已关闭");
        return Plugin_Handled;
    }

}
 
public Action CheckUntrusted(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_vecOrigin") && IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && anti_rool)
        {
            int warmupPeriod = GameRules_GetProp("m_bWarmupPeriod");
            char clientname[32];
            float pos[3];
            float view_pos[3];
            GetClientName(i, clientname, 32);
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
            GetClientEyeAngles(i, view_pos);
            if (pos[0] == 0 && pos[1] == 0)
            {
                PrintToChatAll("\x0E\x0B \x0E[SVS] %s 试图使用tp", clientname);
                ForcePlayerSuicide(i);
            }
            
            if (view_pos[2] > 2 || view_pos[2] < -2)
            {
                clientnumber[i] = clientnumber[i] + 1;
                PrintToChatAll("\x0E\x0B \x0F[SVS] \x03 %s \x05开roll了 (Roll: %f)[%i次]", clientname, view_pos[2], clientnumber[i]);
                if(warmupPeriod == 1)
                {
                    ForcePlayerSuicide(i);
                }
                if (clientnumber[i] == 5 || clientnumber[i] == 10 && warmupPeriod != 1)
                {
                    PrintToChatAll("\x0E\x0B \x0F[SVS] \x03 %s \x05开roll多次 到达15次将结束比赛", clientname);
                }
            }
            
            if (clientnumber[i] >= 10 && warmupPeriod == 1)
            {
                KickClient(i,"[SVS] 多次不合法");
                clientnumber[i] = 0;
            }
            
            if (clientnumber[i] >= 15 && warmupPeriod != 1)
            {
                PrintToChatAll("\x0E\x0B \x0F[SVS] \x03 %s \x05开roll多次 已结束比赛", clientname);
                ServerCommand("sm_endgame");
                clientnumber[i] = 0;
            }
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "logic_script", true) 
		|| StrEqual(classname, "trigger_multiple", true))
	{
		SDKHook(entity, SDKHook_Spawn, SDK_OnEntitySpawn);
	}
}

public void SDK_OnEntitySpawn(int entity)
{
	char vScripts[256];
	GetEntPropString(entity, Prop_Data, "m_iszVScripts", vScripts, sizeof(vScripts));
	
	if (StrEqual(vScripts, "warmup/warmup_arena.nut", true) 
		|| StrEqual(vScripts, "warmup/warmup_teleport.nut", true))
	{
		DispatchKeyValue(entity, "vscripts", "");
		DispatchKeyValue(entity, "targetname", "");
	}
}