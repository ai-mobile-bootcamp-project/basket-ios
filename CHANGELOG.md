# Changelog

All notable changes to this project are documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- Welcome screen on first launch: start with the sample lists or with no lists
- Category emoji in aisle headers, filter chips, the item category field, product details and Categories

### Changed

- Refreshed design for Lists, List detail, Add / edit item, Browse products, Product detail, Categories and Settings
- Finish shopping removes bought items at once with Undo
- Sample lists are no longer added automatically on first launch; default categories always are

## 1.0.0 — 2026-09-27

### Added

- Lists screen with progress, estimated totals, and create, rename, duplicate and delete with Undo
- List detail with items grouped by aisle, ticking, quantities, "In basket" section, totals, share as text and
  finish shopping
- Add / edit item form with quantity, price, category and note
- Browse products from the DummyJSON groceries catalog with search, category chips and offline cache
- Product detail with price, discount, rating, stock and add to list with a quantity
- Categories screen to add, rename, reorder and delete aisles
- Settings for theme, language, moving ticked items down, catalog refresh and resetting sample data
- English, Spanish and Arabic localizations with right-to-left layout
- Light and dark mode, Dynamic Type and VoiceOver support
- BasketCore package with the product rules and unit tests
- GitHub Actions workflow for building and testing
