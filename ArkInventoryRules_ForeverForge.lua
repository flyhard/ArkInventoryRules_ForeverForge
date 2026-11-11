-- ArkInventory rule functions that sort items by what to do with them:
-- Vendor, Disenchant or Post on AH.
--
--   ffrec( "vendor", "disenchant", "ah" )  any of the listed recommendations
--   ffde( )                                 Disenchant
--   ffah( )                                 Post on AH
--   ffvendor( )                             Vendor
--
-- Prices come from TradeSkillMaster when it's loaded, otherwise from
-- ForeverForge Auction (the recommendation its tooltip shows).
-- "/ffrules tsm", "/ffrules ff" or "/ffrules auto" picks the source.

local rule = ArkInventoryRules:NewModule( "ArkInventoryRules_ForeverForge" )

local NAME = "ArkInventoryRules_ForeverForge"
local DISENCHANT = 13262

-- TSM custom price strings. The AH and disenchant values are what you'd get
-- after the auction house's 5% cut.
local TSM_VENDOR = "VendorSell"
local TSM_AH = "first(DBMinBuyout, DBMarket)"
local TSM_DE = "Destroy"
local AH_CUT = 0.95

local warned = { }

local function warn( key, msg )
	if warned[key] then return end
	warned[key] = true
	ArkInventory.OutputWarning( NAME .. ": " .. msg )
end

local function settings( )
	ArkInventoryRules_ForeverForgeDB = ArkInventoryRules_ForeverForgeDB or { }
	local db = ArkInventoryRules_ForeverForgeDB
	if db.source ~= "tsm" and db.source ~= "ff" then db.source = "auto" end
	return db
end

local function hasTSM( )
	return TSM_API and TSM_API.GetCustomPriceValue and TSM_API.ToItemString and true or false
end

local function hasFF( )
	local A = ForeverForgeAuction
	return A and A.Market and A.Market.Evaluate and true or false
end

-- Which price source the rules use right now: "tsm", "ff" or nil.
local function activeSource( )
	local want = settings( ).source
	if want == "tsm" then return hasTSM( ) and "tsm" or nil end
	if want == "ff" then return hasFF( ) and "ff" or nil end
	if hasTSM( ) then return "tsm" end
	if hasFF( ) then return "ff" end
	return nil
end

local function tsmValue( price, itemString )
	local ok, v = pcall( TSM_API.GetCustomPriceValue, price, itemString )
	if ok and type( v ) == "number" and v > 0 then return v end
end

-- A random-suffix item may have no price of its own yet, so fall back to
-- the plain item's price.
local function tsmPrice( price, itemString, baseString )
	return tsmValue( price, itemString ) or ( baseString ~= itemString and tsmValue( price, baseString ) ) or nil
end

-- TSM's "Destroy" value also covers milling and prospecting, so only
-- weapons and armor count as something to disenchant.
local function canDisenchant( link )
	local info = ( C_Item and C_Item.GetItemInfoInstant ) or GetItemInfoInstant
	if not info then return false end
	local classID = select( 6, info( link ) )
	return classID == 2 or classID == 4
end

-- The best of vendor, disenchant (when you can) and AH (when it's
-- tradeable). Ties go to the simplest: vendor, then disenchant.
local function tsmRecommendation( link, canTrade, canDE )
	local ok, itemString = pcall( TSM_API.ToItemString, link )
	if not ok or type( itemString ) ~= "string" then return nil end
	local baseString = string.match( itemString, "^i:%d+" ) or itemString

	local best, bestV
	local function consider( name, v )
		if v and v > 0 and ( not bestV or v > bestV ) then best, bestV = name, v end
	end
	consider( "vendor", tsmPrice( TSM_VENDOR, itemString, baseString ) )
	if canDE and canDisenchant( link ) then
		local de = tsmPrice( TSM_DE, itemString, baseString )
		consider( "disenchant", de and math.floor( de * AH_CUT ) )
	end
	if canTrade then
		local ah = tsmPrice( TSM_AH, itemString, baseString )
		consider( "ah", ah and math.floor( ah * AH_CUT ) )
	end
	return best
