-- Migracao inicial: tabela de usuarios do KRIPTA

CREATE TABLE users (
    id    BIGSERIAL   PRIMARY KEY,
    nome  VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    tipo  VARCHAR(20)  NOT NULL,

    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT ck_users_tipo  CHECK (tipo IN ('ADMIN', 'USUARIO'))
);
