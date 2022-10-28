local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

local LocalPlayer = game:GetService('Players').LocalPlayer
local Camera = workspace.CurrentCamera
local Direction = {
	Forward = 0,
	Backward = 0,
	Left = 0,
	Right = 0,
	Up = 0,
	Down = 0
}

local FlyEnabled = false
local Character = LocalPlayer.Character
local RootPart = Character and Character.HumanoidRootPart or nil
local Speed = 65
local BodyPosition : BodyPosition
local BodyGyro : BodyGyro
local BigVector = Vector3.new(math.huge, math.huge, math.huge)

local Keys = {
  Forward = Enum.KeyCode.W,
  Backward = Enum.KeyCode.S,
  Right = Enum.KeyCode.D,
  Left = Enum.KeyCode.A,
  Up = Enum.KeyCode.E,
  Down = Enum.KeyCode.Q,
	Toggle = Enum.KeyCode.X
}

local BodyPositionOrigin = Instance.new('BodyPosition')
BodyPositionOrigin.Name = 'BodyPosition'
BodyPositionOrigin.MaxForce = BigVector

local BodyGyroOrigin = Instance.new('BodyGyro')
BodyGyroOrigin.Name = 'BodyGyro'
BodyGyroOrigin.MaxTorque = BigVector

--local sqrt = math.sqrt(2)
local GravityVector = Vector3.new(0, 0.20792, 0)

local function Fly()
	if not FlyEnabled then return end

	local cameraCFrame = Camera.CFrame
	local zAxis = cameraCFrame.LookVector * (Direction.Forward - Direction.Backward)
	local xAxis = cameraCFrame.RightVector * (Direction.Right - Direction.Left)
	local yAxis = BodyGyro.CFrame.UpVector * (Direction.Up - Direction.Down)

	local allAxises = xAxis + yAxis + zAxis

	-- if Direction.Forward + Direction.Backward ~= 0 and (Direction.Right + Direction.Left ~= 0 or Direction.Up + Direction.Down ~= 0)  then
	-- 	sum = Vector3.new(sum.X / sqrt, sum.Y, sum.Z / sqrt)
	-- end
	--if (Direction.Forward + Direction.Backward ~= 0 or Direction.Right + Direction.Left ~= 0) and Direction.Up + Direction.Down ~= 0 then
	--	sum = sum / sqrt
	--end

	BodyPosition.Position = RootPart.Position + (allAxises * Speed) + GravityVector
	Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
end

local function LaunchFly()
	task.spawn(function()
		BodyPosition = BodyPositionOrigin:Clone()
		BodyPosition.Parent = RootPart
		BodyPosition.Position = RootPart.CFrame.Position
		BodyPosition.MaxForce = BigVector

		BodyGyro = BodyGyroOrigin:Clone()
		BodyGyro.Parent = RootPart
		while FlyEnabled and RootPart do
			Fly()
			RunService.Heartbeat:Wait()
			--task.wait()
		end
		if RootPart then
			BodyPosition.Position = RootPart.CFrame.Position
			if BodyPosition then
				BodyPosition:Destroy()
			end
			if BodyGyro then
				BodyGyro:Destroy()
			end
		end
	end)
end

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
	elseif key == Keys.Down then
		Direction.Down = 1
	elseif key == Keys.Up then
		Direction.Up = 1
	end
end)

local KeyUp = UserInputService.InputEnded:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local key = input.KeyCode
	if key == Keys.Forward then
		Direction.Forward = 0
	elseif key == Keys.Backward then
		Direction.Backward = 0
	elseif key == Keys.Left then
		Direction.Left = 0
	elseif key == Keys.Right then
		Direction.Right = 0
	elseif key == Keys.Down then
		Direction.Down = 0
	elseif key == Keys.Up then
		Direction.Up = 0
	end
end)

local HBHook = RunService.Heartbeat:Connect(function()
	if FlyEnabled and RootPart and BodyGyro then
		BodyGyro.CFrame = Camera.CFrame
	end
end)

local CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
	Character = character
	local humanoid = Character:WaitForChild('Humanoid')
	RootPart = humanoid.RootPart
	humanoid.Died:Once(function()
		FlyEnabled = false
	end)
end)

Character.Humanoid.Died:Once(function()
	FlyEnabled = false
end)

local function Destroy()
	FlyEnabled = nil
	KeyDown:Disconnect()
	KeyDown = nil
	KeyUp:Disconnect()
	KeyUp = nil
	HBHook:Disconnect()
	HBHook = nil
	CharacterAdded:Disconnect()
	CharacterAdded = nil
	Direction = nil
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