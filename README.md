# ArkInventory [Rules] ForeverForge

Sort your bags by what ForeverForge Auction tells you to do with each item. This addon adds rule functions to ArkInventory that return the same Vendor, Disenchant or Post on AH recommendation shown on ForeverForge Auction's tooltip, so you can build categories like "To disenchant", "To post" and "To vendor".

ArkInventory's built-in `tooltip()` rule can't see ForeverForge's tooltip line, because ForeverForge only adds it to the tooltip on your screen. This addon asks ForeverForge Auction for its recommendation directly instead.

## Requirements

- [ArkInventory](https://www.curseforge.com/wow/addons/ark-inventory), including its Rules module
- [ForeverForge Auction](https://www.curseforge.com/wow/addons/foreverforge-auction), which also needs the ForeverForge core addon

## Rule functions

| Function | Matches items ForeverForge recommends to |
|---|---|
| `ffde()` | Disenchant |
| `ffah()` | Post on AH |
| `ffvendor()` | Vendor |
| `ffrec("ah", "disenchant", ...)` | Any of the listed recommendations (`"vendor"`, `"disenchant"`, `"ah"`) |

## Setup

1. Install the addon and `/reload`.
2. In ArkInventory, open Config and go to Rules. Add a rule, for example "To disenchant", with the formula `ffde()`, and enable it.
3. In the bag window, turn on edit mode, right-click a bar and assign the new category to it. It's listed under Rules.

You can combine these with other rule functions, for example `ffah() and not soulbound()`.

## Notes

- The recommendation is the same one the tooltip shows. It uses your latest auction scan, ForeverForge's disenchant odds, and whether your current character can disenchant. Without Enchanting, items are never marked Disenchant.
- ArkInventory remembers which category an item is in, so `/reload` after a new auction scan to re-sort.
- This addon relies on ForeverForge Auction's internal price function. If a ForeverForge update changes that function, the rules will match nothing until this addon is updated.

## License

MIT. This addon isn't made by or affiliated with the ForeverForge or ArkInventory authors.
