## v1.5.0 (2023-10-31)

- Image attaching support

## v1.4.2 (2023-06-03)

- Allow '-' in page name

## v1.3.7 (2022-11-30)

- fix css rendering error

## v1.3.6 (2022-11-20)

- security: bundle update

## v1.3.4 (2022-05-22)

- security: bundle update

## v1.3.3 (2021-08-13)

- security: bundle update

## v1.3.2 (2021-08-13)

- security: Update addressable

## v1.3.1 (2021-06-06)

- Changed google analytics tag format

## v1.2.1 (2021-02-07)

- security: Update nokogiri, redcarpet

## v1.2.0 (2020-03-29)

Notable changes

- Changed database file name to `production.sqlite3`
- Removed constant NLog2::VERSION

Other changes

- security: update rack, activesupport

## v1.1.9 (2020-03-29)

- chores: bundle update
- fix: Fixed fragile test

## v1.1.8 (2019-08-31)

- chores: Upgrade to ActiveRecord 6

## v1.1.7 (2019-08-29)

- security: Update nokogiri

## v1.1.6 (2019-06-09)

- fix: 500 on page overflow (#4)

## v1.1.5 (2019-05-10)

- chores: migrated to pagy gem

## v1.1.4 (2018-11-07)

- security: Update rack, loofah, nokogiri

## v1.1.3 (2018-06-28)

- Bundle update

## v1.1.2 (2017-06-06)

- Bundle update (security fixes)
  - of sinatra 2.0.1 https://nvd.nist.gov/vuln/detail/CVE-2018-11627

## v1.1.1 (2017-04-29)

- Bundle update (security fixes)
  - of loofah 2.2.0 https://github.com/flavorjones/loofah/issues/144
  - of rails-html-sanitizer 1.4.0 https://nvd.nist.gov/vuln/detail/CVE-2018-3741

## v1.1.0 (2017-02-26)

- Add sidebar
- category_id is now mandatory

## v1.0.1 (2017-10-09)

- fix: could not edit an article

## v1.0.0 (2017-10-08)

Breaking change: changed DB schema.

## v0.6.0 (2017-10-03)

- new: Set current time if omitted
- fix: fix development reload paths

## v0.5.0 (2017-07-03)

Imporant fix: authentication is broken since v0.3.0

- new: Show newest/related posts

## v0.4.0 (2017-06-29)

- new: Shorten long posts in the top page
- fix: /?category=XXX did not work

## v0.3.1 (2017-06-29)

- fix: Category is reset by Preview button

## v0.3.0 (2017-06-27)

- Changed admin urls (eg. /_edit -> /_admin/edit)
- Update dependencies

## v0.2.0 (2017-05-16)

- new: category for posts

## v0.1.0 (2017-05-03)

- first tag 

## v0.0.0 (2016-08-11)

- initial commit
