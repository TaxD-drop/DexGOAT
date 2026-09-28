local Layout = {}

function Layout.window(viewportWidth,viewportHeight,config,currentWidth,currentHeight,resetSize)
	local padding=config.ScreenPadding
	local maximumWidth=math.max(1,viewportWidth-padding*2)
	local maximumHeight=math.max(1,viewportHeight-padding*2)
	local desiredWidth=resetSize and config.InitialSize.X.Offset or currentWidth
	local desiredHeight=resetSize and config.InitialSize.Y.Offset or currentHeight
	if desiredWidth<=1 then desiredWidth=config.InitialSize.X.Offset end
	if desiredHeight<=1 then desiredHeight=config.InitialSize.Y.Offset end
	return {
		width=math.min(desiredWidth,maximumWidth),
		height=math.min(desiredHeight,maximumHeight),
		x=viewportWidth/2,y=viewportHeight/2,
		maximumWidth=maximumWidth,maximumHeight=maximumHeight,
	}
end

function Layout.panels(width,height,config,explorerVisible)
	local compact=width<=config.MobileBreakpointWidth or height<=config.MobileBreakpointHeight
	local narrow=width<=config.StackBreakpointWidth
	local maximumExplorer=math.max(0,width-config.MinimumEditorWidth)
	local requested=compact and math.floor(width*config.MobileExplorerRatio) or config.ExplorerWidth
	local minimumExplorer=math.min(config.MobileExplorerMin,maximumExplorer)
	local explorerWidth=narrow and width or math.clamp(requested,minimumExplorer,maximumExplorer)
	if not explorerVisible then explorerWidth=0 end
	return {
		compact=compact,narrow=narrow,explorerWidth=explorerWidth,
		leftVisible=explorerVisible,
		dividerVisible=explorerVisible and not narrow,
		rightVisible=not (narrow and explorerVisible),
		rightOffset=explorerVisible and not narrow and explorerWidth+1 or 0,
		rightInset=explorerVisible and not narrow and -explorerWidth-1 or 0,
	}
end

return Layout
