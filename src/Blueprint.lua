--[[
	License: Licensed under the MIT License
	Version: 1.1.0
	Github: https://github.com/OssieNomae/Blueprint
	Authors:
		OssieNomae - 2024

	Blueprint: Simple Roblox Studio plugin to automatically replace the default script source with a template
	
	--------------------------------
	
	Select a "Script" Instance in the Roblox Studio "Explorer" with the desired source template -> go to "Plugins" Page from the TopBar -> Blueprint -> "Set" Button -> Done!
	
--]]
--!strict

----- Loaded Services -----
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")

----- Private Variables -----
local Toolbar = plugin:CreateToolbar("Blueprint") :: PluginToolbar
local SetBlueprint = Toolbar:CreateButton("Blueprint Set", "Select a Script and Press to Set as a Blueprint", "rbxassetid://16867772594", "Set") :: PluginToolbarButton

----- Private Methods -----
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

local function ReplaceBlueprintSource()
	local Selected = Selection:Get()
	if #Selected < 1 then
		error(`Blueprint: Select a "Script" as source input`)
	end
	
	local Script = Selected[1] :: Script
	if not Script or (not Script:IsA("Script") and not Script:IsA("ModuleScript") and not Script:IsA("LocalScript")) then 
		error(`Blueprint: Select a "Script" object as source input`)
	end
	
	local ScriptSource = Script.Source
	if not ScriptSource then
		error(`Blueprint: Invalid script source`)
	end
	
	plugin:SetSetting(`{Script.ClassName}-BlueprintSource`, ScriptSource)
	print(`Blueprint: Successfully set {Script.ClassName} blueprint source as ->`, {ScriptSource})
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
	ReplaceBlueprintSource()
end)