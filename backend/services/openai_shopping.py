"""
OpenAI Shopping Assistant Service
Provides ChatGPT-style shopping mode with function calling for product search,
deal discovery, price comparison, and smart recommendations.
"""

import os
import json
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from openai import AsyncOpenAI

from database import db
from rate_limiter import APIUsageTracker


# Initialize OpenAI client
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))


# Shopping function definitions for function calling
SHOPPING_FUNCTIONS = [
    {
        "name": "search_products",
        "description": "Search for products by name, category, or description. Returns matching products with prices and availability.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query (product name, brand, or category)"
                },
                "category": {
                    "type": "string",
                    "description": "Product category filter (e.g., 'electronics', 'clothing', 'grocery')",
                    "enum": ["electronics", "clothing", "grocery", "home", "beauty", "sports", "toys", "automotive", "health", "office"]
                },
                "max_price": {
                    "type": "number",
                    "description": "Maximum price filter"
                },
                "min_price": {
                    "type": "number",
                    "description": "Minimum price filter"
                },
                "sort_by": {
                    "type": "string",
                    "description": "Sort results by",
                    "enum": ["price_low", "price_high", "rating", "relevance", "popularity"]
                },
                "limit": {
                    "type": "integer",
                    "description": "Maximum number of results (default 10)",
                    "default": 10
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "find_deals",
        "description": "Find active deals, coupons, and discounts for products or categories",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Product or category to find deals for"
                },
                "retailer": {
                    "type": "string",
                    "description": "Specific retailer to search (e.g., 'Amazon', 'Target', 'Walmart')"
                },
                "discount_type": {
                    "type": "string",
                    "description": "Type of discount",
                    "enum": ["percent_off", "dollar_off", "bogo", "free_shipping", "cashback"]
                },
                "min_discount": {
                    "type": "number",
                    "description": "Minimum discount percentage"
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "compare_prices",
        "description": "Compare prices for a product across multiple retailers",
        "parameters": {
            "type": "object",
            "properties": {
                "product_name": {
                    "type": "string",
                    "description": "Name of the product to compare"
                },
                "include_used": {
                    "type": "boolean",
                    "description": "Include used/refurbished options",
                    "default": False
                }
            },
            "required": ["product_name"]
        }
    },
    {
        "name": "add_to_shopping_list",
        "description": "Add an item to the user's shopping list",
        "parameters": {
            "type": "object",
            "properties": {
                "item_name": {
                    "type": "string",
                    "description": "Name of the item to add"
                },
                "quantity": {
                    "type": "integer",
                    "description": "Quantity to add",
                    "default": 1
                },
                "category": {
                    "type": "string",
                    "description": "Category of the item"
                },
                "target_price": {
                    "type": "number",
                    "description": "Target price to watch for"
                },
                "preferred_store": {
                    "type": "string",
                    "description": "Preferred store to buy from"
                },
                "notes": {
                    "type": "string",
                    "description": "Additional notes"
                }
            },
            "required": ["item_name"]
        }
    },
    {
        "name": "create_price_alert",
        "description": "Create a price alert to notify when a product drops to a target price",
        "parameters": {
            "type": "object",
            "properties": {
                "product_name": {
                    "type": "string",
                    "description": "Name of the product to track"
                },
                "target_price": {
                    "type": "number",
                    "description": "Target price to alert at"
                }
            },
            "required": ["product_name", "target_price"]
        }
    },
    {
        "name": "get_product_recommendations",
        "description": "Get personalized product recommendations based on user's shopping history and preferences",
        "parameters": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "Category to get recommendations for"
                },
                "budget": {
                    "type": "number",
                    "description": "Maximum budget for recommendations"
                },
                "use_case": {
                    "type": "string",
                    "description": "Intended use case (e.g., 'gift', 'daily use', 'work')"
                }
            }
        }
    },
    {
        "name": "get_shopping_list",
        "description": "Get the user's current shopping list",
        "parameters": {
            "type": "object",
            "properties": {
                "include_purchased": {
                    "type": "boolean",
                    "description": "Include already purchased items",
                    "default": False
                }
            }
        }
    },
    {
        "name": "find_best_credit_card",
        "description": "Find the best credit card to use for a purchase based on rewards",
        "parameters": {
            "type": "object",
            "properties": {
                "merchant": {
                    "type": "string",
                    "description": "Merchant name or category"
                },
                "amount": {
                    "type": "number",
                    "description": "Purchase amount"
                }
            },
            "required": ["merchant"]
        }
    },
    {
        "name": "check_loyalty_points",
        "description": "Check available loyalty points and rewards across programs",
        "parameters": {
            "type": "object",
            "properties": {
                "retailer": {
                    "type": "string",
                    "description": "Specific retailer to check (optional)"
                }
            }
        }
    },
    {
        "name": "get_reorder_suggestions",
        "description": "Get suggestions for items that may need reordering based on purchase history",
        "parameters": {
            "type": "object",
            "properties": {
                "days_ahead": {
                    "type": "integer",
                    "description": "Number of days to look ahead",
                    "default": 7
                }
            }
        }
    }
]