end

local function ffRecommendation( id, link, canTrade, canDE )
	local A = ForeverForgeAuction
	local ok, v = pcall( A.Market.Evaluate, A.Market, id, link, canTrade, canDE )
	if ok and type( v ) == "table" then return v.best end
end

-- Tradeable unless soulbound, and whether this character knows Disenchant.
local function recommendation( )
	local o = ArkInventoryRules.Object
	if not o.h or o.class ~= "item" then return nil end
	local id = tonumber( string.match( o.h, "item:(%d+)" ) )
	if not id then return nil end

	local source = activeSource( )
	if not source then
		local want = settings( ).source
		if want == "tsm" then
			warn( "none", "TradeSkillMaster isn't loaded, so ff rules match nothing. Type /ffrules auto to use ForeverForge Auction instead." )
		elseif want == "ff" then
			warn( "none", "ForeverForge Auction isn't loaded, so ff rules match nothing. Type /ffrules auto to use TradeSkillMaster instead." )
		else
			warn( "none", "neither TradeSkillMaster nor ForeverForge Auction is loaded, so ff rules match nothing." )
		end
		return nil
	end

	local canTrade = o.sb ~= ArkInventory.ENUM.ITEM.BINDING.PICKUP
	local canDE = IsPlayerSpell and IsPlayerSpell( DISENCHANT ) or false
	if source == "tsm" then
		return tsmRecommendation( o.h, canTrade, canDE )
	end
	return ffRecommendation( id, o.h, canTrade, canDE )
end

function rule.ffrec( ... )
	local fn = "ffrec"
	local ac = select( '#', ... )
	if ac == 0 then
		error( string.format( ArkInventory.Localise["RULE_FAILED_ARGUMENT_NONE_SPECIFIED"], fn ), 0 )
	end
	local best = recommendation( )
	if not best then return false end
	for ax = 1, ac do
		local arg = select( ax, ... )
		if type( arg ) ~= "string" then
			error( string.format( ArkInventory.Localise["RULE_FAILED_ARGUMENT_IS_NOT"], fn, ax, "string" ), 0 )
		end
		if string.lower( arg ) == best then return true end
	end
	return false
end

function rule.ffde( )
	return recommendation( ) == "disenchant"
end

function rule.ffah( )
	return recommendation( ) == "ah"
end

function rule.ffvendor( )
	return recommendation( ) == "vendor"
end

local LABEL = { tsm = "TradeSkillMaster", ff = "ForeverForge Auction" }

local function resort( )
	ArkInventory.ItemCacheClear( )
	ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Recalculate )
end

local function slash( msg )
	msg = string.lower( strtrim( msg or "" ) )
	local db = settings( )
	if msg == "tsm" or msg == "ff" or msg == "auto" then
		db.source = msg
		wipe( warned )
		resort( )
	elseif msg ~= "" then
		ArkInventory.Output( NAME .. ": /ffrules tsm, /ffrules ff or /ffrules auto (TSM when it's loaded, else ForeverForge)" )
		return
	end
	local active = activeSource( )
	ArkInventory.Output( string.format( "%s: price source is %s, now using %s.", NAME, db.source, active and LABEL[active] or "nothing (not loaded)" ) )
end

function rule:OnEnable( )
	settings( )
	ArkInventoryRules.Register( self, "ffrec", rule.ffrec )
	ArkInventoryRules.Register( self, "ffde", rule.ffde )
	ArkInventoryRules.Register( self, "ffah", rule.ffah )
	ArkInventoryRules.Register( self, "ffvendor", rule.ffvendor )
	SLASH_ARKINVENTORYRULESFF1 = "/ffrules"
	SlashCmdList["ARKINVENTORYRULESFF"] = slash
end
