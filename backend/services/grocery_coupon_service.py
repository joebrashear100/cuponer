"""
Grocery Coupon Service - Location-Based Coupon Discovery

Provides location-aware grocery store coupons with personal preference support.
Aggregates coupons from multiple sources and applies user preferences for filtering.
"""

import os
import math
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, asdict
from enum import Enum


class GroceryChain(str, Enum):
    KROGER = "kroger"
    SAFEWAY = "safeway"
    WHOLEFOODS = "wholefoods"
    TRADERJOES = "traderjoes"
    COSTCO = "costco"
    WALMART = "walmart"
    TARGET = "target"
    ALDIS = "aldis"
    PUBLIX = "publix"
    HEB = "heb"
    WEGMANS = "wegmans"
    SPROUTS = "sprouts"
    OTHER = "other"


class DiscountType(str, Enum):
    PERCENT_OFF = "percent_off"
    DOLLAR_OFF = "dollar_off"
    BOGO = "bogo"
    BOGO_HALF = "bogo_half"
    FREE = "free"
    CASHBACK = "cashback"
    POINTS_MULTIPLIER = "points_multiplier"


class CouponCategory(str, Enum):
    PRODUCE = "produce"
    DAIRY = "dairy"
    MEAT = "meat"
    SEAFOOD = "seafood"
    BAKERY = "bakery"
    FROZEN = "frozen"
    PANTRY = "pantry"
    SNACKS = "snacks"
    BEVERAGES = "beverages"
    HOUSEHOLD = "household"
    PERSONAL = "personal"
    BABY = "baby"
    PET = "pet"
    ORGANIC = "organic"
    GLUTEN_FREE = "gluten_free"
    VEGAN = "vegan"
    OTHER = "other"


class DietaryPreference(str, Enum):
    VEGAN = "vegan"
    VEGETARIAN = "vegetarian"
    GLUTEN_FREE = "gluten_free"
    DAIRY_FREE = "dairy_free"
    NUT_FREE = "nut_free"
    ORGANIC = "organic"
    KETO = "keto"
    PALEO = "paleo"
    LOW_SODIUM = "low_sodium"
    SUGAR_FREE = "sugar_free"
    HALAL = "halal"
    KOSHER = "kosher"


class CouponSortOption(str, Enum):
    RELEVANCE = "relevance"
    DISTANCE = "distance"
    SAVINGS = "savings"
    EXPIRING_SOON = "expiring_soon"
    NEWEST = "newest"
    CATEGORY = "category"


@dataclass
class GroceryStore:
    """A grocery store location"""
    id: str
    name: str
    chain: str
    address: str
    city: str
    state: str
    zip_code: str
    latitude: float
    longitude: float
    distance: Optional[float] = None
    is_open: bool = True
    closing_time: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class GroceryCoupon:
    """A grocery store coupon"""
    id: str
    store_id: str
    chain: str
    title: str
    description: str
    discount_type: str
    discount_value: float
    minimum_purchase: Optional[float]
    max_savings: Optional[float]
    code: Optional[str]
    barcode: Optional[str]
    category: str
    brand: Optional[str]
    product_name: Optional[str]
    image_url: Optional[str]
    expires_at: str  # ISO format
    is_digital: bool
    is_clipped: bool
    is_stackable: bool
    requires_loyalty_card: bool
    limit_per_customer: Optional[int]
    tags: List[str]

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class UserCouponPreferences:
    """User's coupon preferences"""
    preferred_stores: List[str]
    excluded_stores: List[str]
    preferred_categories: List[str]
    excluded_categories: List[str]
    dietary_preferences: List[str]
    max_distance_miles: float
    show_expiring_soon: bool
    show_digital_only: bool
    minimum_discount_percent: Optional[float]
    sort_by: str


