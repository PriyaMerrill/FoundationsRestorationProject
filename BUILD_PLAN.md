# Foundations of the Restoration: Rails Build Plan

A step-by-step checklist to build and host the site in Ruby on Rails. Work top to bottom; each phase ends with something you can see working.

## The stack (decided up front)

| Need | Spec suggested | This plan uses |
|---|---|---|
| App + pages | React + React Router | Rails 8 views + Hotwire (Turbo and Stimulus) |
| Styling | Tailwind CSS | Tailwind CSS (`tailwindcss-rails`) |
| Map | Leaflet + OpenStreetMap | Same, loaded through importmap |
| Charts | Recharts or D3 | Chartkick + Chart.js (D3 only for the network diagram) |
| Historical data | JSON files | PostgreSQL, loaded from YAML seed files |
| Search | not specified | `pg_search` gem |
| Progress and scores | Local storage | Local storage (accounts are optional, Phase 12) |
| Hosting | Vercel | Render (web service + Postgres) |

No Node build step, no separate API, no background jobs.

---

## Phase 0: Set up Mac

- [x] Install a Ruby version manager: `brew install mise`
- [x] Install Ruby: `mise use --global ruby@3.4`
- [x] Install Rails: `gem install rails`
- [x] Install PostgreSQL: `brew install postgresql@17` then `brew services start postgresql@17`
- [x] Confirm all three: `ruby -v`, `rails -v`, `psql --version`

## Phase 1: Create the app

- [x] Generate it: `rails new restoration --database=postgresql --css=tailwind --skip-solid --skip-kamal`
  - `--skip-solid` leaves out the queue, cache and cable databases, which this site does not need and which complicate hosting
- [x] `cd restoration` then `bin/rails db:create`
- [x] Start it: `bin/dev` and open `http://localhost:3000`
- [x] `git add -A && git commit -m "New Rails app"`

## Phase 2: Deploy the empty app

- [x] Add `bin/render-build.sh` and make it executable (`chmod +x`):
  ```bash
  #!/usr/bin/env bash
  set -o errexit
  bundle install
  bin/rails assets:precompile
  bin/rails db:migrate
  bin/rails db:seed
  ```
- [x] In `config/database.yml`, set production to `url: <%= ENV["DATABASE_URL"] %>`
- [x] Add the Linux platform to the lockfile: `bundle lock --add-platform x86_64-linux`
- [x] Commit and push
- [x] On Render: **New > PostgreSQL**, name it `restoration-db`
- [x] On Render: **New > Web Service**, connect the GitHub repo
  - [x] Build command: `./bin/render-build.sh`
  - [x] Start command: `bundle exec puma -C config/puma.rb`
  - [x] Health check path: `/up`
- [x] Add environment variables on the web service:
  - [x] `DATABASE_URL` = the database's *Internal Database URL*
  - [x] `RAILS_MASTER_KEY` = contents of `config/master.key` (never commit this file)
  - [x] `WEB_CONCURRENCY` = `2`
- [x] Deploy and open the `onrender.com` URL
- [x] Confirm auto-deploy is on, so every push to `main` redeploys

**Done when:** the live URL responds. 

## Phase 3: Build the shared historical database

Every page reads from these tables.

**Core models**
- [x] `Place`: name, slug, modern_name, state, latitude, longitude, kinds (a list: temple, revelation site, settlement, landmark), summary, significance, start_year, end_year, trail_order
- [x] `Person`: name, slug, birth_date, death_date, roles, biography, clues (for "Who Am I?")
- [x] `Event`: title, slug, start_date, end_date, date_precision (exact, month, year, approximate), category, period, summary, context, `place_id`
- [x] `Revelation`: section_number, title, slug, received_on, date_precision, summary, subjects, context, `place_id`
- [x] `Source`: title, author, published_on, url, citation, kind (primary, secondary)

**Linking models**
- [x] `EventParticipant`: joins Event and Person, with a role
- [x] `RevelationPerson`: joins Revelation and Person
- [x] `EventRevelation`: joins Event and Revelation
- [x] `Citation`: polymorphic, joins a Source to any record, with a note and page
- [x] `Image`: polymorphic, file name, caption, credit, license, year, is_modern (for then-and-now views)

**Supporting models**
- [x] `MembershipEstimate`: year, members, is_approximate, note, `source_id`
- [x] `TriviaQuestion`: mode, difficulty, prompt, choices (JSON), answer, explanation, polymorphic link to the related record

