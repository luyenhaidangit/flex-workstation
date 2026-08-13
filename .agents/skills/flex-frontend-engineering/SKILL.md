---
name: flex-frontend-engineering
description: Build and modify Angular UI (components, HTML templates, SCSS, forms, modals, tables) in flex-microfrontend using the existing Skote/Bootstrap 5 design system instead of ad-hoc markup. Use when creating or editing pages, list/table views, modals, reactive forms, or any user-facing screen in this repo, or when a screen's look/behavior feels inconsistent with the rest of the app.
---

# Flex Frontend Engineering (Angular + Skote)

## Overview

`flex-microfrontend` is Angular 16 on the Skote Bootstrap 5 admin template. There is no separate design-system package — the "design system" is the set of shared components under `src/app/shared/ui/` and `src/app/core/components/`, plus recurring Bootstrap utility patterns already used across `src/app/pages/**`. New screens must **reuse these**, not reinvent tables, modals, badges, or loading states from raw Bootstrap classes.

This skill is descriptive of what the codebase already does (verified against `pages/master/issuer/*` and `pages/system/user/*`), not a generic Angular/Bootstrap style guide. When in doubt, grep for a sibling screen under `pages/master/` or `pages/system/` and match it rather than inventing a new pattern.

## When to Use

- Building a new list/table page, detail view, or form
- Adding or editing a modal (create/edit/delete/approve/reject/detail)
- Touching reactive forms and needing validation UX
- A generated screen "doesn't look right" — check it against the patterns below before guessing

## Required checks before writing markup

1. Find an existing screen doing the same job (list page, CRUD modal, approval flow) under `pages/master/` or `pages/system/` and use it as the template.
2. Check `src/app/shared/ui/*` and `src/app/core/components/pagination/` for a component that already does what you're about to build by hand.
3. Feature module (`*.module.ts`) **must** import `SharedModule` (provides `safeField` pipe) and `PaginationModule` (provides `<app-pagination>`).
4. Never write a custom modal backdrop, spinner, or table skeleton — the patterns below exist precisely so nothing does that.

## Shared components — use these, don't hand-roll

| Need | Component/selector | Source |
| --- | --- | --- |
| Page header + breadcrumb | `<app-page-title [title]="..." [breadcrumbItems]="...">` | `shared/ui/pagetitle` |
| Tabs (e.g. approved/pending) | `<app-tabs [tabs]="..." [activeId]="..." (activeIdChange)="...">` | `shared/ui/tab` |
| Table loading placeholder | `<app-skeleton [width]="..." height="18px">` inside skeleton `<tr>` rows | `shared/ui/skeleton` |
| Status/action pill | `<app-badge [value]="..." [customConfigs]="...">` | `shared/ui/badge` |
| List pagination | `<app-pagination [paginationState]="..." [pageSizeOptions]="..." (pageChanged)="..." (pageSizeChanged)="...">` | `core/components/pagination` |
| Inline loading state | `shared/ui/loader` / `shared/ui/loading` | pick loader for small inline spots, loading for full-section states |
| Null-safe display | `{{ value \| safeField }}` | `shared/pipes/safe-field.pipe.ts` |
| Uppercase code inputs, no spaces | `appUpperNoSpace` directive | `shared/directives/upper-nospace.directive.ts` |
| Uppercase code inputs, no accents | `appUpperNoAccent` directive | `shared/directives/upper-noaccent.directive.ts` |

If a screen needs something not in this table, check whether a near-identical widget already exists before writing new CSS/markup from scratch.

## List/table page pattern

Structure (see `pages/master/issuer/issuer.component.html` as the reference):

