------------------------------------------------------------------------------
-- Technology Web
------------------------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "TechButtonInclude" );
include( "TechHelpInclude" );
include( "MathHelpers" );
include( "TechFilterFunctions" );



-- ===== 1 Time Toggable Options =============================================

local m_fastDebug						= false; 	-- Debug: Use to animated in all nodes while debugging (before they are done loaded.)
local m_showTechIDsDebug				= false;		-- Debug: Show technology IDs in their names
local m_forceNodesNum					= -1; 		-- Debug: Force only this many nodes on the tree
local isLookLikeWindows95				= false;	-- Miss windows 95? Turn this on.
local isHasLineSparkles					= false;	-- Faint Sparkles along ALL lines
local isHasLineSparklesAvailable		= false;		-- Same as above but for available lines only.
local m_bUseMiniMapIfPresent			= true;		-- Connect to minimap (if it exists in XML)


-- ===== COLOR and TEXTURE constants =========================================

-- Colors are in ABGR hex format:
local MAX_LINE_SPARKLES					= 12;				-- Number of art elements moving on a line
local g_colorLine 						= 0x7f74564a;
local g_colorAvailableLine				= 0xffb4366b; --0xffF05099; --0xff501040; --0xffb4366b;	 -- purple 	

local g_colorNotResearched 				= 0x50ffffff; --0xbb7d7570;	 -- gray 		125, 117, 	112
local g_colorAvailable					= 0xaaffffff;
local g_colorCurrent 					= 0xfff09020;	 -- blue 		251, 187, 	74
local g_colorAlreadyResearched			= 0xffd6b8a3;	 -- 
local g_colorWhiteAlmost			 	= 0xfffafafa;	 -- white		250, 250, 	250
local g_colorNodeSelectedCursor			= 0xffe09050;
local g_colorNotResearchedSmallIcons	= 0xff908070;

-- TechWebAtlas:
local g_textureTearFullNotResearched	= { u=1,	v=1 };		-- 68x68
local g_textureTearFullResearched		= { u=69,	v=1 };
local g_textureTearFullSelected			= { u=137,	v=1 };
local g_textureTearFullAvailable		= { u=205,	v=1 };
local g_textureTearLeafNotResearched	= { u=1,	v=70 };
local g_textureTearLeafResearched		= { u=54,	v=70 };
local g_textureTearLeafSelected			= { u=107,	v=70 };
local g_textureTearLeafAvailable		= { u=160,	v=70 };


local g_textColors = {};
g_textColors["AlreadyResearched"]		= g_colorWhiteAlmost;
g_textColors["Free"]					= g_colorNotResearched;
g_textColors["CurrentlyResearching"]	= g_colorCurrent;
g_textColors["Available"]				= g_colorNotResearched;
g_textColors["Locked"]					= g_colorNotResearched;
g_textColors["Unavailable"]				= g_colorNotResearched;

local g_iconColors = {};
g_iconColors["AlreadyResearched"]		= g_colorWhiteAlmost;
g_iconColors["Free"]					= g_colorAvailable;
g_iconColors["CurrentlyResearching"]	= g_colorWhiteAlmost;
g_iconColors["Available"]				= g_colorAvailable;
g_iconColors["Locked"]					= g_colorNotResearched;
g_iconColors["Unavailable"]				= g_colorNotResearched;

local g_smallIconColors = {};
g_smallIconColors["AlreadyResearched"]		= g_colorWhiteAlmost;
g_smallIconColors["Free"]					= g_colorNotResearchedSmallIcons;
g_smallIconColors["CurrentlyResearching"]	= g_colorWhiteAlmost;
g_smallIconColors["Available"]				= g_colorNotResearchedSmallIcons;
g_smallIconColors["Locked"]					= g_colorNotResearchedSmallIcons;
g_smallIconColors["Unavailable"]			= g_colorNotResearchedSmallIcons;

local g_textureBgFull = {};
g_textureBgFull["AlreadyResearched"]	= g_textureTearFullResearched;
g_textureBgFull["Free"]					= g_textureTearFullAvailable;
g_textureBgFull["CurrentlyResearching"]	= g_textureTearFullSelected;
g_textureBgFull["Available"]			= g_textureTearFullAvailable;
g_textureBgFull["Locked"]				= g_textureTearFullNotResearched;
g_textureBgFull["Unavailable"]			= g_textureTearFullNotResearched;

local g_textureBgLeaf = {};
g_textureBgLeaf["AlreadyResearched"]	= g_textureTearLeafResearched;
g_textureBgLeaf["Free"]					= g_textureTearLeafAvailable;
g_textureBgLeaf["CurrentlyResearching"]	= g_textureTearLeafSelected;
g_textureBgLeaf["Available"]			= g_textureTearLeafAvailable;
g_textureBgLeaf["Locked"]				= g_textureTearLeafNotResearched;
g_textureBgLeaf["Unavailable"]			= g_textureTearLeafNotResearched;

local g_colorAffinity		= {};
g_colorAffinity["AFFINITY_TYPE_HARMONY"] 		= 0xffa7d74a;
g_colorAffinity["AFFINITY_TYPE_PURITY"] 		= 0xff1d1ad8;
g_colorAffinity["AFFINITY_TYPE_SUPREMACY"] 		= 0xff2fbcff;


-- ===== Static Constants ===================================================

local NUM_SEARCH_CONTROLS		= 5;	-- Number of search result fields.
local m_smallButtonTextureSize 	= 45;
local g_maxSmallButtons 		= 6;	-- Maximum number of small buttons per tech
local MAX_TECH_NAME_LENGTH 		= 32; 	-- Locale.Length(Locale.Lookup("TXT_KEY_TURNS"));

local SEARCH_TYPE_MAIN_TECH		= 1;
local SEARCH_TYPE_UNLOCKABLE	= 2;

local SEARCH_SCORE_HIGH			= 3;	-- Be favored in search results
local SEARCH_SCORE_LOW			= 1;	-- Less favored in search results



-- ===== Members ===================================================

local g_loadedTechButtonNum 	= 1;	-- number of tech buttons created
local g_maxTechs				= 0;

local m_miniMapControl		= nil;
local m_PopupInfo			= nil;
local g_isOpen				= false;

local g_TechLineManager 	= InstanceManager:new( "TechLineInstance", 	 	"TechLine", 		Controls.TechTreeDragPanel );
local g_BGLineManager 		= InstanceManager:new( "BackgroundLineInstance","Line", 			Controls.TechTreeDragPanel );
local g_SparkleManager 		= InstanceManager:new( "SparkleInstance",		"Sparkle", 			Controls.TechTreeDragPanel );
local g_SelectedTechManager = InstanceManager:new( "SelectedWebInstance", 	"Accoutrements",	Controls.TechTreeDragPanel );
local g_FilteredTechManager = InstanceManager:new( "SelectedWebInstance", 	"Accoutrements",	Controls.FilteredDragPanel );
local g_TechInstanceManager = InstanceManager:new( "TechWebNodeInstance", 	"TechButton", 		Controls.TechTreeDragPanel );
local g_LeafInstanceManager = InstanceManager:new( "TechWebLeafInstance", 	"TechButton", 		Controls.TechTreeDragPanel );


local g_NeedsFullRefreshOnOpen 	= false;
local g_NeedsFullRefresh 		= false;
local g_NeedsNodeArtRefresh		= true;
local m_numQueuedItems			= 0;

-- Game information
local m_playerID 			= Game.GetActivePlayer();	
local g_player 				= Players[m_playerID];
local civType 				= GameInfo.Civilizations[g_player:GetCivilizationType()].Type;
local activeTeamID 			= Game.GetActiveTeam();
local activeTeam 			= Teams[activeTeamID];

local g_radiusScalar		= 400;		-- applied to the GridRadius value set on a tech entry to produce the true screen-unit value
local g_gridRatio			= 0.6;		-- default ratio of y-axis to x-axis. Anything other than 1 will produce an elliptical look to the web
local g_lineInstances 		= {};		-- offsets are synced with table above for corresponding, actual line coordinates to draw

-- Zoom
local g_zoomWebStart		= 0;					-- What the value is of the tech web when starting zoom
local g_zoomWebEnd			= 0;					-- What the target ending value for the tech web is when zooming.
local g_zoomStart			= 0;					-- What the drag control is using for a minimum transition from one zoom to another
local g_zoomEnd 			= 0;
local g_zoomCurrent 		= 0.9;					-- a value within the range
local g_zoomLevelPercents  	= {0.5, 0.7, g_zoomCurrent};		-- what % to zoom at each level
local g_zoomLevel			= 3;					-- 1, 2, or 3 

local g_screenWidth			= -1;					-- screen resolution width
local g_screenHeight		= -1;					-- screen resolution height
local g_screenCenterH		= -1;					-- half screen width
local g_screenCenterV		= -1;					-- half screen height
local g_webExtents			= { xmin=0, ymin= 0, xmax= 0, ymax= 0 };	-- how far does diagram


local g_techButtons 		= {};					-- Collection of all the buttons
local g_currentTechButton;							-- Button of the tech currently being researched
local g_selectedArt;								-- Art for the selected node.
local g_selectedFilteredArt;						-- Art for the selected node if it's filtered out.
local g_techs;										-- cache of techs for across-frame (stream) loading
local g_animValueAfterLoad	= 0;					-- value (0 to 1) for animation in after loading
local g_updateAnim			= 0;					-- persistant value for animating (after load)

local g_techLeafToParent	= {};					-- Temporary, for storing leaf techs
local g_techParentToLeafs	= {};

local m_isEnterPressedInSearch	= false;			-- Was enter pressed while doing a search (instead of using mouse to click).

local g_filterTable			= {};					-- Contains table of filters
local g_currentFilter		= nil;					-- Filter currently being used in displaying techs.
local g_currentFilterLabel	= nil;					-- Filter text for the current filter.


