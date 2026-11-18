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
- [ ] Verify the drafted content against the sources: every date, place, coordinate, membership figure and trivia answer, then remove the DRAFT note at the top of each file in `db/seeds/`
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
- [x] "On This Day in Church History" block (query events matching today's month and day, fall back to a featured event)
- [x] Optional featured person or revelation

## Phase 7: Interactive timeline

- [ ] `TimelineController#index` loading events in date order with place and people
- [ ] Render the timeline (vertical on mobile, horizontal on desktop) grouped by period
- [ ] Period jump links: New York, Ohio, Missouri, Nauvoo, Westward Migration
- [ ] Category filter chips, submitted as query params into a Turbo Frame
- [ ] Build the slide-over panel partial (moved here from Phase 5; the map reuses it)
- [ ] Clicking an event opens a detail panel in a Turbo Frame: date, place, explanation, participants, scriptures, images, sources
- [ ] Cross-links from the panel: "View on map", person pages, D&C sections
- [ ] Search box for person, event, location or revelation
- [ ] Deep links work (`/timeline?event=liberty-jail` opens that event)
- [ ] Test: Liberty Jail shows Joseph Smith, D&C 121 to 123, and a map link

## Phase 8: Restoration Road Trip (map)

- [ ] Pin Leaflet: `bin/importmap pin leaflet`, and add its CSS
- [ ] Add a JSON endpoint `/places.json` with coordinates, kind and slug
- [ ] Write a `map` Stimulus controller: create the map, add OpenStreetMap tiles with attribution, add a marker per place
- [ ] Clicking a marker loads the place panel in a Turbo Frame: name, dates, significance, people, scriptures, photos, documents, citations
- [ ] Filter buttons: temples, revelation sites, settlements, landmarks
- [ ] Links from the panel to related timeline events and records
- [ ] Then-and-now image comparison where both images exist
- [ ] "Visited" toggle saved to local storage, with visited markers styled differently
- [ ] Optional road-trip mode: draw a line through places in `trail_order` and show a stop list with approximate distances
- [ ] Deep links work (`/road-trip?place=kirtland`)
- [ ] Test: Kirtland panel shows all four spec dates and links to D&C 110

## Phase 9: Restoration by the Numbers

- [ ] Add gems `chartkick` and `groupdate`; pin `chartkick` and `Chart.js`
- [ ] Membership growth: line chart from `MembershipEstimate`
- [ ] Revelations by location: bar chart of D&C sections per place
- [ ] Revelations over time: column chart by year
- [ ] Period comparison: revelations, settlements, temples and membership per period
- [ ] Geographic expansion: Leaflet map with a year slider from 1830 to 1850
- [ ] Filters for year range, period, category and location
- [ ] Clicking a bar or point opens the matching records (Chart.js `onClick` in a Stimulus controller)
- [ ] Under every chart: source notes, definitions, and a caveat for approximate figures
- [ ] Stretch: relationship network diagram of people, events and places using D3

## Phase 10: Restoration Trivia

- [ ] Trivia landing page with mode and difficulty selection
- [ ] `/trivia/questions.json?mode=...&difficulty=...` returning a shuffled set
- [ ] A `quiz` Stimulus controller: question counter, progress bar, clickable answers, instant right/wrong feedback, explanation, link to the related timeline entry
- [ ] Final results screen with score and Play Again
- [ ] Modes, in this order:
  - [ ] General Restoration Trivia (multiple choice from `TriviaQuestion`)
  - [ ] Guess the Location (generated from events and their places)
  - [ ] Doctrine and Covenants Challenge (generated from revelations)
  - [ ] Who Am I? (reveals person clues one at a time)
  - [ ] Chronology Challenge (drag events into order; use SortableJS)
- [ ] Save best scores per mode in local storage
- [ ] Test: "Where was the Church formally organized on April 6, 1830?" accepts Fayette, New York

## Phase 11: Explore History (search) and Sources page

**Record pages**
- [x] Show pages for places, people, events and revelations with the full entry format: title, dates, location, summary, people, context, related revelations, sources, related records (built early, in Phase 5)

**Search**
- [ ] Add `pg_search`, enable multisearch on all four record types, rebuild the index in seeds
- [ ] `/explore` with a search box and results grouped by type
- [ ] Test the spec's example searches: Joseph Smith, Emma Smith, Liberty Jail, Doctrine and Covenants 76, Book of Mormon translation, Nauvoo Temple

**Sources and Methodology**
- [ ] Bibliography generated from the `Source` table, grouped by primary and secondary
- [ ] Written sections: how research was done, how uncertain dates and figures are handled, how conflicting accounts are treated, image credits

## Phase 12 (optional): Accounts and saved progress

Only do this if time allows; local storage already covers the essentials.

- [ ] `bin/rails generate authentication` (built into Rails 8)
- [ ] Add a sign-up page (the generator only creates sign-in)
- [ ] `VisitedPlace` and `TriviaScore` models belonging to a user
- [ ] Sync local storage progress to the account on sign-in

## Final review (saved for the end)

Content and functionality get reviewed together, once the site is built. Until then the content in `db/seeds/` is a draft written from memory.

**Content**
- [ ] Check every event: date, date precision, place, people, summary and context
- [ ] Check every revelation against its section heading: date, place and people
- [ ] Check every person: birth and death dates, roles, biography and clues
- [ ] Check every place: years, summary, and coordinates on a real map (least reliable)
- [ ] Check every membership figure against the Church Almanac (least reliable)
- [ ] Check every trivia answer and explanation
- [ ] Check every source: title, author and URL
- [ ] Add chapter or page notes to the citations, which currently cite whole works
- [ ] Collect images and record a credit and license for each (none yet)
- [ ] Add a hero photograph at `app/assets/images/hero.jpg`; the home page uses it automatically in place of the green gradient
- [ ] Decide whether the Twelve's mission to Britain needs a place on the map (it has none)
- [ ] Decide whether Jefferson City, Hawn's Mill and Kanesville should be road-trip stops (they are on the map but not on the route)
- [ ] Check the footer wording: it says the site is an independent educational project and not an official Church publication
- [ ] Remove the DRAFT note at the top of each file in `db/seeds/` once that file is checked

**Functionality**
- [ ] Everything in Phase 13 below

## Phase 13: Polish and test

- [ ] Walk the spec's visitor journey end to end: timeline > Liberty Jail > map > D&C 121 to 123 > people > trivia
- [ ] System tests (Capybara) for that journey and for one trivia round
- [ ] Check every page on phone, tablet and desktop widths
- [ ] Keyboard-only pass: every control reachable and visibly focused
- [ ] Run Lighthouse for accessibility and performance; fix what it flags
- [ ] Alt text on every image; lazy-load images below the fold
- [ ] Fix N+1 queries with `includes` (the `bullet` gem will point them out)
- [ ] Custom 404 and 500 pages
- [ ] Page titles, meta descriptions and a social share image
- [ ] `bin/rails test` and `bin/rubocop` both pass

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

