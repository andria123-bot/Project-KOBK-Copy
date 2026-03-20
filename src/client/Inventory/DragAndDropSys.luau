local DragAndDropSys = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

DragAndDropSys.dragging = {
	active = false,
	fromSlot = nil,
	clone = nil,
}

return DragAndDropSys