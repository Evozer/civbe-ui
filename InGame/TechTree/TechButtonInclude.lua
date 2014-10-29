-------------------------------------------------
-- Include file that has handy stuff for the tech tree and other screens that need to show a tech button
-------------------------------------------------
include( "IconSupport" );
include( "InfoTooltipInclude" );
include( "MathHelpers" );


techPediaSearchStrings			= {};		-- GLOBAL
g_searchTable					= {};		-- GLOBAL Holds mapping of searchable words to techs.
g_recentlyAddedUnlocks			= {};


-- List the textures that we will need here
local defaultErrorTextureSheet	= "UnitActions360.dds";
local validUnitBuilds			= nil;
local validBuildingBuilds		= nil;
local validImprovementBuilds	= nil;

--turnString 	= Locale.ConvertTextKey("TXT_KEY_TURN");
--turnsString = Locale.ConvertTextKey("TXT_KEY_TURNS");
freeString 	= Locale.ConvertTextKey("TXT_KEY_FREE");

local m_textureAffinity		= {};
m_textureAffinity["AFFINITY_TYPE_PURITY"] 		= { atlas="AFFINITY_ATLAS_TECHWEB", size=64, index=0};
m_textureAffinity["AFFINITY_TYPE_HARMONY"] 		= { atlas="AFFINITY_ATLAS_TECHWEB", size=64, index=2};
m_textureAffinity["AFFINITY_TYPE_SUPREMACY"] 	= { atlas="AFFINITY_ATLAS_TECHWEB", size=64, index=1};

local m_tooltipAffinity		= {};
m_tooltipAffinity["AFFINITY_TYPE_HARMONY"] 		= "TXT_KEY_TECHWEB_AFFINITY_ADDS_HARMONY";
m_tooltipAffinity["AFFINITY_TYPE_PURITY"] 		= "TXT_KEY_TECHWEB_AFFINITY_ADDS_PURITY";
m_tooltipAffinity["AFFINITY_TYPE_SUPREMACY"] 	= "TXT_KEY_TECHWEB_AFFINITY_ADDS_SUPREMACY";

function GetTechPedia( void1, void2, button )
	local searchString = techPediaSearchStrings[tostring(button)];
	Events.SearchForPediaEntry( searchString );		
end

function GatherInfoAboutUniqueStuff( civType )

	validUnitBuilds = {};
	validBuildingBuilds = {};
	validImprovementBuilds = {};

	-- put in the default units for any civ
	for thisUnitClass in GameInfo.UnitClasses() do
		validUnitBuilds[thisUnitClass.Type]	= thisUnitClass.DefaultUnit;	
	end

	-- put in my overrides
	for thisOverride in GameInfo.Civilization_UnitClassOverrides() do
 		if thisOverride.CivilizationType == civType then
			validUnitBuilds[thisOverride.UnitClassType]	= thisOverride.UnitType;
 		end
	end

	-- put in the default buildings for any civ
	for thisBuildingClass in GameInfo.BuildingClasses() do
		validBuildingBuilds[thisBuildingClass.Type]	= thisBuildingClass.DefaultBuilding;	
	end

	-- put in my overrides
	for thisOverride in GameInfo.Civilization_BuildingClassOverrides() do
 		if thisOverride.CivilizationType == civType then
			validBuildingBuilds[thisOverride.BuildingClassType]	= thisOverride.BuildingType;	
 		end
	end
	
	-- add in support for unique improvements
	for thisImprovement in GameInfo.Improvements() do
		if thisImprovement.CivilizationType == civType or thisImprovement.CivilizationType == nil then
			validImprovementBuilds[thisImprovement.Type] = thisImprovement.Type;	
		else
			validImprovementBuilds[thisImprovement.Type] = nil;	
		end
	end
	
end


