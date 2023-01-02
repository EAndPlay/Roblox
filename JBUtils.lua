local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local List = {}
List.new = function()
  local self = {}
  self.OnDelete = nil

  local Items = {}

  local function Insert(object) : nil
    table.insert(Items, object)
  end

  function self.Add(object: ({string} | Instance), childs: (table | string)?, recursive: boolean?)
    recursive = recursive or false
    local objType = typeof(object)
    if objType ~= 'table' then
      if childs then
        if typeof(childs) == 'table' then
          for _, v in next, childs do
            Insert(object:FindFirstChild(v, recursive))
          end
        else
          Insert(object:FindFirstChild(childs, recursive))
        end
      else
        Insert(object)
      end
    else
      if childs then
        warn('WTF, childs not null with table of objects!')
        return
      end
      for _, v in next, object do
        Insert(v)
      end
    end
  end

  function self.Clear()
    for i, v in Items do
      if v then
        if self.OnDelete then
          self.OnDelete(v)
        end
        Items[i] = nil
      end
    end
  end

  return self
end

local GC = List.new()
GC.OnDelete = function(v)
  v:Destroy()
end

local Names = {
  Museum = {
    'Lights', 'Doors'
  },
  Bank = {
    'Lasers', 'Door'
  },
  Casino = {
    'Lasers', 'LasersMoving', 'CamerasMoving', 'OpenIndicators', 'VaultLaserControl', 'LaserCarousel'
  },
  BarbedWire = {
    'TouchInterest'
  },
  Cell = {
    'Door'
  },
  MilitaryIsland = {
    'MilitaryLasers'
  }
}

local IsClearing = true
local ClearTime = 0.25
local nowhere = Vector3.new(0, -10000, 0)

local function EmptyFunction(...)end

local function DeleteDoor(door)
  local model = door:FindFirstChild('Model')
  if model then
    local part = Instance.new('Part')
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = false
    part.Parent = workspace
    model.PrimaryPart = part
    part.Position = nowhere
    for _, k in next, model:GetChildren() do
      GC.Add(k)
    end
  end

  -- local touch = door:FindFirstChild('Touch')
  -- if touch then
  --   if touch:IsA('Part') then
  --     touch.Position = nowhere
  --   elseif touch:IsA('ObjectValue') then
  --     touch.Value.Position = nowhere
  --   end
  -- end
end

local function MakeInvisible(object)
  for _, v in next, object:GetDescendants() do
    if v:IsA('Part') then
      v.Transparency = 1
      v.CanCollide = false
    end
  end
end

local function ClearTrains(trains: table)
  for _, v: Instance in next, trains:GetChildren() do
    local name : string = v.Name
    if name:sub(0, 6) == 'BoxCar' then
      local model : Model = v.Model
      local function Destroy(childName: string)
        local child = model:FindFirstChild(childName)
        if not child then return end

        for _, k: Instance in next, child:GetChildren() do
          if k.Name == 'BarbedWire' then
            GC.Add(k)
          end
        end
      end
      Destroy('Box')
      Destroy('Rob')
    end
  end
end

