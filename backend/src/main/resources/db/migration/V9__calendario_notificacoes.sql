CREATE TABLE eventos_calendario(id BIGSERIAL PRIMARY KEY,owner_id BIGINT NOT NULL REFERENCES users(id),title VARCHAR(200) NOT NULL,note VARCHAR(4000),date DATE NOT NULL,time TIME,scope VARCHAR(20) NOT NULL CHECK(scope IN ('PESSOAL','ESCOLAR')),type VARCHAR(20) NOT NULL CHECK(type IN ('EVENT','EXAM','TASK')));
CREATE INDEX idx_eventos_date ON eventos_calendario(date);
CREATE INDEX idx_eventos_owner ON eventos_calendario(owner_id);
CREATE TABLE leituras_notificacao(id BIGSERIAL PRIMARY KEY,event_id BIGINT NOT NULL REFERENCES eventos_calendario(id) ON DELETE CASCADE,user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,UNIQUE(event_id,user_id));
