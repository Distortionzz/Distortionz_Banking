CREATE TABLE IF NOT EXISTS `distortionz_banking_transactions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `account_id` VARCHAR(128) NOT NULL,
    `type` VARCHAR(32) NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `message` VARCHAR(255) DEFAULT '',
    `receiver` VARCHAR(128) DEFAULT '',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
