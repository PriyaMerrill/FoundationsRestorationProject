#!/usr/bin/env bash
# Build script Render runs on every deploy.
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails db:migrate
bin/rails db:seed
