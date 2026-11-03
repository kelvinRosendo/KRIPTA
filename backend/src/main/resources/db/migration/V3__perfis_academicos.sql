ALTER TABLE users ADD COLUMN rm VARCHAR(50);
ALTER TABLE users DROP CONSTRAINT ck_users_tipo;
ALTER TABLE users ADD CONSTRAINT ck_users_tipo CHECK (tipo IN ('ADMIN','USUARIO','ALUNO','PROFESSOR'));
ALTER TABLE users ADD CONSTRAINT ck_aluno_rm CHECK (tipo <> 'ALUNO' OR (rm IS NOT NULL AND length(trim(rm)) > 0));
