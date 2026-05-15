"""
test_product_service.py
=======================
Unit tests for ProductQuerySet service-layer logic.

Tier: API — Python service / ORM layer
Tests the Fake QuerySet implementation that mirrors Django ORM.
Keeps all tests in-memory: no database, no network.
"""
import pytest
from product_resolver import Product, ProductQuerySet, ProductDoesNotExist


@pytest.fixture
def qs():
    return ProductQuerySet([
        Product(id=1, name="Alpha",  slug="alpha",  is_published=True,  category_id=1),
        Product(id=2, name="Beta",   slug="beta",   is_published=False, category_id=2),
        Product(id=3, name="Gamma",  slug="gamma",  is_published=True,  category_id=1),
    ])


class TestProductQuerySet:

    def test_all_returns_all_items(self, qs):
        assert len(qs.all()) == 3

    def test_filter_by_is_published_true(self, qs):
        result = qs.filter(is_published=True)
        assert len(result) == 2
        for p in result:
            assert p.is_published is True

    def test_filter_by_is_published_false(self, qs):
        result = qs.filter(is_published=False)
        assert len(result) == 1
        assert result._items[0].name == "Beta"

    def test_filter_by_category_id(self, qs):
        result = qs.filter(category_id=1)
        assert len(result) == 2

    def test_filter_chaining(self, qs):
        """Filter by category then by published status."""
        result = qs.filter(category_id=1).filter(is_published=True)
        assert len(result) == 2

    def test_get_by_pk(self, qs):
        p = qs.get(pk=2)
        assert p.name == "Beta"

    def test_get_by_slug(self, qs):
        p = qs.get(slug="gamma")
        assert p.id == 3

    def test_get_raises_when_not_found(self, qs):
        with pytest.raises(ProductDoesNotExist):
            qs.get(pk=9999)

    def test_count(self, qs):
        assert qs.count() == 3

    def test_count_after_filter(self, qs):
        assert qs.filter(is_published=True).count() == 2

    def test_order_by_name_ascending(self, qs):
        ordered = list(qs.order_by("name"))
        names = [p.name for p in ordered]
        assert names == sorted(names)

    def test_order_by_name_descending(self, qs):
        ordered = list(qs.order_by("-name"))
        names = [p.name for p in ordered]
        assert names == sorted(names, reverse=True)

    def test_empty_queryset_count_is_zero(self):
        empty = ProductQuerySet([])
        assert empty.count() == 0

    def test_empty_queryset_filter_returns_empty(self):
        empty = ProductQuerySet([])
        assert len(empty.filter(is_published=True)) == 0