**Steps**
- [x] Generate each model with `bin/rails g model ...` and run `bin/rails db:migrate`
- [x] Add `has_many` / `belongs_to` / `has_many :through` associations
- [x] Add validations: presence of names and titles, unique slugs
- [x] Add enums for `category`, `period`, `date_precision`
  - Categories: revelations, leadership, temples, migration, missionary work, persecution, scripture translation
  - Periods: New York, Ohio, Missouri, Nauvoo, Westward Migration
- [x] Add a `display_date` helper that respects precision (shows "c. 1829" instead of a false exact date)
- [x] Write a model test for each association


## Phase 4: Research and load the content

- [x] Create `db/seeds/` with one YAML file per type: `places.yml`, `people.yml`, `events.yml`, `revelations.yml`, `sources.yml`, `membership.yml`, `trivia.yml`
- [x] Write `db/seeds.rb` to load them with `find_or_initialize_by(slug:)` so it is safe to rerun on every deploy
- [x] Enter the places with coordinates (15 so far): Palmyra/Manchester, Harmony, Fayette, Kirtland, Independence, Liberty, Far West, Nauvoo, Winter Quarters, Salt Lake City
- [x] Enter 15 to 20 people
- [x] Enter 30 to 50 events, including the seven milestones (1820, 1823, 1829, 1830, 1836, 1844, 1847)
- [x] Enter selected Doctrine and Covenants sections with date and place (include 76, 110, 121 to 123)
- [x] Enter sources: Joseph Smith Papers, Church History Department, Doctrine and Covenants, *Saints*
- [x] Attach at least one citation to every event, revelation and membership figure
- [ ] Collect images and record the credit and license for each (public domain or properly licensed only)
- [x] Verify the drafted content against the sources: every date, place, coordinate, membership figure and trivia answer, then remove the DRAFT note at the top of each file in `db/seeds/`
- [ ] Add chapter or page notes to the citations
- [x] Run `bin/rails db:seed` and spot-check in the console
- [x] Verify the spec's worked examples exist: Kirtland (1831, 1833, March 27 1836, April 3 1836 / D&C 110), Liberty Jail (D&C 121 to 123), D&C 76 (Feb 16 1832, Hiram, Joseph Smith and Sidney Rigdon)

## Phase 5: Design system and layout

- [x] Add the palette to the Tailwind theme: forest green, antique gold, parchment, warm brown, slate
- [x] Add fonts: a classic serif for headings, a modern sans-serif for body
- [x] Build the shared layout: header or sidebar on desktop, hamburger menu on mobile (a small Stimulus controller)
- [x] Build the footer with a link to Sources and Methodology
- [x] Build reusable partials: page header, card, badge, source list, record link
- [x] Set visible focus rings and check colour contrast
- [x] Define routes: `/`, `/road-trip`, `/timeline`, `/numbers`, `/trivia`, `/explore`, `/sources`, plus `resources` for places, people, events, revelations

**Done when:** every nav link opens a placeholder page that looks right on phone and desktop.

## Phase 6: Home page

- [x] Hero with the headline "Explore the Restoration" and subtitle (photo still to add, see Final review)
- [x] Two buttons: Explore the Timeline, Start the Road Trip
- [x] Four navigation cards: Road Trip, Timeline, By the Numbers, Trivia
- [x] Featured event, different each day ("On This Day" was built, then removed in review)
- [x] Optional featured person or revelation

## Phase 7: Interactive timeline

- [x] `TimelineController#show` loading events in date order with place and people
- [x] Render the timeline grouped by period: a vertical line on mobile, a row that scrolls sideways per period on desktop
- [x] Period jump links: New York, Ohio, Missouri, Nauvoo, Westward Migration
- [x] Category filter chips, submitted as query params into a Turbo Frame
- [x] Build the slide-over panel partial (moved here from Phase 5; the map reuses it)
- [x] Clicking an event opens a detail panel in a Turbo Frame: date, place, explanation, participants, scriptures, images, sources
- [x] Cross-links from the panel: "View on map", person pages, D&C sections
- [x] Search box for person, event, location or revelation
- [x] Deep links work (`/timeline?event=liberty-jail` opens that event)
- [x] Test: Liberty Jail shows Joseph Smith, D&C 121 to 123, and a map link

## Phase 8: Restoration Road Trip (map)

