local Reader = if script then require(script.Parent.Parent.Core.Reader) else require("../Core/Reader")
local Opcodes = if script then require(script.Parent.Parent.Core.Opcodes) else require("../Core/Opcodes")
local Parser = if script then require(script.Parent.Parent.Core.Parser) else require("../Core/Parser")
local Decompiler = if script then require(script.Parent.Parent.Core.Decompiler) else require("../Core/Decompiler")
local Layout = if script then require(script.Parent.Parent.UI.Layout) else require("../UI/Layout")
local GestureState = if script then require(script.Parent.Parent.UI.GestureState) else require("../UI/GestureState")

local SelfTest={}

local function expect(condition,message) if not condition then error(message or "expectation failed",2) end end

function SelfTest.run(rawFixture)
	local reader=Reader.new(string.char(0x78,0x56,0x34,0x12,0xfe,0xff,0xff,0xff))
	expect(reader:u32()==0x12345678,"Reader:u32")
	expect(reader:i32()==-2,"Reader:i32")

	local loadN=bit32.bor(Opcodes.ByName.LOADN,bit32.lshift(3,8),bit32.lshift(42,16))
	local decoded=Opcodes.decode({loadN})
	expect(decoded[1].name=="LOADN" and decoded[1].a==3 and decoded[1].d==42,"opcode LOADN")

	local layoutConfig={
		ScreenPadding=12,InitialSize={X={Offset=980},Y={Offset=620}},MinimumEditorWidth=280,
		MobileBreakpointWidth=760,MobileBreakpointHeight=520,StackBreakpointWidth=620,
		MobileExplorerRatio=.34,ExplorerWidth=330,MobileExplorerMin=180,
	}
	local screenshot=Layout.window(1024,461,layoutConfig,980,620,true)
	expect(screenshot.width==980 and screenshot.height==437,"layout da captura mobile")
	local split=Layout.panels(screenshot.width,screenshot.height,layoutConfig,true)
	expect(split.compact and not split.narrow and split.explorerWidth==333,"layout landscape dividido")
	local portrait=Layout.window(412,915,layoutConfig,980,620,true)
	local stacked=Layout.panels(portrait.width,portrait.height,layoutConfig,true)
	expect(stacked.narrow and stacked.explorerWidth==portrait.width and not stacked.rightVisible,"layout portrait empilhado")

	local gestures=GestureState.new(9)
	local tap=gestures:Begin("touch-1",10,10)
	expect(gestures:Release(tap)=="click","toque rápido deve clicar")
	local hold=gestures:Begin("touch-2",20,20)
	expect(gestures:Hold(hold),"long press deve disparar")
	expect(gestures:Release(hold)=="held","long press não pode virar clique")
	local scroll=gestures:Begin("touch-3",30,30)
	expect(gestures:Move(scroll,30,45)=="cancelled","movimento deve cancelar long press")
	expect(not gestures:Hold(scroll),"scroll cancelado não pode abrir menu")
	expect(gestures:Release(scroll)=="cancelled","scroll não pode selecionar item")
	local removed=gestures:Begin("touch-4",40,40)
	gestures:Cancel()
	expect(not gestures:Hold(removed),"refresh deve invalidar timer pendente")

	if rawFixture then
		local chunk=Parser.parse(rawFixture)
		local source=Decompiler.decompile(chunk)
		expect(source:find("DeGOAT Client",1,true)~=nil,"decompile header")
		return source
	end
	return true
end

return SelfTest
