# Distortionz Banking

> Premium custom banking system for Qbox/FiveM — deposits, withdrawals, transfers, transaction history, and a polished NUI tied to qbx_core money accounts.

![FiveM](https://img.shields.io/badge/FiveM-cerulean-yellow?style=flat-square&labelColor=181b20)
![Qbox](https://img.shields.io/badge/Qbox-required-red?style=flat-square&labelColor=dfb317)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Version](https://img.shields.io/github/v/release/Distortionzz/distortionz_banking?style=flat-square&color=d4aa62&label=version)

---

## Overview

A hand-built replacement for default Qbox banking. Premium dark/red NUI with deposit / withdraw / transfer flows, transaction ledger persisted in MySQL, and ox_target ATM + bank counter integration.

## Features

- Personal bank account dashboard
- Deposit cash → bank
- Withdraw bank → cash
- Transfer to another online citizen by Citizen ID
- Transaction history persisted via oxmysql
- ox_target on bank counter + ATMs
- `/bank` command
- Distortionz Notify integration with ox_lib fallback
- GitHub version checker

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| `qbx_core` | yes | Money accounts (cash / bank) |
| `ox_lib` | yes | Callbacks, notify fallback |
| `oxmysql` | yes | Transaction history |
| `ox_target` | recommended | ATM + counter interactions |
| `distortionz_notify` | optional | Branded notifications |

## Installation

```cfg
ensure ox_lib
ensure qbx_core
ensure oxmysql
ensure ox_target
ensure distortionz_notify
ensure distortionz_banking
```

### SQL setup

Run the included migration once:

```
sql/distortionz_banking.sql
```

## Configuration

See [`config.lua`](config.lua) for ATM locations, bank counter peds, transaction limits, fee tiers.

## Credits

- **Author:** Distortionz
- **Framework:** [Qbox Project](https://github.com/Qbox-project)

## License

MIT — see [LICENSE](LICENSE).