- [x] Pin Leaflet: `bin/importmap pin leaflet`, and add its CSS
- [x] Give the map each place's coordinates, kinds and slug (passed in the page, so no separate JSON request)
- [x] Write a `map` Stimulus controller: create the map, add OpenStreetMap tiles with attribution, add a marker per place
- [x] Clicking a marker loads the place panel in a Turbo Frame: name, dates, significance, people, scriptures, photos, documents, citations
- [x] Filter buttons: temples, revelation sites, settlements, landmarks
- [x] Links from the panel to related timeline events and records
- [x] Then-and-now image comparison where both images exist (ready; shows once images are added)
- [x] "Visited" toggle saved to local storage, with visited markers styled differently
- [x] Road-trip route: a line through places in `trail_order`, with straight-line distances between stops
- [x] Deep links work (`/road-trip?place=kirtland`)
- [x] Test: Kirtland panel shows all four spec dates and links to D&C 110

## Phase 9: Restoration by the Numbers

- [x] Add Chart.js (its self-contained build, pinned through importmap; no extra gems needed)
- [x] Membership growth: line chart from `MembershipEstimate`
- [x] Revelations by location: bar chart of D&C sections per place
- [x] Revelations over time: column chart by year; events over time as a second column chart
- [x] Period comparison: events, revelations, temple events and membership per period, as four small charts
- [x] Geographic expansion: Leaflet map with a year slider from 1830 to 1850
- [x] Filters for year range, period, category and location
- [x] Clicking a bar or point opens the matching records (Chart.js `onClick` in a Stimulus controller)
- [x] Under every chart: source notes, definitions, and a caveat for approximate figures
- [ ] Stretch: relationship network diagram of people, events and places using D3
- [x] Reworked in review: charts now count only complete data (membership, and all 138 Doctrine and Covenants sections). The charts that counted this site's selection of events and revelations, the period comparison, and the period, category and place filters were removed.

## Phase 10: Restoration Trivia

- [x] Trivia landing page with mode and difficulty selection
- [x] `/trivia/questions.json?mode=...&difficulty=...` returning a shuffled set
- [x] A `quiz` Stimulus controller: question counter, progress bar, clickable answers, instant right/wrong feedback, explanation, link to the related timeline entry
- [x] Final results screen with score and Play Again
- [x] Modes, in this order:
  - [x] General Restoration Trivia (multiple choice from `TriviaQuestion`)
  - [x] Guess the Location (generated from events and their places)
  - [x] Doctrine and Covenants Challenge (generated from revelations)
  - [x] Who Am I? (reveals person clues one at a time)
  - [x] Chronology Challenge (drag events into order; use SortableJS)
- [x] Save best scores per mode in local storage, plus a review of missed questions at the end of a round
- [x] Test: "Where was the Church formally organized on April 6, 1830?" accepts Fayette, New York

## Phase 11: Explore History (search) and Sources page

**Record pages**
- [x] Show pages for places, people, events and revelations with the full entry format: title, dates, location, summary, people, context, related revelations, sources, related records (built early, in Phase 5)

**Search**
- [x] Add `pg_search` and make all four record types searchable (searched directly, so there is no index to rebuild)
- [x] `/explore` with a search box and results grouped by type
- [x] Test the spec's example searches: Joseph Smith, Emma Smith, Liberty Jail, Doctrine and Covenants 76, Book of Mormon translation, Nauvoo Temple

**Sources and Methodology**
- [x] Bibliography generated from the `Source` table, grouped by primary and secondary
- [x] Written sections: how research was done, how uncertain dates and figures are handled, how conflicting accounts are treated, image credits

## Phase 12 (optional): Accounts and saved progress

Only do this if time allows; local storage already covers the essentials.

- [ ] `bin/rails generate authentication` (built into Rails 8)
- [ ] Add a sign-up page (the generator only creates sign-in)
- [ ] `VisitedPlace` and `TriviaScore` models belonging to a user
- [ ] Sync local storage progress to the account on sign-in

## Final review (saved for the end)

Content and functionality were reviewed together once the site was built. The content in `db/seeds/` was drafted from memory and then fact-checked by hand (finished 2026-11-19).

