-- Etec São Mateus (227), cinco cursos M-Tec. Fonte e versão em cada bloco.
-- Marketing 2ª/3ª: projeção do Plano 1051; Nutrição 2ª/3ª: referência CPS 338.
ALTER TABLE users ADD COLUMN curso_mtec VARCHAR(32);
ALTER TABLE users ADD COLUMN serie_mtec INTEGER;
ALTER TABLE users ADD CONSTRAINT ck_users_mtec CHECK (
    (curso_mtec IS NULL AND serie_mtec IS NULL) OR
    (curso_mtec IS NOT NULL AND serie_mtec IS NOT NULL AND serie_mtec BETWEEN 1 AND 3)
);

CREATE TABLE curriculo_mtec (
    id BIGSERIAL PRIMARY KEY,
    curso VARCHAR(32) NOT NULL,
    serie INTEGER NOT NULL CHECK (serie BETWEEN 1 AND 3),
    componente_id BIGINT NOT NULL REFERENCES componentes_curriculares(id),
    UNIQUE (curso, serie, componente_id)
);

CREATE TEMP TABLE mtec_matriz_importacao (
    curso VARCHAR(32) NOT NULL,
    serie INTEGER NOT NULL,
    componente TEXT NOT NULL,
    horas_aula INTEGER NOT NULL
) ON COMMIT DROP;

-- Administração, 1ª série | Plano 1040 | página 20 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Administracao-2026-MTec-1040-1a-Serie-1.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('administracao', 1, 'Língua Portuguesa', 80),
    ('administracao', 1, 'Língua Inglesa', 80),
    ('administracao', 1, 'Arte', 80),
    ('administracao', 1, 'Educação Física', 80),
    ('administracao', 1, 'Matemática', 80),
    ('administracao', 1, 'Biologia', 80),
    ('administracao', 1, 'Física', 80),
    ('administracao', 1, 'Química', 80),
    ('administracao', 1, 'História', 80),
    ('administracao', 1, 'Geografia', 80),
    ('administracao', 1, 'Filosofia', 40),
    ('administracao', 1, 'Sociologia', 40),
    ('administracao', 1, 'Legislação Empresarial', 40),
    ('administracao', 1, 'Conduta Profissional e Relações do Trabalho', 40),
    ('administracao', 1, 'Projetos de Tecnologia da Informação e Comunicação', 80),
    ('administracao', 1, 'Planejamento Empresarial', 80),
    ('administracao', 1, 'Planejamento e Organização das Rotinas Administrativas', 80);

-- Administração, 2ª série | Plano 427 | página 35 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2023/02/Administracao-427_MTec_atualizado-em-16-11-22-2.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('administracao', 2, 'Língua Portuguesa', 120),
    ('administracao', 2, 'Língua Inglesa', 80),
    ('administracao', 2, 'Educação Física', 80),
    ('administracao', 2, 'Matemática', 120),
    ('administracao', 2, 'Física', 80),
    ('administracao', 2, 'Química', 80),
    ('administracao', 2, 'Biologia', 80),
    ('administracao', 2, 'História', 80),
    ('administracao', 2, 'Geografia', 80),
    ('administracao', 2, 'Filosofia', 40),
    ('administracao', 2, 'Projeto Integrador I e II', 80),
    ('administracao', 2, 'Aplicativos informatizados', 80),
    ('administracao', 2, 'Custos, Processos e Operações contábeis', 120),
    ('administracao', 2, 'Planejamento e Organização de Rotinas de Departamento Pessoal', 80);

-- Administração, 3ª série | Plano 427 | página 35 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2023/02/Administracao-427_MTec_atualizado-em-16-11-22-2.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('administracao', 3, 'Língua Portuguesa', 160),
    ('administracao', 3, 'Língua Inglesa', 80),
    ('administracao', 3, 'Matemática', 160),
    ('administracao', 3, 'Sociologia', 40),
    ('administracao', 3, 'Administração da Produção e Serviços', 80),
    ('administracao', 3, 'Administração de Recursos Humanos', 80),
    ('administracao', 3, 'Administração Financeira e Orçamentária', 80),
    ('administracao', 3, 'Desenvolvimento de Modelos de Negócios', 80),
    ('administracao', 3, 'Estudos da Administração Pública', 80),
    ('administracao', 3, 'Estudos de Economia, Mercado e de Comércio Internacional', 80),
    ('administracao', 3, 'Ética e Cidadania organizacional', 40),
    ('administracao', 3, 'Planejamento e Desenvolvimento do Trabalho de Conclusão de Curso (TCC) em Administração', 80),
    ('administracao', 3, 'Processos Logísticos Empresariais', 80),
    ('administracao', 3, 'Tecnologia da Informação em Administração', 80);

