local gizmo = require(game:GetService('ReplicatedStorage').Shared.gizmo)

local RS = game:GetService('RunService')
local TS = game:GetService('TweenService')
local UIS = game:GetService('UserInputService')
local CAS = game:GetService('ContextActionService')

local camera = game.Workspace.CurrentCamera
local character = game.Workspace:WaitForChild(game.Players.LocalPlayer.Name)
local hrp: Part = character:WaitForChild('HumanoidRootPart')


local xAxis = 0
local yAxis = 0

local xValue = Instance.new('NumberValue')
local yValue = Instance.new('NumberValue')

local targetCameraOffset = Vector3.new(2,2,8)
local yCameraOffset = 2

local cameraRotationCFrame = CFrame.new(hrp.CFrame.Position)

local mostRecentCameraOffset = targetCameraOffset
local currentCameraOffset = Instance.new('Vector3Value')
local yRotationMultiplier = .4
local cameraSmoothnessMultiplier = 20

local function CustomCamera(_, inputState, inputObject)
    if inputState == Enum.UserInputState.Change then
        xAxis -= inputObject.Delta.X
        yAxis = math.clamp(yAxis - inputObject.Delta.Y * yRotationMultiplier, -75, 75)
    end
end


local function RenderCamera(deltaTime)
    local rootPosition = hrp.CFrame.Position

    cameraRotationCFrame = CFrame.new(rootPosition) * CFrame.Angles(0, math.rad(xValue.Value), 0) * CFrame.Angles(math.rad(yValue.Value), 0, 0)
    mostRecentCameraOffset = CameraOffsetRaycast()

    TS:Create(xValue,
    TweenInfo.new(deltaTime * cameraSmoothnessMultiplier, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0),
    {Value = xAxis})
    :Play()

    TS:Create(yValue,
    TweenInfo.new(deltaTime * cameraSmoothnessMultiplier, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0),
    {Value = yAxis})
    :Play()

    TS:Create(currentCameraOffset,
    TweenInfo.new(deltaTime, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0, false, 0),
    {Value = mostRecentCameraOffset})
    :Play()

    local finalCameraCFrame = cameraRotationCFrame * CFrame.new(mostRecentCameraOffset)
    camera.CFrame = finalCameraCFrame
end

local r = workspace:Raycast()


CAS:BindAction('Camera', CustomCamera, false, Enum.UserInputType.MouseMovement)

RS:BindToRenderStep('CameraMovement', Enum.RenderPriority.Camera.Value, RenderCamera)

function CameraOffsetRaycast() : Vector3
    local cameraLookVector = cameraRotationCFrame.LookVector
    local raycastOrigin = hrp.CFrame.Position
    local rcp = RaycastParams.new()
    rcp.FilterType = Enum.RaycastFilterType.Exclude
    rcp.FilterDescendantsInstances = {character}

    local xOffset = (cameraLookVector:Cross(Vector3.new(0,1,0))) * targetCameraOffset.X
    local yOffset = (targetCameraOffset.Y * camera.CFrame.UpVector)
    local zOffset = (targetCameraOffset.Z * -cameraLookVector)
    local totalOffset = camera.CFrame.Position + xOffset + yOffset + zOffset

    local initalLookVector = CFrame.lookAt(raycastOrigin, totalOffset).LookVector
    local initalDistance = (raycastOrigin - totalOffset).Magnitude
    local initalResult = workspace:Raycast(raycastOrigin, initalLookVector * initalDistance, rcp)
    if initalResult then
        local dist = (initalResult.Position - raycastOrigin).Magnitude
        local multiplyer = dist/initalDistance
        return (targetCameraOffset * .95) * multiplyer

    else
        return targetCameraOffset

    end
end