-- ===========================================================================
--
--	Psuedo CTOR
--
-- ===========================================================================
function InitialSetup()

	-- Setup minimap (if a file exist)

	if ( m_miniMapControl == nil ) then
		m_miniMapControl = ContextPtr:LookUpControl( "../TechTree/TechMiniMap/TechTreeMiniMap" );
	end


	-- Setup filter area

	local pullDownButton = Controls.FilterPulldown:GetButton();	
	pullDownButton:SetText( "   "..Locale.ConvertTextKey("TXT_KEY_TECHWEB_FILTER"));	
	local pullDownLabel = pullDownButton:GetTextControl();
	pullDownLabel:SetAnchor("L,C");
	pullDownLabel:ReprocessAnchoring();


	-- Hard coded/special filters:
	table.insert( g_filterTable, { "", "TXT_KEY_TECHWEB_FILTER_NONE", nil } );

	-- Load entried into filter table from TechFilters XML data
	for row in GameInfo.TechFilters() do
		table.insert(g_filterTable, { row.IconString, row.Description, g_TechFilters[row.Type] });
	end

	for i,filterType in ipairs(g_filterTable) do

		local filterIconText = filterType[1];
		local filterLabel	 = Locale.ConvertTextKey( filterType[2] );
		local filterFunction = filterType[3];
        
		local controlTable	 = {};        
		Controls.FilterPulldown:BuildEntry( "FilterItemInstance", controlTable );

		controlTable.Button:SetText( filterLabel );
		local labelControl = controlTable.Button:GetTextControl();
		labelControl:SetAnchor("L,C");
		labelControl:ReprocessAnchoring();

		-- If a text icon exists, use it and bump the label in the button over.
		if filterIconText ~= nil and filterIconText ~= "" then
			controlTable.IconText:SetText( filterIconText );
			labelControl:SetOffsetVal(35, 0);
			filterLabel = filterIconText .." ".. filterLabel;
		else
			labelControl:SetOffsetVal(5, 0);	-- Move over ever so slightly anyway.
			filterLabel = filterLabel;
		end

		-- Use a lambda function to organize how paramters will be passed...
		controlTable.Button:RegisterCallback( Mouse.eLClick,  function() OnFilterClicked( filterLabel, filterFunction ); end );
	end
	Controls.FilterPulldown:CalculateInternals();


	DrawBackground();

	Controls.SearchResult1:RegisterCallback( Mouse.eLClick, OnSearchResult1ButtonClicked );
	Controls.SearchResult2:RegisterCallback( Mouse.eLClick, OnSearchResult2ButtonClicked );
	Controls.SearchResult3:RegisterCallback( Mouse.eLClick, OnSearchResult3ButtonClicked );
	Controls.SearchResult4:RegisterCallback( Mouse.eLClick, OnSearchResult4ButtonClicked );
	Controls.SearchResult5:RegisterCallback( Mouse.eLClick, OnSearchResult5ButtonClicked );

	-- gather info about this player's unique units and buldings
	GatherInfoAboutUniqueStuff( civType );

	g_screenWidth, g_screenHeight 	= UIManager:GetScreenSizeVal();
	g_screenCenterH = g_screenWidth / 2;
	g_screenCenterV = g_screenHeight / 2;

	-- Clear extends, rebuild when tech buttons are layed out.
	g_webExtents = { 
		xmin=-g_screenCenterH, 
		ymin=-g_screenCenterV, 
		xmax=g_screenCenterH, 
		ymax=g_screenCenterV 
	};

	BuildTechConnections();

	-- Create instance here that shows selected node.
	-- This is not in the XML but exactly here so it's created after the lines, but
	-- before the Nodes are created.  Otherwise, z-order will make the art look bad
	-- (lines going through nodes, etc.. )
	g_selectedArt = g_SelectedTechManager:GetInstance();
	g_selectedArt.LeafPieces:SetHide( true );
	g_selectedArt.FullPieces:SetHide( true );

	-- Now create one for the filtered layer, so if an item is filtered out but is selected this
	-- will be used instead of the one above.		
	g_selectedFilteredArt = g_FilteredTechManager:GetInstance();
	g_selectedFilteredArt.LeafPieces:SetHide( true );
	g_selectedFilteredArt.FullPieces:SetHide( true );
	g_selectedFilteredArt.Accoutrements:ChangeParent( Controls.FilteredDragPanel );
	
	techPediaSearchStrings = {};

	-- Load initial amount of techs displayed; stream the rest in across frames for a better user experience.
	local nodesToPreload = 8;
	if ( not (m_forceNodesNum == -1) ) then
		nodesToPreload = m_forceNodesNum;
	end
	local iTech = 0;
	g_techs = {};
	for tech in GameInfo.Technologies() do
		iTech = iTech + 1;		
		if iTech < nodesToPreload then
			AddTechNode( tech );			
			g_loadedTechButtonNum = iTech;
		end
		g_techs[iTech] = tech;
	end	
	g_maxTechs = #g_techs;
	if (m_fastDebug) then					g_maxTechs = 40; end -- debug: - faster debugging by limiting techs
	if ( not (m_forceNodesNum == -1) ) then	g_maxTechs = m_forceNodesNum; end

	-- resize the panel to fit the contents
    Controls.TechTreeDragPanel:CalculateInternalSize();
	Controls.FilteredDragPanel:CalculateInternalSize();

    -- Set callbacks from drag control
    Controls.TechTreeDragPanel:SetZoomStartCallback( OnZoomStart  );
    Controls.TechTreeDragPanel:SetZoomingCallback(   OnZoomChange );
    Controls.TechTreeDragPanel:SetDragCallback(   	 OnDragChange );
    
    -- start centered
	Controls.TechTreeDragPanel:SetDragOffset( g_screenCenterH, g_screenCenterV );
	Controls.FilteredDragPanel:SetDragOffset( g_screenCenterH, g_screenCenterV );

	-- Initial setup takes a few seconds as pieces are built
	-- Do this when game is first loading to prevent hitch the first time techweb is brought up
	ClearSearchResults();
	RefreshDisplay();
	ContextPtr:SetUpdate( OnUpdateAddTechs );

	-- Debug: Needed for hotloading or certain things (keyboard input, won't work.)
	if ( not ContextPtr:IsHidden() ) then
		g_isOpen = true;
		Events.SerialEventToggleTechWeb(false);
	end

end


-- ===========================================================================
--	Create collection of coordiantes that map lines between techs
-- ===========================================================================
function BuildTechConnections()	

	print("BuildTechConnection");

	local connectionsSeen = {};
	g_lineInstances = {};

	-- Just in case, force zoom to 1.0 while the lines are being built, as
	-- these are the "base values" that will be used again in future zooming.
	local pushZoomCurrent = g_zoomCurrent;
	g_zoomCurrent = 1.0;

	for row in GameInfo.Technology_Connections() do
		local firstTech = GameInfo.Technologies[row.FirstTech];
		local secondTech = GameInfo.Technologies[row.SecondTech];

		-- Techs must be valid and both cannot be leafs
		if ( firstTech ~= nil and secondTech ~= nil ) then

			-- Swap based on ID or if a child tech
			if (firstTech.ID > secondTech.ID) or (firstTech.LeafTech and not secondTech.LeafTech) then
				local temp = firstTech;
				firstTech = secondTech;
				secondTech = temp;
			end

			-- Now smaller ids are first in the list with the accept of children techs.

			-- One parent may have many leaves
			if ( g_techParentToLeafs[firstTech.ID] == nil) then
				g_techParentToLeafs[firstTech.ID] = {};
			end

			if (firstTech.LeafTech and secondTech.LeafTech) then
			
				-- If there is a chain of children, more likely they will need to be sorted out
				-- by traversing from parent to most leaf child.  This will have to be done later.
				print("(Maybe) TODO: Implement chained leafs; if we use them");

			elseif ( secondTech.LeafTech ) then
				
				local leafs = g_techParentToLeafs[firstTech.ID];
				table.insert( leafs, secondTech );

				-- One leaf can only have one parent
				g_techLeafToParent[secondTech.ID] = firstTech;
			
			else
			
				local hash = firstTech.ID .. '_' .. secondTech.ID;

				-- Draw a line for unseen connections
				if not connectionsSeen[hash] then
					connectionsSeen[hash] = true;
				
					-- Protect the flock (even in script... make sure DB entry has proper values!)
					if firstTech.GridRadius ~= nil and secondTech.GridRadius ~= nil then

						local startX, startY= GetTechXY( firstTech );
						local endX, endY 	= GetTechXY( secondTech );
						local lineInstance 	= g_TechLineManager:GetInstance();

						lineInstance["firstTechId"]	= firstTech.ID;
						lineInstance["secondTechId"]= secondTech.ID;
						lineInstance["sX"]			= startX;
						lineInstance["sY"]			= startY;
						lineInstance["eX"]			= endX;
						lineInstance["eY"]			= endY;
						if ( isHasLineSparkles ) then
							lineInstance["sparkle1"]	= g_SparkleManager:GetInstance();
							lineInstance["sparkle2"]	= g_SparkleManager:GetInstance();
							lineInstance["sparkle3"]	= g_SparkleManager:GetInstance();
						end
						if ( isHasLineSparklesAvailable ) then
							--print("Sparkles for: ", startX .. ", ".. startY .." to ".. endX ..", ".. endY );
							for availSparkleIdx=1,MAX_LINE_SPARKLES,1 do
								lineInstance["extra"..tostring(availSparkleIdx)]	= g_SparkleManager:GetInstance();
							end
						end

						table.insert( g_lineInstances,	lineInstance );
					else
						print("Tech "..tech.Description.." misisng <GridRadius>.");
					end
				end
			end
		end -- if nil
	end

	g_zoomCurrent = pushZoomCurrent;	-- Restore zoom to what it was.

end

-- ===========================================================================
--	Read in line values and apply new multiplier to them to redraw at a 
--	different zoom level.
-- ===========================================================================
function DrawLines()

	local i;
	local lineInstance;
	local startX;
	local startY;
	local endX;
	local endY;
	local color;
	local firstTechId;
	local secondTechId;
	local lineWidth = 2 + ( 3 * g_zoomCurrent );
	local currentResearchID = g_player:GetCurrentResearch();

	--print("Setting line width: ", lineWidth, "zoom: ".. g_zoomCurrent );  --??TRON debug

	for i,lineInstance in ipairs(g_lineInstances) do

		startX	= lineInstance["sX"] * g_zoomCurrent;
		startY	= lineInstance["sY"] * g_zoomCurrent;
		endX	= lineInstance["eX"] * g_zoomCurrent;
		endY	= lineInstance["eY"] * g_zoomCurrent;

		firstTechId 	= lineInstance["firstTechId"];
		secondTechId 	= lineInstance["secondTechId"];

		local hasFirst		= activeTeam:GetTeamTechs():HasTech( firstTechId );
		local hasSecond		= activeTeam:GetTeamTechs():HasTech( secondTechId );


		if 	(firstTechId == currentResearchID and hasSecond) or 
			(secondTechId == currentResearchID and hasFirst) then
			color = g_colorCurrent;					
		elseif hasFirst or hasSecond then
			if hasFirst and hasSecond then
				color = g_colorAlreadyResearched;
			else
				--print("Available tech: ",firstTechId.." to "..secondTechId);
				color = g_colorAvailableLine;
			end
		else
			color = g_colorNotResearched;
		end
		
		lineInstance.TechLine:SetWidth( lineWidth );		
		lineInstance.TechLine:SetColor( color );
		lineInstance.TechLine:SetStartVal(startX, startY);
		lineInstance.TechLine:SetEndVal(endX, endY);
		lineInstance.TechLine:SetHide(false);

		-- Animation on *ALL* lines
		if isHasLineSparkles then
			local speed = 0.2;
			for i=1,MAX_LINE_SPARKLES,1 do				
				local sparkleInstance = lineInstance["extraAll" .. tostring(i) ];
				sparkleInstance.Sparkle:SetBeginVal(startX, startY);
				sparkleInstance.Sparkle:SetEndVal(endX, endY);
				sparkleInstance.Sparkle:SetProgress( math.random() );
				sparkleInstance.Sparkle:SetSpeed( speed + (math.random() *0.2) );
				sparkleInstance.Sparkle:Play();
				sparkleInstance.Sparkle:SetHide(false);					
			end			
		end

		-- Animation on the available tech lines
		if isHasLineSparklesAvailable then			
			local speed = 0.2;
			for i=1,MAX_LINE_SPARKLES,1 do
				local sparkleInstance	= lineInstance["extra" .. tostring(i) ];
				if ( color == g_colorAvailableLine ) then
					sparkleInstance.Sparkle:SetBeginVal(startX, startY);
					sparkleInstance.Sparkle:SetEndVal(endX, endY);
					sparkleInstance.Sparkle:SetProgress( math.random() );
					sparkleInstance.Sparkle:SetSpeed( speed + (math.random() *0.1) );
					sparkleInstance.Sparkle:Play();
					sparkleInstance.Sparkle:SetHide(false);					
				else
					sparkleInstance.Sparkle:SetHide(true);
				end
			end			
		end
		
	end
end


-- ===========================================================================
--	New Zoom level for the tech web
--
--	dragControl,	Control hosting the tech web
--	startValue,		The value the drag control is using to start at
--	endValue,		The value the drag control is using for the ending value
--	fZoomDelta,		A positive, negative or zero number for change in
--					requested zooming since the previous frame.
-- ===========================================================================
function OnZoomStart( dragControl, startValue, endValue, delta )
	
	local newZoomLevel = g_zoomLevel;
	local oldZoomLevel = g_zoomLevel;

	-- Has player been playing with the scroll wheel?
	-- No, he hasn't
	--if delta ~= 0 then
	--	if delta < 0 then
	--		newZoomLevel = newZoomLevel - 2;	-- skip level 2 straight to 1
	--	else
	--		newZoomLevel = newZoomLevel + 2;	-- skip level 2 straight to 3
	--	end
	--end

	g_zoomWebStart	= g_zoomCurrent;
	g_zoomStart 	= startValue;
	g_zoomEnd 		= endValue;


	-- Stay within zoom level bounds
	newZoomLevel	= math.clamp( newZoomLevel, 1, #g_zoomLevelPercents);
	g_zoomLevel		= newZoomLevel;
	g_zoomWebEnd	= g_zoomLevelPercents[ g_zoomLevel ];

	-- If not the same zoom level, start fade in/out...
	if ( oldZoomLevel < newZoomLevel ) then
		LuaEvents.TechWebMiniMapFadeIn();
	elseif ( oldZoomLevel > newZoomLevel ) then
		LuaEvents.TechWebMiniMapFadeOut();
	end

	g_NeedsNodeArtRefresh = true;
	RefreshDisplay();
end


-- ===========================================================================
--	New Zoom level for the tech web
--
--	dragControl,	Control hosting the tech web
--	fZoomPercent, 	A value between the drag panel's min and max (0 and 1 
--					unless overridden)
-- ===========================================================================
function OnZoomChange( dragControl, fZoomCurrent  )

	local zoomprev = g_zoomCurrent;

	-- Map the drag control's progression in zooming into the tech-web's zoom settings
	local fPercent = fZoomCurrent / (g_zoomEnd - g_zoomStart);
	g_zoomCurrent = g_zoomWebStart + ( fPercent * ( g_zoomWebEnd - g_zoomWebStart ) );


	-- Determine the center of the screen which is the true 0,0
	local xoff, yoff 	= Controls.TechTreeDragPanel:GetDragOffsetVal();

	-- remove offset that accounts for center of screen
	xoff = xoff - g_screenCenterH;
	yoff = yoff - g_screenCenterV;

	-- determine how much the screen offset is, relative to the zoom
	local xratio = xoff / zoomprev;
	local yratio = yoff / zoomprev;

	--  compute new offset using same ratio as above but now using the new zoom
	local xnewoff = xratio * g_zoomCurrent;
	local ynewoff = yratio * g_zoomCurrent;

	-- apply offset to re-center in screen
	xnewoff = xnewoff + g_screenCenterH;
	ynewoff = ynewoff + g_screenCenterV;

--	print("OZC old: " ..str(xoff).." x "..str(yoff),"         new: "..str(xnewoff).." x "..str(ynewoff)," at ",g_zoomCurrent);
--	print("OZC xoff: " ..str(xoff), " xnewoff: "..str(xnewoff), "  ratio: "..str(xratio)," at "..g_zoomCurrent);
	
	Controls.TechTreeDragPanel:SetDragOffset( xnewoff, ynewoff );	
	
	OnDragChange( nil, xnewoff, ynewoff );	
	
	-- Perform a fast refresh only (to animate properly)...
	DrawLines();
	DrawBackground();
	
	-- Draw only the techs that have finished loading.
	local iTech = 0;
	local thisTechButton;	
	local x;
	local y;
	for tech in GameInfo.Technologies() do
		iTech = iTech + 1;
		if iTech <= g_loadedTechButtonNum then
			thisTechButton = g_techButtons[tech.ID];
			x,y = GetTechXY( tech );
			x = x - (thisTechButton.TechButton:GetSizeX() / 2);
			y = y - (thisTechButton.TechButton:GetSizeY() / 2);
			thisTechButton.TechButton:SetOffsetVal( x, y );
		end
	end	

	-- Still need to do complete refresh on selected tech to move the selected art pieces with it.
	if ( g_currentTechButton ~= nil ) then
		RefreshDisplayOfSpecificTech( g_currentTechButton.tech );
	end

	if ( m_miniMapControl ) then
		LuaEvents.TechWebMiniMapDrawNodes( g_techButtons  );
	end
end


-- ===========================================================================
--
--	eventRaiser,	Control hosting the tech web
--	x,				horizontal offset amount
--	y,				vertical offset amount
-- ===========================================================================
function OnDragChange( eventRaiser, x, y )

	-- Clamp to tree's dimensions (clamp half to max as we shift the screen over to center)

	-- Get center
	x = x - g_screenCenterH;
	y = y - g_screenCenterV;

	-- Clamp
	local EXTRA_SPACE = 150;
	local clampx = math.clamp(x, g_webExtents.xmin - EXTRA_SPACE, g_webExtents.xmax );
	local clampy = math.clamp(y, g_webExtents.ymin, g_webExtents.ymax );

	-- Put back the offset
	x = clampx + g_screenCenterH;
	y = clampy + g_screenCenterV;

	Controls.TechTreeDragPanel:SetDragOffset( x, y );
	Controls.FilteredDragPanel:SetDragOffset( x, y );

	--print( "extens: ", g_webExtents.xmin..","..g_webExtents.xmax, g_webExtents.ymin..","..g_webExtents.ymax, "   clamp: ",clampx..","..clampy,"   xy: ",x..","..y );	

	-- Tell listeners (aka: minimap) the offset...
	LuaEvents.TechWebMiniMapNewPosition( x, y );
end


-- ===========================================================================
--	Tech tree node was clicked
-- ===========================================================================
function TechSelected( eTech, iDiscover)
	--print("eTech:"..tostring(eTech));
	if eTech > -1 then		
		g_NeedsNodeArtRefresh = true;
		local isShiftHeld = UIManager:GetShift();

		if ( isShiftHeld ) then
			
			-- Shift select, only allow on the last node if already in queue.
			local queuePosition = g_player:GetQueuePosition( eTech );			
			local isLastItem	= (queuePosition == m_numQueuedItems );
			local isNotInQueue	= (queuePosition < 1);

			if  (isNotInQueue or isLastItem ) then
				-- It is either not in the current queue, or in the queue by the last item, 

				-- Normal select
				Network.SendResearch(eTech, g_player:GetNumFreeTechs(), -1, true);
				Events.AudioPlay2DSound("AS2D_INTERFACE_TECH_WEB_CONFIRM");
			else
				-- Ignore
			end
		else
			-- Normal select
			Network.SendResearch(eTech, g_player:GetNumFreeTechs(), -1, false);
			Events.AudioPlay2DSound("AS2D_INTERFACE_TECH_WEB_CONFIRM");
		end 		
		
		-- Do not call RefreshDisplay() here as it is expensive with the art refresh yet
		-- the engine will have not selected the new tech yet to be considered research.
		-- Wait for the callback from the dirty event being triggered.
   	end
end


-- ===========================================================================
--	Create a new node in the web based on a tech
--		tech, The technology the node should be representing.
-- ===========================================================================
function AddTechNode( tech )

	-- Build node type based on if this is a "full" node or a leaf node.
	local thisTechButtonInstance;
	if (tech.LeafTech) then
		thisTechButtonInstance = g_LeafInstanceManager:GetInstance();
	else
		thisTechButtonInstance = g_TechInstanceManager:GetInstance();
	end

	if thisTechButtonInstance then
		
		thisTechButtonInstance.tech = tech;						-- point back to tech (easy access)		
		g_techButtons[tech.ID] = thisTechButtonInstance;		-- store this instance off for later		
		
		-- add the input handler to this button
		thisTechButtonInstance.TechButton:SetVoid1( tech.ID ); 	-- indicates tech to add to queue
		thisTechButtonInstance.TechButton:SetVoid2( 0 ); 		-- how many free techs		
		thisTechButtonInstance.NodeName:SetVoid1( tech.ID );	-- ditto to label
		thisTechButtonInstance.NodeName:SetVoid2( 0 );

		thisTechButtonInstance.TechButton:RegisterCallback( Mouse.eRClick, GetTechPedia );

		techPediaSearchStrings[tostring(thisTechButtonInstance.TechButton)] = tech.Description;

		local scienceDisabled = Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE);
 		if (not scienceDisabled) then
			thisTechButtonInstance.TechButton	:RegisterCallback( Mouse.eLClick, TechSelected );
			thisTechButtonInstance.NodeName		:RegisterCallback( Mouse.eLClick, TechSelected );

			-- Double click closes.
			thisTechButtonInstance.TechButton	:RegisterCallback( Mouse.eLDblClick, OnClose );
			thisTechButtonInstance.NodeName		:RegisterCallback( Mouse.eLDblClick, OnClose );
		end

		thisTechButtonInstance.TechButton:SetToolTipString( GetHelpTextForTech(tech.ID) );

		if ( tech.LeafTech ) then
			thisTechButtonInstance.parent 	= g_techLeafToParent[tech.ID];
			thisTechButtonInstance.isLeaf	= true;
		else
			thisTechButtonInstance.children = g_techParentToLeafs[tech.ID];
			thisTechButtonInstance.isLeaf	= false;
		end
		
		-- update the picture
		if IconHookup( tech.PortraitIndex, 64, tech.IconAtlas, thisTechButtonInstance.TechPortrait ) then
