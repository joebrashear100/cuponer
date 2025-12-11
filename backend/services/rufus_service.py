"""
Rufus Service - Amazon Shopping AI Integration
Powered by Amazon Product Advertising API 5.0

Helps users save money through:
- Price tracking and drop alerts
- Deal discovery
- Finding cheaper alternatives
- Smart purchase timing recommendations
"""

import os
import hashlib
import hmac
import json
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from urllib.parse import quote
import httpx
from dataclasses import dataclass


# Amazon PA-API Configuration
AMAZON_ACCESS_KEY = os.getenv("AMAZON_ACCESS_KEY", "")
AMAZON_SECRET_KEY = os.getenv("AMAZON_SECRET_KEY", "")
AMAZON_PARTNER_TAG = os.getenv("AMAZON_PARTNER_TAG", "furg-20")
AMAZON_HOST = "webservices.amazon.com"
AMAZON_REGION = "us-east-1"


@dataclass
class AmazonProduct:
    """Amazon product data"""
    asin: str
    title: str
    price: float
    original_price: Optional[float]
    currency: str
    image_url: Optional[str]
    url: str
    rating: Optional[float]
    review_count: Optional[int]
    is_prime: bool
    deal_badge: Optional[str]
    savings_percent: Optional[float]
    category: Optional[str]
    availability: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "asin": self.asin,
            "title": self.title,
            "price": self.price,
            "original_price": self.original_price,
            "currency": self.currency,
            "image_url": self.image_url,
            "url": self.url,
            "rating": self.rating,
            "review_count": self.review_count,
            "is_prime": self.is_prime,
            "deal_badge": self.deal_badge,
            "savings_percent": self.savings_percent,
            "category": self.category,
            "availability": self.availability
        }


@dataclass
class RufusDeal:
    """A deal found by Rufus"""
    product: AmazonProduct
    deal_type: str  # "lightning", "daily", "prime", "coupon", "price_drop"
    expires_at: Optional[datetime]
    match_reason: str  # Why this deal was suggested
    savings_amount: float
    relevance_score: float  # 0-1 how relevant to user

    def to_dict(self) -> Dict[str, Any]:
        return {
            "product": self.product.to_dict(),
            "deal_type": self.deal_type,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "match_reason": self.match_reason,
            "savings_amount": self.savings_amount,
            "relevance_score": self.relevance_score
        }


