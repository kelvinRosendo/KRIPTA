CREATE TABLE tarefas(id BIGSERIAL PRIMARY KEY, owner_id BIGINT NOT NULL REFERENCES users(id), subject_id BIGINT REFERENCES disciplinas(id) ON DELETE SET NULL, title VARCHAR(200) NOT NULL, description VARCHAR(4000), due_date TIMESTAMP WITH TIME ZONE, priority VARCHAR(255) NOT NULL, completed BOOLEAN NOT NULL DEFAULT FALSE);
CREATE INDEX idx_tarefas_owner ON tarefas(owner_id);
