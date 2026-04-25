# 🏦 Distortionz Banking

Premium custom Qbox banking system for Distortionz RP.

## ✨ Features

- Premium dark/red Distortionz Bank NUI
- Personal bank account dashboard
- Deposit cash into bank
- Withdraw bank funds into cash
- Transfer to another online citizen by Citizen ID
- Transaction history stored with oxmysql
- ox_target bank and ATM interactions
- `/bank` command support
- Distortionz Notify integration with ox_lib fallback
- GitHub version checker support

## 📦 Dependencies

- qbx_core
- ox_lib
- oxmysql
- ox_target recommended
- distortionz_notify recommended

## 📁 Install

Place the resource here:

```txt
resources/[CustomScripts]/distortionz_banking
```

Add this to `server.cfg` after core resources:

```cfg
ensure ox_lib
ensure qbx_core
ensure oxmysql
ensure ox_target
ensure distortionz_notify
ensure distortionz_banking
```

## 🗄️ SQL

Run this once:

```txt
sql/distortionz_banking.sql
```

## ⚙️ Version Check

Version checking is disabled by default until the repository is uploaded.

After uploading `version.json` to GitHub, set this in `config.lua`:

```lua
Config.VersionCheck.enabled = true
```

## ✅ Status

Initial v1.0.0 release.
