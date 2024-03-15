local _CameraFolder = workspace:WaitForChild('ModelCamera')
local CameraRotationPart = _CameraFolder:WaitForChild('CameraRotation')
local FakeHrp = _CameraFolder:WaitForChild('HumanoidRootPart')

local ConfigUI = game.Players.LocalPlayer.PlayerGui:WaitForChild('Config'):WaitForChild('Background')
local _XLabel: TextLabel = ConfigUI:WaitForChild('XLabel')
local _YLabel: TextLabel = ConfigUI:WaitForChild('YLabel')

local scale = 5
local xAxis = 0
local yAxis = 0

ConfigUI:WaitForChild('XPlus').MouseButton1Click:Connect(function()
    print(123)
    local newNumber = math.clamp(xAxis + scale, -90, 90)
    xAxis = newNumber
    _XLabel.Text = 'X-Axis: ' .. newNumber
end)

ConfigUI:WaitForChild('XMinus').MouseButton1Click:Connect(function()
    local newNumber = math.clamp(xAxis - scale, -90, 90)
    xAxis = newNumber
    _XLabel.Text = 'X-Axis: ' .. newNumber
end)

ConfigUI:WaitForChild('YPlus').MouseButton1Click:Connect(function()
    local newNumber = math.clamp(yAxis + scale, -90, 90)
    yAxis = newNumber
    _YLabel.Text = 'Y-Axis: ' .. newNumber
end)

ConfigUI:WaitForChild('YMinus').MouseButton1Click:Connect(function()
    local newNumber = math.clamp(yAxis - scale, -90, 90)
    yAxis = newNumber
    _YLabel.Text = 'Y-Axis: ' .. newNumber
end)

ConfigUI:WaitForChild('Reset').MouseButton1Click:Connect(function()
    _YLabel.Text = 'Y-Axis: 0'
    _XLabel.Text = 'X-Axis: 0'
    xAxis = 0
    yAxis = 0
end)

local _Scale = ConfigUI:WaitForChild('Scale')
_Scale.FocusLost:Connect(function()
    local input = tonumber(_Scale.Text)
    if input then
        scale = input
    end
end)



local gizmo = require(game:GetService('ReplicatedStorage').Shared.gizmo)

local RS = game:GetService('RunService')
local TS = game:GetService('TweenService')
local UIS = game:GetService('UserInputService')
local CAS = game:GetService('ContextActionService')

local camera = game.Workspace.CurrentCamera
local character = game.Workspace:WaitForChild(game.Players.LocalPlayer.Name)
local hrp: Part = character:WaitForChild('HumanoidRootPart')







local targetCameraOffset = Vector3.new(2,2,8)

local cameraRotationCFrame = CFrame.new(hrp.CFrame.Position)

local mostRecentCameraOffset = targetCameraOffset
local currentCameraOffset = Instance.new('Vector3Value')
local yRotationMultiplier = .4
local cameraSmoothnessMultiplier = 20




local function RenderCamera(deltaTime)
    local rootPosition = hrp.CFrame.Position

    cameraRotationCFrame = CFrame.new(rootPosition) * CFrame.Angles(0, math.rad(xAxis), 0) * CFrame.Angles(math.rad(yAxis), 0, 0)
    mostRecentCameraOffset = CameraOffsetRaycast()

    local finalCameraCFrame = cameraRotationCFrame * CFrame.new(mostRecentCameraOffset)
    camera.CFrame = finalCameraCFrame
end




function CameraOffsetRaycast()
    CameraRotationPart.CFrame =
    CFrame.new(CameraRotationPart.CFrame.Position) *
    CFrame.Angles(0, math.rad(xAxis), 0) *
    CFrame.Angles(math.rad(yAxis), 0, 0)

    gizmo.setColor(Color3.fromRGB(255, 75, 216))
    gizmo.setColor(Color3.fromRGB(0, 255, 0))
    gizmo.drawSphere(CameraRotationPart.CFrame * CFrame.new(CameraRotationPart.CFrame.LookVector*3), .5)

    local computedVector = Vector3.zero

    local cameraLookVector = CameraRotationPart.CFrame.LookVector
    local raycastOrigin = CameraRotationPart.CFrame.Position
    local rcp = RaycastParams.new()
    rcp.FilterType = Enum.RaycastFilterType.Exclude
    rcp.FilterDescendantsInstances = {FakeHrp, CameraRotationPart}

    local topOffset = (targetCameraOffset.Y * camera.CFrame.UpVector)
    local topResult = workspace:Raycast(raycastOrigin, topOffset, rcp)
    if not topResult then
        computedVector = Vector3.new(computedVector.X, targetCameraOffset.Y, computedVector.Z)
    else
        local yVectorLength = (topResult.Position - raycastOrigin).Magnitude
        computedVector = Vector3.new(computedVector.X, yVectorLength, computedVector.Z)
    end
    gizmo.drawArrow(raycastOrigin, raycastOrigin + topOffset * (computedVector.Y/targetCameraOffset.Y))
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
        print('Right')
        local clipDistance = (raycastOriginPostBack - rightClipResult.Position).Magnitude
        --gizmo.drawArrow(raycastOriginPostBack, rightClipResult.Position)
        local yOffset = computedVector.X - clipDistance
        local zOffset = computedVector.Z - (.1/clipDistance)
        computedVector = Vector3.new(yOffset, computedVector.Y, zOffset)

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


RS:BindToRenderStep('TestRender', 500, CameraOffsetRaycast)