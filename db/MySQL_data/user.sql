        DROP TABLE IF EXISTS `user`;
        CREATE TABLE `user` (
        `user_id` VARCHAR(225) NOT NULL,
      `username` VARCHAR(255) DEFAULT NULL,
      `first_name` VARCHAR(255) DEFAULT NULL,
      `last_name` VARCHAR(255) DEFAULT NULL,
      `password_hash` VARCHAR(255) DEFAULT NULL,
      `last_password_date` datetime DEFAULT NULL,
      `password_attempt` INT(11) DEFAULT NULL,
      `login_attempt` INT(11) DEFAULT NULL,
      `email` VARCHAR(255) DEFAULT NULL,
      `active` tinyint(1) NOT NULL  DEFAULT '0',
      `notify` tinyint(1) NOT NULL  DEFAULT '0',
      `role` VARCHAR(255) DEFAULT NULL,
      `site_code` VARCHAR(255) DEFAULT NULL,
      `preferred_keyboard` VARCHAR(255) DEFAULT NULL,
      `district_code` VARCHAR(255) DEFAULT NULL,
      `creator` VARCHAR(255) DEFAULT NULL,
      `plain_password` VARCHAR(255) DEFAULT NULL,
      `un_or_block_reason` VARCHAR(255) DEFAULT NULL,
      `signature` VARCHAR(255) DEFAULT NULL,
      `_rev` VARCHAR(255) DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      PRIMARY KEY (`user_id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=latin1;

INSERT INTO user (user_id, username, first_name, last_name, password_hash, last_password_date, password_attempt, login_attempt, email, active, notify, role, site_code, preferred_keyboard, district_code, creator, plain_password, un_or_block_reason, signature, _rev, updated_at, created_at) VALUES 
('d7d044ae3052b270a0b0dbbd5e76381e', "admin","EDRS","Administrator","$2a$10$sEJxvm4xsnkcEh110VlAFO0Shj2WwX.ixxXSJYdc2IPAyYvvyE1ua","2018-05-07 14:33:50",'0','0',"admin@baobabhealth.org",'true',0, "System Administrator","HQ","abc",NULL, "admin",NULL, NULL, NULL, "1-ceddab3a8367a082e12bb64ae3b51005","2018-05-07 14:33:50","2018-05-07 14:33:50");
