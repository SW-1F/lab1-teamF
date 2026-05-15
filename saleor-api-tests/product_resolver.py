"""
product_resolver.py
===================
Simplified extraction of Saleor's product resolver logic.

In production this lives in:
  saleor/graphql/product/resolvers.py
  saleor/product/models.py

This standalone module is the Unit Under Test (UUT) for pytest.
It mirrors the real resolver/manager interface without requiring
Django ORM or a running database — allowing pure unit isolation.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import List, Optional


# ---------------------------------------------------------------------------
# Simplified domain model (mirrors saleor.product.models.Product)
# ---------------------------------------------------------------------------

@dataclass
class Product:
    id: int
    name: str
    slug: str
    is_published: bool = False
    category_id: Optional[int] = None
    rating: Optional[float] = None


class ProductDoesNotExist(Exception):
    pass


# ---------------------------------------------------------------------------
# Simplified QuerySet (Fake — mirrors Django QuerySet interface)
# ---------------------------------------------------------------------------

class ProductQuerySet:
    def __init__(self, items: List[Product]):
        self._items = list(items)

    def all(self) -> "ProductQuerySet":
        return ProductQuerySet(self._items)

    def filter(self, **kwargs) -> "ProductQuerySet":
        result = self._items
        if "is_published" in kwargs:
            result = [p for p in result if p.is_published == kwargs["is_published"]]
        if "category_id" in kwargs:
            result = [p for p in result if p.category_id == kwargs["category_id"]]
        return ProductQuerySet(result)

    def get(self, **kwargs) -> Product:
        candidates = self._items
        if "pk" in kwargs:
            candidates = [p for p in candidates if p.id == kwargs["pk"]]
        if "slug" in kwargs:
            candidates = [p for p in candidates if p.slug == kwargs["slug"]]
        if not candidates:
            raise ProductDoesNotExist(f"No product matching {kwargs}")
        if len(candidates) > 1:
            raise ValueError("Multiple products found for given lookup")
        return candidates[0]

    def count(self) -> int:
        return len(self._items)

    def order_by(self, field: str) -> "ProductQuerySet":
        reverse = field.startswith("-")
        key = field.lstrip("-")
        return ProductQuerySet(sorted(self._items, key=lambda p: getattr(p, key, 0), reverse=reverse))

    def __iter__(self):
        return iter(self._items)

    def __len__(self):
        return len(self._items)


# ---------------------------------------------------------------------------
# Manager (mirrors Django Model.objects)
# ---------------------------------------------------------------------------

class ProductManager:
    def __init__(self, queryset: ProductQuerySet):
        self._qs = queryset

    def all(self) -> ProductQuerySet:
        return self._qs.all()

    def filter(self, **kwargs) -> ProductQuerySet:
        return self._qs.filter(**kwargs)

    def get(self, **kwargs) -> Product:
        return self._qs.get(**kwargs)


# ---------------------------------------------------------------------------
# Resolver functions
# (mirrors saleor/graphql/product/resolvers.py)
# ---------------------------------------------------------------------------

def resolve_products(info, filter=None):
    """Return all products, optionally filtered by is_published."""
    qs = info.context.product_manager.all()
    if filter and filter.get("is_published") is not None:
        qs = qs.filter(is_published=filter["is_published"])
    return qs


def resolve_product(info, id=None, slug=None):
    """Return a single product by id or slug. Returns None if not found."""
    try:
        if id is not None:
            return info.context.product_manager.get(pk=id)
        if slug is not None:
            return info.context.product_manager.get(slug=slug)
    except ProductDoesNotExist:
        return None
    return None


def resolve_product_count(info, filter=None):
    """Return a count of products matching optional filter."""
    qs = info.context.product_manager.all()
    if filter and filter.get("is_published") is not None:
        qs = qs.filter(is_published=filter["is_published"])
    return qs.count()
