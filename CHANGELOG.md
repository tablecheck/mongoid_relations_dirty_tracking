# Changelog

## v1.0.0 - May 2026

### Breaking changes

- **Default trackables narrowed to embedded relations only.** Including
  `Mongoid::RelationsDirtyTracking` now tracks `embeds_one` and `embeds_many`
  relations only. Tracking `has_one`, `has_many`, `has_and_belongs_to_many`,
  and `belongs_to` requires opt-in via `relations_dirty_tracking track_referenced: true`.
  This is a performance change — tracking referenced relations forces them to be
  loaded on every `after_initialize` and `after_save` callback. See the
  [Upgrading from 0.x](README.md#upgrading-from-0x) section of the README.

### Features

- Add `:track_referenced` option to `relations_dirty_tracking` to re-enable
  tracking of referenced relations on a per-class basis.
- Expose `EMBEDDED_TRACKABLES` and `REFERENCED_TRACKABLES` constants for
  applications that need to introspect or override the trackable set.

## v0.3.0 - May 2025

- Support Mongoid 8.0, 8.1, and 9.0 (drop support for earlier versions)
- Support Rails 7.1+ (drop support for earlier versions)
- Enable Github Actions CI.
- Upgrade and fix Rubocop.

## v0.2.2 - Aug 2020

- Automatically disable relations dirty tracking for readonly documents.

## v0.2.1 - Aug 2020

- Change homepage in gemspec to https://github.com/tablecheck/mongoid_relations_dirty_tracking

## v0.2.0 - Aug 2020

- Resumption of maintenance
- Rails 5.1, 5.2, and 6.0 support (drop support for earlier versions)
- Mongoid 7.0 and 7.1 support (drop support for earlier versions)
- Add global disable feature

## v0.1.0 - Jan 2014

- Initial release
- Rails 3.0, 3.1, and 3.2 support
- Mongoid 3.1 support
