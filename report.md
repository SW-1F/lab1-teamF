# Unit Test Extension Report

**Course:** Software Quality — SQ_2026i
**Team:** F
**System:** [saleor/saleor-platform](https://github.com/saleor/saleor-platform)
**Functional flow:** Product Listing — Dashboard → API resolver → Database
**Tiers covered:** Frontend (React/Jest) ↔ Backend (Python/pytest) ↔ Database (PostgreSQL/SQL)

---

## 1. Architectural Benefit of Enforcing Isolation in Unit Tests

Enforcing isolation means each unit (DB, API resolver, Dashboard component) is tested using **test doubles** instead of real collaborators. No unit test contacts a running service from another tier.

**Benefit:** Tests become **fast, deterministic, and independent of deployment state.** The full suite runs in seconds without Docker, a live database, or a running API. Failures are immediately localized to a single tier — if `resolve_products` breaks, only its test fails, not the frontend tests. This maps directly to the *Test Isolation* and *Single Responsibility* principles.

**What would be lost:** Tests would become **integration tests masquerading as unit tests.** A schema change in the DB would cascade into failing API and FE tests, making the root cause impossible to pinpoint quickly. Non-deterministic container startup races would produce flaky results, eroding confidence in the suite and discouraging frequent runs.

---

## 2. Test Doubles Applied per Tier

### Unit 1 — `ProductQuerySet` (API Tier, Python)

| | |
|---|---|
| **Test double** | **Fake** |
| **Implementation** | `ProductQuerySet`: in-memory list implementing `.all()`, `.filter()`, `.get()`, `.count()`, `.order_by()` — the same interface as Django's QuerySet. |
| **Justification** | The resolver calls `manager.filter(is_published=…)`. A Fake allows full behavioural coverage of the filtering logic without an ORM or a running PostgreSQL instance. A Mock would over-specify internals; a Fake gives state-based correctness without coupling tests to ORM implementation details. Technique: **State-based testing with a Fake Object** (Freeman & Pryce, *GOOS*). |

### Unit 2 — `resolve_products()` resolver (API Tier, Python)

| | |
|---|---|
| **Test double** | **Stub** (`mock_info`) + **Mock** (`mock_info_spy`) |
| **Implementation** | `mock_info`: a `MagicMock` with a real `ProductManager` injected — provides controlled context without a full Django request lifecycle. `mock_info_spy`: a fully mocked info object used to assert that `.all()` is called exactly once and `.filter()` is called with the correct arguments. |
| **Justification** | Two complementary techniques are needed: the Stub tests *what the resolver returns* (state verification), while the Mock tests *how it delegates* to the manager (interaction/behaviour verification). Together they cover both contracts of the unit. Technique: **Interaction-based testing / Behaviour Verification** (Fowler, *Mocks Aren't Stubs*). |

### Unit 3 — `fetchProducts()` in `api.js` (Frontend Tier, JavaScript)

| | |
|---|---|
| **Test double** | **Stub** (`global.fetch`) + **Mock** (`jest.mock("../api")`) |
| **Implementation** | In `productApi.test.js`, `global.fetch` is replaced with `jest.fn()` returning a controlled `Promise.resolve` with deterministic product data. In `ProductList.test.jsx`, the entire `api` module is replaced via `jest.mock("../api")` so `fetchProducts` is a `jest.fn()` whose resolved value each test controls independently. |
| **Justification** | `fetchProducts` fires a real HTTP POST to the Saleor GraphQL endpoint. The Stub on `fetch` prevents any network call, satisfying the isolation rule. Mocking at the module boundary (rather than at `fetch`) is more idiomatic for component tests: it decouples the component from `api.js` internals entirely, which is the correct isolation level for testing rendering behaviour. Technique: **Test Stub for external dependency** and **Mock Object at module boundary** (Meszaros, *xUnit Patterns*). |
