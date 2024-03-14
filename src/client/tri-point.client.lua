local gizmo = require(game:GetService('ReplicatedStorage').Shared.gizmo)

local RS = game:GetService('RunService')
local TS = game:GetService('TweenService')
local UIS = game:GetService('UserInputService')
local CAS = game:GetService('ContextActionService')
local Workspace = game:GetService('Workspace')

local camera = game.Workspace.CurrentCamera
local character = game.Workspace:WaitForChild(game.Players.LocalPlayer.Name)
local hrp: Part = character:WaitForChild('HumanoidRootPart')


local xAxis = 0
local yAxis = 0

local xValue = Instance.new('NumberValue')
local yValue = Instance.new('NumberValue')

local targetCameraOffset = Vector3.new(2,2,8)

local mostRecentCameraOffset = targetCameraOffset
local currentCameraOffset = Instance.new('Vector3Value')
local yRotationMultiplier = .4
local cameraSmoothnessMultiplier = 1

local function CustomCamera(_, inputState, inputObject)
    if inputState == Enum.UserInputState.Change then
        xAxis -= inputObject.Delta.X
        yAxis = math.clamp(yAxis - inputObject.Delta.Y * yRotationMultiplier, -75, 75)
    end
end


local function RenderCamera(deltaTime)
    local rootPosition = hrp.CFrame.Position
    mostRecentCameraOffset = RaycastCameraOffset()

    TS:Create(xValue,
    TweenInfo.new(deltaTime * cameraSmoothnessMultiplier, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
    {Value = xAxis})
    :Play()

    TS:Create(yValue,
    TweenInfo.new(deltaTime * cameraSmoothnessMultiplier, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
    {Value = yAxis})
    :Play()

    TS:Create(currentCameraOffset,
    TweenInfo.new(deltaTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0),
    {Value = mostRecentCameraOffset})
    :Play()

    local cameraCFrame = CFrame.new(rootPosition) * CFrame.Angles(0, math.rad(--[[xValue.Value]]xAxis), 0) * CFrame.Angles(math.rad(--[[yValue.Value]]yAxis), 0, 0)
    cameraCFrame = cameraCFrame * CFrame.new( mostRecentCameraOffset --[[currentCameraOffset.Value]])

    camera.CFrame = cameraCFrame
end


local function FocusCamera(_, inputState, _)
    if inputState == Enum.UserInputState.Begin then
        camera.CameraType = Enum.CameraType.Scriptable
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

        CAS:UnbindAction('Focus')
    end
end

CAS:BindAction('Focus', FocusCamera, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.Focus)

CAS:BindAction('Camera', CustomCamera, false, Enum.UserInputType.MouseMovement)

RS:BindToRenderStep('CameraMovement', Enum.RenderPriority.Camera.Value, RenderCamera)

function RaycastCameraOffset() : Vector3
    local computedVector = Vector3.zero

    local cameraLookVector = camera.CFrame.LookVector
    local raycastOrigin = hrp.CFrame.Position + (cameraLookVector:Cross(Vector3.new(0,1,0)) * .21)
    local rcp = RaycastParams.new()
    rcp.FilterType = Enum.RaycastFilterType.Exclude
    rcp.FilterDescendantsInstances = {character}

    local topOffset = (targetCameraOffset.Y * camera.CFrame.UpVector)
    local topResult = workspace:Raycast(raycastOrigin, topOffset, rcp)
    if not topResult then
        computedVector = Vector3.new(computedVector.X, targetCameraOffset.Y, computedVector.Z)
    else
        local yVectorLength = (topResult.Position - raycastOrigin).Magnitude
        computedVector = Vector3.new(computedVector.X, yVectorLength, computedVector.Z)
    end
    --gizmo.drawArrow(raycastOrigin, raycastOrigin + topOffset * (computedVector.Y/targetCameraOffset.Y))
    raycastOrigin = raycastOrigin + (topOffset * (computedVector.Y/targetCameraOffset.Y))

    local sideOffset = (cameraLookVector:Cross(Vector3.new(0,1,0))) * targetCameraOffset.X
    local sideResult = workspace:Raycast(raycastOrigin, sideOffset, rcp)
    if not sideResult then
        computedVector = Vector3.new(targetCameraOffset.X, computedVector.Y, computedVector.Z)
    else
        local xVectorLength = (sideResult.Position - raycastOrigin).Magnitude
        computedVector = Vector3.new(xVectorLength, computedVector.Y, computedVector.Z)
    end
    --gizmo.drawArrow(raycastOrigin, raycastOrigin + sideOffset * (computedVector.X/targetCameraOffset.X))
    raycastOrigin = raycastOrigin + (sideOffset * (computedVector.X/targetCameraOffset.X))

    local backOffset = (targetCameraOffset.Z * -cameraLookVector)
    local backResult = workspace:Raycast(raycastOrigin, backOffset, rcp)
    if not backResult then
        computedVector = Vector3.new(computedVector.X, computedVector.Y, targetCameraOffset.Z)
    else
        local zVectorLength = (backResult.Position - raycastOrigin).Magnitude
        computedVector = Vector3.new(computedVector.X, computedVector.Y, zVectorLength)
    end
    --gizmo.drawArrow(raycastOrigin, raycastOrigin + backOffset * (computedVector.Z/targetCameraOffset.Z))
    raycastOrigin = raycastOrigin + (backOffset * (computedVector.Z/targetCameraOffset.Z))

    return computedVector
end