class GroceryCouponService:
    """
    Location-based grocery coupon discovery service.

    Features:
    - Find nearby grocery stores
    - Fetch coupons based on location
    - Apply user preference filters
    - Support dietary preferences
    - Sort by relevance, distance, savings
    """

    # Simulated store database (in production, use real store locator APIs)
    STORE_DATABASE: Dict[str, Dict[str, Any]] = {
        "kroger": {
            "name": "Kroger",
            "has_coupons": True,
            "loyalty_program": "Kroger Plus Card"
        },
        "safeway": {
            "name": "Safeway",
            "has_coupons": True,
            "loyalty_program": "Club Card"
        },
        "wholefoods": {
            "name": "Whole Foods Market",
            "has_coupons": True,
            "loyalty_program": "Amazon Prime"
        },
        "target": {
            "name": "Target",
            "has_coupons": True,
            "loyalty_program": "Target Circle"
        },
        "walmart": {
            "name": "Walmart",
            "has_coupons": True,
            "loyalty_program": "Walmart+"
        },
        "traderjoes": {
            "name": "Trader Joe's",
            "has_coupons": False,  # Everyday low pricing
            "loyalty_program": None
        },
        "costco": {
            "name": "Costco",
            "has_coupons": True,
            "loyalty_program": "Costco Membership"
        },
        "publix": {
            "name": "Publix",
            "has_coupons": True,
            "loyalty_program": "Club Publix"
        }
    }

    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points in miles using Haversine formula."""
        R = 3959  # Earth's radius in miles

        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)

        a = (math.sin(delta_lat / 2) ** 2 +
             math.cos(lat1_rad) * math.cos(lat2_rad) *
             math.sin(delta_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    @classmethod
    def find_nearby_stores(
        cls,
        latitude: float,
        longitude: float,
        radius_miles: float = 10.0,
        preferred_chains: Optional[List[str]] = None,
        excluded_chains: Optional[List[str]] = None
    ) -> List[GroceryStore]:
        """
        Find grocery stores near a given location.

        In production, this would call store locator APIs for each chain.
        For now, returns simulated stores based on location.
        """
        stores = []
        now = datetime.now()

        # Simulated store locations around the user
        # In production, use Google Places API, store-specific APIs, etc.
        store_offsets = [
            ("kroger", 0.005, 0.003, "123 Main St"),
            ("safeway", 0.008, -0.002, "456 Oak Ave"),
            ("wholefoods", -0.003, 0.006, "789 Market St"),
            ("target", 0.012, 0.008, "321 Mission St"),
            ("traderjoes", -0.007, -0.004, "555 Folsom St"),
            ("walmart", 0.015, -0.010, "888 Commerce Blvd"),
            ("publix", -0.010, 0.012, "222 Peachtree Rd"),
            ("costco", 0.020, 0.015, "999 Warehouse Way"),
        ]

        for chain, lat_offset, lon_offset, address in store_offsets:
            # Skip excluded chains
            if excluded_chains and chain in excluded_chains:
                continue

            store_lat = latitude + lat_offset
            store_lon = longitude + lon_offset
            distance = cls.calculate_distance(latitude, longitude, store_lat, store_lon)

            # Only include stores within radius
            if distance <= radius_miles:
                chain_info = cls.STORE_DATABASE.get(chain, {})
                stores.append(GroceryStore(
                    id=f"{chain}-1",
                    name=chain_info.get("name", chain.title()),
                    chain=chain,
                    address=address,
                    city="San Francisco",  # Would be geocoded in production
                    state="CA",
                    zip_code="94102",
                    latitude=store_lat,
                    longitude=store_lon,
                    distance=round(distance, 2),
                    is_open=True,
                    closing_time="10:00 PM"
                ))

        # Sort by preference then distance
        if preferred_chains:
            stores.sort(key=lambda s: (
                0 if s.chain in preferred_chains else 1,
                s.distance or float('inf')
            ))
        else:
            stores.sort(key=lambda s: s.distance or float('inf'))

        return stores

    @classmethod
    def get_coupons_for_stores(
        cls,
        stores: List[GroceryStore],
        preferences: Optional[UserCouponPreferences] = None
    ) -> List[GroceryCoupon]:
        """
        Get coupons for the given stores.

        In production, this would aggregate from:
        - Store-specific APIs (Kroger API, Target Circle, etc.)
        - Coupon aggregators (RetailMeNot, Coupons.com)
        - Ibotta, Fetch Rewards
        """
        coupons = []
        now = datetime.now()

        # Generate sample coupons for each store
        coupon_templates = cls._get_coupon_templates()

        for store in stores:
            chain_info = cls.STORE_DATABASE.get(store.chain, {})

            # Skip stores without coupon programs
            if not chain_info.get("has_coupons", True):
                continue

            # Get coupons for this chain
            chain_coupons = coupon_templates.get(store.chain, [])

            for template in chain_coupons:
                # Apply dietary preference filtering
                if preferences and preferences.dietary_preferences:
                    dietary_tags = preferences.dietary_preferences
                    # Skip non-matching coupons for restricted categories
                    if template.get("category") in ["meat", "dairy", "bakery"]:
                        if not any(tag in template.get("tags", []) for tag in dietary_tags):
                            # Check if this conflicts with dietary preferences
                            if "vegan" in dietary_tags and template.get("category") == "meat":
                                if "vegan" not in template.get("tags", []):
                                    continue
                            if "dairy_free" in dietary_tags and template.get("category") == "dairy":
                                if "dairy_free" not in template.get("tags", []):
                                    continue

                # Apply category exclusions
                if preferences and preferences.excluded_categories:
                    if template.get("category") in preferences.excluded_categories:
                        continue

                # Create coupon with expiration date
                expires_days = template.get("expires_days", 7)
                expires_at = now + timedelta(days=expires_days)

                coupon = GroceryCoupon(
                    id=f"{store.chain}-{template['id']}",
                    store_id=store.id,
                    chain=store.chain,
                    title=template["title"],
                    description=template["description"],
                    discount_type=template["discount_type"],
                    discount_value=template["discount_value"],
                    minimum_purchase=template.get("minimum_purchase"),
                    max_savings=template.get("max_savings"),
                    code=template.get("code"),
                    barcode=template.get("barcode"),
                    category=template["category"],
                    brand=template.get("brand"),
                    product_name=template.get("product_name"),
                    image_url=template.get("image_url"),
                    expires_at=expires_at.isoformat(),
                    is_digital=template.get("is_digital", True),
                    is_clipped=False,
                    is_stackable=template.get("is_stackable", True),
                    requires_loyalty_card=template.get("requires_loyalty_card", True),
                    limit_per_customer=template.get("limit_per_customer"),
                    tags=template.get("tags", [])
                )
                coupons.append(coupon)

        # Sort coupons based on preferences
        if preferences:
            coupons = cls._sort_coupons(coupons, stores, preferences)

        return coupons

    @classmethod
    def _sort_coupons(
        cls,
        coupons: List[GroceryCoupon],
        stores: List[GroceryStore],
        preferences: UserCouponPreferences
    ) -> List[GroceryCoupon]:
        """Sort coupons based on user preferences."""
        store_distances = {s.id: s.distance or float('inf') for s in stores}

        if preferences.sort_by == CouponSortOption.DISTANCE.value:
            return sorted(coupons, key=lambda c: store_distances.get(c.store_id, float('inf')))

        elif preferences.sort_by == CouponSortOption.SAVINGS.value:
            return sorted(coupons, key=lambda c: c.discount_value, reverse=True)

        elif preferences.sort_by == CouponSortOption.EXPIRING_SOON.value:
            return sorted(coupons, key=lambda c: c.expires_at)

        elif preferences.sort_by == CouponSortOption.CATEGORY.value:
            return sorted(coupons, key=lambda c: c.category)

        else:  # RELEVANCE or default
            # Score each coupon
            def relevance_score(coupon: GroceryCoupon) -> float:
                score = 0.0

                # Preferred stores get +10
                if coupon.chain in preferences.preferred_stores:
                    score += 10

                # Preferred categories get +5
                if coupon.category in preferences.preferred_categories:
                    score += 5

                # Higher discounts get +discount_value
                score += coupon.discount_value

                # Closer stores get slight preference
                distance = store_distances.get(coupon.store_id, 10)
                score += max(0, 5 - distance)

                return score

            return sorted(coupons, key=relevance_score, reverse=True)

    @classmethod
    def _get_coupon_templates(cls) -> Dict[str, List[Dict[str, Any]]]:
        """Get coupon templates for each chain."""
        return {
            "kroger": [
                {
                    "id": "c1",
                    "title": "$2 off Fresh Organic Strawberries",
                    "description": "Save on 1 lb container of organic strawberries",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 2.00,
                    "category": CouponCategory.PRODUCE.value,
                    "product_name": "Organic Strawberries",
                    "barcode": "4901234567890",
                    "expires_days": 7,
                    "tags": ["organic", "fruit", "produce"],
                    "limit_per_customer": 2
                },
                {
                    "id": "c2",
                    "title": "25% off Kroger Brand Cereal",
                    "description": "Any Kroger brand cereal, 12oz or larger",
                    "discount_type": DiscountType.PERCENT_OFF.value,
                    "discount_value": 25,
                    "max_savings": 3.00,
                    "category": CouponCategory.PANTRY.value,
                    "brand": "Kroger",
                    "barcode": "4901234567891",
                    "expires_days": 14,
                    "tags": ["breakfast", "cereal"],
                    "limit_per_customer": 4
                },
                {
                    "id": "c3",
                    "title": "BOGO Chobani Greek Yogurt",
                    "description": "Buy one, get one free on any Chobani product",
                    "discount_type": DiscountType.BOGO.value,
                    "discount_value": 1.50,
                    "max_savings": 1.50,
                    "category": CouponCategory.DAIRY.value,
                    "brand": "Chobani",
                    "barcode": "4901234567892",
                    "expires_days": 5,
                    "tags": ["dairy", "yogurt", "protein"],
                    "limit_per_customer": 1
                },
                {
                    "id": "c4",
                    "title": "3x Fuel Points on Gift Cards",
                    "description": "Earn triple fuel points on all gift card purchases",
                    "discount_type": DiscountType.POINTS_MULTIPLIER.value,
                    "discount_value": 3,
                    "category": CouponCategory.OTHER.value,
                    "expires_days": 5,
                    "tags": ["fuel_points", "gift_cards"],
                    "is_stackable": False
                }
            ],
            "safeway": [
                {
                    "id": "c1",
                    "title": "$5 off $25 Purchase",
                    "description": "Save $5 on any purchase of $25 or more",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 5.00,
                    "minimum_purchase": 25.00,
                    "category": CouponCategory.OTHER.value,
                    "code": "SAVE5",
                    "expires_days": 3,
                    "tags": ["storewide"],
                    "is_stackable": False,
                    "limit_per_customer": 1
                },
                {
                    "id": "c2",
                    "title": "$1 off Beyond Meat",
                    "description": "Any Beyond Meat product",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 1.00,
                    "category": CouponCategory.MEAT.value,
                    "brand": "Beyond Meat",
                    "barcode": "4901234567893",
                    "expires_days": 10,
                    "tags": ["vegan", "plant_based", "meat_alternative"],
                    "limit_per_customer": 2
                },
                {
                    "id": "c3",
                    "title": "$1.50 off Gluten-Free Bread",
                    "description": "Any Canyon Bakehouse gluten-free bread",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 1.50,
                    "category": CouponCategory.BAKERY.value,
                    "brand": "Canyon Bakehouse",
                    "barcode": "4901234567896",
                    "expires_days": 12,
                    "tags": ["gluten_free", "bread", "bakery"],
                    "limit_per_customer": 2
                }
            ],
            "wholefoods": [
                {
                    "id": "c1",
                    "title": "10% off All Vitamins",
                    "description": "Prime members save 10% on all vitamins and supplements",
                    "discount_type": DiscountType.PERCENT_OFF.value,
                    "discount_value": 10,
                    "category": CouponCategory.PERSONAL.value,
                    "expires_days": 30,
                    "tags": ["vitamins", "supplements", "prime"],
                    "requires_loyalty_card": False
                },
                {
                    "id": "c2",
                    "title": "$3 off Organic Chicken",
                    "description": "Save on organic free-range chicken breast",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 3.00,
                    "category": CouponCategory.MEAT.value,
                    "product_name": "Organic Chicken Breast",
                    "barcode": "4901234567894",
                    "expires_days": 4,
                    "tags": ["organic", "meat", "chicken"],
                    "requires_loyalty_card": False,
                    "limit_per_customer": 2
                },
                {
                    "id": "c3",
                    "title": "FREE Organic Apple with $10 Purchase",
                    "description": "Get a free organic Honeycrisp apple with any $10 purchase",
                    "discount_type": DiscountType.FREE.value,
                    "discount_value": 2.50,
                    "minimum_purchase": 10.00,
                    "category": CouponCategory.PRODUCE.value,
                    "product_name": "Organic Honeycrisp Apple",
                    "expires_days": 2,
                    "tags": ["organic", "fruit", "free"],
                    "requires_loyalty_card": False,
                    "limit_per_customer": 1
                }
            ],
            "target": [
                {
                    "id": "c1",
                    "title": "15% off Good & Gather",
                    "description": "Save on any Good & Gather grocery item",
                    "discount_type": DiscountType.PERCENT_OFF.value,
                    "discount_value": 15,
                    "max_savings": 5.00,
                    "category": CouponCategory.PANTRY.value,
                    "brand": "Good & Gather",
                    "expires_days": 21,
                    "tags": ["pantry", "store_brand"],
                    "requires_loyalty_card": False
                },
                {
                    "id": "c2",
                    "title": "$2 off Oatly Oat Milk",
                    "description": "Any Oatly product, 64 oz or larger",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 2.00,
                    "category": CouponCategory.DAIRY.value,
                    "brand": "Oatly",
                    "barcode": "4901234567895",
                    "expires_days": 14,
                    "tags": ["dairy_free", "vegan", "milk_alternative"],
                    "requires_loyalty_card": False,
                    "limit_per_customer": 2
                },
                {
                    "id": "c3",
                    "title": "20% off Baby Food",
                    "description": "Save on all organic baby food pouches",
                    "discount_type": DiscountType.PERCENT_OFF.value,
                    "discount_value": 20,
                    "max_savings": 10.00,
                    "category": CouponCategory.BABY.value,
                    "expires_days": 7,
                    "tags": ["baby", "organic"],
                    "requires_loyalty_card": False
                }
            ],
            "walmart": [
                {
                    "id": "c1",
                    "title": "$1 off Great Value Milk",
                    "description": "Any Great Value milk, gallon size",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 1.00,
                    "category": CouponCategory.DAIRY.value,
                    "brand": "Great Value",
                    "expires_days": 7,
                    "tags": ["dairy", "milk"],
                    "requires_loyalty_card": False
                },
                {
                    "id": "c2",
                    "title": "10% off Pet Food",
                    "description": "Save on all dog and cat food",
                    "discount_type": DiscountType.PERCENT_OFF.value,
                    "discount_value": 10,
                    "max_savings": 8.00,
                    "category": CouponCategory.PET.value,
                    "expires_days": 14,
                    "tags": ["pet", "dog", "cat"],
                    "requires_loyalty_card": False
                }
            ],
            "publix": [
                {
                    "id": "c1",
                    "title": "BOGO Publix Premium Ice Cream",
                    "description": "Buy one, get one free on Publix ice cream",
                    "discount_type": DiscountType.BOGO.value,
                    "discount_value": 5.99,
                    "max_savings": 5.99,
                    "category": CouponCategory.FROZEN.value,
                    "brand": "Publix Premium",
                    "expires_days": 7,
                    "tags": ["frozen", "ice_cream", "dessert"]
                },
                {
                    "id": "c2",
                    "title": "$2 off Deli Sandwich",
                    "description": "Any Publix deli sub or sandwich",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 2.00,
                    "category": CouponCategory.OTHER.value,
                    "expires_days": 5,
                    "tags": ["deli", "lunch", "sandwich"]
                }
            ],
            "costco": [
                {
                    "id": "c1",
                    "title": "$5 off Kirkland Olive Oil",
                    "description": "Kirkland Signature Extra Virgin Olive Oil, 2L",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 5.00,
                    "category": CouponCategory.PANTRY.value,
                    "brand": "Kirkland Signature",
                    "expires_days": 21,
                    "tags": ["pantry", "olive_oil", "cooking"]
                },
                {
                    "id": "c2",
                    "title": "$4 off Rotisserie Chicken",
                    "description": "Costco Rotisserie Chicken",
                    "discount_type": DiscountType.DOLLAR_OFF.value,
                    "discount_value": 4.00,
                    "category": CouponCategory.MEAT.value,
                    "expires_days": 7,
                    "tags": ["meat", "chicken", "rotisserie"]
                }
            ]
        }

    @classmethod
    async def search_coupons(
        cls,
        latitude: float,
        longitude: float,
        radius_miles: float = 10.0,
        preferred_stores: Optional[List[str]] = None,
        excluded_stores: Optional[List[str]] = None,
        categories: Optional[List[str]] = None,
        dietary_preferences: Optional[List[str]] = None,
        sort_by: str = "relevance",
        page: int = 1,
        limit: int = 20
    ) -> Dict[str, Any]:
        """
        Main search endpoint for grocery coupons.

        Returns coupons from nearby stores filtered by preferences.
        """
        # Build preferences object
        preferences = UserCouponPreferences(
            preferred_stores=preferred_stores or [],
            excluded_stores=excluded_stores or [],
            preferred_categories=categories or [],
            excluded_categories=[],
            dietary_preferences=dietary_preferences or [],
            max_distance_miles=radius_miles,
            show_expiring_soon=True,
            show_digital_only=False,
            minimum_discount_percent=None,
            sort_by=sort_by
        )

        # Find nearby stores
        stores = cls.find_nearby_stores(
            latitude=latitude,
            longitude=longitude,
            radius_miles=radius_miles,
            preferred_chains=preferred_stores,
            excluded_chains=excluded_stores
        )

        # Get coupons for those stores
        all_coupons = cls.get_coupons_for_stores(stores, preferences)

        # Filter by categories if specified
        if categories:
            all_coupons = [c for c in all_coupons if c.category in categories]

        # Paginate
        total_count = len(all_coupons)
        start_idx = (page - 1) * limit
        end_idx = start_idx + limit
        paginated_coupons = all_coupons[start_idx:end_idx]

        return {
            "coupons": [c.to_dict() for c in paginated_coupons],
            "stores": [s.to_dict() for s in stores],
            "total_count": total_count,
            "has_more": end_idx < total_count,
            "next_page": page + 1 if end_idx < total_count else None
        }

    @classmethod
    async def clip_coupon(
        cls,
        user_id: str,
        coupon_id: str,
        store_id: str
    ) -> Dict[str, Any]:
        """
        Clip a coupon to user's account.

        In production, this would call store-specific APIs to link
        the coupon to the user's loyalty card.
        """
        # For now, just return success
        # In production: call Kroger API, Target Circle API, etc.
        return {
            "success": True,
            "coupon_id": coupon_id,
            "message": "Coupon clipped to your account",
            "loyalty_card_required": True
        }

    @classmethod
    async def get_user_stats(
        cls,
        user_id: str
    ) -> Dict[str, Any]:
        """Get user's coupon usage statistics."""
        # In production, query database for user's coupon history
        return {
            "total_coupons_used": 47,
            "total_savings": 156.32,
            "coupons_clipped": 12,
            "favorite_store": "kroger",
            "favorite_category": "produce",
            "this_month_savings": 23.45
        }


# Export for use in main.py
grocery_coupon_service = GroceryCouponService()
