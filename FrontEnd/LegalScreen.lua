-------------------------------------------------
-------------------------------------------------
Controls.ContinueButton:RegisterCallback(Mouse.eLClick, function()
	UIManager:DequeuePopup(ContextPtr);
end);


function ShowHideHandler( bIsHide, bIsInit )
	if not bIsHide then
		UIManager:DequeuePopup(ContextPtr);
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );