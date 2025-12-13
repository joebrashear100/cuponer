"""
Gemini (Google) integration for FURG
Handles routing, categorization, and receipt scanning
"""

import os
import json
import httpx
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from enum import Enum


class ModelIntent(str, Enum):
    """Classified intent for model routing"""
    ROAST = "roast"           # Banter, jokes, spending mockery -> Grok
    ADVICE = "advice"         # Financial guidance, serious questions -> Claude
    CATEGORIZE = "categorize" # Transaction classification -> Gemini
    SENSITIVE = "sensitive"   # Account issues, complaints -> Claude
    RECEIPT = "receipt"       # Receipt scanning -> Gemini Vision
    GENERAL = "general"       # General chat -> Grok (cheaper)


@dataclass
class RouterResponse:
    """Response from intent classification"""
    intent: ModelIntent
    confidence: float
    reasoning: Optional[str] = None


@dataclass
class CategoryResponse:
    """Response from transaction categorization"""
    category: str
    confidence: float
    subcategory: Optional[str] = None


@dataclass
class GeminiResponse:
    """Generic Gemini response"""
    content: str
    input_tokens: int
    output_tokens: int
    model: str


class GeminiService:
    """
    Gemini API service for routing and categorization

    Uses Gemini 2.0 Flash for fast, cheap inference
    - Router: Classify intent to route to appropriate model
    - Categorizer: Classify transactions
    - Receipt Scanner: Extract data from receipt images
    """

    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
    MODEL = "gemini-2.0-flash"  # Fast and cheap

    # Stable router prompt (cacheable)
    ROUTER_SYSTEM = """You are an intent classifier for a financial AI app. Classify user messages into one of these categories:

CATEGORIES:
- "roast": Casual chat, banter, jokes about spending, playful messages, greetings, small talk
- "advice": Serious financial questions, budgeting help, investment questions, "should I buy", planning
- "categorize": Questions about transaction categories, asking what category something is
- "sensitive": Complaints, account issues, errors, frustration, requests to change settings
- "receipt": User mentions receipt, bill, scanning, or shares an image
- "general": Anything else that doesn't fit above

OUTPUT FORMAT (JSON only):
{"intent": "category", "confidence": 0.0-1.0, "reasoning": "brief reason"}

EXAMPLES:
User: "roast my uber spending" -> {"intent": "roast", "confidence": 0.95, "reasoning": "explicit roast request"}
User: "should I buy these shoes?" -> {"intent": "advice", "confidence": 0.9, "reasoning": "purchase decision"}
User: "hey what's up" -> {"intent": "roast", "confidence": 0.8, "reasoning": "casual greeting"}
User: "this app sucks" -> {"intent": "sensitive", "confidence": 0.9, "reasoning": "complaint"}
User: "what category is netflix" -> {"intent": "categorize", "confidence": 0.95, "reasoning": "category question"}
"""

    CATEGORIZER_SYSTEM = """You are a transaction categorizer. Classify transactions into these categories:

CATEGORIES:
- food_dining: Restaurants, fast food, coffee shops, bars
- groceries: Supermarkets, grocery stores, food delivery (groceries)
- transportation: Uber, Lyft, gas, parking, public transit
- shopping: Retail, Amazon, clothing, electronics
- entertainment: Streaming, movies, concerts, games
- bills_utilities: Rent, utilities, phone, internet
- health_fitness: Gym, pharmacy, doctors, wellness
- travel: Hotels, flights, Airbnb, vacation
- subscriptions: Monthly services, memberships
- transfers: Bank transfers, payments to people
- income: Salary, deposits, refunds
- other: Anything else

OUTPUT FORMAT (JSON only):
{"category": "category_name", "confidence": 0.0-1.0, "subcategory": "optional_detail"}
"""

    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY")
        self.client = httpx.AsyncClient(timeout=30.0)

    async def _call_gemini(
        self,
        prompt: str,
        system: str = None,
        temperature: float = 0.1,
        max_tokens: int = 256
    ) -> Dict:
        """Make a call to Gemini API"""

        url = f"{self.BASE_URL}/models/{self.MODEL}:generateContent"

        # Build request
        contents = []
        if system:
            contents.append({
                "role": "user",
                "parts": [{"text": f"System instructions:\n{system}\n\nUser message:\n{prompt}"}]
            })
        else:
            contents.append({
                "role": "user",
                "parts": [{"text": prompt}]
            })

        body = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens,
            }
        }

        response = await self.client.post(
            url,
            params={"key": self.api_key},
            json=body
        )
        response.raise_for_status()
        return response.json()

    async def classify_intent(self, message: str) -> RouterResponse:
        """
        Classify user intent for model routing

        Args:
            message: User's message

        Returns:
            RouterResponse with intent and confidence
        """
        try:
            result = await self._call_gemini(
                prompt=f"Classify this message: {message}",
                system=self.ROUTER_SYSTEM,
                temperature=0.1,
                max_tokens=100
            )

            # Parse response
            text = result["candidates"][0]["content"]["parts"][0]["text"]

            # Extract JSON from response
            text = text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]

            data = json.loads(text)

            intent_str = data.get("intent", "general").lower()
            try:
                intent = ModelIntent(intent_str)
            except ValueError:
                intent = ModelIntent.GENERAL

            return RouterResponse(
                intent=intent,
                confidence=float(data.get("confidence", 0.5)),
                reasoning=data.get("reasoning")
            )

        except Exception as e:
            print(f"Router classification error: {e}")
            # Default to roast (cheapest path) on error
            return RouterResponse(
                intent=ModelIntent.ROAST,
                confidence=0.5,
                reasoning="fallback due to error"
            )

    async def categorize_transaction(
        self,
        merchant: str,
        amount: float,
        description: str = None
    ) -> CategoryResponse:
        """
        Categorize a transaction

        Args:
            merchant: Merchant name
            amount: Transaction amount
            description: Optional description

        Returns:
            CategoryResponse with category and confidence
        """
        prompt = f"Categorize: ${abs(amount):.2f} at {merchant}"
        if description:
            prompt += f" ({description})"

        try:
            result = await self._call_gemini(
                prompt=prompt,
                system=self.CATEGORIZER_SYSTEM,
                temperature=0.1,
                max_tokens=100
            )

            text = result["candidates"][0]["content"]["parts"][0]["text"]

            # Extract JSON
            text = text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]

            data = json.loads(text)

            return CategoryResponse(
                category=data.get("category", "other"),
                confidence=float(data.get("confidence", 0.5)),
                subcategory=data.get("subcategory")
            )

        except Exception as e:
            print(f"Categorization error: {e}")
            return CategoryResponse(
                category="other",
                confidence=0.3,
                subcategory=None
            )

    async def batch_categorize(
        self,
        transactions: List[Dict]
    ) -> List[CategoryResponse]:
        """
        Categorize multiple transactions in one call
        More efficient for bulk processing
        """
        if not transactions:
            return []

        # Build batch prompt
        lines = ["Categorize each transaction (return JSON array):"]
        for i, txn in enumerate(transactions[:20]):  # Limit to 20
            merchant = txn.get("merchant", "Unknown")
            amount = abs(txn.get("amount", 0))
            lines.append(f"{i+1}. ${amount:.2f} at {merchant}")

        prompt = "\n".join(lines)

        try:
            result = await self._call_gemini(
                prompt=prompt,
                system=self.CATEGORIZER_SYSTEM + "\n\nFor batch requests, return a JSON array of results.",
                temperature=0.1,
                max_tokens=1000
            )

            text = result["candidates"][0]["content"]["parts"][0]["text"]

            # Extract JSON array
            text = text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]

            data = json.loads(text)

            if isinstance(data, list):
                return [
                    CategoryResponse(
                        category=item.get("category", "other"),
                        confidence=float(item.get("confidence", 0.5)),
                        subcategory=item.get("subcategory")
                    )
                    for item in data
                ]
            else:
                # Single result returned
                return [CategoryResponse(
                    category=data.get("category", "other"),
                    confidence=float(data.get("confidence", 0.5)),
                    subcategory=data.get("subcategory")
                )]

        except Exception as e:
            print(f"Batch categorization error: {e}")
            return [CategoryResponse(category="other", confidence=0.3) for _ in transactions]

    async def scan_receipt(self, image_base64: str) -> Dict:
        """
        Extract data from receipt image

        Args:
            image_base64: Base64 encoded image

        Returns:
            Dict with merchant, amount, date, items
        """
        # Use vision-capable model
        url = f"{self.BASE_URL}/models/gemini-2.0-flash:generateContent"

        body = {
            "contents": [{
                "role": "user",
                "parts": [
                    {"text": """Extract from this receipt and return JSON:
{
  "merchant": "store name",
  "total": 0.00,
  "date": "YYYY-MM-DD or null",
  "items": [{"name": "item", "price": 0.00}],
  "tax": 0.00,
  "payment_method": "card/cash/unknown"
}"""},
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": image_base64
                        }
                    }
                ]
            }],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 500
            }
        }

        try:
            response = await self.client.post(
                url,
                params={"key": self.api_key},
                json=body
            )
            response.raise_for_status()
            result = response.json()

            text = result["candidates"][0]["content"]["parts"][0]["text"]

            # Extract JSON
            text = text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]

            return json.loads(text)

        except Exception as e:
            print(f"Receipt scan error: {e}")
            return {
                "merchant": "Unknown",
                "total": 0,
                "date": None,
                "items": [],
                "error": str(e)
            }

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()


# Global service instance
gemini_service = GeminiService()
