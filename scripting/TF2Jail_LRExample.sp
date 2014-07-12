#pragma semicolon 1

#include <sourcemod>

//TF2Jail Includes
#include <tf2jail>	//Be sure to include the TF2Jail include.

/**
 * Called when a last request is about to be executed.
 *
 * @param Handler		String or text called by the Handler in the Last Request configuration file. (Use this to differentiate your custom LRs)
 * @noreturn
 **/
public TF2Jail_OnLastRequestExecute(const String:Handler[])
{
	if (StrEqual(Handler, "gabenthegreat"))	//"Handler"	"gabenthegreat"			-- Based in the configuration file.
	{
		//Execute your code on all clients, create timers, etc. Be sure to hook into events like the end of the round to disable effects.
	}
}