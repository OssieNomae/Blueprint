--!strict
--[[
	License: Licensed under the MIT License
	Version: 1.2.2
	Github: https://github.com/OssieNomae/Blueprint
	Authors:
		OssieNomae - 2024

	Blueprint: Simple Roblox Studio plugin to automatically replace the default script source with a template
	
	--------------------------------
	
	Modify the desired script source template -> go to "Plugins" Page from the TopBar -> Blueprint -> "Open Blueprint" Button -> Select Script Type from the dropdown menu -> Modify the created blueprint script -> Close the blueprint script tab to save!
	
--]]

----- Module / Class / Object Table -----------
local DEFAULT_SCRIPT_SOURCE = 'print("Hello world!")\n'
local DEFAULT_MODULE_SOURCE = 'local module = {}\n\nreturn module\n'

----- Loaded Services -----
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")
local StudioService = game:GetService("StudioService")

----- Types -----
type ScriptType = "Script" | "LocalScript" | "ModuleScript"

----- Private Variables -----
local Toolbar = plugin:CreateToolbar("Blueprint") :: PluginToolbar
local SetBlueprint = Toolbar:CreateButton("Blueprint Main", "Open a Script Blueprint", "rbxassetid://16867772594", "Open Blueprint") :: PluginToolbarButton

local PluginMenu = plugin:CreatePluginMenu("Blueprint Selection Menu", "Blueprint Selection Menu")
PluginMenu:AddNewAction("Blueprint Script", "Script", StudioService:GetClassIcon("Script").Image)
PluginMenu:AddNewAction("Blueprint LocalScript", "LocalScript", StudioService:GetClassIcon("LocalScript").Image)
PluginMenu:AddNewAction("Blueprint ModuleScript", "ModuleScript", StudioService:GetClassIcon("ModuleScript").Image)


----- Private Methods -----
local function IsNewScript(Script: Script, Source: string): boolean
	if Script:IsA("LocalScript") or Script:IsA("Script") then
		if Source == DEFAULT_SCRIPT_SOURCE then
			return true
		end
	elseif Script:IsA("ModuleScript") then
		if Source == DEFAULT_MODULE_SOURCE then 
			return true
		end
	end
	
	return false
end

local function CreateScript(Source: string, ScriptType: ScriptType): Script?
	local Script = Instance.new(ScriptType)
	Script.Parent = workspace

	ScriptEditorService:UpdateSourceAsync(Script, function()
		return Source
	end)

	local Success, _ = ScriptEditorService:OpenScriptDocumentAsync(Script)
	if not Success then
		Script:Destroy()
		return
	end

	return Script
end

local function ReplaceBlueprintSource(ScriptType: ScriptType, ScriptSource: string)
	if not ScriptType then return end
	if not ScriptSource then return end
	
	plugin:SetSetting(`{ScriptType}-BlueprintSource`, ScriptSource)
	print(`Blueprint: Successfully set {ScriptType} blueprint source as ->`, {ScriptSource})
end

local function ReplaceSource(ScriptDocument)
	local Script = ScriptDocument:GetScript()
	if not Script then return end

	if not IsNewScript(Script, Script.Source) then return end

	local BlueprintSource = plugin:GetSetting(`{Script.ClassName}-BlueprintSource`)
	if not BlueprintSource then return end
	
	-- Source replace verification for Team Create
	local ChangedConnection
	local CloseConnection
	
	local function Disconnect()
		ChangedConnection:Disconnect()
		CloseConnection:Disconnect()
	end
	
	ChangedConnection = ScriptEditorService.TextDocumentDidChange:Connect(function(ChangedScript, Changes)
		if ChangedScript ~= ScriptDocument then
			return
		end
		
		local Script = ScriptDocument:GetScript()
		if not Script then return end
		
		Disconnect()
		
		if Script.Source ~= BlueprintSource then
			ReplaceSource(ScriptDocument) -- Recursive
		end
	end)
	
	CloseConnection = ScriptEditorService.TextDocumentDidClose:Connect(function(ClosedScript)
		if ClosedScript ~= ScriptDocument then
			return
		end
		
		Disconnect()
	end)
	
	-- Actually replace the script
	ScriptEditorService:UpdateSourceAsync(Script, function()
		return BlueprintSource
	end)
end
	
----- Connections -----
ScriptEditorService.TextDocumentDidOpen:Connect(function(ScriptDocument)
	ReplaceSource(ScriptDocument)
end)

SetBlueprint.Click:Connect(function()
	task.defer(function()
		SetBlueprint:SetActive(false)
	end)
	
	local Selected = PluginMenu:ShowAsync() :: PluginAction & {Text: ScriptType}
	if not Selected then return end
	
	local ScriptDocument = CreateScript(plugin:GetSetting(`{Selected.Text}-BlueprintSource`), Selected.Text)
	if not ScriptDocument then return end
	
	ScriptDocument.Name = `{string.upper(Selected.Text)} BLUEPRINT (TEMPORARY INSTANCE)`
	
	local CloseConnection
	CloseConnection = ScriptEditorService.TextDocumentDidClose:Connect(function(ClosedScript)
		if ScriptDocument.Parent == nil then -- incase blueprint instance gets destroyed???
			CloseConnection:Disconnect()
			return
		end
		
		if not string.find(ClosedScript:GetFullName(), ScriptDocument:GetFullName(), 1, true) then -- :GetScript() breaks in team create???
			return
		end
		
		CloseConnection:Disconnect()
		
		local ScriptSource = ScriptDocument.Source
		ScriptDocument:Destroy()
		
		ReplaceBlueprintSource(Selected.Text, ScriptSource)
	end)
end)

----- Initialize -----
local function InitializeBlueprint(ScriptType: ScriptType, ScriptSource: string)
	local SavedSource = plugin:GetSetting(`{ScriptType}-BlueprintSource`)
	if SavedSource then return end
	
	plugin:SetSetting(`{ScriptType}-BlueprintSource`, ScriptSource)
end

InitializeBlueprint("Script", DEFAULT_SCRIPT_SOURCE)
InitializeBlueprint("LocalScript", DEFAULT_SCRIPT_SOURCE)
InitializeBlueprint("ModuleScript", DEFAULT_MODULE_SOURCE)