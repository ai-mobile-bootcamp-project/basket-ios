# Basket

Basket is a grocery shopping-list app for iPhone. Plan a trip on your phone, add items by hand or straight from
a product catalog, tick them off aisle by aisle in the store and always see what the trip will cost.

- Keep several shopping lists, each with progress and an estimated total
- Items are grouped by aisle (category) in an order you choose, with ticked items moving into "In basket"
- Browse the grocery catalog from [DummyJSON](https://dummyjson.com) and add products with a quantity
- Totals in US dollars: the whole list, what is already in the basket, and items still without a price
- Share a list as text, finish a trip and keep what you did not buy
- English, Spanish and Arabic (right-to-left), light and dark mode, Dynamic Type and VoiceOver

Lists live on the device (no account, no sync). Only the product catalog comes from the internet, and it is
cached for offline use.

## Screens

| # | Screen | What it does |
| --- | --- | --- |
| 1 | Lists | Home: every shopping list with progress and estimated total; create, rename, duplicate, delete |
| 2 | List detail | One list: items by aisle, tick off, quantities, totals, share, finish shopping |
| 3 | Add / edit item | Name, quantity, price, category and note for an item typed by hand or edited |
| 4 | Browse products | The online grocery catalog with search and category chips, added straight into the open list |
| 5 | Product detail | One catalog product: image, price, discount, rating, stock, add with a quantity |
| 6 | Categories | The aisle order that groups every list; add, rename, reorder, delete |
| 7 | Settings | Theme, language, list behaviour, catalog refresh, reset sample data, about |

## Stack

- SwiftUI with `NavigationStack` and value-based navigation
- Core Data with a programmatic `NSManagedObjectModel` (no model file)
- `URLSession` with async/await for the catalog; `AsyncImage` backed by `URLCache` for product images
- `Localizable.strings` / `Localizable.stringsdict` for English, Spanish and Arabic
- XCTest for the product rules
- No third-party dependencies

## Project layout

```
Basket/                     App target
  App/                      App entry point, root view, navigation router, settings, localization helper
  Theme/                    Colour roles, typography, spacing and shapes
  Components/               Shared views: toast with Undo, quantity stepper, product image, name entry sheet, ...
  Persistence/              Core Data stack, managed objects, BasketStore, sample data
  Network/                  Catalog service and catalog cache
  Screens/                  One folder per screen (Lists, ListDetail, ItemForm, Browse, ProductDetail,
                            Categories, Settings)
  Resources/                Asset catalog, sample data, en/es/ar localizations
  Info.plist
BasketCore/                 Swift package with the product rules (money, totals, sorting, grouping,
                            validation, catalog mapping, share text)
  Sources/BasketCore/
  Tests/BasketCoreTests/
Basket.xcodeproj            Xcode project (scheme: Basket)
project.yml                 XcodeGen spec that produces an equivalent project
```

The BasketCore sources are compiled directly into the app target as well, so the app does not import
a separate module. The `BasketTests` target runs the BasketCore tests inside the app.

## Requirements

- Xcode 15.0 or later (Swift 5.9)
- iOS 16.0 or later (deployment target)
- iPhone, portrait

## Getting started

1. Open `Basket.xcodeproj` in Xcode.
2. Select the **Basket** scheme and an iPhone simulator.
3. Run with ⌘R.

Run the tests with ⌘U in Xcode, or run the product-rule tests on their own from the command line:

```sh
cd BasketCore && swift test
```

Command-line build and test of the app:

```sh
xcodebuild -project Basket.xcodeproj -scheme Basket \
  -destination 'platform=iOS Simulator,name=iPhone 15' build test CODE_SIGNING_ALLOWED=NO
```

To run on a device, choose your team under Signing & Capabilities for the Basket target.

## Regenerating the project with XcodeGen

The checked-in `Basket.xcodeproj` is the source of truth. If you prefer to generate it, `project.yml` describes an
equivalent project:

```sh
brew install xcodegen && xcodegen generate
```

Run the command from the repository root.

## Continuous integration

GitHub Actions (`.github/workflows/ios.yml`) runs on every push and pull request on `macos-14` with Xcode 15.4:
it runs `swift test` for BasketCore, then builds the app and runs the test target on an iPhone 15 simulator.

## Data source

Product data comes from the public [DummyJSON](https://dummyjson.com) groceries catalog
(`https://dummyjson.com/products/category/groceries`). No API key is needed. Catalog product names and
descriptions are shown as provided by the API.

## Version

1.0.0. See [CHANGELOG.md](CHANGELOG.md).
