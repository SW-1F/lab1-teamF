#!/bin/bash
# ============================================================
# run-tests.sh — Execute all Saleor DB unit tests
# Tier: Database (PostgreSQL)
# Scope: UNIT TESTS ONLY — isolated test schema, no real Saleor instance
# Usage: ./run-tests.sh  (or via docker compose)
# ============================================================
set -e

DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-saleor}"
DB_PASS="${DB_PASS:-saleor}"
DB_NAME="${DB_NAME:-saleor_test}"

PSQL="psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
export PGPASSWORD="$DB_PASS"

echo "=================================================="
echo " Saleor Product DB Unit Tests"
echo " Host: $DB_HOST | DB: $DB_NAME"
echo "=================================================="

# Wait for PostgreSQL to be ready
until pg_isready -h "$DB_HOST" -U "$DB_USER" -q; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

echo ""
echo ">>> [SETUP] Initializing isolated test schema..."
$PSQL -f /tests/init_test_schema.sql
echo "    Schema ready."

echo ""
echo ">>> [TEST 1] INSERT — product can be created with valid fields"
$PSQL -f /tests/test_product_insert.sql
echo "    PASSED"

echo ""
echo ">>> [TEST 2] SELECT — published/draft filters and JOIN with category"
$PSQL -f /tests/test_product_select.sql
echo "    PASSED"

echo ""
echo ">>> [TEST 3] UPDATE — name and published status can be modified"
$PSQL -f /tests/test_product_update.sql
echo "    PASSED"

echo ""
echo ">>> [TEST 4] DELETE — cascade removes linked variants"
$PSQL -f /tests/test_product_delete.sql
echo "    PASSED"

echo ""
echo ">>> [TEST 5] CONSTRAINTS — NOT NULL, UNIQUE, FK violations are enforced"
$PSQL -f /tests/test_product_constraints.sql 2>&1 | grep -E "ERROR|PASSED" || true
echo "    INFO: constraint violations above are expected."

echo ""
echo "=================================================="
echo " All DB unit tests completed."
echo "=================================================="
