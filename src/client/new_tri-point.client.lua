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

    local finalCameraCFrame = cameraRotationCFrame * CFrame.new(mostRecentCameraOffset--[[currentCameraOffset.Value]])
    camera.CFrame = finalCameraCFrame
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

function CameraOffsetRaycast() : Vector3
    local computedVector = Vector3.zero

    local cameraLookVector = cameraRotationCFrame.LookVector
    local raycastOrigin = hrp.CFrame.Position --+ (cameraLookVector:Cross(Vector3.new(0,1,0)) * .21)
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
    local raycastOriginPostBack = raycastOrigin + (backOffset * (computedVector.Z/targetCameraOffset.Z))

    local rightClipCheckOffset = (cameraLookVector:Cross(Vector3.new(0,1,0)) * .21)
    local rightLookVector = CFrame.lookAt(hrp.CFrame.Position, raycastOriginPostBack + rightClipCheckOffset).LookVector
    local rightDistance = (hrp.CFrame.Position - raycastOriginPostBack + rightClipCheckOffset).Magnitude

    local rightClipResult = workspace:Raycast(hrp.CFrame.Position, rightLookVector * rightDistance, rcp)
    if rightClipResult then
        --print('Right')
        local clipDistance = (raycastOriginPostBack - rightClipResult.Position).Magnitude
        --gizmo.drawArrow(raycastOriginPostBack, rightClipResult.Position)
        local totalClip = computedVector.X - clipDistance
        --print('Total Clip: ' .. clipDistance)
        local zOffset = computedVector.Z - (.1/clipDistance)
        computedVector = Vector3.new(computedVector.X, computedVector.Y, computedVector.Z - totalClip)

        local rightCrossed = computedVector:Cross(Vector3.new(0,1,0) * (clipDistance/.21))
        print(rightCrossed)

        return computedVector
    end
    --gizmo.drawRay(hrp.CFrame.Position, rightLookVector * rightDistance)

    local leftClipCheckOffset = (cameraLookVector:Cross(Vector3.new(0,1,0)) * -.21)
    local leftLookVector = CFrame.lookAt(hrp.CFrame.Position, raycastOriginPostBack + leftClipCheckOffset).LookVector
    local leftDistance = (hrp.CFrame.Position - raycastOriginPostBack + leftClipCheckOffset).Magnitude

    local leftClipResult = workspace:Raycast(hrp.CFrame.Position, leftLookVector * leftDistance, rcp)
    if leftClipResult then
        print('Left')
        local clipDistance = (raycastOriginPostBack - leftClipResult.Position).Magnitude
        computedVector = Vector3.new((computedVector.X + clipDistance), computedVector.Y, computedVector.Z)

        return computedVector
    end
    --gizmo.drawRay(hrp.CFrame.Position, leftLookVector * leftDistance)

    return computedVector
end