-- Desenvolvimento de Sistemas, 1ª série | Plano 1062 | página 20 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Desenvolvimento-de-Sistemas-2026-MTec-1062-1a-serie.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('desenvolvimento-de-sistemas', 1, 'Língua Portuguesa', 80),
    ('desenvolvimento-de-sistemas', 1, 'Língua Inglesa', 80),
    ('desenvolvimento-de-sistemas', 1, 'Arte', 80),
    ('desenvolvimento-de-sistemas', 1, 'Educação Física', 80),
    ('desenvolvimento-de-sistemas', 1, 'Matemática', 80),
    ('desenvolvimento-de-sistemas', 1, 'Biologia', 80),
    ('desenvolvimento-de-sistemas', 1, 'Física', 80),
    ('desenvolvimento-de-sistemas', 1, 'Química', 80),
    ('desenvolvimento-de-sistemas', 1, 'História', 80),
    ('desenvolvimento-de-sistemas', 1, 'Geografia', 80),
    ('desenvolvimento-de-sistemas', 1, 'Programação Web I, II e III', 120),
    ('desenvolvimento-de-sistemas', 1, 'Projetos de Tecnologia de Informação e Comunicação', 80),
    ('desenvolvimento-de-sistemas', 1, 'Programação e Algoritmos', 120),
    ('desenvolvimento-de-sistemas', 1, 'Sistemas Embarcados e IoT', 80),
    ('desenvolvimento-de-sistemas', 1, 'Conduta Profissional e Relações de Trabalho', 40),
    ('desenvolvimento-de-sistemas', 1, 'Bancos de Dados I e II', 80);

-- Desenvolvimento de Sistemas, 2ª série | Plano Piloto 2025 | página 24 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/02/MTec-Desenvolvimento-de-Sistemas-Projeto-Piloto-2025.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('desenvolvimento-de-sistemas', 2, 'Língua Portuguesa', 120),
    ('desenvolvimento-de-sistemas', 2, 'Língua Inglesa', 80),
    ('desenvolvimento-de-sistemas', 2, 'Educação Física', 80),
    ('desenvolvimento-de-sistemas', 2, 'Matemática', 120),
    ('desenvolvimento-de-sistemas', 2, 'Física', 80),
    ('desenvolvimento-de-sistemas', 2, 'Química', 80),
    ('desenvolvimento-de-sistemas', 2, 'Biologia', 80),
    ('desenvolvimento-de-sistemas', 2, 'História', 80),
    ('desenvolvimento-de-sistemas', 2, 'Geografia', 80),
    ('desenvolvimento-de-sistemas', 2, 'Ética e Relações Humanas no Trabalho', 120),
    ('desenvolvimento-de-sistemas', 2, 'Bancos de Dados I e II', 80),
    ('desenvolvimento-de-sistemas', 2, 'Programação Web I, II e III', 80),
    ('desenvolvimento-de-sistemas', 2, 'Análise e Projeto de Sistemas', 40),
    ('desenvolvimento-de-sistemas', 2, 'Programação de Aplicativos Mobile I e II', 80);

-- Desenvolvimento de Sistemas, 3ª série | Plano 363 | página 29 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2023/02/Desenvolvimento-de-Sistemas-363_MTec_atualizado-em-22-11-22.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('desenvolvimento-de-sistemas', 3, 'Língua Portuguesa', 120),
    ('desenvolvimento-de-sistemas', 3, 'Língua Inglesa', 80),
    ('desenvolvimento-de-sistemas', 3, 'Matemática', 160),
    ('desenvolvimento-de-sistemas', 3, 'Biologia', 80),
    ('desenvolvimento-de-sistemas', 3, 'Geografia', 80),
    ('desenvolvimento-de-sistemas', 3, 'Filosofia', 80),
    ('desenvolvimento-de-sistemas', 3, 'Sociologia', 80),
    ('desenvolvimento-de-sistemas', 3, 'Programação Web I, II e III', 80),
    ('desenvolvimento-de-sistemas', 3, 'Programação de Aplicativos Mobile I e II', 80),
    ('desenvolvimento-de-sistemas', 3, 'Internet, Protocolos e Segurança de Sistemas da Informação', 80),
    ('desenvolvimento-de-sistemas', 3, 'Planejamento e Desenvolvimento do Trabalho de Conclusão de Curso (TCC) em Desenvolvimento de Sistemas', 120),
    ('desenvolvimento-de-sistemas', 3, 'Qualidade e Teste de Software', 80),
    ('desenvolvimento-de-sistemas', 3, 'Sistemas Embarcados', 80);

