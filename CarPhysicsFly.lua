local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

local Player = game:GetService('Players').LocalPlayer
local Camera = workspace.CurrentCamera
local Direction = {
	Forward = 0,
	Backward = 0,
	Left = 0,
	Right = 0,
	Up = 0,
	Down = 0
}

local InCar = false
local PrimaryPart : BasePart
local FlyEnabled = false
local Speed = 300
local BodyPosition : BodyPosition = nil
local BodyGyro : BodyGyro = nil

local BigVector = Vector3.new(math.huge, math.huge, math.huge)

local Keys = {
  Forward = Enum.KeyCode.W,
  Backward = Enum.KeyCode.S,
  Right = Enum.KeyCode.D,
  Left = Enum.KeyCode.A,
  Up = Enum.KeyCode.LeftShift,
  Down = Enum.KeyCode.LeftControl,
	Toggle = Enum.KeyCode.N
}

local BodyPositionOrigin = Instance.new('BodyPosition')
BodyPositionOrigin.Name = 'BodyPosition'
BodyPositionOrigin.P = 9
BodyPositionOrigin.D = 6
BodyPositionOrigin.MaxForce = BigVector

local BodyGyroOrigin = Instance.new('BodyGyro')
BodyGyroOrigin.Name = 'BodyGyro'
BodyGyroOrigin.MaxTorque = BigVector

local function IsNear(obj, dist)
  local vector
	if obj:IsA('Model') then
		vector = obj.PrimaryPart and obj:GetPrimaryPartCFrame().Position or obj:GetModelCFrame().Position
	elseif obj:IsA('BasePart') or obj:IsA('Part') then
		vector = obj.CFrame.Position
  elseif typeof(obj) == 'Vector3' then
    vector = obj
  end

  return Player:DistanceFromCharacter(vector) < dist
end

local function ClearCar()
	if BodyPosition then BodyPosition:Destroy() end
	if BodyGyro then BodyGyro:Destroy() end
	Car = nil
end

local GravityVector = Vector3.new(0, workspace.Gravity / 16.8, 0)

local function Fly()
	if not FlyEnabled then return end

  local lookVector = BodyGyro.CFrame.LookVector
	local lookDirection = Vector3.new(lookVector.X, 0, lookVector.Z)
	local xAxis = Camera.CFrame.RightVector * (Direction.Right - Direction.Left)
	local yAxis = BodyGyro.CFrame.UpVector * (Direction.Up - Direction.Down) / 1.5
	local zAxis = lookDirection.Unit * (Direction.Forward - Direction.Backward)
	local vector = zAxis + xAxis + yAxis

	BodyPosition.Position = PrimaryPart.Position + (vector * Speed) + GravityVector
end

local function LaunchFly()
	if not InCar then return end
	task.spawn(function()
		BodyPosition = BodyPositionOrigin:Clone()
		BodyPosition.Parent = PrimaryPart
		BodyPosition.Position = PrimaryPart.Position

		BodyGyro = BodyGyroOrigin:Clone()
		BodyGyro.Parent = PrimaryPart
		repeat task.wait()
			if InCar then
				Fly()
			end
		until not FlyEnabled or not InCar
		if InCar then
			if BodyPosition then BodyPosition:Destroy() end
			if BodyGyro then BodyGyro:Destroy() end
		end
	end)
end

local VehicleModule = require(ReplicatedStorage.Game.Vehicle)

local VehicleEntered = VehicleModule.OnVehicleEntered:Connect(function(module)
	local seatPacket = module.SeatPacket
	if seatPacket.IsPassenger then return end
	print()
	module.Model.PrimaryPart = seatPacket.Part
	PrimaryPart = seatPacket.Part
	InCar = true
	if FlyEnabled then
		LaunchFly()
	end
end)

local VehicleExited = VehicleModule.OnVehicleExited:Connect(function(module)
	local seatPacket = module.SeatPacket
	if seatPacket.IsPassenger then return end

	InCar = false
	PrimaryPart = nil
	if module.Model then
		if BodyPosition then BodyPosition:Destroy() end
		if BodyGyro then BodyGyro:Destroy() end
	end
end)