-- ===========================================================================
--	Has a few assumptions: 
--		1.) the small buttons are named "B1", "B2", "B3"
--		2.) GatherInfoAboutUniqueStuff() has been called before this
--
--	ARGS:
--	thisTechButtonInstance,	UI element
--	tech,					data structure with technology info
--	maxSmallButtonSize		no more than this many buttons will be populated
--	textureSize
--	startingButtoNum,		(optional) 1, but will use this instead if set
--
--	RETURNS: the # of small buttons added
-- ===========================================================================
function AddSmallButtonsToTechButton( thisTechButtonInstance, tech, maxSmallButtons, textureSize, startingButtonNum )

	-- temporary used (e.g., search populating)
	g_recentlyAddedUnlocks = {};
	
	if tech == nil then
		return;
	end

	local techType = tech.Type;

	-- (optional)
	local buttonNum = 1;
	if startingButtonNum ~= nil then
		buttonNum = startingButtonNum;
	end

	-- hide the ones we aren't using
	for i = buttonNum, maxSmallButtons, 1 do
		local buttonName = "B"..tostring(i);
		thisTechButtonInstance[buttonName]:SetHide(true);
	end

	local affinities = {};
	for techAffinityPair in GameInfo.Technology_Affinities()  do
		local techType		= techAffinityPair.TechType;
		local affinityType	= techAffinityPair.AffinityType;
		if ( techType == tech.Type ) then							
			--print("Setting affinity Type: " .. tech.ID .. " > " .. thisTechButtonInstance.affinityType );				
			if thisTechButtonInstance.affinityTypes == nil then
				thisTechButtonInstance.affinityTypes = {};
			end
			table.insert( affinities, affinityType );
		end
	end

	-- If an affinity exists, wire it up as the first small button
	for _,affinityType in ipairs(affinities) do				
		local thisButton	= thisTechButtonInstance["B"..tostring(buttonNum)];						
		local textureInfo   = m_textureAffinity[ tostring(affinityType) ];
		if ( textureInfo ~= nil ) then 
			thisButton:SetSizeVal( textureInfo.size, textureInfo.size);
			IconHookup( textureInfo.index, textureInfo.size, textureInfo.atlas, thisButton );
			local toolTipString = Locale.ConvertTextKey(m_tooltipAffinity[ affinityType ]);
			if ( toolTipString ~= nil ) then
				thisButton:SetToolTipString( toolTipString );
			else
				print("WARNING: Missing tooltip string for affinity '"..tostring(affinityType).."', on tech "..thisTechButtonInstance.tech.Description);
			end
				
			local conceptType = GameInfo.Affinity_Types[affinityType].CivilopediaConcept;
			local concept = GameInfo.Concepts[conceptType];
			techPediaSearchStrings[tostring(thisButton)] = concept.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );

			thisButton:SetHide( false );
			buttonNum = buttonNum + 1;
		else
			print("ERROR: Missing infinity texture for affinity '"..tostring(affinityType).."', on tech "..thisTechButtonInstance.tech.Description);
		end
	end		
	
	--0xAABBGGRR
	local unitColor = 0xaa5050ff; -- Units, eg. ranger
	local orbitalColor = 0xaaff5050; -- Satellites, eg. tacnet hub
	local buildingColor = 0xaa50ff50; -- Buildings, eg. trade depot
	local wonderColor = 0xaaff50ff; -- Wonders, eg. panopticon
	--local resourceColor = 0xaa00ff00; -- Resources, eg. show petroleum
	local projectColor = 0xaaff80ff; -- Projects, eg. exodus gate
	--local improvementColor = 0xaaff0000; -- Improvements, eg. terrascape
	--local perkColor = 0xaaff5050; -- Passive perks, eg. food carries over
	--local yieldColor = 0xaaff5050; -- Improvement yields, eg. +1 food from farms
	--local unitAbilityColor = 0xaaff5050; -- Unit abilities, eg. embark and heal
	
	local affinityIconSize = 0.6;

	-- add the stuff granted by this tech here --
	
	if (CachedUnitAffinityPrereqs == nil) then
		CachedUnitAffinityPrereqs = {};
		for row in GameInfo.Unit_AffinityPrereqs() do
			CachedUnitAffinityPrereqs[row.UnitType] = hmake AffinityPrereq { AffinityType = row.AffinityType, Level = row.Level };
		end
	end
	
	if (CachedBuildingAffinityPrereqs == nil) then
		CachedBuildingAffinityPrereqs = {};
		for row in GameInfo.Building_AffinityPrereqs() do
			CachedBuildingAffinityPrereqs[row.BuildingType] = hmake AffinityPrereq { AffinityType = row.AffinityType, Level = row.Level };
		end
	end

  	for thisUnitInfo in GameInfo.Units(string.format("PreReqTech = '%s'", techType)) do
 		-- if this tech grants this player the ability to make this unit
		if validUnitBuilds[thisUnitInfo.Class] == thisUnitInfo.Type then
			local buttonName = "B"..tostring(buttonNum);
			local thisButton = thisTechButtonInstance[buttonName];
			if thisButton then
				if(thisUnitInfo.Orbital == nil) then
					thisButton:SetColor(unitColor);
				else
					thisButton:SetColor(orbitalColor);
				end
				
				local unitAffinityPrereq = CachedUnitAffinityPrereqs[thisUnitInfo.Type];
				if (unitAffinityPrereq ~= nil) then
					if (unitAffinityPrereq.Level > 0) then
						local affinityInfo = GameInfo.Affinity_Types[unitAffinityPrereq.AffinityType];
						local textureInfo = m_textureAffinity[tostring(unitAffinityPrereq.AffinityType)];
						local affinityIconName = "AffinityIcon"..tostring(buttonNum);
						local affinityIcon = thisTechButtonInstance[affinityIconName];
						if affinityIcon ~= nil then
							affinityIcon:SetSizeVal( textureInfo.size, textureInfo.size);
							IconHookup( textureInfo.index, textureInfo.size, textureInfo.atlas, affinityIcon );
							affinityIcon:SetSizeVal( textureInfo.size*affinityIconSize, textureInfo.size*affinityIconSize);
							affinityIcon:SetHide( false );
						end
					end
				end
				AdjustArtOnGrantedUnitButton( thisButton, thisUnitInfo, textureSize );
				table.insert( g_recentlyAddedUnlocks, thisUnitInfo.Description );
				buttonNum = buttonNum + 1;
			end
		end
 	end

 	for thisBuildingInfo in GameInfo.Buildings(string.format("PreReqTech = '%s'", techType)) do
 		-- if this tech grants this player the ability to construct this building
		if validBuildingBuilds[thisBuildingInfo.BuildingClass] == thisBuildingInfo.Type then
			local buttonName = "B"..tostring(buttonNum);
			local thisButton = thisTechButtonInstance[buttonName];
			if thisButton then
				if GameInfo.BuildingClasses[thisBuildingInfo.BuildingClass].MaxGlobalInstances == 1 then
					thisButton:SetColor(wonderColor);
				else
					thisButton:SetColor(buildingColor);
				end
				
				local buildingAffinityPrereq = CachedBuildingAffinityPrereqs[thisBuildingInfo.Type];
				if (buildingAffinityPrereq ~= nil) then
					if (buildingAffinityPrereq.Level > 0) then
						local affinityInfo = GameInfo.Affinity_Types[buildingAffinityPrereq.AffinityType];
						local textureInfo = m_textureAffinity[tostring(buildingAffinityPrereq.AffinityType)];
						local affinityIconName = "AffinityIcon"..tostring(buttonNum);
						local affinityIcon = thisTechButtonInstance[affinityIconName];
						if affinityIcon ~= nil then
							affinityIcon:SetSizeVal( textureInfo.size, textureInfo.size);
							IconHookup( textureInfo.index, textureInfo.size, textureInfo.atlas, affinityIcon );
							affinityIcon:SetSizeVal( textureInfo.size*affinityIconSize, textureInfo.size*affinityIconSize);
							affinityIcon:SetHide( false );
						end
					end
				end
				AdjustArtOnGrantedBuildingButton( thisButton, thisBuildingInfo, textureSize );
				table.insert( g_recentlyAddedUnlocks, thisBuildingInfo.Description );
				buttonNum = buttonNum + 1;
			end
		end
 	end

 	for thisResourceInfo in GameInfo.Resources(string.format("TechReveal = '%s'", techType)) do
 		-- if this tech grants this player the ability to reveal this resource
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			--thisButton:SetColor(resourceColor);
			AdjustArtOnGrantedResourceButton( thisButton, thisResourceInfo, textureSize );
			table.insert( g_recentlyAddedUnlocks, thisResourceInfo.Description );
			buttonNum = buttonNum + 1;
		end
 	end
 
 	for thisProjectInfo in GameInfo.Projects(string.format("TechPrereq = '%s'", techType)) do
 		-- if this tech grants this player the ability to build this project
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
 		if thisButton then
			thisButton:SetColor(projectColor);
			AdjustArtOnGrantedProjectButton( thisButton, thisProjectInfo, textureSize );
			table.insert( g_recentlyAddedUnlocks, thisProjectInfo.Description );
 			buttonNum = buttonNum + 1;
 		end
	end

	-- if this tech grants this player the ability to perform this action (usually only workers can do these)
	for thisBuildInfo in GameInfo.Builds(string.format("PrereqTech = '%s'", techType)) do
		-- Improvement Build
		if thisBuildInfo.ImprovementType then
			if validImprovementBuilds[thisBuildInfo.ImprovementType] == thisBuildInfo.ImprovementType then
				local buttonName = "B"..tostring(buttonNum);
				local thisButton = thisTechButtonInstance[buttonName];
				if thisButton then
					--thisButton:SetColor(improvementColor);
					AdjustArtOnGrantedImprovementButton( thisButton, GameInfo.Improvements[thisBuildInfo.ImprovementType], textureSize );
					table.insert( g_recentlyAddedUnlocks, thisBuildInfo.Description );
					buttonNum = buttonNum + 1;
				end
 			end
		else -- Other Action
			local buttonName = "B"..tostring(buttonNum);
			local thisButton = thisTechButtonInstance[buttonName];
			if thisButton then
				AdjustArtOnGrantedActionButton( thisButton, thisBuildInfo, textureSize );
				table.insert( g_recentlyAddedUnlocks, thisBuildInfo.Description );
 				buttonNum = buttonNum + 1;
 			end
		end
	end
	
	-- show processes
	local processCondition = "TechPrereq = '" .. techType .. "'";
	for row in GameInfo.Processes(processCondition) do
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( row.PortraitIndex, textureSize, row.IconAtlas, thisButton );
			thisButton:SetHide( false );
			local strPText = Locale.ConvertTextKey( row.Description );
			thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_ENABLE_PRODUCITON_CONVERSION", strPText) );
			--table.insert( g_recentlyAddedUnlocks, row.Description );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
			buttonNum = buttonNum + 1;
		end		
	end	
		
 	-- todo: need to add abilities, etc.
	local condition = "TechType = '" .. techType .. "'";

	-- Player Perk unlocks
	for row in GameInfo.Technology_FreePlayerPerks(condition) do
		local playerPerkType = row.PlayerPerkType;
		local thisPerkInfo = GameInfo.PlayerPerks[playerPerkType];
		if (thisPerkInfo ~= nil) then
			local buttonName = "B"..tostring(buttonNum);
			local thisButton = thisTechButtonInstance[buttonName];
			if thisButton then
				--thisButton:SetColor(perkColor);
				AdjustArtOnGrantedPlayerPerkButton( thisButton, thisPerkInfo, textureSize );				
				local perkInfo = GameInfo.PlayerPerks[thisPerkInfo.ID];
				local description =  GetHelpTextForPlayerPerk(thisPerkInfo.ID, true);
				--table.insert( g_recentlyAddedUnlocks, description );
				buttonNum = buttonNum + 1;
			else
				break;
			end
		end
	end
		
	for row in GameInfo.Route_TechMovementChanges(condition) do
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_FASTER_MOVEMENT", GameInfo.Routes[row.RouteType].Description ) );
			--table.insert( g_recentlyAddedUnlocks, row.Description );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			buttonNum = buttonNum + 1;
		else
			break
		end
	end	
	
	-- Some improvements can have multiple yield changes, group them and THEN add buttons.
	local yieldChanges = {};
	for row in GameInfo.Improvement_TechYieldChanges(condition) do
		local improvementType = row.ImprovementType;
		
		if(yieldChanges[improvementType] == nil) then
			yieldChanges[improvementType] = {};
		end
		
		local improvement = GameInfo.Improvements[row.ImprovementType];
		local yield = GameInfo.Yields[row.YieldType];
		
		table.insert(yieldChanges[improvementType], Locale.Lookup( "TXT_KEY_TECH_IMPROVEMENT_YIELD_CHANGE", row.Yield, yield.IconString, yield.Description, improvement.Description));
	end
	
	-- Let's sort the yield change butons!
	local sortedYieldChanges = {};
	for k,v in pairs(yieldChanges) do
		table.insert(sortedYieldChanges, {k,v});
	end
	table.sort(sortedYieldChanges, function(a,b) return Locale.Compare(a[1], b[1]) == -1 end); 
	
	for i,v in pairs(sortedYieldChanges) do
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if(thisButton ~= nil) then
			table.sort(v[2], function(a,b) return Locale.Compare(a,b) == -1 end);
		
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(yieldColor);
			thisButton:SetHide( false );
			thisButton:SetToolTipString(table.concat(v[2], "[NEWLINE]"));
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, v[2][1] );
			buttonNum = buttonNum + 1;
		else
			break;
		end
	end	
	
	for row in GameInfo.Improvement_TechNoFreshWaterYieldChanges(condition) do
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_NO_FRESH_WATER", GameInfo.Improvements[row.ImprovementType].Description , GameInfo.Yields[row.YieldType].Description, row.Yield));
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		--table.insert( g_recentlyAddedUnlocks, row.Description );
			buttonNum = buttonNum + 1;
		else
			break;
		end
	end	

	for row in GameInfo.Improvement_TechFreshWaterYieldChanges(condition) do
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_FRESH_WATER", GameInfo.Improvements[row.ImprovementType].Description , GameInfo.Yields[row.YieldType].Description, row.Yield));
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
			--table.insert( g_recentlyAddedUnlocks, row.Description );
			buttonNum = buttonNum + 1;
		else
			break;
		end
	end	

	if tech.EmbarkedMoveChange > 0 then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_FASTER_EMBARKED_MOVEMENT" ) );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, "TXT_KEY_FASTER_EMBARKED_MOVEMENT" );
			buttonNum = buttonNum + 1;
		end
	end
	
	if tech.AllowsEmbarking then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_ALLOWS_EMBARKING" ) );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, "TXT_KEY_ALLOWS_EMBARKING" );
			buttonNum = buttonNum + 1;
		end
	end
	
	if tech.UnitFortificationModifier > 0 then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetHide( false );
			local description = Locale.ConvertTextKey( "TXT_KEY_UNIT_FORTIFICATION_MOD", tech.UnitFortificationModifier );
			thisButton:SetToolTipString( description );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, description );
			buttonNum = buttonNum + 1;
		end
	end
	
	if tech.UnitBaseHealModifier > 0 then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetHide( false );
			local description = Locale.ConvertTextKey( "TXT_KEY_UNIT_BASE_HEAL_MOD", tech.UnitBaseHealModifier );
			thisButton:SetToolTipString( description );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
			--table.insert( g_recentlyAddedUnlocks, description );
			buttonNum = buttonNum + 1;
		end
	end

	if tech.UnitBaseMiasmaHeal > 0 then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetHide( false );
			local description = Locale.ConvertTextKey( "TXT_KEY_BASE_MIASMA_HEAL", tech.UnitBaseMiasmaHeal );
			thisButton:SetToolTipString( description );	
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, description );
			buttonNum = buttonNum + 1;
		end
	end

	if tech.MapVisible then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_REVEALS_ENTIRE_MAP" ) );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, "TXT_KEY_REVEALS_ENTIRE_MAP" );
			buttonNum = buttonNum + 1;
		end
	end
	
	if tech.InternationalTradeRoutesChange > 0 then
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton then
			IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
			thisButton:SetHide( false );
			thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_ADDITIONAL_INTERNATIONAL_TRADE_ROUTE" ) );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, "TXT_KEY_ADDITIONAL_INTERNATIONAL_TRADE_ROUTE" );
			buttonNum = buttonNum + 1;
		end	
	end

	for row in GameInfo.Technology_TradeRouteDomainExtraRange(condition) do
		if (row.TechType == techType and row.Range > 0) then
			local buttonName = "B"..tostring(buttonNum);
			local thisButton = thisTechButtonInstance[buttonName];
			if thisButton then
				IconHookup( 0, textureSize, "GENERIC_FUNC_ATLAS", thisButton );
				thisButton:SetHide( false );
				if (GameInfo.Domains[row.DomainType].ID == DomainTypes.DOMAIN_LAND) then
					thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_EXTENDS_LAND_TRADE_ROUTE_RANGE" ) );
				elseif (GameInfo.Domains[row.DomainType].ID == DomainTypes.DOMAIN_SEA) then
					thisButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_EXTENDS_SEA_TRADE_ROUTE_RANGE" ) );
				end
				techPediaSearchStrings[tostring(thisButton)] = tech.Description;
				thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
				--table.insert( g_recentlyAddedUnlocks, row.Description );
				buttonNum = buttonNum + 1;
			end	
		end
	end
	
	for row in GameInfo.Technology_FreePromotions(condition) do
		local promotion = GameInfo.UnitPromotions[row.PromotionType];
		local buttonName = "B"..tostring(buttonNum);
		local thisButton = thisTechButtonInstance[buttonName];
		if thisButton and promotion ~= nil then
			AdjustArtOnButton( thisButton, promotion.PortraitIndex, promotion.IconAtlas, textureSize );		
			local description = Locale.ConvertTextKey("TXT_KEY_FREE_PROMOTION_FROM_TECH", promotion.Description, promotion.Help);
			--thisButton:SetColor(unitAbilityColor);
			thisButton:SetToolTipString( description );
			techPediaSearchStrings[tostring(thisButton)] = tech.Description;
			thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
			--table.insert( g_recentlyAddedUnlocks, description ); --row.Description );
			buttonNum = buttonNum + 1;
		else
			break;
		end
	end
	
	buttonNum = buttonNum - 1;	-- Starts off 1 based, adjust to account for # of buttons.

	return buttonNum;
	
