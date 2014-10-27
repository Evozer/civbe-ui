-------------------------------------------------
-- Diplomacy and Advisors Buttons that float out in the screen
-------------------------------------------------
include( "IconSupport" );
include( "SupportFunctions"  );
include( "InstanceManager" );
local g_ChatInstances = {};

local g_iChatTeam   = -1;
local g_iChatPlayer = -1;

local g_iLocalPlayer = Game.GetActivePlayer();
local g_pLocalPlayer = Players[ g_iLocalPlayer ];
local g_iLocalTeam = g_pLocalPlayer:GetTeam();
local g_pLocalTeam = Teams[ g_iLocalTeam ];      

local m_bChatOpen = not Controls.ChatPanel:IsHidden();

-------------------------------------------------
-------------------------------------------------
-- This method refreshes the entries that are in the additional information dropdown.
-- Modders can use the Lua event "AdditionalInformationDropdownGatherEntries" to 
-- add entries to the list.
function RefreshAdditionalInformationEntries()
	local iLocalPlayer = Game.GetActivePlayer();
	local pLocalPlayer = Players[iLocalPlayer];
	local isObserver = pLocalPlayer ~= nil and pLocalPlayer:IsObserver();

	local function Popup(popupType, data1, data2)
		Events.SerialEventGameMessagePopup{ 
			Type = popupType,
			Data1 = data1,
			Data2 = data2
		};
	end

	local additionalEntries = {
		{ text = Locale.Lookup("TXT_KEY_ADVISOR_SCREEN_TECH_TREE_DISPLAY"), showInObserverMode=false, call=function() Popup(ButtonPopupTypes.BUTTONPOPUP_TECH_TREE, nil, -1); end };
		{ text = Locale.Lookup("TXT_KEY_MILITARY_OVERVIEW"), showInObserverMode=false, call=function() Popup(ButtonPopupTypes.BUTTONPOPUP_MILITARY_OVERVIEW); end };
		{ text = Locale.Lookup("TXT_KEY_ECONOMIC_OVERVIEW"),showInObserverMode=false, call=function() Popup(ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW); end };
		{ text = Locale.Lookup("TXT_KEY_POP_NOTIFICATION_LOG"), showInObserverMode=true, call=function() Popup(ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG,Game.GetActivePlayer()); end };
		{ text = Locale.Lookup("TXT_KEY_TRADE_ROUTE_OVERVIEW"), showInObserverMode=false, call=function() Popup(ButtonPopupTypes.BUTTONPOPUP_TRADE_ROUTE_OVERVIEW); end };
	};

	-- Obtain any modder/dlc entries.
	LuaEvents.AdditionalInformationDropdownGatherEntries(additionalEntries);
	
	-- Now that we have all entries, call methods to sort them
	LuaEvents.AdditionalInformationDropdownSortEntries(additionalEntries);

	 Controls.MultiPull:ClearEntries();

	Controls.MultiPull:RegisterSelectionCallback(function(id)
		local entry = additionalEntries[id];
		if(entry and entry.call ~= nil) then
			entry.call();
		end
	end);
		 
	for i,v in ipairs(additionalEntries) do
		-- Most entries are disabled for observers.
		if(not isObserver or v.showInObserverMode) then
			local controlTable = {};
			Controls.MultiPull:BuildEntry( "InstanceOne", controlTable );

			controlTable.Button:SetText( v.text );
			controlTable.Button:LocalizeAndSetToolTip( v.tip );
			controlTable.Button:SetVoid1(i);
		end		
	end

	-- STYLE HACK
	-- The grid has a nice little footer that will overlap entries if it is not resized to be larger than everything else.
	Controls.MultiPull:CalculateInternals();
	local dropDown = Controls.MultiPull;
	local width, height = dropDown:GetGrid():GetSizeVal();
	dropDown:GetGrid():SetSizeVal(width, height+20);

end
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries.Add(RefreshAdditionalInformationEntries);

function SortAdditionalInformationDropdownEntries(entries)
	table.sort(entries, function(a,b)
		return (Locale.Compare(a.text, b.text) == -1);
	end);
