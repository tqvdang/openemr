# Vietnamese PT E2E Tests

[AI-GENERATED: Claude Code]

This directory contains end-to-end (E2E) tests for the Vietnamese Physiotherapy module using Symfony Panther and Selenium WebDriver.

## Test Files

### AnatomySelectorTest.php
Comprehensive E2E tests for the interactive anatomy selector component:
- **testAnatomySelectorLoads()**: Verifies anatomy selector panel loads with heading and body SVG
- **testFrontBackViewToggle()**: Tests switching between front/back body views
- **testLayerToggles()**: Tests showing/hiding anatomical layers (muscles, bones, joints, etc.)
- **testZoomControls()**: Tests zoom in, zoom out, and reset functionality
- **testRegionSelection()**: Tests clicking body regions and clearing selections
- **testBreadcrumbNavigation()**: Tests breadcrumb navigation for drill-down
- **testBilingualSupport()**: Verifies Vietnamese/English bilingual UI

### AssessmentFormTest.php
Tests for Vietnamese PT Assessment form functionality.

### ExercisePrescriptionFormTest.php
Tests for Exercise Prescription form.

### TreatmentPlanFormTest.php
Tests for Treatment Plan form.

### OutcomeMeasuresFormTest.php
Tests for Outcome Measures form.

### WidgetIntegrationTest.php
Tests for patient summary widget integration.

## Running Tests

### Using Docker (Recommended)

```bash
# Start development environment
cd docker/development-easy
docker compose up -d

# Run all Vietnamese PT E2E tests
docker compose exec openemr /root/devtools e2e-test --group vietnamese-e2e

# Run only anatomy selector tests
docker compose exec openemr /root/devtools e2e-test --group anatomy-selector

# Run specific test class
docker compose exec openemr /root/devtools e2e-test tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php

# View test execution in browser
# Open: http://localhost:7900
# Password: openemr123
```

### Using PHPUnit Directly

```bash
# Run all Vietnamese PT E2E tests
./vendor/bin/phpunit --testsuite e2e --group vietnamese-e2e

# Run specific test class
./vendor/bin/phpunit tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php

# Run specific test method
./vendor/bin/phpunit --filter testAnatomySelectorLoads tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php
```

## Test Environment

### Requirements
- Docker and Docker Compose (for containerized testing)
- Selenium Grid with Chrome driver
- OpenEMR running at http://localhost:8300 (or configured base URL)

### Environment Variables

Configure in `.env` or docker-compose environment:

```bash
# Use Selenium Grid for consistent testing
SELENIUM_USE_GRID=true
SELENIUM_HOST=selenium
SELENIUM_BASE_URL=http://openemr

# Optional: Timeout configurations
SELENIUM_IMPLICIT_WAIT=30
SELENIUM_PAGE_LOAD_TIMEOUT=60

# Optional: Force headless mode (disables VNC viewing)
SELENIUM_FORCE_HEADLESS=false
```

## Test Data

Tests use the following test data:
- **Default Admin User**: admin/pass (from LoginTestData)
- **Test Patient**: Demo data from PatientTestData
- **Test Encounter**: Auto-created or uses existing

## Browser Automation

Tests use **Symfony Panther** which provides:
- Chrome/Firefox browser automation via WebDriver
- DOM crawling with Symfony DomCrawler
- JavaScript execution support
- Screenshot capture on failure
- VNC viewing for debugging (when not in headless mode)

## Debugging Tests

### View Live Test Execution

1. Ensure `SELENIUM_FORCE_HEADLESS=false` in environment
2. Start Docker environment: `docker compose up -d`
3. Open VNC viewer: http://localhost:7900
4. Enter password: `openemr123`
5. Run tests and watch execution in real-time

### Capture Screenshots

```php
// Add to test method
$this->client->takeScreenshot('/tmp/screenshot.png');
```

### Enable Verbose Output

```bash
docker compose exec openemr /root/devtools e2e-test --verbose
```

## Test Structure

All E2E tests follow this pattern:

```php
#[Test]
public function testFeatureName(): void
{
    // 1. Login
    $this->login(LoginTestData::username, LoginTestData::password);

    // 2. Navigate to feature
    $this->navigateToPatientEncounter();
    $this->openPTAssessmentForm();

    // 3. Wait for elements
    $this->waitForAnatomySelector();

    // 4. Perform actions
    $this->crawler = $this->client->refreshCrawler();
    $button = $this->crawler->filter('.some-button');
    $button->click();

    // 5. Assert results
    $this->assertGreaterThan(0, $result->count(), 'Element should exist');
}
```

## Troubleshooting

### Selenium Connection Issues
```bash
# Check Selenium is running
docker compose ps selenium

# View Selenium logs
docker compose logs selenium
```

### Timeout Errors
Increase timeout values in environment:
```bash
SELENIUM_IMPLICIT_WAIT=60
SELENIUM_PAGE_LOAD_TIMEOUT=120
```

### Element Not Found
- Check if page loaded completely
- Verify element selector is correct
- Add explicit waits before interaction
- Check iframe context (switch to correct frame)

### Vietnamese Character Display
Ensure:
- Database uses utf8mb4_vietnamese_ci collation
- Browser supports UTF-8 encoding
- Vietnamese fonts are installed in test container

## Coverage

Current coverage for Vietnamese PT E2E tests:
- Anatomy Selector: 7 test methods
- Assessment Form: 6 test methods
- Exercise Prescription: 5 test methods
- Treatment Plan: 5 test methods
- Outcome Measures: 6 test methods
- Widget Integration: 5 test methods

**Total**: 34+ E2E test methods

## CI/CD Integration

Tests can be integrated into CI pipelines:

```yaml
# .github/workflows/e2e-tests.yml
- name: Run Vietnamese PT E2E Tests
  run: |
    docker compose exec -T openemr /root/devtools e2e-test --group vietnamese-e2e
```

## Performance Considerations

- E2E tests are slower than unit tests (30-60 seconds per test)
- Run in parallel when possible using PHPUnit parallel execution
- Use test groups to run subsets during development
- Full E2E suite should run in CI/CD before merges

## Contributing

When adding new E2E tests:

1. Mark all AI-generated code with `[AI-GENERATED: Claude Code]`
2. Follow existing test patterns and naming conventions
3. Use descriptive test method names
4. Add proper PHPDoc comments
5. Use test groups for organization
6. Add assertions with clear failure messages
7. Clean up test data in tearDown()

## References

- [Symfony Panther Documentation](https://github.com/symfony/panther)
- [PHPUnit Attributes](https://docs.phpunit.de/en/10.5/attributes.html)
- [Selenium WebDriver](https://www.selenium.dev/documentation/webdriver/)
- [OpenEMR E2E Testing Guide](../../../../CONTRIBUTING.md#e2e-testing)

---

[AI-GENERATED: Claude Code] - End of README.md
