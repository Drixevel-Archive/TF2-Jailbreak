#if defined _betheskeleton_included_
  #endinput
#endif
#define _betheskeleton_included_

enum SkeletonStatus {
	SkeletonStatus_Human = 0, // Client is human
	SkeletonStatus_WantsToBeSkeleton, // Client wants to be Skeleton, but can't because of defined rules.
	SkeletonStatus_Skeleton // Client is a Skeleton. Beep boop.
}

/**
 * Checks if a client is a Skeleton.
 *
 * @param client			Index of the client to check.
 * @return					SkeletonStatus value of the client; SkeletonStatus_Human if they're a human, SkeletonStatus_Skeleton if they're a Skeleton, SkeletonStatus_WantsToBeSkeleton if they want to be a Skeleton, but can't for some reason.
 */
native SkeletonStatus:BeTheSkeleton_GetSkeletonStatus(client);

/**
 * Sets if a client should be Skeleton or not.
 *
 * @param client			Index of the client to set.
 * @param toggle			True to make the client a Skeleton, false to change them back to a human. Skip this argument to toggle instead.
 * @noreturn
 */
native BeTheSkeleton_SetSkeleton(client, bool:toggle = bool:2);

/**
 * Uses Be the Skeleton's "CheckTheRules()" native to check if a client should be allowed to be a Skeleton or not.
 *
 * @param client			Index of the client to check.
 * @return					True if the client is allowed to be a Skeleton (not dead, allowed class by server, etc.) false otherwise.
 */
native bool:BeTheSkeleton_CheckRules(client);

public SharedPlugin:__pl_betheskeleton = 
{
	name = "betheskeleton",
	file = "betheskeleton.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_betheskeleton_SetNTVOptional()
{
	MarkNativeAsOptional("BeTheSkeleton_GetSkeletonStatus");
	MarkNativeAsOptional("BeTheSkeleton_SetSkeleton");
	MarkNativeAsOptional("BeTheSkeleton_CheckRules");
}
#endif