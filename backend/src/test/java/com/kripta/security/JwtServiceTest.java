package com.kripta.security;

import com.kripta.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {

    private static final String SECRET = "chave-de-teste-kripta-0123456789abcdef0123456789abcdef";
    private static final String OUTRO_SECRET = "outra-chave-de-teste-9876543210fedcba9876543210fedcba";

    private JwtService jwtService;
    private User user;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService(SECRET, 3600000L);

        user = new User("Joao Silva", "joao@email.com", "senha123", User.UserType.USUARIO);
        user.setId(1L);
    }

    @Test
    void deveGerarTokenComIdComoSubject() {
        String token = jwtService.generateToken(user);

        assertNotNull(token);
        assertEquals(3, token.split("\\.").length);
        assertEquals("1", jwtService.extractSubject(token).orElseThrow());
    }

    @Test
    void deveConsiderarTokenValidoParaODonoDoToken() {
        String token = jwtService.generateToken(user);

        assertTrue(jwtService.isTokenValid(token, "1"));
        assertTrue(jwtService.isTokenValid(token, String.valueOf(user.getId())));
    }

    @Test
    void deveRejeitarTokenDeOutroUsuario() {
        String token = jwtService.generateToken(user);

        assertFalse(jwtService.isTokenValid(token, "2"));
    }

    @Test
    void deveRejeitarTokenAssinadoComOutraChave() {
        String tokenDeOutro = new JwtService(OUTRO_SECRET, 3600000L).generateToken(user);

        assertTrue(jwtService.extractSubject(tokenDeOutro).isEmpty());
        assertFalse(jwtService.isTokenValid(tokenDeOutro, "1"));
    }

    @Test
    void deveRejeitarTokenExpirado() {
        JwtService expirado = new JwtService(SECRET, -1000L);

        String token = expirado.generateToken(user);

        assertTrue(expirado.extractSubject(token).isEmpty());
    }

    @Test
    void deveRejeitarTokenInvalidoOuVazio() {
        assertTrue(jwtService.extractSubject("token.invalido.aqui").isEmpty());
        assertTrue(jwtService.extractSubject("").isEmpty());
        assertFalse(jwtService.isTokenValid("token.invalido.aqui", "1"));
    }

    @Test
    void deveExporTempoDeExpiracaoConfigurado() {
        assertEquals(3600000L, jwtService.getExpirationMs());
    }
}