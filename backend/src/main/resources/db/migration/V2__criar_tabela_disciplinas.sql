CREATE TABLE disciplinas (
    id         BIGSERIAL   PRIMARY KEY,
    usuario_id BIGINT      NOT NULL,
    nome       VARCHAR(100) NOT NULL,
    cor        VARCHAR(7)  NOT NULL,

    CONSTRAINT fk_disciplinas_usuario
        FOREIGN KEY (usuario_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT uk_disciplinas_usuario_nome UNIQUE (usuario_id, nome)
);

CREATE INDEX idx_disciplinas_usuario ON disciplinas (usuario_id);