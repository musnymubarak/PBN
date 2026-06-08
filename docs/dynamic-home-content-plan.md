# Dynamic Home Sliders & Customizable Chapter Posters — Implementation Plan

> Goal: let admins change the **home carousel** (content, order, scheduling, audience)
> and **chapter posters** from the admin panel **without shipping a new mobile build**.

## 1. The principle: server-driven content

The mobile app ships a *generic slide renderer*. The actual content (images, text,
order, links, schedule, audience) lives in the database and is fetched at runtime
from `GET /home/slides`. The app loops over whatever the server returns and renders
each slide. Admins edit slides in the existing React admin panel.

This is the same pattern Instagram / LinkedIn / banking / food-delivery apps use for
their home banners. The one real limitation: a button can only trigger behaviors the
app already understands (see **Action vocabulary** below). New *content/order/links* =
no app update. A genuinely *new behavior* = still needs a release.

### Slide types

Each slide has a `slide_type` so we keep today's behavior while enabling full control:

| `slide_type`          | Behavior |
|-----------------------|----------|
| `custom`              | Fully admin-authored (like today's "Network Growth" promo). |
| `next_virtual_event`  | Backend auto-fills it with the next upcoming **virtual** event. |
| `next_physical_event` | Backend auto-fills it with the next upcoming **physical** event. |

The two dynamic types reproduce today's slides 2 & 3 (which read live event data) but
are now reorderable and toggleable like any other slide.

## 2. Data model

### New table `home_slides`

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (pk) | |
| `slide_type` | enum(`custom`,`next_virtual_event`,`next_physical_event`) | static vs auto-event |
| `badge_label` | varchar(60)? | the "NETWORK GROWTH" tag |
| `title` | varchar(160)? | headline |
| `subtitle` | text? | supporting copy |
| `image_url` | varchar(500)? | `/static/banners/...` (uploaded) or full URL |
| `cta_label` | varchar(60)? | button text |
| `cta_action_type` | enum(`none`,`route`,`url`,`event`,`maps`) | **fixed vocabulary** the app understands |
| `cta_action_value` | varchar(500)? | route name / URL / event id / maps query |
| `sort_order` | int | ordering |
| `is_active` | bool | on/off toggle |
| `starts_at` | timestamptz? | schedule window start (null = open) |
| `ends_at` | timestamptz? | schedule window end (null = open) |
| `audience_roles` | jsonb? | e.g. `["MEMBER","PROSPECT"]`; null = everyone |
| `audience_chapter_ids` | jsonb? | list of chapter UUIDs; null = all chapters |
| `created_at` / `updated_at` | timestamptz | |

### Chapters: one new column

`chapters.poster_url varchar(500) null` — the chapter banner/hero image.

## 3. Backend (FastAPI)

New feature folder `backend/app/features/home_content/` (model lives in
`backend/app/models/home_content.py`), registered in `main.py` like every other router.

### Endpoints

Public (any authenticated member):
- `GET /home/slides` — returns only slides that are **active**, within their
  **schedule window**, and that **match the caller's role + chapter**. Dynamic slides
  are resolved here with the next event. Targeting is done **server-side**, so the app
  needs zero filtering logic.

Admin (`require_role([SUPER_ADMIN, ADMIN])`):
- `GET    /admin/home/slides` — list all (incl. inactive)
- `POST   /admin/home/slides` — create
- `PATCH  /admin/home/slides/{id}` — update
- `DELETE /admin/home/slides/{id}` — delete
- `POST   /admin/home/slides/reorder` — body `{ordered_ids: [...]}`
- `POST   /admin/home/slides/upload-image` — reuses the existing image-upload pattern
  (5 MB cap, JPEG/PNG/WebP) → saves to `uploads/banners/`, returns `/static/banners/...`

Chapter poster:
- `POST /chapters/{id}/upload-poster` (admin) → saves to `uploads/chapter-posters/`,
  sets `chapters.poster_url`. `poster_url` is also added to the chapter
  create/update/response payloads.

### Migration + seed

One Alembic revision (down_revision = current head `c9f3e1a7b5d2`):
1. create the two enum types
2. create `home_slides`
3. add `chapters.poster_url`
4. **seed the existing 3 slides** so the home screen looks identical on day one
   (custom promo + next_virtual_event + next_physical_event).

## 4. Action vocabulary (CTA dispatch)

Buttons are data-driven. `cta_action_type` + `cta_action_value`:

| `cta_action_type` | `cta_action_value` | App behavior |
|-------------------|--------------------|--------------|
| `none`            | —                  | No button |
| `route`           | route name, e.g. `create_referral`, `events`, `marketplace` | In-app navigation |
| `url`             | `https://…`        | Open in browser / launch URL (also used for Zoom links) |
| `event`           | event id           | Open the event detail screen |
| `maps`            | location query     | Open maps (today's "VIEW LOCATION") |

Seed the route vocabulary with every screen you may want to deep-link to. New slides
reuse these; only a brand-new behavior requires an app release.

## 5. Mobile (Flutter) — Phase 3

- `mobile/lib/models/home_slide.dart` — generic slide model (mirrors `NextEvent`).
- `mobile/lib/core/services/home_content_service.dart` — fetches `/home/slides`, and
  **caches via `PrefsService.setJson('cache_home_slides', …)`** so the carousel paints
  instantly and works offline; reads cache on network failure.
- `slide_action.dart` — maps `(cta_action_type, value)` → navigation / `url_launcher` /
  maps, reusing the dispatch logic already in `dashboard_page.dart`.
- Refactor `dashboard_page.dart`: collapse the three hardcoded panel builders into one
  data-driven `_buildSlidePanel(HomeSlide)` (same navy + gold styling), drive the
  `PageView` from `slides.map(...)`, and make the indicator + auto-rotate timer use
  `slides.length` instead of the hardcoded `3`. If the list is empty and there's no
  cache, fall back to the current 3 hardcoded panels.
- Chapter posters: add `posterUrl` to `chapter.dart`; render it as a hero header on the
  chapter cards/detail when present, else keep the current gradient + icon.

## 6. Admin panel (React) — Phase 2

- `lib/api.js`: add `listHomeSlides`, `createHomeSlide`, `updateHomeSlide`,
  `deleteHomeSlide`, `reorderHomeSlides`, `uploadHomeSlideImage` (FormData, like
  `uploadEventImage`), plus `uploadChapterPoster`.
- New page `adminpanel/src/content/HomeSlidesPage.jsx`: list with drag/up-down reorder +
  live preview, active toggle, and an edit modal exposing all fields — image upload,
  title/subtitle/badge, CTA type+value, schedule start/end, audience roles + chapters.
- Register the tab in `App.jsx` `renderContent()` and add a menu entry to
  `components/layout/menuConfig.js`.
- Chapters page: add a poster upload + preview to the existing chapter edit form.

## 7. Rollout sequence

1. **Phase 1 — Backend** (this phase): model, migration + seed, public/admin endpoints,
   chapter poster column + upload. Verifiable via Swagger.
2. **Phase 2 — Admin panel**: Home Slides page + chapter poster upload.
3. **Phase 3 — Mobile**: cached service + dynamic carousel + chapter poster hero.

## 8. Notes / risks

- **Persistence**: `uploads/` must sit on a persistent Docker volume — banners and
  posters live there alongside event/profile images.
- **Auth on `/home/slides`**: required so server-side audience targeting works; the
  dashboard is already authenticated, so no UX change.
- **Caching/staleness**: banners tolerate slight staleness; the app refetches on each
  dashboard load and falls back to the last cached list offline.
- **Enum storage**: the home-slide enums use `values_callable` so DB labels match the
  lowercase string values the API/app exchange — avoids the name-vs-value mismatch.