--			thisTechButtonInstance.TechPortrait:SetHide( false  );
		else
			thisTechButtonInstance.TechPortrait:SetHide( true );
		end

		AddSmallButtons( thisTechButtonInstance );

		-- Add the tech's name and contents from "small buttons" (buildings, etc...) for search system
		
		local techName = Locale.ConvertTextKey( tech.Description );
		table.insert( g_searchTable, { word=techName, tech=tech, type=SEARCH_TYPE_MAIN_TECH } );
		
		for _,smallButtonText in pairs(g_recentlyAddedUnlocks) do
			--print("text: ", smallButtonText);
			smallButtonText = Locale.ConvertTextKey(smallButtonText);
			table.insert( g_searchTable, { word=smallButtonText, tech=tech, type=SEARCH_TYPE_UNLOCKABLE } );
		end

		-- For each button...
		--[[ Interesting but too fine a result
		for _,smallButton in pairs(g_recentlyAddedSmallIcons) do
			smallButtonText = smallButton:GetToolTipString(); 

			-- For each word in the tooltip text
			for word in string.gmatch(smallButtonText, "%S+") do
				table.insert( g_searchTable, { word=word, tech=tech, type=SEARCH_TYPE_UNLOCKABLE } );
			end
		end
		]]

		--[[ ??TRON - Darken, issue is that alphaed elements see through each other (overlap)
		-- Darken / alpha nodes farther away (in response to play tests where full tree felt busy.)		
		local amount		= 1;
		local pathLength	= g_player:FindPathLength( tech.ID );
		if ( pathLength > 0 ) then
			amount = math.clamp( 1 / (pathLength*0.02), 0.2, 1);			-- values: 0 to xxxxx map to 0.2 to 1
		end
		thisTechButtonInstance["visibleIndex"] = amount;

		local argb = RGBAValuesToABGRHex( amount, amount, amount, amount );
		thisTechButtonInstance.bg:SetColor( argb );
		thisTechButtonInstance.Tear:SetColor( argb );
		thisTechButtonInstance.NodeName:SetColor( argb );		
		thisTechButtonInstance.NodeName:SetAlpha( amount );
		thisTechButtonInstance.TechPortrait:SetAlpha( amount );
		for i=1,g_maxSmallButtons,1 do
			thisTechButtonInstance["B"..tostring(i)]:SetAlpha( amount );
		end
		if ( thisTechButtonInstance.isLeaf) then
			thisTechButtonInstance.spacer:SetColor( argb );
		end
		]]
	else
		print("ERROR: Unable to create a new tech button instance for ", tech.Description);
	end
