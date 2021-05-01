CREATE SCHEMA IF NOT EXISTS `database` DEFAULT CHARACTER SET utf8mb4 ;
USE `database` ;

SET CHARSET utf8mb4;

CREATE TABLE IF NOT EXISTS `database`.`sample` (
     `id`  INT(11)
    ,`age` INT(11)
    ,`ja_name`  VARCHAR(30)
    ,`en_name`  VARCHAR(30)
    ,PRIMARY KEY (`id`)
    ,INDEX language_id_index (`id`)
)ENGINE = InnoDB ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;