end
LuaEvents.AdditionalInformationDropdownSortEntries.Add(SortAdditionalInformationDropdownEntries);

-------------------------------------------------
-- On ChatToggle
-------------------------------------------------
function OnChatToggle()

    m_bChatOpen = not m_bChatOpen;

    if( m_bChatOpen ) then
        Controls.ChatPanel:SetHide( false );
        Controls.ChatToggle:SetTexture( "assets/UI/Art/Icons/MainChatOn.dds" );
        Controls.ChatToggleMouseOver:SetTexture("assets/UI/Art/Icons/MainChatOn.dds" );
				Controls.ChatToggleMouseOut:SetTexture( "assets/UI/Art/Icons/MainChatOn.dds" );
				Controls.ChatWaiting:SetToBeginning(); -- stop flashing if chat messages were waiting.
    else
        Controls.ChatPanel:SetHide( true );
        Controls.ChatToggle:SetTexture( "assets/UI/Art/Icons/MainChatOff.dds" );
        Controls.ChatToggleMouseOver:SetTexture("assets/UI/Art/Icons/MainChatOff.dds" );
				Controls.ChatToggleMouseOut:SetTexture( "assets/UI/Art/Icons/MainChatOff.dds" );
    end

	Controls.DiploStack:CalculateSize();
	Controls.DiploStack:ReprocessAnchoring();

    LuaEvents.ChatShow( m_bChatOpen );
end
Controls.ChatToggle:RegisterCallback( Mouse.eLClick, OnChatToggle );


