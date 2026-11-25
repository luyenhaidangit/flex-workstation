# Domain Checklist Examples & Anti-Examples (`speckit-checklist`)

Reference examples for generating domain checklists ("Unit Tests for Requirements"). Every item tests whether the **requirements** are complete, clear, consistent, measurable, and covered — never whether the implementation works.

## Sample Items by Domain

**UX Requirements Quality (`ux.md`):**
- `- [ ] CHK001 \`[High]\` \`[Status: Chưa kiểm]\` Are visual hierarchy requirements defined with measurable criteria? [Clarity, Spec §FR-1]`
- `- [ ] CHK002 \`[Medium]\` \`[Status: Chưa kiểm]\` Is the number and positioning of UI elements explicitly specified? [Completeness, Spec §FR-1]`
- `- [ ] CHK003 \`[Medium]\` \`[Status: Chưa kiểm]\` Are interaction state requirements (hover, focus, active) consistently defined? [Consistency]`
- `- [ ] CHK004 \`[High]\` \`[Status: Chưa kiểm]\` Are accessibility requirements specified for all interactive elements? [Coverage, Gap]`
- `- [ ] CHK005 \`[Low]\` \`[Status: Chưa kiểm]\` Is fallback behavior defined when images fail to load? [Edge Case, Gap]`
- `- [ ] CHK006 \`[Medium]\` \`[Status: Chưa kiểm]\` Can 'prominent display' be objectively measured? [Measurability, Spec §FR-4]`

**API Requirements Quality (`api.md`):**
- `- [ ] CHK001 \`[Blocker]\` \`[Status: Chưa kiểm]\` Are error response formats specified for all failure scenarios? [Completeness]`
- `- [ ] CHK002 \`[High]\` \`[Status: Chưa kiểm]\` Are rate limiting requirements quantified with specific thresholds? [Clarity]`
- `- [ ] CHK003 \`[Blocker]\` \`[Status: Chưa kiểm]\` Are authentication requirements consistent across all endpoints? [Consistency]`
- `- [ ] CHK004 \`[High]\` \`[Status: Chưa kiểm]\` Are retry/timeout requirements defined for external dependencies? [Coverage, Gap]`
- `- [ ] CHK005 \`[Medium]\` \`[Status: Chưa kiểm]\` Is versioning strategy documented in requirements? [Gap]`

**Performance Requirements Quality (`performance.md`):**
- `- [ ] CHK001 \`[High]\` \`[Status: Chưa kiểm]\` Are performance requirements quantified with specific metrics? [Clarity]`
- `- [ ] CHK002 \`[High]\` \`[Status: Chưa kiểm]\` Are performance targets defined for all critical user journeys? [Coverage]`
- `- [ ] CHK003 \`[Medium]\` \`[Status: Chưa kiểm]\` Are performance requirements under different load conditions specified? [Completeness]`
- `- [ ] CHK004 \`[Medium]\` \`[Status: Chưa kiểm]\` Can performance requirements be objectively measured? [Measurability]`
- `- [ ] CHK005 \`[High]\` \`[Status: Chưa kiểm]\` Are degradation requirements defined for high-load scenarios? [Edge Case, Gap]`

**Security Requirements Quality (`security.md`):**
- `- [ ] CHK001 \`[Blocker]\` \`[Status: Chưa kiểm]\` Are authentication requirements specified for all protected resources? [Coverage]`
- `- [ ] CHK002 \`[Blocker]\` \`[Status: Chưa kiểm]\` Are data protection requirements defined for sensitive information? [Completeness]`
- `- [ ] CHK003 \`[High]\` \`[Status: Chưa kiểm]\` Is the threat model documented and requirements aligned to it? [Traceability]`
- `- [ ] CHK004 \`[High]\` \`[Status: Chưa kiểm]\` Are security requirements consistent with compliance obligations? [Consistency]`
- `- [ ] CHK005 \`[Blocker]\` \`[Status: Chưa kiểm]\` Are security failure/breach response requirements defined? [Gap, Exception Flow]`

## Anti-Examples (What NOT To Write)

**WRONG — tests implementation behavior:**
```markdown
- [ ] CHK001 - Verify landing page displays 3 episode cards [Spec §FR-001]
- [ ] CHK002 - Test hover states work correctly on desktop [Spec §FR-003]
- [ ] CHK003 - Confirm logo click navigates to home page [Spec §FR-010]
```

**CORRECT — tests requirements quality:**
```markdown
- [ ] CHK001 `[Medium]` `[Status: Chưa kiểm]` Are the number and layout of featured episodes explicitly specified? [Completeness, Spec §FR-001]
- [ ] CHK002 `[Medium]` `[Status: Chưa kiểm]` Are hover state requirements consistently defined for all interactive elements? [Consistency, Spec §FR-003]
- [ ] CHK003 `[High]` `[Status: Chưa kiểm]` Are navigation requirements clear for all clickable brand elements? [Clarity, Spec §FR-010]
```
