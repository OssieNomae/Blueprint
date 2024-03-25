--!strict
--[[
	License: Licensed under the MIT License
	Version: 1.0.0
	Authors:
		OssieNomae - 2024

	Blueprint: Simple Roblox Studio plugin to automatically replace the default script source with a template
	
	--------------------------------
	
	Select a "Script" Instance in the Roblox Studio "Explorer" with the desired source template -> go to "Plugins" Page from the TopBar -> Blueprint -> "Set" Button -> Done!
	
--]]

----- Loaded Services -----
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")

----- Private Variables -----
local Toolbar = plugin:CreateToolbar("Blueprint") :: PluginToolbar
local SetBlueprint = Toolbar:CreateButton("Blueprint Set", "Select a Script and Press to Set as a Blueprint", "rbxassetid://16867772594", "Set") :: PluginToolbarButton
local DebugBlueprint = Toolbar:CreateButton("Blueprint Debug", "Toggle Debug for Blueprint", "rbxassetid://16865274680", "Debug") :: PluginToolbarButton

local Blueprint_Debug: boolean = false

----- Private Methods -----
local function ReplaceBlueprintSource()
	local Selected = Selection:Get()
	if #Selected < 1 then
		error(`Blueprint: Select a "Script" as source input`)
	end
	
	local Script = Selected[1] :: Script
	if not Script then 
		error(`Blueprint: Select a "Script" as source input`)
	end
	
	local ScriptSource = Script.Source
	if not ScriptSource then
		error(`Blueprint: Invalid Script Source`)
	end
	
	plugin:SetSetting("BlueprintSource", ScriptSource)
	print("Blueprint: Successfully set blueprint source as ->", {ScriptSource})
end

local function IsNewScript(Script: Script, Source: string): boolean
	if Script:IsA("LocalScript") or Script:IsA("Script") then
		if Source == 'print("Hello world!")\n' then
			return true
		end
	elseif Script:IsA("ModuleScript") then
		if Source == 'local module = {}\n\nreturn module\n' then 
			return true
		end
	end
	
	return false
end
	
----- Connections -----
ScriptEditorService.TextDocumentDidOpen:Connect(function(ScriptDocument)
	local Script = ScriptDocument:GetScript()
	if not Script then return end

	if not IsNewScript(Script, Script.Source) then return end

	local BlueprintSource = plugin:GetSetting("BlueprintSource")
	if not BlueprintSource then return end

	ScriptEditorService:UpdateSourceAsync(Script, function()
		return BlueprintSource
	end)

	if Blueprint_Debug then
		print(`Blueprint Debug: Successfully replaced {Script:GetFullName()} with a blueprint`)
	end
end)

SetBlueprint.Click:Connect(function()
	ReplaceBlueprintSource()
end)

DebugBlueprint.Click:Connect(function()
	Blueprint_Debug = not Blueprint_Debug
	DebugBlueprint:SetActive(Blueprint_Debug)
end)
DebugBlueprint:SetActive(Blueprint_Debug)