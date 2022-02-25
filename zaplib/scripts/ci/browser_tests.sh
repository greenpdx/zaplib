#!/bin/bash

set -euxo pipefail

# Per https://stackoverflow.com/a/16349776; go to repo root
cd "${0%/*}/../../.."

# Build test_suite.wasm
cargo run -p cargo-zaplib -- build -p test_suite

# Build
pushd zaplib/web
    # Dev build (instead of prod, so we get better stack traces)
    yarn
    yarn run build
popd

# Integration tests with Browserstack (uses test suite)
# Local identifier is necessary to be able to run multiple jobs in parallel.
export BROWSERSTACK_LOCAL_IDENTIFIER=$(echo $RANDOM$RANDOM$RANDOM)
BrowserStackLocal --key $BROWSERSTACK_KEY --debug-utility --daemon start --local-identifier $BROWSERSTACK_LOCAL_IDENTIFIER
cargo run -p zaplib_ci -- --webdriver-url "https://jpposma_0ZuiXP:${BROWSERSTACK_KEY}@hub-cloud.browserstack.com/wd/hub" --browserstack-local-identifier $BROWSERSTACK_LOCAL_IDENTIFIER

# Screenshots are saved in `screenshots/`. Previous ones in `previous_screenshots/`. Let's compare!
# `--ignoreChange` makes it so this call doesn't fail when there are changed screenshots; we don't
# want to block merging in that case.
# TODO(JP): We do want to add an automatic comment being posted to Github, so someone can review the
# screenshots.
zaplib/web/node_modules/.bin/reg-cli screenshots/ previous_screenshots/ diff_screenshots/ -R ./index.html --ignoreChange
# Now let's bundle everything up in screenshots_report/
mkdir screenshots_report/
mv index.html screenshots_report/
mv screenshots/ screenshots_report/
mv previous_screenshots/ screenshots_report/
mv diff_screenshots/ screenshots_report/