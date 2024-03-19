local RS = game:GetService('RunService')
local TS = game:GetService('TweenService')
local UIS = game:GetService('UserInputService')
local CAS = game:GetService('ContextActionService')

local Module = {}


local Configuration = {
    TargetCameraOffset = Vector3.new(2,2,8);
    CameraSmoothness = 10;
    VerticalMultiplyer = .5;
    HorizontalMultiplyer = 1;
    MaxVerticalAngle = 75
}

local _InternalProperties = {
    CameraRotationCFrame = CFrame.identity;
    SmoothedInput = {X = Instance.new('NumberValue'), Y = Instance.new('NumberValue')};
    RawInput = {X = 0, Y = 0};
    CurrentCameraMode = '';
}

local CamearTypesStart = {
    Default = StartDefaultCamera();
    Survivor = StartSurvivorCamera();
}

local CameraTypesStop = {
    Default = StopDefaultCamear();
    Survivor = StartSurvivorCamera();
}

function Module:DisableCurrentCamera()
    local currentMode = _InternalProperties.CurrentCameraMode
    local StopFunction = CameraTypesStop[currentMode]

    StopFunction()
    _InternalProperties.CurrentCameraMode = ""
end

function Module:SetCameraType(type: string)
    local currentMode = _InternalProperties.CurrentCameraMode
    if type == currentMode then
        warn('Camera type is already: ' .. type)
        return
    end

    for index, startFunction in pairs(CamearTypesStart) do
        if type == index then
            _InternalProperties.CurrentCameraMode = type
            print('Switching type to: ' .. type)
            startFunction()
            return
        end
    end
    warn('Invalid Input: ' .. type)
end


-- Camera Type Functions --

function StartDefaultCamera()
    local camera = workspace.CurrentCamera

    camera.CameraType = Enum.CameraType.Custom
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

function StopDefaultCamear()
    local camera = workspace.CurrentCamera

    camera.CameraType = Enum.CameraType.Fixed
end


function StartSurvivorCamera()
    local camera = workspace.CurrentCamera

    CAS:BindAction('CameraInput', CaptureCameraInput, false, Enum.UserInputType.MouseMovement)
    RS:BindToRenderStep('RenderCamera', Enum.RenderPriority.Camera.Value + 1, RenderSurvivorCamera)

    camera.CameraType = Enum.CameraType.Scriptable
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function StopSurvivorCamera()
    local camera = workspace.CurrentCamera

    CAS:UnbindAction('CameraInput')
    RS:UnbindFromRenderStep('RenderCamera')
    camera.CameraType = Enum.CameraType.Scriptable
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
end


function CameraOffsetRaycast() : Vector3
    local character = workspace:WaitForChild(game.Players.LocalPlayer.Name)
    local hrp = character:WaitForChild('HumanoidRootPart')
    local camera = workspace.CurrentCamera

    local computedVector = Vector3.zero
    local targetCameraOffset = Configuration.TargetCameraOffset

    local cameraLookVector = _InternalProperties.CameraRotationCFrame.LookVector
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

        local clipDistance = (raycastOriginPostBack - rightClipResult.Position).Magnitude
        --gizmo.drawArrow(raycastOriginPostBack, rightClipResult.Position)
        computedVector = Vector3.new((computedVector.X - clipDistance), computedVector.Y, computedVector.Z)

        return computedVector
    end
    --gizmo.drawRay(hrp.CFrame.Position, rightLookVector * rightDistance)

    local leftClipCheckOffset = (cameraLookVector:Cross(Vector3.new(0,1,0)) * -.21)
    local leftLookVector = CFrame.lookAt(hrp.CFrame.Position, raycastOriginPostBack + leftClipCheckOffset).LookVector
    local leftDistance = (hrp.CFrame.Position - raycastOriginPostBack + leftClipCheckOffset).Magnitude

    local leftClipResult = workspace:Raycast(hrp.CFrame.Position, leftLookVector * leftDistance, rcp)
    if leftClipResult then

        local clipDistance = (raycastOriginPostBack - leftClipResult.Position).Magnitude
        computedVector = Vector3.new((computedVector.X + clipDistance), computedVector.Y, computedVector.Z)

        return computedVector
    end
    --gizmo.drawRay(hrp.CFrame.Position, leftLookVector * leftDistance)

    return computedVector
end

function RenderSurvivorCamera(deltaTime)
    local humanoidRootPart = workspace:WaitForChild(game.Players.LocalPlayer.Name):WaitForChild('HumanoidRootPart')
    local camera = workspace.CurrentCamera
    local rootPosition = humanoidRootPart.CFrame.Position

    _InternalProperties.CameraRotationCFrame = CFrame.new(rootPosition) *
    CFrame.Angles(0, math.rad(_InternalProperties.SmoothedInput.X.Value), 0) *
    CFrame.Angles(math.rad(_InternalProperties.SmoothedInput.Y.Value), 0, 0)

    local newCameraOffset = CameraOffsetRaycast()

    TS:Create(_InternalProperties.SmoothedInput.X,
    TweenInfo.new(deltaTime * Configuration.CameraSmoothness, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0),
    {Value = _InternalProperties.RawInput.X})
    :Play()

    TS:Create(_InternalProperties.SmoothedInput.Y,
    TweenInfo.new(deltaTime * Configuration.CameraSmoothness, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0),
    {Value = _InternalProperties.RawInput.Y})
    :Play()

    local finalCameraCFrame = _InternalProperties.CameraRotationCFrame * CFrame.new(newCameraOffset)
    camera.CFrame = finalCameraCFrame
end

function CaptureCameraInput(_, inputState, inputObject)
    if inputState == Enum.UserInputState.Change then
        _InternalProperties.RawInput.X = _InternalProperties.RawInput.X - inputObject.Delta.X
        _InternalProperties.RawInput.Y = math.clamp(_InternalProperties.RawInput.Y - inputObject.Delta.Y * Configuration.VerticalMultiplyer, -Configuration.MaxVerticalAngle, Configuration.MaxVerticalAngle)
    end
end

return Module