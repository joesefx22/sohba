// Core enumerations for Mochi Points app
// Provides type safety for all domain concepts

/// User role within the family
enum UserRole { parent, child }

/// Quest type determining frequency and behavior
enum QuestType { daily, weekly, epic, series }

/// Quest rarity affecting XP multiplier and visual styling
enum QuestRarity { common, rare, epic, legendary }

/// Quest lifecycle status
enum QuestStatus { available, inProgress, pendingApproval, completed, expired }

/// Category of purchasable rewards
enum RewardCategory { experience, item, privilege, custom }

/// Status of a reward purchase
enum PurchaseStatus { purchased, pendingRedemption, redeemed, expired, cancelled }

/// Type of point transaction
enum TransactionType { questComplete, purchase, bonus, adjustment, refund }

/// Achievement tier levels
enum AchievementTier { bronze, silver, gold, platinum }

/// Achievement category for grouping
enum AchievementCategory { streak, quests, points, special }