end


-- ===========================================================================
-- On Display
-- ===========================================================================
function OnDisplay( popupInfo )
	
	if popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_TECH_TREE then
		-- Stop pop-ups from fighting for you eyes; if a new one is requested and this is up, shutdown this screen.
		if not ContextPtr:IsHidden() and popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_TUTORIAL then
			OnClose();
		end
		return;
	end

	m_PopupInfo 			= popupInfo;
	g_NeedsNodeArtRefresh 	= true;
    g_isOpen 				= true;

	Events.SerialEventToggleTechWeb(true);

    if not g_NeedsFullRefresh then
		g_NeedsFullRefresh = g_NeedsFullRefreshOnOpen;
	end
	g_NeedsFullRefreshOnOpen = false;

	if( m_PopupInfo.Data1 == 1 ) then
    	if( ContextPtr:IsHidden() == false ) then
    	    OnClose();
    	    return;
    	else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
    	end
	else
        UIManager:QueuePopup( ContextPtr, PopupPriority.TechTree );
    end
    
	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
	
	Game.SetAdvisorRecommenderTech( m_playerID );

  	RefreshDisplay();  	
end
Events.SerialEventGameMessagePopup.Add( OnDisplay );


-- ===========================================================================
-- ===========================================================================
function RefreshDisplay()
	
	g_currentTechButton = nil;

	DrawLines();

	-- Hide selected art for cases of "free" tech being granted or just completed
	-- researching tech.  If it needs to be turned on, the node that is selected
	-- will turn it on.
	g_selectedArt.Accoutrements:SetHide( true );
	g_selectedFilteredArt.Accoutrements:SetHide( true );

	m_numQueuedItems	= 0;
	local queuePosition = 0;
	for tech in GameInfo.Technologies() do
		queuePosition = g_player:GetQueuePosition( tech.ID );		
		if ( queuePosition > 0 ) then
			m_numQueuedItems = m_numQueuedItems + 1;
		end
	end

	-- Draw only the techs that have finished loading.
	local iTech = 0;
	for tech in GameInfo.Technologies() do
		iTech = iTech + 1;
		if iTech <= g_loadedTechButtonNum then
			RefreshDisplayOfSpecificTech( tech );
		end
	end	

	-- Is a filter active? If so raise the art wall for those that don't pass the filter.
	Controls.FilteredTechWall:SetHide( g_currentFilter == nil );
	
	-- Dynamically compute the size at 100% for calculations. (e.g., 6680x3340)
	if g_zoomLevel == 3 then
		if ( m_miniMapControl ) then
			LuaEvents.TechWebMiniMapSetExtents( g_webExtents );
		end
	end

	if ( m_miniMapControl ) then
		LuaEvents.TechWebMiniMapDrawNodes( g_techButtons  );
	end
	
	g_NeedsFullRefresh = false;	
	g_NeedsNodeArtRefresh = false;
end


-- ===========================================================================
--	Returns width and height from a set of extents.
-- ===========================================================================
function GetExtentDimensions( extent )
	-- protect the flock, return 0 if not an initialized (or proper) object
	if extent.xmax == nil then
		return 0,0;
	end
	local width 	= extent.xmax - extent.xmin;
	local height	= extent.ymax - extent.ymin;
	return width, height;
end



-- ===========================================================================
-- ===========================================================================
function GetTurnText( turnNumber )
	local turnText = "";
	if 	g_player:GetScience() > 0 then
		local turns = tonumber( turnNumber );
		turnText = "("..turns..")";
	end
	return turnText;
end


-- ===========================================================================
-- 	Update queue number if needed, place in proper position.
-- ===========================================================================
function RealizeTechQueue( thisTechButton, techID )
	
	local queuePosition = g_player:GetQueuePosition( techID );
	
	if queuePosition == -1 then
		thisTechButton.TechQueueLabel:SetHide( true );
	else
		thisTechButton.TechQueueLabel:SetHide( false );					
		thisTechButton.TechQueueLabel:SetText( tostring( queuePosition-1 ) );

		if ( queuePosition == m_numQueuedItems ) then
			thisTechButton.TechQueueLabel:SetColor( 0xeeffffff, 2 );	-- glow on (last item)
		else
			thisTechButton.TechQueueLabel:SetColor( 0x00000000, 2 );	-- glow off
		end


	end

	-- If a leaf, reposition based on zoom level.
	if ( thisTechButton.isLeaf ) then
		if g_zoomLevel == 3 then
			thisTechButton.TechQueueLabel:SetOffsetVal( 52, 0 );
		elseif g_zoomLevel == 2 then 
			thisTechButton.TechQueueLabel:SetOffsetVal( 0, 30 );	-- not used anymore
		else
			thisTechButton.TechQueueLabel:SetOffsetVal( 10, 35 );
		end	
	else
		if g_zoomLevel == 3 then
			thisTechButton.TechQueueLabel:SetOffsetVal( 70, 0 );
		else
			thisTechButton.TechQueueLabel:SetOffsetVal( 15, 45 );
		end
	end

end

-- ===========================================================================
--	
-- ===========================================================================
function AddSmallButtons( techButtonInstance )
	AddSmallButtonsToTechButton( techButtonInstance, techButtonInstance.tech, g_maxSmallButtons, m_smallButtonTextureSize, 1);
end


