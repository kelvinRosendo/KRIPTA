CREATE TABLE study_items(id BIGSERIAL PRIMARY KEY,owner_id BIGINT NOT NULL REFERENCES users(id),parent_id BIGINT NOT NULL,kind VARCHAR(255) NOT NULL CHECK(kind IN ('UNIT','MATERIAL')),name VARCHAR(200) NOT NULL,description VARCHAR(4000),url VARCHAR(2000),type VARCHAR(255),completed BOOLEAN NOT NULL DEFAULT FALSE);
CREATE INDEX idx_study_parent ON study_items(owner_id,kind,parent_id);