-- Marketing, 1ª série | Plano 1051 | página 20 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Marketing-2026-MTec-1051-1a-Serie-1.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('marketing', 1, 'Língua Portuguesa', 80),
    ('marketing', 1, 'Língua Inglesa', 80),
    ('marketing', 1, 'Arte', 80),
    ('marketing', 1, 'Educação Física', 80),
    ('marketing', 1, 'Matemática', 80),
    ('marketing', 1, 'Biologia', 80),
    ('marketing', 1, 'Física', 80),
    ('marketing', 1, 'Química', 80),
    ('marketing', 1, 'História', 80),
    ('marketing', 1, 'Geografia', 80),
    ('marketing', 1, 'Filosofia', 40),
    ('marketing', 1, 'Sociologia', 40),
    ('marketing', 1, 'Projetos de Tecnologia de Informação e Comunicação', 80),
    ('marketing', 1, 'Planejamento de Processos Comerciais e Técnicas de Negociação', 40),
    ('marketing', 1, 'Planejamento Estratégico de Marketing e Comunicação', 40),
    ('marketing', 1, 'Pesquisa de Mercado e Comportamento do Consumidor', 80),
    ('marketing', 1, 'Promoção de Vendas e Merchandising', 80);

-- Marketing, 2ª série | Plano 1051 | página 20 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Marketing-2026-MTec-1051-1a-Serie-1.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('marketing', 2, 'Língua Portuguesa', 120),
    ('marketing', 2, 'Língua Inglesa', 80),
    ('marketing', 2, 'Educação Física', 80),
    ('marketing', 2, 'Matemática', 120),
    ('marketing', 2, 'Biologia', 80),
    ('marketing', 2, 'Física', 80),
    ('marketing', 2, 'Química', 80),
    ('marketing', 2, 'História', 80),
    ('marketing', 2, 'Geografia', 80),
    ('marketing', 2, 'Filosofia', 40),
    ('marketing', 2, 'Sociologia', 40),
    ('marketing', 2, 'Design Digital e Estratégias de Comunicação Online', 80),
    ('marketing', 2, 'Legislação de Mercado', 40),
    ('marketing', 2, 'Modelos de Negócios e Administração de Compras e Vendas', 80),
    ('marketing', 2, 'Marketing Institucional e de Relacionamento', 80),
    ('marketing', 2, 'Conduta Profissional e Relações de Trabalho', 40);

-- Marketing, 3ª série | Plano 1051 | página 20 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Marketing-2026-MTec-1051-1a-Serie-1.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('marketing', 3, 'Língua Portuguesa', 160),
    ('marketing', 3, 'Língua Inglesa', 80),
    ('marketing', 3, 'Matemática', 160),
    ('marketing', 3, 'Biologia', 80),
    ('marketing', 3, 'Física', 80),
    ('marketing', 3, 'Química', 80),
    ('marketing', 3, 'História', 80),
    ('marketing', 3, 'Geografia', 80),
    ('marketing', 3, 'Filosofia', 40),
    ('marketing', 3, 'Sociologia', 40),
    ('marketing', 3, 'Administração Financeira Aplicada ao Marketing', 40),
    ('marketing', 3, 'Canais de Distribuição e Marketing de Varejo', 80),
    ('marketing', 3, 'Estratégias de Marketing', 40),
    ('marketing', 3, 'Plano de Marketing', 80),
    ('marketing', 3, 'Planejamento e Desenvolvimento do Trabalho de Conclusão de Curso (TCC) em Marketing', 80);