-- ===========================================================================
--	Given a tech, update it's corresponding button
-- ===========================================================================
function RefreshDisplayOfSpecificTech( tech )

	local techID 			= tech.ID;
	local thisTechButton 	= g_techButtons[techID];
  	local numFreeTechs 		= g_player:GetNumFreeTechs();
 	local researchTurnsLeft = g_player:GetResearchTurnsLeft( techID, true ); 	
 	local turnText 			= GetTurnText( researchTurnsLeft );
 	local isTechOwner 		= activeTeam:GetTeamTechs():HasTech(techID);
 	local isNowResearching	= (g_player:GetCurrentResearch() == techID);


	-- Advisor recommendations...

	-- Setup the stack to hold (any) advisor recommendations.
	-- Do this first as it may effect the amount of space for the node's name.
	thisTechButton.AdvisorStack:DestroyAllChildren();
	thisTechButton.advisorsNum = 0;
	local advisorInstance  = {};
	ContextPtr:BuildInstanceForControl( "AdvisorRecommendInstance", advisorInstance, thisTechButton.AdvisorStack );
	
	-- Create instance(s) per advisors for this tech.
	for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
		if Game.IsTechRecommended(tech.ID, iAdvisorLoop) then

			local advisorX			= -2;
			local advisorY			= -6;
			local advisorTooltip	= "";
			if ( thisTechButton.isLeaf ) then
				advisorX = 11;
			end			

			advisorInstance.EconomicRecommendation:SetHide( true );
			advisorInstance.MilitaryRecommendation:SetHide( true );
			advisorInstance.ScienceRecommendation:SetHide( true );
			advisorInstance.CultureRecommendation:SetHide( true );
			advisorInstance.GrowthRecommendation:SetHide( true );

			local pControl = nil;
			if (iAdvisorLoop	== AdvisorTypes.ADVISOR_ECONOMIC) then			
				advisorToolTip	= Locale.ConvertTextKey( "TXT_KEY_TECH_CHOOSER_ADVISOR_RECOMMENDATION_ECONOMIC");
				pControl		= advisorInstance.EconomicRecommendation;
			elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_MILITARY) then
				advisorToolTip	= Locale.ConvertTextKey( "TXT_KEY_TECH_CHOOSER_ADVISOR_RECOMMENDATION_MILITARY");
				pControl		= advisorInstance.MilitaryRecommendation;
			elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_SCIENCE) then
				advisorToolTip	= Locale.ConvertTextKey( "TXT_KEY_TECH_CHOOSER_ADVISOR_RECOMMENDATION_SCIENCE");
				pControl		= advisorInstance.ScienceRecommendation;
			elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_FOREIGN) then	-- ADVISOR_CULTURE?
				advisorToolTip	= Locale.ConvertTextKey( "TXT_KEY_TECH_CHOOSER_ADVISOR_RECOMMENDATION_FOREIGN");
				pControl		= advisorInstance.CultureRecommendation;
			elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_GROWTH) then	-- Does not exist?
				advisorToolTip	= Locale.ConvertTextKey( "TXT_KEY_TECH_CHOOSER_ADVISOR_RECOMMENDATION_GROWTH");
				pControl		= advisorInstance.GrowthRecommendation;
			end

			if (pControl) then
				pControl:SetHide( false );
				thisTechButton.advisorsNum  = thisTechButton.advisorsNum + 1;	-- track amt for other code
			end
		
			--advisorInstance.AdvisorMarking:ChangeParent( thisTechButton.bg );
			advisorInstance.AdvisorMarking:SetOffsetVal( 0, -2 );
			--advisorInstance.AdvisorBackground:SetOffsetVal( advisorX, advisorY );
			advisorInstance.AdvisorMarking:SetToolTipString( advisorTooltip );
			
		end
	end


	-- Update the name of this node's instance
	local techName = Locale.ConvertTextKey( tech.Description );
	techName = Locale.TruncateString(techName, MAX_TECH_NAME_LENGTH, true);
	if ( m_showTechIDsDebug ) then
		techName = tostring(techID) .. " " .. techName;
	end
	if ( not isTechOwner ) then
		techName = Locale.ToUpper(techName) .. " ".. turnText;
	else
		techName = Locale.ToUpper(techName);
	end
	--TruncateStringWithTooltip( thisTechButton.NodeName, 
	thisTechButton.NodeName	:SetText( techName );


	-- Update queue & tooltip regions.	
	if ( m_numQueuedItems > 0 ) then
		
		local progressAmount	= nil;
		local queuePosition		= g_player:GetQueuePosition( tech.ID );
		if queuePosition ~= 1 then 
			-- If queue is active, then only show spill-over tech for that one.
			-- But still show progress we have past that (ex. from Expeditions)
			local overflowResearch = g_player:GetOverflowResearch();
			local researchTowardsThis = g_player:GetResearchProgress(tech.ID);
			progressAmount = researchTowardsThis - overflowResearch;
			if (progressAmount < 0) then
				progressAmount = 0;
			end
		end

		thisTechButton.TechButton:SetToolTipString( GetHelpTextForTech(techID, progressAmount) );
		thisTechButton.NodeName:SetToolTipString( GetHelpTextForTech(techID, progressAmount) );
		
	else
		thisTechButton.TechButton:SetToolTipString( GetHelpTextForTech(techID), nil );
		thisTechButton.NodeName:SetToolTipString( GetHelpTextForTech(techID), nil );
	end


 	-- Rebuild the small buttons if needed
 	if (g_NeedsFullRefresh) then
		AddSmallButtons( thisTechButton )
 	end
 	
 	local scienceDisabled = Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE);
 	
	if(not scienceDisabled) then
		thisTechButton.TechButton:SetVoid1( techID ); -- indicates tech to add to queue
		thisTechButton.TechButton:SetVoid2( numFreeTechs ); -- how many free techs
		AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, techID, numFreeTechs, Mouse.eLClick, TechSelected );
		AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, techID, numFreeTechs, Mouse.eLDblClick, OnClose );
	end

 	if isTechOwner then -- the player (or more accurately his team) has already researched this one
		ShowTechState( thisTechButton, "AlreadyResearched");
		if(not scienceDisabled) then
			thisTechButton.TechQueueLabel:SetHide( true );
			thisTechButton.TechButton:SetVoid2( 0 ); -- num free techs
			thisTechButton.TechButton:SetVoid1( -1 ); -- indicates tech is invalid
			AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, -1, 0, Mouse.eLClick, TechSelected );
			AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, -1, 0, Mouse.eLDblClick, OnClose );
 		end
 		
 	elseif isNowResearching then -- the player is currently researching this one
				
		RealizeTechQueue( thisTechButton, techID );
		if g_player:GetNumFreeTechs() > 0 then
			
			ShowTechState( thisTechButton, "Free");		-- over-write tech queue #
			thisTechButton.TechQueueLabel:SetText( freeString );
			thisTechButton.TechQueueLabel:SetHide( false );

			-- Keep selected node's art hidden while choosing a free tech.

		else
			g_currentTechButton = thisTechButton;
 			ShowTechState( thisTechButton, "CurrentlyResearching");
			thisTechButton.TechQueueLabel:SetHide( true );

	 		-- Determine values for the memeter
			local researchProgressPercent 		= 0;
			local researchProgressPlusThisTurnPercent = 0;
			local researchTurnsLeft 			= g_player:GetResearchTurnsLeft(techID, true);
			local currentResearchProgress 		= g_player:GetResearchProgress(techID);
			local researchNeeded 				= g_player:GetResearchCost(techID);
			local researchPerTurn 				= g_player:GetScience();
			local currentResearchPlusThisTurn 	= currentResearchProgress + researchPerTurn;		
			researchProgressPercent 			= currentResearchProgress / researchNeeded;
			researchProgressPlusThisTurnPercent = currentResearchPlusThisTurn / researchNeeded;		
			if (researchProgressPlusThisTurnPercent > 1) then
				researchProgressPlusThisTurnPercent = 1
			end

			currentResearchPlusThisTurn = currentResearchPlusThisTurn * 0.1;

			-- Set art, etc... based on if it's a leaf or not.

			local x,y 		= GetTechXY( tech );
			local width 	= thisTechButton.TechButton:GetSizeX();
			local height 	= thisTechButton.TechButton:GetSizeY();
			local accoutrementx;
			local accoutrementy;
			local meterx;
			local metery;
			local meterHeight;

			-- Set the selected art based on if a filter is active for this.
			local selectedArt = g_selectedArt;
			if ( g_currentFilter ~= nil ) then
				-- In filter mode, is this tech in the filter?
				if not g_currentFilter( tech ) then
					-- Current tech isn't in the filter, use the filtered version of the art.
					selectedArt = g_selectedFilteredArt;					
				end
			end
			selectedArt.Accoutrements:SetHide( false );


			if ( thisTechButton.isLeaf ) then
				
				-- Show selecetd leaf art				
				selectedArt.FullPieces:SetHide( true );
				selectedArt.LeafPieces:SetHide( false );

				if ( g_zoomCurrent >= g_zoomLevelPercents[3] ) then

					selectedArt.LeafPieces:SetHide( false );

					accoutrementx 	= x - 34;
					accoutrementy 	= y - 30;
					meterx 			= width + thisTechButton.bg:GetSizeX() - 11;
					metery  		= 1;
					meterHeight 	= selectedArt.AmountLeaf:GetSizeY();

					-- Since art is interlaced, ensure offsets are even
					local nextHeight= math.floor(-meterHeight + (meterHeight * researchProgressPlusThisTurnPercent));
					local thisHeight= math.floor(-meterHeight + (meterHeight * researchProgressPercent));
					if ( (nextHeight) % 2 == 0) then nextHeight = nextHeight - 1; end
					if ( (thisHeight) % 2 == 1) then thisHeight = thisHeight - 1; end

					selectedArt.Accoutrements	:SetOffsetVal( accoutrementx, accoutrementy );
					selectedArt.BorderLeaf		:SetHide( false );
					selectedArt.MeterLeaf		:SetOffsetVal( meterx, metery );
					selectedArt.NewAmountLeaf	:SetTextureOffsetVal( 0, nextHeight);
					selectedArt.AmountLeaf 		:SetTextureOffsetVal( 0, thisHeight);
				else
					-- Zoom level isn't 3 (full) so keep extra leaf selected data hidden.
					selectedArt.LeafPieces:SetHide( true );
				end
	
			else

				-- Show non-leaf stuff for a selected piece.
				selectedArt.FullPieces:SetHide( false );
				selectedArt.LeafPieces:SetHide( true );

				if ( g_zoomCurrent >= g_zoomLevelPercents[2] ) then

					selectedArt.LeafPieces:SetHide( true );
					
					accoutrementx 	= x - 46;
					accoutrementy 	= y - 36;
					meterx 			= width + thisTechButton.bg:GetSizeX() - 10;
					metery  		= 0;
					meterHeight 	= selectedArt.AmountFull:GetSizeY();

					-- Since art is interlaced, ensure offsets are even
					local nextHeight= math.floor(-meterHeight + (meterHeight * researchProgressPlusThisTurnPercent));
					local thisHeight= math.floor(-meterHeight + (meterHeight * researchProgressPercent));
					if ( (nextHeight) % 2 == 0) then nextHeight = nextHeight - 1; end
					if ( (thisHeight) % 2 == 1) then thisHeight = thisHeight - 1; end

					selectedArt.Accoutrements	:SetOffsetVal( accoutrementx, accoutrementy );
					selectedArt.BorderFull		:SetHide( false );
					selectedArt.MeterFull		:SetOffsetVal( meterx, metery );
					selectedArt.NewAmountFull	:SetTextureOffsetVal( 0, nextHeight);
					selectedArt.AmountFull 		:SetTextureOffsetVal( 0, thisHeight);
				else
					-- Zoom is tiny so even full nodes don't show extra selected art goodness...
					selectedArt.FullPieces:SetHide( true );
				end			
			end
		end

 	elseif (g_player:CanResearch( techID ) and not scienceDisabled) then -- the player research this one right now if he wants
 		-- deal with free 		
		RealizeTechQueue( thisTechButton, techID );
		if g_player:GetNumFreeTechs() > 0 then
 			ShowTechState( thisTechButton, "Free");		-- over-write tech queue #
			-- update queue number to say "FREE"
			thisTechButton.TechQueueLabel:SetText( freeString );
			thisTechButton.TechQueueLabel:SetHide( false );
		else
			ShowTechState( thisTechButton, "Available");			
		end

 	elseif (not g_player:CanEverResearch( techID ) or g_player:GetNumFreeTechs() > 0) then
  		ShowTechState( thisTechButton, "Locked");
		-- have queue number say "LOCKED"
		thisTechButton.TechQueueLabel:SetText( "" );
		thisTechButton.TechQueueLabel:SetHide( false );
		if(not scienceDisabled) then
			thisTechButton.TechButton:SetVoid1( -1 ); 
			thisTechButton.TechButton:SetVoid2( 0 ); -- num free techs
			AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, -1, 0, Mouse.eLClick, TechSelected );
			AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, -1, 0, Mouse.eLDblClick, OnClose );
 		end
 	else -- currently unavailable
 		ShowTechState( thisTechButton, "Unavailable");		
		RealizeTechQueue( thisTechButton, techID );
		if g_player:GetNumFreeTechs() > 0 then
			thisTechButton.TechButton:SetVoid1( -1 ); 
			AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, -1, 0, Mouse.eLClick, function() end );
		else
			if(not scienceDisabled) then
				thisTechButton.TechButton:SetVoid1( tech.ID );
				AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, techID, numFreeTechs, Mouse.eLClick, TechSelected );
				AddCallbackToSmallButtons( thisTechButton, g_maxSmallButtons, techID, numFreeTechs, Mouse.eLDblClick, OnClose );
			end
		end
	end

	-- Place the node in teh web.
	local x,y = GetTechXY( tech );
	x = x - (thisTechButton.TechButton:GetSizeX() / 2);
	y = y - (thisTechButton.TechButton:GetSizeY() / 2);
	thisTechButton.TechButton:SetOffsetVal( x, y );
	

	-- Update extends of web if this node pushes it out some.
	local TECH_NODE_WIDTH = 250;
	if (x - TECH_NODE_WIDTH) < g_webExtents.xmin then
		g_webExtents.xmin = (x - TECH_NODE_WIDTH);
	elseif x > g_webExtents.xmax then
		g_webExtents.xmax = x;
	end

	if y < g_webExtents.ymin then
		g_webExtents.ymin = y;
	elseif y > g_webExtents.ymax then
		g_webExtents.ymax = y;
	end


	-- Filter, if one is set.
	if g_currentFilter ~= nil then
		if g_currentFilter( tech ) then
			thisTechButton.TechButton:ChangeParent( Controls.TechTreeDragPanel );
		else
			thisTechButton.TechButton:ChangeParent( Controls.FilteredDragPanel );
		end
	else
		thisTechButton.TechButton:ChangeParent( Controls.TechTreeDragPanel );
	end