class ShoppingAssistant:
    """
    AI-powered shopping assistant using OpenAI with function calling.
    Provides ChatGPT shopping mode functionality.
    """

    SYSTEM_PROMPT = """You are a helpful shopping assistant integrated into FURG, a personal finance app. Your role is to help users:

1. **Find Products**: Search for products, compare options, and find the best deals
2. **Save Money**: Discover coupons, deals, cashback offers, and price drops
3. **Make Smart Decisions**: Recommend products based on user preferences and budget
4. **Track Shopping**: Manage shopping lists, price alerts, and reorder reminders
5. **Optimize Purchases**: Suggest the best credit cards for rewards and find loyalty points

## Communication Style
- Be helpful, concise, and specific with prices and product details
- Always mention when deals are time-limited
- Proactively suggest ways to save money
- Format product results clearly with prices, ratings, and key features
- When comparing products, highlight trade-offs (price vs quality, features, etc.)

## Shopping Intelligence
- Consider the user's budget when making recommendations
- Alert users to potential price drops or upcoming sales
- Cross-reference with their shopping list to find relevant deals
- Suggest credit cards that maximize rewards for each purchase

## Response Format for Products
When showing products, format them clearly:
- **Product Name** - $XX.XX at Retailer
  - Key features/specs
  - Rating: X.X/5 (XXX reviews)
  - Deal: XX% off (if applicable)

Remember: Your goal is to help users shop smarter, not just shop more."""

    def __init__(self, user_id: str):
        self.user_id = user_id
        self.conversation_history: List[Dict] = []

    async def chat(
        self,
        message: str,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process a shopping-related message and return response with any actions taken.

        Args:
            message: User's message
            context: Additional context (shopping list, preferences, etc.)

        Returns:
            Dict with response, actions taken, and any product results
        """
        # Add user message to history
        self.conversation_history.append({
            "role": "user",
            "content": message
        })

        # Build messages for API
        messages = [
            {"role": "system", "content": self._build_system_prompt(context)}
        ] + self.conversation_history

        # Track API usage
        async with APIUsageTracker(self.user_id, "shopping_chat") as tracker:
            try:
                response = await client.chat.completions.create(
                    model="gpt-4o",
                    messages=messages,
                    functions=SHOPPING_FUNCTIONS,
                    function_call="auto",
                    temperature=0.7,
                    max_tokens=2000
                )

                assistant_message = response.choices[0].message
                actions_taken = []
                function_results = []

                # Handle function calls
                while assistant_message.function_call:
                    function_name = assistant_message.function_call.name
                    function_args = json.loads(assistant_message.function_call.arguments)

                    # Execute the function
                    result = await self._execute_function(function_name, function_args)
                    function_results.append({
                        "function": function_name,
                        "args": function_args,
                        "result": result
                    })
                    actions_taken.append(f"{function_name}: {function_args}")

                    # Add function call and result to conversation
                    self.conversation_history.append({
                        "role": "assistant",
                        "content": None,
                        "function_call": {
                            "name": function_name,
                            "arguments": assistant_message.function_call.arguments
                        }
                    })
                    self.conversation_history.append({
                        "role": "function",
                        "name": function_name,
                        "content": json.dumps(result)
                    })

                    # Get next response
                    messages = [
                        {"role": "system", "content": self._build_system_prompt(context)}
                    ] + self.conversation_history

                    response = await client.chat.completions.create(
                        model="gpt-4o",
                        messages=messages,
                        functions=SHOPPING_FUNCTIONS,
                        function_call="auto",
                        temperature=0.7,
                        max_tokens=2000
                    )
                    assistant_message = response.choices[0].message

                # Get final text response
                response_text = assistant_message.content or "I found some results for you!"

                # Add to history
                self.conversation_history.append({
                    "role": "assistant",
                    "content": response_text
                })

                # Track usage
                tracker.record(
                    response.usage.prompt_tokens,
                    response.usage.completion_tokens
                )

                # Save to database
                await db.save_message(
                    self.user_id,
                    "user",
                    message,
                    conversation_type="shopping"
                )
                await db.save_message(
                    self.user_id,
                    "assistant",
                    response_text,
                    conversation_type="shopping"
                )

                return {
                    "message": response_text,
                    "actions": actions_taken,
                    "function_results": function_results,
                    "tokens_used": {
                        "input": response.usage.prompt_tokens,
                        "output": response.usage.completion_tokens
                    }
                }

            except Exception as e:
                print(f"OpenAI API error: {e}")
                fallback = "I'm having trouble processing that request. Please try again."

                return {
                    "message": fallback,
                    "error": str(e),
                    "actions": [],
                    "function_results": []
                }

    def _build_system_prompt(self, context: Optional[Dict[str, Any]] = None) -> str:
        """Build system prompt with user context"""
        prompt = self.SYSTEM_PROMPT

        if context:
            prompt += "\n\n## User Context\n"

            if context.get("shopping_list"):
                items = context["shopping_list"][:5]
                prompt += f"Shopping list ({len(items)} items):\n"
                for item in items:
                    prompt += f"- {item.get('name', 'Item')}"
                    if item.get('target_price'):
                        prompt += f" (target: ${item['target_price']:.2f})"
                    prompt += "\n"

            if context.get("budget"):
                prompt += f"Monthly shopping budget: ${context['budget']:.2f}\n"

            if context.get("preferred_retailers"):
                prompt += f"Preferred retailers: {', '.join(context['preferred_retailers'])}\n"

            if context.get("credit_cards"):
                prompt += f"Credit cards: {', '.join(context['credit_cards'])}\n"

        return prompt

    async def _execute_function(
        self,
        function_name: str,
        args: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute a shopping function and return results"""

        if function_name == "search_products":
            return await self._search_products(**args)

        elif function_name == "find_deals":
            return await self._find_deals(**args)

        elif function_name == "compare_prices":
            return await self._compare_prices(**args)

        elif function_name == "add_to_shopping_list":
            return await self._add_to_shopping_list(**args)

        elif function_name == "create_price_alert":
            return await self._create_price_alert(**args)

        elif function_name == "get_product_recommendations":
            return await self._get_recommendations(**args)

        elif function_name == "get_shopping_list":
            return await self._get_shopping_list(**args)

        elif function_name == "find_best_credit_card":
            return await self._find_best_card(**args)

        elif function_name == "check_loyalty_points":
            return await self._check_loyalty_points(**args)

        elif function_name == "get_reorder_suggestions":
            return await self._get_reorder_suggestions(**args)

        return {"error": f"Unknown function: {function_name}"}

    # Function implementations

    async def _search_products(
        self,
        query: str,
        category: Optional[str] = None,
        max_price: Optional[float] = None,
        min_price: Optional[float] = None,
        sort_by: str = "relevance",
        limit: int = 10
    ) -> Dict[str, Any]:
        """
        Search for products. In production, this would call actual product APIs
        (Amazon Product API, Google Shopping API, etc.)
        """
        # Simulated product search results
        # In production: Call external APIs like Amazon, Google Shopping, etc.
        import random

        base_products = [
            {"name": "Apple AirPods Pro 2", "category": "electronics", "base_price": 249.00, "rating": 4.8, "reviews": 45000, "retailer": "Amazon"},
            {"name": "Sony WH-1000XM5 Headphones", "category": "electronics", "base_price": 398.00, "rating": 4.7, "reviews": 12000, "retailer": "Best Buy"},
            {"name": "Samsung Galaxy Buds2 Pro", "category": "electronics", "base_price": 229.00, "rating": 4.5, "reviews": 8000, "retailer": "Samsung"},
            {"name": "Nike Air Max 270", "category": "clothing", "base_price": 150.00, "rating": 4.6, "reviews": 25000, "retailer": "Nike"},
            {"name": "Instant Pot Duo 7-in-1", "category": "home", "base_price": 89.99, "rating": 4.7, "reviews": 150000, "retailer": "Amazon"},
            {"name": "Ninja Foodi Air Fryer", "category": "home", "base_price": 159.99, "rating": 4.6, "reviews": 35000, "retailer": "Target"},
            {"name": "Dyson V15 Detect", "category": "home", "base_price": 749.99, "rating": 4.8, "reviews": 5000, "retailer": "Dyson"},
            {"name": "Olaplex No. 3 Hair Perfector", "category": "beauty", "base_price": 30.00, "rating": 4.5, "reviews": 85000, "retailer": "Sephora"},
            {"name": "The Ordinary Niacinamide Serum", "category": "beauty", "base_price": 6.50, "rating": 4.4, "reviews": 120000, "retailer": "Ulta"},
            {"name": "Whey Protein Powder 5lb", "category": "health", "base_price": 54.99, "rating": 4.6, "reviews": 40000, "retailer": "Amazon"},
        ]

        # Filter by query
        query_lower = query.lower()
        results = [p for p in base_products if query_lower in p["name"].lower() or query_lower in p.get("category", "")]

        # If no exact matches, return similar products
        if not results:
            results = base_products[:5]

        # Apply filters
        if category:
            results = [p for p in results if p.get("category") == category]

        if max_price:
            results = [p for p in results if p["base_price"] <= max_price]

        if min_price:
            results = [p for p in results if p["base_price"] >= min_price]

        # Add some variance and deals
        products = []
        for p in results[:limit]:
            has_deal = random.random() > 0.6
            discount = random.choice([10, 15, 20, 25, 30]) if has_deal else 0
            price = p["base_price"] * (1 - discount/100)

            products.append({
                "name": p["name"],
                "price": round(price, 2),
                "original_price": p["base_price"] if has_deal else None,
                "discount_percent": discount if has_deal else None,
                "rating": p["rating"],
                "reviews": p["reviews"],
                "retailer": p["retailer"],
                "in_stock": random.random() > 0.1,
                "url": f"https://{p['retailer'].lower().replace(' ', '')}.com/product/{p['name'].lower().replace(' ', '-')}"
            })

        # Sort
        if sort_by == "price_low":
            products.sort(key=lambda x: x["price"])
        elif sort_by == "price_high":
            products.sort(key=lambda x: x["price"], reverse=True)
        elif sort_by == "rating":
            products.sort(key=lambda x: x["rating"], reverse=True)

        return {
            "query": query,
            "total_results": len(products),
            "products": products
        }

    async def _find_deals(
        self,
        query: str,
        retailer: Optional[str] = None,
        discount_type: Optional[str] = None,
        min_discount: Optional[float] = None
    ) -> Dict[str, Any]:
        """Find deals and coupons for products"""
        import random

        # Simulated deals database
        all_deals = [
            {
                "retailer": "Amazon",
                "title": "20% off Electronics",
                "code": "TECH20",
                "discount_type": "percent_off",
                "discount_value": 20,
                "categories": ["electronics"],
                "expires": (datetime.now() + timedelta(days=3)).isoformat(),
                "min_purchase": 50
            },
            {
                "retailer": "Target",
                "title": "$10 off $50 Home Purchase",
                "code": "HOME10",
                "discount_type": "dollar_off",
                "discount_value": 10,
                "categories": ["home"],
                "expires": (datetime.now() + timedelta(days=7)).isoformat(),
                "min_purchase": 50
            },
            {
                "retailer": "Walmart",
                "title": "BOGO 50% off Groceries",
                "code": None,
                "discount_type": "bogo",
                "discount_value": 50,
                "categories": ["grocery"],
                "expires": (datetime.now() + timedelta(days=5)).isoformat(),
                "min_purchase": None
            },
            {
                "retailer": "Best Buy",
                "title": "Free Shipping on Orders $35+",
                "code": "SHIPFREE",
                "discount_type": "free_shipping",
                "discount_value": 0,
                "categories": ["electronics", "home"],
                "expires": (datetime.now() + timedelta(days=14)).isoformat(),
                "min_purchase": 35
            },
            {
                "retailer": "Amazon",
                "title": "5% Cashback with Prime Card",
                "code": None,
                "discount_type": "cashback",
                "discount_value": 5,
                "categories": ["all"],
                "expires": None,
                "min_purchase": None
            },
            {
                "retailer": "Sephora",
                "title": "15% off Beauty Products",
                "code": "BEAUTY15",
                "discount_type": "percent_off",
                "discount_value": 15,
                "categories": ["beauty"],
                "expires": (datetime.now() + timedelta(days=2)).isoformat(),
                "min_purchase": None
            },
        ]

        query_lower = query.lower()
        deals = all_deals.copy()

        # Filter by retailer
        if retailer:
            deals = [d for d in deals if d["retailer"].lower() == retailer.lower()]

        # Filter by discount type
        if discount_type:
            deals = [d for d in deals if d["discount_type"] == discount_type]

        # Filter by minimum discount
        if min_discount:
            deals = [d for d in deals if d["discount_value"] >= min_discount]

        # Filter by query (match category or retailer)
        filtered_deals = []
        for d in deals:
            if (query_lower in d["retailer"].lower() or
                any(query_lower in cat for cat in d["categories"]) or
                "all" in d["categories"]):
                filtered_deals.append(d)

        return {
            "query": query,
            "deals_found": len(filtered_deals),
            "deals": filtered_deals
        }

    async def _compare_prices(
        self,
        product_name: str,
        include_used: bool = False
    ) -> Dict[str, Any]:
        """Compare prices across retailers"""
        import random

        retailers = ["Amazon", "Walmart", "Target", "Best Buy", "Costco", "eBay"]
        base_price = random.uniform(50, 500)

        comparisons = []
        for retailer in retailers:
            # Vary prices by +-20%
            variance = random.uniform(-0.2, 0.2)
            price = base_price * (1 + variance)

            comparisons.append({
                "retailer": retailer,
                "price": round(price, 2),
                "in_stock": random.random() > 0.15,
                "shipping": "Free" if random.random() > 0.3 else f"${random.randint(5, 15):.2f}",
                "delivery_days": random.randint(1, 7),
                "condition": "New"
            })

        # Add used options if requested
        if include_used:
            for retailer in ["eBay", "Amazon Warehouse"]:
                comparisons.append({
                    "retailer": retailer,
                    "price": round(base_price * random.uniform(0.5, 0.75), 2),
                    "in_stock": True,
                    "shipping": "Free",
                    "delivery_days": random.randint(3, 10),
                    "condition": random.choice(["Like New", "Very Good", "Good"])
                })

        # Sort by price
        comparisons.sort(key=lambda x: x["price"])

        best_deal = comparisons[0]
        avg_price = sum(c["price"] for c in comparisons) / len(comparisons)
        savings = avg_price - best_deal["price"]

        return {
            "product": product_name,
            "comparisons": comparisons,
            "best_deal": best_deal,
            "average_price": round(avg_price, 2),
            "potential_savings": round(savings, 2)
        }

    async def _add_to_shopping_list(
        self,
        item_name: str,
        quantity: int = 1,
        category: Optional[str] = None,
        target_price: Optional[float] = None,
        preferred_store: Optional[str] = None,
        notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """Add item to user's shopping list"""
        # In production, this would call the database
        item = {
            "id": f"item_{datetime.now().timestamp()}",
            "name": item_name,
            "quantity": quantity,
            "category": category or "Other",
            "target_price": target_price,
            "preferred_store": preferred_store,
            "notes": notes,
            "added_at": datetime.now().isoformat(),
            "status": "pending"
        }

        # Would save to database
        # await db.add_shopping_list_item(self.user_id, item)

        return {
            "success": True,
            "message": f"Added {quantity}x {item_name} to your shopping list",
            "item": item
        }

    async def _create_price_alert(
        self,
        product_name: str,
        target_price: float
    ) -> Dict[str, Any]:
        """Create a price drop alert"""
        alert = {
            "id": f"alert_{datetime.now().timestamp()}",
            "product": product_name,
            "target_price": target_price,
            "created_at": datetime.now().isoformat(),
            "status": "active"
        }

        # Would save to database
        # await db.create_price_alert(self.user_id, alert)

        return {
            "success": True,
            "message": f"Price alert created! I'll notify you when {product_name} drops to ${target_price:.2f}",
            "alert": alert
        }

    async def _get_recommendations(
        self,
        category: Optional[str] = None,
        budget: Optional[float] = None,
        use_case: Optional[str] = None
    ) -> Dict[str, Any]:
        """Get personalized product recommendations"""
        import random

        recommendations = [
            {
                "name": "Apple AirPods Pro 2",
                "price": 199.99,
                "why": "Based on your previous electronics purchases and premium brand preference",
                "rating": 4.8,
                "match_score": 95
            },
            {
                "name": "Anker Soundcore Life Q30",
                "price": 79.99,
                "why": "Great value alternative with similar features",
                "rating": 4.5,
                "match_score": 88
            },
            {
                "name": "Sony WF-1000XM5",
                "price": 279.99,
                "why": "Top-rated in your preferred category",
                "rating": 4.9,
                "match_score": 92
            }
        ]

        # Filter by budget
        if budget:
            recommendations = [r for r in recommendations if r["price"] <= budget]

        return {
            "recommendations": recommendations,
            "based_on": ["purchase_history", "preferences", "trending"],
            "category": category,
            "budget": budget
        }

    async def _get_shopping_list(
        self,
        include_purchased: bool = False
    ) -> Dict[str, Any]:
        """Get user's shopping list"""
        # In production, fetch from database
        # items = await db.get_shopping_list(self.user_id, include_purchased)

        # Simulated data
        items = [
            {"name": "Milk", "quantity": 2, "category": "Grocery", "status": "pending"},
            {"name": "AirPods Case", "quantity": 1, "category": "Electronics", "target_price": 15.00, "status": "pending"},
            {"name": "Laundry Detergent", "quantity": 1, "category": "Household", "status": "pending"},
        ]

        return {
            "items": items,
            "total_items": len(items),
            "estimated_total": sum(item.get("target_price", 10) for item in items)
        }

    async def _find_best_card(
        self,
        merchant: str,
        amount: Optional[float] = None
    ) -> Dict[str, Any]:
        """Find best credit card for a purchase"""
        # In production, this would use user's actual card data

        cards = [
            {
                "name": "Chase Sapphire Preferred",
                "category_match": "dining",
                "multiplier": 3,
                "reward_type": "points",
                "estimated_value": (amount or 100) * 0.03 if "restaurant" in merchant.lower() else (amount or 100) * 0.01
            },
            {
                "name": "Amazon Prime Rewards",
                "category_match": "amazon",
                "multiplier": 5,
                "reward_type": "cashback",
                "estimated_value": (amount or 100) * 0.05 if "amazon" in merchant.lower() else (amount or 100) * 0.01
            },
            {
                "name": "Citi Double Cash",
                "category_match": "everything",
                "multiplier": 2,
                "reward_type": "cashback",
                "estimated_value": (amount or 100) * 0.02
            }
        ]

        # Sort by estimated value
        cards.sort(key=lambda x: x["estimated_value"], reverse=True)

        return {
            "merchant": merchant,
            "amount": amount,
            "best_card": cards[0],
            "all_options": cards,
            "recommendation": f"Use {cards[0]['name']} to earn ${cards[0]['estimated_value']:.2f} back"
        }

    async def _check_loyalty_points(
        self,
        retailer: Optional[str] = None
    ) -> Dict[str, Any]:
        """Check loyalty points balance"""
        # In production, integrate with loyalty program APIs

        programs = [
            {"retailer": "Target", "program": "Target Circle", "points": 1250, "value": 12.50},
            {"retailer": "Starbucks", "program": "Starbucks Rewards", "points": 340, "value": 17.00},
            {"retailer": "Amazon", "program": "Prime Rewards", "points": 2500, "value": 25.00},
            {"retailer": "Sephora", "program": "Beauty Insider", "points": 500, "value": 15.00},
        ]

        if retailer:
            programs = [p for p in programs if retailer.lower() in p["retailer"].lower()]

        total_value = sum(p["value"] for p in programs)

        return {
            "programs": programs,
            "total_points_value": total_value,
            "tip": "You have rewards expiring soon at Target - use them before month end!"
        }

    async def _get_reorder_suggestions(
        self,
        days_ahead: int = 7
    ) -> Dict[str, Any]:
        """Get reorder suggestions based on purchase patterns"""
        # In production, analyze purchase history

        suggestions = [
            {
                "item": "Laundry Detergent",
                "last_purchased": "3 weeks ago",
                "typical_interval": "4 weeks",
                "suggested_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
                "best_price": {"retailer": "Costco", "price": 18.99}
            },
            {
                "item": "Coffee Pods (K-Cup)",
                "last_purchased": "2 weeks ago",
                "typical_interval": "3 weeks",
                "suggested_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
                "best_price": {"retailer": "Amazon", "price": 32.99}
            },
        ]

        return {
            "suggestions": suggestions,
            "days_ahead": days_ahead,
            "estimated_spend": sum(s["best_price"]["price"] for s in suggestions)
        }

    def clear_history(self):
        """Clear conversation history"""
        self.conversation_history = []


# Convenience function for quick shopping queries
async def quick_shop(
    user_id: str,
    query: str,
    context: Optional[Dict] = None
) -> Dict[str, Any]:
    """Quick shopping query without maintaining conversation state"""
    assistant = ShoppingAssistant(user_id)
    return await assistant.chat(query, context)