**Content**
- [x] Check every event: date, date precision, place, people, summary and context
- [x] Check the full write-up of every event in `db/seeds/event_details.yml` (what led to it, what happened, why it matters): names, numbers, dates and quotations. Written from memory, not yet checked against the sources
- [x] Check every revelation against its section heading: date, place and people
- [x] Spot-check the verse text on a few revelation pages against the official edition (1,053 verses were downloaded from the Open Scripture API)
- [x] Spot-check the year and place of Doctrine and Covenants sections in `db/data/doctrine_and_covenants.yml` (read from the section headings; five were set by hand and are listed in the file)
- [x] Check every person: birth and death dates, roles, biography and clues
- [x] Check the longer stories of every person, place and revelation in `db/seeds/stories.yml`: names, numbers, dates, quotations and what each site is like today. Written from memory, not yet checked against the sources
- [x] People, places and revelations now have "At a glance" facts from Wikidata and the section headings, and their dates were checked against Wikipedia (see `FACT_CHECK.md`, kept on your computer, for what was changed and what is still unchecked)
- [x] Check every place: years, summary, and coordinates on a real map (least reliable)
- [x] Check every membership figure against the Church Almanac (least reliable)
- [x] Check every trivia answer and explanation
- [x] Play each trivia game and check the generated questions read well (four of the five games write their questions from the records)
- [x] Check every source: title, author and URL
- [x] Read the Sources and Methodology page and make sure every statement matches how the content was actually researched and checked
- [ ] Add chapter or page notes to the citations, which currently cite whole works
- [x] Portraits for all 19 people, from Wikimedia Commons, with captions, credits and sources (approved in review)
- [x] Check each portrait's public-domain status and caption, especially Joseph Smith, Hyrum Smith, Lucy Mack Smith, Joseph Smith Sr., Sidney Rigdon and Willard Richards
- [ ] Collect images for places and events, and record a credit and license for each (none yet)
- [ ] Add a hero photograph at `app/assets/images/hero.jpg`; the home page uses it automatically in place of the green gradient
- [ ] Decide whether the Twelve's mission to Britain needs a place on the map (it has none)
- [x] Jefferson City, Hawn's Mill and Kanesville are now road-trip stops (decided in review: all 15 places are numbered)
- [x] Check the order of the 15 road-trip stops
- [x] Check the chart caveats and definitions on By the Numbers read correctly once the content is verified
- [ ] Decide whether the road trip needs real driving distances and travel times (it shows straight-line miles now)
- [ ] Map markers that sit close together (New York and Ohio) are small touch targets when zoomed out; the place list beside the map is the alternative
- [x] Check the footer wording: it says the site is an independent University homework project and not an official publication
- [x] Remove the DRAFT note at the top of each file in `db/seeds/` once that file is checked

**Functionality**
- [ ] Everything in Phase 13 below

## Phase 13: Polish and test

- [x] Walk the spec's visitor journey end to end: timeline > Liberty Jail > map > D&C 121 to 123 > people > trivia
- [x] System tests (Capybara) for that journey and for one trivia round (9 browser tests in `test/system`; run with `bin/rails test:system`)
- [x] Check every page on phone, tablet and desktop widths (14 pages at 375, 768 and 1280 pixels: no sideways scrolling)
- [x] Keyboard-only pass: every control reachable and visibly focused
- [x] Run Lighthouse for accessibility and performance; fix what it flags (accessibility, best practices and SEO: 100 on eight pages, 96 on the map)
- [x] Alt text on every image; lazy-load images below the fold
- [x] Fix N+1 queries with `includes` (the `bullet` gem will point them out) (every page runs 19 queries or fewer; no `bullet` gem needed)
- [x] Custom 404 and 500 pages
- [x] Page titles, meta descriptions and a social share image
- [x] `bin/rails test` and `bin/rubocop` both pass
- [x] Fix GitHub CI, which had been failing on every push because its runners no longer carry Ruby 3.4.2
- [ ] Run a Lighthouse performance check on the live site (it is only meaningful there, not on a development machine)

## Phase 14: Launch

- [ ] Push to `main` and confirm the Render deploy is green
- [ ] Confirm production data loaded (counts of places, events and people match local)
- [ ] Move to paid Render plans if the site must stay awake and keep its database
- [ ] Buy a domain
- [ ] Add it under the Render service's **Custom Domains** and create the DNS records Render shows
- [ ] Wait for the TLS certificate, then confirm `https://` works and `http://` redirects
- [ ] Turn on database backups
- [ ] Add error tracking (Honeybadger or Sentry free tier) and an uptime check on `/up`
- [ ] Click through every page once on the live site