end


-- ===========================================================================
--	Obtain small buttons for a tech and lay them out radially centered 
--	from the bottom.
-- ===========================================================================
function AddSmallButtonsToTechButtonRadial( thisTechButtonInstance, tech, maxSmallButtons, textureSize )
	local buttonNum = AddSmallButtonsToTechButton( thisTechButtonInstance, tech, maxSmallButtons, textureSize );

	-- If there are any sub-icons, lay them out:
	if buttonNum > 0 then	
		local distance		= 46;
		local anglePerIcon	= 48;
		local phiDegrees 	= 90;		-- 90 is facing down (0 is far right), +values are clockwise

		-- Push the start back based on # of icons
		phiDegrees = phiDegrees - (((buttonNum-1) * anglePerIcon) * 0.5);

		thisTechButtonInstance["B1"]:SetOffsetVal( PolarToCartesian( distance, phiDegrees ));
		thisTechButtonInstance["B2"]:SetOffsetVal( PolarToCartesian( distance, phiDegrees + (1 * anglePerIcon)) );
		thisTechButtonInstance["B3"]:SetOffsetVal( PolarToCartesian( distance, phiDegrees + (2 * anglePerIcon)) );
		thisTechButtonInstance["B4"]:SetOffsetVal( PolarToCartesian( distance, phiDegrees + (3 * anglePerIcon)) );
		--thisTechButtonInstance["B5"]:SetOffsetVal( PolarToCartesian( distance, phiDegrees + (4 * anglePerIcon)) );
		--thisTechButtonInstance["B6"]:SetOffsetVal( PolarToCartesian(50, phiDegrees + (5 * anglePerIcon)) );
		--thisTechButtonInstance["B7"]:SetOffsetVal( PolarToCartesian(50, phiDegrees + (6 * anglePerIcon)) );
	end

	
	return buttonNum;
