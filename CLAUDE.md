# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

OpenEMR is a Free and Open Source electronic health records (EHR) and medical practice management application. It uses a hybrid modern/legacy architecture with:
- **Modern layer** (`src/`): PSR-4 namespaced PHP with Symfony components, REST APIs, FHIR support
- **Legacy layer** (`library/`, `interface/`): Procedural PHP for backward compatibility
- **Frontend**: Bootstrap 4, Angular.js, jQuery, SCSS via Gulp
- **Database**: MySQL/MariaDB via ADODB library

### Vietnamese Physiotherapy Customization

This fork includes a **complete Vietnamese Physiotherapy module** with:
- **Bilingual UI**: Full Vietnamese/English parallel support with utf8mb4_vietnamese_ci collation
- **8 Service classes** with CRUD operations and event dispatching
- **4 Validators** for data integrity
- **8 REST Controllers** exposing 40+ API endpoints
- **4 Complete form modules**: PT Assessment, Exercise Prescription, Treatment Plan, Outcome Measures
- **Patient summary widget** with quick access to PT features
- **Medical terminology translation service** with 52+ pre-loaded Vietnamese medical terms
- **90 comprehensive tests** with 100% coverage
- **Specialized Docker environment** for Vietnamese PT development

See `Documentation/physiotherapy/` for complete physiotherapy documentation.

## Building and Development

### Initial Setup
```bash
# Build OpenEMR (requires Node.js 22.x)
composer install --no-dev
npm install
npm run build
composer dump-autoload -o
```

### Docker Development Environment (Recommended)

**Standard OpenEMR:**
```bash
cd docker/development-easy
docker compose up

# Access:
# - OpenEMR: http://localhost:8300 (admin/pass)
# - phpMyAdmin: http://localhost:8310
# - MySQL: localhost:8320 (openemr/openemr)
```

**Vietnamese Physiotherapy Development (Hybrid):**
```bash
cd docker/development-physiotherapy
./scripts/start-dev.sh

# Hybrid architecture: Local PHP + Docker services
# Access:
# - MariaDB: localhost:3306 (openemr/openemr123!)
# - phpMyAdmin: http://localhost:8081
# - Adminer: http://localhost:8082
# - Redis: localhost:6379
# - MailHog: http://localhost:8025

# Vietnamese database tools
./scripts/vietnamese-db-tools.sh

# See docker/development-physiotherapy/README.md for details
```

### Development Commands
```bash
# Frontend development
npm run dev              # Watch SCSS and rebuild
npm run build            # Production build
npm run gulp-build       # Build themes
npm run gulp-watch       # Watch for changes

# Linting and code style
npm run lint:js          # ESLint check
npm run lint:js-fix      # Auto-fix JS issues
npm run stylelint        # Check SCSS/CSS
npm run stylelint-fix    # Auto-fix style issues

# Testing
npm run test:js          # Run Jest tests
npm run test:js-coverage # Jest with coverage

# PHP testing (via Docker)
docker compose exec openemr /root/devtools unit-test
docker compose exec openemr /root/devtools api-test
docker compose exec openemr /root/devtools e2e-test
docker compose exec openemr /root/devtools services-test
docker compose exec openemr /root/devtools fixtures-test
docker compose exec openemr /root/devtools validators-test
docker compose exec openemr /root/devtools controllers-test
docker compose exec openemr /root/devtools common-test

# PHP code quality
docker compose exec openemr /root/devtools psr12-fix        # Fix PSR-12 issues
docker compose exec openemr /root/devtools psr12-report     # PSR-12 report
docker compose exec openemr /root/devtools php-parserror    # Check syntax
docker compose exec openemr /root/devtools rector-process   # Apply Rector refactors

# Run all tests and fixes
docker compose exec openemr /root/devtools clean-sweep       # All fixes + tests
docker compose exec openemr /root/devtools clean-sweep-tests # All tests only
```

### Theme Development
When changing SCSS files in `interface/themes/`:
```bash
docker compose exec openemr /root/devtools build-themes
# Or locally:
npm run dev  # Auto-rebuild on changes
```

## Architecture

### Directory Structure

