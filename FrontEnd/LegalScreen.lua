-------------------------------------------------
-------------------------------------------------
function ShowHideHandler( bIsHide, bIsInit )
    UIManager:DequeuePopup(ContextPtr);
end
ContextPtr:SetShowHideHandler( ShowHideHandler );