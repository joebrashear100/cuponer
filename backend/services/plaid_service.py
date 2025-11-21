"""
Plaid integration service for FURG
Handles bank connections, transaction syncing, and account management
"""

import os
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.accounts_get_request import AccountsGetRequest
from plaid.model.item_get_request import ItemGetRequest
from plaid.model.institutions_get_by_id_request import InstitutionsGetByIdRequest
from fastapi import HTTPException

from database import db


# Plaid configuration
PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET = os.getenv("PLAID_SECRET")
PLAID_ENV = os.getenv("PLAID_ENV", "sandbox")  # sandbox, development, production

# Map environment to Plaid host
ENV_MAP = {
    "sandbox": plaid.Environment.Sandbox,
    "development": plaid.Environment.Development,
    "production": plaid.Environment.Production,
}

# Configure Plaid client
configuration = plaid.Configuration(
    host=ENV_MAP.get(PLAID_ENV, plaid.Environment.Sandbox),
    api_key={
        "clientId": PLAID_CLIENT_ID,
        "secret": PLAID_SECRET,
    }
)

api_client = plaid.ApiClient(configuration)
client = plaid_api.PlaidApi(api_client)


class PlaidService:
    """Service for Plaid operations"""

    @staticmethod
    async def create_link_token(user_id: str) -> str:
        """
        Create a Plaid Link token for user to connect bank

        Args:
            user_id: User UUID

        Returns:
            Link token string
        """
        try:
            request = LinkTokenCreateRequest(
                user=LinkTokenCreateRequestUser(client_user_id=user_id),
                client_name="Furg - Your Roasting Financial AI",
                products=[Products("transactions")],
                country_codes=[CountryCode("US")],
                language="en",
                webhook="https://api.furg.app/webhooks/plaid",  # Update with actual webhook URL
            )

            response = client.link_token_create(request)
            return response["link_token"]

        except plaid.ApiException as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create Plaid link token: {e}"
            )

    @staticmethod
    async def exchange_public_token(user_id: str, public_token: str) -> Dict[str, Any]:
        """
        Exchange public token for access token after user links bank

        Args:
            user_id: User UUID
            public_token: Public token from Plaid Link

        Returns:
            Dict with item_id and institution info
        """
        try:
            # Exchange token
            exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
            exchange_response = client.item_public_token_exchange(exchange_request)

            access_token = exchange_response["access_token"]
            item_id = exchange_response["item_id"]

            # Get item details
            item_request = ItemGetRequest(access_token=access_token)
            item_response = client.item_get(item_request)
            institution_id = item_response["item"]["institution_id"]

            # Get institution name
            institution_request = InstitutionsGetByIdRequest(
                institution_id=institution_id,
                country_codes=[CountryCode("US")]
            )
            institution_response = client.institutions_get_by_id(institution_request)
            institution_name = institution_response["institution"]["name"]

            # Save to database
            await db.save_plaid_item(
                user_id=user_id,
                plaid_item_id=item_id,
                access_token=access_token,
                institution_name=institution_name,
                institution_id=institution_id
            )

            return {
                "item_id": item_id,
                "institution_name": institution_name,
                "institution_id": institution_id
            }

        except plaid.ApiException as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to exchange token: {e}"
            )

    @staticmethod
    async def sync_transactions(user_id: str, item_id: str) -> Dict[str, Any]:
        """
        Sync transactions for a Plaid item using Transactions Sync API

        Args:
            user_id: User UUID
            item_id: Plaid item ID

        Returns:
            Dict with sync results
        """
        try:
            # Get Plaid item from database
            plaid_item = await db.get_plaid_item(user_id, item_id)
            if not plaid_item:
                raise HTTPException(404, "Plaid item not found")

            access_token = plaid_item["plaid_access_token"]

            # Use Transactions Get for initial sync
            # In production, use Transactions Sync for incremental updates
            start_date = (datetime.now() - timedelta(days=90)).date()
            end_date = datetime.now().date()

            request = TransactionsGetRequest(
                access_token=access_token,
                start_date=start_date,
                end_date=end_date
            )

            response = client.transactions_get(request)
            transactions = response["transactions"]

            # Process and save transactions
            saved_count = 0
            for txn in transactions:
                # Convert Plaid transaction to our format
                transaction_data = {
                    "plaid_transaction_id": txn["transaction_id"],
                    "date": datetime.strptime(txn["date"], "%Y-%m-%d"),
                    "amount": float(txn["amount"]) * -1,  # Plaid uses positive for debit
                    "merchant": txn["name"],
                    "merchant_category_code": txn.get("personal_finance_category", {}).get("primary", ""),
                    "category": None,  # Will be categorized by ML
                    "is_recurring": txn.get("transaction_type") == "recurring",
                }

                # Save transaction
                await db.save_transaction(user_id, transaction_data)
                saved_count += 1

            # Update sync time
            await db.update_plaid_sync_time(item_id)

            return {
                "synced": saved_count,
                "total_transactions": len(transactions),
                "start_date": str(start_date),
                "end_date": str(end_date)
            }

        except plaid.ApiException as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to sync transactions: {e}"
            )

    @staticmethod
    async def get_accounts(user_id: str, item_id: str) -> List[Dict[str, Any]]:
        """
        Get account information for a Plaid item

        Args:
            user_id: User UUID
            item_id: Plaid item ID

        Returns:
            List of account dicts
        """
        try:
            plaid_item = await db.get_plaid_item(user_id, item_id)
            if not plaid_item:
                raise HTTPException(404, "Plaid item not found")

            request = AccountsGetRequest(access_token=plaid_item["plaid_access_token"])
            response = client.accounts_get(request)

            accounts = []
            for account in response["accounts"]:
                accounts.append({
                    "account_id": account["account_id"],
                    "name": account["name"],
                    "official_name": account.get("official_name"),
                    "type": account["type"],
                    "subtype": account.get("subtype"),
                    "balance": {
                        "current": account["balances"]["current"],
                        "available": account["balances"].get("available"),
                        "limit": account["balances"].get("limit"),
                    },
                    "mask": account.get("mask"),
                })

            return accounts

        except plaid.ApiException as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get accounts: {e}"
            )

    @staticmethod
    async def get_total_balance(user_id: str) -> float:
        """
        Get total balance across all connected banks

        Args:
            user_id: User UUID

        Returns:
            Total balance
        """
        plaid_items = await db.get_plaid_items(user_id)
        total = 0.0

        for item in plaid_items:
            try:
                request = AccountsGetRequest(access_token=item["plaid_access_token"])
                response = client.accounts_get(request)

                for account in response["accounts"]:
                    # Only count checking and savings accounts
                    if account["type"] in ["depository"]:
                        current_balance = account["balances"].get("current", 0)
                        if current_balance:
                            total += float(current_balance)

            except plaid.ApiException as e:
                print(f"Warning: Failed to get balance for item {item['plaid_item_id']}: {e}")
                continue

        return total

    @staticmethod
    async def sync_all_banks(user_id: str) -> Dict[str, Any]:
        """
        Sync transactions from all connected banks

        Args:
            user_id: User UUID

        Returns:
            Dict with sync results
        """
        plaid_items = await db.get_plaid_items(user_id)

        results = {
            "total_synced": 0,
            "banks_synced": 0,
            "errors": []
        }

        for item in plaid_items:
            try:
                result = await PlaidService.sync_transactions(
                    user_id,
                    item["plaid_item_id"]
                )
                results["total_synced"] += result["synced"]
                results["banks_synced"] += 1
            except Exception as e:
                results["errors"].append({
                    "bank": item["institution_name"],
                    "error": str(e)
                })

        return results

    @staticmethod
    async def remove_bank(user_id: str, item_id: str) -> bool:
        """
        Remove a connected bank

        Args:
            user_id: User UUID
            item_id: Plaid item ID

        Returns:
            True if successful
        """
        plaid_item = await db.get_plaid_item(user_id, item_id)
        if not plaid_item:
            raise HTTPException(404, "Plaid item not found")

        # Update status in database (don't delete for audit trail)
        async with db.acquire() as conn:
            await conn.execute(
                "UPDATE plaid_items SET status = 'disconnected' WHERE plaid_item_id = $1",
                item_id
            )

        return True

    @staticmethod
    def categorize_plaid_category(plaid_category: str) -> str:
        """
        Map Plaid's category to our simplified categories

        Args:
            plaid_category: Plaid personal_finance_category

        Returns:
            Simplified category
        """
        category_map = {
            "FOOD_AND_DRINK": "Food",
            "TRANSPORTATION": "Transport",
            "ENTERTAINMENT": "Entertainment",
            "GENERAL_MERCHANDISE": "Shopping",
            "HOME_IMPROVEMENT": "Shopping",
            "MEDICAL": "Health",
            "PERSONAL_CARE": "Health",
            "RENT_AND_UTILITIES": "Bills",
            "LOAN_PAYMENTS": "Bills",
            "BANK_FEES": "Bills",
            "TRANSFER": "Transfer",
            "INCOME": "Income",
        }

        # Extract primary category
        primary = plaid_category.split("_")[0] if "_" in plaid_category else plaid_category

        for key, value in category_map.items():
            if primary.startswith(key):
                return value

        return "Other"
