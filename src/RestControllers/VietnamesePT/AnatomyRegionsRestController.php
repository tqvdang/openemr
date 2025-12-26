<?php

/**
 * Anatomy Regions REST Controller
 * Exposes anatomy region hierarchy endpoints for PT visualization
 *
 * [AI-GENERATED: Claude Code]
 *
 * @package   OpenEMR
 * @link      https://www.open-emr.org
 * @author    Dang Tran <tqvdang@msn.com>
 * @copyright Copyright (c) 2025 Dang Tran
 * @license   https://github.com/openemr/openemr/blob/master/LICENSE GNU General Public License 3
 */

namespace OpenEMR\RestControllers\VietnamesePT;

use OpenEMR\Services\VietnamesePT\AnatomyRegionsService;
use OpenEMR\RestControllers\RestControllerHelper;

class AnatomyRegionsRestController
{
    private $service;

    public function __construct()
    {
        $this->service = new AnatomyRegionsService();
    }

    /**
     * Get all anatomy regions
     *
     * @return array HTTP response
     */
    public function getAll()
    {
        $processingResult = $this->service->getAll();
        return RestControllerHelper::handleProcessingResult($processingResult, 200, true);
    }

    /**
     * Get a single anatomy region by code
     *
     * @param string $code Region code
     * @return array HTTP response
     */
    public function getOne($code)
    {
        $processingResult = $this->service->getByCode($code);

        if (!$processingResult->hasErrors() && count($processingResult->getData()) == 0) {
            return RestControllerHelper::handleProcessingResult($processingResult, 404);
        }

        return RestControllerHelper::handleProcessingResult($processingResult, 200);
    }

    /**
     * Get child regions by parent ID
     *
     * @param int $parentId Parent region ID
     * @return array HTTP response
     */
    public function getChildren($parentId)
    {
        $processingResult = $this->service->getByParent($parentId);
        return RestControllerHelper::handleProcessingResult($processingResult, 200, true);
    }

    /**
     * Get hierarchical tree structure
     *
     * @param int|null $parentId Root parent ID (null for top level)
     * @return array HTTP response
     */
    public function getHierarchy($parentId = null)
    {
        $processingResult = $this->service->getHierarchy($parentId);
        return RestControllerHelper::handleProcessingResult($processingResult, 200, true);
    }

    /**
     * Search regions by name
     *
     * @param string $term Search term
     * @param string $language Language preference ('en' or 'vi')
     * @return array HTTP response
     */
    public function search($term, $language = 'en')
    {
        $processingResult = $this->service->search($term, $language);
        return RestControllerHelper::handleProcessingResult($processingResult, 200, true);
    }
}
// [AI-GENERATED: Claude Code]
