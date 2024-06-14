CREATE DATABASE boarddb DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

USE boarddb;

GRANT REPLICATION SLAVE ON *.* TO 'replicationuser'@'%' IDENTIFIED BY 'replpwd';
FLUSH PRIVILEGES;

CREATE USER 'boarduser'@'%' IDENTIFIED BY 'boardpass';
GRANT ALL PRIVILEGES ON boarddb.* TO 'boarduser'@'%';
FLUSH PRIVILEGES;

CREATE TABLE `user` (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    password VARCHAR(255),
    username VARCHAR(255),
    created DATETIME(6),
    updated DATETIME(6)
);

CREATE TABLE role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20),
    created DATETIME(6),
    updated DATETIME(6)
);

CREATE TABLE user_role (
    user_id BIGINT,
    role_id INT,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES user(id),
    FOREIGN KEY (role_id) REFERENCES role(id)
);

CREATE TABLE board (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NULL COMMENT '제목',
    content TEXT NULL COMMENT '내용',
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    `user_id` BIGINT,
    CONSTRAINT fk_user_id FOREIGN KEY (`user_id`) REFERENCES `user` (id)
) COMMENT '게시판';


CREATE TABLE comment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    content TEXT NULL,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    board_id INT NULL,
    user_id BIGINT,
    CONSTRAINT comment_board_id_fk FOREIGN KEY (board_id) REFERENCES board (id),
    CONSTRAINT comment_user_id_fk  FOREIGN KEY (user_id) REFERENCES user (id)
);

CREATE TABLE image (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mimetype VARCHAR(100),
    data LONGBLOB,
    original_name VARCHAR(100),
    created DATETIME
);