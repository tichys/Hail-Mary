// Roleplay System Constants for Big Iron: Hail Mary
// Centralizes all magic numbers for consistency and easy tuning

// ============ KARMA SYSTEM ============
// Note: Main karma constants are in karma.dm for proximity to the code that uses them
// These are additional karma-related constants

#define KARMA_FEEDBACK_MIN 5			// Minimum karma change to show feedback
#define KARMA_HISTORY_DISPLAY_LIMIT 50	// Max entries to show in karma history

// ============ REPUTATION SYSTEM ============
// Note: Main reputation thresholds are in faction_definitions.dm
// These are additional reputation-related constants

#define REP_MIN -100					// Minimum possible reputation
#define REP_MAX 250						// Maximum possible reputation (higher for special rewards)
#define REP_CHANGE_MAX 25				// Maximum reputation change per action

// ============ BOUNTY SYSTEM ============
// Bounty thresholds (already defined in bounty_system.dm, listed here for reference)
// #define BOUNTY_THRESHOLD_VILLAIN -500
// #define BOUNTY_THRESHOLD_INFAMOUS -750
// #define BOUNTY_AMOUNT_VILLAIN 500

#define BOUNTY_CAPS_STACK_MAX 50		// Maximum caps per stack when collecting bounty
#define BOUNTY_HUNTER_SPAWN_MIN 1		// Minimum bounty hunters to spawn
#define BOUNTY_HUNTER_SPAWN_MAX 3		// Maximum bounty hunters to spawn
#define BOUNTY_HUNTER_DURATION 600		// How long bounty hunters pursue (10 minutes)

// ============ TRADE SYSTEM ============
#define TRADE_MAX_DISTANCE 3			// Maximum tiles between traders
#define TRADE_REQUEST_TIMEOUT 300		// Trade request expires after 30 seconds
#define TRADE_Z_LEVEL_CHECK TRUE		// Whether traders must be on same Z-level

// ============ COMPANION SYSTEM ============
#define COMPANION_HIRE_BASE_COST 500	// Base cost for hiring companions
#define COMPANION_FOLLOW_DISTANCE 2		// Distance companion tries to maintain
#define COMPANION_MAX_ACTIVE 2			// Maximum active companions per player

// ============ DIALOGUE SYSTEM ============
#define DIALOGUE_DEFAULT_RANGE 3		// Default range for auto-dialogue trigger
#define DIALOGUE_COOLDOWN_DEFAULT 300	// Default cooldown between dialogue triggers
#define DIALOGUE_UI_WIDTH 600			// Dialogue UI window width
#define DIALOGUE_UI_HEIGHT 450			// Dialogue UI window height

// ============ QUEST SYSTEM ============
#define QUEST_MAX_ACTIVE 5				// Maximum active quests per player
#define QUEST_DEFAULT_TIME_LIMIT 0		// Default time limit (0 = no limit)
#define QUEST_TRACKING_RANGE 50			// Range for objective tracking

// ============ NPC MEMORY SYSTEM ============
#define NPC_MEMORY_MAX_PER_PLAYER 100	// Maximum memories stored per player per NPC
#define NPC_MEMORY_DECAY_DAYS 30		// Days before old memories are cleaned up

// ============ NPC BARK SYSTEM ============
#define BARK_DEFAULT_CHANCE 5			// Default chance per tick to bark (1-100)
#define BARK_DEFAULT_COOLDOWN 600		// Default cooldown between barks (60 seconds)
#define BARK_DEFAULT_RANGE 7			// Default range for barks to be heard

// ============ LEVEL/XP SYSTEM ============
#define XP_LEVEL_CAP 50					// Maximum player level
#define XP_SPECIAL_BONUS_PER_LEVEL 1	// SPECIAL points per level

// ============ CAPS SYSTEM ============
#define CAPS_STARTING_DEFAULT 50		// Default starting caps for new characters
#define CAPS_MAX_IN_WALLET 10000		// Maximum caps that can be carried

// ============ PERK SYSTEM ============
#define PERK_POINTS_PER_LEVEL 1			// Perk points gained per level
#define PERK_MAX_TOTAL 30				// Maximum total perk points (soft cap)

// ============ DATABASE TABLES ============
#define DB_TABLE_KARMA "player_karma"
#define DB_TABLE_REPUTATION "player_reputation"
#define DB_TABLE_LEVELS "player_levels"
#define DB_TABLE_QUESTS "player_quests"
#define DB_TABLE_MEMORY "npc_memory"
#define DB_TABLE_KARMA_HISTORY "karma_history"
#define DB_TABLE_PERKS "player_perks"

// ============ UI CONSTANTS ============
#define UI_TRADE_WIDTH 700
#define UI_TRADE_HEIGHT 600
#define UI_BOUNTY_WIDTH 600
#define UI_BOUNTY_HEIGHT 500
#define UI_QUEST_WIDTH 500
#define UI_QUEST_HEIGHT 400
