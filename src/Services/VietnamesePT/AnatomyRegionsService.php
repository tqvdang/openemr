<?php

/**
 * Anatomy Regions Service
 * Manages anatomical region hierarchy for PT assessment visualization
 *
 * [AI-GENERATED: Claude Code]
 *
 * @package   OpenEMR
 * @link      https://www.open-emr.org
 * @author    Dang Tran <tqvdang@msn.com>
 * @copyright Copyright (c) 2025 Dang Tran
 * @license   https://github.com/openemr/openemr/blob/master/LICENSE GNU General Public License 3
 */

namespace OpenEMR\Services\VietnamesePT;

use OpenEMR\Common\Database\QueryUtils;
use OpenEMR\Common\Logging\SystemLogger;
use OpenEMR\Services\BaseService;
use OpenEMR\Validators\ProcessingResult;

class AnatomyRegionsService extends BaseService
{
    private const REGIONS_TABLE = "anatomy_regions";

    public function __construct()
    {
        parent::__construct(self::REGIONS_TABLE);
    }

    /**
     * Get all active anatomy regions
     *
     * @return ProcessingResult
     */
    public function getAll($search = array(), $isAndCondition = true): ProcessingResult
    {
        $processingResult = new ProcessingResult();

        try {
            $sql = "SELECT * FROM " . self::REGIONS_TABLE . " WHERE is_active = 1 ORDER BY display_order ASC";

            $statementResults = QueryUtils::sqlStatementThrowException($sql, []);

            while ($row = sqlFetchArray($statementResults)) {
                $processingResult->addData($this->createResultRecordFromDatabaseResult($row));
            }
        } catch (\Exception $e) {
            SystemLogger::instance()->error('AnatomyRegions getAll failed', [
                'error' => $e->getMessage()
            ]);
            $processingResult->addInternalError('Failed to retrieve anatomy regions: ' . $e->getMessage());
        }

        return $processingResult;
    }

    /**
     * Get a single anatomy region by code
     *
     * @param string $code Region code
     * @return ProcessingResult
     */
    public function getByCode($code): ProcessingResult
    {
        $processingResult = new ProcessingResult();

        try {
            $sql = "SELECT * FROM " . self::REGIONS_TABLE . " WHERE code = ? AND is_active = 1 LIMIT 1";

            $result = QueryUtils::sqlQueryThrowException($sql, [$code]);

            if ($result) {
                $processingResult->addData($this->createResultRecordFromDatabaseResult($result));
            }
        } catch (\Exception $e) {
            SystemLogger::instance()->error('AnatomyRegions getByCode failed', [
                'code' => $code,
                'error' => $e->getMessage()
            ]);
            $processingResult->addInternalError('Failed to retrieve anatomy region: ' . $e->getMessage());
        }

        return $processingResult;
    }

    /**
     * Get child regions by parent ID
     *
     * @param int $parentId Parent region ID
     * @return ProcessingResult
     */
    public function getByParent($parentId): ProcessingResult
    {
        $processingResult = new ProcessingResult();

        try {
            $sql = "SELECT * FROM " . self::REGIONS_TABLE . " WHERE parent_id = ? AND is_active = 1 ORDER BY display_order ASC";

            $statementResults = QueryUtils::sqlStatementThrowException($sql, [$parentId]);

            while ($row = sqlFetchArray($statementResults)) {
                $processingResult->addData($this->createResultRecordFromDatabaseResult($row));
            }
        } catch (\Exception $e) {
            SystemLogger::instance()->error('AnatomyRegions getByParent failed', [
                'parent_id' => $parentId,
                'error' => $e->getMessage()
            ]);
            $processingResult->addInternalError('Failed to retrieve child regions: ' . $e->getMessage());
        }

        return $processingResult;
    }