class RufusService:
    """
    Rufus - Your AI Shopping Sidekick

    Integrates with Amazon Product Advertising API to help users
    find deals, track prices, and save money on purchases.
    """

    @staticmethod
    def _generate_signature(
        method: str,
        host: str,
        path: str,
        payload: str,
        timestamp: str,
        date: str
    ) -> Dict[str, str]:
        """Generate AWS Signature v4 for Amazon PA-API"""
        algorithm = "AWS4-HMAC-SHA256"
        service = "ProductAdvertisingAPI"

        # Create canonical request
        canonical_uri = path
        canonical_querystring = ""

        payload_hash = hashlib.sha256(payload.encode("utf-8")).hexdigest()

        canonical_headers = (
            f"content-encoding:amz-1.0\n"
            f"content-type:application/json; charset=utf-8\n"
            f"host:{host}\n"
            f"x-amz-date:{timestamp}\n"
            f"x-amz-target:com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems\n"
        )
        signed_headers = "content-encoding;content-type;host;x-amz-date;x-amz-target"

        canonical_request = (
            f"{method}\n{canonical_uri}\n{canonical_querystring}\n"
            f"{canonical_headers}\n{signed_headers}\n{payload_hash}"
        )

        # Create string to sign
        credential_scope = f"{date}/{AMAZON_REGION}/{service}/aws4_request"
        string_to_sign = (
            f"{algorithm}\n{timestamp}\n{credential_scope}\n"
            f"{hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()}"
        )

        # Calculate signature
        def sign(key: bytes, msg: str) -> bytes:
            return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()

        k_date = sign(f"AWS4{AMAZON_SECRET_KEY}".encode("utf-8"), date)
        k_region = sign(k_date, AMAZON_REGION)
        k_service = sign(k_region, service)
        k_signing = sign(k_service, "aws4_request")

        signature = hmac.new(
            k_signing, string_to_sign.encode("utf-8"), hashlib.sha256
        ).hexdigest()

        # Build authorization header
        authorization_header = (
            f"{algorithm} Credential={AMAZON_ACCESS_KEY}/{credential_scope}, "
            f"SignedHeaders={signed_headers}, Signature={signature}"
        )

        return {
            "content-encoding": "amz-1.0",
            "content-type": "application/json; charset=utf-8",
            "host": host,
            "x-amz-date": timestamp,
            "x-amz-target": "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems",
            "Authorization": authorization_header
        }

    @staticmethod
    async def search_products(
        keywords: str,
        category: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        min_rating: Optional[float] = None,
        prime_only: bool = False,
        sort_by: str = "Relevance",
        page: int = 1
    ) -> List[AmazonProduct]:
        """
        Search Amazon products using PA-API

        Args:
            keywords: Search terms
            category: Amazon category (e.g., "Electronics", "Home")
            min_price: Minimum price filter
            max_price: Maximum price filter
            min_rating: Minimum review rating (1-5)
            prime_only: Only show Prime-eligible items
            sort_by: Sort order (Relevance, Price:LowToHigh, Price:HighToLow, AvgCustomerReviews)
            page: Page number for pagination

        Returns:
            List of matching AmazonProduct objects
        """
        # Build request payload
        payload = {
            "Keywords": keywords,
            "Resources": [
                "Images.Primary.Large",
                "ItemInfo.Title",
                "ItemInfo.Features",
                "ItemInfo.ProductInfo",
                "Offers.Listings.Price",
                "Offers.Listings.SavingBasis",
                "Offers.Listings.DeliveryInfo.IsPrimeEligible",
                "Offers.Listings.Promotions",
                "Offers.Summaries.LowestPrice",
                "BrowseNodeInfo.BrowseNodes.Ancestor",
                "CustomerReviews.Count",
                "CustomerReviews.StarRating"
            ],
            "PartnerTag": AMAZON_PARTNER_TAG,
            "PartnerType": "Associates",
            "Marketplace": "www.amazon.com",
            "ItemCount": 10,
            "ItemPage": page,
            "SortBy": sort_by
        }

        # Add optional filters
        if category:
            payload["SearchIndex"] = category

        if min_price or max_price:
            payload["MinPrice"] = int((min_price or 0) * 100)  # Convert to cents
            if max_price:
                payload["MaxPrice"] = int(max_price * 100)

        if min_rating:
            payload["MinReviewsRating"] = min_rating

        if prime_only:
            payload["DeliveryFlags"] = ["Prime"]

        # In production, make actual API call
        # For now, return mock data for development
        if not AMAZON_ACCESS_KEY or not AMAZON_SECRET_KEY:
            return await RufusService._get_mock_products(keywords, max_price)

        # Make API request
        now = datetime.utcnow()
        timestamp = now.strftime("%Y%m%dT%H%M%SZ")
        date = now.strftime("%Y%m%d")

        payload_str = json.dumps(payload)
        headers = RufusService._generate_signature(
            "POST", AMAZON_HOST, "/paapi5/searchitems",
            payload_str, timestamp, date
        )

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"https://{AMAZON_HOST}/paapi5/searchitems",
                headers=headers,
                content=payload_str,
                timeout=10.0
            )

            if response.status_code != 200:
                print(f"Amazon PA-API error: {response.status_code} - {response.text}")
                return []

            data = response.json()
            return RufusService._parse_search_results(data)

    @staticmethod
    async def get_product_by_asin(asin: str) -> Optional[AmazonProduct]:
        """Get detailed product info by ASIN"""
        if not AMAZON_ACCESS_KEY or not AMAZON_SECRET_KEY:
            # Return mock data
            return AmazonProduct(
                asin=asin,
                title="Sample Product",
                price=49.99,
                original_price=79.99,
                currency="USD",
                image_url="https://m.media-amazon.com/images/I/sample.jpg",
                url=f"https://www.amazon.com/dp/{asin}?tag={AMAZON_PARTNER_TAG}",
                rating=4.5,
                review_count=1234,
                is_prime=True,
                deal_badge="37% off",
                savings_percent=37.5,
                category="Electronics",
                availability="In Stock"
            )

        payload = {
            "ItemIds": [asin],
            "Resources": [
                "Images.Primary.Large",
                "ItemInfo.Title",
                "ItemInfo.Features",
                "ItemInfo.ProductInfo",
                "Offers.Listings.Price",
                "Offers.Listings.SavingBasis",
                "Offers.Listings.DeliveryInfo.IsPrimeEligible",
                "Offers.Listings.Promotions",
                "CustomerReviews.Count",
                "CustomerReviews.StarRating"
            ],
            "PartnerTag": AMAZON_PARTNER_TAG,
            "PartnerType": "Associates",
            "Marketplace": "www.amazon.com"
        }

        now = datetime.utcnow()
        timestamp = now.strftime("%Y%m%dT%H%M%SZ")
        date = now.strftime("%Y%m%d")

        payload_str = json.dumps(payload)
        headers = RufusService._generate_signature(
            "POST", AMAZON_HOST, "/paapi5/getitems",
            payload_str, timestamp, date
        )
        headers["x-amz-target"] = "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.GetItems"

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"https://{AMAZON_HOST}/paapi5/getitems",
                headers=headers,
                content=payload_str,
                timeout=10.0
            )

            if response.status_code != 200:
                return None

            data = response.json()
            products = RufusService._parse_search_results(data)
            return products[0] if products else None

    @staticmethod
    async def find_deals(
        categories: Optional[List[str]] = None,
        max_price: Optional[float] = None,
        keywords: Optional[List[str]] = None
    ) -> List[RufusDeal]:
        """
        Find current deals on Amazon

        Args:
            categories: List of categories to search
            max_price: Maximum price filter
            keywords: Keywords to match deals against

        Returns:
            List of RufusDeal objects sorted by relevance
        """
        deals = []

        # Search for deals in specified categories or default hot categories
        search_categories = categories or ["Electronics", "Home", "Fashion", "Toys"]

        for category in search_categories:
            # Search with deal-focused keywords
            products = await RufusService.search_products(
                keywords=f"deal {category}" if not keywords else " ".join(keywords),
                category=category,
                max_price=max_price,
                sort_by="Price:LowToHigh"
            )

            for product in products:
                # Check if this is actually a deal
                if product.savings_percent and product.savings_percent >= 10:
                    deal = RufusDeal(
                        product=product,
                        deal_type=RufusService._determine_deal_type(product),
                        expires_at=None,  # Would come from API in production
                        match_reason=f"Great deal in {category}",
                        savings_amount=round((product.original_price or product.price) - product.price, 2),
                        relevance_score=min(product.savings_percent / 100, 1.0)
                    )
                    deals.append(deal)

        # Sort by relevance score
        deals.sort(key=lambda d: d.relevance_score, reverse=True)
        return deals[:20]  # Return top 20 deals

    @staticmethod
    async def find_alternatives(
        asin: str,
        max_price: Optional[float] = None
    ) -> List[AmazonProduct]:
        """
        Find cheaper alternatives to a product

        Args:
            asin: ASIN of the original product
            max_price: Maximum price for alternatives

        Returns:
            List of alternative products sorted by price
        """
        # Get original product
        original = await RufusService.get_product_by_asin(asin)
        if not original:
            return []

        # Search for similar products at lower price
        search_terms = original.title.split()[:3]  # Use first 3 words

        alternatives = await RufusService.search_products(
            keywords=" ".join(search_terms),
            max_price=max_price or original.price * 0.8,  # 20% cheaper by default
            sort_by="Price:LowToHigh"
        )

        # Filter out the original product
        return [p for p in alternatives if p.asin != asin][:10]

    @staticmethod
    async def match_wishlist_deals(
        wishlist_items: List[Dict[str, Any]],
        max_results_per_item: int = 3
    ) -> Dict[str, List[RufusDeal]]:
        """
        Find Amazon deals matching wishlist items

        Args:
            wishlist_items: List of wishlist items with name and price
            max_results_per_item: Max deals to return per item

        Returns:
            Dict mapping wishlist item names to matching deals
        """
        results = {}

        for item in wishlist_items:
            name = item.get("name", "")
            target_price = item.get("price", 0)

            # Search for this item
            products = await RufusService.search_products(
                keywords=name,
                max_price=target_price * 1.1,  # Allow 10% over budget
                sort_by="Price:LowToHigh"
            )

            deals = []
            for product in products[:max_results_per_item]:
                # Calculate match score
                price_match = 1 - (abs(product.price - target_price) / target_price)

                deal = RufusDeal(
                    product=product,
                    deal_type="wishlist_match",
                    expires_at=None,
                    match_reason=f"Matches your wishlist item: {name}",
                    savings_amount=max(0, target_price - product.price),
                    relevance_score=max(0, min(1, price_match))
                )
                deals.append(deal)

            if deals:
                results[name] = deals

        return results

    @staticmethod
    async def get_price_prediction(asin: str) -> Dict[str, Any]:
        """
        Get price prediction and buy recommendation

        Args:
            asin: Product ASIN

        Returns:
            Price prediction with buy/wait recommendation
        """
        # In production, this would analyze historical price data
        # For now, provide a simulated prediction
        product = await RufusService.get_product_by_asin(asin)
        if not product:
            return {"error": "Product not found"}

        # Simulate prediction based on current deal status
        is_good_price = product.savings_percent and product.savings_percent >= 15

        return {
            "current_price": product.price,
            "average_price": product.price * 1.15 if is_good_price else product.price,
            "lowest_price_30d": product.price * 0.95,
            "highest_price_30d": product.price * 1.3,
            "recommendation": "buy" if is_good_price else "wait",
            "confidence": 0.75 if is_good_price else 0.6,
            "reason": (
                "Current price is below average - good time to buy!"
                if is_good_price else
                "Price may drop soon. Consider waiting for a deal."
            ),
            "next_expected_sale": "Black Friday" if not is_good_price else None
        }

    @staticmethod
    async def smart_search_for_chat(
        query: str,
        budget: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Smart search handler for chat integration

        Parses natural language queries and finds relevant products/deals

        Args:
            query: Natural language search query
            budget: User's available budget

        Returns:
            Formatted response for chat
        """
        # Extract intent from query
        query_lower = query.lower()

        # Determine search type
        is_deal_search = any(word in query_lower for word in ["deal", "sale", "cheap", "discount", "save"])
        is_alternative_search = any(word in query_lower for word in ["alternative", "instead", "cheaper", "similar"])

        # Clean up keywords
        stop_words = ["find", "me", "a", "an", "the", "for", "deal", "on", "good", "best"]
        keywords = [w for w in query.split() if w.lower() not in stop_words]
        search_terms = " ".join(keywords)

        if is_deal_search:
            products = await RufusService.search_products(
                keywords=search_terms,
                max_price=budget,
                sort_by="Price:LowToHigh"
            )

            if products:
                best = products[0]
                return {
                    "type": "deal_found",
                    "message": f"Found a great deal! {best.title[:50]}... is ${best.price:.2f}" +
                              (f" (was ${best.original_price:.2f} - {best.savings_percent:.0f}% off!)" if best.savings_percent else ""),
                    "products": [p.to_dict() for p in products[:3]],
                    "rufus_tip": "I can track this price for you and alert you if it drops even more!"
                }
        else:
            products = await RufusService.search_products(
                keywords=search_terms,
                max_price=budget,
                sort_by="Relevance"
            )

            if products:
                return {
                    "type": "search_results",
                    "message": f"Found {len(products)} options for '{search_terms}'",
                    "products": [p.to_dict() for p in products[:5]],
                    "rufus_tip": "Want me to find cheaper alternatives or track prices on any of these?"
                }

        return {
            "type": "no_results",
            "message": f"Couldn't find anything for '{search_terms}'. Try different keywords?",
            "products": [],
            "rufus_tip": "Tip: Be specific! Instead of 'headphones', try 'wireless bluetooth headphones'"
        }

    @staticmethod
    def _determine_deal_type(product: AmazonProduct) -> str:
        """Determine the type of deal based on product info"""
        if product.deal_badge:
            badge_lower = product.deal_badge.lower()
            if "lightning" in badge_lower:
                return "lightning"
            elif "prime" in badge_lower:
                return "prime"
            elif "black friday" in badge_lower or "cyber monday" in badge_lower:
                return "holiday"

        if product.savings_percent and product.savings_percent >= 30:
            return "price_drop"

        return "daily"

    @staticmethod
    def _parse_search_results(data: Dict[str, Any]) -> List[AmazonProduct]:
        """Parse Amazon PA-API response into AmazonProduct objects"""
        products = []

        items = data.get("SearchResult", {}).get("Items", [])
        if not items:
            items = data.get("ItemsResult", {}).get("Items", [])

        for item in items:
            try:
                asin = item.get("ASIN", "")

                # Get title
                title = item.get("ItemInfo", {}).get("Title", {}).get("DisplayValue", "Unknown")

                # Get pricing
                offers = item.get("Offers", {})
                listings = offers.get("Listings", [])

                price = 0
                original_price = None
                is_prime = False

                if listings:
                    listing = listings[0]
                    price_info = listing.get("Price", {})
                    price = price_info.get("Amount", 0)

                    # Check for savings
                    saving_basis = listing.get("SavingBasis", {})
                    if saving_basis:
                        original_price = saving_basis.get("Amount")

                    # Check Prime eligibility
                    delivery_info = listing.get("DeliveryInfo", {})
                    is_prime = delivery_info.get("IsPrimeEligible", False)

                # Get image
                image_url = None
                images = item.get("Images", {}).get("Primary", {})
                if images:
                    image_url = images.get("Large", {}).get("URL")

                # Get rating
                rating = None
                review_count = None
                reviews = item.get("CustomerReviews", {})
                if reviews:
                    rating = reviews.get("StarRating", {}).get("Value")
                    review_count = reviews.get("Count")

                # Calculate savings
                savings_percent = None
                if original_price and original_price > price:
                    savings_percent = round(((original_price - price) / original_price) * 100, 1)

                # Get deal badge from promotions
                deal_badge = None
                if listings:
                    promotions = listings[0].get("Promotions", [])
                    if promotions:
                        deal_badge = promotions[0].get("Type", "")

                product = AmazonProduct(
                    asin=asin,
                    title=title,
                    price=price,
                    original_price=original_price,
                    currency="USD",
                    image_url=image_url,
                    url=f"https://www.amazon.com/dp/{asin}?tag={AMAZON_PARTNER_TAG}",
                    rating=rating,
                    review_count=review_count,
                    is_prime=is_prime,
                    deal_badge=deal_badge,
                    savings_percent=savings_percent,
                    category=None,
                    availability="In Stock"
                )
                products.append(product)

            except Exception as e:
                print(f"Error parsing product: {e}")
                continue

        return products

    @staticmethod
    async def _get_mock_products(keywords: str, max_price: Optional[float] = None) -> List[AmazonProduct]:
        """Generate mock products for development/testing"""
        # Mock product data based on keywords
        mock_data = [
            {
                "keywords": ["headphones", "earbuds", "audio"],
                "products": [
                    AmazonProduct(
                        asin="B09JQ7V4XC",
                        title="Sony WH-1000XM5 Wireless Noise Canceling Headphones",
                        price=328.00,
                        original_price=399.99,
                        currency="USD",
                        image_url="https://m.media-amazon.com/images/I/61vJtKbAssL._AC_SL1500_.jpg",
                        url=f"https://www.amazon.com/dp/B09JQ7V4XC?tag={AMAZON_PARTNER_TAG}",
                        rating=4.6,
                        review_count=15234,
                        is_prime=True,
                        deal_badge="18% off",
                        savings_percent=18.0,
                        category="Electronics",
                        availability="In Stock"
                    ),
                    AmazonProduct(
                        asin="B0BX8S2G1V",
                        title="Apple AirPods Pro (2nd Gen) with USB-C",
                        price=189.99,
                        original_price=249.00,
                        currency="USD",
                        image_url="https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SL1500_.jpg",
                        url=f"https://www.amazon.com/dp/B0BX8S2G1V?tag={AMAZON_PARTNER_TAG}",
                        rating=4.7,
                        review_count=42891,
                        is_prime=True,
                        deal_badge="24% off",
                        savings_percent=24.0,
                        category="Electronics",
                        availability="In Stock"
                    )
                ]
            },
            {
                "keywords": ["laptop", "computer", "macbook"],
                "products": [
                    AmazonProduct(
                        asin="B0CM5JV268",
                        title="Apple 2024 MacBook Air 13-inch M3 Chip",
                        price=999.00,
                        original_price=1099.00,
                        currency="USD",
                        image_url="https://m.media-amazon.com/images/I/71f5Eu5lJSL._AC_SL1500_.jpg",
                        url=f"https://www.amazon.com/dp/B0CM5JV268?tag={AMAZON_PARTNER_TAG}",
                        rating=4.8,
                        review_count=8923,
                        is_prime=True,
                        deal_badge="$100 off",
                        savings_percent=9.1,
                        category="Electronics",
                        availability="In Stock"
                    )
                ]
            },
            {
                "keywords": ["coffee", "maker", "espresso"],
                "products": [
                    AmazonProduct(
                        asin="B07P8RNCS7",
                        title="Nespresso Vertuo Next Coffee and Espresso Machine",
                        price=129.95,
                        original_price=179.95,
                        currency="USD",
                        image_url="https://m.media-amazon.com/images/I/71HXS2ad82L._AC_SL1500_.jpg",
                        url=f"https://www.amazon.com/dp/B07P8RNCS7?tag={AMAZON_PARTNER_TAG}",
                        rating=4.4,
                        review_count=28456,
                        is_prime=True,
                        deal_badge="28% off",
                        savings_percent=27.8,
                        category="Home & Kitchen",
                        availability="In Stock"
                    )
                ]
            }
        ]

        # Find matching products
        keywords_lower = keywords.lower()
        matching_products = []

        for category in mock_data:
            if any(kw in keywords_lower for kw in category["keywords"]):
                matching_products.extend(category["products"])

        # If no specific match, return some generic deals
        if not matching_products:
            matching_products = [
                AmazonProduct(
                    asin="B0GENERIC1",
                    title=f"Top Rated {keywords.title()} - Best Seller",
                    price=49.99,
                    original_price=79.99,
                    currency="USD",
                    image_url=None,
                    url=f"https://www.amazon.com/s?k={keywords.replace(' ', '+')}&tag={AMAZON_PARTNER_TAG}",
                    rating=4.3,
                    review_count=1500,
                    is_prime=True,
                    deal_badge="37% off",
                    savings_percent=37.5,
                    category="General",
                    availability="In Stock"
                )
            ]

        # Filter by price if specified
        if max_price:
            matching_products = [p for p in matching_products if p.price <= max_price]

        return matching_products


# Price tracking service
class RufusPriceTracker:
    """
    Tracks prices for products and alerts users on drops
    """

    @staticmethod
    async def track_product(
        user_id: str,
        asin: str,
        target_price: Optional[float] = None,
        db=None
    ) -> Dict[str, Any]:
        """
        Start tracking a product for price drops

        Args:
            user_id: User ID
            asin: Amazon product ASIN
            target_price: Alert when price drops below this
            db: Database connection

        Returns:
            Tracking confirmation
        """
        # Get current product info
        product = await RufusService.get_product_by_asin(asin)
        if not product:
            return {"error": "Product not found"}

        # Set target price to 10% below current if not specified
        if not target_price:
            target_price = product.price * 0.9

        tracking_data = {
            "asin": asin,
            "title": product.title,
            "current_price": product.price,
            "target_price": target_price,
            "image_url": product.image_url,
            "tracked_at": datetime.utcnow().isoformat()
        }

        # Save to database if provided
        if db:
            await db.create_rufus_tracked_product(user_id, tracking_data)

        return {
            "success": True,
            "message": f"Now tracking {product.title[:50]}...",
            "current_price": product.price,
            "target_price": target_price,
            "savings_if_hit": round(product.price - target_price, 2)
        }

    @staticmethod
    async def check_price_drops(user_id: str, db=None) -> List[Dict[str, Any]]:
        """
        Check for price drops on tracked products

        Returns:
            List of products with price drops
        """
        if not db:
            return []

        tracked = await db.get_rufus_tracked_products(user_id)
        drops = []

        for item in tracked:
            current = await RufusService.get_product_by_asin(item["asin"])
            if current and current.price < item.get("last_checked_price", item["current_price"]):
                drops.append({
                    "asin": item["asin"],
                    "title": item["title"],
                    "old_price": item.get("last_checked_price", item["current_price"]),
                    "new_price": current.price,
                    "savings": round(item.get("last_checked_price", item["current_price"]) - current.price, 2),
                    "hit_target": current.price <= item["target_price"]
                })

                # Update last checked price
                await db.update_rufus_tracked_price(item["id"], current.price)

        return drops
