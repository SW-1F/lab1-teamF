"""
conftest.py — Shared pytest fixtures for Saleor API unit tests.

Test doubles used:
  - Fake   : ProductQuerySet (in-memory list, same interface as Django QS)
  - Stub   : mock_info (MagicMock with controlled context attributes)
  - Mock   : mock_info_with_mock_manager (full MagicMock for call verification)
"""
import pytest
from unittest.mock import MagicMock
from product_resolver import Product, ProductQuerySet, ProductManager


@pytest.fixture
def sample_products():
    """In-memory product data used across all tests."""
    return [
        Product(id=1, name="Laptop Pro",       slug="laptop-pro",       is_published=True,  category_id=10),
        Product(id=2, name="Wireless Mouse",   slug="wireless-mouse",   is_published=True,  category_id=10),
        Product(id=3, name="Draft Keyboard",   slug="draft-keyboard",   is_published=False, category_id=20),
        Product(id=4, name="Smart Monitor",    slug="smart-monitor",    is_published=True,  category_id=10),
    ]


@pytest.fixture
def product_manager(sample_products):
    """Fake ProductManager backed by in-memory data (no DB needed)."""
    return ProductManager(ProductQuerySet(sample_products))


@pytest.fixture
def mock_info(product_manager):
    """Stub: GraphQL ResolveInfo with a controlled context."""
    info = MagicMock()
    info.context.product_manager = product_manager
    return info


@pytest.fixture
def mock_info_spy():
    """Mock: fully mocked info object to verify interactions."""
    info = MagicMock()
    mock_qs = MagicMock()
    mock_qs.filter.return_value = mock_qs
    info.context.product_manager.all.return_value = mock_qs
    return info, mock_qs
