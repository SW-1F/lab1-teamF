# Unit Test Extension Report

- **Course:** Software Quality — SQ_2026i
- **Team:** F
- **Members:** Maria Jose Jara Herrera, Breyner Ismael Ciro Otero, Juan David Cristancho Rincon, Jairo Daniel Salas Mosquera, Aura Milena Alba, Carlos Alberto Cortez Polanco.
- **System:** [saleor/saleor-platform](https://github.com/saleor/saleor-platform)
- **Functional flow:** Product Listing — Dashboard → API resolver → Database
- **Tiers covered:** Frontend (React/Jest) ↔ Backend (Python/pytest) ↔ Database (PostgreSQL/SQL)

---

## Context

This repository contains our **Extended Laboratory 1** submission for **Software Quality (SQ_2026i)**.  
We performed **unit-level verification** on one functional flow of the open-source system [saleor/saleor-platform](https://github.com/saleor/saleor-platform):

**Product Listing — Dashboard → API resolver → Database**

The goal was to validate this flow across **three tiers** while preserving the **isolation principle** required by the laboratory:

- frontend unit tests must not contact the real backend,
- backend unit tests must not contact the real database,
- database tests must validate SQL behavior directly in the DB tier.

---

## Functional Flow Covered

The selected flow is:

1. the **Dashboard** requests product data,
2. the **API layer** resolves product queries,
3. the **Database** stores and retrieves product records.

This makes it possible to verify the same behavior across:

- **Frontend**: UI rendering and API-consumption logic,
- **Backend**: resolver logic and query behavior,
- **Database**: persistence, constraints, and SQL operations.

---

## Why Isolation Matters

Isolation makes the test suites **fast, deterministic, and diagnosable**.

- If SQL behavior or constraints are wrong, only the **DB suite** fails.
- If resolver logic is wrong, only the **backend suite** fails.
- If rendering or fetch logic is wrong, only the **frontend suite** fails.

Without this separation, tests would become cross-tier integration checks disguised as unit tests. That would make them slower, more fragile, and harder to debug, because failures would propagate across layers instead of staying localized.

---

# Repository Structure

```text
lab1-teamF/
│   docker-compose-tests.yml
│   report.pdf
│   README.md
│
├───saleor-api-tests
│   │   conftest.py
│   │   product_resolver.py
│   │   requirements.txt
│   │   test_product_resolver.py
│   │   test_product_service.py
│
├───saleor-dashboard-tests
│   │   babel.config.js
│   │   jest.config.js
│   │   package.json
│   │
│   └───src
│       │   api.js
│       │   ProductList.jsx
│       │
│       └───__tests__
│               productApi.test.js
│               ProductList.test.jsx
│
└───saleor-db-tests
        init_test_schema.sql
        run-tests.sh
        test_product_constraints.sql
        test_product_delete.sql
        test_product_insert.sql
        test_product_select.sql
        test_product_update.sql
```

---

# Tier-by-Tier Overview

## Database Tier

**Directory:** `saleor-db-tests/`

This directory contains the SQL-based unit verification of the database layer. The tests operate directly on an isolated PostgreSQL schema and validate the core persistence behavior required by the product listing flow.

### Relevant files

- `init_test_schema.sql`  
  Creates the simplified schema used in the tests and inserts deterministic seed data.

- `test_product_insert.sql`  
  Verifies that a valid product can be inserted and later retrieved.

- `test_product_select.sql`  
  Verifies filtering, lookup by slug, and join behavior with categories.

- `test_product_update.sql`  
  Verifies product updates such as name changes and publication status.

- `test_product_delete.sql`  
  Verifies product deletion and cascading deletion of related variants.

- `test_product_constraints.sql`  
  Verifies integrity rules such as `NOT NULL`, `UNIQUE`, and `FOREIGN KEY`.

- `run-tests.sh`  
  Executes the SQL suites in order using strict failure behavior.

### Isolation strategy

In this tier, the database itself is the **unit under test**, so we do not replace it with mocks or stubs. Instead, isolation is achieved through:

- a dedicated test schema,
- controlled seed data,
- direct SQL execution,
- and automated assertions that stop execution when expectations are not met.

This follows the laboratory requirement that DB unit tests must validate the DB tier directly, independently from backend code.

### Test design notes

An important improvement in this tier was turning the SQL scripts into **real automated tests** rather than manual verification queries. Instead of only printing `SELECT` results and relying on visual inspection, the scripts now include executable checks that raise exceptions when a condition is not satisfied.

This is especially relevant for:

- insert verification,
- select verification,
- update verification,
- delete verification,
- and constraint validation.

As a result, the DB suite now behaves like the other test suites: it not only runs, but also **fails automatically** when SQL behavior is incorrect. This makes the database tier consistent with the automation and isolation goals of the laboratory.

---

## Backend Tier

**Directory:** `saleor-api-tests/`

This directory contains the backend-side unit tests for resolver and query behavior. The tests simulate the minimum execution context needed by the resolver and replace persistence concerns with controlled in-memory behavior.

### Relevant files

- `product_resolver.py`  
  Contains the simplified product resolver logic and query abstractions used in the tests.

- `conftest.py`  
  Defines the shared fixtures and controlled setup used by the backend test suite.

- `test_product_resolver.py`  
  Tests resolver behavior such as retrieving products, filtering by publication state, and counting products.

- `test_product_service.py`  
  Tests the fake queryset/service behavior used to simulate the resolver’s data access path.

### Isolation strategy

The backend must not contact the real database, so this suite uses:

- a **Fake** query object (`ProductQuerySet`),
- a **Stub** resolver context (`mock_info`),
- and a **Mock** interaction verifier (`mock_info_spy`).

This allows resolver behavior to be validated independently from PostgreSQL, Django request lifecycle details, or network access.

---

## Frontend Tier

**Directory:** `saleor-dashboard-tests/`

This directory contains the frontend-side unit tests for product retrieval and rendering behavior. The tests cover both the API-consumption boundary and the UI components that render the results.

### Relevant files

- `src/api.js`  
  Contains the functions that interact with the GraphQL endpoint.

- `src/ProductList.jsx`  
  Contains the component that renders the product listing UI.

- `src/__tests__/productApi.test.js`  
  Tests API-consumption behavior, including successful responses, error responses, GraphQL errors, and pure helper functions.

- `src/__tests__/ProductList.test.jsx`  
  Tests rendering behavior such as loading state, empty state, error state, product count, and filtered fetching.

- `package.json`  
  Defines the local frontend test commands and Jest execution scripts.

### Isolation strategy

The frontend must not contact the real backend, so the suite replaces external calls with test doubles:

- a **Stub** on `global.fetch`,
- and a **Mock** on the `api` module via `jest.mock("../api")`.

This keeps the DOM and component behavior as the main unit under test and ensures deterministic frontend execution.

---

# Test Strategy Summary

| Tier | Verified Unit | Isolation Mechanism |
|---|---|---|
| Database | `product_product` SQL verification scripts | isolated schema and direct SQL assertions |
| Backend | `resolve_products()` and query behavior | fake queryset + stub + mock |
| Frontend | `fetchProducts()` / `ProductList` | fetch stub + module mock |

---

# Running the Tests

## Run all automated suites with Docker

From the project root:

```bash
docker compose -f docker-compose-tests.yml up --build saleor-db-tests saleor-api-tests saleor-fe-tests
```

### Expected result

- all three containers finish with **exit code 0**
- failures remain isolated by tier

---

## Run only the database suite

```bash
docker compose -f docker-compose-tests.yml up --build saleor-db-tests
```

---

## Run only the backend suite

```bash
cd saleor-api-tests
pip install -r requirements.txt
pytest -v
```

---

## Run only the frontend suite

```bash
cd saleor-dashboard-tests
npm install
npm test -- --watchAll=false
```

---

# Automation

The repository includes Docker-based automation for the three tiers in `docker-compose-tests.yml`.  
Each suite runs in an isolated service, which mirrors how real CI pipelines isolate failures:

- **DB tests** run against a dedicated PostgreSQL test instance,
- **backend tests** run with mocked database behavior,
- **frontend tests** run with mocked API calls.

The system is considered correctly verified only when **all three suites pass**.

---

# Result

This project demonstrates that a real open-source functional flow can be unit-tested across tiers while preserving isolation:

- the **database tier** verifies SQL behavior directly,
- the **backend tier** verifies resolver logic without a real DB,
- the **frontend tier** verifies UI/API behavior without a real backend.

The result is a reproducible automated suite suitable for software quality evaluation and direct verification of the implemented tests.