-- Meio Ambiente, 1ª série | Plano 1011 | página 21 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Meio-Ambiente-2026-MTec-1011-1a-serie.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('meio-ambiente', 1, 'Língua Portuguesa', 80),
    ('meio-ambiente', 1, 'Língua Inglesa', 80),
    ('meio-ambiente', 1, 'Arte', 80),
    ('meio-ambiente', 1, 'Educação Física', 80),
    ('meio-ambiente', 1, 'Matemática', 80),
    ('meio-ambiente', 1, 'Biologia', 80),
    ('meio-ambiente', 1, 'Física', 80),
    ('meio-ambiente', 1, 'Química', 80),
    ('meio-ambiente', 1, 'História', 80),
    ('meio-ambiente', 1, 'Geografia', 80),
    ('meio-ambiente', 1, 'Projetos de Tecnologia de Informação e Comunicação', 80),
    ('meio-ambiente', 1, 'Processos Ecossistêmicos', 80),
    ('meio-ambiente', 1, 'Práticas em Processos Geodinâmicos', 80),
    ('meio-ambiente', 1, 'Ecossistemas Aquáticos', 80),
    ('meio-ambiente', 1, 'Práticas em Química Ambiental', 80),
    ('meio-ambiente', 1, 'Conduta Profissional e Relações de Trabalho', 40),
    ('meio-ambiente', 1, 'Geotecnologias e Interpretação de Imagens', 80);

-- Meio Ambiente, 2ª série | Plano 497 | página 34 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2023/02/Meio-Ambiente-497_MTec_versao-provisoria_atualizado-em-18-11-22.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('meio-ambiente', 2, 'Língua Portuguesa', 120),
    ('meio-ambiente', 2, 'Língua Inglesa', 80),
    ('meio-ambiente', 2, 'Educação Física', 80),
    ('meio-ambiente', 2, 'Matemática', 120),
    ('meio-ambiente', 2, 'Física', 80),
    ('meio-ambiente', 2, 'Química', 80),
    ('meio-ambiente', 2, 'Biologia', 80),
    ('meio-ambiente', 2, 'História', 80),
    ('meio-ambiente', 2, 'Geografia', 80),
    ('meio-ambiente', 2, 'Análise Físico-Química da Água e Efluentes', 80),
    ('meio-ambiente', 2, 'Dinâmicas Atmosféricas e Recursos Energéticos', 40),
    ('meio-ambiente', 2, 'Ética e Cidadania Organizacional', 40),
    ('meio-ambiente', 2, 'Microbiologia dos Sistemas Naturais', 80),
    ('meio-ambiente', 2, 'Projetos em Educação Ambiental', 80),
    ('meio-ambiente', 2, 'Sistema de Tratamento de Águas e Resíduos', 80);

-- Meio Ambiente, 3ª série | Plano 497 | página 34 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2023/02/Meio-Ambiente-497_MTec_versao-provisoria_atualizado-em-18-11-22.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('meio-ambiente', 3, 'Língua Portuguesa', 160),
    ('meio-ambiente', 3, 'Língua Inglesa', 80),
    ('meio-ambiente', 3, 'Matemática', 160),
    ('meio-ambiente', 3, 'Física', 80),
    ('meio-ambiente', 3, 'Filosofia', 40),
    ('meio-ambiente', 3, 'Sociologia', 40),
    ('meio-ambiente', 3, 'Aplicativos Informatizados em Meio Ambiente', 80),
    ('meio-ambiente', 3, 'Avaliação de Riscos e Impacto Ambiental', 80),
    ('meio-ambiente', 3, 'Gestão e Qualidade Ambiental', 40),
    ('meio-ambiente', 3, 'Manejo de Sistemas Florestais', 80),
    ('meio-ambiente', 3, 'Planejamento e Desenvolvimento do Trabalho de Conclusão de Curso (TCC) em Meio Ambiente', 120),
    ('meio-ambiente', 3, 'Poluição Ambiental e Saúde Pública', 80),
    ('meio-ambiente', 3, 'Tecnologia de Processos', 80),
    ('meio-ambiente', 3, 'Uso, Ocupação e Conservação do Solo', 80);

-- Nutrição e Dietética, 1ª série | Plano 1014 | página 21 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/95/2025/12/Nutricao-e-Dietetica-2026-MTec-1014-1a-serie.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('nutricao-e-dietetica', 1, 'Língua Portuguesa', 80),
    ('nutricao-e-dietetica', 1, 'Língua Inglesa', 80),
    ('nutricao-e-dietetica', 1, 'Arte', 80),
    ('nutricao-e-dietetica', 1, 'Educação Física', 80),
    ('nutricao-e-dietetica', 1, 'Matemática', 80),
    ('nutricao-e-dietetica', 1, 'Biologia', 80),
    ('nutricao-e-dietetica', 1, 'Física', 80),
    ('nutricao-e-dietetica', 1, 'Química', 80),
    ('nutricao-e-dietetica', 1, 'História', 80),
    ('nutricao-e-dietetica', 1, 'Geografia', 80),
    ('nutricao-e-dietetica', 1, 'Estruturas e Rotinas em Serviço de Alimentação', 80),
    ('nutricao-e-dietetica', 1, 'Saúde e Segurança no Trabalho em Serviços de Alimentação', 40),
    ('nutricao-e-dietetica', 1, 'Boas Práticas em Serviços de Alimentação', 80),
    ('nutricao-e-dietetica', 1, 'Administração em Serviços de Alimentação', 40),
    ('nutricao-e-dietetica', 1, 'Diagnóstico da Alimentação Humana', 120),
    ('nutricao-e-dietetica', 1, 'Técnica Dietética I e II', 160);

