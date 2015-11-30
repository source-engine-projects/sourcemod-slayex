int g_iSelectedTarget[MAXPLAYERS+1];
int g_iPendingSlays[MAXPLAYERS+1];

#include <ttt>

public void TTT_OnRoundStart_Pre(){
	for(int i=1;i<=MaxClients;i++){
		if(TTT_IsClientValid(i) && IsPlayerAlive(i) && (g_iPendingSlays[i] > 0)){
			g_iPendingSlays[i] -= 1;
			ForcePlayerSuicide(i);
			
			ShowActivity2(0, "[SM] ", "%t", "Pending slays left", target_name, g_iPendingSlays[i]);
		}
	}
}

void PerformSlay(int client, int target, int times=1){
	g_iSelectedTarget[client] = 0;
	g_iPendingSlays[target] += times;
	
	LogAction(client, target, "\"%L\" marked \"%L\" to be slayed %i times", client, target, times);
	
	if(IsPlayerAlive(target)){
		g_iPendingSlays[target] -= 1;
		ForcePlayerSuicide(target);
	}
}

void DisplaySlayMenu(int client){
	g_iSelectedTarget[client] = 0;
	Menu menu = CreateMenu(MenuHandler_Slay);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Slay player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public AdminMenu_Slay(Handle topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "Slay player", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySlayMenu(param);
}

public MenuHandler_Slay(Menu menu, MenuAction action, int param1, int param2){
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != null)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			g_iSelectedTarget[client] = userid;
			Menu menu = CreateMenu(MenuHandler_Slay2);
			
			menu.SetTitle("# of times");
			menu.ExitBackButton = true;
			
			menu.AddItem("1", "1");
			menu.AddItem("2", "2");
			menu.AddItem("3", "3");
			menu.AddItem("4", "4");
			menu.AddItem("5", "5");
			
			menu.Display(client, MENU_TIME_FOREVER);
		}
		
		DisplaySlayMenu(param1);
	}
}

public int MenuHandler_Slay2(Menu menu, MenuAction action, int param1, int param2){
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != null)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid = g_iSelectedTarget[param1]; int target;
		int times;

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			menu.GetItem(param2, info, sizeof(info));
			times = StringToInt(info);
			
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			
			PerformSlay(param1, target, times);
			ShowActivity2(param1, "[SM] ", "%t", "Marked to slay", "_s", name, times);
		}
		
		DisplaySlayMenu(param1);
	}
}

public Action Command_Slay(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_slay <#userid|name> [times]");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS]; int target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int times = 0;
	if (args > 1){
		char arg2[20];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StringToIntEx(arg2, times) == 0 || times < 0){
			times = 1;
		}
	}
	

	for (int i = 0; i < target_count; i++){
		PerformSlay(client, target_list[i], times);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Marked to slay", target_name, times);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Marked to slay", "_s", target_name, times);
	}

	return Plugin_Handled;
}