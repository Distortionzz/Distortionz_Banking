local VersionCheck = {
    enabled = Config.VersionCheck.enabled,
    resourceName = Config.VersionCheck.resourceName,
    currentVersion = Config.VersionCheck.currentVersion,
    githubVersionUrl = Config.VersionCheck.githubVersionUrl
}

local function PrintVersionMessage(messageType, resourceName, message)
    local colors = {
        success = '^2',
        warning = '^3',
        error = '^1',
        info = '^5'
    }

    local color = colors[messageType] or '^7'

    print(('%s[%s]^7 %s'):format(color, resourceName or GetCurrentResourceName(), message))
end

local function NormalizeVersion(version)
    if not version then return '0.0.0' end

    version = tostring(version)
    version = version:gsub('^v', '')

    return version
end

local function SplitVersion(version)
    version = NormalizeVersion(version)

    local major, minor, patch = version:match('^(%d+)%.(%d+)%.(%d+)')

    return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

local function IsVersionNewer(latestVersion, currentVersion)
    local latestMajor, latestMinor, latestPatch = SplitVersion(latestVersion)
    local currentMajor, currentMinor, currentPatch = SplitVersion(currentVersion)

    if latestMajor > currentMajor then return true end
    if latestMajor < currentMajor then return false end

    if latestMinor > currentMinor then return true end
    if latestMinor < currentMinor then return false end

    return latestPatch > currentPatch
end

local function CheckVersion()
    if not VersionCheck.enabled then
        return
    end

    local resourceName = VersionCheck.resourceName or GetCurrentResourceName()
    local currentVersion = VersionCheck.currentVersion or GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'
    local versionUrl = VersionCheck.githubVersionUrl

    if not versionUrl or versionUrl == '' then
        PrintVersionMessage('warning', resourceName, 'Version check enabled, but no GitHub version URL was set.')
        return
    end

    PerformHttpRequest(versionUrl, function(statusCode, responseText)
        if statusCode ~= 200 or not responseText then
            PrintVersionMessage('error', resourceName, 'Could not check latest version. HTTP status: ' .. tostring(statusCode))
            return
        end

        local success, data = pcall(json.decode, responseText)

        if not success or not data then
            PrintVersionMessage('error', resourceName, 'Could not decode version.json from GitHub.')
            return
        end

        local latestVersion = data.version or '0.0.0'
        local downloadUrl = data.download or 'No download URL provided.'
        local changelog = data.changelog or 'No changelog provided.'

        if IsVersionNewer(latestVersion, currentVersion) then
            PrintVersionMessage('warning', resourceName, 'Update available!')
            PrintVersionMessage('warning', resourceName, 'Current: v' .. NormalizeVersion(currentVersion) .. ' | Latest: v' .. NormalizeVersion(latestVersion))
            PrintVersionMessage('info', resourceName, 'Download: ' .. downloadUrl)
            PrintVersionMessage('info', resourceName, 'Changelog: ' .. changelog)
        else
            PrintVersionMessage('success', resourceName, 'You are running the latest version. v' .. NormalizeVersion(currentVersion))
        end
    end, 'GET')
end

CreateThread(function()
    Wait(3000)
    CheckVersion()
end)
