ALTER TABLE users ADD COLUMN pode_aprovar BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD CONSTRAINT ck_professor_aprovador CHECK (NOT pode_aprovar OR tipo = 'PROFESSOR');
