"""
Database service layer for FURG
Handles all database operations with PostgreSQL/TimescaleDB
"""

import os
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from contextlib import asynccontextmanager
import asyncpg
from asyncpg.pool import Pool
import json

# Database connection configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://frugal:warfare_ai_2024@localhost:5432/frugal_ai"
)


class Database:
    """Database service with connection pooling"""

    def __init__(self):
        self.pool: Optional[Pool] = None

    async def connect(self):
        """Initialize database connection pool"""
        if not self.pool:
            self.pool = await asyncpg.create_pool(
                DATABASE_URL,
                min_size=2,
                max_size=10,
                command_timeout=60
            )
            print("✅ Database pool created")

    async def disconnect(self):
        """Close database connection pool"""
        if self.pool:
            await self.pool.close()
            self.pool = None
            print("✅ Database pool closed")

    @asynccontextmanager
    async def acquire(self):
        """Get database connection from pool"""
        if not self.pool:
            await self.connect()

        async with self.pool.acquire() as connection:
            yield connection

    # ==================== USER OPERATIONS ====================

    async def get_or_create_user(self, apple_id: str, email: Optional[str] = None) -> Dict[str, Any]:
        """Get existing user or create new one"""
        async with self.acquire() as conn:
            # Try to get existing user
            user = await conn.fetchrow(
                "SELECT id, apple_id, email, created_at FROM users WHERE apple_id = $1",
                apple_id
            )

            if user:
                # Update last_seen
                await conn.execute(
                    "UPDATE users SET last_seen = NOW() WHERE id = $1",
                    user["id"]
                )
                return dict(user)

            # Create new user
            user = await conn.fetchrow(
                """
                INSERT INTO users (apple_id, email)
                VALUES ($1, $2)
                RETURNING id, apple_id, email, created_at
                """,
                apple_id,
                email
            )

            # Create default profile
            await conn.execute(
                """
                INSERT INTO user_profiles (user_id, intensity_mode, emergency_buffer)
                VALUES ($1, 'moderate', 500.00)
                """,
                user["id"]
            )

            return dict(user)

    async def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        async with self.acquire() as conn:
            user = await conn.fetchrow(
                "SELECT * FROM users WHERE id = $1",
                user_id
            )
            return dict(user) if user else None

    async def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile"""
        async with self.acquire() as conn:
            profile = await conn.fetchrow(
                "SELECT * FROM user_profiles WHERE user_id = $1",
                user_id
            )
            if not profile:
                return None

            # Convert to dict and parse JSONB fields
            profile_dict = dict(profile)
            if profile_dict.get("savings_goal"):
                profile_dict["savings_goal"] = json.loads(profile_dict["savings_goal"]) if isinstance(profile_dict["savings_goal"], str) else profile_dict["savings_goal"]
            if profile_dict.get("spending_preferences"):
                profile_dict["spending_preferences"] = json.loads(profile_dict["spending_preferences"]) if isinstance(profile_dict["spending_preferences"], str) else profile_dict["spending_preferences"]
            if profile_dict.get("health_metrics"):
                profile_dict["health_metrics"] = json.loads(profile_dict["health_metrics"]) if isinstance(profile_dict["health_metrics"], str) else profile_dict["health_metrics"]

            return profile_dict

    async def update_user_profile(self, user_id: str, updates: Dict[str, Any]) -> bool:
        """Update user profile fields"""
        async with self.acquire() as conn:
            # Build dynamic UPDATE query
            set_clauses = []
            values = [user_id]
            param_count = 2

            for key, value in updates.items():
                if key in ["savings_goal", "spending_preferences", "health_metrics"]:
                    # JSONB fields
                    set_clauses.append(f"{key} = ${param_count}::jsonb")
                    values.append(json.dumps(value))
                elif key in ["learned_insights"]:
                    # Array fields
                    set_clauses.append(f"{key} = ${param_count}::text[]")
                    values.append(value)
                else:
                    set_clauses.append(f"{key} = ${param_count}")
                    values.append(value)
                param_count += 1

            if not set_clauses:
                return False

            query = f"""
                UPDATE user_profiles
                SET {', '.join(set_clauses)}, updated_at = NOW()
                WHERE user_id = $1
            """

            result = await conn.execute(query, *values)
            return result != "UPDATE 0"

    # ==================== CONVERSATION OPERATIONS ====================

    async def save_message(self, user_id: str, role: str, content: str, metadata: Optional[Dict] = None):
        """Save a conversation message"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO conversations (user_id, role, content, metadata)
                VALUES ($1, $2, $3, $4)
                """,
                user_id,
                role,
                content,
                json.dumps(metadata) if metadata else None
            )

    async def get_conversation_history(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """Get conversation history for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT role, content, metadata, created_at
                FROM conversations
                WHERE user_id = $1
                ORDER BY created_at DESC
                LIMIT $2 OFFSET $3
                """,
                user_id,
                limit,
                offset
            )

            # Return in chronological order (oldest first)
            return [dict(row) for row in reversed(rows)]

    async def clear_conversation_history(self, user_id: str):
        """Clear all conversation history for user"""
        async with self.acquire() as conn:
            await conn.execute(
                "DELETE FROM conversations WHERE user_id = $1",
                user_id
            )

    # ==================== TRANSACTION OPERATIONS ====================

    async def save_transaction(self, user_id: str, transaction: Dict[str, Any]) -> str:
        """Save a transaction"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO transactions (
                    user_id, date, amount, merchant, merchant_category_code,
                    category, plaid_transaction_id, financekit_transaction_id,
                    notes, is_bill, is_recurring, location_lat, location_lon
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
                ON CONFLICT (id, date) DO UPDATE
                SET category = EXCLUDED.category,
                    notes = EXCLUDED.notes,
                    is_bill = EXCLUDED.is_bill
                RETURNING id
                """,
                user_id,
                transaction.get("date", datetime.now()),
                transaction["amount"],
                transaction["merchant"],
                transaction.get("merchant_category_code"),
                transaction.get("category"),
                transaction.get("plaid_transaction_id"),
                transaction.get("financekit_transaction_id"),
                transaction.get("notes"),
                transaction.get("is_bill", False),
                transaction.get("is_recurring", False),
                transaction.get("location_lat"),
                transaction.get("location_lon")
            )
            return str(result["id"])

    async def get_transactions(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Get transactions for user"""
        async with self.acquire() as conn:
            if not start_date:
                start_date = datetime.now() - timedelta(days=90)
            if not end_date:
                end_date = datetime.now()

            rows = await conn.fetch(
                """
                SELECT *
                FROM transactions
                WHERE user_id = $1 AND date >= $2 AND date <= $3
                ORDER BY date DESC
                LIMIT $4
                """,
                user_id,
                start_date,
                end_date,
                limit
            )

            return [dict(row) for row in rows]

    async def get_transaction_by_id(self, transaction_id: str) -> Optional[Dict[str, Any]]:
        """Get single transaction by ID"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM transactions WHERE id = $1",
                transaction_id
            )
            return dict(row) if row else None

    async def update_transaction_category(self, transaction_id: str, category: str):
        """Update transaction category"""
        async with self.acquire() as conn:
            await conn.execute(
                "UPDATE transactions SET category = $1 WHERE id = $2",
                category,
                transaction_id
            )

    async def get_spending_by_category(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime
    ) -> Dict[str, float]:
        """Get spending totals by category"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT category, SUM(ABS(amount)) as total
                FROM transactions
                WHERE user_id = $1 AND date >= $2 AND date <= $3
                AND amount < 0
                GROUP BY category
                """,
                user_id,
                start_date,
                end_date
            )

            return {row["category"]: float(row["total"]) for row in rows if row["category"]}

    # ==================== BILL OPERATIONS ====================

    async def upsert_bill(self, user_id: str, bill: Dict[str, Any]) -> str:
        """Insert or update a bill"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO bills (
                    user_id, merchant, amount, frequency_days,
                    next_due_date, confidence, category
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT ON CONSTRAINT bills_pkey
                DO UPDATE SET
                    amount = EXCLUDED.amount,
                    frequency_days = EXCLUDED.frequency_days,
                    next_due_date = EXCLUDED.next_due_date,
                    confidence = EXCLUDED.confidence,
                    updated_at = NOW()
                RETURNING id
                """,
                user_id,
                bill["merchant"],
                bill["amount"],
                bill["frequency_days"],
                bill["next_due_date"],
                bill["confidence"],
                bill.get("category")
            )
            return str(result["id"])

    async def get_active_bills(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all active bills for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM bills
                WHERE user_id = $1 AND is_active = TRUE
                ORDER BY next_due_date
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def get_upcoming_bills(self, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
        """Get bills due in next N days"""
        async with self.acquire() as conn:
            cutoff = datetime.now() + timedelta(days=days)
            rows = await conn.fetch(
                """
                SELECT * FROM bills
                WHERE user_id = $1 AND is_active = TRUE
                AND next_due_date <= $2
                ORDER BY next_due_date
                """,
                user_id,
                cutoff.date()
            )
            return [dict(row) for row in rows]

    async def calculate_upcoming_bills_total(self, user_id: str, days: int = 30) -> float:
        """Calculate total of upcoming bills"""
        async with self.acquire() as conn:
            result = await conn.fetchval(
                "SELECT calculate_upcoming_bills($1, $2)",
                user_id,
                days
            )
            return float(result) if result else 0.0

    # ==================== SHADOW ACCOUNT OPERATIONS ====================

    async def create_shadow_account(
        self,
        user_id: str,
        balance: float,
        purpose: str
    ) -> str:
        """Create a shadow account"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO shadow_accounts (user_id, balance, purpose, last_hidden_at)
                VALUES ($1, $2, $3, NOW())
                RETURNING id
                """,
                user_id,
                balance,
                purpose
            )
            return str(result["id"])

    async def get_shadow_accounts(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all shadow accounts for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM shadow_accounts WHERE user_id = $1",
                user_id
            )
            return [dict(row) for row in rows]

    async def get_total_hidden(self, user_id: str) -> float:
        """Get total hidden balance"""
        async with self.acquire() as conn:
            result = await conn.fetchval(
                "SELECT COALESCE(SUM(balance), 0) FROM shadow_accounts WHERE user_id = $1",
                user_id
            )
            return float(result)

    async def update_shadow_balance(self, account_id: str, new_balance: float):
        """Update shadow account balance"""
        async with self.acquire() as conn:
            await conn.execute(
                "UPDATE shadow_accounts SET balance = $1 WHERE id = $2",
                new_balance,
                account_id
            )

    # ==================== PLAID OPERATIONS ====================

    async def save_plaid_item(
        self,
        user_id: str,
        plaid_item_id: str,
        access_token: str,
        institution_name: str,
        institution_id: str
    ) -> str:
        """Save Plaid item"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO plaid_items (
                    user_id, plaid_item_id, plaid_access_token,
                    institution_name, institution_id
                )
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (plaid_item_id) DO UPDATE
                SET plaid_access_token = EXCLUDED.plaid_access_token,
                    status = 'active'
                RETURNING id
                """,
                user_id,
                plaid_item_id,
                access_token,
                institution_name,
                institution_id
            )
            return str(result["id"])

    async def get_plaid_items(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all Plaid items for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM plaid_items
                WHERE user_id = $1 AND status = 'active'
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def get_plaid_item(self, user_id: str, item_id: str) -> Optional[Dict[str, Any]]:
        """Get specific Plaid item"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT * FROM plaid_items
                WHERE user_id = $1 AND plaid_item_id = $2
                """,
                user_id,
                item_id
            )
            return dict(row) if row else None

    async def update_plaid_sync_time(self, item_id: str):
        """Update last sync time for Plaid item"""
        async with self.acquire() as conn:
            await conn.execute(
                "UPDATE plaid_items SET last_synced = NOW() WHERE plaid_item_id = $1",
                item_id
            )

    # ==================== API USAGE TRACKING ====================

    async def log_api_usage(
        self,
        user_id: str,
        endpoint: str,
        input_tokens: int,
        output_tokens: int,
        cost: float
    ):
        """Log API usage for cost tracking"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO api_usage (user_id, endpoint, input_tokens, output_tokens, cost)
                VALUES ($1, $2, $3, $4, $5)
                """,
                user_id,
                endpoint,
                input_tokens,
                output_tokens,
                cost
            )

    async def get_user_api_usage_today(self, user_id: str) -> Dict[str, Any]:
        """Get user's API usage for today"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT
                    COUNT(*) as requests,
                    COALESCE(SUM(input_tokens), 0) as input_tokens,
                    COALESCE(SUM(output_tokens), 0) as output_tokens,
                    COALESCE(SUM(cost), 0) as total_cost
                FROM api_usage
                WHERE user_id = $1
                AND created_at >= CURRENT_DATE
                """,
                user_id
            )
            return dict(row) if row else {"requests": 0, "input_tokens": 0, "output_tokens": 0, "total_cost": 0}

    # ==================== TRAINING EXAMPLES ====================

    async def save_training_example(
        self,
        user_id: str,
        transaction_data: Dict[str, Any],
        correct_category: str
    ):
        """Save training example for ML model"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO training_examples (user_id, transaction_data, correct_category)
                VALUES ($1, $2, $3)
                """,
                user_id,
                json.dumps(transaction_data),
                correct_category
            )

    async def get_training_examples(self, limit: int = 1000) -> List[Dict[str, Any]]:
        """Get training examples for model training"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT transaction_data, correct_category
                FROM training_examples
                ORDER BY created_at DESC
                LIMIT $1
                """,
                limit
            )
            return [
                {
                    "transaction": json.loads(row["transaction_data"]) if isinstance(row["transaction_data"], str) else row["transaction_data"],
                    "category": row["correct_category"]
                }
                for row in rows
            ]

    async def get_training_example_count(self) -> int:
        """Get total count of training examples"""
        async with self.acquire() as conn:
            count = await conn.fetchval("SELECT COUNT(*) FROM training_examples")
            return int(count)

    # ==================== DEVICE TOKENS ====================

    async def save_device_token(self, user_id: str, token: str, platform: str = "ios"):
        """Save device token for push notifications"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO device_tokens (user_id, token, platform)
                VALUES ($1, $2, $3)
                ON CONFLICT (user_id, token) DO UPDATE
                SET is_active = TRUE
                """,
                user_id,
                token,
                platform
            )

    async def get_device_tokens(self, user_id: str) -> List[str]:
        """Get active device tokens for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT token FROM device_tokens
                WHERE user_id = $1 AND is_active = TRUE
                """,
                user_id
            )
            return [row["token"] for row in rows]

    # ==================== GOALS OPERATIONS ====================

    async def create_goal(self, user_id: str, goal: Dict[str, Any]) -> str:
        """Create a savings goal"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO goals (
                    user_id, name, target_amount, current_amount, deadline,
                    icon, color, priority, is_primary
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                RETURNING id
                """,
                user_id,
                goal["name"],
                goal["target_amount"],
                goal.get("current_amount", 0),
                goal.get("deadline"),
                goal.get("icon", "flag.fill"),
                goal.get("color", "#4ECDC4"),
                goal.get("priority", 1),
                goal.get("is_primary", False)
            )
            return str(result["id"])

    async def get_goals(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all goals for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM goals
                WHERE user_id = $1 AND is_active = TRUE
                ORDER BY is_primary DESC, priority, deadline
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def get_goal(self, goal_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific goal"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM goals WHERE id = $1",
                goal_id
            )
            return dict(row) if row else None

    async def update_goal(self, goal_id: str, updates: Dict[str, Any]) -> bool:
        """Update a goal"""
        async with self.acquire() as conn:
            set_clauses = []
            values = [goal_id]
            param_count = 2

            for key, value in updates.items():
                set_clauses.append(f"{key} = ${param_count}")
                values.append(value)
                param_count += 1

            if not set_clauses:
                return False

            query = f"""
                UPDATE goals
                SET {', '.join(set_clauses)}, updated_at = NOW()
                WHERE id = $1
            """
            result = await conn.execute(query, *values)
            return result != "UPDATE 0"

    async def add_to_goal(self, goal_id: str, amount: float) -> float:
        """Add amount to a goal and return new total"""
        async with self.acquire() as conn:
            result = await conn.fetchval(
                """
                UPDATE goals
                SET current_amount = current_amount + $1, updated_at = NOW()
                WHERE id = $2
                RETURNING current_amount
                """,
                amount,
                goal_id
            )
            return float(result) if result else 0.0

    async def delete_goal(self, goal_id: str) -> bool:
        """Soft delete a goal"""
        async with self.acquire() as conn:
            result = await conn.execute(
                "UPDATE goals SET is_active = FALSE WHERE id = $1",
                goal_id
            )
            return result != "UPDATE 0"

    # ==================== SUBSCRIPTION OPERATIONS ====================

    async def create_subscription(self, user_id: str, sub: Dict[str, Any]) -> str:
        """Create a tracked subscription"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO subscriptions (
                    user_id, name, amount, billing_cycle, next_billing_date,
                    category, icon, color, importance, auto_detected
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                RETURNING id
                """,
                user_id,
                sub["name"],
                sub["amount"],
                sub.get("billing_cycle", "monthly"),
                sub.get("next_billing_date"),
                sub.get("category", "entertainment"),
                sub.get("icon", "creditcard.fill"),
                sub.get("color", "#9B59B6"),
                sub.get("importance", "nice_to_have"),
                sub.get("auto_detected", False)
            )
            return str(result["id"])

    async def get_subscriptions(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all active subscriptions for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM subscriptions
                WHERE user_id = $1 AND is_active = TRUE
                ORDER BY next_billing_date
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def update_subscription(self, sub_id: str, updates: Dict[str, Any]) -> bool:
        """Update a subscription"""
        async with self.acquire() as conn:
            set_clauses = []
            values = [sub_id]
            param_count = 2

            for key, value in updates.items():
                set_clauses.append(f"{key} = ${param_count}")
                values.append(value)
                param_count += 1

            if not set_clauses:
                return False

            query = f"""
                UPDATE subscriptions
                SET {', '.join(set_clauses)}, updated_at = NOW()
                WHERE id = $1
            """
            result = await conn.execute(query, *values)
            return result != "UPDATE 0"

    async def cancel_subscription(self, sub_id: str) -> bool:
        """Cancel/deactivate a subscription"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE subscriptions
                SET is_active = FALSE, cancelled_at = NOW()
                WHERE id = $1
                """,
                sub_id
            )
            return result != "UPDATE 0"

    async def get_subscription_total(self, user_id: str) -> Dict[str, float]:
        """Get total subscription costs by period"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT billing_cycle, SUM(amount) as total
                FROM subscriptions
                WHERE user_id = $1 AND is_active = TRUE
                GROUP BY billing_cycle
                """,
                user_id
            )

            result = {"monthly": 0.0, "yearly": 0.0, "weekly": 0.0}
            for row in rows:
                result[row["billing_cycle"]] = float(row["total"])

            # Calculate monthly equivalent
            result["monthly_equivalent"] = (
                result["monthly"] +
                (result["yearly"] / 12) +
                (result["weekly"] * 4.33)
            )
            return result

    # ==================== ROUND-UP OPERATIONS ====================

    async def get_roundup_config(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get round-up configuration for user"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM roundup_config WHERE user_id = $1",
                user_id
            )
            return dict(row) if row else None

    async def upsert_roundup_config(self, user_id: str, config: Dict[str, Any]) -> bool:
        """Create or update round-up config"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO roundup_config (
                    user_id, is_enabled, round_up_amount, multiplier,
                    linked_goal_id, transfer_frequency, min_transfer_amount
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT (user_id) DO UPDATE
                SET is_enabled = EXCLUDED.is_enabled,
                    round_up_amount = EXCLUDED.round_up_amount,
                    multiplier = EXCLUDED.multiplier,
                    linked_goal_id = EXCLUDED.linked_goal_id,
                    transfer_frequency = EXCLUDED.transfer_frequency,
                    min_transfer_amount = EXCLUDED.min_transfer_amount,
                    updated_at = NOW()
                """,
                user_id,
                config.get("is_enabled", False),
                config.get("round_up_amount", "nearest_dollar"),
                config.get("multiplier", 1),
                config.get("linked_goal_id"),
                config.get("transfer_frequency", "weekly"),
                config.get("min_transfer_amount", 5.0)
            )
            return True

    async def save_roundup_transaction(self, user_id: str, txn: Dict[str, Any]) -> str:
        """Save a round-up transaction"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO roundup_transactions (
                    user_id, original_transaction_id, original_amount,
                    roundup_amount, multiplied_amount, goal_id
                )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING id
                """,
                user_id,
                txn.get("original_transaction_id"),
                txn["original_amount"],
                txn["roundup_amount"],
                txn.get("multiplied_amount", txn["roundup_amount"]),
                txn.get("goal_id")
            )
            return str(result["id"])

    async def get_pending_roundups(self, user_id: str) -> List[Dict[str, Any]]:
        """Get pending round-up transactions"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM roundup_transactions
                WHERE user_id = $1 AND status = 'pending'
                ORDER BY created_at
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def get_roundup_summary(self, user_id: str) -> Dict[str, Any]:
        """Get round-up summary statistics"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT
                    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
                    COALESCE(SUM(multiplied_amount) FILTER (WHERE status = 'pending'), 0) as pending_total,
                    COALESCE(SUM(multiplied_amount) FILTER (WHERE status = 'transferred'), 0) as total_transferred,
                    COUNT(*) FILTER (WHERE status = 'transferred') as transfer_count
                FROM roundup_transactions
                WHERE user_id = $1
                """,
                user_id
            )
            return {
                "pending_count": row["pending_count"],
                "pending_total": float(row["pending_total"]),
                "total_transferred": float(row["total_transferred"]),
                "transfer_count": row["transfer_count"]
            }

    async def transfer_roundups(self, user_id: str, goal_id: str) -> float:
        """Transfer pending round-ups to a goal"""
        async with self.acquire() as conn:
            async with conn.transaction():
                # Get pending total
                total = await conn.fetchval(
                    """
                    SELECT COALESCE(SUM(multiplied_amount), 0)
                    FROM roundup_transactions
                    WHERE user_id = $1 AND status = 'pending'
                    """,
                    user_id
                )

                if float(total) > 0:
                    # Update round-ups to transferred
                    await conn.execute(
                        """
                        UPDATE roundup_transactions
                        SET status = 'transferred', transferred_at = NOW()
                        WHERE user_id = $1 AND status = 'pending'
                        """,
                        user_id
                    )

                    # Add to goal
                    await conn.execute(
                        """
                        UPDATE goals
                        SET current_amount = current_amount + $1, updated_at = NOW()
                        WHERE id = $2
                        """,
                        float(total),
                        goal_id
                    )

                return float(total)

    # ==================== SPENDING LIMITS OPERATIONS ====================

    async def create_spending_limit(self, user_id: str, limit: Dict[str, Any]) -> str:
        """Create a spending limit"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO spending_limits (
                    user_id, category, limit_amount, period, warning_threshold
                )
                VALUES ($1, $2, $3, $4, $5)
                RETURNING id
                """,
                user_id,
                limit["category"],
                limit["limit_amount"],
                limit.get("period", "monthly"),
                limit.get("warning_threshold", 0.8)
            )
            return str(result["id"])

    async def get_spending_limits(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all spending limits for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM spending_limits
                WHERE user_id = $1 AND is_active = TRUE
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def check_spending_limit(
        self,
        user_id: str,
        category: str,
        period_start: datetime
    ) -> Optional[Dict[str, Any]]:
        """Check spending against limit for a category"""
        async with self.acquire() as conn:
            # Get the limit
            limit = await conn.fetchrow(
                """
                SELECT * FROM spending_limits
                WHERE user_id = $1 AND category = $2 AND is_active = TRUE
                """,
                user_id,
                category
            )

            if not limit:
                return None

            # Get current spending
            spent = await conn.fetchval(
                """
                SELECT COALESCE(SUM(ABS(amount)), 0)
                FROM transactions
                WHERE user_id = $1 AND category = $2 AND date >= $3 AND amount < 0
                """,
                user_id,
                category,
                period_start
            )

            limit_dict = dict(limit)
            limit_dict["current_spent"] = float(spent)
            limit_dict["remaining"] = float(limit["limit_amount"]) - float(spent)
            limit_dict["percentage_used"] = float(spent) / float(limit["limit_amount"]) if float(limit["limit_amount"]) > 0 else 0

            return limit_dict

    async def update_spending_limit(self, limit_id: str, updates: Dict[str, Any]) -> bool:
        """Update a spending limit"""
        async with self.acquire() as conn:
            set_clauses = []
            values = [limit_id]
            param_count = 2

            for key, value in updates.items():
                set_clauses.append(f"{key} = ${param_count}")
                values.append(value)
                param_count += 1

            if not set_clauses:
                return False

            query = f"""
                UPDATE spending_limits
                SET {', '.join(set_clauses)}
                WHERE id = $1
            """
            result = await conn.execute(query, *values)
            return result != "UPDATE 0"

    async def delete_spending_limit(self, limit_id: str) -> bool:
        """Delete a spending limit"""
        async with self.acquire() as conn:
            result = await conn.execute(
                "UPDATE spending_limits SET is_active = FALSE WHERE id = $1",
                limit_id
            )
            return result != "UPDATE 0"

    # ==================== WISHLIST OPERATIONS ====================

    async def create_wishlist_item(self, user_id: str, item: Dict[str, Any]) -> str:
        """Create a wishlist item"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO wishlist (
                    user_id, name, price, url, image_url, priority,
                    category, notes, linked_goal_id
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                RETURNING id
                """,
                user_id,
                item["name"],
                item["price"],
                item.get("url"),
                item.get("image_url"),
                item.get("priority", 1),
                item.get("category"),
                item.get("notes"),
                item.get("linked_goal_id")
            )
            return str(result["id"])

    async def get_wishlist(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all wishlist items for user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT w.*, g.name as goal_name, g.current_amount as goal_progress
                FROM wishlist w
                LEFT JOIN goals g ON w.linked_goal_id = g.id
                WHERE w.user_id = $1 AND w.is_active = TRUE
                ORDER BY w.priority, w.created_at
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def update_wishlist_item(self, item_id: str, updates: Dict[str, Any]) -> bool:
        """Update a wishlist item"""
        async with self.acquire() as conn:
            set_clauses = []
            values = [item_id]
            param_count = 2

            for key, value in updates.items():
                set_clauses.append(f"{key} = ${param_count}")
                values.append(value)
                param_count += 1

            if not set_clauses:
                return False

            query = f"""
                UPDATE wishlist
                SET {', '.join(set_clauses)}, updated_at = NOW()
                WHERE id = $1
            """
            result = await conn.execute(query, *values)
            return result != "UPDATE 0"

    async def delete_wishlist_item(self, item_id: str) -> bool:
        """Delete a wishlist item"""
        async with self.acquire() as conn:
            result = await conn.execute(
                "UPDATE wishlist SET is_active = FALSE WHERE id = $1",
                item_id
            )
            return result != "UPDATE 0"

    async def mark_wishlist_purchased(self, item_id: str) -> bool:
        """Mark a wishlist item as purchased"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE wishlist
                SET is_purchased = TRUE, purchased_at = NOW()
                WHERE id = $1
                """,
                item_id
            )
            return result != "UPDATE 0"

    # ==================== ALERTS/NOTIFICATIONS OPERATIONS ====================

    async def create_alert(self, user_id: str, alert: Dict[str, Any]) -> str:
        """Create an alert/notification"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO alerts (
                    user_id, alert_type, title, message, data, priority
                )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING id
                """,
                user_id,
                alert["alert_type"],
                alert["title"],
                alert["message"],
                json.dumps(alert.get("data", {})),
                alert.get("priority", "normal")
            )
            return str(result["id"])

    async def get_alerts(self, user_id: str, unread_only: bool = False) -> List[Dict[str, Any]]:
        """Get alerts for user"""
        async with self.acquire() as conn:
            query = """
                SELECT * FROM alerts
                WHERE user_id = $1
            """
            if unread_only:
                query += " AND is_read = FALSE"
            query += " ORDER BY created_at DESC LIMIT 50"

            rows = await conn.fetch(query, user_id)
            return [dict(row) for row in rows]

    async def mark_alert_read(self, alert_id: str) -> bool:
        """Mark an alert as read"""
        async with self.acquire() as conn:
            result = await conn.execute(
                "UPDATE alerts SET is_read = TRUE, read_at = NOW() WHERE id = $1",
                alert_id
            )
            return result != "UPDATE 0"

    async def mark_all_alerts_read(self, user_id: str) -> int:
        """Mark all alerts as read for user"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE alerts
                SET is_read = TRUE, read_at = NOW()
                WHERE user_id = $1 AND is_read = FALSE
                """,
                user_id
            )
            # Extract count from "UPDATE N"
            return int(result.split()[-1]) if result else 0


    # ==================== DEALS OPERATIONS ====================

    async def create_deals_tracked_product(self, user_id: str, product: Dict[str, Any]) -> str:
        """Create a tracked product for Deals price alerts"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO deals_tracked_products (
                    user_id, asin, title, current_price, target_price,
                    image_url, url, category
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                ON CONFLICT (user_id, asin) DO UPDATE
                SET target_price = EXCLUDED.target_price,
                    current_price = EXCLUDED.current_price,
                    updated_at = NOW()
                RETURNING id
                """,
                user_id,
                product["asin"],
                product["title"],
                product["current_price"],
                product["target_price"],
                product.get("image_url"),
                product.get("url"),
                product.get("category")
            )
            return str(result["id"])

    async def get_deals_tracked_products(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all tracked products for a user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM deals_tracked_products
                WHERE user_id = $1 AND is_active = TRUE
                ORDER BY created_at DESC
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def get_deals_tracked_product(self, user_id: str, asin: str) -> Optional[Dict[str, Any]]:
        """Get a specific tracked product"""
        async with self.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT * FROM deals_tracked_products
                WHERE user_id = $1 AND asin = $2 AND is_active = TRUE
                """,
                user_id,
                asin
            )
            return dict(row) if row else None

    async def update_deals_tracked_price(
        self,
        tracking_id: str,
        new_price: float,
        price_dropped: bool = False
    ) -> bool:
        """Update the current price for a tracked product"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE deals_tracked_products
                SET current_price = $1,
                    last_checked_price = current_price,
                    last_checked_at = NOW(),
                    price_drop_detected = $2,
                    updated_at = NOW()
                WHERE id = $3
                """,
                new_price,
                price_dropped,
                tracking_id
            )
            return result != "UPDATE 0"

    async def delete_deals_tracked_product(self, user_id: str, asin: str) -> bool:
        """Stop tracking a product"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE deals_tracked_products
                SET is_active = FALSE
                WHERE user_id = $1 AND asin = $2
                """,
                user_id,
                asin
            )
            return result != "UPDATE 0"

    async def save_deals_price_history(
        self,
        asin: str,
        price: float,
        original_price: Optional[float] = None,
        deal_badge: Optional[str] = None
    ):
        """Save a price point to history"""
        async with self.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO deals_price_history (asin, price, original_price, deal_badge)
                VALUES ($1, $2, $3, $4)
                """,
                asin,
                price,
                original_price,
                deal_badge
            )

    async def get_deals_price_history(
        self,
        asin: str,
        days: int = 30
    ) -> List[Dict[str, Any]]:
        """Get price history for a product"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT price, original_price, deal_badge, recorded_at
                FROM deals_price_history
                WHERE asin = $1 AND recorded_at >= NOW() - INTERVAL '%s days'
                ORDER BY recorded_at DESC
                """,
                asin,
                days
            )
            return [dict(row) for row in rows]

    async def save_deals_deal(self, user_id: str, deal: Dict[str, Any]) -> str:
        """Save a deal for later"""
        async with self.acquire() as conn:
            result = await conn.fetchrow(
                """
                INSERT INTO deals_saved_deals (
                    user_id, asin, title, price, original_price,
                    savings_percent, image_url, url, deal_type, expires_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                ON CONFLICT (user_id, asin) DO UPDATE
                SET price = EXCLUDED.price,
                    savings_percent = EXCLUDED.savings_percent,
                    updated_at = NOW()
                RETURNING id
                """,
                user_id,
                deal["asin"],
                deal["title"],
                deal["price"],
                deal.get("original_price"),
                deal.get("savings_percent"),
                deal.get("image_url"),
                deal.get("url"),
                deal.get("deal_type", "saved"),
                deal.get("expires_at")
            )
            return str(result["id"])

    async def get_deals_saved_deals(self, user_id: str) -> List[Dict[str, Any]]:
        """Get saved deals for a user"""
        async with self.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT * FROM deals_saved_deals
                WHERE user_id = $1 AND is_active = TRUE
                ORDER BY created_at DESC
                """,
                user_id
            )
            return [dict(row) for row in rows]

    async def delete_deals_saved_deal(self, user_id: str, asin: str) -> bool:
        """Remove a saved deal"""
        async with self.acquire() as conn:
            result = await conn.execute(
                """
                UPDATE deals_saved_deals
                SET is_active = FALSE
                WHERE user_id = $1 AND asin = $2
                """,
                user_id,
                asin
            )
            return result != "UPDATE 0"

    async def get_deals_stats(self, user_id: str) -> Dict[str, Any]:
        """Get Deals usage statistics for a user"""
        async with self.acquire() as conn:
            # Get tracking stats
            tracking_stats = await conn.fetchrow(
                """
                SELECT
                    COUNT(*) as total_tracked,
                    COUNT(*) FILTER (WHERE price_drop_detected = TRUE) as price_drops_found,
                    COALESCE(SUM(current_price - target_price) FILTER (WHERE current_price <= target_price), 0) as potential_savings
                FROM deals_tracked_products
                WHERE user_id = $1 AND is_active = TRUE
                """,
                user_id
            )

            # Get saved deals stats
            deals_stats = await conn.fetchrow(
                """
                SELECT
                    COUNT(*) as saved_deals,
                    COALESCE(SUM(original_price - price) FILTER (WHERE original_price IS NOT NULL), 0) as total_savings_available
                FROM deals_saved_deals
                WHERE user_id = $1 AND is_active = TRUE
                """,
                user_id
            )

            return {
                "products_tracked": tracking_stats["total_tracked"] if tracking_stats else 0,
                "price_drops_found": tracking_stats["price_drops_found"] if tracking_stats else 0,
                "potential_savings": float(tracking_stats["potential_savings"]) if tracking_stats else 0,
                "saved_deals": deals_stats["saved_deals"] if deals_stats else 0,
                "total_savings_available": float(deals_stats["total_savings_available"]) if deals_stats else 0
            }


# Global database instance
db = Database()


# Dependency for FastAPI endpoints
async def get_db() -> Database:
    """FastAPI dependency to get database instance"""
    if not db.pool:
        await db.connect()
    return db
