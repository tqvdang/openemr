<!-- AI-GENERATED: Claude Code -->
# Anatomy Visualization - Technical Documentation

## Overview

The Anatomy Visualization feature provides an interactive, SVG-based drill-down body diagram for anatomical region selection in the Vietnamese Physiotherapy module. Physical therapists can click on body regions to navigate through multiple levels of anatomical detail (Body → Region → Sub-region → Structure) and document clinical findings with severity, pain levels, and notes.

### Key Features

- **Multi-level drill-down navigation**: 4 levels of anatomical hierarchy
- **Bilingual support**: English and Vietnamese labels throughout
- **Interactive SVG graphics**: Hover effects, click handling, and visual feedback
- **Layer controls**: Show/hide different anatomical structure types
- **Touch support**: Mobile-friendly interaction
- **Clinical documentation**: Severity and pain ratings with notes
- **Breadcrumb navigation**: Easy navigation back through hierarchy levels
- **Zoom controls**: Zoom in/out and reset view
- **Selection persistence**: Save and restore anatomical selections

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     PT Assessment Form                       │
│                   (vietnamese_pt_assessment)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    anatomy-panel.php                         │
│  - Initializes AnatomySelector component                     │
│  - Loads existing selections from database                   │
│  - Handles form integration                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌──────────────────┐    ┌──────────────────────┐
│ anatomy-selector │    │  anatomy-selector    │
│     .js          │    │      .css            │
│                  │    │                      │
│ - AnatomySelector│    │ - UI styles          │
│   class          │    │ - Responsive layout  │
│ - Event handlers │    │ - Dark mode support  │
│ - State mgmt     │    │ - Print styles       │
└────────┬─────────┘    └──────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│           SVG Assets (/public/assets/anatomy)│
│                                              │
│  - body-full-front.svg (Level 1)            │
│  - body-full-back.svg (Level 1)             │
│  - regions/*.svg (Level 2)                  │
│  - structures/*.svg (Level 3)               │
└────────┬────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│          Database Tables                     │
│                                              │
│  - anatomy_regions (hierarchy)              │
│  - pt_anatomical_selections (user data)     │
└──────────────────────────────────────────────┘
```

### Data Flow Diagram

```
User Interaction Flow:
───────────────────────

1. Page Load
   ├─> anatomy-panel.php includes anatomy-selector.js
   ├─> AnatomySelector initialized with config
   ├─> Loads body-full-front.svg (default view)
   └─> Loads existing selections from hidden field

2. User Clicks Body Region (e.g., shoulder)
   ├─> handleRegionClick() fires
   ├─> Checks data-drill-down attribute
   ├─> If true: drillDown() → loads regions/shoulder.svg
   ├─> If false: selectRegion() → shows finding dialog
   └─> Updates breadcrumb navigation

3. User Selects Structure (e.g., deltoid muscle)
   ├─> showFindingDialog() displays modal
   ├─> User inputs severity (0-10), pain (0-10), notes
   ├─> Selection added to selections array
   ├─> updateSelectionsUI() renders selection in sidebar
   ├─> Element marked with 'selected' class and highlight color
   └─> onSelectionChange callback fires

4. Form Submission
   ├─> Hidden field 'anatomical_selections' contains JSON
   ├─> PHP processes and saves to pt_anatomical_selections table
   └─> Data linked to assessment_id and patient_id

Navigation Flow:
────────────────

Body → Region → Sub-region → Structure
  ↓       ↓         ↓           ↓
Level1  Level2    Level3      Level4
  │       │         │           │
  └───────┴─────────┴───────────┴──> All stored in anatomy_regions
                                      with parent_id relationships
```

## File Structure

### JavaScript Files

#### `/library/js/anatomy-selector.js` (937 lines)
**Purpose**: Main component class for anatomy visualization

**Key Classes/Objects**:
- `AnatomySelector` - Main class
- `DEFAULT_CONFIG` - Configuration defaults
- `STRUCTURE_COLORS` - Color mapping for structure types
- `LABELS` - Bilingual UI labels (English/Vietnamese)

**Key Methods**:
- `init()` - Initialize component
- `createUI()` - Build HTML structure
- `loadSvg(filename, regionCode)` - Load and display SVG
- `setupSvgInteraction()` - Attach event handlers to SVG elements
- `handleRegionClick(event, region)` - Process region clicks
- `drillDown(regionCode, svgFile)` - Navigate deeper into hierarchy
- `drillUp()` - Navigate back up hierarchy
- `selectRegion(regionCode, element)` - Mark region as selected
- `showFindingDialog()` - Display clinical finding input modal
- `updateSelectionsUI()` - Render selection list in sidebar
- `applyLayerVisibility()` - Show/hide structure type layers
- `getSelections()` - Export current selections
- `setSelections(selections)` - Import saved selections

### PHP Files

#### `/interface/forms/vietnamese_pt_assessment/anatomy-panel.php` (189 lines)
**Purpose**: Integration component for PT Assessment form

**Responsibilities**:
- Include CSS and JS assets
- Render anatomy-selector container
- Initialize AnatomySelector with form-specific config
- Load existing selections from database
- Handle form submission data
- Convert between database and component formats

**Key Features**:
- Bilingual support via `language_preference`
- Loads existing selections for edit mode
- Updates hidden field on selection changes
- Callbacks for region clicks, drill-down, drill-up

### CSS Files

#### `/public/assets/anatomy/anatomy-selector.css` (581 lines)
**Purpose**: Component styling

**Key Sections**:
- `.anatomy-selector-wrapper` - Main container
- `.anatomy-header` - View selector and breadcrumb
- `.anatomy-svg-container` - SVG display area
- `.anatomy-side-panel` - Layer controls and selections list
- `.anatomy-finding-dialog` - Clinical finding input modal
- `.anatomy-tooltip` - Hover tooltips
- Responsive styles (@media queries)
- Dark mode support (@media prefers-color-scheme: dark)
- Print styles

### SVG Assets

#### `/public/assets/anatomy/`

**Level 1 - Body Views**:
- `body-full-front.svg` - Full body front view
- `body-full-back.svg` - Full body back view

**Level 2 - Major Regions** (`regions/`):
- `shoulder.svg` - Shoulder detail
- `knee.svg` - Knee detail
- `spine-lumbar.svg` - Lumbar spine detail
- `elbow.svg`, `wrist.svg`, `hand.svg`, etc.

**Level 3 - Structures** (`structures/`):
- `shoulder-muscles.svg` - Rotator cuff, deltoid, etc.
- `shoulder-bones.svg` - Humerus, scapula, clavicle
- `shoulder-joints.svg` - Glenohumeral, AC joint
- `knee-ligaments.svg` - ACL, PCL, MCL, LCL
- `lumbar-vertebrae.svg` - L1-L5 vertebrae

### Database Schema

#### `/sql/anatomy_selections.sql`

**Tables**:
1. `anatomy_regions` - Anatomical hierarchy
2. `pt_anatomical_selections` - User selections

## SVG Structure Requirements

### Required Data Attributes

All clickable SVG elements must include these attributes:

#### `data-region` (required)
Unique code identifying the anatomical region.

**Format**: `{region}_{laterality}` for bilateral structures
**Examples**:
- `shoulder_right`
- `knee_left`
- `lumbar_spine` (midline)
- `deltoid_right`

#### `data-structure-type` (required)
Type of anatomical structure for filtering and color coding.

**Valid values**:
- `region` - Major body region
- `muscle` - Skeletal muscle
- `bone` - Bone structure
- `joint` - Joint/articulation
- `nerve` - Nerve structure
- `vessel` - Blood vessel
- `ligament` - Ligament
- `tendon` - Tendon
- `organ` - Internal organ

#### `data-drill-down` (required)
Indicates whether clicking this region navigates to a detailed view.

**Values**:
- `true` - Clicking loads the SVG specified in `data-svg-file`
- `false` - Clicking opens finding dialog for selection

#### `data-svg-file` (required if drill-down=true)
Path to SVG file for next level of detail (relative to `/public/assets/anatomy/`).

**Examples**:
- `regions/shoulder.svg`
- `structures/shoulder-muscles.svg`

### SVG Element Structure Example

```xml
<!-- Level 1: Body region with drill-down -->
<ellipse cx="125" cy="145" rx="30" ry="25"
         class="region"
         data-region="shoulder_left"
         data-structure-type="region"
         data-drill-down="true"
         data-svg-file="regions/shoulder.svg"/>

<!-- Level 2: Specific muscle (no drill-down) -->
<path d="M180 110 C150 130..."
      class="muscle region"
      data-region="deltoid_right"
      data-structure-type="muscle"
      data-drill-down="false"/>
```

### Layer Naming Conventions

Use `data-layer` attribute on parent `<g>` elements to enable layer toggling:

```xml
<g id="muscles-layer" data-layer="muscle">
  <!-- All muscle elements -->
</g>

<g id="bones-layer" data-layer="bone">
  <!-- All bone elements -->
</g>

<g id="joints-layer" data-layer="joint">
  <!-- All joint elements -->
</g>
```

**Valid layer values** (must match `data-structure-type`):
- `muscle`
- `bone`
- `joint`
- `ligament`
- `tendon`
- `nerve`
- `vessel`

### Color Scheme for Structure Types

Defined in `anatomy-selector.js` as `STRUCTURE_COLORS`:

```javascript
region:    '#E3F2FD'  // Light blue
muscle:    '#FFCDD2'  // Light red
bone:      '#FFF9C4'  // Light yellow
joint:     '#C8E6C9'  // Light green
nerve:     '#E1BEE7'  // Light purple
vessel:    '#FFCCBC'  // Light orange
ligament:  '#B2DFDB'  // Light teal
tendon:    '#F0F4C3'  // Light lime
organ:     '#D1C4E9'  // Light lavender
```

### SVG CSS Classes

```css
.region {
  cursor: pointer;
  transition: fill 0.2s ease;
}

.region:hover {
  fill: rgba(76, 175, 80, 0.3);
  stroke: #4CAF50;
  stroke-width: 2;
}
```

## REST API Reference

### GET /apis/default/vietnamese-pt/anatomy/regions

**Description**: Retrieve all anatomical regions in the hierarchy.

**Authentication**: OAuth2 or session-based

**Request**:
```http
GET /apis/default/vietnamese-pt/anatomy/regions HTTP/1.1
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "shoulder_right": {
    "id": 3,
    "code": "shoulder_right",
    "name_en": "Right Shoulder",
    "name_vi": "Vai phải",
    "level": 2,
    "structure_type": "region",
    "svg_file": "regions/shoulder.svg",
    "parent_id": 1
  },
  "deltoid_right": {
    "id": 15,
    "code": "deltoid_right",
    "name_en": "Deltoid",
    "name_vi": "Cơ delta",
    "level": 3,
    "structure_type": "muscle",
    "svg_file": "structures/shoulder-muscles.svg",
    "parent_id": 3,
    "fma_id": "FMA32521"
  }
}
```

### GET /apis/default/vietnamese-pt/anatomy/regions/:code

**Description**: Retrieve a specific anatomical region by code.

**Parameters**:
- `code` (path) - Region code (e.g., `shoulder_right`)

**Request**:
```http
GET /apis/default/vietnamese-pt/anatomy/regions/shoulder_right HTTP/1.1
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "id": 3,
  "code": "shoulder_right",
  "name_en": "Right Shoulder",
  "name_vi": "Vai phải",
  "level": 2,
  "structure_type": "region",
  "svg_file": "regions/shoulder.svg",
  "svg_element_id": "shoulder_r",
  "parent_id": 1,
  "fma_id": null,
  "display_order": 3,
  "is_active": 1
}
```

### GET /apis/default/vietnamese-pt/anatomy/regions/hierarchy

**Description**: Retrieve the full hierarchical structure of anatomical regions.

**Request**:
```http
GET /apis/default/vietnamese-pt/anatomy/regions/hierarchy HTTP/1.1
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "body_front": {
    "id": 1,
    "code": "body_front",
    "name_en": "Body (Front View)",
    "name_vi": "Cơ thể (Mặt trước)",
    "level": 1,
    "children": [
      {
        "id": 3,
        "code": "shoulder_right",
        "name_en": "Right Shoulder",
        "name_vi": "Vai phải",
        "level": 2,
        "children": [
          {
            "id": 15,
            "code": "deltoid_right",
            "name_en": "Deltoid",
            "name_vi": "Cơ delta",
            "level": 3,
            "structure_type": "muscle"
          }
        ]
      }
    ]
  }
}
```

## Database Schema

### `anatomy_regions` Table

Stores the hierarchical structure of anatomical regions (4 levels).

**Columns**:

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) AUTO_INCREMENT | Primary key |
| `parent_id` | INT(11) NULL | Parent region (NULL for level 1) |
| `code` | VARCHAR(50) UNIQUE | Unique region code |
| `name_en` | VARCHAR(255) | English name |
| `name_vi` | VARCHAR(255) | Vietnamese name |
| `level` | TINYINT(1) | Hierarchy level (1-4) |
| `structure_type` | ENUM | Type: region, muscle, bone, joint, nerve, vessel, ligament, tendon, organ |
| `svg_file` | VARCHAR(255) NULL | SVG file for this level |
| `svg_element_id` | VARCHAR(100) NULL | Element ID within parent SVG |
| `fma_id` | VARCHAR(50) NULL | Foundational Model of Anatomy ID |
| `display_order` | INT(11) | Sort order |
| `is_active` | TINYINT(1) | Active status (1=active) |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

**Indexes**:
- PRIMARY KEY (`id`)
- UNIQUE KEY (`code`)
- KEY (`parent_id`)
- KEY (`level`)
- KEY (`structure_type`)
- FULLTEXT (`name_en`, `name_vi`)

**Collation**: `utf8mb4_vietnamese_ci`

### `pt_anatomical_selections` Table

Stores patient anatomical selections from PT assessments.

**Columns**:

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) AUTO_INCREMENT | Primary key |
| `assessment_id` | INT(11) | FK to pt_assessments_bilingual |
| `patient_id` | INT(11) | FK to patient_data |
| `encounter_id` | INT(11) NULL | FK to form_encounter |
| `region_id` | INT(11) | FK to anatomy_regions |
| `region_code` | VARCHAR(50) | Region code (denormalized) |
| `region_path` | VARCHAR(500) NULL | Full path (e.g., body>shoulder>deltoid) |
| `laterality` | ENUM | left, right, bilateral, midline, not_applicable |
| `finding_type` | VARCHAR(100) NULL | Type of finding (tenderness, weakness, etc.) |
| `severity_level` | TINYINT(2) NULL | Severity (0-10) |
| `pain_level` | TINYINT(2) NULL | Pain level (0-10) |
| `notes_en` | TEXT NULL | English notes |
| `notes_vi` | TEXT NULL | Vietnamese notes |
| `view_state` | JSON NULL | UI state for restoring view |
| `selected_by` | INT(11) NULL | User who made selection |
| `created_at` | TIMESTAMP | Selection timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

**Indexes**:
- PRIMARY KEY (`id`)
- KEY (`assessment_id`)
- KEY (`patient_id`)
- KEY (`encounter_id`)
- KEY (`region_id`)
- KEY (`region_code`)
- FULLTEXT (`notes_en`, `notes_vi`)

**Collation**: `utf8mb4_vietnamese_ci`

## Adding New Regions

### Step-by-Step Guide

#### 1. Create SVG File

Create an SVG file with proper structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 450">
  <title>Ankle Anatomy / Giải phẫu mắt cá</title>

  <defs>
    <style>
      .bone { fill: #fff9c4; stroke: #8d6e63; stroke-width: 1.5; }
      .muscle { fill: #ffcdd2; stroke: #c62828; stroke-width: 1; }
      .ligament { fill: #b2dfdb; stroke: #00695c; stroke-width: 1; }
      .region { cursor: pointer; transition: all 0.2s ease; }
      .region:hover { filter: brightness(1.1); stroke-width: 3; }
    </style>
  </defs>

  <!-- Bones Layer -->
  <g id="bones-layer" data-layer="bone">
    <path d="..." class="bone region"
          data-region="talus_right"
          data-structure-type="bone"
          data-drill-down="false"/>
  </g>

  <!-- Ligaments Layer -->
  <g id="ligaments-layer" data-layer="ligament">
    <path d="..." class="ligament region"
          data-region="atfl_right"
          data-structure-type="ligament"
          data-drill-down="false"/>
  </g>
</svg>
```

Save as: `/public/assets/anatomy/regions/ankle.svg`

#### 2. Insert into Database

Add the parent region (if not exists):

```sql
INSERT INTO anatomy_regions
  (parent_id, code, name_en, name_vi, level, structure_type, svg_file, svg_element_id, display_order)
VALUES
  ((SELECT id FROM anatomy_regions WHERE code = 'body_front' LIMIT 1),
   'ankle_right',
   'Right Ankle',
   'Mắt cá phải',
   2,
   'region',
   'regions/ankle.svg',
   'ankle_r',
   25);
```

Add detailed structures:

```sql
-- Talus bone
INSERT INTO anatomy_regions
  (parent_id, code, name_en, name_vi, level, structure_type, fma_id, display_order)
VALUES
  ((SELECT id FROM anatomy_regions WHERE code = 'ankle_right' LIMIT 1),
   'talus_right',
   'Talus',
   'Xương sên',
   3,
   'bone',
   'FMA9708',
   1);

-- ATFL ligament
INSERT INTO anatomy_regions
  (parent_id, code, name_en, name_vi, level, structure_type, fma_id, display_order)
VALUES
  ((SELECT id FROM anatomy_regions WHERE code = 'ankle_right' LIMIT 1),
   'atfl_right',
   'Anterior Talofibular Ligament',
   'Dây chằng sên mác trước',
   3,
   'ligament',
   'FMA44614',
   2);
```

#### 3. Update Parent SVG

Add the new region to the parent body SVG (`body-full-front.svg`):

```xml
<!-- Right Ankle -->
<ellipse cx="260" cy="665" rx="18" ry="22" class="region"
         data-region="ankle_right"
         data-drill-down="true"
         data-svg-file="regions/ankle.svg"/>
```

#### 4. Test the Integration

1. Load PT Assessment form
2. Click on the ankle region in the body diagram
3. Verify SVG loads correctly
4. Test layer toggles (bones, ligaments)
5. Select a structure and verify finding dialog
6. Save and verify data in database

#### 5. Verify Database Entries

```sql
-- Check hierarchy
SELECT
  r1.name_en AS level1,
  r2.name_en AS level2,
  r3.name_en AS level3
FROM anatomy_regions r3
LEFT JOIN anatomy_regions r2 ON r3.parent_id = r2.id
LEFT JOIN anatomy_regions r1 ON r2.parent_id = r1.id
WHERE r3.code LIKE 'ankle%'
ORDER BY r3.display_order;
```

### FMA ID Reference

Use the Foundational Model of Anatomy (FMA) for standardized anatomical identifiers:

- FMA Browser: https://bioportal.bioontology.org/ontologies/FMA
- Common structures are already mapped in the schema

## Troubleshooting

### Common Issues

#### 1. SVG Not Loading

**Symptoms**: "Could not load anatomy diagram" error message

**Causes**:
- SVG file path incorrect
- SVG file doesn't exist
- SVG contains syntax errors
- CORS issues (if loaded from external source)

**Solutions**:
```bash
# Verify file exists
ls -la /home/dang/dev/openemr/public/assets/anatomy/regions/shoulder.svg

# Check file permissions
chmod 644 /home/dang/dev/openemr/public/assets/anatomy/regions/*.svg

# Validate SVG syntax
xmllint --noout /home/dang/dev/openemr/public/assets/anatomy/regions/shoulder.svg

# Check browser console for errors
# Open DevTools → Console → Look for failed fetch() requests
```

#### 2. Regions Not Clickable

**Symptoms**: Hover works but clicking does nothing

**Causes**:
- Missing `data-region` attribute
- Missing `data-drill-down` attribute
- Missing `data-svg-file` attribute (when drill-down=true)
- JavaScript errors preventing event binding

**Solutions**:
```javascript
// Check SVG structure in browser console
const svg = document.querySelector('#anatomy-svg-wrapper svg');
const regions = svg.querySelectorAll('[data-region]');
console.log('Found regions:', regions.length);

regions.forEach(r => {
  console.log({
    region: r.getAttribute('data-region'),
    drillDown: r.getAttribute('data-drill-down'),
    svgFile: r.getAttribute('data-svg-file')
  });
});
```

#### 3. Layers Not Toggling

**Symptoms**: Layer checkboxes don't show/hide elements

**Causes**:
- Missing `data-layer` attribute on parent `<g>` element
- Missing `data-structure-type` on clickable elements
- Mismatch between layer name and structure type

**Solutions**:
```xml
<!-- Ensure layer wrapper exists -->
<g id="muscles-layer" data-layer="muscle">
  <!-- Ensure each element has structure-type -->
  <path class="muscle region"
        data-region="deltoid_right"
        data-structure-type="muscle"
        data-drill-down="false"/>
</g>
```

```javascript
// Verify layer visibility code
applyLayerVisibility() {
  if (!this.currentSvg) return;

  this.currentSvg.querySelectorAll('[data-structure-type]').forEach(element => {
    const type = element.getAttribute('data-structure-type');
    const isVisible = this.visibleLayers.includes(type);
    element.style.display = isVisible ? '' : 'none';
    console.log(`${type}: ${isVisible ? 'visible' : 'hidden'}`);
  });
}
```

#### 4. Selections Not Saving

**Symptoms**: Selections disappear on form save/reload

**Causes**:
- Hidden field not updated
- JSON encoding error
- Database insert failure
- Missing assessment_id

**Solutions**:
```javascript
// Check hidden field value
const selectionsField = document.getElementById('anatomical_selections');
console.log('Selections JSON:', selectionsField.value);

// Validate JSON
try {
  const selections = JSON.parse(selectionsField.value);
  console.log('Parsed selections:', selections);
} catch (e) {
  console.error('Invalid JSON:', e);
}
```

```sql
-- Verify data saved
SELECT * FROM pt_anatomical_selections
WHERE assessment_id = ?
ORDER BY created_at DESC;
```

#### 5. Bilingual Labels Not Showing

**Symptoms**: Only English or only Vietnamese labels appear

**Causes**:
- `language_preference` not set correctly
- Missing translation in `anatomy_regions` table
- JavaScript language config incorrect

**Solutions**:
```php
// Check language preference in PHP
var_dump($formData['language_preference']); // Should be 'en' or 'vi'
```

```javascript
// Check JavaScript language config
console.log('Language:', anatomySelector.config.language);

// Check region data has both languages
const regionData = anatomySelector.getRegionData('shoulder_right');
console.log('English:', regionData.name_en);
console.log('Vietnamese:', regionData.name_vi);
```

```sql
-- Verify translations exist
SELECT code, name_en, name_vi
FROM anatomy_regions
WHERE name_vi IS NULL OR name_vi = '';
```

### Debug Logging

Enable verbose logging:

```javascript
// In anatomy-selector.js, add to init()
this.debug = true;

// Add logging to key methods
handleRegionClick(event, region) {
  if (this.debug) {
    console.log('=== Region Click ===');
    console.log('Region code:', region.getAttribute('data-region'));
    console.log('Can drill down:', region.getAttribute('data-drill-down'));
    console.log('SVG file:', region.getAttribute('data-svg-file'));
    console.log('Current level:', this.currentLevel);
    console.log('Navigation stack:', this.navigationStack);
  }
  // ... rest of method
}
```

### Performance Issues

**Symptoms**: Slow SVG loading or laggy interactions

**Solutions**:

1. **Optimize SVG files**:
   ```bash
   # Use SVGO to optimize
   npm install -g svgo
   svgo /home/dang/dev/openemr/public/assets/anatomy/regions/*.svg
   ```

2. **Reduce SVG complexity**:
   - Simplify paths (reduce anchor points)
   - Remove unnecessary metadata
   - Combine similar elements

3. **Enable browser caching**:
   ```apache
   # In .htaccess
   <FilesMatch "\.(svg)$">
     Header set Cache-Control "max-age=2592000, public"
   </FilesMatch>
   ```

4. **Lazy load detailed SVGs**:
   - Only load when user drills down
   - Already implemented in `loadSvg()` method

### Browser Compatibility

**Tested browsers**:
- Chrome 90+ ✓
- Firefox 88+ ✓
- Safari 14+ ✓
- Edge 90+ ✓

**Known issues**:
- IE11: Not supported (SVG manipulation limitations)
- Mobile Safari: Touch events may require `touch-action: manipulation` on SVG elements

## Related Documentation

- **User Guide**: `/home/dang/dev/openemr/Documentation/physiotherapy/user-guides/ANATOMY_SELECTOR_GUIDE.md`
- **PT Module Overview**: `/home/dang/dev/openemr/Documentation/physiotherapy/README.md`
- **Database Schema**: `/home/dang/dev/openemr/sql/anatomy_selections.sql`
- **Form Integration**: `/home/dang/dev/openemr/interface/forms/vietnamese_pt_assessment/`

## License

GNU General Public License 3

Copyright (c) 2025 Dang Tran

<!-- AI-GENERATED: Claude Code -->