-- Nutrição e Dietética, 2ª série | Plano 338 (referência CPS) | página 33 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/175/2026/02/Nutricao-e-Dietetica-2017-MTec-338.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('nutricao-e-dietetica', 2, 'Língua Portuguesa', 120),
    ('nutricao-e-dietetica', 2, 'Língua Inglesa', 80),
    ('nutricao-e-dietetica', 2, 'Educação Física', 80),
    ('nutricao-e-dietetica', 2, 'Matemática', 120),
    ('nutricao-e-dietetica', 2, 'Física', 80),
    ('nutricao-e-dietetica', 2, 'Química', 80),
    ('nutricao-e-dietetica', 2, 'Biologia', 80),
    ('nutricao-e-dietetica', 2, 'História', 80),
    ('nutricao-e-dietetica', 2, 'Geografia', 80),
    ('nutricao-e-dietetica', 2, 'Técnica Dietética I e II', 160),
    ('nutricao-e-dietetica', 2, 'Estrutura e Rotina em Serviços de Alimentação', 80),
    ('nutricao-e-dietetica', 2, 'Educação Nutricional em Saúde Pública', 80),
    ('nutricao-e-dietetica', 2, 'Planejamento Alimentar', 80);

-- Nutrição e Dietética, 3ª série | Plano 338 (referência CPS) | página 33 do PDF
-- https://bkpsitecpsnew.blob.core.windows.net/uploadsitecps/sites/175/2026/02/Nutricao-e-Dietetica-2017-MTec-338.pdf
INSERT INTO mtec_matriz_importacao (curso, serie, componente, horas_aula) VALUES
    ('nutricao-e-dietetica', 3, 'Língua Portuguesa', 160),
    ('nutricao-e-dietetica', 3, 'Língua Inglesa', 80),
    ('nutricao-e-dietetica', 3, 'Arte', 80),
    ('nutricao-e-dietetica', 3, 'Educação Física', 80),
    ('nutricao-e-dietetica', 3, 'Matemática', 160),
    ('nutricao-e-dietetica', 3, 'Filosofia', 40),
    ('nutricao-e-dietetica', 3, 'Sociologia', 40),
    ('nutricao-e-dietetica', 3, 'Aplicativos Informatizados', 80),
    ('nutricao-e-dietetica', 3, 'Tecnologia dos Alimentos e Rotulagem Nutricional', 80),
    ('nutricao-e-dietetica', 3, 'Gestão Profissional em Unidades de Alimentação', 80),
    ('nutricao-e-dietetica', 3, 'Gestão de Serviços Especiais de Alimentação e Nutrição', 120),
    ('nutricao-e-dietetica', 3, 'Terapia Nutricional e Gastronomia Hospitalar', 120),
    ('nutricao-e-dietetica', 3, 'Planejamento e Desenvolvimento do Trabalho de Conclusão de Curso (TCC) em Nutrição e Dietética', 80);

UPDATE mtec_matriz_importacao
SET componente = replace(componente, 'Trabalho de Conclusão de Curso (TCC)', 'TCC')
WHERE char_length(componente) > 100;

LOCK TABLE componentes_curriculares IN SHARE ROW EXCLUSIVE MODE;

INSERT INTO componentes_curriculares (name)
SELECT MIN(importado.componente)
FROM mtec_matriz_importacao importado
WHERE NOT EXISTS (
    SELECT 1 FROM componentes_curriculares existente
    WHERE lower(btrim(existente.name)) = lower(importado.componente)
)
GROUP BY lower(importado.componente);

INSERT INTO curriculo_mtec (curso, serie, componente_id)
SELECT importado.curso, importado.serie, MIN(componente.id)
FROM mtec_matriz_importacao importado
JOIN componentes_curriculares componente
    ON lower(btrim(componente.name)) = lower(importado.componente)
GROUP BY importado.curso, importado.serie, lower(importado.componente);
