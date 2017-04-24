// Plugin and Scripts by Drixevel, Pull request by General Lentils//

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// So you want to make a custom LR? Nice! Let's get right into it.                                                                                                  //
// The first thing you want to do is navigate to your Last Request config located in sourcemod/configs/TF2Jail, and create a new row for your custom LR like this:  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

"TF2Jail_LastRequests"
{
	"0" // Whatever number comes after the last LR number in your lastrequests.cfg, Don't just put a random number here, if you do that, the LR menu will not work.
	{
		"Name"			"My LR"
		"Description"		"I made this LR!" // Will be shown in the sm_lrlist command when a player clicks the LR to show more info.
		"Handler"		"yourhandlername"
		"Queue_Announce"	"%M Place your chat announcement here"

		"Parameters" // These are also found in your lastrequests.cfg. Edit/Add them to your liking.
		{
			"Disabled"		"0"
			"OpenCells"		"0"
			"VoidFreekills"		"0"
			"IsVIPOnly"		"0"
			"TimerStatus"		"1"
			"LockWarden"		"0"
			"EnableCriticals"	"1"
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// You have now set up the config for your last request. Now you can get into the scripting part:  //
/////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1 // This isn't neccesary, but it helps you make a clean code.

#include <sourcemod>
#include <tf2jail>	// Be sure to include the TF2Jail include, else you won't be able to call TF2Jail_OnLastRequestExecute.


public TF2Jail_OnLastRequestExecute(const String:Handler[])
{
	if (StrEqual(Handler, "yourhandlername")) //"Handler" -- Specified in the configuration you just made.
	{
		// When a client picks the last request with handler "yourhandlername" in this case, this will get called. From here you can do anything you want to happen in the LR. 
	}
}    

/* Examples can be found in the file: "TF2Jail_LastRequests.sp". Have fun!
