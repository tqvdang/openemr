<!-- AI-GENERATED: Claude Code -->
# Anatomy Selector User Guide

## Introduction

The Anatomy Selector is an interactive visual tool for physical therapists to document patient findings by selecting specific anatomical regions on a body diagram. Instead of typing anatomical terms, you can simply click on the body to drill down from general regions (like "shoulder") to specific structures (like "supraspinatus muscle" or "ACL ligament").

### What is the Anatomy Selector?

Think of it as a visual "zoom lens" for the human body:
- Start with a full-body diagram (front or back view)
- Click a region to see detailed anatomy
- Click specific muscles, bones, joints, or ligaments
- Document your findings with severity ratings and notes
- All selections are bilingual (English/Vietnamese)

### Key Benefits

- **Faster documentation**: Click instead of typing complex anatomical terms
- **Reduces errors**: Visual selection eliminates spelling mistakes
- **Bilingual support**: Automatically shows both English and Vietnamese terms
- **Comprehensive**: Access to muscles, bones, joints, ligaments, tendons, nerves, and vessels
- **Standardized**: Uses Foundational Model of Anatomy (FMA) codes for consistency

## Getting Started

### Opening the PT Assessment Form

1. Navigate to a patient's chart
2. Go to **Encounters** → **New Encounter**
3. From the encounter screen, click **Add Form**
4. Select **Vietnamese PT Assessment** from the forms list
5. The anatomy selector appears in the **Anatomical Region Selection** section

### Understanding the Interface

The anatomy selector has three main areas:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Front View] [Back View]    Home > Shoulder > Deltoid          │ ← Header
├─────────────────────────────────────────┬───────────────────────┤
│                                         │  LAYERS               │
│                                         │  ☑ Muscles            │
│         Body Diagram                    │  ☑ Bones              │
│         (Click regions)                 │  ☑ Joints             │
│                                         │  ☑ Ligaments          │
│                                         │  ☑ Tendons            │
│                                         │  ☐ Nerves             │
│                                         │  ☐ Vessels            │
│                                         ├───────────────────────┤
│         [Zoom controls]                 │  SELECTED REGIONS     │
│                                         │  • Deltoid            │
│                                         │    Severity: 7/10     │
│                                         │    Pain: 6/10         │
│                                         │  • Supraspinatus      │
│                                         │    Severity: 8/10     │
│                                         │    Pain: 9/10         │
│                                         │                       │
│                                         │  [Clear]  [Save]      │
└─────────────────────────────────────────┴───────────────────────┘
```

**1. Header Section** (Top)
- **View selector buttons**: Switch between Front View and Back View
- **Breadcrumb navigation**: Shows your current location in the anatomy hierarchy
  - Example: `Body > Shoulder > Rotator Cuff > Supraspinatus`
  - Click any breadcrumb to jump back to that level

**2. Main Diagram Area** (Center-left)
- Large interactive body diagram
- Hover over regions to see their names
- Click regions to drill down or select
- Zoom controls in bottom-right corner

**3. Side Panel** (Right)
- **Layers section**: Toggle visibility of different structure types
- **Selected Regions list**: Shows all your current selections
- **Action buttons**: Clear all selections or save

## Selecting Body Regions

### Basic Selection Process

#### 1. Choose Your View

Click **Front View** or **Back View** depending on the patient's complaint:

- **Front View**: Chest, abdomen, anterior shoulders, knees, etc.
- **Back View**: Spine, posterior shoulders, hamstrings, calves, etc.

**Tip**: You can switch views at any time without losing selections.

#### 2. Click on the Body Region

Hover your mouse over the body diagram. Regions will highlight in light green when you hover over them. A tooltip shows the region name in your selected language.

**Example - Selecting Right Shoulder**:
1. Hover over the right shoulder area
2. See tooltip: "Right Shoulder / Vai phải"
3. Click the region

#### 3. What Happens Next?

The system checks if the region has more detail available:

**If the region has drill-down detail** (like shoulder, knee, spine):
- The view zooms into that region
- You see detailed anatomy (muscles, bones, joints)
- The breadcrumb updates: `Body > Right Shoulder`

**If the region is a final structure** (like deltoid muscle):
- A finding dialog appears
- Enter severity, pain level, and notes
- Click **Add Finding** to confirm

### Drill-Down Navigation

The anatomy selector has up to 4 levels of detail:

```
Level 1: Body          (Full body front/back view)
  ↓