local function FindCar()
	if Car then
		local seat = Car:FindFirstChild('Seat')
		if seat and seat.PlayerName.Value ~= Player.Name then
			ClearCar()
		end
	end
	if Car then
		return
	end
	for _, vehicle in next, workspace.Vehicles:GetChildren() do
		local seat = vehicle:FindFirstChild('Seat')
		if seat then
			local playerName = seat:FindFirstChild('PlayerName')
			if playerName and playerName.Value == Player.Name then
				Car = vehicle
				Car.PrimaryPart = seat
				PrimaryPart = seat
				if FlyEnabled then
					LaunchFly()
				end
			end
		end
	end
end

-- coroutine.wrap(function()
-- 	while DoFindCar do
-- 		FindCar()
-- 		task.wait(.4)
-- 	end
-- end)()

local KeyDown = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
  if input.UserInputType ~= Enum.UserInputType.Keyboard or gameProcessedEvent then return end
	local key = input.KeyCode
	if key == Keys.Toggle then
		FlyEnabled = not FlyEnabled
		if FlyEnabled then
			LaunchFly()
		end
	elseif key == Keys.Forward then
		Direction.Forward = 1
	elseif key == Keys.Backward then
		Direction.Backward = 1
	elseif key == Keys.Left then
		Direction.Left = 1
	elseif key == Keys.Right then
		Direction.Right = 1
	elseif key == Keys.Up then
		Direction.Up = 1
	elseif key == Keys.Down then
		Direction.Down = 1
	elseif key == Enum.KeyCode.Up then
		Speed = Speed + 20
	elseif key == Enum.KeyCode.Down then
		Speed = Speed - 20
	end
end)

local KeyUp = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
  if input.UserInputType ~= Enum.UserInputType.Keyboard or gameProcessedEvent then return end

	local key = input.KeyCode
	if key == Keys.Forward then
		Direction.Forward = 0
	elseif key == Keys.Backward then
		Direction.Backward = 0
	elseif key == Keys.Left then
		Direction.Left = 0
	elseif key == Keys.Right then
		Direction.Right = 0
	elseif key == Keys.Up then
		Direction.Up = 0
	elseif key == Keys.Down then
		Direction.Down = 0
	end
end)

local HBHook = RunService.Heartbeat:Connect(function()
	if FlyEnabled and InCar and BodyGyro then
		local cameraLook = Camera.CFrame.LookVector
		local look = Vector3.new(cameraLook.X, 0, cameraLook.Z)
		local pos = Vector3.new(0, (Direction.Forward - Direction.Backward) * math.rad(10), 0)
		BodyGyro.CFrame = CFrame.new(pos, look) * CFrame.fromOrientation(0, 0, math.rad(15 * (Direction.Left - Direction.Right)))
		--for i, v in pairs(Wheels) do
			--print(v.PrimaryPart.Position)
			--local c = v.CFrame
			--v.CFrame = CFrame.new(c.Position, c.LookVector) * CFrame.fromOrientation(0, 0, math.rad(2))
		--end
	end
end)

local function Destroy()
	FlyEnabled = nil
	InCar = nil
	VehicleEntered:Disconnect()
	VehicleEntered = nil
	VehicleExited:Disconnect()
	VehicleExited = nil
	KeyDown:Disconnect()
	KeyDown = nil
	KeyUp:Disconnect()
	KeyUp = nil
	HBHook:Disconnect()
	HBHook = nil
	Direction = nil
	PrimaryPart = nil
	BodyPositionOrigin = nil
	if BodyPosition then
		BodyPosition:Destroy()
	end
	BodyPosition = nil
	BodyGyroOrigin = nil
	if BodyGyro then
		BodyGyro:Destroy()
	end
	BodyGyro = nil
	BigVector = nil
	Keys = nil
	GravityVector = nil
	VehicleModule = nil
end

local DestroyHook = nil
DestroyHook = UserInputService.InputBegan:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
  if input.KeyCode == Enum.KeyCode.RightAlt then
		DestroyHook:Disconnect()
		DestroyHook = nil
		Destroy()
  end
end)