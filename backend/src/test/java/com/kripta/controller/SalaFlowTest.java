package com.kripta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kripta.model.SalaAluno;
import com.kripta.model.User;
import com.kripta.repository.SalaAlunoRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class SalaFlowTest {
    @Autowired MockMvc api;
    @Autowired ObjectMapper json;
    @Autowired JwtService jwt;
    @Autowired UserRepository usuarios;
    @Autowired SalaAlunoRepository vinculos;
    @Autowired PasswordEncoder passwords;

    @Test
    void autenticaVinculaEEntregaAtividadesMantendoProgressoIndividual() throws Exception {
        var professor = token(user(User.UserType.PROFESSOR));
        var outroProfessor = token(user(User.UserType.PROFESSOR));
        var aluno = user(User.UserType.ALUNO);
        var outroAluno = token(user(User.UserType.ALUNO));
        var sala = criar(professor, "Desenvolvimento de Sistemas");
        var outraSala = criar(outroProfessor, "Marketing");

        publicar(outroProfessor, sala.id(), "Publicação indevida").andExpect(status().isNotFound());
        publicar(professor, sala.id(), "Trabalho inicial").andExpect(status().isCreated());
        api.perform(get("/api/salas").header("Authorization", outroProfessor))
                .andExpect(jsonPath("$[0].nome").value("Marketing"));

        var request = Map.of("email", aluno.getEmail(), "senha", "teste-curso-2026", "codigoSala", sala.codigo());
        api.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsBytes(request)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.token").isNotEmpty());

        var alunoToken = token(aluno);
        entrar(alunoToken, sala.codigo()).andExpect(status().isOk()).andExpect(jsonPath("$.alunos").value(1));
        entrar(alunoToken, outraSala.codigo()).andExpect(status().isConflict());
        entrar(outroAluno, sala.codigo()).andExpect(status().isOk()).andExpect(jsonPath("$.alunos").value(2));
        publicar(professor, sala.id(), "Segundo trabalho").andExpect(status().isCreated());
        api.perform(get("/api/tarefas").header("Authorization", outroAluno))
                .andExpect(jsonPath("$", hasSize(2))).andExpect(jsonPath("$[0].title").value("Segundo trabalho"));

        var response = api.perform(get("/api/tarefas").header("Authorization", alunoToken))
                .andExpect(jsonPath("$", hasSize(2))).andReturn();
        long id = json.readTree(response.getResponse().getContentAsByteArray()).get(0).get("id").asLong();
        api.perform(delete("/api/tarefas/" + id).header("Authorization", alunoToken))
                .andExpect(status().isForbidden());
        api.perform(patch("/api/tarefas/" + id + "/concluir").header("Authorization", outroAluno))
                .andExpect(status().isNotFound());
        api.perform(patch("/api/tarefas/" + id + "/concluir").header("Authorization", alunoToken))
                .andExpect(jsonPath("$.completed").value(true))
                .andExpect(jsonPath("$.gamification.xpEarned").value(25));
        api.perform(get("/api/tarefas").header("Authorization", outroAluno))
                .andExpect(jsonPath("$[0].completed").value(false));
    }

    @Test
    void permiteQuadragesimoAlunoERecusaProximo() throws Exception {
        var sala = criar(token(user(User.UserType.PROFESSOR)), "Turma cheia");
        for (int i = 0; i < 39; i++) {
            var vinculo = new SalaAluno();
            vinculo.salaId = sala.id();
            vinculo.alunoId = user(User.UserType.ALUNO, "senha-ja-codificada").getId();
            vinculos.save(vinculo);
        }
        var ultimo = token(user(User.UserType.ALUNO));
        entrar(ultimo, sala.codigo()).andExpect(status().isOk()).andExpect(jsonPath("$.alunos").value(40));
        entrar(ultimo, sala.codigo()).andExpect(status().isOk()).andExpect(jsonPath("$.alunos").value(40));
        entrar(token(user(User.UserType.ALUNO)), sala.codigo())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Esta sala já atingiu o limite de 40 alunos."));
    }

    private record Sala(Long id, String codigo) {}

    private Sala criar(String professor, String nome) throws Exception {
        var response = api.perform(post("/api/salas").header("Authorization", professor)
                        .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(Map.of("nome", nome))))
                .andExpect(status().isCreated()).andReturn();
        var item = json.readTree(response.getResponse().getContentAsByteArray());
        return new Sala(item.get("id").asLong(), item.get("codigo").asText());
    }

    private org.springframework.test.web.servlet.ResultActions entrar(String aluno, String codigo) throws Exception {
        return api.perform(post("/api/salas/entrar").header("Authorization", aluno)
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(Map.of("codigo", codigo))));
    }

    private org.springframework.test.web.servlet.ResultActions publicar(String professor, Long id, String title) throws Exception {
        return api.perform(post("/api/salas/" + id + "/atividades").header("Authorization", professor)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsBytes(Map.of("titulo", title, "prazo", "2030-01-01T14:00:00Z"))));
    }

    private User user(User.UserType tipo) {
        return user(tipo, passwords.encode("teste-curso-2026"));
    }

    private User user(User.UserType tipo, String senha) {
        return usuarios.save(new User("Pessoa de teste", UUID.randomUUID() + "@example.test", senha, tipo));
    }

    private String token(User user) {
        return "Bearer " + jwt.generateToken(user);
    }
}
