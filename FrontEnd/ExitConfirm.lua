-------------------------------------------------
-- Exit Game
-------------------------------------------------


-------------------------------------------------
-- Exit Button Handler
-------------------------------------------------
function OnExitGame()
	if (not UIManager:IsTopModal(ContextPtr)) then
		UIManager:PushModal( ContextPtr );
	end
end
Events.UserRequestClose.Add( OnExitGame );

----------------------------------------------------------------        
----------------------------------------------------------------
function OnYes( )
	UIManager:PopModal( ContextPtr );
	UI.ExitGame();
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );


----------------------------------------------------------------        
----------------------------------------------------------------
function OnNo( )
	UIManager:PopModal( ContextPtr );
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );

----------------------------------------------------------------  
----------------------------------------------------------------        
function OnShowHide( isHide, isInit )
	
	if(not isHide) then
	
		-- Update key depending on whether or not we're in a game.
		local inGame = ContextPtr:LookUpControl("/InGame");
		local bIsInGame = (inGame ~= nil);
		
		Controls.Message:LocalizeAndSetText(bIsInGame and "TXT_KEY_MENU_RETURN_EXIT_WARN" or "TXT_KEY_MENU_EXIT_WARN" );
	end
end
ContextPtr:SetShowHideHandler( OnShowHide );


----------------------------------------------------------------        
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE then
            OnNo()
        end
    end
    return true;
end
ContextPtr:SetInputHandler( InputHandler );