```html
<div class="container-fluid">
  <app-page-title [title]="CONFIG.breadcrumb.title" [breadcrumbItems]="CONFIG.breadcrumb.items"></app-page-title>
  <div class="bg-white rounded shadow-sm p-3">
    <app-tabs ...></app-tabs> <!-- only if the page has tabs -->

    <div class="row gx-3 mb-3 gy-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label fw-bold text-muted">Từ khóa</label>
        <input class="form-control" type="text" placeholder="Nhập từ khóa..." [(ngModel)]="searchInputValue" (keyup.enter)="onSearchClick()">
      </div>
      <div class="col-auto">
        <button class="btn btn-primary w-100" (click)="onSearchClick()">
          <i class="bx bx-search-alt-2"></i> Tìm kiếm
        </button>
      </div>
      <div class="col-auto text-md-end">
        <button type="button" class="btn btn-success fw-bold" (click)="openCreateModal()">
          <i class="fas fa-plus me-1"></i> Thêm mới
        </button>
      </div>
    </div>

    <div class="table-responsive table-header-primary">
      <table class="table align-middle table-nowrap dt-responsive nowrap w-100">
        <thead>
          <tr>
            <th *ngFor="let col of CONFIG.table.columns" [style.width]="col.width">{{ col.label }}</th>
          </tr>
        </thead>
        <tbody *ngIf="loadingTable">
          <tr *ngFor="let _ of [].constructor(CONFIG.table.skeleton.rows)">
            <td *ngFor="let w of CONFIG.table.skeleton.columns">
              <app-skeleton [width]="w" height="18px"></app-skeleton>
            </td>
          </tr>
        </tbody>
        <tbody *ngIf="!loadingTable && items.length">
          <tr *ngFor="let item of items">
            <!-- real row cells -->
          </tr>
        </tbody>
        <tbody *ngIf="!loadingTable && !items.length">
          <tr><td [attr.colspan]="CONFIG.table.columns.length" class="text-center text-muted">Không có dữ liệu</td></tr>
        </tbody>
      </table>
    </div>

    <app-pagination
      [paginationState]="getPaginationState()"
      [pageSizeOptions]="CONFIG.pagination.pageSizeOptions"
      (pageChanged)="onPageChange($event)"
      (pageSizeChanged)="onPageSizeChange($event)">
    </app-pagination>
  </div>
</div>
<!-- modals declared after the closing container div, one <app-*-modal> per action -->
```

Rules:
- Component SCSS file **must** contain `@import 'src/assets/scss/core_table';` so that `.table-header-primary` correctly applies the light-blue table header background (`#EAF4FF`).
- Table config (columns, skeleton column widths/row count, pagination options) lives in a `*.config.ts` file next to the component — follow `issuer.config.ts`.
- Action buttons in a table row are `btn btn-link p-0 ms-2 text-<semantic>` icon buttons (`text-info` view, `text-warning` edit, `text-danger` delete/reject, `text-success` approve), wrapped in a `td class="action-column"`. Never use full bordered buttons inside a row.
- Always render the three `<tbody>` states (loading skeleton / data / empty). A table missing the empty state is incomplete.

## Modal pattern

Modals are separate components (`<name>-modal.component.{ts,html,scss}`), not `ngbModal`/`NgbModal` service calls.

All CRUD modals (Create, Edit, Delete, Detail) **must** use `modal-dialog modal-xl` for consistent sizing across pages.

Modal SCSS file **must** contain `@import 'src/assets/scss/core_modal';`.

### Create / Edit Modal Structure (see `create-issuer-modal.component.html` and `edit-issuer-modal.component.html`):

```html
<div class="modal fade show d-block" *ngIf="isVisible" tabindex="-1" role="dialog" style="background-color: rgba(0,0,0,0.5);">
  <div class="modal-dialog modal-xl" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title fw-semibold" [ngClass]="isEditMode ? 'text-warning' : 'text-success'">
          <i class="fas me-2" [ngClass]="isEditMode ? 'fa-edit' : 'fa-plus-circle'"></i>{{ isEditMode ? 'Chỉnh sửa' : 'Thêm mới' }}
        </h5>
        <button type="button" class="btn-close" (click)="onCancel()"></button>
      </div>
      <form [formGroup]="form" (ngSubmit)="onSubmit()" class="needs-validation">
        <div class="modal-body px-4 py-3">
          <div *ngIf="isLoadingInitial" class="text-center py-4"><div class="spinner-border text-primary"></div></div>
          <div *ngIf="!isLoadingInitial" class="row gy-3">
            <!-- Form fields (2-column layout via col-md-6) -->
            <!-- Always include Status dropdown for entities with active/inactive states -->
            <div class="col-md-6 position-relative">
              <label class="form-label">Trạng thái <span class="text-danger">*</span></label>
              <select class="form-select" formControlName="status" [ngClass]="{'is-invalid': isFieldInvalid('status')}">
                <option value="active">Hoạt động</option>
                <option value="inactive">Không hoạt động</option>
              </select>
              <div *ngIf="isFieldInvalid('status')" class="invalid-tooltip">{{ getFieldError('status') }}</div>
            </div>
          </div>
        </div>
        <div class="modal-footer border-top-0">
          <button type="button" class="btn btn-outline-secondary me-2" (click)="onCancel()" [disabled]="isSubmitting">Hủy</button>
          <button type="submit" [ngClass]="isEditMode ? 'btn btn-warning' : 'btn btn-success'" [disabled]="isSubmitting || form.invalid">
            <i class="fas fa-save me-1" *ngIf="!isSubmitting"></i>
            <span class="spinner-border spinner-border-sm me-1" *ngIf="isSubmitting"></span>
            {{ isSubmitting ? 'Đang lưu...' : (isEditMode ? 'Cập nhật' : 'Tạo mới') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
```

