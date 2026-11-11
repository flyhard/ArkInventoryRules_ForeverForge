# ArkInventory [Rules] ForeverForge

Sort your bags by what to do with each item. This addon adds rule functions to ArkInventory that tell you whether an item is worth most sold to a vendor, disenchanted or posted on the auction house, so you can build categories like "To disenchant", "To post" and "To vendor".

Prices come from [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master) when it's loaded, and otherwise from [ForeverForge Auction](https://www.curseforge.com/wow/addons/foreverforge-auction) (the same recommendation its tooltip shows).

ArkInventory's built-in `tooltip()` rule can't see ForeverForge's tooltip line, because ForeverForge only adds it to the tooltip on your screen. ArkInventory's own `tsmgroup()` rule only checks which TSM group an item is in, not what it's worth. This addon asks TSM or ForeverForge Auction for prices directly instead.

## Requirements

- [ArkInventory](https://www.curseforge.com/wow/addons/ark-inventory), including its Rules module
- At least one of:
  - [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master). Install the TSM desktop app's AppHelper addon too, or scan the auction house with TSM, so it has auction prices.
  - [ForeverForge Auction](https://www.curseforge.com/wow/addons/foreverforge-auction), which also needs the ForeverForge core addon

## Rule functions

| Function | Matches items that are worth most when you |
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

## Choosing the price source

| Command | Uses |
|---|---|
| `/ffrules auto` | TradeSkillMaster when it's loaded, otherwise ForeverForge Auction (the default) |
| `/ffrules tsm` | TradeSkillMaster only |
| `/ffrules ff` | ForeverForge Auction only |
| `/ffrules` | Shows which source is in use |

Switching re-sorts your bags right away.

## How the TSM recommendation works

The addon compares three values and picks the highest. Ties go to vendor, then disenchant.

- **Vendor**: TSM's `VendorSell`.
- **Disenchant**: TSM's `Destroy` value less the 5% auction house cut. It only counts for weapons and armor, and only when your current character knows Disenchant.
- **Post on AH**: `first(DBMinBuyout, DBMarket)` less the 5% auction house cut, so the current lowest price, or the market value when there's no current listing. Soulbound items are never marked Post on AH.

The TSM version ignores ForeverForge's extras: deposits, sending items to an enchanter alt (`"altde"`), and the "check the AH first" advice for random-suffix items with no price (`"check"`). A random-suffix item with no price of its own uses the plain item's price.

## Notes

- Without Enchanting, items are never marked Disenchant.
- ArkInventory remembers which category an item is in, so `/reload` after a new auction scan or TSM data update to re-sort.
- With ForeverForge Auction, this addon relies on its internal price function. If a ForeverForge update changes that function, the rules will match nothing until this addon is updated.

## License

MIT. This addon isn't made by or affiliated with the TradeSkillMaster, ForeverForge or ArkInventory authors.