-------------------------------------------------
-------------------------------------------------
--local bFlipper = false;
function OnChat( fromPlayer, toPlayer, text, eTargetType )

    local controlTable = {};
    ContextPtr:BuildInstanceForControl( "ChatEntry", controlTable, Controls.ChatStack );
  
    table.insert( g_ChatInstances, controlTable );
    if( #g_ChatInstances > 100 ) then
        Controls.ChatStack:ReleaseChild( g_ChatInstances[ 1 ].Box );
        table.remove( g_ChatInstances, 1 );
    end
    
    TruncateString( controlTable.String, 200, Players[fromPlayer]:GetNickName() );
    local fromName = controlTable.String:GetText();
    
    if( eTargetType == ChatTargetTypes.CHATTARGET_TEAM ) then
        controlTable.String:SetColorByName( "Green_Chat" );
        controlTable.String:SetText( fromName .. ": " .. text ); 
        
    elseif( eTargetType == ChatTargetTypes.CHATTARGET_PLAYER ) then
    
        local toName;
        if( toPlayer == g_iLocalPlayer ) then
            toName = Locale.ConvertTextKey( "TXT_KEY_YOU" );
        else
            TruncateString( controlTable.String, 200, Players[toPlayer]:GetNickName() );
            toName = Locale.ConvertTextKey( "TXT_KEY_DIPLO_TO_PLAYER", controlTable.String:GetText() );
        end
        controlTable.String:SetText( fromName .. " (" .. toName .. "): " .. text ); 
        controlTable.String:SetColorByName( "Magenta_Chat" );
        
    elseif( fromPlayer == g_iLocalPlayer ) then
        controlTable.String:SetColorByName( "Gray_Chat" );
        
        controlTable.String:SetText( fromName .. ": " .. text ); 
    else
        controlTable.String:SetText( fromName .. ": " .. text ); 
    end

		-- flash the chat toggle button if there are chat messages waiting while the chat panel is closed.
		if(not m_bChatOpen) then
			Controls.ChatWaiting:Play(); 
		end
      
    controlTable.Box:SetSizeY( controlTable.String:GetSizeY() + 8 );
    controlTable.Box:ReprocessAnchoring();

    --if( bFlipper ) then
    --    controlTable.Box:SetColorChannel( 3, 0.4 );
    --end
    --bFlipper = not bFlipper;
    
	Events.AudioPlay2DSound( "AS2D_IF_MP_CHAT_DING" );		

    Controls.ChatStack:CalculateSize();
    Controls.ChatScroll:CalculateInternalSize();
    Controls.ChatScroll:SetScrollValue( 1 );
end
Events.GameMessageChat.Add( OnChat );


-------------------------------------------------
-------------------------------------------------
function SendChat( text )
    if( string.len( text ) > 0 ) then
        Network.SendChat( text, g_iChatTeam, g_iChatPlayer );
    end
    Controls.ChatEntry:ClearString();
end
Controls.ChatEntry:RegisterCommitCallback( SendChat ); 

-------------------------------------------------
-------------------------------------------------
function ShowHideInviteButton()
	local bShow = PreGame.IsInternetGame();
	Controls.MPInvite:SetHide( not bShow );
end

-------------------------------------------------
-- On MPInvite
-------------------------------------------------
function OnMPInvite()
    Steam.ActivateInviteOverlay();	
end
Controls.MPInvite:RegisterCallback( Mouse.eLClick, OnMPInvite );

----------------------------------------------------------------
----------------------------------------------------------------
function OnPlayerDisconnect( playerID )
    if( ContextPtr:IsHidden() == false ) then
    	ShowHideInviteButton();
	end
end
Events.MultiplayerGamePlayerDisconnected.Add( OnPlayerDisconnect );


-- ===========================================================================
function RealizeCorner()
	
	local iLocalPlayer	= Game.GetActivePlayer();
	local pLocalPlayer	= Players[iLocalPlayer];
	local isObserver	= (pLocalPlayer ~= nil and pLocalPlayer:IsObserver());

	-- Observers have most of the diplocorner disabled because they are not an active civ.
	Controls.ActionCornerBackground:SetHide(isObserver);
	Controls.DiploButton:SetHide(isObserver);
	Controls.VirtuesButton:SetHide(isObserver);
	Controls.EspionageButton:SetHide(isObserver);
	Controls.UnitUpgradeButton:SetHide(isObserver);
	Controls.QuestLogButton:SetHide(isObserver);

	LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();

	Controls.DiploStack:CalculateSize();
	Controls.DiploStack:ReprocessAnchoring();
end


-------------------------------------------------
-------------------------------------------------
function ShowHideHandler( bIsHide )
   -- Controls.CornerAnchor:SetHide( false );

    if(not bIsHide) then
		ShowHideInviteButton();
		RealizeCorner();
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

-------------------------------------------------
-------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if( m_bChatOpen 
        and uiMsg == KeyEvents.KeyUp
        and wParam == Keys.VK_TAB ) then
        Controls.ChatEntry:TakeFocus();
        return true;
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function HideAllWindows()
	--Controls.ButtonDimmer:SetHide( true );

    ContextPtr:LookUpControl("/InGame/QuestLogPopup")       :SetHide(true);
    ContextPtr:LookUpControl("/InGame/UnitUpgradePopup")    :SetHide(true);
	ContextPtr:LookUpControl("/InGame/CovertOpsPopup")      :SetHide(true);
	ContextPtr:LookUpControl("/InGame/VirtuesPopup")		:SetHide(true);
    ContextPtr:LookUpControl("/InGame/DiploPopup")          :SetHide(true);
	    
    Controls.QuestLogTail  :SetHide(true);
    Controls.UpgradeTail   :SetHide(true);
	Controls.EspionageTail :SetHide(true);
	Controls.VirtuesTail   :SetHide(true);
	Controls.DiploTail     :SetHide(true);	
end

-------------------------------------------------------------------------------
--  Callback from raised sub-panel that it's closed due to ESC and/or close
--  button being pressed.
-------------------------------------------------------------------------------
function OnSubDiploPanelClosed()
	HideAllWindows();
    LowerNextTurnBlocker();
end
LuaEvents.SubDiploPanelClosed.Add( OnSubDiploPanelClosed );



-- ===========================================================================
--	Another pop-ups occurs?  Clean up any pop-ups this controls that may be
--	still open.
-- ===========================================================================
function OnPopup( popupInfo )
	if popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_TECH_TREE then
		OnSubDiploPanelClosed();
		return;
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-- ===========================================================================
--	Going into a city? Close out the dialog.
-- ===========================================================================
function OnEnterCityScreen()
	OnSubDiploPanelClosed();
end
Events.SerialEventEnterCityScreen.Add(OnEnterCityScreen);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnVirtuesClicked()	
	if(ContextPtr:LookUpControl("/InGame/VirtuesPopup"):IsHidden()==false) then
		HideAllWindows();
		RaiseNextTurnBlocker();
		LuaEvents.SubDiploPanelClosed();
	else
		HideAllWindows();
		RaiseNextTurnBlocker();
		Events.SerialEventGameMessagePopup{Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY};
		Controls.VirtuesTail:SetHide(false);
		--Controls.ButtonDimmer:SetHide(false);
	end
end
Controls.VirtuesButton:RegisterCallback( Mouse.eLClick, OnVirtuesClicked );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnDiploClicked()
	if(ContextPtr:LookUpControl("/InGame/DiploPopup"):IsHidden()==false) then
		HideAllWindows();
		RaiseNextTurnBlocker();
		LuaEvents.SubDiploPanelClosed();
	else
		HideAllWindows();
		RaiseNextTurnBlocker();
		Events.SerialEventGameMessagePopup{Type = ButtonPopupTypes.BUTTONPOPUP_DIPLOMACY};
		Controls.DiploTail:SetHide(false);
		--Controls.ButtonDimmer:SetHide(false);
	end
end
Controls.DiploButton:RegisterCallback( Mouse.eLClick, OnDiploClicked );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnUnitUpgradeButtonClicked()
	if(ContextPtr:LookUpControl("/InGame/UnitUpgradePopup"):IsHidden()==false) then
		HideAllWindows();
		RaiseNextTurnBlocker();
		LuaEvents.SubDiploPanelClosed();
	else
		HideAllWindows();
		RaiseNextTurnBlocker();
		Events.SerialEventGameMessagePopup{Type = ButtonPopupTypes.BUTTONPOPUP_UNIT_UPGRADE};
		Controls.UpgradeTail:SetHide(false);
		--Controls.ButtonDimmer:SetHide(false);
	end
end
Controls.UnitUpgradeButton:RegisterCallback(Mouse.eLClick, OnUnitUpgradeButtonClicked);

----------------------------------------------------------------
function OnClickOrbitalViewButton()
	Events.SerialEventSetOrbitalView( true );
end
Controls.OrbitalViewButton:RegisterCallback( Mouse.eLClick, OnClickOrbitalViewButton );

----------------------------------------------------------------
function OnSetOrbitalView()
	Controls.OrbitalTail:SetHide( not UI.IsInOrbitalView() );
end
Events.SerialEventSetOrbitalView.Add(OnSetOrbitalView);

-------------------------------------------------------------------------------
function OnInterfaceModeChanged( oldInterfaceMode, newInterfaceMode)
	if (newInterfaceMode == InterfaceModeTypes.INTERFACEMODE_PLANETFALL) then
		Controls.OrbitalTail:SetHide( false );
	elseif (oldInterfaceMode == InterfaceModeTypes.INTERFACEMODE_PLANETFALL) then
		Controls.OrbitalTail:SetHide( true );
	end
end
Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );

-------------------------------------------------------------------------------
function OnQuestLogButtonClicked()
	if(ContextPtr:LookUpControl("/InGame/QuestLogPopup"):IsHidden()==false) then
		HideAllWindows();
		RaiseNextTurnBlocker();
		LuaEvents.SubDiploPanelClosed();
	else
		HideAllWindows();
		RaiseNextTurnBlocker();
		Events.SerialEventGameMessagePopup{Type = ButtonPopupTypes.BUTTONPOPUP_QUEST_LOG, Data2 = -1};
		Controls.QuestLogTail:SetHide(false);
		--Controls.ButtonDimmer:SetHide(false);
	end
end
Controls.QuestLogButton:RegisterCallback(Mouse.eLClick, OnQuestLogButtonClicked);

-------------------------------------------------------------------------------
function OnEspionageButtonClicked()
	if(ContextPtr:LookUpControl("/InGame/CovertOpsPopup"):IsHidden()==false) then
		HideAllWindows();
		RaiseNextTurnBlocker();
		LuaEvents.SubDiploPanelClosed();
	else
		HideAllWindows();
		RaiseNextTurnBlocker();
		Events.SerialEventGameMessagePopup{Type = ButtonPopupTypes.BUTTONPOPUP_ESPIONAGE_OVERVIEW};
		Controls.EspionageTail:SetHide(false);
		--Controls.ButtonDimmer:SetHide(false);
	end