end


-- ===========================================================================
--	Obtain the screen space X and Y coordiantes for a tech
--	ARGS:	tech object
--	RETURNS: x,y
-- ===========================================================================
function GetTechXY( tech )
	--print("GetTechXY ", tech.Description );

	if tech.LeafTech then

		local button 		= g_techButtons[ tech.ID ];

		-- Only dynamically place children if guaranteed all are loaded.
		if ( g_loadedTechButtonNum >= g_maxTechs ) then
			
			button.TechButton:SetHide( false );			
			button.TechButton:SetAlpha( g_animValueAfterLoad );

			-- Obtain the parent to this leaf
			local parentTech 	= button.parent;
			local parentButton 	= g_techButtons[ parentTech.ID ];

			-- Loop through the children of the parent, when it eventually finds
			-- this child... do all the maths and return.
			for i,child in ipairs(parentButton.children) do
				if (child.ID == tech.ID) then

					local parentx,parenty 	= parentButton.TechButton:GetOffsetVal();
					local localx			= 38;
					local localy 			= 95;  
					local degrees 			= 90; 
					local zoom2 			= g_zoomLevelPercents[2];
					local zoom3 			= g_zoomLevelPercents[3];

					-- Set rotation amount based if horizonal, vertical, or animating inbetween; all based on zoom level
					if ( g_zoomCurrent < zoom3 and g_zoomCurrent > zoom2 ) then

						degrees = (90 * InverseLerp(zoom2, zoom3, g_zoomCurrent) );

					elseif ( g_zoomCurrent <= zoom2) then

						degrees = 0;

					end

					-- Pivoting around the first leaf tech, only leafs past the 1st one need to be adjusted.
					if (i > 1 ) then 
						local addLittleExtraX  = (( 1.0 - g_zoomCurrent ) * (15 * i)) - (((90-degrees)/90) * 10);
						if ( degrees == 0) then
							addLittleExtraX = addLittleExtraX + 4;
						end
						localx, localy = PolarToCartesian( (i-1) * 55, degrees );
						localx = localx + 38 + addLittleExtraX;						
						localy = localy + 94;
					end

					-- lerp between zoom1 position and zoom row position
					if ( g_zoomCurrent < zoom2) then
						local percent = g_zoomLevelPercents[1] / g_zoomCurrent;
						localx = Lerp( localx, 37 + (i* 53), percent );
						localy = Lerp( localy, 25, percent );
					end

					-- To animate in when first loading
					localx = localx * g_animValueAfterLoad;
					localy = localy * g_animValueAfterLoad;

					return parentx + localx, parenty + localy;
				end
			end
			print("WARNING: A leaf tech couldn't be dynamically positioned against it's parent.", tech.Type, parentTech.Type );
		else
			-- Start transparent, animate in (via fade) when loaded.
			button.TechButton:SetAlpha( 0 );
			button.TechButton:SetHide( true );
		end
	end


	if tech.GridRadius == 0 then
		return 0,0;
	end

	local x,y = PolarToRatioCartesian( tech.GridRadius * g_radiusScalar, tech.GridDegrees, g_gridRatio );
	return x * g_zoomCurrent, y * g_zoomCurrent;
end


-- ===========================================================================
--	ARGS:	Tech button to show
--			Name of the state of the button
-- ===========================================================================
function ShowTechState( thisTechButton, techStateString )

	-- Store last tech state for minimap to read.
	thisTechButton["techStateString"] = techStateString;

	if ( not g_NeedsNodeArtRefresh ) then
		return;
	end
	
	thisTechButton.TechPortrait	:SetColor( g_iconColors[techStateString] );
	thisTechButton.NodeName		:SetColor( g_textColors[techStateString] );

	-- Increase background size to match text width
	local spaceUsedByAdvisors = (32 * thisTechButton.advisorsNum);
	local extraSpaceNeeded	  = 40;
	if ( thisTechButton.NodeName:GetSizeX() > (thisTechButton.bg:GetSizeX() - (extraSpaceNeeded + spaceUsedByAdvisors)) ) then
		thisTechButton.bg:SetSizeVal( thisTechButton.NodeName:GetSizeX() + (extraSpaceNeeded + spaceUsedByAdvisors), thisTechButton.bg:GetSizeY() );
	end

	-- Is it a full node or leaf node?
	if thisTechButton.tech.LeafTech then

		-- Leaf
		for i=1,g_maxSmallButtons do
			thisTechButton["B"..i]:SetHide( g_zoomLevel < 3 );
			thisTechButton["B"..i]:SetAlpha( 0.6 );
			--thisTechButton["B"..i]:SetColor( g_smallIconColors[techStateString] );
		end	

		thisTechButton.Tear 		:SetTextureOffsetVal ( g_textureBgLeaf[techStateString].u, g_textureBgLeaf[techStateString].v );
				
		if ( g_zoomLevel > 2 ) then 		-- full size
			thisTechButton.TechButton		:SetSizeVal(50, 50);
			thisTechButton.spacer			:SetHide(false);
			thisTechButton.bg 				:SetHide(false);
			thisTechButton.Tear 			:SetHide(false);
			thisTechButton.NodeName 		:SetHide(false);

		elseif ( g_zoomLevel == 2 ) then 	-- collapsed (could remove, not utilized anymore)
			thisTechButton.TechButton		:SetSizeVal(50, 50);
			thisTechButton.spacer			:SetHide(true);
			thisTechButton.bg 				:SetHide(true);
			thisTechButton.Tear 			:SetHide(false);
			thisTechButton.NodeName 		:SetHide(true);

		elseif ( g_zoomLevel < 2 ) then 	-- smallest
			thisTechButton.TechButton		:SetSizeVal(50, 50);
			thisTechButton.spacer			:SetHide(true);
			thisTechButton.bg 				:SetHide(true);
			thisTechButton.Tear 			:SetHide(false);
			thisTechButton.NodeName 		:SetHide(true);

		end

	else			

		for i=1,g_maxSmallButtons do
			thisTechButton["B"..i]:SetHide( g_zoomLevel < 2 );
			--thisTechButton["B"..i]:SetColor( g_smallIconColors[techStateString] );
			if techStateString == "AlreadyResearched" or techStateString == "CurrentlyResearching" then
				thisTechButton["B"..i]:SetAlpha( 1.0 );
			else
				thisTechButton["B"..i]:SetAlpha( 0.6 );
			end
			
		end	

		thisTechButton.Tear 		:SetTextureOffsetVal ( g_textureBgFull[techStateString].u, g_textureBgFull[techStateString].v );

		if ( g_zoomLevel > 2 ) then 		-- full size
			thisTechButton.bg 				:SetHide(false);
			thisTechButton.NodeName 		:SetHide(false);
			thisTechButton.NodeHolder		:SetHide(true);

		elseif ( g_zoomLevel == 2 ) then 	-- collapsed
			thisTechButton.bg 				:SetHide(false);
			thisTechButton.NodeName 		:SetHide(false);
			thisTechButton.NodeHolder		:SetHide(false);

		elseif ( g_zoomLevel < 2 ) then 	-- smallest
			thisTechButton.bg 				:SetHide(true);
			thisTechButton.NodeName 		:SetHide(true);
			thisTechButton.NodeHolder		:SetHide(true);
		end
	end
