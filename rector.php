<?php

# https://getrector.com/documentation

declare(strict_types=1);

use Rector\Caching\ValueObject\Storage\FileCacheStorage;
use Rector\CodeQuality\Rector\If_\SimplifyIfElseToTernaryRector;
use Rector\Config\RectorConfig;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\ValueObject\PhpVersion;

return RectorConfig::configure()
    ->withBootstrapFiles([
        __DIR__ . '/rector-bootstrap.php',
    ])
    ->withPaths([
        __DIR__ . '/Documentation',
        __DIR__ . '/apis',
        __DIR__ . '/ccdaservice',
        __DIR__ . '/ccr',
        __DIR__ . '/contrib',
        __DIR__ . '/controllers',
        __DIR__ . '/custom',
        __DIR__ . '/gacl',
        __DIR__ . '/interface',
        __DIR__ . '/library',
        __DIR__ . '/modules',
        __DIR__ . '/oauth2',
        __DIR__ . '/portal',
        __DIR__ . '/sites',
        __DIR__ . '/sphere',
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->withCache(
        // ensure file system caching is used instead of in-memory
        cacheClass: FileCacheStorage::class,
        // specify a path that works locally as well as on CI job runners
        cacheDirectory: '/tmp/rector'
    )
    ->withCodeQualityLevel(5)
    ->withConfiguredRule(ClassPropertyAssignToConstructorPromotionRector::class, [
        'allow_model_based_classes' => true,
        'inline_public' => false,
        'rename_property' => true,
    ])
    ->withDeadCodeLevel(5)
    // https://getrector.com/documentation/troubleshooting-parallel
    ->withParallel(
        timeoutSeconds: 120,
        maxNumberOfProcess: 12,
        jobSize: 12
    )
    // FIXME rector should pick the php version from composer.json
    // but that doesn't seem to be working, so hard-coding for now.
    ->withPhpVersion(PhpVersion::PHP_82)
    ->withRules([
        // add rules one at a time until we can replace them with a named ruleset
        SimplifyIfElseToTernaryRector::class,
    ])
    ->withPhpSets()
    ->withSkip([
        __DIR__ . '/sites/default/documents/smarty',
        // Vietnamese PT module uses legacy patterns consistent with codebase
        __DIR__ . '/src/RestControllers/VietnamesePT',
        __DIR__ . '/src/Services/VietnamesePT',
        __DIR__ . '/src/Validators/VietnamesePT',
        __DIR__ . '/interface/forms/vietnamese_pt_assessment',
        __DIR__ . '/interface/forms/vietnamese_pt_exercise',
        __DIR__ . '/interface/forms/vietnamese_pt_outcome',
        __DIR__ . '/interface/forms/vietnamese_pt_treatment_plan',
        __DIR__ . '/library/custom/vietnamese_pt_widget.php',
        __DIR__ . '/tests/Tests/E2e/VietnamesePT',
        __DIR__ . '/tests/Tests/Api/VietnamesePT',
        __DIR__ . '/tests/Tests/Unit/Vietnamese',
        __DIR__ . '/tests/Tests/Services/Vietnamese',
        __DIR__ . '/tests/Tests/RestControllers/VietnamesePT',
        __DIR__ . '/tests/Tests/Validators/VietnamesePT',
    ])
    ->withTypeCoverageLevel(5);