Level 2: Region        (Shoulder, knee, lumbar spine)
  ↓
Level 3: Sub-region    (Rotator cuff, meniscus, L4-L5 disc)
  ↓
Level 4: Structure     (Supraspinatus, ACL, multifidus)
```

#### Example: Selecting Rotator Cuff Injury

**Step 1**: Click on **Right Shoulder** (Level 2)
- View zooms to shoulder anatomy
- Breadcrumb: `Body > Right Shoulder`

**Step 2**: Click on **Supraspinatus** muscle (Level 3)
- Finding dialog appears
- Not all regions have Level 4 detail

**Step 3**: Enter clinical findings
- Severity: 8/10
- Pain: 7/10
- Notes: "Positive Jobe's test, painful arc 60-120°"

**Step 4**: Click **Add Finding**
- Selection appears in sidebar
- Muscle highlighted in blue on diagram

#### Navigating Back Up

Three ways to go back:

1. **Click breadcrumb**: Jump to any previous level
   - Click "Body" to return to full body view
   - Click "Right Shoulder" to return to shoulder view

2. **Change view**: Switch to Front/Back view resets to body level

3. **Start new selection**: Just click another region

### Using Front/Back Views

#### When to Use Front View

- **Upper extremity anterior**: Anterior shoulder, biceps, forearm flexors
- **Lower extremity anterior**: Quadriceps, anterior knee, anterior ankle, dorsiflexors
- **Trunk anterior**: Chest, abdomen, hip flexors

**Common PT conditions (Front View)**:
- Rotator cuff injuries (anterior shoulder)
- Patellofemoral pain (anterior knee)
- Shin splints (anterior lower leg)
- Carpal tunnel (wrist/hand)

#### When to Use Back View

- **Upper extremity posterior**: Posterior shoulder, triceps, forearm extensors
- **Lower extremity posterior**: Hamstrings, calf, Achilles tendon
- **Spine**: Cervical, thoracic, lumbar spine
- **Trunk posterior**: Upper back, lower back, gluteal region

**Common PT conditions (Back View)**:
- Low back pain (lumbar spine)
- Hamstring strain (posterior thigh)
- Achilles tendinopathy (posterior ankle)
- Upper crossed syndrome (cervical/thoracic spine)

**Tip**: Some structures are visible from both views. For example, you can access the shoulder from both front and back views, but you'll see different muscles (deltoid from front, infraspinatus from back).

## Using Layer Controls

### What Are Layers?

Layers allow you to show or hide different types of anatomical structures. This helps you focus on specific tissues relevant to your assessment.

### Available Layers

Each layer has a color code:

| Layer | Color | When to Use |
|-------|-------|-------------|
| **Muscles** | Light Red | Strains, tears, weakness, spasms |
| **Bones** | Light Yellow | Fractures, alignment issues, landmarks |
| **Joints** | Light Green | Arthritis, instability, ROM limitations |
| **Ligaments** | Light Teal | Sprains, instability, post-injury |
| **Tendons** | Light Lime | Tendinopathy, tendinitis |
| **Nerves** | Light Purple | Neuropathy, radiculopathy, nerve entrapment |
| **Vessels** | Light Orange | Circulation issues, DVT screening |

### How to Use Layer Controls

#### Toggling Layers On/Off

In the right sidebar **Layers** section:

1. Click the checkbox next to any layer name
2. **Checked** = layer visible on diagram
3. **Unchecked** = layer hidden

**Default visible layers**: Muscles, Bones, Joints, Ligaments, Tendons

**Default hidden layers**: Nerves, Vessels (to reduce visual clutter)

#### Example: Shoulder Impingement Assessment

You want to focus on bones and joints to check for subacromial space:

1. Drill down to **Right Shoulder**
2. In Layers section, **uncheck** Muscles
3. Keep **Bones** and **Joints** checked
4. Now you can clearly see:
   - Acromion (bone)
   - Humeral head (bone)
   - Glenohumeral joint
   - AC joint
5. Click on structures to document findings

#### Example: Knee Ligament Injury

You suspect MCL sprain:

1. Drill down to **Right Knee**
2. **Check** Ligaments layer (if not already visible)
3. Optionally **uncheck** Muscles to reduce clutter
4. Click on **MCL** (Medial Collateral Ligament)
5. Rate severity and pain

**Tip**: You can toggle layers at any time, even after selecting regions. Your selections remain highlighted.

### When to Show/Hide Layers

**Show multiple layers when**:
- Performing comprehensive assessment
- Documenting multiple tissue involvement
- Teaching/demonstrating anatomy

**Hide layers when**:
- Focusing on specific tissue type
- Diagram feels cluttered
- Patient has single-tissue pathology

## Managing Selections

### Viewing Selected Regions

All your selections appear in the **Selected Regions** list in the right sidebar.

Each selection shows:
- **Region name** (in your language preference)
- **Structure type** (color-coded badge)
- **Severity rating** (0-10 scale)
- **Pain rating** (0-10 scale)
- **Remove button** (X icon)

**Example display**:
```
┌─────────────────────────────┐
│ Supraspinatus       [muscle]│
│ Severity: 8/10              │
│ Pain: 7/10                  │
│                          [X]│
└─────────────────────────────┘
```

### Adding Notes to Selections

When you select a structure, the **Finding Dialog** appears:

**Finding Dialog Fields**:

1. **Region Name** (read-only)
   - Shows the structure you clicked
   - Displays in both English and Vietnamese

2. **Severity Slider** (0-10)
   - How severe is the problem?
   - 0 = No issue
   - 5 = Moderate
   - 10 = Severe/Complete dysfunction
   - Use for grading tissue damage, weakness, etc.

3. **Pain Level Slider** (0-10)
   - Patient's pain rating for this region
   - 0 = No pain
   - 5 = Moderate pain
   - 10 = Worst pain imaginable
   - Use standard pain scales (VAS, NRS)

4. **Notes Field** (text area)
   - Free text for detailed findings
   - Can type in English or Vietnamese
   - Examples:
     - "Positive empty can test"
     - "Đau khi nâng tay qua đầu"
     - "ROM: Flexion 90°, limited by pain"

**Buttons**:
- **Clear**: Cancel and close dialog (nothing saved)
- **Add Finding**: Save selection with entered data

### Editing Selections

Currently, you cannot edit a selection after adding it. To change a selection:

1. Click the **X** button to remove it
2. Click the region again on the diagram
3. Enter the correct information
4. Click **Add Finding**

**Tip**: Before clicking "Add Finding", double-check your severity and pain ratings.

### Clearing Selections

#### Clear Individual Selection

Click the **X** button next to any selection in the sidebar list.

The selection is immediately removed and the region unhighlights on the diagram.

#### Clear All Selections

Click the **Clear** button at the bottom of the sidebar.

**Warning**: This removes ALL selections. You'll see a confirmation prompt. Use this to start over if needed.

### Saving Selections

Selections are automatically saved when you submit the PT Assessment form:

1. Complete your anatomical selections
2. Fill out other required form fields
3. Click **Save** at the bottom of the form
4. All selections are saved to the database

**Important**: Don't navigate away from the form without saving, or you'll lose your selections.

## Tips for Physical Therapists

### Best Practices for Documenting Findings

#### 1. Start Broad, Then Focus

**Do**: Click on general region first (e.g., "Right Shoulder")
**Then**: Drill down to specific structure (e.g., "Supraspinatus")

**Don't**: Try to click the exact muscle on the full-body view (too small, hard to click)

#### 2. Use Appropriate Severity Scales

**Severity rating** can represent different measures depending on structure type:

| Structure | Severity Scale |
|-----------|----------------|
| Muscle | 0=Normal strength → 10=Complete paralysis |
| Ligament | 0=Stable → 10=Complete rupture |
| Joint | 0=Normal ROM → 10=Ankylosis/complete loss |
| Tendon | 0=No tendinopathy → 10=Complete rupture |

Be consistent within your practice for easier progress tracking.

#### 3. Document Bilateral Comparisons

If assessing both sides:

1. Select right side structure
2. Enter findings for right
3. Navigate back to body view (click "Body" breadcrumb)
4. Select left side structure
5. Enter findings for left
6. Compare severity/pain levels in the sidebar

**Example: Knee OA comparison**:
- Right Knee: Severity 6/10, Pain 5/10
- Left Knee: Severity 3/10, Pain 2/10

#### 4. Use Notes for Objective Measures

Don't just rely on sliders. Add specific measurements in the Notes field:

**Good examples**:
- "ROM: Shoulder flexion 120° (limited by pain at end range)"
- "MMT: 4/5 strength in external rotation"
- "Palpation: Tenderness over supraspinatus insertion"
- "Special tests: Positive Neer's, negative Hawkins-Kennedy"

**Vietnamese examples**:
- "Biên độ chuyển động: Gập vai 120° (bị đau ở cuối biên độ)"
- "Sức cơ: 4/5 khi xoay ngoài"

#### 5. Select Multiple Structures When Needed

Don't limit yourself to one structure. For complex injuries, select all involved tissues:

**Example: Ankle sprain**:
- ATFL (Anterior Talofibular Ligament): Severity 7, Pain 8
- CFL (Calcaneofibular Ligament): Severity 4, Pain 5
- Peroneus brevis tendon: Severity 3, Pain 4
- Lateral malleolus (bone): Severity 0, Pain 6 (palpation tenderness)

### Using with Vietnamese Patients

#### Language Switching

The form detects your language preference setting. To change language:

1. At the top of the PT Assessment form, find **Language Preference**
2. Select **Vietnamese** or **English**
3. The anatomy selector automatically updates labels

**What changes**:
- All region names in tooltips
- Breadcrumb navigation
- Layer labels
- Button text
- Finding dialog labels

**What stays the same**:
- The visual diagrams
- Your previous selections
- Severity/pain ratings

#### Explaining to Patients

**In Vietnamese**, you can show patients the diagram and explain:

"Tôi sẽ chọn các vùng trên cơ thể nơi anh/chị bị đau. Sau đó tôi sẽ đánh giá mức độ nghiêm trọng và mức độ đau. Điều này giúp chúng tôi theo dõi tiến triển của anh/chị qua các buổi điều trị."

**Translation**: "I will select the regions on the body where you have pain. Then I'll rate the severity and pain level. This helps us track your progress across treatment sessions."

#### Bilingual Notes

You can mix languages in the Notes field:

**Example**:
```
Pain with overhead activities.
Đau khi nâng tay qua đầu.
Aggravating factors: Lifting, reaching.
```

This is helpful when:
- Documenting patient's exact words
- Translating for other providers
- Creating bilingual reports

### Common Clinical Scenarios

#### Scenario 1: Lumbar Disc Herniation

**Steps**:
1. Click **Back View**
2. Click **Lumbar Spine**
3. Click **L4-L5 Disc** (if radiculopathy suspected)
4. Severity: 7, Pain: 8
5. Notes: "Positive SLR at 45°, decreased L5 sensation"
6. Also select **L5 Nerve Root** (if visible with Nerves layer)

#### Scenario 2: Rotator Cuff Tear

**Steps**:
1. Click **Front View**
2. Click **Right Shoulder** (or left)
3. Toggle layers: Show **Muscles**, **Tendons**, hide others
4. Click **Supraspinatus** muscle
5. Severity: 9 (suspected full-thickness tear), Pain: 8
6. Notes: "Positive drop arm test, unable to hold 90° abduction"
7. Click **Supraspinatus tendon** if separately selectable

#### Scenario 3: ACL Reconstruction Post-Op

**Steps**:
1. Click **Front View**
2. Click **Right Knee**
3. Show **Ligaments** layer, hide **Muscles**
4. Click **ACL** (Anterior Cruciate Ligament)
5. Severity: 3 (post-surgical, healing well), Pain: 4
6. Notes: "6 weeks post-op, ROM 0-110°, quad strength 4/5"
7. Optional: Also select **Quadriceps** to document weakness

#### Scenario 4: Plantar Fasciitis

**Steps**:
1. Click **Front View** (or Back View)
2. Click **Right Foot**
3. Show **Ligaments** and **Tendons** layers
4. Click **Plantar Fascia** (if available as selectable structure)
5. Severity: 6, Pain: 7 (especially morning pain)
6. Notes: "Tenderness at medial calcaneal tubercle, tight gastroc/soleus"

#### Scenario 5: Multiple Regions (Chronic Pain)

For patients with widespread pain (fibromyalgia, chronic pain syndrome):

**Steps**:
1. Start with **Front View**
2. Select multiple regions:
   - Bilateral shoulders: Severity 5, Pain 6
   - Lumbar spine: Severity 6, Pain 7
   - Bilateral knees: Severity 4, Pain 5
3. Switch to **Back View**
4. Continue selections:
   - Cervical spine: Severity 5, Pain 6
   - Bilateral gluteal: Severity 4, Pain 5
5. Review all selections in sidebar before saving
6. Add global note about widespread nature

**Tip**: For chronic pain patients, use the Notes field to document whether pain is constant or intermittent, and any patterns you observe.

### Shortcuts and Efficiency Tips

#### Keyboard Navigation (Future Feature)

Currently, the anatomy selector requires mouse/touch interaction. Keyboard shortcuts may be added in future versions.

#### Quick Selection for Repeat Patients

For follow-up visits, you can:

1. Open the previous assessment
2. View the anatomical selections
3. Create new assessment
4. Re-select the same regions
5. Update severity/pain ratings to track progress

**Tip**: Keep a note template for common conditions (e.g., "Shoulder Protocol Week 1") to speed up documentation.

#### Using with Exercise Prescription

After documenting affected regions:

1. Save the PT Assessment
2. Open the **Exercise Prescription** form
3. Reference the anatomical selections when choosing exercises
4. Target specific muscles/joints you've identified

**Example**: If you selected "Rotator cuff" muscles as weak, prescribe:
- External rotation exercises
- Scapular stabilization
- Posterior capsule stretching

#### Printing for Patient Education

The anatomy selector can be printed:

1. Make your selections
2. Use browser **Print Preview** (Ctrl+P / Cmd+P)
3. Print styles automatically hide controls and show only:
   - The anatomical diagram with highlights
   - List of selected regions
   - Severity and pain ratings

This creates a visual handout for patients showing their problem areas.

## Frequently Asked Questions

### Q: Can I select the same region twice?

**A**: No. Each region can only be selected once. If you click an already-selected region, it deselects (removes the selection).

To change the severity/pain rating:
1. Remove the selection (click X)
2. Click the region again
3. Enter new ratings

### Q: What if I can't find the structure I need?

**A**: The anatomy database contains major structures commonly assessed in PT. If a specific structure isn't available:

1. Select the parent region (e.g., "Shoulder" if specific muscle missing)
2. Use the **Notes** field to specify the exact structure
3. Example: Select "Shoulder", Notes: "Specific finding: Infraspinatus tendinopathy"

Contact your administrator to request additional structures be added to the database.

### Q: Can I edit notes after saving the form?

**A**: Yes. Open the saved PT Assessment in edit mode:

1. Go to patient's encounter
2. Click on the saved form
3. The anatomy selector loads with previous selections
4. Remove and re-add any selection to change notes
5. Save the form again

**Note**: This creates a new version; the original timestamp is preserved in the database.

### Q: How do I document bilateral findings?

**A**: Select each side separately:

1. Select right side structure (e.g., "Right Shoulder")
2. Enter findings for right
3. Navigate back to body view
4. Select left side structure (e.g., "Left Shoulder")
5. Enter findings for left

Both will appear in your selections list.

**Tip**: For identical bilateral findings, you can use copy/paste for the Notes field text.

### Q: What if the SVG doesn't load?

**A**: If you see "Could not load anatomy diagram":

1. **Check your internet connection** (if SVGs are hosted remotely)
2. **Refresh the page** (Ctrl+R / Cmd+R)
3. **Clear browser cache** and reload
4. **Try a different browser** (Chrome, Firefox, Safari recommended)
5. **Contact IT support** if issue persists

The SVG files should be stored locally in `/public/assets/anatomy/`, so loading should be fast.

### Q: Can I use this on a tablet/phone?

**A**: Yes! The anatomy selector is mobile-responsive:

- **Tablets**: Full functionality, touch-enabled
- **Phones**: Works but may be cramped (landscape mode recommended)

**Touch gestures**:
- **Tap** = Click (select region)
- **Pinch zoom** = Zoom in/out (browser-level, not built-in yet)

**Tip**: For small screens, use the layer controls to hide unnecessary structures and reduce visual clutter.

### Q: How is severity different from pain?

**A**:

**Severity** = Clinical assessment of tissue damage/dysfunction
- Based on your objective findings
- ROM limitations, strength deficits, instability
- Example: "Grade 2 MCL sprain" = Severity 6/10

**Pain** = Patient's subjective pain experience
- Based on patient report
- Use standard pain scales (VAS, NRS)
- Example: Patient rates knee pain as 7/10

A patient can have:
- High severity, low pain (e.g., chronic stable rotator cuff tear, adapted)
- Low severity, high pain (e.g., acute muscle spasm, highly irritable)

Both ratings help track progress over time.

### Q: Can I export the anatomical selections?

**A**: Currently, selections are stored in the database and visible when viewing the saved PT Assessment form.

**Future features** may include:
- PDF export with diagram and selections
- CSV export for research/reporting
- Integration with exercise prescription module

Contact your administrator for custom export options.

### Q: How accurate is the anatomy?

**A**: The anatomy diagrams are simplified representations for clinical documentation purposes. They are:

- **Based on standard anatomical texts** (Gray's Anatomy, Netter's)
- **Use FMA (Foundational Model of Anatomy) codes** where applicable
- **Sufficient for PT clinical documentation** and communication

**Not intended for**:
- Surgical planning
- Radiological correlation
- Detailed research

For complex cases requiring precise anatomical detail, refer to imaging (MRI, X-ray, CT) in conjunction with this tool.

### Q: What languages are supported?

**A**: Currently supported:
- **English** (en)
- **Vietnamese** (vi)

All anatomical terms, UI labels, and tooltips appear in both languages. The language preference is set at the form level.

**Future languages**: May be added based on demand. Contact your administrator.

## Getting Help

### Training Resources

- **Video tutorials**: Check your organization's training portal
- **Live training sessions**: Contact your PT department supervisor
- **User manual**: This document (print or save PDF for reference)

### Technical Support

**For technical issues** (SVGs not loading, buttons not working, errors):

1. **Check browser console** (F12 → Console tab) for error messages
2. **Screenshot the issue** including any error messages
3. **Contact IT support** with:
   - Browser name and version
   - Steps to reproduce the issue
   - Screenshots
   - Patient ID (if relevant, de-identified)

**For clinical questions** (which region to select, how to rate severity):

1. **Consult PT clinical supervisor**
2. **Review PT assessment protocols** for your organization
3. **Refer to anatomy references** (Netter's, Gray's Anatomy)

### Feedback and Feature Requests

To suggest improvements or request new anatomical regions:

1. **Email**: Your PT department administrator
2. **Include**:
   - Specific structure needed (with FMA code if known)
   - Clinical use case (why it's important)
   - Frequency of need (how often you'd use it)

**Common requests already planned**:
- More detailed hand/foot anatomy
- Cervical spine structures
- Pelvic floor muscles
- Additional nerve pathways

---

## Quick Reference Card

### Common Actions

| Action | Steps |
|--------|-------|
| Switch view | Click **Front View** or **Back View** button |
| Select region | Click on body diagram region |
| Drill down | Click region with drill-down enabled |
| Go back | Click breadcrumb item (e.g., "Body") |
| Toggle layer | Check/uncheck layer in sidebar |
| Add selection | Click structure → Fill form → **Add Finding** |
| Remove selection | Click **X** next to selection in list |
| Clear all | Click **Clear** button (bottom of sidebar) |
| Save | Click **Save** on main form (bottom of page) |
| Zoom in | Click **+** zoom button |
| Zoom out | Click **-** zoom button |
| Reset zoom | Click reset button (circular arrow) |

### Severity Scale Quick Guide

| Rating | Meaning | Examples |
|--------|---------|----------|
| 0-2 | Minimal | Slight tightness, trace weakness, minor inflammation |
| 3-4 | Mild | Grade 1 strain, mild sprain, slight ROM limitation |
| 5-6 | Moderate | Grade 2 strain/sprain, noticeable weakness, mod ROM loss |
| 7-8 | Severe | Grade 3 sprain, significant tear, marked dysfunction |
| 9-10 | Very Severe | Complete rupture, severe instability, complete loss of function |

### Pain Scale Quick Guide (0-10 NRS)

| Rating | Description |
|--------|-------------|
| 0 | No pain |
| 1-3 | Mild pain (annoying but doesn't interfere with activities) |
| 4-6 | Moderate pain (interferes with activities, may wake from sleep) |
| 7-9 | Severe pain (difficult to perform activities, dominates thoughts) |
| 10 | Worst pain imaginable (unable to function) |

---

**Document Version**: 1.0
**Last Updated**: 2025-12-25
**For**: OpenEMR Vietnamese Physiotherapy Module

<!-- AI-GENERATED: Claude Code -->
