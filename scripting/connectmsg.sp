#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <geoip>


public Plugin myinfo = 
{
    name = "Connect Broadcast",
    author = "Picrisol45",
    description = "Broadcast of player connect/spawn/disconnect the server",
    version = "1.0",
    url = "https://github.com/TeasOfficial/Simple-Connect-Boradcast/"
};

public void OnPluginStart()
{
    HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
    HookEvent("player_connect_client", Event_PlayerConnectClient, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

// 拦截游戏默认加入消息
public Action Event_PlayerConnectClient(Event event, const char[] name, bool dontBroadcast)
{  
     
    
    SetEventBroadcast(event, true);  //先关闭默认通知
    return Plugin_Continue;          // 防止影响其他插件

    /*return Plugin_Handled;*/      //也行但是会降低兼容性         
}

// 玩家连接服务器发送广播
public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{  
    char playerName[64];
    char steamID3[32];
    char steamID2[32];
    char ip[64];
    char message[256];
    char Country[99];
    char Country_Code2[3];

    event.GetString("name", playerName, sizeof(playerName));
    event.GetString("networkid", steamID3, sizeof(steamID3));
    event.GetString("address", ip, sizeof(ip));

    if (StrEqual(steamID3, "BOT", false))
    {
        // 如果是机器人则跳过信息
        return Plugin_Continue;
    }

    // 写死IP, 测试国籍信息专用 (Debug)
    //strcopy(ip, sizeof(ip), "117.178.56.98");

    // 未知IP处理
    if (!GeoipCountry(ip, Country, sizeof Country))
	{
		Country = "UnknownCountry";
	}

    if (!GeoipCode2(ip, Country_Code2))
	{
		Country_Code2 = "NO";
	}

    if (!ConvertSteamID3ToSteamID2(steamID3, steamID2, sizeof(steamID2)))
    {
        // 转换失败用原始SteamID3
         strcopy(steamID2, sizeof(steamID2), steamID3);
    }

    Format(message, sizeof(message), "{lightskyblue}▲ %s {white}<{variable}%s{white}, {variable}%s{white}> {white}connected from {lightskyblue}%s {white}({lightskyblue}%s{white})", playerName, steamID2, ip, Country, Country_Code2);
    CPrintToChatAll(message);

    return Plugin_Handled;
}

// 玩家完全进入服务器
public void OnClientPutInServer(int client)
{
    if (!IsClientInGame(client))
        return;
    // 调用定时器, 1.5秒后发消息
    CreateTimer(1.5, Timer_SendConnectMessage, client);
}

// 定时器回应
public Action Timer_SendConnectMessage(Handle timer, any client)
{
    if (!IsClientInGame(client))
        return Plugin_Stop;

    char name[MAX_NAME_LENGTH];
    char steamID[32];
    char message[128];
    char IsBot[64];

    GetClientName(client, name, sizeof(name));
    GetClientAuthString(client, steamID, sizeof(steamID));

    // 如果是BOT则加上特殊标签REPLAY BOT(Shavit Timer Bot)
    if (StrEqual(steamID, "BOT", false))
    {
        strcopy(IsBot, sizeof(IsBot), " {white}<{variable}REPLAY BOT{white}>");
    }
    else
    {
        strcopy(IsBot, sizeof(IsBot), "");
    }
    
    Format(message, sizeof(message), "{lightskyblue}▲ %s {white}%s has joined.", name, IsBot);
    CPrintToChatAll(message);

    return Plugin_Stop;
}

// 监听断开事件，并获取退出原因
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);
    
    char playerName[64];
    char steamID3[32];
    char steamID2[32];
    char reason[128];
    char message[256];

    event.GetString("name", playerName, sizeof(playerName));
    event.GetString("networkid", steamID3, sizeof(steamID3));
    event.GetString("reason", reason, sizeof(reason));

    if (!ConvertSteamID3ToSteamID2(steamID3, steamID2, sizeof(steamID2)))
    {
        strcopy(steamID2, sizeof(steamID2), steamID3);
    }

    Format(message, sizeof(message), "{lightcoral}▼ %s {white}<{variable}%s{white}> {white}disconnected. {white}({lightcoral}%s{white})", playerName, steamID2, reason);

    CPrintToChatAll(message);

    return Plugin_Continue;
}

// Convert SteamID3 -> SteamID2 (感谢ChatGPT) 草拟吗壁SourcePawn不能用sccanf()
bool ConvertSteamID3ToSteamID2(const char[] steamID3, char[] steamID2, int maxlen)
{
    int length = strlen(steamID3);
    int lastColon = -1;

    for (int i = length - 1; i >= 0; i--)
    {
        if (steamID3[i] == ':')
        {
            lastColon = i;
            break;
        }
    }

    if (lastColon == -1)
        return false;

    int numLen = length - lastColon - 2; // 去掉 ':' 和结尾 ']'

    if (numLen <= 0 || numLen >= 32)
        return false;

    char idStr[32];
    for (int j = 0; j < numLen; j++)
    {
        idStr[j] = steamID3[lastColon + 1 + j];
    }
    idStr[numLen] = '\0';

    int accountID = StringToInt(idStr);

    int Y = accountID % 2;
    int Z = accountID / 2;

    Format(steamID2, maxlen, "STEAM_0:%d:%d", Y, Z);

    return true;
}
