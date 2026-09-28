package com.kripta.controller;

import com.kripta.model.User;
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

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class UserControllerTest {

    private static final String EMAIL = "joao@email.com";
    private static final String SENHA = "senha123";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private User usuario;
    private String token;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        usuario = userRepository.save(new User("Joao Silva", EMAIL, passwordEncoder.encode(SENHA), User.UserType.USUARIO));
        token = jwtService.generateToken(usuario);
    }

    private String bearer() {
        return "Bearer " + token;
    }

    @Test
    void deveRetornarDadosDoUsuarioLogado() throws Exception {
        mockMvc.perform(get("/api/users/me").header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(usuario.getId().intValue()))
                .andExpect(jsonPath("$.nome").value("Joao Silva"))
                .andExpect(jsonPath("$.email").value(EMAIL))
                .andExpect(jsonPath("$.tipo").value("USUARIO"));
    }

    @Test
    void deveRetornar401SemToken() throws Exception {
        mockMvc.perform(get("/api/users/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("NAO_AUTENTICADO"));
    }

    @Test
    void deveAtualizarPerfil() throws Exception {
        String payload = """
                {
                  "nome": "Joao Atualizado",
                  "email": "novo@email.com"
                }
                """;

        mockMvc.perform(put("/api/users/me")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Joao Atualizado"))
                .andExpect(jsonPath("$.email").value("novo@email.com"));
    }

    @Test
    void deveRetornar400QuandoPerfilInvalido() throws Exception {
        String payload = """
                {
                  "nome": "",
                  "email": "email-invalido"
                }
                """;

        mockMvc.perform(put("/api/users/me")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDACAO"))
                .andExpect(jsonPath("$.errors.nome").exists())
                .andExpect(jsonPath("$.errors.email").exists());
    }

    @Test
    void deveRetornar409QuandoEmailJaEstaEmUso() throws Exception {
        userRepository.save(new User("Outro", "existente@email.com", passwordEncoder.encode("x"), User.UserType.USUARIO));

        String payload = """
                {
                  "nome": "Joao",
                  "email": "existente@email.com"
                }
                """;

        mockMvc.perform(put("/api/users/me")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("EMAIL_JA_CADASTRADO"));
    }

    @Test
    void deveTrocarSenha() throws Exception {
        String payload = """
                {
                  "senhaAtual": "senha123",
                  "novaSenha": "novaSenha456"
                }
                """;

        mockMvc.perform(put("/api/users/me/senha")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isNoContent());

        User salvo = userRepository.findByEmail(EMAIL).orElseThrow();
        assertTrue(passwordEncoder.matches("novaSenha456", salvo.getSenha()));
    }

    @Test
    void deveRetornar400QuandoSenhaAtualIncorreta() throws Exception {
        String payload = """
                {
                  "senhaAtual": "senhaErrada",
                  "novaSenha": "novaSenha456"
                }
                """;

        mockMvc.perform(put("/api/users/me/senha")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("SENHA_ATUAL_INCORRETA"));
    }

    @Test
    void deveRetornar400QuandoNovaSenhaCurta() throws Exception {
        String payload = """
                {
                  "senhaAtual": "senha123",
                  "novaSenha": "123"
                }
                """;

        mockMvc.perform(put("/api/users/me/senha")
                        .header(HttpHeaders.AUTHORIZATION, bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDACAO"))
                .andExpect(jsonPath("$.errors.novaSenha").exists());
    }

    @Test
    void deveDeletarConta() throws Exception {
        mockMvc.perform(delete("/api/users/me")
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isNoContent());

        assertTrue(userRepository.findByEmail(EMAIL).isEmpty());

        String login = """
                {
                  "email": "joao@email.com",
                  "senha": "senha123"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(login))
                .andExpect(status().isUnauthorized());
    }
}