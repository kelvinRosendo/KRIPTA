ALTER TABLE disciplinas ADD COLUMN componente_id BIGINT REFERENCES componentes_curriculares(id);
