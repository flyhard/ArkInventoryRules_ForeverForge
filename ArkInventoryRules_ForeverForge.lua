-- ArkInventory rule functions backed by ForeverForge Auction's tooltip
-- recommendation (Vendor / Disenchant / Post on AH).
--
--   ffrec( "vendor", "disenchant", "ah" )  any of the listed recommendations
--   ffde( )                                 Disenchant
--   ffah( )                                 Post on AH
--   ffvendor( )                             Vendor

local rule = ArkInventoryRules:NewModule( "ArkInventoryRules_ForeverForge" )

local warned = false

function rule:OnEnable( )
	ArkInventoryRules.Register( self, "ffrec", rule.ffrec )
	ArkInventoryRules.Register( self, "ffde", rule.ffde )
	ArkInventoryRules.Register( self, "ffah", rule.ffah )
	ArkInventoryRules.Register( self, "ffvendor", rule.ffvendor )
end

-- Same inputs the ForeverForge tooltip uses: tradeable unless soulbound, and
-- whether this character knows Disenchant.
local function recommendation( )
	local o = ArkInventoryRules.Object
	if not o.h or o.class ~= "item" then return nil end
	local A = ForeverForgeAuction
	if not ( A and A.Market and A.Market.Evaluate ) then
		if not warned then
			warned = true
			ArkInventory.OutputWarning( "ArkInventoryRules_ForeverForge: ForeverForge Auction's price data isn't available, so ff rules match nothing." )
		end
		return nil
	end
	local id = tonumber( string.match( o.h, "item:(%d+)" ) )
	if not id then return nil end
	local canTrade = o.sb ~= ArkInventory.ENUM.ITEM.BINDING.PICKUP
	local canDE = IsPlayerSpell and IsPlayerSpell( 13262 ) or false
	local ok, v = pcall( A.Market.Evaluate, A.Market, id, o.h, canTrade, canDE )
	if ok and type( v ) == "table" then return v.best end
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
