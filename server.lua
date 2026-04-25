local QBCore = exports['qb-core']:GetCoreObject()

local function RoundAmount(amount)
    amount = tonumber(amount)

    if not amount then return nil end

    amount = math.floor(amount)

    if amount <= 0 then return nil end

    return amount
end

local function IsValidAmount(amount, maxAmount)
    amount = RoundAmount(amount)

    if not amount then
        return false, nil
    end

    if amount < Config.Limits.minAmount then
        return false, amount
    end

    if maxAmount and amount > maxAmount then
        return false, amount
    end

    return true, amount
end

local function GetCharacterName(Player)
    if not Player or not Player.PlayerData then
        return 'Unknown'
    end

    local charinfo = Player.PlayerData.charinfo or {}
    local firstName = charinfo.firstname or ''
    local lastName = charinfo.lastname or ''

    local fullName = (firstName .. ' ' .. lastName):gsub('^%s*(.-)%s*$', '%1')

    if fullName == '' then
        fullName = 'Unknown'
    end

    return fullName
end

local function GetAccountId(citizenid)
    return ('personal:%s'):format(citizenid)
end

local function InsertTransaction(citizenid, accountId, transactionType, amount, message, receiver)
    MySQL.insert.await(
        'INSERT INTO distortionz_banking_transactions (citizenid, account_id, type, amount, message, receiver) VALUES (?, ?, ?, ?, ?, ?)',
        {
            citizenid,
            accountId,
            transactionType,
            amount,
            message or '',
            receiver or ''
        }
    )
end

local function GetTransactions(citizenid)
    local transactions = MySQL.query.await(
        'SELECT id, account_id, type, amount, message, receiver, created_at FROM distortionz_banking_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT ?',
        {
            citizenid,
            Config.TransactionLimit
        }
    )

    return transactions or {}
end

local function BuildBankData(Player)
    if not Player or not Player.PlayerData then
        return nil
    end

    local playerData = Player.PlayerData
    local citizenid = playerData.citizenid
    local money = playerData.money or {}

    local cash = money.cash or 0
    local bank = money.bank or 0
    local characterName = GetCharacterName(Player)
    local accountId = GetAccountId(citizenid)

    return {
        bankName = Config.BankName,
        currency = Config.Currency,
        player = {
            name = characterName,
            citizenid = citizenid
        },
        wallet = {
            cash = cash,
            bank = bank
        },
        accounts = {
            {
                id = accountId,
                type = 'Personal Account',
                name = characterName,
                balance = bank,
                frozen = false
            }
        },
        transactions = GetTransactions(citizenid)
    }
end

local function FindOnlinePlayerByCitizenId(citizenid)
    if not citizenid or citizenid == '' then
        return nil
    end

    local players = QBCore.Functions.GetQBPlayers()

    for _, Player in pairs(players) do
        if Player
            and Player.PlayerData
            and Player.PlayerData.citizenid == citizenid
        then
            return Player
        end
    end

    return nil
end

local function NotifyClient(src, message, notifyType, duration)
    if not src or not message then
        return
    end

    notifyType = notifyType or 'primary'
    duration = duration or 5000

    if notifyType == 'inform' then
        notifyType = 'info'
    end

    if Config.Notify
        and Config.Notify.resource
        and GetResourceState(Config.Notify.resource) == 'started'
    then
        TriggerClientEvent('distortionz_notify:client:notify', src, {
            title = Config.Notify.title or Config.BankName or 'Distortionz Bank',
            message = message,
            type = notifyType,
            duration = duration
        })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.BankName or 'Distortionz Bank',
        description = message,
        type = notifyType,
        duration = duration
    })
end

lib.callback.register('distortionz_banking:server:getBankData', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return nil
    end

    return BuildBankData(Player)
end)

lib.callback.register('distortionz_banking:server:deposit', function(source, amount, note)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return {
            success = false,
            message = 'Player data could not be found.'
        }
    end

    local valid, cleanAmount = IsValidAmount(amount, Config.Limits.maxDeposit)

    if not valid then
        return {
            success = false,
            message = 'Invalid deposit amount.'
        }
    end

    local cash = Player.PlayerData.money.cash or 0

    if cash < cleanAmount then
        return {
            success = false,
            message = 'You do not have enough cash.'
        }
    end

    Player.Functions.RemoveMoney('cash', cleanAmount, 'distortionz-bank-deposit')
    Player.Functions.AddMoney('bank', cleanAmount, 'distortionz-bank-deposit')

    local citizenid = Player.PlayerData.citizenid
    local accountId = GetAccountId(citizenid)
    local characterName = GetCharacterName(Player)
    local message = note and note ~= '' and note or ('%s deposited $%s'):format(characterName, cleanAmount)

    InsertTransaction(
        citizenid,
        accountId,
        'deposit',
        cleanAmount,
        message,
        characterName
    )

    return {
        success = true,
        message = ('Deposited $%s.'):format(cleanAmount),
        data = BuildBankData(Player)
    }
end)