for _, v: Instance in next, workspace:GetChildren() do
  local childName = v.Name
  if childName == 'SlideDoor' or childName == 'SwingDoor' then
    DeleteDoor(v)
  end

  if childName == 'Model' then
    for _, k in next, v:GetDescendants() do
      local desName = k.Name
      if desName == 'BarbedWire' or desName == 'Wood' then
        GC.Add(k)
      end
    end
    local box = v:FindFirstChild('Box')
    if box then
      box:Destroy()
      GC.Add(v, 'Box')
      GC.Add(v, 'Part')
    end

  elseif childName == 'Jewelrys' then
    for _, k in next, v:GetDescendants() do
      local desName = k.Name
      if desName == 'LaserFloor' or desName == 'Cameras' or desName == 'Lasers' or desName == 'BarbedWire' or desName == 'SwingDoor' then
        GC.Add(k)
      elseif desName == 'TouchInterest' and k:FindFirstAncestor('Floors') then
        GC.Add(k.Parent)
      end
    end
    local floors = v:FindFirstChild('Floors', true)
    if floors then
      for _, floor in next, floors:GetChildren() do
        for _, g in next, floor:GetDescendants() do
          if g:FindFirstChild('TouchInterest') then
            GC.Add(g)
          elseif g.Name == 'TouchInterest' and g.Parent then
            GC.Add(g.Parent)
          end
        end
      end
    end

  elseif childName == 'Banks' then
    GC.Add(v, Names.Bank, true)
    --local waterBank = v:FindFirstChild('Underwater', true)
    for _, i in next, v:GetChildren() do
      for _, k in next, i:GetChildren() do
        if k.Name == 'SwingDoor' then
          DeleteDoor(k)
        end
      end
    end

  elseif childName == 'Museum' then
    GC.Add(v, Names.Museum)

  elseif childName == 'PowerPlant' then
    for _, k in next, v:GetChildren() do
      local name = k.Name
      if name == 'Core' then
        local powerWire = k:FindFirstChild('PowerWire')
        if powerWire then
          local touchInterest = powerWire:FindFirstChild('TouchInterest')
          GC.Add(touchInterest)
        end
      elseif name == 'BarbedWire' or name == 'Piston' then
        GC.Add(k)
      end
    end

  elseif childName == 'RobberyTomb' then
    for _, k in next, v:GetDescendants() do
      local name = k.Name
      if (name == 'TouchInterest' and k:FindFirstAncestor('Tile')) or name == 'Planks' then
        GC.Add(k)
      else
        local parent = k.Parent
        if parent then
          local parentName = parent.Name
          if name == 'Spikes' and parentName ~= 'SpikeRoom' then
            k.Transparency = 1
          elseif parentName == 'Darts' then
            k.Position = Vector3.new(0, -10000, 0)
          end
        end
      end
    end

  elseif childName == 'Casino' then
    GC.Add(v, Names.Casino)
    for _, k in next, v:GetChildren() do
      if k.Name == 'SwingDoor' then
        DeleteDoor(k)
      end
    end

  elseif childName == 'MilitaryIsland' then
    GC.Add(v, Names.MilitaryIsland)

  elseif childName == 'MilitaryBase' then
    -- local gun = v:FindFirstChild('MachineGun', true)
    -- if gun then gun:Destroy() end
    -- gun = v:FindFirstChild('MachineGun', true)
    -- if gun then GC.Add(gun) end

    for _, k in next, v.Gates:GetDescendants() do
      if k.Name == 'BarbedWire' then
        GC.Add(k)
      end
    end

  elseif childName == 'SecretBaseCriminal' or childName == 'SecretBasePolice' then
    if v:FindFirstChild('Lift') or v:FindFirstChild('Doors') then
      MakeInvisible(v)
    end

  elseif childName == 'L18n' then
    GC.Add(v)

  elseif childName == 'BarbedWire' then
    GC.Add(v, Names.BarbedWire)
    v.Position = nowhere

  elseif childName == 'Trains' then
    ClearTrains(v)

  elseif childName == 'Cell' then
    GC.Add(v, Names.Cell)
  end
end
GC.Clear()

local JewelryHook = workspace.Jewelrys.DescendantAdded:Connect(function(des: Instance)
  task.delay(1, function()
    local objName = des.Name
    if objName == 'LaserFloor' or objName == 'Cameras' or objName == 'Lasers' or objName == 'BarbedWire' or objName == 'SwingDoor' then
      GC.Add(des)
    elseif objName == 'TouchInterest' and des:FindFirstAncestor('Floors') then
      GC.Add(des.Parent)
    end
  end)
end)

local BankHook = workspace.Banks.DescendantAdded:Connect(function(des: Instance)
  task.delay(1.5, function()
    local objName = des.Name
    if objName == 'Lasers' or objName == 'Door' or objName == 'SwingDoor' then
      GC.Add(des)
    end
  end)
end)