end



-- ===========================================================================
-- ===========================================================================
function OnClose ()
	UIManager:DequeuePopup( ContextPtr );
    Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_TECH_TREE, 0);
	Events.SerialEventToggleTechWeb(false);
    g_isOpen = false;	
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

-- ===========================================================================
-- ===========================================================================
function OnZoom1ButtonClicked ()
	g_zoomLevel 			= 1;
	g_zoomWebEnd 			= g_zoomLevelPercents[ 1 ];	
	Controls.TechTreeDragPanel:SetZoomChange( 0 );
end
--Controls.Zoom1Button:RegisterCallback( Mouse.eLClick, OnZoom1ButtonClicked );

-- ===========================================================================
-- ===========================================================================
function OnZoom2ButtonClicked ()
	g_zoomLevel 			= 2;
	g_zoomWebEnd 			= g_zoomLevelPercents[ 2 ];	
	Controls.TechTreeDragPanel:SetZoomChange( 0 );
end
--Controls.Zoom2Button:RegisterCallback( Mouse.eLClick, OnZoom2ButtonClicked );

-- ===========================================================================
-- ===========================================================================
function OnZoom3ButtonClicked ()	
	g_zoomLevel 			= 3;
	g_zoomWebEnd 			= g_zoomLevelPercents[ 3 ];
	Controls.TechTreeDragPanel:SetZoomChange( 0 );
end
--Controls.Zoom3Button:RegisterCallback( Mouse.eLClick, OnZoom3ButtonClicked );

-- ===========================================================================
--	Input Processing
-- ===========================================================================
function InputHandler( uiMsg, wParam, lParam )
    if g_isOpen and uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
		end
    elseif g_isOpen and uiMsg == 2 and Keys.VK_RETURN then	-- 2 = CHAR message
		if Controls.SearchEditBox:HasFocus() then
			-- HACK: Since the general input cascade happens after the editbox
			--		 fires back, call for the search to occur again, but mark
			--		 a global so it will pull from the first item.
			m_isEnterPressedInSearch = true;
			OnKeywordSearchHandler( "" );
		end
		return true;
	elseif g_isOpen and uiMsg == MouseEvents.MButtonUp then
		OnClose();
	end

    return false;    
end
ContextPtr:SetInputHandler( InputHandler );


function ShowHideHandler( bIsHide, bIsInit )
    if( not bIsInit ) then		
        if( not bIsHide ) then
			-- show
        	UI.incTurnTimerSemaphore();
        else
			-- hide
        	UI.decTurnTimerSemaphore();
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

local g_PerPlayerTechFilterSettings = {}

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnTechTreeActivePlayerChanged( iActivePlayer, iPrevActivePlayer )

	-- print("OnTechTreeActivePlayerChanged", iActivePlayer, iPrevActivePlayer );

	-- Save/Restore the tech web filters.
	if (iPrevActivePlayer ~= -1) then
		if (g_PerPlayerTechFilterSettings[ iPrevActivePlayer + 1 ] == nil) then
			g_PerPlayerTechFilterSettings[ iPrevActivePlayer + 1 ] = {};
		end

		g_PerPlayerTechFilterSettings[ iPrevActivePlayer + 1 ].filterFunc = g_currentFilter;
		g_PerPlayerTechFilterSettings[ iPrevActivePlayer + 1 ].filterLabel = g_currentFilterLabel;
	end

	if (iActivePlayer ~= -1 ) then
		if (g_PerPlayerTechFilterSettings[ iActivePlayer + 1] ~= nil) then
			g_currentFilter = g_PerPlayerTechFilterSettings[ iActivePlayer + 1].filterFunc;
			g_currentFilterLabel = g_PerPlayerTechFilterSettings[ iActivePlayer + 1].filterLabel;
		else
			g_currentFilter = nil;
			g_currentFilterLabel = nil;
		end

		RefreshFilterDisplay();
	end

	m_playerID 	= Game.GetActivePlayer();	
	g_player 	= Players[m_playerID];
	civType 	= GameInfo.Civilizations[g_player:GetCivilizationType()].Type;
	activeTeamID= Game.GetActiveTeam();
	activeTeam 	= Teams[activeTeamID];	
	
	-- Rebuild some tables	
	GatherInfoAboutUniqueStuff( civType );	
	
	-- So some extra stuff gets re-built on the refresh call
	if not g_isOpen then
		g_NeedsFullRefreshOnOpen = true;	
	else
		g_NeedsFullRefresh = true;
	end
	
	-- Close it, so the next player does not have to.
	OnClose();
end
Events.GameplaySetActivePlayer.Add(OnTechTreeActivePlayerChanged);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnEventResearchDirty()
	if (g_isOpen) then
		g_NeedsNodeArtRefresh = true;
		RefreshDisplay();
	end
end
Events.SerialEventResearchDirty.Add(OnEventResearchDirty);


-- ===========================================================================
--	Adds a few techs at a time; essentially streaming them into existance
--	as a single allocation in LUA for the whole web takes quite a while.
--	fDTime, delta time frame previous frame.
-- ===========================================================================
function OnUpdateAddTechs( fDTime )

	g_loadedTechButtonNum = g_loadedTechButtonNum + 1;

	local tech = g_techs[g_loadedTechButtonNum];
	
	AddTechNode( tech );
	RefreshDisplayOfSpecificTech( tech );

	Controls.LoadingBarBacking:SetHide( false );
	Controls.LoadingBar:SetSizeX( g_screenWidth * (g_loadedTechButtonNum / g_maxTechs) );

	if g_loadedTechButtonNum >= g_maxTechs then
		ContextPtr:SetUpdate( OnUpdateAnimateAfterLoad );  	-- animate in
		g_NeedsNodeArtRefresh = true;						-- initialize art in leaf node.
		g_selectedArt.Accoutrements:SetHide( false );	   	-- show current selection
	end
	
end

-- ===========================================================================
-- ===========================================================================
function OnUpdateAnimateAfterLoad( fDTime )

	g_animValueAfterLoad = g_animValueAfterLoad + (fDTime * 7);
	--print("anim:", g_animValueAfterLoad,fDTime);
	
	if ( g_animValueAfterLoad >= 1 ) then
		Controls.LoadingBarBacking:SetHide( true );
		g_animValueAfterLoad = 1;
		ContextPtr:SetUpdate( OnUpdate );  --turn off callback, empty function
	end

	RefreshDisplay();

	-- Set initial minimap positions and show.
	if ( m_miniMapControl ) then
		local xoff, yoff 	= Controls.TechTreeDragPanel:GetDragOffsetVal();
		LuaEvents.TechWebMiniMapNewPosition( xoff, yoff );
		m_miniMapControl:SetHide( false );
	end
end

-- ===========================================================================
-- ===========================================================================
function OnUpdate( fDTime )
	g_updateAnim = g_updateAnim + fDTime;
	if ( g_updateAnim > 1000000 ) then
		g_updateAnim = g_updateAnim - 1000000;		
	end
	-- ContextPtr:SetUpdate( function( misc ) end );  --turn off callback, empty function
end

-- ===========================================================================
--	Take a search string and based on the entry, determine a match score
--	RETURNS: A score for the match, higher score the closer to front.
-- ===========================================================================
function GetPotentialSearchMatch( searchString, searchEntry )
	local word = searchEntry["word"];

	if string.len(searchString) > string.len( word ) then
		return -1;
	end

	-- Escape out minus sign before doing a match call.
	searchString = string.gsub( searchString, "[%-%*%.%~%$%^%?]", " " );		-- Looks ineffective but it's doing work: param 2 is using % as an escape character, param 3 is a literal!
	local status, match = pcall( string.match, Locale.ToLower(word), Locale.ToLower(searchString) );

	if status then
		if match == nil then
			return -1;
		else				
			local score = string.len( match );		
		
			-- adjust score with importance
			if ( searchEntry["type"] == SEARCH_TYPE_MAIN_TECH ) then
				score = score + SEARCH_SCORE_HIGH;
			elseif ( searchEntry["type"] == SEARCH_TYPE_UNLOCKABLE ) then
				score = score + SEARCH_SCORE_LOW;
			end

			-- adjust score to be higher if pattern is found closer to front
			local num = string.find( Locale.ToLower(word), match );
			if ( num ~= nil and (10-num) > 0) then
				num = (10-num) * 4;
			else
				num = 0;
			end
		
			score = score + num;
			return score;
		end
	end

	return -1;
end


-- ===========================================================================
-- ===========================================================================
function ClearSearchResults()
	Controls.SearchResult1:SetText( "" );
	Controls.SearchResult2:SetText( "" );
	Controls.SearchResult3:SetText( "" );
	Controls.SearchResult4:SetText( "" );
	Controls.SearchResult5:SetText( "" );

	Controls.SearchResult1["tech"] = nil;
	Controls.SearchResult2["tech"] = nil;
	Controls.SearchResult3["tech"] = nil;
	Controls.SearchResult4["tech"] = nil;
	Controls.SearchResult5["tech"] = nil;
