
/*	Copyright (C) 2022 SchutzE
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <clients>
#include <discord>
#include <geoip>
#include <multicolors>
#include <ripext>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required
int              NotBots;
char             inserver[64] = "", szSpectator[3], statecon[16] = "Connected", rescon[16] = "Connecting", statedis[16] = "Disconnected", szDiscordWebhook[256], szPvtDiscordWebhook[256], sz2PvtDiscordWebhook[256], szRole[64], szSteamApiKey[128], szPre[16], szDiscordWebhookTag[256], szRole2[64], szDirconn[64];
ConVar           cv_Name, sczSpectator, sczDiscordWebhook, sczRole, sczPvtDiscordWebhook, scz2PvtDiscordWebhook, sczSteamApiKey, sczPre, sczDiscordWebhookTag, sczRole2, sczDirconn;
bool             clientConnected[MAXPLAYERS + 1] = { false, ... }, clientIsAdmin[MAXPLAYERS + 1] = { false, ... }, canSendFB[MAXPLAYERS + 1] = { true, ... }, canSendTG[MAXPLAYERS + 1] = { true, ... };

public Plugin myinfo =
{
	name        = "Log Connections&Chat DC",
	author      = "Schutze",
	description = "This plugin logs players' connect, disconnect, & Chat times along with their Name, SteamID, and IP Address to a discord",
	version     = "1.0",
	url         = "https://github.com/farizmfadjri"


} enum struct playerData {
	int  userid;
	char avatarurl[256];
}
playerData playersdata[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_min", Command_ManggilAdmin);
	RegConsoleCmd("sm_gan", Command_ManggilAdmin);
	RegConsoleCmd("sm_need", Command_TagPlayer);
	RegConsoleCmd("sm_nd", Command_TagPlayer);
	sczSpectator 		  = CreateConVar("szdclog_specvalue", "2", "Spectator Count, Must Be INT");
	sczPre                = CreateConVar("szdclog_prefix", "[GWK]", "Prefix for the webhook");
	sczDiscordWebhookTag  = CreateConVar("szdclog_webhooktag", "", "Tag for the webhook");
	sczRole2              = CreateConVar("szdclog_role2", "", "Player Role for the webhook");
	sczDirconn            = CreateConVar("szdclog_dirconn", "", "Directory for the direct connect");
	sczSteamApiKey        = CreateConVar("szdclog_steamapikey", "", "Your Steam API key (needed for discord avatar)");
	sczDiscordWebhook     = CreateConVar("szdclog_discordwebhook", "", "Discord Log Connection Public Webhook");
	sczRole               = CreateConVar("szdclog_discordrole", "", "Dev/Owner/Mod Role ID to Tag when someone give feedback");
	scz2PvtDiscordWebhook = CreateConVar("szdclog_2pvtdiscordwebhook", "", "Discord Log Connection Private Webhook (Contain Player IP and Steam Profile Link)");
	sczPvtDiscordWebhook  = CreateConVar("szdclog_pvtdiscordwebhook", "", "Private Text Channel Webhook For See Feedback / Report / Critics");
	GetConVarString(sczSpectator, szSpectator, sizeof(szSpectator));
	GetConVarString(sczPre, szPre, sizeof(szPre));
	GetConVarString(sczDirconn, szDirconn, sizeof(szDirconn));
	GetConVarString(sczDiscordWebhookTag, szDiscordWebhookTag, sizeof(szDiscordWebhookTag));
	GetConVarString(sczRole2, szRole2, sizeof(szRole2));
	GetConVarString(sczDiscordWebhook, szDiscordWebhook, sizeof(szDiscordWebhook));
	GetConVarString(sczPvtDiscordWebhook, szPvtDiscordWebhook, sizeof(szPvtDiscordWebhook));
	GetConVarString(scz2PvtDiscordWebhook, sz2PvtDiscordWebhook, sizeof(sz2PvtDiscordWebhook));
	GetConVarString(sczRole, szRole, sizeof(szRole));
	GetConVarString(sczSteamApiKey, szSteamApiKey, sizeof(szSteamApiKey));
	AutoExecConfig(true, "sczlog");
	HookEventEx("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			clientConnected[client] = true;
			if (IsPlayerAdmin(client))
				clientIsAdmin[client] = true;
		}
	}
	cv_Name = FindConVar("hostname");
	cv_Name.GetString(inserver, 64);
	Format(inserver, 64, "%s", inserver);
	sczSpectator.AddChangeHook(OnSchutzeRelay);
	sczDirconn.AddChangeHook(OnSchutzeRelay);
	sczDiscordWebhook.AddChangeHook(OnSchutzeRelay);
	sczDiscordWebhookTag.AddChangeHook(OnSchutzeRelay);
	sczRole2.AddChangeHook(OnSchutzeRelay);
	sczPvtDiscordWebhook.AddChangeHook(OnSchutzeRelay);
	scz2PvtDiscordWebhook.AddChangeHook(OnSchutzeRelay);
	sczRole.AddChangeHook(OnSchutzeRelay);
	sczSteamApiKey.AddChangeHook(OnSchutzeRelay);
	sczPre.AddChangeHook(OnSchutzeRelay);
}

public void OnSchutzeRelay(ConVar convar, char[] oldValue, char[] newValue)
{
	sczDirconn.GetString(szDirconn, sizeof(szDirconn));
	sczSpectator.GetString(szSpectator, sizeof(szSpectator));
	sczPre.GetString(szPre, sizeof(szPre));
	sczDiscordWebhookTag.GetString(szDiscordWebhookTag, sizeof(szDiscordWebhookTag));
	sczRole2.GetString(szRole2, sizeof(szRole2));
	sczDiscordWebhook.GetString(szDiscordWebhook, sizeof(szDiscordWebhook));
	sczRole.GetString(szRole, sizeof(szRole));
	sczSteamApiKey.GetString(szSteamApiKey, sizeof(szSteamApiKey));
	sczPvtDiscordWebhook.GetString(szPvtDiscordWebhook, sizeof(szPvtDiscordWebhook));
	scz2PvtDiscordWebhook.GetString(sz2PvtDiscordWebhook, sizeof(sz2PvtDiscordWebhook));
}

public void OnMapStart()
{
	char FormatedTime[100];
	char MapName[100];

	int CurrentTime = GetTime();

	int lastPlayerC ;
	lastPlayerC = NotBots;
	NotBots = lastPlayerC;

	GetCurrentMap(MapName, 100);
	FormatTime(FormatedTime, 100, "%d_%b_%Y", CurrentTime);    // name the file 'day month year'
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAdmin(client))
		{
			clientIsAdmin[client] = true;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	DiscordWebHook hook  = new DiscordWebHook(szDiscordWebhook);
	DiscordWebHook phook = new DiscordWebHook(sz2PvtDiscordWebhook);
	cv_Name              = FindConVar("hostname");
	cv_Name.GetString(inserver, 64);
	hook.SlackMode  = true;
	phook.SlackMode = true;
	Format(inserver, 64, "%s", inserver);
	if (!client)
	{
		// console or unknown client
	}
	else if (IsFakeClient(client))
	{
		// bot
	}
	else if (clientConnected[client])
	{
		// Already connected
	}
	else if (IsPlayerAdmin(client))
	{    // ADMIN
		playersdata[client].userid = GetClientUserId(client);
		SteamAPIRequest(client);
		clientConnected[client] = true;
		clientIsAdmin[client]   = true;
		int  iTimeTmp           = GetTime();
		char PlayerName[64], szTime[512], Authid[64], IPAddress[64], Country[64], szConMsg[512], szPConMsg[512], szDscName[128], szID[64];
		GetClientName(client, PlayerName, 64);
		GetClientAuthId(client, AuthId_Steam2, Authid, sizeof(Authid), false);
		GetClientAuthId(client, AuthId_SteamID64, szID, sizeof(szID), false);
		GetClientIP(client, IPAddress, 64);
		FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %T", iTimeTmp);
		if (!GeoipCountry(IPAddress, Country, 64))
		{
			Format(Country, 64, "Unknown");
		}
		NotBots++;
		int playersCount = NotBots;
		Format(szDscName, sizeof(szDscName), "%s %s || %s", szPre, Authid, PlayerName);
		Format(szConMsg, sizeof(szConMsg), "```diff\n+Name: %s \n+Reason: %s \n+Status: %s \n+Country: %s \n+Server: %s \n+Player: %i/%i```", PlayerName, rescon, statecon, Country, inserver, playersCount, GetMaxHumanPlayers());
		Format(szPConMsg, sizeof(szPConMsg), "```diff\n+Name: %s \n+Reason: %s \n+Status: %s \n+Country: %s \n+Server: %s \nIP Addr: %s \n+Player: %i/%i```\n[Steam Profile](https://steamcommunity.com/profiles/%s)", PlayerName, rescon, statecon, Country, inserver, IPAddress, playersCount, GetMaxHumanPlayers(), szID);
		hook.SetUsername(szDscName);
		phook.SetUsername(szDscName);
		hook.SetAvatar(playersdata[client].avatarurl);
		phook.SetAvatar(playersdata[client].avatarurl);
		hook.SetContent(szConMsg);
		phook.SetContent(szPConMsg);
		hook.Send();
		phook.Send();
		delete hook;
		delete phook;
	}
	else    // PLAYER
	{
		playersdata[client].userid = GetClientUserId(client);
		SteamAPIRequest(client);
		clientConnected[client] = true;
		clientIsAdmin[client]   = false;
		int  iTimeTmp           = GetTime();
		char PlayerName[64], szTime[512], Authid[64], IPAddress[64], Country[64], szConMsg[512], szPConMsg[512], szDscName[128], szID[64];
		GetClientName(client, PlayerName, 64);
		GetClientAuthId(client, AuthId_Steam2, Authid, sizeof(Authid), false);
		GetClientAuthId(client, AuthId_SteamID64, szID, sizeof(szID), false);
		GetClientIP(client, IPAddress, 64);
		FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %T", iTimeTmp);
		if (!GeoipCountry(IPAddress, Country, 64))
		{
			Format(Country, 64, "Unknown");
		}
		NotBots++;
		int playersCount = NotBots;
		Format(szDscName, sizeof(szDscName), "%s %s || %s", szPre, Authid, PlayerName);
		Format(szConMsg, sizeof(szConMsg), "```diff\n+Name: %s \n+Reason: %s \n+Status: %s \n+Country: %s \n+Server: %s \n+Player: %i/%i```", PlayerName, rescon, statecon, Country, inserver, playersCount, GetMaxHumanPlayers());
		Format(szPConMsg, sizeof(szPConMsg), "```diff\n+Name: %s \n+Reason: %s \n+Status: %s \n+Country: %s \n+Server: %s \nIP Addr: %s \n+Player: %i/%i```\n[Steam Profile](https://steamcommunity.com/profiles/%s)", PlayerName, rescon, statecon, Country, inserver, IPAddress, playersCount, GetMaxHumanPlayers(), szID);
		hook.SetUsername(szDscName);
		phook.SetUsername(szDscName);
		hook.SetAvatar(playersdata[client].avatarurl);
		phook.SetAvatar(playersdata[client].avatarurl);
		hook.SetContent(szConMsg);
		phook.SetContent(szPConMsg);
		hook.Send();
		phook.Send();
		delete hook;
		delete phook;
	}
}

public Action Command_ManggilAdmin(int client, const char args)
{
	DiscordWebHook hook = new DiscordWebHook(szPvtDiscordWebhook);
	hook.SlackMode      = true;
	if (!canSendFB[client])
	{
		ReplyToCommand(client, " \x04 %s \x01CHILL DUDE, THIS COMMAND ON A COOLDOWN", szPre);
		return Plugin_Handled;
	}
	if (args < 1)
	{
		ReplyToCommand(client, " \x04 %s \x01Usage: !min [Your Req/?/feedback goes here]", szPre);
		return Plugin_Handled;
	}
	playersdata[client].userid = GetClientUserId(client);
	SteamAPIRequest(client);
	int  iTimeTmp = GetTime();
	char buginfo[64], szTime[512], IPAddress[64], szSteamID[21], Country[64], szDscName[128], szDscMsg[1024], szID[64];
	GetCmdArg(1, buginfo, sizeof(buginfo));
	char Name[32];
	GetClientName(client, Name, sizeof(Name));
	GetClientIP(client, IPAddress, 64);
	char Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg) - 0] = '\0';
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %T", iTimeTmp);
	cv_Name = FindConVar("hostname");
	cv_Name.GetString(inserver, 64);
	Format(inserver, 64, "%s", inserver);
		if (!GeoipCountry(IPAddress, Country, 64))
		{
			Format(Country, 64, "Unknown");
		}
	if (!GetClientAuthId(client, AuthId_Steam2, szSteamID, sizeof(szSteamID)))
	{
		LogError("Player %N's steamid couldn't be fetched", client);
		return Plugin_Handled;
	}
	if (!GetClientAuthId(client, AuthId_SteamID64, szID, sizeof(szID), false))
	{
		Format(szID, 64, "Unknown SteamID64");
	}
	Format(szDscName, sizeof(szDscName), "%s %s || %s", szPre, szSteamID, Name);
	Format(szDscMsg, sizeof(szDscMsg), "<@&%s>```diff\n+Sender: %s \n+Pesan: %s \nIP: %s \n+Negara: %s \n+Server: %s ```\n[Steam Profile](https://steamcommunity.com/profiles/%s)", szRole, Name, Msg, IPAddress, Country, inserver, szID);
	hook.SetUsername(szDscName);
	hook.SetAvatar(playersdata[client].avatarurl);
	hook.SetContent(szDscMsg);
	hook.Send();
	delete hook;

	PrintToChat(client, " \x04 %s \x01 Your Message Successfully Sent To Admin", szPre);
	canSendFB[client] = false;
	CreateTimer(30.0, ResetCooldown, client);
	return Plugin_Handled;
}

public Action ResetCooldown(Handle timer, any client)
{
	// Reset cooldown
	canSendFB[client] = true;
}

public Action Command_TagPlayer(int client, const char args)
{
	int spc = 2;
	int  playerleft = GetMaxHumanPlayers() - NotBots - spc;
	if (!canSendTG[client])
	{
		ReplyToCommand(client, " \x04 %s \x01CHILL DUDE, THIS COMMAND ON A COOLDOWN", szPre);
		return Plugin_Handled;
	}
	if (playerleft < GetMaxHumanPlayers() - spc)
	{
		DiscordWebHook hook = new DiscordWebHook(szDiscordWebhookTag);
		hook.SlackMode      = true;
		char szName[64], szTitle[128], szDscMsg[512] , szTag[64];
		playersdata[client].userid = GetClientUserId(client);
		SteamAPIRequest(client);
		GetClientName(client, szName, sizeof(szName));
		cv_Name = FindConVar("hostname");
		cv_Name.GetString(inserver, 64);
		MessageEmbed Embed = new MessageEmbed();
		Embed.SetColor("#FF0000");

		Format(szTag, sizeof(szTag), "<@&%s>", szRole2);
		Format(szTitle, sizeof(szTitle), "%s NEED %i PLAYERS !!", szPre, playerleft);
		Format(szDscMsg, sizeof(szDscMsg), "%s NEED %i PLAYERS\n IN SERVER : %s\n DIRECT CONNECT : %s",szPre, playerleft, inserver, szDirconn);
		hook.SetUsername(szName);
		hook.SetAvatar(playersdata[client].avatarurl);
		hook.SetContent(szTag);
		Embed.SetTitle(szTitle);
		Embed.AddField(szName, szDscMsg, false);
		Embed.SetFooter(inserver);
		hook.Embed(Embed);
		hook.Send();	
		delete hook;
		
		PrintToChat(client, " \x04%s\x01 Your Message Successfully Sent To Our Discord Server. DO NOT SPAM!", szPre);
		canSendTG[client] = false;
		CreateTimer(240.0, ResetCooldownTD, client);
		return Plugin_Handled;
	}
	else{
		PrintToChat(client, " \x04%s\x01 Players in this server are FULL", szPre);
		return Plugin_Handled;
	}
}

public Action ResetCooldownTD(Handle timer, any client)
{
	// Reset cooldown
	canSendTG[client] = true;
}

public Action Event_PlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	cv_Name = FindConVar("hostname");
	cv_Name.GetString(inserver, 64);
	Format(inserver, 64, "%s", inserver);
	DiscordWebHook hook  = new DiscordWebHook(szDiscordWebhook);
	DiscordWebHook phook = new DiscordWebHook(sz2PvtDiscordWebhook);
	hook.SlackMode       = true;
	phook.SlackMode      = true;
	int client           = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!clientConnected[client]) return;
	clientConnected[client] = false;
	if (client && !IsFakeClient(client))
	{
		playersdata[client].userid = GetClientUserId(client);
		SteamAPIRequest(client);
		int  iTimeTmp = GetTime();
		char PlayerName[64], szTime[512], Authid[64], IPAddress[64], Country[64], Reason[128], szDis[512], szPDis[512], szDscName[128], szID[64];
		GetClientName(client, PlayerName, 64);
		GetClientIP(client, IPAddress, 64);
		event.GetString("reason", Reason, sizeof(Reason), "EXITING / DISCONNECT");
		GetEventString(event, "reason", Reason, sizeof(Reason), "EXITING / DISCONNECT");
		FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %T", iTimeTmp);
		if (!GetClientAuthId(client, AuthId_Steam2, Authid, sizeof(Authid), false))
		{
			Format(Authid, 64, "Unknown SteamID");
		}
		if (!GetClientAuthId(client, AuthId_SteamID64, szID, sizeof(szID), false))
		{
			Format(szID, 64, "Unknown SteamID64");
		}
		GetClientIP(client, IPAddress, 64);
		if (!GeoipCountry(IPAddress, Country, 64))
		{
			Format(Country, 64, "Unknown");
		}
		NotBots--;
		int playersCount = NotBots;
		Format(szDis, sizeof(szDis), "```diff\n-Name: %s \n-Reason: %s \n-Status: %s \n-Country: %s \n-Server: %s \n+Player: %i/%i```", PlayerName, Reason, statedis, Country, inserver, playersCount, GetMaxHumanPlayers());
		Format(szDscName, sizeof(szDscName), "%s %s || %s", szPre, Authid, PlayerName);
		Format(szPDis, sizeof(szPDis), "```diff\n-Name: %s \n-Reason: %s \n-Status: %s \n-Country: %s \n-Server: %s \nIP Addr: %s \n+Player: %i/%i```\n[Steam Profile](https://steamcommunity.com/profiles/%s)", PlayerName, Reason, statedis, Country, inserver, IPAddress, playersCount, GetMaxHumanPlayers(), szID);
		hook.SetUsername(szDscName);
		phook.SetUsername(szDscName);
		hook.SetAvatar(playersdata[client].avatarurl);
		phook.SetAvatar(playersdata[client].avatarurl);
		hook.SetContent(szDis);
		phook.SetContent(szPDis);
		hook.Send();
		phook.Send();
		delete hook;
		delete phook;
		PrintToChatAll(" \x04%s\x01 %s is DISCONNECTED, Reason: %s", szPre, PlayerName, Reason);
	}

}

public void OnMapEnd(){
	int lastPlayerC ;
	lastPlayerC = NotBots;
	NotBots = lastPlayerC;
}

public void OnMapChange(){
	int lastPlayerC ;
	lastPlayerC = NotBots;
	NotBots = lastPlayerC;
}

public void OnMapChanged(){
	int lastPlayerC ;
	lastPlayerC = NotBots;
	NotBots = lastPlayerC;
}

// Checking if a client is admin
stock bool IsPlayerAdmin(int client)
{
	if (CheckCommandAccess(client, "Generic_admin", ADMFLAG_GENERIC, false))
	{
		return true;
	}
	return false;
}
stock void SteamAPIRequest(int client)
{
	HTTPClient httpClient;
	char       endpoint[1024];
	char       steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	Format(endpoint, sizeof(endpoint), "ISteamUser/GetPlayerSummaries/v2/?key=%s&steamids=%s", szSteamApiKey, steamid);
	httpClient = new HTTPClient("https://api.steampowered.com/");
	httpClient.Get(endpoint, SteamResponse_Callback, client);
}

stock void SteamResponse_Callback(HTTPResponse response, int client)
{
	if (response.Status != HTTPStatus_OK)
	{
		LogError("SteamAPI request fail, HTTPSResponse code %i", response.Status);
		/*connection message delayed so steamapi has time to fetch what it needs*/
		// If there is an error, still send connection message.
	}
	JSONObject objects   = view_as<JSONObject>(response.Data);
	JSONObject Response  = view_as<JSONObject>(objects.Get("response"));
	JSONArray  players   = view_as<JSONArray>(Response.Get("players"));
	int        playerlen = players.Length;
	JSONObject player;
	for (int i = 0; i < playerlen; i++)
	{
		player = view_as<JSONObject>(players.Get(i));
		player.GetString("avatarmedium", playersdata[client].avatarurl, sizeof(playerData::avatarurl));
		delete player;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0)
		return false;
	if (client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (IsFakeClient(client))
		return false;
	return IsClientInGame(client);
}
