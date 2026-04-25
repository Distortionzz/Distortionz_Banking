Config = {}

Config.Script = {
    name = 'Distortionz Banking',
    version = '1.0.0'
}

Config.VersionCheck = {
    enabled = false, -- turn true after you upload this repo to GitHub
    resourceName = 'distortionz_banking',
    currentVersion = '1.0.0',
    githubVersionUrl = 'https://raw.githubusercontent.com/Distortionzz/distortionz_banking/main/version.json'
}

Config.BankName = 'Distortionz Bank'
Config.Currency = 'USD'

Config.Notify = {
    resource = 'distortionz_notify',
    title = 'Distortionz Bank'
}

Config.Target = {
    enabled = true,
    distance = 2.0
}

Config.Commands = {
    enabled = true,
    openBank = 'bank'
}

Config.Blips = {
    enabled = true,
    sprite = 108,
    color = 1,
    scale = 0.72,
    label = 'Distortionz Bank',
    shortRange = true
}

Config.BankLocations = {
    vector4(149.92, -1040.74, 29.37, 160.0),
    vector4(313.83, -278.57, 54.17, 160.0),
    vector4(-351.01, -49.99, 49.04, 160.0),
    vector4(-1212.98, -330.84, 37.79, 205.0),
    vector4(-2962.58, 482.63, 15.70, 90.0),
    vector4(1175.06, 2706.64, 38.09, 0.0),
    vector4(-112.18, 6469.78, 31.63, 315.0)
}

Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

Config.Limits = {
    minAmount = 1,
    maxDeposit = 1000000,
    maxWithdraw = 1000000,
    maxTransfer = 1000000
}

Config.Transfer = {
    onlineOnly = true
}

Config.TransactionLimit = 35