#### `src/` - Modern PHP Application (PSR-4)
- **RestControllers/**: REST API endpoint handlers
  - Each resource has a controller (e.g., `PatientRestController`, `AppointmentRestController`)
  - Controllers delegate to Services
- **Services/**: Business logic layer
  - Extend `BaseService` for CRUD operations
  - Pattern: `insert()`, `getOne()`, `getAll()`, `update()`, `delete()`
  - Dispatch domain events via Symfony EventDispatcher
  - Return `ProcessingResult` objects
- **Validators/**: Input validation
  - Extend `BaseValidator`
  - Validate data before service operations
- **Events/**: Domain events for pub-sub pattern
  - `BeforePatientCreatedEvent`, `PatientCreatedEvent`, etc.
  - Organized by domain (Patient/, User/, Facility/, etc.)
- **Common/**: Shared infrastructure
  - Auth/ (OAuth2, OpenID Connect)
  - Database/ (QueryUtils)
  - Logging/ (SystemLogger, EventAuditLogger)
  - Acl/ (Access Control Lists)
  - CSRF, Encryption, Session management
- **FHIR/**: FHIR R4 specification implementation
  - Services transform internal data to FHIR format
  - Full US Core 3.1 IG compliance

#### `interface/` - Traditional UI Layer
- **globals.php**: **CRITICAL** - Must be included first on every traditional page
  - Initializes database connection
  - Sets up authentication
  - Loads site configuration
  - Sets `$GLOBALS` array
- **forms/**: 41+ clinical form types (LBF, clinical_notes, fee_sheet, etc.)
- **themes/**: SCSS source files
  - `core/`: Shared styles
  - `light/`: Default theme
  - `colors/`: Color variations
  - Build via Gulp to `public/assets/`
- **main/**: Core UI pages (patient summary, charts, calendar, etc.)

#### `library/` - Legacy PHP Utilities
- **sql.inc.php**: Global database wrapper functions
  - `sqlStatement()`, `sqlQuery()`, `sqlInsert()`, `sqlUpdate()`
  - Wraps ADODB library
- **classes/**: Legacy OOP code
- **.inc.php files**: Procedural utility functions
  - `appointments.inc.php`, `auth.inc.php`, `clinical_rules.php`, etc.

#### `apis/` - REST API Entry Point
- **dispatch.php**: Main REST router for all `/apis/*` requests
- **routes/**: Route definitions
  - `_rest_routes_standard.inc.php`: Standard API routes
  - `_rest_routes_fhir_r4_us_core_3_1_0.inc.php`: FHIR routes
  - `_rest_routes_portal.inc.php`: Patient portal routes

#### `portal/` - Patient Portal
- Separate patient-facing UI
- Own authentication system
- REST API endpoints for patient data

#### Other Key Directories
- **modules/custom_modules/**: Extensibility via custom modules
- **sql/**: Database schema and migrations
- **sites/**: Multi-site configurations (`sqlconf.php` per site)
- **tests/**: PHPUnit test suites
- **public/**: Static assets (compiled CSS, JS, images)
- **ccdaservice/**: C-CDA document generation
- **docker/**: Docker development environments

### Request Flow

#### REST API Request Flow
```
HTTP Request → apis/dispatch.php
             → ApiApplication::run()
             → Event Listeners:
                - SiteSetupListener (DB connection)
                - CORSListener (CORS headers)
                - OAuth2AuthorizationListener (auth)
                - AuthorizationListener (ACL check)
                - RoutesExtensionListener (route match)
             → ControllerResolver
             → RestController method (e.g., PatientRestController::getOne())
             → Service method (e.g., PatientService::getOne())
             → ProcessingResult returned
             → ViewRendererListener (format response)
             → HTTP Response (JSON/XML)
```

#### Traditional Page Request Flow
```
HTTP Request → interface/some/page.php
             → include interface/globals.php (MUST BE FIRST)
             → authenticate_user()
             → Use library/*.inc.php for data
             → Render HTML
```

### Service Layer Pattern

All modern business logic follows this pattern:

```php
// Example: PatientService::insert()
public function insert($data): ProcessingResult {
    $result = new ProcessingResult();

    // 1. Validate
    $validationResult = $this->validator->validate($data);
    if (!$validationResult->isValid()) {
        return $validationResult;
    }

    // 2. Fire "before" event
    $this->eventDispatcher->dispatch(new BeforePatientCreatedEvent($data));

    // 3. Database operation
    try {
        // ... insert to database
        $result->setData($insertedData);

        // 4. Fire "after" event
        $this->eventDispatcher->dispatch(
            new PatientCreatedEvent($insertedData),
            PatientCreatedEvent::EVENT_HANDLE
        );
    } catch (Exception $e) {
        $result->addInternalError($e->getMessage());
    }

    return $result;
}
```

### Database Access

**Legacy pattern** (used in `interface/`, `library/`):
```php
global $database;
$result = sqlQuery("SELECT * FROM patient_data WHERE pid = ?", [$pid]);
```

**Modern pattern** (used in `src/Services/`):
```php
// Via QueryUtils
$fields = QueryUtils::listTableFields($table);
// Or direct ADODB access
$result = $this->database->Execute($sql, $params);
```

### Event System

Modules and customizations hook into core operations via events:

```php
// In module's openemr.bootstrap.php:
$dispatcher = $GLOBALS['kernel']->getEventDispatcher();
$dispatcher->addListener(
    PatientCreatedEvent::EVENT_HANDLE,
    function($event) {
        $patientData = $event->getPatientData();
        // Custom logic here
    }
);
```

### Access Control (ACL)

Check permissions using:
```php
use OpenEMR\Common\Acl\AclMain;

if (!AclMain::aclCheck('patients', 'demo', false)) {
    throw new AccessDeniedException('Access Denied');
}
```

ACL sections: `patients`, `admin`, `billing`, `encounters`, etc.

#### GACL (Generic Access Control Lists) Architecture

OpenEMR uses phpGACL for access control with these key tables:

| Table | Purpose |
|-------|---------|
| `gacl_aro_groups` | User groups (ARO = Access Request Objects) |
| `gacl_aro` | Individual users mapped to groups |
| `gacl_groups_aro_map` | Links users to groups |
| `gacl_acl` | ACL entries defining permission levels |
| `gacl_aro_groups_map` | Links ACL entries to ARO groups |
| `gacl_aco_map` | ACO (Access Control Objects) - actual permissions |

**Nested Set Model**: GACL uses nested set for group hierarchy. Each group has `lft` and `rgt` values that MUST be within the parent's range:
```
Parent: lft=1, rgt=14
  └── Child: lft=12, rgt=13  ✓ Valid (within 1-14)
  └── Child: lft=15, rgt=16  ✗ Invalid (outside parent range)
```

**Creating Custom ACL Groups** (e.g., Physiotherapist):
```sql
-- 1. Get parent info
SET @parent_id = (SELECT id FROM gacl_aro_groups WHERE value = 'users');
SET @parent_rgt = (SELECT rgt FROM gacl_aro_groups WHERE id = @parent_id);

-- 2. Create group with nested set values WITHIN parent range
INSERT INTO gacl_aro_groups (id, parent_id, name, value, lft, rgt)
VALUES (@new_id, @parent_id, 'Physiotherapist', 'physio', @parent_rgt, @parent_rgt + 1);

-- 3. Expand parent's rgt
UPDATE gacl_aro_groups SET rgt = rgt + 2 WHERE id = @parent_id;

-- 4. Create ACL entries for 4 permission levels (view, addonly, wsome, write)
-- 5. Link ACL entries to group via gacl_aro_groups_map
-- 6. Copy ACO permissions from similar group (e.g., Clinicians)
```

See `infrastructure/homelab/k8s/overlays/dev/pt-sql-configmap.yaml` → `07-pt-acl-group.sql` for complete implementation.

### API Documentation

- OpenAPI/Swagger definitions in route files
- Swagger UI: `/swagger/` (when running)
- Register OAuth2 client for testing:
  ```bash
  docker compose exec openemr /root/devtools register-oauth2-client
  ```

## Testing

### Test Organization
- **Unit tests**: `tests/Tests/Unit/`
- **API tests**: `tests/Tests/Api/`
- **E2E tests**: `tests/Tests/E2e/` (uses Symfony Panther)
- **Service tests**: `tests/Tests/Services/`
- **Validator tests**: `tests/Tests/Validators/`
- **Controller tests**: `tests/Tests/RestControllers/`
- **Vietnamese PT tests**: `tests/Tests/Vietnamese/` and `tests/Tests/Services/Vietnamese/`

### Running Tests Locally (Docker)
```bash
# Individual test suites
docker compose exec openemr /root/devtools unit-test
docker compose exec openemr /root/devtools api-test
docker compose exec openemr /root/devtools e2e-test

# View E2E tests in real-time
# Browser: http://localhost:7900 (password: openemr123)

# All automated tests
docker compose exec openemr /root/devtools clean-sweep-tests
```

### Running Tests Without Docker
```bash
# Requires phpunit.xml configuration
./vendor/bin/phpunit --testsuite unit
./vendor/bin/phpunit --testsuite api
```

## Code Style and Standards

### Development Philosophy

**Fastest, Simple, Minimal Change - But Solid**

When implementing solutions, prioritize:
1. **Speed**: Choose the fastest path to a working solution
2. **Simplicity**: Keep code simple and straightforward
3. **Minimal Change**: Touch as few files as possible, modify existing patterns rather than creating new ones
4. **Solid Code**: No hacks, no shortcuts that compromise:
   - Security (validation, sanitization, ACL checks)
   - Data integrity (proper validation, transactions where needed)
   - Maintainability (follow existing patterns, clear variable names)
   - Error handling (proper try/catch, meaningful error messages)

**Examples:**
- ✅ Extend existing service class rather than create new architecture
- ✅ Add field to existing form rather than create new form
- ✅ Use existing REST route pattern rather than invent new one
- ✅ Follow BaseService patterns for CRUD operations
- ❌ Don't add unnecessary abstractions or "future-proof" code
- ❌ Don't refactor working code unless explicitly requested
- ❌ Don't add features beyond what's requested
- ❌ Don't skip validation/sanitization for speed

### AI-Generated Code Marking
Per `.github/copilot-instructions.md`, all AI-generated code must be clearly marked:
- Add comments at beginning/end of AI-generated code blocks
- Add end-of-line comments for single lines
- Include notes about AI generation in documentation
- Be specific about which parts were AI-generated

### PHP Standards
- PSR-12 code style
- PHP 8.2+ required
- Run `psr12-fix` before committing:
  ```bash
  docker compose exec openemr /root/devtools psr12-fix
  ```

### JavaScript/SCSS Standards
- ESLint configuration in `eslint.config.mjs`
- Stylelint for SCSS/CSS
- Fix issues before committing:
  ```bash
  npm run lint:js-fix
  npm run stylelint-fix
  ```

## Vietnamese Physiotherapy Module

### Architecture

The Vietnamese PT module follows OpenEMR's modern architecture patterns:

**Location**: All PT code is namespaced under `VietnamesePT/`
- **Services**: `src/Services/VietnamesePT/` (8 services)
- **Controllers**: `src/RestControllers/VietnamesePT/` (8 controllers)
- **Validators**: `src/Validators/VietnamesePT/` (4 validators)
- **Forms**: `interface/forms/vietnamese_pt_*/` (4 forms)
- **Widget**: `library/custom/vietnamese_pt_widget.php`
- **Tests**: `tests/Tests/Services/Vietnamese/` and `tests/Tests/Vietnamese/`

**Database Tables** (all with utf8mb4_vietnamese_ci collation):
- `vietnamese_test` - Vietnamese character support testing
- `vietnamese_medical_terms` - Bilingual medical terminology (52+ terms)
- `pt_assessments_bilingual` - PT assessments with EN/VI fields
- `pt_exercise_prescriptions_bilingual` - Exercise prescriptions
- `pt_treatment_plans_bilingual` - Treatment plans
- `pt_outcome_measures_bilingual` - Outcome tracking
- `pt_treatment_sessions_bilingual` - Treatment session notes
- `pt_assessment_templates_bilingual` - Assessment templates

### Key Features

**Bilingual Support**:
- All data entry fields have both English and Vietnamese versions
- Language preference selection per form
- Medical terminology translation service via stored procedures
- Vietnamese collation for proper sorting and searching

**Form Modules**:
1. **PT Assessment** - Comprehensive assessment with pain visualization
2. **Exercise Prescription** - Exercise programs with sets/reps/frequency
3. **Treatment Plan** - Treatment planning with status tracking
4. **Outcome Measures** - Progress tracking (ROM, strength, pain, function, balance)

**REST API Endpoints**:
All endpoints follow `/apis/default/vietnamese-pt/*` pattern:
- `/vietnamese-pt/assessment` - PT assessments CRUD
- `/vietnamese-pt/exercise` - Exercise prescriptions CRUD
- `/vietnamese-pt/treatment-plan` - Treatment plans CRUD
- `/vietnamese-pt/outcome` - Outcome measures CRUD
- `/vietnamese-pt/medical-terms` - Medical terminology lookup
- `/vietnamese-pt/translation` - Translation service
- `/vietnamese-pt/insurance` - Vietnamese insurance (BHYT) integration

### Working with Vietnamese PT Features

**Adding New PT Data**:
```php
use OpenEMR\Services\VietnamesePT\PTAssessmentService;

$service = new PTAssessmentService();
$result = $service->insert([
    'patient_id' => 123,
    'chief_complaint_en' => 'Lower back pain',
    'chief_complaint_vi' => 'Đau lưng dưới',
    'pain_level' => 7,
    'language_preference' => 'vi'
]);
```

**Using Medical Terms Translation**:
```sql
-- Lookup Vietnamese term
SELECT get_vietnamese_term('pain') AS vi_term;

-- Lookup English term
SELECT get_english_term('đau') AS en_term;
```

**Testing Vietnamese Features**:
```bash
# Run Vietnamese-specific tests
docker compose exec openemr /root/devtools vietnamese-test

# Or directly with phpunit
./vendor/bin/phpunit --testsuite vietnamese
```

### Vietnamese Database Configuration

The MariaDB setup includes:
- Character set: `utf8mb4`
- Collation: `utf8mb4_vietnamese_ci`
- Timezone: `Asia/Ho_Chi_Minh`
- Full-text search indexes for Vietnamese text
- Stored procedures for bilingual term lookup
- Performance optimizations for Vietnamese text processing

### Form Registration

PT forms are registered in the database and accessible via:
- Admin → Forms → Manage Forms (to enable/disable)
- Patient encounter → Add Form → Vietnamese PT forms
- Patient summary widget → Quick "Add New" buttons

## Common Development Tasks

### Adding a New REST Endpoint

1. **Create Service** in `src/Services/`:
   ```php
   class MyService extends BaseService {
       public function getOne($id): ProcessingResult { ... }
   }
   ```

2. **Create RestController** in `src/RestControllers/`:
   ```php
   class MyRestController {
       public function getOne($id) {
           $service = new MyService();
           return $service->getOne($id);
       }
   }
   ```

3. **Add Route** in `apis/routes/_rest_routes_standard.inc.php`:
   ```php
   "/my-resource/:id" => [
       "GET" => "MyRestController::getOne"
   ]
   ```

4. **Create Validator** in `src/Validators/` if needed

5. **Add Events** in `src/Events/` if needed

6. **Write Tests** in `tests/Tests/Services/` and `tests/Tests/Api/`

### Modifying Themes

1. Edit SCSS in `interface/themes/`
2. Rebuild:
   ```bash
   docker compose exec openemr /root/devtools build-themes
   # Or locally:
   npm run dev  # For watch mode
   ```
3. Clear browser cache to see changes

### Creating a Custom Form

1. Create directory in `interface/forms/my_form/`
2. Create files:
   - `new.php` - Create new form instance
   - `view.php` - View/edit form
   - `print.php` - Print form
   - `report.php` - Report view (optional)
3. Register form in database via Admin → Forms

### Database Migrations

1. Create SQL file in `sql/` (e.g., `7_0_4-to-7_0_5_upgrade.sql`)
2. Follow existing migration patterns
3. Test with:
   ```bash
   docker compose exec openemr /root/devtools dev-reset-install-demodata
   ```

## Multi-Site Support

OpenEMR supports multiple independent sites:
- Each site has config in `sites/{site-name}/sqlconf.php`
- Site selected by `?site=` parameter or HTTP_HOST
- Default site: `sites/default/`

Commands:
```bash
# List multisites
docker compose exec openemr /root/devtools list-multisites

# Create multisite bank (for testing)
docker compose exec openemr /root/devtools generate-multisite-bank 5
```

## Important Files

- **interface/globals.php**: Must include first on all traditional pages
- **apis/dispatch.php**: REST API entry point
- **src/Core/Kernel.php**: Symfony kernel, service container
- **sites/default/sqlconf.php**: Database configuration
- **composer.json** / **package.json**: Dependencies
- **.env**: Environment overrides (git-ignored)

## Kubernetes Deployment (Homelab)

### Infrastructure Overview

The Vietnamese PT customization deploys to a K3s cluster via Kustomize overlays:

```
infrastructure/homelab/k8s/
├── base/                    # Base K8s manifests
└── overlays/
    ├── dev/                 # Development environment
    │   ├── kustomization.yaml
    │   ├── pt-configmap.yaml      # sqlconf.php, menu, setup script
    │   ├── pt-sql-configmap.yaml  # SQL migration scripts
    │   └── pt-menu-standard.json  # Simplified PT menu
    └── staging/             # Staging environment (same structure)
```

### Setup Script Execution Order

SQL migrations run in numbered order via `pt-setup.sh`:

| Script | Purpose |
|--------|---------|
| `01-pt-globals.sql` | Disable unused features (prescriptions, labs, etc.) |
| `02-pt-calendar.sql` | PT appointment types and encounter types |
| `03-pt-forms.sql` | Register PT forms, disable unused forms |
| `04-pt-demographics.sql` | Simplify demographics for PT workflow |
| `05-pt-facility.sql` | Set facility name (Rehab Well) |
| `06-pt-users.sql` | Create admin users (dang.tran, hoang.tran, ben.dell) |
| `07-pt-acl-group.sql` | **Create Physiotherapist ACL group** (MUST run before staff) |
| `08-pt-staff.sql` | Create staff users, assign to Physiotherapist + Front Office |

### ConfigMaps

**openemr-pt-sql**: SQL migration scripts mounted to `/etc/openemr/pt-config/*.sql`

**openemr-pt-config**: Contains:
- `sqlconf.php` - Database connection (environment-specific)
- `menu-standard.json` - Simplified PT menu
- `pt-setup.sh` - Script that applies SQL migrations

### Deployment Commands

```bash
# Apply to dev
kubectl apply -k infrastructure/homelab/k8s/overlays/dev

# Apply to staging
kubectl apply -k infrastructure/homelab/k8s/overlays/staging

# Run PT setup manually (if needed)
kubectl exec -it deploy/openemr -n openemr-dev -- /etc/openemr/pt-config/pt-setup.sh
```

### Environment URLs

| Environment | Internal | External |
|-------------|----------|----------|
| Dev | http://192.168.10.60:30090 | https://openemr-dev.trancloud.work |
| Staging | http://192.168.10.60:30091 | https://openemr-staging.trancloud.work |

### Database

MariaDB runs on LXC container (192.168.10.30) with SSL enabled:
- Dev: `openemr_dev` / `openemr_dev`
- Staging: `openemr_staging` / `openemr_staging`

## External Documentation

- OpenEMR Wiki: https://www.open-emr.org/wiki/
- API Documentation: See `API_README.md`
- FHIR Documentation: See `FHIR_README.md`
- Docker Documentation: See `DOCKER_README.md`
- Contributing Guide: See `CONTRIBUTING.md`

### Vietnamese Physiotherapy Documentation

- **Main Hub**: `Documentation/physiotherapy/README.md`
- **Development Guide**: `Documentation/physiotherapy/development/HYBRID_DEVELOPMENT_GUIDE.md`
- **User Guides**: `Documentation/physiotherapy/user-guides/GETTING_STARTED.md`
- **Technical**: `Documentation/physiotherapy/technical/INSTALLATION.md`
- **Docker Environment**: `docker/development-physiotherapy/README.md`
- **Completion Report**: `docker/development-physiotherapy/FINAL_100_PERCENT_COMPLETE.md`
- **Implementation Guide**: `docker/development-physiotherapy/docs/IMPLEMENTATION_GUIDE.md`
- **Feature Gap Analysis**: `docker/development-physiotherapy/docs/PT_FEATURE_GAP_ANALYSIS.md`

### Kubernetes Deployment

- **K8s Manifests**: `infrastructure/homelab/k8s/`
- **Dev Overlay**: `infrastructure/homelab/k8s/overlays/dev/`
- **Staging Overlay**: `infrastructure/homelab/k8s/overlays/staging/`
- **SQL Migrations**: `pt-sql-configmap.yaml` (01-08 scripts)
- **ACL Group Setup**: `07-pt-acl-group.sql` (Physiotherapist group with nested set fix)
