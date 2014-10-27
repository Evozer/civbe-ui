-- ===========================================================================
-- QuestPopup
-- ===========================================================================
local m_PopupInfo = nil;



-- ===========================================================================
--	Functions
-- ===========================================================================


-- ===========================================================================
function OnPopup(popupInfo)
	if (popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_QUEST_COMPLETE) then
		return;
	end

	m_PopupInfo = popupInfo;

	ShowWindow();
end
Events.SerialEventGameMessagePopup.Add(OnPopup);


-- ===========================================================================
function InputHandler(msg, param1, param2)
	if (msg == KeyEvents.KeyDown) then
		if (param1 == Keys.VK_ESCAPE or param1 == Keys.VK_RETURN) then
			HideWindow();
			return true;
		end
	end
end
ContextPtr:SetInputHandler(InputHandler);


-- ===========================================================================
function HideWindow()
	if (m_PopupInfo ~= nil) then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate(m_PopupInfo.Type, 0);
	end

	UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, HideWindow);		--??TRON remove, redundant
Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, HideWindow);


-- ===========================================================================
function ShowWindow()
	local playerType = m_PopupInfo.Data1;
	local questIndex = m_PopupInfo.Data2;
	local quest = Players[playerType]:GetQuestWithIndex(questIndex);
	local objectives = quest:GetObjectives();
	local lastObjective = objectives[#objectives];

	local name = GameInfo.Quests[quest:GetType()].Description;
	local nameOverride = quest:GetNameOverride();
	if nameOverride ~= nil then
		name = nameOverride;
	end

	Controls.CompletedText:SetText(Locale.ConvertTextKey("TXT_KEY_QUEST_COMPLETE_POPUP_COMPLETED", name));
	Controls.EpilogueText:LocalizeAndSetText(lastObjective:GetEpilogue());
	Controls.RewardHeader:SetText(Locale.ConvertTextKey("TXT_KEY_QUEST_COMPLETE_POPUP_REWARD"));
	
	-- Rewards
	local rewardStrings = {quest:GetReward()};
	local noReward		= "$NO REWARD$";				-- defined in CvLuaQuest.cpp

    
	Controls.RewardsStack:DestroyAllChildren(); 

	if (quest:DidSucceed()) then					
		if (#rewardStrings > 0) and (not ( #rewardStrings == 1 and rewardStrings[1] == noReward )) then
			for i,reward in pairs(rewardStrings) do
				local rewardInstance = {};
				ContextPtr:BuildInstanceForControl("RewardInstance", rewardInstance, Controls.RewardsStack);
				rewardInstance.Reward:SetText( Locale.ConvertTextKey(reward) );
			end
		end
	end

	Controls.RewardsStack:CalculateSize(); 
	Controls.RewardsStack:ReprocessAnchoring(); 
	Controls.TextStack:CalculateSize();
	Controls.TextStack:ReprocessAnchoring();

	local originalHeight = Controls.Popup:GetSizeY();
	local textHeight = Controls.TextStack:GetSizeY() + Controls.RewardsStack:GetSizeY();
	if ( textHeight > originalHeight - 60 ) then
		Controls.Popup:SetSizeY(textHeight + 80);
	else
		Controls.Popup:SetSizeY(originalHeight);
	end

	UIManager:QueuePopup(ContextPtr, PopupPriority.InGameUtmost);
end