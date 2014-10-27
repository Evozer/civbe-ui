-------------------------------------------------
-- Plot Bonus Popup
-------------------------------------------------

function OnPopup( popupInfo )	
    if(popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_PLOT_BONUS) then
		local playerID = popupInfo.Data1;
		local x = popupInfo.Data2;
		local y = popupInfo.Data3;
		local fromExpedition = popupInfo.Option1;
		local player = Players[playerID];
		if (player ~= nil and player:HasPlotBonusMessage(x, y)) then
			local messageTextTable = player:RetrieveAndRemovePlotBonusMessageText(x, y);
			DisplayPopup(fromExpedition, messageTextTable);
		end
    end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );



function DisplayPopup(fromExpedition, messageTextTable)
	-- Add generic window title so user knows where the data is coming from. This should be separate for each type (goody hut, or expedition site)
	local title = Locale.ConvertTextKey("{TXT_KEY_RESOURCE_POD_SEARCHED:upper}");
	if (fromExpedition) then
		title = Locale.ConvertTextKey("{TXT_KEY_EXPEDITION_COMPLETE:upper}");
	end
	Events.AudioPlay2DSound("AS2D_INTERFACE_TECH_WINDOW");
	local details = "";
	if (messageTextTable.Details ~= nil) then
		details = Locale.ConvertTextKey(messageTextTable.Details);
	end

	Controls.TitleLabel:SetText(title);	
	Controls.DetailsLabel:SetText(details);

	UIManager:QueuePopup(ContextPtr, PopupPriority.InGameUtmost);
end

function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            ClosePopup();
            return true;
        end
    end
end
ContextPtr:SetInputHandler(InputHandler);

function ClosePopup()
	UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, ClosePopup);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_PLOT_BONUS, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged( iActivePlayer, iPrevActivePlayer )
	if (not ContextPtr:IsHidden()) then
		ClosePopup();
	end
end
Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);