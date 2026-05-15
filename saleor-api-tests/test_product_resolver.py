"""
test_product_resolver.py
========================
Unit tests for Saleor's product resolver functions.

Tier: API — Python / Django / GraphQL
Functional flow: Product Listing
  Dashboard (React) --> [GraphQL Query] --> resolver --> [ORM] --> DB

Test doubles applied
--------------------
- Fake   (ProductQuerySet): an in-memory list that honours the same
  .all() / .filter() / .get() / .count() interface as Django's QuerySet.
  Justification: lets us exercise filter logic without a running database;
  stays deterministic and never touches network or disk.

- Stub   (mock_info): a MagicMock configured with a real ProductManager
  injected into info.context. Provides just enough context for resolvers
  to execute without a full Django request lifecycle.

- Mock   (mock_info_spy): used in interaction tests to assert *how*
  the resolver calls its collaborators (e.g. .all() is called once).
"""
import pytest
from unittest.mock import MagicMock
from product_resolver import (
    resolve_products,
    resolve_product,
    resolve_product_count,
    ProductDoesNotExist,
)


# ── resolve_products ───────────────────────────────────────────────────────

class TestResolveProducts:

    def test_returns_all_products_when_no_filter(self, mock_info):
        result = list(resolve_products(mock_info))
        assert len(result) == 4

    def test_filter_published_returns_only_published(self, mock_info):
        result = list(resolve_products(mock_info, filter={"is_published": True}))
        assert len(result) == 3
        assert all(p.is_published for p in result)

    def test_filter_unpublished_returns_only_drafts(self, mock_info):
        result = list(resolve_products(mock_info, filter={"is_published": False}))
        assert len(result) == 1
        assert result[0].name == "Draft Keyboard"

    def test_none_filter_returns_all(self, mock_info):
        result = list(resolve_products(mock_info, filter=None))
        assert len(result) == 4

    def test_calls_product_manager_all(self, mock_info_spy):
        """Interaction test: resolver must call .all() on the manager (Mock)."""
        info, mock_qs = mock_info_spy
        resolve_products(info)
        info.context.product_manager.all.assert_called_once()

    def test_applies_filter_when_is_published_given(self, mock_info_spy):
        """Interaction test: resolver must call .filter() when filter is set."""
        info, mock_qs = mock_info_spy
        resolve_products(info, filter={"is_published": True})
        mock_qs.filter.assert_called_once_with(is_published=True)


# ── resolve_product ────────────────────────────────────────────────────────

class TestResolveProduct:

    def test_returns_product_by_id(self, mock_info):
        product = resolve_product(mock_info, id=1)
        assert product is not None
        assert product.name == "Laptop Pro"

    def test_returns_product_by_slug(self, mock_info):
        product = resolve_product(mock_info, slug="wireless-mouse")
        assert product is not None
        assert product.id == 2

    def test_returns_none_for_unknown_id(self, mock_info):
        result = resolve_product(mock_info, id=9999)
        assert result is None

    def test_returns_none_for_unknown_slug(self, mock_info):
        result = resolve_product(mock_info, slug="nonexistent-slug")
        assert result is None

    def test_returns_none_when_no_args(self, mock_info):
        result = resolve_product(mock_info)
        assert result is None


# ── resolve_product_count ──────────────────────────────────────────────────

class TestResolveProductCount:

    def test_count_all(self, mock_info):
        assert resolve_product_count(mock_info) == 4

    def test_count_published(self, mock_info):
        assert resolve_product_count(mock_info, filter={"is_published": True}) == 3

    def test_count_unpublished(self, mock_info):
        assert resolve_product_count(mock_info, filter={"is_published": False}) == 1