end


-- ===========================================================================
--	Pan the web to the specified tech.
--	tech,		The tech to go to.
-- ===========================================================================
function PanToTech( tech )

	-- Clear out any searches (as they may have caused the pan)	
	ClearSearchResults();

	-- Fill search with where it's panning...
	Controls.SearchEditBox:SetText( Locale.ConvertTextKey( tech.Description) );
	Controls.SearchEditBox:SetColor( 0x80808080 );

	local sx,sy = Controls.TechTreeDragPanel:GetDragOffsetVal();
	local x,y	= GetTechXY( tech );

	Controls.PanControl:RegisterAnimCallback( OnPanTech );
	Controls.PanControl:SetBeginVal(sx, sy);
	Controls.PanControl:SetEndVal( -x + g_screenCenterH, -y + g_screenCenterV );
	Controls.PanControl:SetToBeginning();
	Controls.PanControl:Play();
end


-- ===========================================================================
--	Callback per-frame for slide animation.
-- ===========================================================================
function OnPanTech()
	local x,y = Controls.PanControl:GetOffsetVal();
	Controls.TechTreeDragPanel:SetDragOffset( x,y );
	Controls.FilteredDragPanel:SetDragOffset( x,y );
	LuaEvents.TechWebMiniMapNewPosition( x, y );
end


-- ===========================================================================
--	px, % 0 to 1
--	py, % 0 to 1
-- ===========================================================================
function OnPanToPercent( px, py )

	local x = (-px * (g_webExtents.xmax - g_webExtents.xmin)) - g_webExtents.xmin;
	local y = (-py * (g_webExtents.ymax - g_webExtents.ymin)) - g_webExtents.ymin;

	x = x + g_screenCenterH;
	y = y + g_screenCenterV;

	Controls.TechTreeDragPanel:SetDragOffset( x,y );
	Controls.FilteredDragPanel:SetDragOffset( x,y );

	LuaEvents.TechWebMiniMapNewPosition( x, y );
end
LuaEvents.TechTreePanToPercent.Add( OnPanToPercent );


-- ===========================================================================
-- ===========================================================================
function OnSearchResult1ButtonClicked() PanToTech( Controls.SearchResult1["tech"] ); end
function OnSearchResult2ButtonClicked() PanToTech( Controls.SearchResult2["tech"] ); end
function OnSearchResult3ButtonClicked() PanToTech( Controls.SearchResult3["tech"] ); end
function OnSearchResult4ButtonClicked() PanToTech( Controls.SearchResult4["tech"] ); end
function OnSearchResult5ButtonClicked() PanToTech( Controls.SearchResult5["tech"] ); end


-- ===========================================================================
-- 	Search Input processing
-- ===========================================================================
function OnSearchInputHandler( charJustPressed, searchString )	

	ClearSearchResults();	

	-- Nothing to search?  Then done...
	if string.len(searchString) < 1 then
		return;
	end
	

	-- Obtain words that have a match
	local results 	= {};
	local strength 	= 0;
	for i,searchEntry in ipairs(g_searchTable) do
		strength = GetPotentialSearchMatch( searchString, searchEntry );
		if strength > 0 then
			table.insert( results, { strength=strength, searchEntry=searchEntry } );
		end
	end

	-- Sort by strength
	local ResultsSort = function(a, b)
		return a.strength > b.strength;
	end
	table.sort( results, ResultsSort );

	local searchControl;
	local searchControlName;
	for i,resultEntry in ipairs(results) do

		if i > NUM_SEARCH_CONTROLS then	
			break;
		end	

		searchControlName = "SearchResult"..str(i);
		searchControl = Controls[searchControlName];

		local text = resultEntry["searchEntry"]["word"];
		if ( resultEntry["searchEntry"]["type"] == SEARCH_TYPE_UNLOCKABLE ) then
			local techDescription = Locale.ConvertTextKey( resultEntry["searchEntry"]["tech"].Description);
			text = text .." (" .. techDescription .. ")";
		end

		searchControl:SetText( text );
		searchControl["tech"] = resultEntry["searchEntry"]["tech"];

		--print("Sorted: ", i, resultEntry["searchEntry"]["word"] );
	end

end
Controls.SearchEditBox:RegisterCharCallback( OnSearchInputHandler );


-- ===========================================================================
--	Enter was pressed or editbox lost focus due to click outside it.
-- ===========================================================================
function OnKeywordSearchHandler( searchString )	
	-- BONUS: Common commands to effect the tech web other than searchincloseg
	--		  NOTE: English only... translations? localization look ups?
	if ( searchString == "close" or searchString == "exit") then
		local defaultSearchlabel = Locale.Lookup("TXT_KEY_TECHWEB_SEARCH");
		Controls.SearchEditBox:SetText(defaultSearchlabel);
		Controls.SearchEditBox:SetColor( 0x80808080 );
		OnClose();		-- Fake a close button clicked
		return;
	end
	
	-- BONUS: Common geek society search strings which translate to "home" node, the center of the techweb 
	if ( searchString == "~" or searchString == "localhost" or searchString == "127.0.0.1" ) then
		searchString = Locale.ConvertTextKey( g_techs[1].Description );
	end

	if searchString=="" then
		ClearSearchResults();
		local defaultSearchlabel = Locale.Lookup("TXT_KEY_TECHWEB_SEARCH");
		Controls.SearchEditBox:SetText(defaultSearchlabel);
		Controls.SearchEditBox:SetColor( 0x80808080 );
	else
		local mostLikelySearchText = Controls.SearchResult1:GetText();
		if ( m_isEnterPressedInSearch and Controls.SearchResult1["tech"] ~= nil and mostLikelySearchText ~= "" ) then
			PanToTech( Controls.SearchResult1["tech"] );
		end
	end

	m_isEnterPressedInSearch = false;
end
Controls.SearchEditBox:RegisterCommitCallback( OnKeywordSearchHandler );



-- ===========================================================================
function OnSearchHasFocus()
	Controls.SearchEditBox:SetText( "" );
	Controls.SearchEditBox:SetColor( 0xffffffff );
	Controls.SearchEditBox:ReprocessAnchoring();
end
Controls.SearchEditBox:RegisterHasFocusCallback( OnSearchHasFocus );


-- ===========================================================================
-- Debug helper
-- ===========================================================================
function str( val )
	return tostring( math.floor(val));
end


-- ===========================================================================
-- Update the Filter text with the current label.
-- ===========================================================================
function RefreshFilterDisplay()
	local pullDownButton = Controls.FilterPulldown:GetButton();	
	if ( g_currentFilter == nil ) then
		pullDownButton:SetText( "  "..Locale.ConvertTextKey("TXT_KEY_TECHWEB_FILTER"));
	else
		pullDownButton:SetText( "  "..Locale.ConvertTextKey(g_currentFilterLabel));
	end
end

-- ===========================================================================
--	filterLabel,	Readable lable of the current filter.
--	filterFunc,		The funciton filter to apply to each node as it's built,
--					nil will reset the filters to none.
-- ===========================================================================
function OnFilterClicked( filterLabel, filterFunc )		
	g_currentFilter=filterFunc;
	g_currentFilterLabel=filterLabel;

	RefreshFilterDisplay();
	RefreshDisplay();
end


-- ===========================================================================
--	Programmatically Draw an oval via line segments
-- ===========================================================================
function DrawBackgroundOval( distance, color )

	local start = 0;
	local step	= 360 / ( 50 + ((math.ceil(distance/100) * 4) ));

	local x,y;
	local ox,oy = PolarToRatioCartesian( distance, start, g_gridRatio );
	for degrees = start+step,361, step do
		x, y = PolarToRatioCartesian( distance, degrees, g_gridRatio );

		local lineInstance 	= g_BGLineManager:GetInstance();
		lineInstance.Line:SetWidth( 2 + ((distance/2500) * 16) );
		lineInstance.Line:SetColor( color );
		lineInstance.Line:SetStartVal( x, y);
		lineInstance.Line:SetEndVal( ox, oy );
		lineInstance.Line:SetHide(false);		
		
		-- Save old points for ending of line for next loop...
		ox = x;
		oy = y;
	end

end


-- ===========================================================================
--	Programmatically draw the background.
-- ===========================================================================
function DrawBackground()

	local MAX_BOUNDS	= 1900;
	local MAX_SPARKLES	= 200;

	g_BGLineManager:ResetInstances();

	-- Draw multiple rings pointing to center
	for distance=100,MAX_BOUNDS,370 do
		--DrawBackgroundOval( distance-5, 0x03f0c0b0 );	-- style it, slightly smaller ring with each ring
		DrawBackgroundOval( distance * g_zoomCurrent, 0x14f0c0b0 );
	end

	-- Experimental starfield, looks a little too cheesy right now; may repurpose for other background animation.
	-- ??TRON When on, many dots align despite progress being random.
	if ( isLookLikeWindows95 ) then
		g_SparkleManager:ResetInstances();
		for i=1,MAX_SPARKLES,1 do
			local instance	= g_SparkleManager:GetInstance();
			local degrees	= math.random(1,360);
			local endx,endy = PolarToRatioCartesian( MAX_BOUNDS, degrees, g_gridRatio );
			instance.Sparkle:SetBeginVal(0, 0);
			instance.Sparkle:SetEndVal(endx, endy);
			instance.Sparkle:SetSpeed( 0.1 );
			instance.Sparkle:SetProgress( math.random() );
			instance.Sparkle:Play();
		end
	end
end


-- ===========================================================================
--	??TRON For debug (when hotloading after making changes)...
-- ===========================================================================
function OnTechWebResendMiniMapData()
	print("TechMiniMap.OnTechWebResendMiniMapData()");
	LuaEvents.TechWebMiniMapSetExtents( g_webExtents );
	LuaEvents.TechWebMiniMapDrawNodes( g_techButtons );
end
LuaEvents.TechWebResendMiniMapData.Add( OnTechWebResendMiniMapData );


-- One time initialization
InitialSetup();
