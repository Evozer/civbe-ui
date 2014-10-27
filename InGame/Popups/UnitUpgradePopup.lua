-- ===========================================================================
--	Unit Upgrade Panel
-- ===========================================================================

include("IconSupport");
include("InstanceManager");
include("UnitUpgradeHelper");
include("SupportFunctions");
include("InfoTooltipInclude");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local Mode				= { NORMAL = 0, TURN_BLOCKING = 1 };
local SlotTypes			= { NO_SLOT = -1, ATTACK_SLOT = 0, DEFENSE_SLOT = 1, UTILITY_SLOT = 2 };
local MAX_UPGRADE_LEVELS= 5;	-- Note NOT affinity level! (base game has 3, by default check for any extras.)

local m_UnitEntryInstanceManager = InstanceManager:new("UnitEntryInstance", "Content", Controls.UnitStack);


-- ===========================================================================
--	VARIABLES
-- ===========================================================================

local m_PopupInfo			= nil;
local m_SelectedUnit		= nil;
local m_SelectedPerk		= nil;
local m_SelectedUpgrade		= nil;
local m_Mode				= Mode.NORMAL;
local m_isSwitchToNormalMode= false;
local m_SelectedSlotType	= SlotTypes.NO_SLOT;
local m_Shown				= false;
local m_upgradeNotifications= {};



-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

function OnPopup (popupInfo)
	if (popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_UNIT_UPGRADE) then
		if not ContextPtr:IsHidden() and popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_TUTORIAL then
			OnCloseButtonClicked();
		end
		return;
	end

	m_PopupInfo = popupInfo;
	m_Mode = popupInfo.Data2;

	local isShowRequest = true;

	-- Toggle?
	if ( popupInfo.Data1 == 1 ) and ( ContextPtr:IsHidden() == false ) then
		isShowRequest = false;		
	end

	if isShowRequest then
		if (not m_Shown) then
			ShowWindow();
		end
	else
		if (m_Shown) then
			HideWindow();
		end
	end
end
Events.SerialEventGameMessagePopup.Add(OnPopup);

-- ===========================================================================
function ShowHideHandler(isHide)
	if (not isHide) then
		if (m_Shown == false) then
			Events.SerialEventGameMessagePopupShown(m_PopupInfo);
			Events.SerialEventUnitUpgradeScreenDirty();
		end
	else
		if (m_Shown == true) then
			HideWindow();
		end
		Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_UNIT_UPGRADE, 0);
	end
end
ContextPtr:SetShowHideHandler(ShowHideHandler);

-- ===========================================================================
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then

			if (not Controls.ConfirmationPopup:IsHidden()) then
				Controls.ConfirmationPopup:SetHide(true);	-- hide confirmation (internal pop-up) if up.
			else
				OnCloseButtonClicked();
			end
            return true;
        end
    end
end
ContextPtr:SetInputHandler(InputHandler);

-- ===========================================================================
function OnCloseButtonClicked()
	m_SelectedUnit = nil;
	HideWindow();
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnCloseButtonClicked);

function ShowWindow()
	ContextPtr:SetHide(false);
	UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
	Events.BlurStateChange(0);

	m_Shown = true;
end

function HideWindow()
	m_Shown = false;

	m_SelectedUpgrade = nil;
	ContextPtr:SetHide(true);
	LuaEvents.SubDiploPanelClosed();
	Events.BlurStateChange(1);
end



-- ===========================================================================
function UpdateWindow()
	-- Early-out if we're not visible
	if (ContextPtr:IsHidden() == true) then
		return;
	end

	ResetSelection();
	UpdateUnitSelectionPulldown();
	UpdateUnitInfoPanel();
	UpdateUpgradeTiers();
	UpdateUpgradeConfirmationPopup();

	if (m_SelectedUnit ~= nil) then
		local selectedUnitType = m_SelectedUnit.ID;
		local selectedUpgradeType = -1;
		local selectedPerkType = -1;

		if (m_SelectedUpgrade ~= nil) then
			selectedUpgradeType = m_SelectedUpgrade.ID;
		end

		if (m_SelectedPerk ~= nil) then
			selectedPerkType = m_SelectedPerk.ID;
		end

		UI:UpdateUnitUpgradePreview(selectedUnitType, selectedUpgradeType, selectedPerkType);
	end

	if ( m_isSwitchToNormalMode and m_Mode ~= Mode.NORMAL) then
		m_isSwitchToNormalMode = false;
		m_Mode = Mode.NORMAL;
		Events.SerialEventUnitUpgradeScreenDirty();
	end
