package com.kripta.controller;

import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.greaterThan;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void deveRegistrarUsuarioComSucesso() throws Exception {
        String payload = """
                {
                  "nome": "Joao Silva",
                  "email": "joao@email.com",
                  "senha": "senha123",
                  "tipo": "ALUNO",
                  "rm": "12345"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(greaterThan(0)))
                .andExpect(jsonPath("$.nome").value("Joao Silva"))
                .andExpect(jsonPath("$.email").value("joao@email.com"))
                .andExpect(jsonPath("$.tipo").value("ALUNO"));

        User salvo = userRepository.findByEmail("joao@email.com").orElseThrow();
        assertTrue(passwordEncoder.matches("senha123", salvo.getSenha()));
    }

    @Test
    void deveRetornar400QuandoDadosInvalidos() throws Exception {
        String payload = """
                {
                  "nome": "",
                  "email": "email-invalido",
                  "senha": "123",
                  "tipo": "ALUNO",
                  "rm": "12345"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value("error"))
                .andExpect(jsonPath("$.error").value("VALIDACAO"))
                .andExpect(jsonPath("$.errors.nome").exists())
                .andExpect(jsonPath("$.errors.email").exists())
                .andExpect(jsonPath("$.errors.senha").exists());
    }

    @Test
    void deveRetornar409QuandoEmailJaCadastrado() throws Exception {
        String payload = """
                {
                  "nome": "Joao Silva",
                  "email": "duplicado@email.com",
                  "senha": "senha123",
                  "tipo": "ALUNO",
                  "rm": "12345"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("EMAIL_JA_CADASTRADO"));
    }

    @Test
    void deveValidarPerfisAcademicos() throws Exception {
        for (String tipo : new String[]{"ADMIN", "ALUNO", "USUARIO"}) {
            mockMvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"nome\":\"Teste\",\"email\":\"teste@email.com\",\"senha\":\"senha123\",\"tipo\":\"" + tipo + "\"}"))
                .andExpect(status().isBadRequest());
        }
        mockMvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
            .content("{\"nome\":\"Aluno\",\"email\":\"aluno@email.com\",\"senha\":\"senha123\",\"tipo\":\"ALUNO\",\"rm\":\"12345\"}"))
            .andExpect(status().isCreated());
        var result = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
            .content("{\"email\":\"aluno@email.com\",\"senha\":\"senha123\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.tipo").value("ALUNO"))
            .andReturn();
        String token = new com.fasterxml.jackson.databind.ObjectMapper().readTree(result.getResponse().getContentAsString()).get("token").asText();
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/users/me").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.email").value("aluno@email.com"));
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
            .content("{\"email\":\"aluno@email.com\",\"senha\":\"errada\"}"))
            .andExpect(status().isUnauthorized());
    }

    @Autowired
    private com.kripta.security.JwtService jwtService;

    @Test
    void permissaoVemDoServidorERevogacaoValeNoMesmoToken() throws Exception {
        var teacher = userRepository.save(new User("Professor", "prof@example.com", passwordEncoder.encode("senha123"), User.UserType.PROFESSOR));
        String token = jwtService.generateToken(teacher);
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/users/me").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.podeAprovar").value(false));
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch("/api/conteudos/1/aprovar").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        teacher.setPodeAprovar(true);
        userRepository.saveAndFlush(teacher);
        assertTrue(new com.kripta.security.UserPrincipal(teacher).getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("APROVAR_CONTEUDO")));
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/users/me").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.podeAprovar").value(true));
        teacher.setPodeAprovar(false);
        userRepository.saveAndFlush(teacher);
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch("/api/conteudos/1/aprovar").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void cadastroNaoPodeConcederPermissao() throws Exception {
        mockMvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
            .content("{\"nome\":\"Professor\",\"email\":\"novo@example.com\",\"senha\":\"senha123\",\"tipo\":\"PROFESSOR\",\"authorized\":true,\"podeAprovar\":true}"))
            .andExpect(status().isCreated());
        org.junit.jupiter.api.Assertions.assertFalse(userRepository.findByEmail("novo@example.com").orElseThrow().isPodeAprovar());
    }

    @Test
    void kaiExigeLoginValidaMensagemEInformaAusenciaDeProvedor() throws Exception {
        mockMvc.perform(post("/api/ai/chat").contentType(MediaType.APPLICATION_JSON).content("{\"message\":\"Olá\"}"))
            .andExpect(status().isUnauthorized());
        var user = userRepository.save(new User("Aluno", "kai@example.com", passwordEncoder.encode("senha123"), User.UserType.USUARIO));
        String token = jwtService.generateToken(user);
        mockMvc.perform(post("/api/ai/chat").header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content("{\"message\":\" \"}"))
            .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/ai/chat").header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content("{\"message\":\"Olá\"}"))
            .andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.error").value("IA_INDISPONIVEL"));
    }
}
