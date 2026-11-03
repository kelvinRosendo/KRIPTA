package com.kripta.controller;

import com.kripta.model.Disciplina;
import com.kripta.model.User;
import com.kripta.repository.DisciplinaRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class DisciplinaControllerTest {

    private static final String EMAIL = "joao@email.com";
    private static final String SENHA = "senha123";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DisciplinaRepository disciplinaRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private User usuario;
    private String token;

    @BeforeEach
    void setUp() {
        disciplinaRepository.deleteAll();
        userRepository.deleteAll();
        usuario = userRepository.save(new User("Joao Silva", EMAIL, passwordEncoder.encode(SENHA), User.UserType.USUARIO));
        token = jwtService.generateToken(usuario);
    }

    private String bearer() {
        return "Bearer " + token;
    }

    @Test
    void deveCriarDisciplina() throws Exception {
        String payload = """
                {
                  "nome": "Matematica",
                  "cor": "#FF5733"
                }
                """;

        mockMvc.perform(post("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.nome").value("Matematica"))
                .andExpect(jsonPath("$.cor").value("#FF5733"));
    }

    @Test
    void deveUsarCorPadraoQuandoNaoInformada() throws Exception {
        String payload = """
                {
                  "nome": "Portugues"
                }
                """;

        mockMvc.perform(post("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.cor").value("#3B82F6"));
    }

    @Test
    void deveRetornar400QuandoNomeVazio() throws Exception {
        String payload = """
                {
                  "nome": "",
                  "cor": "#FF5733"
                }
                """;

        mockMvc.perform(post("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDACAO"))
                .andExpect(jsonPath("$.errors.nome").exists());
    }

    @Test
    void deveRetornar400QuandoCorInvalida() throws Exception {
        String payload = """
                {
                  "nome": "Matematica",
                  "cor": "vermelho"
                }
                """;

        mockMvc.perform(post("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDACAO"))
                .andExpect(jsonPath("$.errors.cor").exists());
    }

    @Test
    void deveRetornar409QuandoDisciplinaJaExiste() throws Exception {
        disciplinaRepository.save(new Disciplina(usuario, "Matematica", "#FF5733"));

        String payload = """
                {
                  "nome": "matematica",
                  "cor": "#FF5733"
                }
                """;

        mockMvc.perform(post("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("DISCIPLINA_JA_CADASTRADA"));
    }

    @Test
    void deveRetornar401SemToken() throws Exception {
        mockMvc.perform(get("/api/disciplinas"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("NAO_AUTENTICADO"));
    }

    @Test
    void deveListarDisciplinas() throws Exception {
        disciplinaRepository.save(new Disciplina(usuario, "Portugues", "#3B82F6"));
        disciplinaRepository.save(new Disciplina(usuario, "Matematica", "#FF5733"));

        mockMvc.perform(get("/api/disciplinas")
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].nome").value("Matematica"))
                .andExpect(jsonPath("$[1].nome").value("Portugues"));
    }

    @Test
    void deveBuscarDisciplina() throws Exception {
        Disciplina disciplina = disciplinaRepository.save(new Disciplina(usuario, "Fisica", "#22C55E"));

        mockMvc.perform(get("/api/disciplinas/{id}", disciplina.getId())
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Fisica"))
                .andExpect(jsonPath("$.cor").value("#22C55E"));
    }

    @Test
    void deveRetornar404QuandoDisciplinaDeOutroUsuario() throws Exception {
        User outro = userRepository.save(new User("Maria", "maria@email.com", passwordEncoder.encode("x"), User.UserType.USUARIO));
        Disciplina disciplina = disciplinaRepository.save(new Disciplina(outro, "Quimica", "#3B82F6"));

        mockMvc.perform(get("/api/disciplinas/{id}", disciplina.getId())
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("DISCIPLINA_NAO_ENCONTRADA"));
    }

    @Test
    void deveAtualizarDisciplina() throws Exception {
        Disciplina disciplina = disciplinaRepository.save(new Disciplina(usuario, "Matematica", "#FF5733"));

        String payload = """
                {
                  "nome": "Calculo",
                  "cor": "#22C55E"
                }
                """;

        mockMvc.perform(put("/api/disciplinas/{id}", disciplina.getId())
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Calculo"))
                .andExpect(jsonPath("$.cor").value("#22C55E"));
    }

    @Test
    void deveExcluirDisciplina() throws Exception {
        Disciplina disciplina = disciplinaRepository.save(new Disciplina(usuario, "Matematica", "#FF5733"));

        mockMvc.perform(delete("/api/disciplinas/{id}", disciplina.getId())
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isNoContent());
    }
}