end
Events.SerialEventUnitUpgradeScreenDirty.Add(UpdateWindow);


-- ===========================================================================
function ResetSelection()
	local player = Players[Game.GetActivePlayer()];

	-- Select first unit
	local units = {}
	for unit in GameInfo.Units() do
		local upgrades = player:GetUpgradesForUnitClassLevel(unit.ID, 1);

		if (player:CanTrain(unit.ID, true, true, true, false) and #upgrades > 0) then
			table.insert(units, unit);
		end
	end

	table.sort(units, function(a, b) return Locale.Compare(Locale.Lookup(a.Description), Locale.Lookup(b.Description)) < 0; end);

	-- If a unit isn't selected, either get the first unit in the list or
	-- the first unit that needs an upgrade (when turn blocking).
	if (m_SelectedUnit == nil) then
		m_SelectedUnit = units[1];
		if (m_Mode == Mode.TURN_BLOCKING) then
			for _,unit in ipairs(units) do
				if (player:DoesUnitHavePendingUpgrades(unit.ID)) then
					m_SelectedUnit = unit;					
					break;
				end
			end
		end				
	end

end


-- ===========================================================================
function UpdateUnitSelectionPulldown()
	local player = Players[Game.GetActivePlayer()];

	-- Track if
	local isAtLeastOneEnabled = (m_Mode == Mode.NORMAL);

	local entries = {};
	for unit in GameInfo.Units() do
		local upgrades = player:GetUpgradesForUnitClassLevel(unit.ID, 1);

		if (player:CanTrain(unit.ID, true, true, true, false) and #upgrades > 0) then

			if ( not isAtLeastOneEnabled ) then
				isAtLeastOneEnabled = player:DoesUnitHavePendingUpgrades(unit.ID);
			end

			-- Only populate in drop down if it's one in a series of blocked for upgrades or
			-- just populate if in normal (non-blocking) mode.
			table.insert(entries, 
			{
				Unit	= unit,
				Name	= Locale.ToUpper( Locale.Lookup(unit.Description)),
				Enabled	= player:DoesUnitHavePendingUpgrades(unit.ID) or (m_Mode == Mode.NORMAL)
			});
		end
	end
		
	if (m_SelectedUnit == nil and #entries >= 1) then
		m_SelectedUnit = entries[1].Unit;
	end
	Controls.UnitSelectionPullDown:ClearEntries();

	-- Signal system to switch modes because no more pending upgrades
	if ( (not isAtLeastOneEnabled) and m_Mode == Mode.TURN_BLOCKING ) then
		m_isSwitchToNormalMode = true;
		return;
	end

	table.sort(entries, function(a, b) return Locale.Compare(a.Name, b.Name) < 0; end);
	
	for i,entry in ipairs(entries) do
		local instance = {};
		Controls.UnitSelectionPullDown:BuildEntry("UnitUpgradePulldownInstance", instance);
		instance.Button:SetDisabled( not entry.Enabled );
		instance.Button:LocalizeAndSetText( entry.Name );
		instance.Button:RegisterCallback(Mouse.eLClick, function() 
			Controls.UnitSelectionPullDown:GetButton():LocalizeAndSetText(entry.Name);

			m_SelectedUnit = entry.Unit;
			m_SelectedUpgrade = nil;

			Events.SerialEventUnitUpgradeScreenDirty();
		end);
	end

	Controls.UnitSelectionPullDown:CalculateInternals();
	Controls.UnitSelectionPullDown:GetButton():LocalizeAndSetText("{" .. m_SelectedUnit.Description .. ":upper}");
	Controls.UnitSelectionPullDown:SetDisabled(false);
end


-- ===========================================================================
function AddBaseUnitTier( unit )
	local name		= Locale.ToUpper( Locale.ConvertTextKey( unit.Description ));
	--local buildType = unit:GetBuildType();
	--local thisBuild = GameInfo.Builds[buildType];
	--local thisUnitInfo = GameInfo.Units[unit:GetUnitType()];
	--local thisDomainType = unit:GetDomainType();		--if unit:GetDomainType() == DomainTypes.DOMAIN_AIR then

	-- Row
	local tierInstance = {};
	ContextPtr:BuildInstanceForControl("UpgradeTierInstance", tierInstance, Controls.UpgradeTiersStack);

	-- Cell
	local upgradeInstance = {};
	ContextPtr:BuildInstanceForControl("UpgradeInstance", upgradeInstance, tierInstance.UpgradesStack);
	
	local MAX_WIDTH = 200;

	TruncateStringWithTooltip( upgradeInstance.NameLabel, MAX_WIDTH, name );
	
	upgradeInstance.AnyAffinityLabel:SetHide( true );
	upgradeInstance.PurityLabel:SetHide( true );
	upgradeInstance.HarmonyLabel:SetHide( true );
	upgradeInstance.SupremacyLabel:SetHide( true );
	for info in GameInfo.Unit_AffinityPrereqs("UnitType = '" .. unit.Type .. "'") do
		if (info.Level > 0) then
			if (info.AffinityType == "AFFINITY_TYPE_HARMONY") then
				upgradeInstance.HarmonyLabel:SetText("[ICON_HARMONY]" .. info.Level);
				upgradeInstance.HarmonyLabel:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT", "TXT_KEY_AFFINITY_TYPE_HARMONY", info.Level));
				upgradeInstance.HarmonyLabel:SetHide(false);
			elseif (info.AffinityType == "AFFINITY_TYPE_PURITY") then
				upgradeInstance.PurityLabel:SetText("[ICON_PURITY]" .. info.Level);
				upgradeInstance.PurityLabel:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT", "TXT_KEY_AFFINITY_TYPE_PURITY", info.Level));
				upgradeInstance.PurityLabel:SetHide(false);
			elseif (info.AffinityType == "AFFINITY_TYPE_SUPREMACY") then
				upgradeInstance.SupremacyLabel:SetText("[ICON_SUPREMACY]" .. info.Level);
				upgradeInstance.SupremacyLabel:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT", "TXT_KEY_AFFINITY_TYPE_SUPREMACY", info.Level));
				upgradeInstance.SupremacyLabel:SetHide(false);
			end
		end
	end
	
	--IconHookup(upgrade.PortraitIndex, 128, upgrade.IconAtlas, upgradeInstance.Portrait);
	local portraitAtlas = "UNIT_ATLAS_1";
	--IconHookup(upgrade.PortraitIndex, 128, portraitAtlas, upgradeInstance.Portrait);
	upgradeInstance.SelectedPerkLabel:SetHide( true );
	upgradeInstance.Highlight:SetHide( true );

	local buttonText = Locale.ToUpper( Locale.ConvertTextKey("TXT_KEY_UNIT_UPGRADE_SELECT_PERK") );
	TruncateStringWithTooltip( upgradeInstance.Button, upgradeInstance.Button:GetSizeX(), buttonText );	
	upgradeInstance.Button:SetHide( true );


	-- Portrait system isn't wired up for BASE UNITs!
	local portraitSize = 128;
	if ( unit.Type == "UNIT_MARINE" ) then
		IconHookup(3, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_AIR_FIGHTER" ) then
		IconHookup(51, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_CAVALRY" ) then
		IconHookup(43, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_NAVAL_CARRIER" ) then		-- no entry
		IconHookup(28, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_NAVAL_FIGHTER" ) then
		IconHookup(19, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_RANGED_MARINE" ) then
		IconHookup(11, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_SIEGE" ) then	
		IconHookup(35, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_CNDR" ) then	
		IconHookup(63, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_CARVR" ) then	
		IconHookup(64, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_SABR" ) then	
		IconHookup(65, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_ANGEL" ) then	
		IconHookup(66, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_BATTLESUIT" ) then	
		IconHookup(67, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_AEGIS" ) then	
		IconHookup(68, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_LEV_TANK" ) then	
		IconHookup(69, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_LEV_DESTROYER" ) then	
		IconHookup(70, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_XENO_SWARM" ) then	
		IconHookup(71, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_XENO_CAVALRY" ) then	
		IconHookup(72, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_XENO_TITAN" ) then	
		IconHookup(96, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	elseif ( unit.Type == "UNIT_ROCKTOPUS" ) then	
		IconHookup(95, portraitSize, "UNIT_UPGRADE_ATLAS_1", upgradeInstance.Portrait);
	else
		upgradeInstance.Portrait:SetColor( 0xff000000 );	-- blackout if not option exists
	end

end


-- ===========================================================================
function UpdateUpgradeTiers()
	if (m_SelectedUnit == nil) then
		return;
	end

	Controls.UpgradeTiersStack:DestroyAllChildren();
	ContextPtr:BuildInstanceForControl("StackSpaceInstance", {}, Controls.UpgradeTiersStack );

	local player = Players[Game.GetActivePlayer()];

	local MAX_WIDTH = 200;
	
	AddBaseUnitTier( m_SelectedUnit );

	for i=1,MAX_UPGRADE_LEVELS,1 do
		local upgradeTypes = player:GetUpgradesForUnitClassLevel(m_SelectedUnit.ID, i);

		if (#upgradeTypes > 0) then
			local tierInstance = {};
			ContextPtr:BuildInstanceForControl("UpgradeTierInstance", tierInstance, Controls.UpgradeTiersStack);

			local hasUpgradeInPreviousTier = true;
			if (i > 1) then
				hasUpgradeInPreviousTier = player:GetAssignedUpgradeAtLevel(m_SelectedUnit.ID, i - 1) ~= -1;
			end
			local hasUpgradeInTier = player:GetAssignedUpgradeAtLevel(m_SelectedUnit.ID, i) ~= -1;

			for _,upgradeType in ipairs(upgradeTypes) do
				local hasUpgrade = player:DoesUnitHaveUpgrade(m_SelectedUnit.ID, upgradeType);

				if (not hasUpgradeInTier or hasUpgrade) then
					local upgrade = GameInfo.UnitUpgrades[upgradeType];
				
					-- Build upgrade instance
					local upgradeInstance = {};

					ContextPtr:BuildInstanceForControl("UpgradeInstance", upgradeInstance, tierInstance.UpgradesStack);

					local nameLabel = Locale.ToUpper( Locale.ConvertTextKey( upgrade.Description ) );
					TruncateStringWithTooltip( upgradeInstance.NameLabel, MAX_WIDTH, nameLabel );

					upgradeInstance.Top:SetToolTipString( GetHelpTextForUnitPerk(GameInfo.UnitPerks[upgrade.FreePerk].ID) );
					upgradeInstance.AnyAffinityLabel:SetText(upgrade.AnyAffinityLevel);
					upgradeInstance.PurityLabel:SetText("[ICON_PURITY]" .. upgrade.PurityLevel);
					upgradeInstance.HarmonyLabel:SetText("[ICON_HARMONY]" .. upgrade.HarmonyLevel);
					upgradeInstance.SupremacyLabel:SetText("[ICON_SUPREMACY]" .. upgrade.SupremacyLevel);

					upgradeInstance.AnyAffinityLabel:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT", "TXT_KEY_AFFINITY_TYPE_ANY", upgrade.AnyAffinityLevel) );
					upgradeInstance.PurityLabel:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT","TXT_KEY_AFFINITY_TYPE_PURITY",upgrade.PurityLevel) );
					upgradeInstance.HarmonyLabel:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT","TXT_KEY_AFFINITY_TYPE_HARMONY",upgrade.HarmonyLevel) );
					upgradeInstance.SupremacyLabel:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_UPANEL_AFFINITY_LEVEL_UNLOCK_TT","TXT_KEY_AFFINITY_TYPE_SUPREMACY",upgrade.SupremacyLevel) );

					upgradeInstance.AnyAffinityLabel:SetHide(upgrade.AnyAffinityLevel <= 0);					
					upgradeInstance.PurityLabel:SetHide(upgrade.PurityLevel <= 0);
					upgradeInstance.HarmonyLabel:SetHide(upgrade.HarmonyLevel <= 0);
					upgradeInstance.SupremacyLabel:SetHide(upgrade.SupremacyLevel <= 0);
					IconHookup(upgrade.PortraitIndex, 128, upgrade.IconAtlas, upgradeInstance.Portrait);

					local buttonText = Locale.ToUpper( Locale.ConvertTextKey("TXT_KEY_UNIT_UPGRADE_SELECT_PERK") );
					TruncateStringWithTooltip( upgradeInstance.Button, upgradeInstance.Button:GetSizeX(), buttonText );	

					local perkTypes		= player:GetPerksForUpgrade(upgrade.ID);
					local selectedPerk	= nil;
					local isFirstPerk	= true;
					for _,perkType in ipairs(perkTypes) do
						local doesHavePerk = player:DoesUnitHavePerk(m_SelectedUnit.ID, perkType)

						if (not hasUpgrade or (hasUpgrade and doesHavePerk)) then
							local perk = GameInfo.UnitPerks[perkType];

							-- Perk already exist, add a separator art.
							if not isFirstPerk then
								ContextPtr:BuildInstanceForControl("PerkPreviewSeperatorInstance", {}, upgradeInstance.PerksStack);
							end
					
							-- Build perk instance
							local perkInstance = {};
							ContextPtr:BuildInstanceForControl("PerkPreviewInstance", perkInstance, upgradeInstance.PerksStack);

							IconHookup(perk.PortraitIndex, 32, perk.IconAtlas, perkInstance.Portrait);
							perkInstance.Button:SetToolTipString(GetHelpTextForUnitPerk(perk.ID));

							if (doesHavePerk) then
								selectedPerk = perk;
							end

							isFirstPerk = false;
						end
					end

					local tempUpgrade = upgrade;

					upgradeInstance.Highlight:SetHide(true);
					upgradeInstance.SelectedPerkLabel:SetHide(true);					

					if (player:IsUpgradeUnlocked(upgradeType)) then
						upgradeInstance.Portrait:SetColor( 0xffffffff );
						--upgradeInstance.NewUpgradeIcon:SetHide(player:IsUnitUpgradeIgnored(upgradeType));

						if (hasUpgrade and selectedPerk ~= nil ) then
							upgradeInstance.Button:SetHide(true);
							upgradeInstance.SelectedPerkLabel:SetHide(false);
							--upgradeInstance.SelectedPerkLabel:SetText(GetHelpTextForUnitPerk(selectedPerk.ID));
						elseif (not hasUpgradeInTier and hasUpgradeInPreviousTier) then
							upgradeInstance.Button:RegisterCallback(Mouse.eLClick, function() 
								m_SelectedUpgrade = tempUpgrade;
								Events.SerialEventUnitUpgradeScreenDirty();
							end);
							upgradeInstance.Highlight:SetHide( false );
						else
							upgradeInstance.Button:SetHide(true);
						end
					else
						upgradeInstance.Portrait:SetColor( 0x30ffffff );	-- alpha out a little
						upgradeInstance.Button:SetHide(true);
					end
				end
			end

			tierInstance.UpgradesStack:CalculateSize();
			tierInstance.UpgradesStack:ReprocessAnchoring();
		end

		Controls.UpgradeTiersStack:CalculateSize();
		Controls.UpgradeTiersStack:ReprocessAnchoring();
		Controls.UpgradeTiersScrollPanel:CalculateInternalSize();
	end
end

-- ===========================================================================
--	Return the appropriate roman numeral given a base 10 number.
--	num			A number
--	RETURNS:	A string with the apporpiate roman numeral for a digit
-- ===========================================================================
function ToRoman( num ) 
	if (num == 1) then return "I"; end
	if (num == 2) then return "II"; end
	if (num == 3) then return "III"; end
	if (num == 4) then return "IV"; end
	if (num == 5) then return "V"; end
	if (num == 6) then return "VI"; end
	if (num == 7) then return "VII"; end
	if (num == 8) then return "VIII"; end
	if (num == 9) then return "IV"; end
	if (num == 10) then return "X"; end
	if (num == 40 ) then return "XL"; end
	if (num == 50 ) then return "L"; end
	if (num == 90 ) then return "XC"; end
	if (num == 100 ) then return "XC"; end

	-- Recurse...
	if (num > 100) then	return ToRoman(100).. ToRoman(num-100); end
	if (num > 90) then	return ToRoman(90) .. ToRoman(num-90);	end
	if (num > 50) then	return ToRoman(50) .. ToRoman(num-50);	end
	if (num > 40) then	return ToRoman(40) .. ToRoman(num-40);	end
	if (num > 10 ) then	return ToRoman(10) .. ToRoman(num-10);	end

	return "0";
end


-- ===========================================================================
function UpdateUpgradeConfirmationPopup()
	if m_SelectedUnit == nil or m_SelectedUpgrade == nil then
		Controls.ConfirmationPopup:SetHide(true);
		return;
	end

	Controls.UnitSelectionPullDown:SetDisabled(true);

	local player			= Players[Game.GetActivePlayer()];
	local affinityText		= "";
	local tierText			= ToRoman( m_SelectedUpgrade.UpgradeTier );
	
	local primaryAffinityInfo = nil;
	local primaryAffinityLevel = 0;
	local secondaryAffinityInfo = nil;
	local secondaryAffinityLevel = 0;

	if (m_SelectedUpgrade.HarmonyLevel > primaryAffinityLevel) then
		secondaryAffinityInfo = primaryAffinityInfo;
		secondaryAffinityLevel = primaryAffinityLevel;
		primaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_HARMONY"];
		primaryAffinityLevel = m_SelectedUpgrade.HarmonyLevel;
	elseif (m_SelectedUpgrade.HarmonyLevel > secondaryAffinityLevel) then
		secondaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_HARMONY"];
		secondaryAffinityLevel = m_SelectedUpgrade.HarmonyLevel;
	end
	if (m_SelectedUpgrade.PurityLevel > primaryAffinityLevel) then
		secondaryAffinityInfo = primaryAffinityInfo;
		secondaryAffinityLevel = primaryAffinityLevel;
		primaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_PURITY"];
		primaryAffinityLevel = m_SelectedUpgrade.PurityLevel;
	elseif (m_SelectedUpgrade.PurityLevel > secondaryAffinityLevel) then
		secondaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_PURITY"];
		secondaryAffinityLevel = m_SelectedUpgrade.PurityLevel;
	end
	if (m_SelectedUpgrade.SupremacyLevel > primaryAffinityLevel) then
		secondaryAffinityInfo = primaryAffinityInfo;
		secondaryAffinityLevel = primaryAffinityLevel;
		primaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_SUPREMACY"];
		primaryAffinityLevel = m_SelectedUpgrade.SupremacyLevel;
	elseif (m_SelectedUpgrade.SupremacyLevel > secondaryAffinityLevel) then
		secondaryAffinityInfo = GameInfo.Affinity_Types["AFFINITY_TYPE_SUPREMACY"];
		secondaryAffinityLevel = m_SelectedUpgrade.SupremacyLevel;
	end

	if (primaryAffinityInfo ~= nil) then
		affinityText = affinityText .. Locale.ConvertTextKey(primaryAffinityInfo.Description);
		if (secondaryAffinityInfo ~= nil) then
			affinityText = affinityText .. " " .. Locale.ConvertTextKey(secondaryAffinityInfo.Description);
		end
	end
	Controls.ConfirmationTitleLabel:LocalizeAndSetText("TXT_KEY_UNIT_UPGRADE_TIER", affinityText, tierText, "{" .. m_SelectedUpgrade.Description .. ":upper}");

	Controls.ConfirmationPerksStack:DestroyAllChildren();

	Controls.UpgradeDescriptionLabel:SetHide(true);
	if (m_SelectedUpgrade.FreePerk ~= nil) then
		local freePerkInfo = GameInfo.UnitPerks[m_SelectedUpgrade.FreePerk];
		if (freePerkInfo ~= nil) then
			Controls.UpgradeDescriptionLabel:SetHide(false);
			Controls.UpgradeDescriptionLabel:SetText(Locale.ToUpper( GetHelpTextForUnitPerk(freePerkInfo.ID) ));
		end
	end

	local perkTypes = player:GetPerksForUpgrade(m_SelectedUpgrade.ID);
	for _,perkType in ipairs(perkTypes) do
		local perk = GameInfo.UnitPerks[perkType];
					
		-- Build perk instance
		local perkInstance = {};
		ContextPtr:BuildInstanceForControl("PerkInstance", perkInstance, Controls.ConfirmationPerksStack);
		IconHookup(perk.PortraitIndex, 64, perk.IconAtlas, perkInstance.Portrait);
		local tempPerk = perk;
		
		-- Allow the portrait area also to be selectable for choosing a perk.
		perkInstance.Portrait:RegisterCallback(Mouse.eLClick, function() 
			m_SelectedPerk = tempPerk;
			Events.SerialEventUnitUpgradeScreenDirty();
		end);

		perkInstance.Button:RegisterCheckHandler( function(isChecked) 
			m_SelectedPerk = tempPerk;
			Events.SerialEventUnitUpgradeScreenDirty();
		end);

		-- Because setting the checkbox causes the screen to redraw (and recreate the
		-- checkbox instances) check here :) to see if a perk was seleceted.
		if ( m_SelectedPerk ~= nil ) then
			if ( m_SelectedPerk.ID == perk.ID ) then
				perkInstance.Button:SetCheck( true );
			end
		end

		Controls.PerkDescriptionLabel:SetHide(m_SelectedPerk == nil);
		Controls.UpgradeConfirmButton:SetDisabled(m_SelectedPerk == nil);
		if (m_SelectedPerk ~= nil) then
			Controls.PerkDescriptionLabel:SetText(Locale.ToUpper( GetHelpTextForUnitPerk(m_SelectedPerk.ID) ));
		end

		Controls.UpgradeConfirmButton:RegisterCallback(Mouse.eLClick, function() 
			player:AssignUnitUpgrade(m_SelectedUnit.ID, m_SelectedUpgrade.ID, m_SelectedPerk.ID);
			m_SelectedPerk				= nil;
			m_SelectedUpgrade			= nil;
			RealizeNextBlockingUnitToUpgrade();

			Events.AudioPlay2DSound("AS2D_INTERFACE_UNIT_UPGRADE_CONFIRM");
			Events.SerialEventUnitUpgradeScreenDirty();			
		end);

		Controls.UpgradeIgnoreButton:RegisterCallback(Mouse.eLClick, function() 
			player:IgnoreUnitUpgrade(m_SelectedUpgrade.ID);
			m_SelectedPerk				= nil;
			m_SelectedUpgrade			= nil;			
			RealizeNextBlockingUnitToUpgrade();

			Events.SerialEventUnitUpgradeScreenDirty();
		end);

		Controls.UpgradeCancelButton:RegisterCallback(Mouse.eLClick, function() 
			m_SelectedUpgrade = nil;
			m_SelectedPerk = nil;

			Events.SerialEventUnitUpgradeScreenDirty();
		end);

	end

	Controls.ConfirmationPerksStack:CalculateSize();
	Controls.ConfirmationPerksStack:ReprocessAnchoring();
	Controls.ContentStack:CalculateSize();
	Controls.ContentStack:ReprocessAnchoring();
	SizeWindowToContent();
	Controls.ConfirmationPopup:SetHide(false);
end
-- ===========================================================================
function SizeWindowToContent()
	Controls.ContentStack:CalculateSize();
	Controls.ContentStack:ReprocessAnchoring();
	local windowx = 500;
	if(Controls.ContentStack:GetSizeX() > Controls.ConfirmationTitleLabel:GetSizeX()) then
		windowx = Controls.ContentStack:GetSizeX() + 40;
	else
		windowx = Controls.ConfirmationTitleLabel:GetSizeX() + 40;
	end
	local windowy = Controls.ContentStack:GetSizeY() + 75;
	Controls.Window:SetSizeX(windowx);
	Controls.WindowHeader:SetSizeX(windowx);
	Controls.HeaderSeparator:SetSizeX(windowx);
	Controls.Window:SetSizeY(windowy);
	Controls.WindowHeader:SetSizeY(Controls.ConfirmationTitleLabel:GetSizeY() + 20);
	Controls.WindowHeader:SetOffsetY((Controls.ConfirmationTitleLabel:GetSizeY()-15)*-1);
end
-- ===========================================================================
function RealizeNextBlockingUnitToUpgrade()
	m_SelectedUnit = nil;

	local player = Players[Game.GetActivePlayer()];
	for unit in GameInfo.Units() do
		local isHasUpgrade = false;
		for level = 1, MAX_UPGRADE_LEVELS, 1 do
			local upgradeTypes = player:GetUpgradesForUnitClassLevel(unit.ID, level);
			isHasUpgrade = (#upgradeTypes > 0);
			if (isHasUpgrade) then
				break;
			end
		end
		if (player:CanTrain(unit.ID, true, true, true, false) and isHasUpgrade) then
			if (player:DoesUnitHavePendingUpgrades(unit.ID)) then
				m_SelectedUnit = unit;
				break;
			end
		end
	end
end



-- ===========================================================================
function UpdateUnitInfoPanel()
	if (m_SelectedUnit == nil) then
		return;
	end

	local player = Players[Game.GetActivePlayer()];
	local upgrades = player:GetUpgradesForUnit(m_SelectedUnit.ID);

	-- Perks / Special Abilities
	Controls.BuffStack:DestroyAllChildren();
	local includeFreePromotions = false;
	local helpText = GetHelpTextForUnitType(m_SelectedUnit.ID, player:GetID(), includeFreePromotions);
	if (m_SelectedPerk ~= nil) then
		if (helpText ~= "") then
			helpText = helpText .. "[NEWLINE]";
		end
		helpText = helpText .. "[COLOR_POSITIVE_TEXT]" .. GetHelpTextForUnitPerk(m_SelectedPerk.ID) .. "[ENDCOLOR]";
	end
	local buffEntryInstance = {};
	ContextPtr:BuildInstanceForControl("BuffEntryInstance", buffEntryInstance, Controls.BuffStack);
	if (helpText ~= "") then
		buffEntryInstance.Label:SetText(helpText);
	else
		buffEntryInstance.Label:SetText( Locale.ConvertTextKey("{TXT_KEY_UNIT_UPGRADE_SPECIAL_ABILITIES_NONE:upper}"));
	end

	UpdateUnitStats(m_SelectedUnit);
end


-- ===========================================================================
function UpdateUnitStats(unit)

	local player = Players[Game.GetActivePlayer()];
	local statText = "";

	-- Movement
	if unit.Domain == "DOMAIN_AIR" then
		local iRange = player:GetBaseRangeWithPerks(unit.ID);
		local szMoveStr = "[ICON_MOVES]"..iRange;
		local rebaseRange = iRange * GameDefines.AIR_UNIT_REBASE_RANGE_MULTIPLIER;
		rebaseRange = rebaseRange / 100;
	
		Controls.UnitStatMovement:SetToolTipString(Locale.ConvertTextKey( "TXT_KEY_UPANEL_UNIT_MAY_STRIKE_REBASE", iRange, rebaseRange ));
		statText = Locale.ConvertTextKey("{TXT_KEY_UPANEL_RANGEMOVEMENT:upper}").." "..szMoveStr;

	else
		local max_moves	= player:GetBaseMovesWithPerks(unit.ID);
		if (unit.Domain == "DOMAIN_SEA") then
			max_moves = max_moves + player:GetNavalMovementChangeFromPlayerPerks();
		end
		local szMoveStr	= "[ICON_MOVES]" .. math.floor(max_moves);
		
		Controls.UnitStatMovement:SetToolTipString(Locale.ConvertTextKey( "TXT_KEY_UPANEL_UNIT_MAY_MOVE", max_moves ));
		statText = Locale.ConvertTextKey("{TXT_KEY_UPANEL_MOVEMENT:upper}").." "..szMoveStr;
	end	
	Controls.UnitStatMovement:SetText( statText );
    
	-- Strength
	local strength = 0;
	statText = "";
	if(unit.Domain == DomainTypes.DOMAIN_AIR) then
		strength = player:GetBaseRangedCombatStrengthWithPerks(unit.ID);
	else
		strength = player:GetBaseCombatStrengthWithPerks(unit.ID);
	end
	if(strength > 0) then
		strength = "[ICON_STRENGTH]"..strength;
		Controls.UnitStrengthBox:SetHide(false);
		local strengthTT = Locale.ConvertTextKey( "TXT_KEY_UPANEL_STRENGTH_TT" );
		Controls.UnitStatStrength:SetToolTipString(strengthTT);

		statText = Locale.ConvertTextKey("{TXT_KEY_UPANEL_STRENGTH:upper}").." "..strength;
	else
		Controls.UnitStrengthBox:SetHide(true);
	end        
	Controls.UnitStatStrength:SetText( statText );
    
	-- Ranged Strength
	statText = "";
	local iRangedStrength = 0;
	if(unit.RangedCombat > 0 and unit.Domain ~= DomainTypes.DOMAIN_AIR) then
		iRangedStrength = player:GetBaseRangedCombatStrengthWithPerks(unit.ID);
	else
		iRangedStrength = 0;
	end
	if(iRangedStrength > 0) then
		local szRangedStrength =  "[ICON_RANGE_STRENGTH]" .. iRangedStrength ;
		Controls.UnitRangedAttackBox:SetHide(false);
		local rangeStrengthStr = Locale.ConvertTextKey( "TXT_KEY_UPANEL_RANGED_ATTACK" );
		--Controls.UnitStatNameRangedAttack:SetText(rangeStrengthStr);
		--Controls.UnitStatRangedAttack:SetText(szRangedStrength);
		local rangeStrengthTT = Locale.ConvertTextKey( "TXT_KEY_UPANEL_RANGED_ATTACK_TT" );
		Controls.UnitStatRangedAttack:SetToolTipString(rangeStrengthTT);
		--Controls.UnitStatNameRangedAttack:SetToolTipString(rangeStrengthTT);
		statText = Locale.ConvertTextKey("{TXT_KEY_UPANEL_RANGED_ATTACK:upper}").." "..szRangedStrength;
	else
		Controls.UnitRangedAttackBox:SetHide(true);
	end        
	Controls.UnitStatRangedAttack:SetText( statText );
end


-- ===========================================================================
function OnNotificationAdded( Id, type, toolTip, strSummary, iGameValue, iExtraGameData, ePlayer )
	
	if (type == NotificationTypes.NOTIFICATION_UNIT_UPGRADES_AVAILABLE) then
		table.insert( m_upgradeNotifications, Id );
	end
end
Events.NotificationAdded.Add( OnNotificationAdded );


-- ===========================================================================
function OnNotificationRemoved( Id )

	local position = 0;

	-- Find the corresponding upgrade notification (if it exist)
	for i,v in pairs(m_upgradeNotifications) do
		if ( v == Id ) then
			position = i;
			break;
		end
	end

	-- If the removed notification was related to upgrades, it would have
	-- a position other than 0. 
	if (position > 0 ) then
		table.remove( m_upgradeNotifications, i );
		-- Turn off blocking if not notifications exist.
		if #m_upgradeNotifications == 0 then
			m_Mode = Mode.NORMAL;
		else
			RealizeNextBlockingUnitToUpgrade();
		end		
		UpdateWindow();
	end
end
Events.NotificationRemoved.Add( OnNotificationRemoved );