### Delete Confirmation Modal Structure (see `delete-issuer-modal.component.html`):

```html
<div class="modal fade show d-block" *ngIf="isVisible" tabindex="-1" role="dialog" style="background-color: rgba(0,0,0,0.5);">
  <div class="modal-dialog modal-xl" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title text-danger fw-semibold">
          <i class="fas fa-trash-alt me-2"></i>Xóa
        </h5>
        <button type="button" class="btn-close" (click)="onCancel()"></button>
      </div>
      <div class="modal-body px-4 py-3">
        <!-- Info Card -->
        <div class="card border-0 bg-light mb-3">
          <div class="card-body">
            <h6 class="card-title text-muted mb-3"><i class="fas fa-info-circle me-2"></i>Thông tin sẽ xóa</h6>
            <div class="row gy-2">
              <!-- Item summary details with app-badge for status -->
            </div>
          </div>
        </div>
        <!-- Warning Alert -->
        <div class="alert alert-warning d-flex align-items-center mb-0" role="alert">
          <i class="fas fa-exclamation-triangle me-2"></i>
          <div><strong>Cảnh báo:</strong> Thao tác này không thể hoàn tác.</div>
        </div>
      </div>
      <div class="modal-footer border-top-0">
        <button type="button" class="btn btn-outline-secondary me-2" (click)="onCancel()" [disabled]="isSubmitting">Hủy</button>
        <button type="button" class="btn btn-danger" [disabled]="isSubmitting" (click)="onConfirm()">
          <i class="fas fa-trash me-1" *ngIf="!isSubmitting"></i>
          <span class="spinner-border spinner-border-sm me-1" *ngIf="isSubmitting"></span>
          {{ isSubmitting ? 'Đang xóa...' : 'Xác nhận xóa' }}
        </button>
      </div>
    </div>
  </div>
</div>
```

Component contract:
- `@Input() isVisible: boolean`, `@Output() close: EventEmitter<void>`. Create/edit/delete emit a matching result event (`created`/`updated`/`deleted`) so the parent list can refetch.
- Semantic color is consistent between the header title, header icon, and submit button: create = `success`, edit = `warning`, delete/reject = `danger`, detail/approve = `info`/`primary` — match `text-<color>` on `.modal-title` to `btn-<color>` on submit.
- Load remote data for edit/detail only once per open (`hasLoadedData` guard in `ngOnChanges`/`ngOnInit`), not on every change detection cycle.

## Reactive form validation UX

Every field follows this shape — do not invent a different validation display:

```html
<div class="col-md-6 position-relative">
  <label class="form-label">Field name <span class="text-danger">*</span></label>
  <input class="form-control" formControlName="x" [ngClass]="{'is-invalid': isFieldInvalid('x')}" />
  <div *ngIf="isFieldInvalid('x')" class="invalid-tooltip">{{ getFieldError('x') }}</div>
</div>
```

`isFieldInvalid(field)` / `getFieldError(field)` are re-implemented per modal component today (not shared) — copy the existing implementation from a sibling modal (e.g. `edit-issuer-modal.component.ts`) rather than writing new validation-message logic.

Non-editable/system fields (e.g. codes after creation) use `class="form-control non-editable-field"` with `readonly` and a `form-text text-muted` hint below (`<i class="fas fa-info-circle me-1"></i>...`), not a disabled input.

## Styling