end


function AddCallbackToSmallButtons( thisTechButtonInstance, maxSmallButtons, void1, void2, thisEvent, thisCallback )
	for buttonNum = 1, maxSmallButtons, 1 do
		local buttonName = "B"..tostring(buttonNum);
		thisTechButtonInstance[buttonName]:SetVoids(void1, void2);
		thisTechButtonInstance[buttonName]:RegisterCallback(thisEvent, thisCallback);
	end
end


function AdjustArtOnGrantedUnitButton( thisButton, thisUnitInfo, textureSize )
	-- if we have one, update the unit picture
	if thisButton then
		
		-- Tooltip
		local bIncludeRequirementsInfo = true;
		thisButton:SetToolTipString( GetHelpTextForUnit(thisUnitInfo.ID, bIncludeRequirementsInfo) );
		local portraitOffset, portraitAtlas = UI.GetUnitPortraitIcon(thisUnitInfo.ID);
		local textureOffset, textureSheet = IconLookup( portraitOffset, textureSize, portraitAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide( false );
		techPediaSearchStrings[tostring(thisButton)] = Locale.ConvertTextKey(thisUnitInfo.Description);
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
	end
end


function AdjustArtOnGrantedBuildingButton( thisButton, thisBuildingInfo, textureSize )
	-- if we have one, update the building (or wonder) picture
	if thisButton then
		
		-- Tooltip
		local bExcludeName = false;
		local bExcludeHeader = false;
		thisButton:SetToolTipString( GetHelpTextForBuilding(thisBuildingInfo.ID, bExcludeName, bExcludeHeader, false, nil) );
		
		local textureOffset, textureSheet = IconLookup( thisBuildingInfo.PortraitIndex, textureSize, thisBuildingInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide( false );
		techPediaSearchStrings[tostring(thisButton)] = Locale.ConvertTextKey(thisBuildingInfo.Description);
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
	end
end


function AdjustArtOnGrantedProjectButton( thisButton, thisProjectInfo, textureSize )
	-- if we have one, update the project picture
	if thisButton then
		
		-- Tooltip
		local bIncludeRequirementsInfo = true;
		thisButton:SetToolTipString( GetHelpTextForProject(thisProjectInfo.ID, bIncludeRequirementsInfo) );

		local textureOffset, textureSheet = IconLookup( thisProjectInfo.PortraitIndex, textureSize, thisProjectInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide( false );
		techPediaSearchStrings[tostring(thisButton)] = Locale.ConvertTextKey(thisProjectInfo.Description);
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
	end
end


function AdjustArtOnGrantedImprovementButton( thisButton, thisImprovementInfo, textureSize )
	-- if we have one, update the picture
	if thisButton then
		
		-- Tooltip
		local bExcludeName = false;
		local bExcludeHeader = false;
		thisButton:SetToolTipString( GetHelpTextForImprovement(thisImprovementInfo.ID, bExcludeName, bExcludeHeader, false) );
		
		local textureOffset, textureSheet = IconLookup( thisImprovementInfo.PortraitIndex, textureSize, thisImprovementInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide( false );
		techPediaSearchStrings[tostring(thisButton)] = Locale.ConvertTextKey(thisImprovementInfo.Description);
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
	end
end


function AdjustArtOnGrantedResourceButton( thisButton, thisResourceInfo, textureSize )
	if thisButton then
		thisButton:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVEALS_RESOURCE_ON_MAP", thisResourceInfo.Description)); 

		local textureOffset, textureSheet = IconLookup( thisResourceInfo.PortraitIndex, textureSize, thisResourceInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide( false );
		techPediaSearchStrings[tostring(thisButton)] =  Locale.Lookup(thisResourceInfo.Description);
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
	end
end

function AdjustArtOnGrantedActionButton( thisButton, thisBuildInfo, textureSize )
	if thisButton then
		thisButton:SetToolTipString( Locale.ConvertTextKey( thisBuildInfo.Description ) );
		local textureOffset, textureSheet = IconLookup( thisBuildInfo.IconIndex, textureSize, thisBuildInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		thisButton:SetTexture( textureSheet );
		thisButton:SetTextureOffset( textureOffset );
		thisButton:SetHide(false);

		local searchString = thisBuildInfo.Description;
		if thisBuildInfo.RouteType then
			searchString = Locale.ConvertTextKey( GameInfo.Routes[thisBuildInfo.RouteType].Description );
		elseif thisBuildInfo.ImprovementType then
			searchString = Locale.ConvertTextKey( GameInfo.Improvements[thisBuildInfo.ImprovementType].Description );
		elseif thisBuildInfo.Type == "TERRAFORM_ADD_MIASMA" then
			searchString = GameInfo.Concepts["CONCEPT_WORKERS_PLACE"].Description;
		elseif thisBuildInfo.Type == "TERRAFORM_CLEAR_MIASMA" then
			searchString = GameInfo.Concepts["CONCEPT_WORKERS_REMOVE"].Description;
		else -- we are a choppy thing
			searchString = Locale.ConvertTextKey( GameInfo.Concepts["CONCEPT_WORKERS_CLEARINGLAND"].Description );
		end
		techPediaSearchStrings[tostring(thisButton)] = searchString;
		thisButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
		
	end
end

function AdjustArtOnGrantedUnitUpgradeButton (thisButton, thisUnitUpgradeInfo, textureSize)
	if (thisButton ~= nil and thisUnitUpgradeInfo ~= nil) then
		IconHookup(0, textureSize, "GENERIC_FUNC_ATLAS", thisButton);
		thisButton:SetHide(false);
		thisButton:SetToolTipString(Locale.ConvertTextKey(thisUnitUpgradeInfo.Description));
	end
end

function AdjustArtOnGrantedPlayerPerkButton (thisButton, thisPerkInfo, textureSize)
	if (thisButton ~= nil and thisPerkInfo ~= nil) then
		local textureOffset, textureSheet = IconLookup( thisPerkInfo.IconIndex, textureSize, thisPerkInfo.IconAtlas );				
		if textureSheet ~= nil then
			if textureOffset == nil then
				textureSheet = defaultErrorTextureSheet;
				textureOffset = nullOffset;
			end

			thisButton:SetTexture( textureSheet );
			thisButton:SetTextureOffset( textureOffset );
			thisButton:SetHide(false);
		else
			IconHookup(0, textureSize, "GENERIC_FUNC_ATLAS", thisButton);
		end

		thisButton:SetHide(false);
		thisButton:SetToolTipString( GetHelpTextForPlayerPerk(thisPerkInfo.ID, true) );
	end
end

function AdjustArtOnButton (thisButton, iconIndex, iconAtlas, textureSize)
	if (thisButton ~= nil and iconIndex ~= nil and iconAtlas ~= nil and textureSize ~= nil) then
		local textureOffset, textureSheet = IconLookup(iconIndex, textureSize, iconAtlas );				
		if textureSheet ~= nil then
			if textureOffset == nil then
				textureSheet = defaultErrorTextureSheet;
				textureOffset = nullOffset;
			end

			thisButton:SetTexture( textureSheet );
			thisButton:SetTextureOffset( textureOffset );
			thisButton:SetHide(false);
		else
			IconHookup(0, textureSize, "GENERIC_FUNC_ATLAS", thisButton);
		end

		thisButton:SetHide(false);
	end
end


-- ===========================================================================
-- ??TRON - debug helper only (don't put into code, this can be commented out)
-- ===========================================================================
function str( val )
	if val == nil then
		return "nil";
	else
		return tostring( math.floor(val));
	end
end
