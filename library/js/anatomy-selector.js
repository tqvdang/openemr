/**
 * Anatomy Selector - Interactive SVG-based drill-down body diagram
 *
 * @package   OpenEMR
 * @link      http://www.open-emr.org
 * @author    Dang Tran <tqvdang@msn.com>
 * @copyright Copyright (c) 2025 Dang Tran
 * @license   https://github.com/openemr/openemr/blob/master/LICENSE GNU General Public License 3
 *
 * Features:
 * - Multi-level drill-down: Body → Region → Sub-region → Structure
 * - Bilingual labels (English/Vietnamese)
 * - Touch and mouse support
 * - Breadcrumb navigation
 * - Selection history
 * - Integration with PT Assessment forms
 */

(function(window, document) {
    'use strict';

    // Default configuration
    const DEFAULT_CONFIG = {
        containerId: 'anatomy-selector',
        assetsPath: '/public/assets/anatomy/',
        language: 'en', // 'en' or 'vi'
        showBreadcrumb: true,
        showLegend: true,
        showLayerControls: true,
        enableTouch: true,
        highlightColor: '#4CAF50',
        hoverColor: '#81C784',
        selectedColor: '#2196F3',
        onRegionClick: null,
        onRegionHover: null,
        onSelectionChange: null,
        onDrillDown: null,
        onDrillUp: null
    };

    // Structure type colors
    const STRUCTURE_COLORS = {
        region: '#E3F2FD',
        muscle: '#FFCDD2',
        bone: '#FFF9C4',
        joint: '#C8E6C9',
        nerve: '#E1BEE7',
        vessel: '#FFCCBC',
        ligament: '#B2DFDB',
        tendon: '#F0F4C3',
        organ: '#D1C4E9'
    };

    // Bilingual labels
    const LABELS = {
        en: {
            breadcrumbHome: 'Body',
            selectView: 'Select View',
            frontView: 'Front View',
            backView: 'Back View',
            layers: 'Layers',
            muscles: 'Muscles',
            bones: 'Bones',
            joints: 'Joints',
            nerves: 'Nerves',
            vessels: 'Vessels',
            ligaments: 'Ligaments',
            tendons: 'Tendons',
            selectedRegions: 'Selected Regions',
            noSelection: 'Click on body to select regions',
            addFinding: 'Add Finding',
            severity: 'Severity',
            painLevel: 'Pain Level',
            notes: 'Notes',
            clear: 'Clear',
            save: 'Save Selection',
            zoomIn: 'Zoom In',
            zoomOut: 'Zoom Out',
            reset: 'Reset View',
            left: 'Left',
            right: 'Right',
            bilateral: 'Bilateral'
        },
        vi: {
            breadcrumbHome: 'Cơ thể',
            selectView: 'Chọn góc nhìn',
            frontView: 'Mặt trước',
            backView: 'Mặt sau',
            layers: 'Lớp',
            muscles: 'Cơ',
            bones: 'Xương',
            joints: 'Khớp',
            nerves: 'Thần kinh',
            vessels: 'Mạch máu',
            ligaments: 'Dây chằng',
            tendons: 'Gân',
            selectedRegions: 'Vùng đã chọn',
            noSelection: 'Nhấp vào cơ thể để chọn vùng',
            addFinding: 'Thêm phát hiện',
            severity: 'Mức độ nghiêm trọng',
            painLevel: 'Mức độ đau',
            notes: 'Ghi chú',
            clear: 'Xóa',
            save: 'Lưu lựa chọn',
            zoomIn: 'Phóng to',
            zoomOut: 'Thu nhỏ',
            reset: 'Đặt lại',
            left: 'Trái',
            right: 'Phải',
            bilateral: 'Hai bên'
        }
    };

    /**
     * AnatomySelector Class
     */
    class AnatomySelector {
        constructor(config = {}) {
            this.config = { ...DEFAULT_CONFIG, ...config };
            this.container = null;
            this.svgContainer = null;
            this.currentSvg = null;
            this.currentLevel = 0;
            this.navigationStack = [];
            this.selections = [];
            this.regionsData = {};
            this.visibleLayers = ['muscle', 'bone', 'joint', 'ligament', 'tendon'];

            this.init();
        }

        /**
         * Initialize the anatomy selector
         */
        init() {
            this.container = document.getElementById(this.config.containerId);
            if (!this.container) {
                console.error('AnatomySelector: Container not found:', this.config.containerId);
                return;
            }

            this.createUI();
            this.loadRegionsData();
            this.loadInitialView();
            this.bindEvents();
        }

        /**
         * Create the UI structure
         */
        createUI() {
            const labels = LABELS[this.config.language] || LABELS.en;

            this.container.innerHTML = `
                <div class="anatomy-selector-wrapper">
                    <!-- Header with view selector and breadcrumb -->
                    <div class="anatomy-header">
                        <div class="anatomy-view-selector">
                            <button type="button" class="view-btn active" data-view="front">
                                <i class="fa fa-user"></i> ${labels.frontView}
                            </button>
                            <button type="button" class="view-btn" data-view="back">
                                <i class="fa fa-user fa-flip-horizontal"></i> ${labels.backView}
                            </button>
                        </div>
                        <div class="anatomy-breadcrumb">
                            <span class="breadcrumb-item home" data-level="0">${labels.breadcrumbHome}</span>
                        </div>
                    </div>

                    <!-- Main content area -->
                    <div class="anatomy-content">
                        <!-- SVG display area -->
                        <div class="anatomy-svg-container">
                            <div class="anatomy-svg-wrapper" id="anatomy-svg-wrapper">
                                <div class="anatomy-loading">
                                    <i class="fa fa-spinner fa-spin"></i> Loading...
                                </div>
                            </div>
                            <div class="anatomy-zoom-controls">
                                <button type="button" class="zoom-btn" data-action="zoom-in" title="${labels.zoomIn}">
                                    <i class="fa fa-plus"></i>
                                </button>
                                <button type="button" class="zoom-btn" data-action="zoom-out" title="${labels.zoomOut}">
                                    <i class="fa fa-minus"></i>
                                </button>
                                <button type="button" class="zoom-btn" data-action="reset" title="${labels.reset}">
                                    <i class="fa fa-refresh"></i>
                                </button>
                            </div>
                        </div>

                        <!-- Side panel -->
                        <div class="anatomy-side-panel">
                            <!-- Layer controls -->
                            ${this.config.showLayerControls ? `
                            <div class="anatomy-layers">
                                <h4>${labels.layers}</h4>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="muscle" checked>
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.muscle}"></span>
                                    ${labels.muscles}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="bone" checked>
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.bone}"></span>
                                    ${labels.bones}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="joint" checked>
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.joint}"></span>
                                    ${labels.joints}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="ligament" checked>
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.ligament}"></span>
                                    ${labels.ligaments}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="tendon" checked>
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.tendon}"></span>
                                    ${labels.tendons}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="nerve">
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.nerve}"></span>
                                    ${labels.nerves}
                                </label>
                                <label class="layer-toggle">
                                    <input type="checkbox" data-layer="vessel">
                                    <span class="layer-color" style="background:${STRUCTURE_COLORS.vessel}"></span>
                                    ${labels.vessels}
                                </label>
                            </div>
                            ` : ''}

                            <!-- Selected regions list -->
                            <div class="anatomy-selections">
                                <h4>${labels.selectedRegions}</h4>
                                <div class="selections-list" id="anatomy-selections-list">
                                    <p class="no-selection">${labels.noSelection}</p>
                                </div>
                                <div class="selections-actions">
                                    <button type="button" class="btn btn-sm btn-secondary" id="anatomy-clear-btn">
                                        <i class="fa fa-times"></i> ${labels.clear}
                                    </button>
                                    <button type="button" class="btn btn-sm btn-primary" id="anatomy-save-btn">
                                        <i class="fa fa-save"></i> ${labels.save}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Finding dialog (hidden by default) -->
                    <div class="anatomy-finding-dialog" id="anatomy-finding-dialog" style="display:none;">
                        <div class="finding-dialog-content">
                            <h4 id="finding-region-name"></h4>
                            <div class="form-group">
                                <label>${labels.severity} (0-10)</label>
                                <input type="range" min="0" max="10" value="5" id="finding-severity" class="form-control">
                                <span id="finding-severity-value">5</span>
                            </div>
                            <div class="form-group">
                                <label>${labels.painLevel} (0-10)</label>
                                <input type="range" min="0" max="10" value="5" id="finding-pain" class="form-control">
                                <span id="finding-pain-value">5</span>
                            </div>
                            <div class="form-group">
                                <label>${labels.notes}</label>
                                <textarea id="finding-notes" class="form-control" rows="3"></textarea>
                            </div>
                            <div class="dialog-actions">
                                <button type="button" class="btn btn-secondary" id="finding-cancel">${labels.clear}</button>
                                <button type="button" class="btn btn-primary" id="finding-add">${labels.addFinding}</button>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            this.svgContainer = document.getElementById('anatomy-svg-wrapper');
        }

        // [AI-GENERATED: Claude Code - Start]
        /**
         * Load regions data from server with fallback chain:
         * 1. REST API: /apis/default/vietnamese-pt/anatomy/regions
         * 2. Static JSON: regions-data.json
         * 3. Embedded default data
         */
        async loadRegionsData() {
            console.log('[AnatomySelector] Loading regions data...');

            // Try REST API first
            try {
                console.log('[AnatomySelector] Attempting REST API fetch...');
                const response = await fetch('/apis/default/vietnamese-pt/anatomy/regions');
                if (response.ok) {
                    const data = await response.json();
                    this.regionsData = this.processRegionsData(data);
                    console.log('[AnatomySelector] Regions data loaded from REST API:', Object.keys(this.regionsData).length, 'regions');
                    return;
                } else {
                    console.warn('[AnatomySelector] REST API returned status:', response.status);
                }
            } catch (error) {
                console.warn('[AnatomySelector] REST API fetch failed:', error.message);
            }

            // Fallback to static JSON file
            try {
                console.log('[AnatomySelector] Attempting static JSON fetch...');
                const staticPath = this.config.assetsPath + 'regions-data.json';
                const response = await fetch(staticPath);
                if (response.ok) {
                    const data = await response.json();
                    this.regionsData = this.processRegionsData(data);
                    console.log('[AnatomySelector] Regions data loaded from static JSON:', Object.keys(this.regionsData).length, 'regions');
                    return;
                } else {
                    console.warn('[AnatomySelector] Static JSON returned status:', response.status);
                }
            } catch (error) {
                console.warn('[AnatomySelector] Static JSON fetch failed:', error.message);
            }

            // Final fallback to embedded default data
            console.log('[AnatomySelector] Using embedded default regions data');
            this.regionsData = this.getDefaultRegionsData();
            console.log('[AnatomySelector] Default regions loaded:', Object.keys(this.regionsData).length, 'regions');
        }

        /**
         * Process regions data from array format to object lookup format
         * @param {Object|Array} data - Regions data from API or JSON file
         * @returns {Object} Regions data indexed by code
         */
        processRegionsData(data) {
            // If data has a 'regions' array property (JSON file format), process it
            if (data && Array.isArray(data.regions)) {
                const processed = {};
                data.regions.forEach(region => {
                    if (region.code) {
                        processed[region.code] = region;
                    }
                });
                return processed;
            }
            // If data is already an object indexed by code, return as-is
            if (data && typeof data === 'object' && !Array.isArray(data)) {
                return data;
            }
            // If data is an array, process it
            if (Array.isArray(data)) {
                const processed = {};
                data.forEach(region => {
                    if (region.code) {
                        processed[region.code] = region;
                    }
                });
                return processed;
            }
            return {};
        }

        /**
         * Get embedded default regions data for fallback
         * @returns {Object} Default regions data indexed by code
         */
        getDefaultRegionsData() {
            return {
                // Body views
                'body_front': { code: 'body_front', name_en: 'Body (Front View)', name_vi: 'Co the (Mat truoc)', structure_type: 'region', parent_code: null, svg_file: 'body-full-front.svg', has_drill_down: false },
                'body_back': { code: 'body_back', name_en: 'Body (Back View)', name_vi: 'Co the (Mat sau)', structure_type: 'region', parent_code: null, svg_file: 'body-full-back.svg', has_drill_down: false },
                // Head and Neck
                'head_front': { code: 'head_front', name_en: 'Head (Front)', name_vi: 'Dau (Mat truoc)', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/head.svg', has_drill_down: true },
                'head_back': { code: 'head_back', name_en: 'Head (Back)', name_vi: 'Dau (Mat sau)', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/head-back.svg', has_drill_down: true },
                'neck_front': { code: 'neck_front', name_en: 'Neck (Front)', name_vi: 'Co (Mat truoc)', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/neck.svg', has_drill_down: true },
                // Spine
                'cervical_spine': { code: 'cervical_spine', name_en: 'Cervical Spine', name_vi: 'Cot song co', structure_type: 'bone', parent_code: 'body_back', svg_file: 'regions/spine-cervical.svg', has_drill_down: true },
                'thoracic_spine': { code: 'thoracic_spine', name_en: 'Thoracic Spine', name_vi: 'Cot song nguc', structure_type: 'bone', parent_code: 'body_back', svg_file: 'regions/spine-thoracic.svg', has_drill_down: true },
                'lumbar_spine': { code: 'lumbar_spine', name_en: 'Lumbar Spine', name_vi: 'Cot song that lung', structure_type: 'bone', parent_code: 'body_back', svg_file: 'regions/spine-lumbar.svg', has_drill_down: true },
                'sacrum': { code: 'sacrum', name_en: 'Sacrum', name_vi: 'Xuong cung', structure_type: 'bone', parent_code: 'body_back', svg_file: 'regions/sacrum.svg', has_drill_down: true },
                // Torso
                'chest': { code: 'chest', name_en: 'Chest', name_vi: 'Nguc', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/chest.svg', has_drill_down: true },
                'abdomen': { code: 'abdomen', name_en: 'Abdomen', name_vi: 'Bung', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/abdomen.svg', has_drill_down: true },
                'upper_back_right': { code: 'upper_back_right', name_en: 'Right Upper Back', name_vi: 'Lung tren phai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/upper-back.svg', has_drill_down: true },
                'upper_back_left': { code: 'upper_back_left', name_en: 'Left Upper Back', name_vi: 'Lung tren trai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/upper-back.svg', has_drill_down: true },
                'lower_back_right': { code: 'lower_back_right', name_en: 'Right Lower Back', name_vi: 'Lung duoi phai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/lower-back.svg', has_drill_down: true },
                'lower_back_left': { code: 'lower_back_left', name_en: 'Left Lower Back', name_vi: 'Lung duoi trai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/lower-back.svg', has_drill_down: true },
                // Shoulders
                'shoulder_right': { code: 'shoulder_right', name_en: 'Right Shoulder', name_vi: 'Vai phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/shoulder.svg', has_drill_down: true },
                'shoulder_left': { code: 'shoulder_left', name_en: 'Left Shoulder', name_vi: 'Vai trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/shoulder.svg', has_drill_down: true },
                'shoulder_right_back': { code: 'shoulder_right_back', name_en: 'Right Shoulder (Back)', name_vi: 'Vai phai (Mat sau)', structure_type: 'joint', parent_code: 'body_back', svg_file: 'regions/shoulder-back.svg', has_drill_down: true },
                'shoulder_left_back': { code: 'shoulder_left_back', name_en: 'Left Shoulder (Back)', name_vi: 'Vai trai (Mat sau)', structure_type: 'joint', parent_code: 'body_back', svg_file: 'regions/shoulder-back.svg', has_drill_down: true },
                // Upper Arms
                'upper_arm_right': { code: 'upper_arm_right', name_en: 'Right Upper Arm', name_vi: 'Canh tay phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/upper-arm.svg', has_drill_down: true },
                'upper_arm_left': { code: 'upper_arm_left', name_en: 'Left Upper Arm', name_vi: 'Canh tay trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/upper-arm.svg', has_drill_down: true },
                'triceps_right': { code: 'triceps_right', name_en: 'Right Triceps', name_vi: 'Co tam dau phai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/upper-arm-back.svg', has_drill_down: true },
                'triceps_left': { code: 'triceps_left', name_en: 'Left Triceps', name_vi: 'Co tam dau trai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/upper-arm-back.svg', has_drill_down: true },
                // Elbows
                'elbow_right': { code: 'elbow_right', name_en: 'Right Elbow', name_vi: 'Khuyu tay phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/elbow.svg', has_drill_down: true },
                'elbow_left': { code: 'elbow_left', name_en: 'Left Elbow', name_vi: 'Khuyu tay trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/elbow.svg', has_drill_down: true },
                'elbow_right_back': { code: 'elbow_right_back', name_en: 'Right Elbow (Back)', name_vi: 'Khuyu tay phai (Mat sau)', structure_type: 'joint', parent_code: 'body_back', svg_file: 'regions/elbow-back.svg', has_drill_down: true },
                'elbow_left_back': { code: 'elbow_left_back', name_en: 'Left Elbow (Back)', name_vi: 'Khuyu tay trai (Mat sau)', structure_type: 'joint', parent_code: 'body_back', svg_file: 'regions/elbow-back.svg', has_drill_down: true },
                // Forearms
                'forearm_right': { code: 'forearm_right', name_en: 'Right Forearm', name_vi: 'Cang tay phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/forearm.svg', has_drill_down: true },
                'forearm_left': { code: 'forearm_left', name_en: 'Left Forearm', name_vi: 'Cang tay trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/forearm.svg', has_drill_down: true },
                'forearm_right_back': { code: 'forearm_right_back', name_en: 'Right Forearm (Back)', name_vi: 'Cang tay phai (Mat sau)', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/forearm-back.svg', has_drill_down: true },
                'forearm_left_back': { code: 'forearm_left_back', name_en: 'Left Forearm (Back)', name_vi: 'Cang tay trai (Mat sau)', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/forearm-back.svg', has_drill_down: true },
                // Wrists
                'wrist_right': { code: 'wrist_right', name_en: 'Right Wrist', name_vi: 'Co tay phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/wrist.svg', has_drill_down: true },
                'wrist_left': { code: 'wrist_left', name_en: 'Left Wrist', name_vi: 'Co tay trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/wrist.svg', has_drill_down: true },
                // Hands
                'hand_right': { code: 'hand_right', name_en: 'Right Hand', name_vi: 'Ban tay phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/hand.svg', has_drill_down: true },
                'hand_left': { code: 'hand_left', name_en: 'Left Hand', name_vi: 'Ban tay trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/hand.svg', has_drill_down: true },
                'hand_right_back': { code: 'hand_right_back', name_en: 'Right Hand (Back)', name_vi: 'Ban tay phai (Mat sau)', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/hand-back.svg', has_drill_down: true },
                'hand_left_back': { code: 'hand_left_back', name_en: 'Left Hand (Back)', name_vi: 'Ban tay trai (Mat sau)', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/hand-back.svg', has_drill_down: true },
                // Hips and Gluteals
                'hip_right': { code: 'hip_right', name_en: 'Right Hip', name_vi: 'Hong phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/hip.svg', has_drill_down: true },
                'hip_left': { code: 'hip_left', name_en: 'Left Hip', name_vi: 'Hong trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/hip.svg', has_drill_down: true },
                'gluteal_right': { code: 'gluteal_right', name_en: 'Right Gluteal', name_vi: 'Mong phai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/gluteal.svg', has_drill_down: true },
                'gluteal_left': { code: 'gluteal_left', name_en: 'Left Gluteal', name_vi: 'Mong trai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/gluteal.svg', has_drill_down: true },
                // Thighs and Hamstrings
                'thigh_right': { code: 'thigh_right', name_en: 'Right Thigh', name_vi: 'Dui phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/thigh.svg', has_drill_down: true },
                'thigh_left': { code: 'thigh_left', name_en: 'Left Thigh', name_vi: 'Dui trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/thigh.svg', has_drill_down: true },
                'hamstring_right': { code: 'hamstring_right', name_en: 'Right Hamstring', name_vi: 'Co dui sau phai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/hamstring.svg', has_drill_down: true },
                'hamstring_left': { code: 'hamstring_left', name_en: 'Left Hamstring', name_vi: 'Co dui sau trai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/hamstring.svg', has_drill_down: true },
                // Knees
                'knee_right': { code: 'knee_right', name_en: 'Right Knee', name_vi: 'Dau goi phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/knee.svg', has_drill_down: true },
                'knee_left': { code: 'knee_left', name_en: 'Left Knee', name_vi: 'Dau goi trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/knee.svg', has_drill_down: true },
                'popliteal_right': { code: 'popliteal_right', name_en: 'Right Popliteal (Behind Knee)', name_vi: 'Hoc kheo phai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/knee-back.svg', has_drill_down: true },
                'popliteal_left': { code: 'popliteal_left', name_en: 'Left Popliteal (Behind Knee)', name_vi: 'Hoc kheo trai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/knee-back.svg', has_drill_down: true },
                // Lower Legs and Calves
                'lower_leg_right': { code: 'lower_leg_right', name_en: 'Right Lower Leg', name_vi: 'Cang chan phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/lower-leg.svg', has_drill_down: true },
                'lower_leg_left': { code: 'lower_leg_left', name_en: 'Left Lower Leg', name_vi: 'Cang chan trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/lower-leg.svg', has_drill_down: true },
                'calf_right': { code: 'calf_right', name_en: 'Right Calf', name_vi: 'Bap chan phai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/calf.svg', has_drill_down: true },
                'calf_left': { code: 'calf_left', name_en: 'Left Calf', name_vi: 'Bap chan trai', structure_type: 'muscle', parent_code: 'body_back', svg_file: 'regions/calf.svg', has_drill_down: true },
                // Ankles
                'ankle_right': { code: 'ankle_right', name_en: 'Right Ankle', name_vi: 'Mat ca chan phai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/ankle.svg', has_drill_down: true },
                'ankle_left': { code: 'ankle_left', name_en: 'Left Ankle', name_vi: 'Mat ca chan trai', structure_type: 'joint', parent_code: 'body_front', svg_file: 'regions/ankle.svg', has_drill_down: true },
                'achilles_right': { code: 'achilles_right', name_en: 'Right Achilles Tendon', name_vi: 'Gan Achilles phai', structure_type: 'tendon', parent_code: 'body_back', svg_file: 'regions/achilles.svg', has_drill_down: true },
                'achilles_left': { code: 'achilles_left', name_en: 'Left Achilles Tendon', name_vi: 'Gan Achilles trai', structure_type: 'tendon', parent_code: 'body_back', svg_file: 'regions/achilles.svg', has_drill_down: true },
                // Feet and Heels
                'foot_right': { code: 'foot_right', name_en: 'Right Foot', name_vi: 'Ban chan phai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/foot.svg', has_drill_down: true },
                'foot_left': { code: 'foot_left', name_en: 'Left Foot', name_vi: 'Ban chan trai', structure_type: 'region', parent_code: 'body_front', svg_file: 'regions/foot.svg', has_drill_down: true },
                'heel_right': { code: 'heel_right', name_en: 'Right Heel', name_vi: 'Got chan phai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/heel.svg', has_drill_down: true },
                'heel_left': { code: 'heel_left', name_en: 'Left Heel', name_vi: 'Got chan trai', structure_type: 'region', parent_code: 'body_back', svg_file: 'regions/heel.svg', has_drill_down: true }
            };
        }
        // [AI-GENERATED: Claude Code - End]

        /**
         * Load the initial body view
         */
        loadInitialView() {
            this.loadSvg('body-full-front.svg', 'body_front');
        }

        // [AI-GENERATED: Claude Code - Start]
        /**
         * Load an SVG file with error handling and fallback display
         */
        async loadSvg(filename, regionCode) {
            const svgPath = this.config.assetsPath + filename;
            const regionData = this.getRegionData(regionCode);
            const regionName = this.config.language === 'vi' ?
                (regionData?.name_vi || regionCode) :
                (regionData?.name_en || regionCode);

            console.log('[AnatomySelector] Loading SVG:', filename, 'for region:', regionCode);
            console.log('[AnatomySelector] Full SVG path:', svgPath);

            try {
                this.svgContainer.innerHTML = '<div class="anatomy-loading"><i class="fa fa-spinner fa-spin"></i> Loading...</div>';

                const response = await fetch(svgPath);
                if (!response.ok) {
                    console.warn('[AnatomySelector] SVG fetch failed with status:', response.status, 'for:', filename);
                    throw new Error(`Failed to load SVG: ${response.status}`);
                }

                const svgContent = await response.text();
                this.svgContainer.innerHTML = svgContent;
                this.currentSvg = this.svgContainer.querySelector('svg');

                if (this.currentSvg) {
                    console.log('[AnatomySelector] SVG loaded successfully, setting up interaction');
                    this.setupSvgInteraction();
                    this.applyLayerVisibility();

                    // Update navigation
                    if (regionCode) {
                        this.updateBreadcrumb(regionCode);
                    }

                    // Fire callback
                    if (typeof this.config.onDrillDown === 'function') {
                        this.config.onDrillDown(regionCode, this.navigationStack);
                    }

                    console.log('[AnatomySelector] SVG setup complete for:', regionCode);
                } else {
                    console.warn('[AnatomySelector] No SVG element found in loaded content');
                    this.showPlaceholderForMissingRegion(regionCode, regionName, filename);
                }
            } catch (error) {
                console.error('[AnatomySelector] Error loading SVG:', error.message);
                this.showPlaceholderForMissingRegion(regionCode, regionName, filename);
            }
        }

        /**
         * Show a placeholder when region SVG file is missing
         * @param {string} regionCode - The region code
         * @param {string} regionName - The display name for the region
         * @param {string} filename - The SVG filename that was not found
         */
        showPlaceholderForMissingRegion(regionCode, regionName, filename) {
            const labels = LABELS[this.config.language] || LABELS.en;
            console.log('[AnatomySelector] Showing placeholder for missing region:', regionCode);

            this.svgContainer.innerHTML = `
                <div class="anatomy-placeholder">
                    <div class="placeholder-icon">
                        <i class="fa fa-image fa-3x"></i>
                    </div>
                    <h4>${regionName}</h4>
                    <p class="placeholder-message">
                        ${this.config.language === 'vi' ?
                            'So do chi tiet chua co san cho vung nay.' :
                            'Detailed diagram not yet available for this region.'}
                    </p>
                    <p class="placeholder-code">
                        <small>Region: ${regionCode}</small>
                    </p>
                    <button type="button" class="btn btn-secondary btn-sm anatomy-back-btn" id="placeholder-back-btn">
                        <i class="fa fa-arrow-left"></i>
                        ${this.config.language === 'vi' ? 'Quay lai' : 'Go Back'}
                    </button>
                </div>
            `;

            // Update breadcrumb even for missing regions
            if (regionCode) {
                this.updateBreadcrumb(regionCode);
            }

            // Bind back button handler
            const backBtn = document.getElementById('placeholder-back-btn');
            if (backBtn) {
                backBtn.addEventListener('click', () => {
                    console.log('[AnatomySelector] Placeholder back button clicked, drilling up');
                    this.drillUp();
                });
            }
        }
        // [AI-GENERATED: Claude Code - End]

        // [AI-GENERATED: Claude Code - Start]
        /**
         * Setup SVG interaction (clicks, hovers)
         */
        setupSvgInteraction() {
            console.log('[AnatomySelector] Setting up SVG interaction');

            if (!this.currentSvg) {
                console.warn('[AnatomySelector] No current SVG, cannot setup interaction');
                return;
            }

            // Find all clickable regions (elements with data-region attribute)
            const regions = this.currentSvg.querySelectorAll('[data-region]');
            console.log('[AnatomySelector] Found', regions.length, 'clickable regions');

            regions.forEach(region => {
                const regionCode = region.getAttribute('data-region');
                const canDrillDown = region.getAttribute('data-drill-down') === 'true';
                console.log('[AnatomySelector] Setting up region:', regionCode, 'drill-down:', canDrillDown);

                // Add hover effect
                region.addEventListener('mouseenter', (e) => this.handleRegionHover(e, region));
                region.addEventListener('mouseleave', (e) => this.handleRegionLeave(e, region));

                // Add click handler
                region.addEventListener('click', (e) => this.handleRegionClick(e, region));

                // Add touch support
                if (this.config.enableTouch) {
                    region.addEventListener('touchstart', (e) => {
                        e.preventDefault();
                        this.handleRegionClick(e, region);
                    });
                }

                // Style as clickable
                region.style.cursor = 'pointer';
                region.style.transition = 'fill 0.2s ease, opacity 0.2s ease';
            });

            console.log('[AnatomySelector] SVG interaction setup complete');
        }
        // [AI-GENERATED: Claude Code - End]

        /**
         * Handle region hover
         */
        handleRegionHover(event, region) {
            const regionCode = region.getAttribute('data-region');
            const originalFill = region.getAttribute('data-original-fill') || region.style.fill;

            // Store original fill if not already stored
            if (!region.getAttribute('data-original-fill')) {
                region.setAttribute('data-original-fill', region.style.fill || region.getAttribute('fill') || '#ccc');
            }

            // Apply hover color
            region.style.fill = this.config.hoverColor;
            region.style.opacity = '0.9';

            // Show tooltip with region name
            this.showTooltip(event, regionCode);

            // Fire callback
            if (typeof this.config.onRegionHover === 'function') {
                this.config.onRegionHover(regionCode, region);
            }
        }

        /**
         * Handle region leave
         */
        handleRegionLeave(event, region) {
            const originalFill = region.getAttribute('data-original-fill');
            const isSelected = region.classList.contains('selected');

            // Restore original fill or selected color
            region.style.fill = isSelected ? this.config.selectedColor : (originalFill || '');
            region.style.opacity = '1';

            this.hideTooltip();
        }

        /**
         * Handle region click
         */
        handleRegionClick(event, region) {
            event.stopPropagation();

            const regionCode = region.getAttribute('data-region');
            const canDrillDown = region.getAttribute('data-drill-down') === 'true';
            const svgFile = region.getAttribute('data-svg-file');

            // Fire callback
            if (typeof this.config.onRegionClick === 'function') {
                this.config.onRegionClick(regionCode, region, {
                    canDrillDown,
                    svgFile
                });
            }

            if (canDrillDown && svgFile) {
                // Drill down to sub-region
                this.drillDown(regionCode, svgFile);
            } else {
                // Select this region
                this.selectRegion(regionCode, region);
            }
        }

        // [AI-GENERATED: Claude Code - Start]
        /**
         * Drill down to a sub-region
         */
        drillDown(regionCode, svgFile) {
            console.log('[AnatomySelector] Drill-down initiated');
            console.log('[AnatomySelector] Target region:', regionCode);
            console.log('[AnatomySelector] Target SVG file:', svgFile);
            console.log('[AnatomySelector] Current level before:', this.currentLevel);
            console.log('[AnatomySelector] Navigation stack before:', JSON.stringify(this.navigationStack));

            // Save current state to navigation stack
            const currentState = {
                regionCode: this.getCurrentRegionCode(),
                svgFile: this.getCurrentSvgFile(),
                scrollPosition: this.svgContainer.scrollTop
            };
            this.navigationStack.push(currentState);
            console.log('[AnatomySelector] Pushed to stack:', JSON.stringify(currentState));

            this.currentLevel++;
            console.log('[AnatomySelector] New level:', this.currentLevel);
            console.log('[AnatomySelector] Navigation stack after:', JSON.stringify(this.navigationStack));

            this.loadSvg(svgFile, regionCode);
        }

        /**
         * Drill up to parent region
         */
        drillUp() {
            console.log('[AnatomySelector] Drill-up initiated');
            console.log('[AnatomySelector] Current level before:', this.currentLevel);
            console.log('[AnatomySelector] Navigation stack before:', JSON.stringify(this.navigationStack));

            if (this.navigationStack.length === 0) {
                console.log('[AnatomySelector] Navigation stack empty, cannot drill up');
                return;
            }

            const previousState = this.navigationStack.pop();
            this.currentLevel--;

            console.log('[AnatomySelector] Popped from stack:', JSON.stringify(previousState));
            console.log('[AnatomySelector] New level:', this.currentLevel);
            console.log('[AnatomySelector] Navigation stack after:', JSON.stringify(this.navigationStack));

            this.loadSvg(previousState.svgFile, previousState.regionCode);

            // Fire callback
            if (typeof this.config.onDrillUp === 'function') {
                this.config.onDrillUp(previousState.regionCode, this.navigationStack);
            }
        }
        // [AI-GENERATED: Claude Code - End]

        /**
         * Select a region
         */
        selectRegion(regionCode, element) {
            const regionData = this.getRegionData(regionCode);

            // Check if already selected
            const existingIndex = this.selections.findIndex(s => s.code === regionCode);

            if (existingIndex >= 0) {
                // Deselect
                this.selections.splice(existingIndex, 1);
                element.classList.remove('selected');
                element.style.fill = element.getAttribute('data-original-fill') || '';
            } else {
                // Show finding dialog
                this.showFindingDialog(regionCode, regionData, element);
            }

            this.updateSelectionsUI();

            // Fire callback
            if (typeof this.config.onSelectionChange === 'function') {
                this.config.onSelectionChange(this.selections);
            }
        }

        /**
         * Show finding dialog
         */
        showFindingDialog(regionCode, regionData, element) {
            const dialog = document.getElementById('anatomy-finding-dialog');
            const labels = LABELS[this.config.language] || LABELS.en;

            // Set region name
            const nameField = document.getElementById('finding-region-name');
            nameField.textContent = this.config.language === 'vi' ?
                (regionData?.name_vi || regionCode) :
                (regionData?.name_en || regionCode);

            // Reset form
            document.getElementById('finding-severity').value = 5;
            document.getElementById('finding-severity-value').textContent = '5';
            document.getElementById('finding-pain').value = 5;
            document.getElementById('finding-pain-value').textContent = '5';
            document.getElementById('finding-notes').value = '';

            // Show dialog
            dialog.style.display = 'flex';

            // Handle add button
            const addBtn = document.getElementById('finding-add');
            const cancelBtn = document.getElementById('finding-cancel');

            const addHandler = () => {
                const selection = {
                    code: regionCode,
                    name_en: regionData?.name_en || regionCode,
                    name_vi: regionData?.name_vi || regionCode,
                    structure_type: regionData?.structure_type || 'region',
                    path: this.getNavigationPath(),
                    severity: parseInt(document.getElementById('finding-severity').value),
                    pain_level: parseInt(document.getElementById('finding-pain').value),
                    notes: document.getElementById('finding-notes').value,
                    timestamp: new Date().toISOString()
                };

                this.selections.push(selection);
                element.classList.add('selected');
                element.style.fill = this.config.selectedColor;

                this.updateSelectionsUI();
                dialog.style.display = 'none';

                addBtn.removeEventListener('click', addHandler);
                cancelBtn.removeEventListener('click', cancelHandler);

                if (typeof this.config.onSelectionChange === 'function') {
                    this.config.onSelectionChange(this.selections);
                }
            };

            const cancelHandler = () => {
                dialog.style.display = 'none';
                addBtn.removeEventListener('click', addHandler);
                cancelBtn.removeEventListener('click', cancelHandler);
            };

            addBtn.addEventListener('click', addHandler);
            cancelBtn.addEventListener('click', cancelHandler);
        }

        /**
         * Update selections UI
         */
        updateSelectionsUI() {
            const list = document.getElementById('anatomy-selections-list');
            const labels = LABELS[this.config.language] || LABELS.en;

            if (this.selections.length === 0) {
                list.innerHTML = `<p class="no-selection">${labels.noSelection}</p>`;
                return;
            }

            list.innerHTML = this.selections.map((selection, index) => `
                <div class="selection-item" data-index="${index}">
                    <div class="selection-info">
                        <span class="selection-name">${this.config.language === 'vi' ? selection.name_vi : selection.name_en}</span>
                        <span class="selection-type" style="background:${STRUCTURE_COLORS[selection.structure_type] || STRUCTURE_COLORS.region}">
                            ${selection.structure_type}
                        </span>
                    </div>
                    <div class="selection-details">
                        <span class="severity">Severity: ${selection.severity}/10</span>
                        <span class="pain">Pain: ${selection.pain_level}/10</span>
                    </div>
                    <button class="remove-selection" data-index="${index}">
                        <i class="fa fa-times"></i>
                    </button>
                </div>
            `).join('');

            // Add remove handlers
            list.querySelectorAll('.remove-selection').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const index = parseInt(btn.getAttribute('data-index'));
                    this.removeSelection(index);
                });
            });
        }

        /**
         * Remove a selection
         */
        removeSelection(index) {
            if (index >= 0 && index < this.selections.length) {
                const removed = this.selections.splice(index, 1)[0];

                // Find and deselect in SVG
                const element = this.currentSvg?.querySelector(`[data-region="${removed.code}"]`);
                if (element) {
                    element.classList.remove('selected');
                    element.style.fill = element.getAttribute('data-original-fill') || '';
                }

                this.updateSelectionsUI();

                if (typeof this.config.onSelectionChange === 'function') {
                    this.config.onSelectionChange(this.selections);
                }
            }
        }

        /**
         * Update breadcrumb navigation
         */
        updateBreadcrumb(regionCode) {
            const breadcrumb = this.container.querySelector('.anatomy-breadcrumb');
            const labels = LABELS[this.config.language] || LABELS.en;

            let html = `<span class="breadcrumb-item home" data-level="0">${labels.breadcrumbHome}</span>`;

            this.navigationStack.forEach((item, index) => {
                const regionData = this.getRegionData(item.regionCode);
                const name = this.config.language === 'vi' ?
                    (regionData?.name_vi || item.regionCode) :
                    (regionData?.name_en || item.regionCode);
                html += ` <i class="fa fa-chevron-right"></i> `;
                html += `<span class="breadcrumb-item" data-level="${index + 1}" data-code="${item.regionCode}">${name}</span>`;
            });

            // Add current region
            if (regionCode && regionCode !== 'body_front' && regionCode !== 'body_back') {
                const regionData = this.getRegionData(regionCode);
                const name = this.config.language === 'vi' ?
                    (regionData?.name_vi || regionCode) :
                    (regionData?.name_en || regionCode);
                html += ` <i class="fa fa-chevron-right"></i> `;
                html += `<span class="breadcrumb-item current">${name}</span>`;
            }

            breadcrumb.innerHTML = html;

            // Add click handlers
            breadcrumb.querySelectorAll('.breadcrumb-item:not(.current)').forEach(item => {
                item.addEventListener('click', () => {
                    const level = parseInt(item.getAttribute('data-level'));
                    this.navigateToLevel(level);
                });
            });
        }

        /**
         * Navigate to a specific level
         */
        navigateToLevel(level) {
            while (this.navigationStack.length > level) {
                this.navigationStack.pop();
            }

            if (level === 0) {
                this.currentLevel = 0;
                this.loadInitialView();
            } else {
                const targetState = this.navigationStack[level - 1];
                if (targetState) {
                    this.currentLevel = level;
                    this.loadSvg(targetState.svgFile, targetState.regionCode);
                }
            }
        }

        /**
         * Get current region code
         */
        getCurrentRegionCode() {
            return this.navigationStack.length > 0 ?
                this.navigationStack[this.navigationStack.length - 1].regionCode :
                'body_front';
        }

        /**
         * Get current SVG file
         */
        getCurrentSvgFile() {
            if (this.navigationStack.length > 0) {
                return this.navigationStack[this.navigationStack.length - 1].svgFile;
            }
            return this.container.querySelector('.view-btn.active')?.getAttribute('data-view') === 'back' ?
                'body-full-back.svg' : 'body-full-front.svg';
        }

        /**
         * Get navigation path as string
         */
        getNavigationPath() {
            return this.navigationStack.map(s => s.regionCode).join('>');
        }

        /**
         * Get region data by code
         */
        getRegionData(code) {
            return this.regionsData[code] || null;
        }

        /**
         * Apply layer visibility
         */
        applyLayerVisibility() {
            if (!this.currentSvg) return;

            this.currentSvg.querySelectorAll('[data-structure-type]').forEach(element => {
                const type = element.getAttribute('data-structure-type');
                element.style.display = this.visibleLayers.includes(type) ? '' : 'none';
            });
        }

        /**
         * Show tooltip
         */
        showTooltip(event, regionCode) {
            let tooltip = document.getElementById('anatomy-tooltip');
            if (!tooltip) {
                tooltip = document.createElement('div');
                tooltip.id = 'anatomy-tooltip';
                tooltip.className = 'anatomy-tooltip';
                document.body.appendChild(tooltip);
            }

            const regionData = this.getRegionData(regionCode);
            const name = this.config.language === 'vi' ?
                (regionData?.name_vi || regionCode) :
                (regionData?.name_en || regionCode);

            tooltip.textContent = name;
            tooltip.style.display = 'block';
            tooltip.style.left = (event.pageX + 10) + 'px';
            tooltip.style.top = (event.pageY + 10) + 'px';
        }

        /**
         * Hide tooltip
         */
        hideTooltip() {
            const tooltip = document.getElementById('anatomy-tooltip');
            if (tooltip) {
                tooltip.style.display = 'none';
            }
        }

        /**
         * Bind global events
         */
        bindEvents() {
            // View selector buttons
            this.container.querySelectorAll('.view-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                    this.container.querySelectorAll('.view-btn').forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');

                    const view = btn.getAttribute('data-view');
                    this.navigationStack = [];
                    this.currentLevel = 0;
                    this.loadSvg(view === 'back' ? 'body-full-back.svg' : 'body-full-front.svg',
                        view === 'back' ? 'body_back' : 'body_front');
                });
            });

            // Layer toggles
            this.container.querySelectorAll('.layer-toggle input').forEach(checkbox => {
                checkbox.addEventListener('change', () => {
                    const layer = checkbox.getAttribute('data-layer');
                    if (checkbox.checked) {
                        if (!this.visibleLayers.includes(layer)) {
                            this.visibleLayers.push(layer);
                        }
                    } else {
                        this.visibleLayers = this.visibleLayers.filter(l => l !== layer);
                    }
                    this.applyLayerVisibility();
                });
            });

            // Zoom controls
            this.container.querySelectorAll('.zoom-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                    const action = btn.getAttribute('data-action');
                    this.handleZoom(action);
                });
            });

            // Clear button
            const clearBtn = document.getElementById('anatomy-clear-btn');
            if (clearBtn) {
                clearBtn.addEventListener('click', () => {
                    this.clearSelections();
                });
            }

            // Save button
            const saveBtn = document.getElementById('anatomy-save-btn');
            if (saveBtn) {
                saveBtn.addEventListener('click', () => {
                    this.saveSelections();
                });
            }

            // Severity/pain sliders
            const severitySlider = document.getElementById('finding-severity');
            if (severitySlider) {
                severitySlider.addEventListener('input', (e) => {
                    document.getElementById('finding-severity-value').textContent = e.target.value;
                });
            }

            const painSlider = document.getElementById('finding-pain');
            if (painSlider) {
                painSlider.addEventListener('input', (e) => {
                    document.getElementById('finding-pain-value').textContent = e.target.value;
                });
            }
        }

        /**
         * Handle zoom actions
         */
        handleZoom(action) {
            if (!this.currentSvg) return;

            const currentScale = parseFloat(this.currentSvg.style.transform?.replace(/[^0-9.]/g, '') || 1);

            switch (action) {
                case 'zoom-in':
                    this.currentSvg.style.transform = `scale(${Math.min(currentScale + 0.25, 3)})`;
                    break;
                case 'zoom-out':
                    this.currentSvg.style.transform = `scale(${Math.max(currentScale - 0.25, 0.5)})`;
                    break;
                case 'reset':
                    this.currentSvg.style.transform = 'scale(1)';
                    break;
            }
        }

        /**
         * Clear all selections
         */
        clearSelections() {
            this.selections = [];

            if (this.currentSvg) {
                this.currentSvg.querySelectorAll('.selected').forEach(el => {
                    el.classList.remove('selected');
                    el.style.fill = el.getAttribute('data-original-fill') || '';
                });
            }

            this.updateSelectionsUI();

            if (typeof this.config.onSelectionChange === 'function') {
                this.config.onSelectionChange(this.selections);
            }
        }

        /**
         * Save selections
         */
        saveSelections() {
            // This will be overridden by form integration
            console.log('Selections to save:', this.selections);
            return this.selections;
        }

        /**
         * Get current selections
         */
        getSelections() {
            return this.selections;
        }

        /**
         * Set selections (for loading saved data)
         */
        setSelections(selections) {
            this.selections = selections || [];
            this.updateSelectionsUI();
        }

        /**
         * Set language
         */
        setLanguage(lang) {
            this.config.language = lang;
            this.createUI();
            this.loadInitialView();
            this.bindEvents();
        }

        /**
         * Destroy the component
         */
        destroy() {
            this.container.innerHTML = '';
            this.selections = [];
            this.navigationStack = [];

            const tooltip = document.getElementById('anatomy-tooltip');
            if (tooltip) {
                tooltip.remove();
            }
        }
    }

    // Export to global scope
    window.AnatomySelector = AnatomySelector;

})(window, document);