local WorkspaceHook = workspace.ChildAdded:Connect(function(child: Instance)
  task.delay(.1, function()
    if child.Name == 'Model' then
      local box = child:FindFirstChild('Box')
      if box then
        box:Destroy()
        GC.Add(child, {'Box', 'Part'})
      end
    end
  end)
end)

local Modules = {}
--local Replaces = {}
local GameFolder : Folder = ReplicatedStorage.Game
local GuardFolder : Folder = ReplicatedStorage.GuardNPC
Modules.CircleActions = require(ReplicatedStorage.Module.UI).CircleAction.Specs
Modules.NPC = require(ReplicatedStorage.NPC.NPC)
Modules.GuardNPC = {
  Consts = require(GuardFolder.GuardNPCConsts),
  Shared = require(GuardFolder.GuardNPCShared)
}
Modules.PowerPlant = {
  Piston = require(GameFolder.Robbery.PowerPlant.Piston)
}
Modules.CargoShip = require(GameFolder.Robbery.CargoShip.CargoShip)
Modules.PlayerUtils = require(GameFolder.PlayerUtils)
Modules.MilitaryTurrets = {
  Utils = require(GameFolder.MilitaryTurret.MilitaryTurretUtils)
}

coroutine.wrap(function()
  while IsClearing do
    for i, _ in next, Modules.CircleActions do
      local circle : table = Modules.CircleActions[i]
      local isTimed : boolean = circle.Timed
      local name : string = circle.Name
      local tag : Instance = circle.Tag
      if isTimed and (not tag or (tag.Name ~= 'Drop')) and (not name or (name ~= 'Rob')) then
        circle.Duration = 0
        circle.Timed = false
      end
    end
    task.wait(0.25)
  end
end)()

Modules.NPC.GetTarget = EmptyFunction
-- Modules.NPC.Move = function()
--   Modules.NPC:Destroy()
-- end
Modules.GuardNPC.Consts.MAX_SHOOT_DIST = 0
Modules.GuardNPC.Shared.canSeeTarget = function()
  return false
end
Modules.PowerPlant.Piston.SlamPlayer = EmptyFunction
Modules.CargoShip.SetTurretSeek = EmptyFunction

if not _G.isPointInTag then
  _G.isPointInTag = Modules.PlayerUtils.isPointInTag
end
--Replaces.isPointInTag = Modules.PlayerUtils.isPointInTag
Modules.PlayerUtils.isPointInTag = function(vector, key)
  if key == 'NoFallDamage' or key == 'NoRagdoll' then
    return true
  else
    return _G.isPointInTag(vector, key)
  end
end

--getupvalues(Modules.PlayerUtils.init, 1).playerHasItem = function() return true end
Modules.PlayerUtils.hasKey = function()
  return true
end

Modules.MilitaryTurrets.Utils.getNearestNonPolice = function()
  return nil
end

for _, v in next, ReplicatedStorage.Game.ItemConfig:GetChildren() do
  local weapon = require(v)
  if weapon.CamShakeMagnitude then
    weapon.CamShakeMagnitude = 0
  end
  weapon = nil
end

ClearTrains(ReplicatedStorage.Resource.TrainCars)

local function Destroy()
  JewelryHook:Disconnect()
  JewelryHook = nil
  BankHook:Disconnect()
  BankHook = nil
  WorkspaceHook:Disconnect()
  WorkspaceHook = nil
  IsClearing = nil
  ClearTime = nil
  List = nil
  GC = nil
  Names = nil
  nowhere = nil
  Modules = nil
  UserInputService = nil
  ReplicatedStorage = nil
end

local DestroyHook = nil
DestroyHook = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
  if input.UserInputType ~= Enum.UserInputType.Keyboard or gameProcessedEvent then return end

  if input.KeyCode == Enum.KeyCode.RightControl then
    DestroyHook:Disconnect()
    DestroyHook = nil
    Destroy()
  end
end)

task.spawn(function()
  while IsClearing do
    GC.Clear()
    task.wait(ClearTime)
  end
end)
--with name 'Cameras' and 'Lasers' and 'Door2' and 'Floors' and 'BarbedWire' and 'SlideDoor' and ('Door' from 'Cell')