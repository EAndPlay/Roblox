local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterGui = game:GetService('StarterGui')
local UserInputService = game:GetService('UserInputService')
local IsUpdate = true
local UpdateTime = 2
local MessageColor = Color3.fromRGB(0, 255, 255)

local RobberyConsts : table = require(ReplicatedStorage.Game.Robbery.RobberyConsts)
local RobberiesEnum : table = RobberyConsts.ENUM_ROBBERY
local ClosedState : number = RobberyConsts.ENUM_STATE.CLOSED
local StatesFolder : Array<IntValue> = ReplicatedStorage.RobberyState

local function SendMessage(text: string) : nil
  StarterGui:SetCore('ChatMakeSystemMessage',
  {
    Text = '[Script]: ' .. text,
    Color = MessageColor
  })
end

local Robberies = {
  Bank = {},
  Jewelry = {},
  Museum = {},
  Power_Plant = {},
  Train_Passenger = {},
  Train_Cargo = {},
  Cargo_Ship = {},
  Cargo_Plane = {},
  Store_Gas = {},
  Store_Donut = {},
  Money_Truck = {},
  Tomb = {},
  Casino = {
    OnOpen = function()
      local password = ''
      for _, obj in next, workspace.Casino.RobberyDoor.Codes:GetChildren() do
        for _, code in next, obj:GetChildren() do
          local text = code.SurfaceGui.TextLabel.Text
          if text ~= nil and text ~= '' then
            password = password .. text
          end
        end

        if password == '' then continue end
        SendMessage('Casino Code = ' .. password)
        password = ''
        break
      end
    end
  }
}

local function IsOpened(id: number) : boolean
  local state : number = StatesFolder[id].Value
  return state < ClosedState
end

for name, _ in next, Robberies do
  local rob = Robberies[name]
  local id = RobberiesEnum[tostring(name):upper()]
  rob.Id = id
  rob.Opened = false--IsOpened(id)
end

task.spawn(function()
  local casino = Robberies.Casino
  while IsUpdate do
    local current = IsOpened(casino.Id)
    if casino.Opened ~= current then
      casino.Opened = current
      if current then
        casino.OnOpen()
      end
    end
    task.wait(UpdateTime)
  end
end)

-- -- Update all
-- task.spawn(function()
--   while IsUpdate do
--     for _, rob in next, Robberies do
--       local opened = IsOpened(rob.Id)
--       if rob.Opened ~= opened then
--         rob.Opened = opened
--         local onOpen = rob.OnOpen
--         if opened and onOpen then
--           onOpen()
--         end
--       end
--     end
--     task.wait(UpdateTime)
--   end
-- end)

local DestroyHook = nil
DestroyHook = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
  if input.UserInputType ~= Enum.UserInputType.Keyboard or gameProcessedEvent then return end

  if input.KeyCode == Enum.KeyCode.RightControl then
    DestroyHook:Disconnect()
    DestroyHook = nil
    IsUpdate = false
    Robberies = nil
    MessageColor = nil
    RobberyConsts = nil
    RobberiesEnum = nil
    StatesFolder = nil
  end
end)