    /**
     * Get hierarchical tree structure
     *
     * @param int|null $parentId Root parent ID (null for top level)
     * @return ProcessingResult
     */
    public function getHierarchy($parentId = null): ProcessingResult
    {
        $processingResult = new ProcessingResult();

        try {
            // Get all regions
            $allResult = $this->getAll();

            if ($allResult->hasErrors()) {
                return $allResult;
            }

            $allRegions = $allResult->getData();

            // Build hierarchy tree
            $tree = $this->buildTree($allRegions, $parentId);

            foreach ($tree as $node) {
                $processingResult->addData($node);
            }
        } catch (\Exception $e) {
            SystemLogger::instance()->error('AnatomyRegions getHierarchy failed', [
                'parent_id' => $parentId,
                'error' => $e->getMessage()
            ]);
            $processingResult->addInternalError('Failed to build hierarchy: ' . $e->getMessage());
        }

        return $processingResult;
    }

    /**
     * Search regions by name (English or Vietnamese)
     *
     * @param string $searchTerm Search term
     * @param string $language Language preference ('en' or 'vi')
     * @return ProcessingResult
     */
    public function search($searchTerm, $language = 'en'): ProcessingResult
    {
        $processingResult = new ProcessingResult();

        try {
            $searchPattern = '%' . $searchTerm . '%';

            if ($language === 'vi') {
                $sql = "SELECT * FROM " . self::REGIONS_TABLE . "
                        WHERE name_vi LIKE ? AND is_active = 1
                        ORDER BY display_order ASC";
            } else {
                $sql = "SELECT * FROM " . self::REGIONS_TABLE . "
                        WHERE name_en LIKE ? AND is_active = 1
                        ORDER BY display_order ASC";
            }

            $statementResults = QueryUtils::sqlStatementThrowException($sql, [$searchPattern]);

            while ($row = sqlFetchArray($statementResults)) {
                $processingResult->addData($this->createResultRecordFromDatabaseResult($row));
            }
        } catch (\Exception $e) {
            SystemLogger::instance()->error('AnatomyRegions search failed', [
                'searchTerm' => $searchTerm,
                'language' => $language,
                'error' => $e->getMessage()
            ]);
            $processingResult->addInternalError('Failed to search regions: ' . $e->getMessage());
        }

        return $processingResult;
    }

    /**
     * Build hierarchical tree structure from flat array
     *
     * @param array $elements Flat array of regions
     * @param int|null $parentId Parent ID to start from
     * @return array Tree structure
     */
    private function buildTree(array $elements, $parentId = null): array
    {
        $branch = [];

        foreach ($elements as $element) {
            $elementParentId = $element['parent_id'] ?? null;

            // Match parent (null matches null for root)
            if ($elementParentId == $parentId) {
                $children = $this->buildTree($elements, $element['id']);

                if ($children) {
                    $element['children'] = $children;
                }

                $branch[] = $element;
            }
        }

        return $branch;
    }

    /**
     * Create result record from database result
     *
     * @param array $row Database row
     * @return array Formatted result record
     */
    protected function createResultRecordFromDatabaseResult($row): array
    {
        return [
            'id' => $row['id'] ?? null,
            'parent_id' => $row['parent_id'] ?? null,
            'code' => $row['code'] ?? '',
            'name_en' => $row['name_en'] ?? '',
            'name_vi' => $row['name_vi'] ?? '',
            'level' => (int)($row['level'] ?? 1),
            'structure_type' => $row['structure_type'] ?? 'region',
            'svg_file' => $row['svg_file'] ?? null,
            'svg_element_id' => $row['svg_element_id'] ?? null,
            'fma_id' => $row['fma_id'] ?? null,
            'display_order' => (int)($row['display_order'] ?? 0),
            'is_active' => (bool)($row['is_active'] ?? true),
            'created_at' => $row['created_at'] ?? null,
            'updated_at' => $row['updated_at'] ?? null
        ];
    }
}
// [AI-GENERATED: Claude Code]