end
Controls.EspionageButton:RegisterCallback(Mouse.eLClick, OnEspionageButtonClicked);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnOpenPlayerDealScreen( iOtherPlayer )
	-- close panels when the player deal screen is opened.
	if(ContextPtr:LookUpControl("/InGame/DiploPopup"):IsHidden()==false) then
		LuaEvents.SubDiploPanelClosed();
	end
	
	HideAllWindows();
	RaiseNextTurnBlocker();
end
Events.OpenPlayerDealScreenEvent.Add( OnOpenPlayerDealScreen );
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnChatTarget( iTeam, iPlayer )
	g_iChatTeam = iTeam;
	g_iChatPlayer = iPlayer;

	if( iTeam ~= -1 ) then
		Controls.ChatPull:GetButton():LocalizeAndSetToolTip("TXT_KEY_DIPLO_TO_TEAM");
		Controls.ChatPull:GetButton():SetText( "[ICON_CHAT_TEAM]" );
	else
		if( iPlayer ~= -1 ) then
			local MAX_NAME_CHARS= 20;
			local strNickName	= TruncateStringByLength( Players[ iPlayer ]:GetNickName(), MAX_NAME_CHARS);
			Controls.ChatPull:GetButton():LocalizeAndSetToolTip("TXT_KEY_DIPLO_TO_PLAYER", strNickName);
			Controls.ChatPull:GetButton():SetText("[ICON_CHAT_PLAYER]");
		else
			Controls.ChatPull:GetButton():LocalizeAndSetToolTip("TXT_KEY_DIPLO_TO_ALL");
			Controls.ChatPull:GetButton():SetText("[ICON_CHAT_ALL]");
		end
	end
end
Controls.ChatPull:RegisterSelectionCallback( OnChatTarget );


-------------------------------------------------------
-------------------------------------------------------
function PopulateChatPull()

    Controls.ChatPull:ClearEntries();

    -------------------------------------------------------
    -- Add All Entry
    local controlTable = {};
    Controls.ChatPull:BuildEntry( "InstanceOne", controlTable );
    controlTable.Button:SetVoids( -1, -1 );
    local textControl = controlTable.Button:GetTextControl();
		controlTable.Button:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DIPLO_TO_ALL") );
    textControl:SetText( "[ICON_CHAT_ALL]" );


    -------------------------------------------------------
    -- See if Team has more than 1 other human member
    local iTeamCount = 0;
    for iPlayer = 0, GameDefines.MAX_PLAYERS do
        local pPlayer = Players[iPlayer];

        if( iPlayer ~= g_iLocalPlayer and pPlayer ~= nil and pPlayer:IsHuman() and pPlayer:GetTeam() == g_iLocalTeam ) then
            iTeamCount = iTeamCount + 1;
        end
    end

    if( iTeamCount > 0 ) then
        local controlTable = {};
        Controls.ChatPull:BuildEntry( "InstanceOne", controlTable );
        controlTable.Button:SetVoids( g_iLocalTeam, -1 );
        local textControl = controlTable.Button:GetTextControl();
				controlTable.Button:LocalizeAndSetToolTip("TXT_KEY_DIPLO_TO_TEAM");
        textControl:SetText( "[ICON_CHAT_TEAM]" );
    end


    -------------------------------------------------------
    -- Humans
    for iPlayer = 0, GameDefines.MAX_PLAYERS do
        local pPlayer = Players[iPlayer];

        if( iPlayer ~= g_iLocalPlayer and pPlayer ~= nil and pPlayer:IsHuman() ) then

            controlTable = {};
            Controls.ChatPull:BuildEntry( "InstanceOne", controlTable );
            controlTable.Button:SetVoids( -1, iPlayer );
            textControl = controlTable.Button:GetTextControl();
			local MAX_NAME_CHARS= 20;
			local strNickName		= TruncateStringByLength(pPlayer:GetNickName(), MAX_NAME_CHARS);
			controlTable.Button:LocalizeAndSetToolTip("TXT_KEY_DIPLO_TO_PLAYER", strNickName);
			textControl:SetText( "[ICON_CHAT_PLAYER]" );
        end
    end
    Controls.ChatPull:GetButton():SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_TO_ALL" ));
	Controls.ChatPull:GetButton():SetText("[ICON_CHAT_ALL]");
    Controls.ChatPull:CalculateInternals();
