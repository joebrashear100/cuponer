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


# Global database instance
db = Database()


# Dependency for FastAPI endpoints
async def get_db() -> Database:
    """FastAPI dependency to get database instance"""
    if not db.pool:
        await db.connect()
    return db