lib.callback.register('distortionz_banking:server:withdraw', function(source, amount, note)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return {
            success = false,
            message = 'Player data could not be found.'
        }
    end

    local valid, cleanAmount = IsValidAmount(amount, Config.Limits.maxWithdraw)

    if not valid then
        return {
            success = false,
            message = 'Invalid withdraw amount.'
        }
    end

    local bank = Player.PlayerData.money.bank or 0

    if bank < cleanAmount then
        return {
            success = false,
            message = 'You do not have enough money in the bank.'
        }
    end

    Player.Functions.RemoveMoney('bank', cleanAmount, 'distortionz-bank-withdraw')
    Player.Functions.AddMoney('cash', cleanAmount, 'distortionz-bank-withdraw')

    local citizenid = Player.PlayerData.citizenid
    local accountId = GetAccountId(citizenid)
    local characterName = GetCharacterName(Player)
    local message = note and note ~= '' and note or ('%s withdrew $%s'):format(characterName, cleanAmount)

    InsertTransaction(
        citizenid,
        accountId,
        'withdraw',
        cleanAmount,
        message,
        characterName
    )

    return {
        success = true,
        message = ('Withdrew $%s.'):format(cleanAmount),
        data = BuildBankData(Player)
    }
end)

lib.callback.register('distortionz_banking:server:transfer', function(source, targetCitizenId, amount, note)
    local src = source
    local Sender = QBCore.Functions.GetPlayer(src)

    if not Sender then
        return {
            success = false,
            message = 'Player data could not be found.'
        }
    end

    targetCitizenId = tostring(targetCitizenId or ''):gsub('%s+', '')

    if targetCitizenId == '' then
        return {
            success = false,
            message = 'Enter a valid citizen ID.'
        }
    end

    if targetCitizenId == Sender.PlayerData.citizenid then
        return {
            success = false,
            message = 'You cannot transfer money to yourself.'
        }
    end

    local valid, cleanAmount = IsValidAmount(amount, Config.Limits.maxTransfer)

    if not valid then
        return {
            success = false,
            message = 'Invalid transfer amount.'
        }
    end

    local senderBank = Sender.PlayerData.money.bank or 0

    if senderBank < cleanAmount then
        return {
            success = false,
            message = 'You do not have enough money in the bank.'
        }
    end

    local Receiver = FindOnlinePlayerByCitizenId(targetCitizenId)

    if not Receiver then
        return {
            success = false,
            message = 'That citizen is not online.'
        }
    end

    Sender.Functions.RemoveMoney('bank', cleanAmount, 'distortionz-bank-transfer-sent')
    Receiver.Functions.AddMoney('bank', cleanAmount, 'distortionz-bank-transfer-received')

    local senderCitizenId = Sender.PlayerData.citizenid
    local receiverCitizenId = Receiver.PlayerData.citizenid

    local senderAccountId = GetAccountId(senderCitizenId)
    local receiverAccountId = GetAccountId(receiverCitizenId)

    local senderName = GetCharacterName(Sender)
    local receiverName = GetCharacterName(Receiver)

    local senderMessage = note and note ~= '' and note or ('Transfer sent to %s'):format(receiverName)
    local receiverMessage = note and note ~= '' and note or ('Transfer received from %s'):format(senderName)

    InsertTransaction(
        senderCitizenId,
        senderAccountId,
        'transfer_sent',
        cleanAmount,
        senderMessage,
        receiverName
    )

    InsertTransaction(
        receiverCitizenId,
        receiverAccountId,
        'transfer_received',
        cleanAmount,
        receiverMessage,
        senderName
    )

    NotifyClient(
        Receiver.PlayerData.source,
        ('You received $%s from %s.'):format(cleanAmount, senderName),
        'cash',
        6000
    )

    return {
        success = true,
        message = ('Transferred $%s to %s.'):format(cleanAmount, receiverName),
        data = BuildBankData(Sender)
    }
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    print(('[distortionz_banking] Server loaded. Bank: %s | Version: %s'):format(
        Config.BankName or 'Distortionz Bank',
        Config.Script and Config.Script.version or '1.0.0'
    ))
end)