end
Events.MultiplayerGamePlayerUpdated.Add(PopulateChatPull);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function DoUpdateLeagueCountdown()
	local bHide = true;
	local sTooltip = Locale.ConvertTextKey("TXT_KEY_EO_DIPLOMACY");
				
	if (Game.GetNumActiveLeagues() > 0) then
		local pLeague = Game.GetActiveLeague();
		if (pLeague ~= nil) then
			local iCountdown = pLeague:GetTurnsUntilSession();
			if (iCountdown ~= 0 and not pLeague:IsInSession()) then
				bHide = false;
				if (PreGame.IsVictory(GameInfo.Victories["VICTORY_DIPLOMATIC"].ID) and Game.IsUnitedNationsActive() and Game.GetGameState() == GameplayGameStateTypes.GAMESTATE_ON) then
					local iCountdownToVictorySession = pLeague:GetTurnsUntilVictorySession();
					if (iCountdownToVictorySession <= iCountdown) then
						Controls.UNTurnsLabel:SetText("[COLOR_POSITIVE_TEXT]" .. iCountdownToVictorySession .. "[ENDCOLOR]");
					else
						Controls.UNTurnsLabel:SetText(iCountdown);
					end
					sTooltip = Locale.ConvertTextKey("TXT_KEY_EO_DIPLOMACY_AND_VICTORY_SESSION", iCountdown, iCountdownToVictorySession);
				else
					Controls.UNTurnsLabel:SetText(iCountdown);
					sTooltip = Locale.ConvertTextKey("TXT_KEY_EO_DIPLOMACY_AND_LEAGUE_SESSION", iCountdown);
				end
			end
		end
	end
	
	Controls.UNTurnsLabel:SetHide(bHide);
	Controls.DiploButton:SetToolTipString(sTooltip);
end
Events.SerialEventGameDataDirty.Add(DoUpdateLeagueCountdown);

-- Also call it once so it starts correct - surprisingly enough, GameData isn't dirtied as we're loading a game
DoUpdateLeagueCountdown();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function DoUpdateEspionageButton()
	local iLocalPlayer = Game.GetActivePlayer();
	local pLocalPlayer = Players[iLocalPlayer];
	local iNumUnassignedSpies = pLocalPlayer:GetNumIdleCovertAgents();
	
	local strToolTip = Locale.ConvertTextKey("TXT_KEY_COVERT_OPS");
	
	if (iNumUnassignedSpies > 0) then
		strToolTip = strToolTip .. "[NEWLINE][NEWLINE]";
		strToolTip = strToolTip .. Locale.ConvertTextKey("TXT_KEY_EO_UNASSIGNED_AGENTS_TT", iNumUnassignedSpies);
		Controls.UnassignedSpiesLabel:SetHide(false);
		Controls.UnassignedSpiesLabel:SetText(iNumUnassignedSpies);
	else
		Controls.UnassignedSpiesLabel:SetHide(true);
	end
	
	Controls.EspionageButton:SetToolTipString(strToolTip);
end
Events.SerialEventEspionageScreenDirty.Add(DoUpdateEspionageButton);

--------------------------------------------------------------------
function HandleNotificationAdded(notificationId, notificationType, toolTip, summary, gameValue, extraGameData)
	
	-- In the event we receive a new spy, make sure the large button is displayed.
	if(ContextPtr:IsHidden() == false) then
		if(notificationType == NotificationTypes.NOTIFICATION_SPY_CREATED_ACTIVE_PLAYER) then
			CheckEspionageStarted();
		end
	end
end
Events.NotificationAdded.Add(HandleNotificationAdded);

DoUpdateEspionageButton();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
if( Game.IsGameMultiPlayer() ) then
    PopulateChatPull();

	if ( not Game.IsHotSeat() ) then
		Controls.ChatToggle:SetHide( false );
		OnChatToggle();
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnEndGameButton()

    local which = math.random( 1, 6 );
    
    if( which == 1 ) then Events.EndGameShow( EndGameTypes.Technology, Game.GetActivePlayer() ); 
    elseif( which == 2 ) then Events.EndGameShow( EndGameTypes.Domination, Game.GetActivePlayer() );
    elseif( which == 3 ) then Events.EndGameShow( EndGameTypes.Culture, Game.GetActivePlayer() );
    elseif( which == 4 ) then Events.EndGameShow( EndGameTypes.Diplomatic, Game.GetActivePlayer() );
    elseif( which == 5 ) then Events.EndGameShow( EndGameTypes.Time, Game.GetActivePlayer() );
    elseif( which == 6 ) then Events.EndGameShow( EndGameTypes.Time, Game.GetActivePlayer() + 1 ); 
    end
end
Controls.EndGameButton:RegisterCallback( Mouse.eLClick, OnEndGameButton );

local g_PerPlayerState = {};
-------------------------------------------------------------------------------
-- 'Active' (local human) player has changed
-------------------------------------------------------------------------------
function OnDiploCornerActivePlayerChanged( iActivePlayer, iPrevActivePlayer )
	local diploContext = ContextPtr:LookUpControl("/InGame/DiploPopup");

	-- Restore the state per player
	local bIsHidden = diploContext:IsHidden() == true;
	-- Save the state per player
	if (iPrevActivePlayer ~= -1) then
		g_PerPlayerState[ iPrevActivePlayer + 1 ] = bIsHidden;
	end
	
	if (iActivePlayer ~= -1) then
		if (g_PerPlayerState[ iActivePlayer + 1 ] == nil or g_PerPlayerState[ iActivePlayer + 1 ] == -1) then
			diploContext:SetHide( true );
		else
			local bWantHidden = g_PerPlayerState[ iActivePlayer + 1 ];
			if ( bWantHidden ~= diploContext:IsHidden()) then
				diploContext:SetHide( bWantHidden );
			end
		end
	end

	g_iLocalPlayer = Game.GetActivePlayer();
	g_pLocalPlayer = Players[ g_iLocalPlayer ];
	g_iLocalTeam = g_pLocalPlayer:GetTeam();
	g_pLocalTeam = Teams[ g_iLocalTeam ];
	PopulateChatPull();
end
Events.GameplaySetActivePlayer.Add(OnDiploCornerActivePlayerChanged);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function CheckEspionageStarted()
	function TestEspionageStarted()
		local player = Players[Game.GetActivePlayer()];
		return player:GetNumCovertAgents() > 0;
	end

	local bEspionageStarted = TestEspionageStarted();

--	Controls.CornerAnchor:SetHide(bEspionageStarted);
--	Controls.CornerAnchor_Espionage:SetHide(not bEspionageStarted);
--	Controls.EspionageButton:SetHide(not bEspionageStarted);
--	if(bEspionageStarted) then
		DoUpdateEspionageButton();
--	end
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnSubDiploPanelOpen( subPanel )
    RaiseNextTurnBlocker();
end
LuaEvents.SubDiploPanelOpen.Add( OnSubDiploPanelOpen );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function RaiseNextTurnBlocker()
    local nextTurnButton = ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel/NextTurnBlocker");
    nextTurnButton:SetHide( false );   
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function LowerNextTurnBlocker()
    local nextTurnButton = ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel/NextTurnBlocker");
    nextTurnButton:SetHide( true );   
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnActivePlayerTurnStart()
 	CheckEspionageStarted();
	RealizeCorner();
end
Events.ActivePlayerTurnStart.Add(OnActivePlayerTurnStart);





-------------------------------------------------------------------------------
--  Go...
-------------------------------------------------------------------------------
OnActivePlayerTurnStart();

--Hide CultureOverview, if disabled.
if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then
	Controls.CultureOverviewButton:SetHide(true);
end