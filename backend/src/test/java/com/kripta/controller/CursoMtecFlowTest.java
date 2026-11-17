package com.kripta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kripta.model.ComponenteCurricular;
import com.kripta.model.CurriculoMtec;
import com.kripta.model.User;
import com.kripta.repository.ComponenteRepository;
import com.kripta.repository.CurriculoMtecRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class CursoMtecFlowTest {
    @Autowired MockMvc api;
    @Autowired ObjectMapper json;
    @Autowired JwtService jwt;
    @Autowired UserRepository usuarios;
    @Autowired ComponenteRepository componentes;
    @Autowired CurriculoMtecRepository curriculos;

    @Test
    void selecionaTurmaSemDuplicarOuRemoverMateriasEAtividades() throws Exception {
        membro("marketing", "Matemática");
        membro("marketing", "Plano de Marketing");
        membro("administracao", "Matemática");
        membro("administracao", "Gestão Empresarial");
        var aluno = token(User.UserType.ALUNO);
        var outro = token(User.UserType.ALUNO);

        var response = api.perform(post("/api/disciplinas").header(HttpHeaders.AUTHORIZATION, aluno)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nome\":\"matemática\",\"cor\":\"#123456\"}"))
                .andExpect(status().isCreated()).andReturn();
        long disciplina = json.readTree(response.getResponse().getContentAsByteArray()).get("id").asLong();
        api.perform(put("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"curso\":\"marketing\",\"serie\":1}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.selecao.disciplinaIds", hasSize(2)));
        api.perform(put("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"curso\":\"marketing\",\"serie\":1}"))
                .andExpect(status().isOk());
        api.perform(get("/api/disciplinas").header(HttpHeaders.AUTHORIZATION, aluno)).andExpect(jsonPath("$", hasSize(2)));
        api.perform(get("/api/disciplinas/" + disciplina).header(HttpHeaders.AUTHORIZATION, aluno))
                .andExpect(jsonPath("$.cor").value("#123456"))
                .andExpect(jsonPath("$.componenteId").isNumber());

        api.perform(post("/api/tarefas").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"Lista de exercícios","dueDate":"2026-11-20T21:00:00Z",
                                 "priority":"MEDIUM","subjectId":%d}
                                """.formatted(disciplina)))
                .andExpect(status().isCreated());
        api.perform(put("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"curso\":\"administracao\",\"serie\":1}"))
                .andExpect(status().isOk());
        api.perform(get("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno))
                .andExpect(jsonPath("$.selecao.curso").value("administracao"))
                .andExpect(jsonPath("$.selecao.disciplinaIds", hasSize(2)));
        api.perform(get("/api/disciplinas").header(HttpHeaders.AUTHORIZATION, aluno)).andExpect(jsonPath("$", hasSize(3)));
        api.perform(get("/api/tarefas").param("subjectId", Long.toString(disciplina)).header(HttpHeaders.AUTHORIZATION, aluno))
                .andExpect(jsonPath("$[0].title").value("Lista de exercícios"))
                .andExpect(jsonPath("$[0].dueDate").value("2026-11-20T21:00:00Z"));
        api.perform(get("/api/disciplinas").header(HttpHeaders.AUTHORIZATION, outro)).andExpect(jsonPath("$", hasSize(0)));
        api.perform(get("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, outro)).andExpect(jsonPath("$.selecao").isEmpty());
    }

    @Test
    void loginSalvaTurmaSomenteDepoisDeAutenticar() throws Exception {
        membro("marketing", "Planejamento");
        api.perform(get("/api/curso-mtec/opcoes")).andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(5)));
        api.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"nome":"Aluno M-Tec","email":"login-mtec@example.test",
                                 "senha":"senha-de-teste","tipo":"ALUNO","rm":"2026001"}
                                """))
                .andExpect(status().isCreated());
        api.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"login-mtec@example.test","senha":"incorreta",
                                 "cursoMtec":"marketing","serieMtec":1}
                                """))
                .andExpect(status().isUnauthorized());
        var account = usuarios.findByEmail("login-mtec@example.test").orElseThrow();
        api.perform(get("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, "Bearer " + jwt.generateToken(account)))
                .andExpect(jsonPath("$.selecao").isEmpty());

        var login = api.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"login-mtec@example.test","senha":"senha-de-teste",
                                 "cursoMtec":"marketing","serieMtec":1}
                                """))
                .andExpect(status().isOk()).andReturn();
        var token = "Bearer " + json.readTree(login.getResponse().getContentAsByteArray()).get("token").asText();
        api.perform(get("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.selecao.curso").value("marketing"));
        api.perform(get("/api/disciplinas").header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$[0].nome").value("Planejamento"));
    }

    @Test
    void rejeitaSerieInvalidaECursoDesconhecidoEProtegeSelecaoDoProfessor() throws Exception {
        var aluno = token(User.UserType.ALUNO);
        api.perform(put("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"curso\":\"marketing\",\"serie\":4}"))
                .andExpect(status().isBadRequest());
        api.perform(put("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, aluno).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"curso\":\"curso-inexistente\",\"serie\":1}"))
                .andExpect(status().isNotFound());
        api.perform(get("/api/curso-mtec").header(HttpHeaders.AUTHORIZATION, token(User.UserType.PROFESSOR)))
                .andExpect(status().isForbidden());
    }

    private void membro(String curso, String nome) {
        var componente = new ComponenteCurricular();
        componente.name = nome;
        curriculos.save(new CurriculoMtec(curso, 1, componentes.save(componente)));
    }

    private String token(User.UserType tipo) {
        return "Bearer " + jwt.generateToken(usuarios.save(new User("Teste M-Tec", UUID.randomUUID() + "@example.test", "senha", tipo)));
    }
}