- **List Component SCSS**: Must include `@import 'src/assets/scss/core_table';` to apply `.table-header-primary` table header styling (`#EAF4FF` background).
- **Modal Component SCSS**: Must include `@import 'src/assets/scss/core_modal';`.
- Don't write new top-level SCSS for a page/modal beyond these imports. Component-level `.scss` files in this codebase are typically near-empty (1–2 lines) — layout comes from Bootstrap utility classes in the template, not custom CSS.
- Icons are Font Awesome (`fas fa-*`) for actions/buttons and boxicons (`bx bx-*`) for search/nav spots — match existing usage; don't mix icon sets arbitrarily.
- Spacing/layout is Bootstrap grid + gap utilities (`row gx-3 gy-2`, `col-md-*`, `me-*`/`mt-*`), not custom margin/padding CSS.

## Naming

- Selector prefix `app-`, kebab-case, domain-specific (`app-edit-issuer-modal`, not `app-modal-2`).
- Component folder = one feature/modal, colocating `.ts`/`.html`/`.scss` (and `.config.ts`/`.models.ts` for list pages).
- All user-facing text (labels, placeholders, toasts, confirmations) is Vietnamese; keep code identifiers (variables, methods, selectors) in English.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just use Angular Material/NgbModal, it's faster" | The repo has no such dependency wired into the design language — it introduces a second, inconsistent visual system alongside Skote/Bootstrap for one screen. |
| "A custom SCSS file is cleaner than inline utility classes" | Every sibling screen in this repo uses Bootstrap utilities with a near-empty component `.scss`. A large custom stylesheet is a fork of the design system, not an improvement. |
| "Skipping the empty/loading state saves time, I'll add it later" | The three-state `<tbody>` pattern (skeleton/data/empty) is what every existing list page does — a table missing it reads as unfinished, not simplified. |
| "I'll write my own validation message logic, it's just a few lines" | `isFieldInvalid`/`getFieldError` + `invalid-tooltip` is the established pattern across every modal — a different validation UI on one screen breaks consistency for no benefit. |
| "The color doesn't really matter, I'll just use btn-primary everywhere" | Action color is semantic (success=create, warning=edit, danger=delete/reject, info/primary=view/approve) and tied consistently to header + icon + submit button — using primary for a delete action misleads the user. |

## Red Flags

- Missing `@import 'src/assets/scss/core_table';` in list component `.scss` (causes white/un-styled table headers instead of `#EAF4FF`)
- Missing `@import 'src/assets/scss/core_modal';` in modal component `.scss`
- A CRUD modal using `modal-lg` or `modal-md` instead of `modal-xl`
- A Create/Edit form missing the Status dropdown (Hoạt động / Không hoạt động) when the entity has an active/inactive state
- Missing `SharedModule` or `PaginationModule` imports in feature `*.module.ts`
- A table with only a "data" `<tbody>` and no skeleton-loading or empty-state branch
- A modal built with `NgbModal`/a modal service instead of the `isVisible`/`@Output() close` component pattern
- A hardcoded status/action label+color pair in a template instead of `app-badge`
- A new page-level or component-level `.scss` file with more than a few lines of custom layout/spacing CSS
- A disabled (`disabled`) system-controlled field where the existing convention is `readonly` + `non-editable-field` + `form-text` hint

## Verification

- [ ] Feature `*.module.ts` imports `SharedModule` (`safeField` pipe) and `PaginationModule` (`<app-pagination>`)
- [ ] List `.scss` includes `@import 'src/assets/scss/core_table';` and `.table-header-primary` is applied to `.table-responsive`
- [ ] Modal `.scss` includes `@import 'src/assets/scss/core_modal';`
- [ ] All CRUD modals use `modal-dialog modal-xl`
- [ ] Create/Edit modal includes Status dropdown (`active` / `inactive`) when applicable
- [ ] List/table pages render all three `<tbody>` states: skeleton loading, data, empty
- [ ] Modals follow the `isVisible` input / `close` output / result-event contract, not a modal service
- [ ] Shared components (`app-page-title`, `app-tabs`, `app-skeleton`, `app-badge`, `app-pagination`, `safeField` pipe) are reused instead of re-implemented
- [ ] Form fields use `isFieldInvalid`/`getFieldError` + `invalid-tooltip`, copied from an existing modal, not a new validation UI
- [ ] Action/semantic colors are consistent between modal title, icon, and submit button
