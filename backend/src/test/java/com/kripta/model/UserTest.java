package com.kripta.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class UserTest {

    @Test
    void deveCriarUserComConstrutorCompleto() {
        User user = new User("Joao", "joao@email.com", "senha123", User.UserType.USUARIO);

        assertEquals("Joao", user.getNome());
        assertEquals("joao@email.com", user.getEmail());
        assertEquals("senha123", user.getSenha());
        assertEquals(User.UserType.USUARIO, user.getTipo());
        assertNull(user.getId());
    }

    @Test
    void deveCriarUserAdmin() {
        User admin = new User("Admin", "admin@email.com", "admin123", User.UserType.ADMIN);

        assertEquals(User.UserType.ADMIN, admin.getTipo());
    }

    @Test
    void devePermitirSetters() {
        User user = new User("Nome", "old@email.com", "senha", User.UserType.USUARIO);

        user.setNome("Novo Nome");
        user.setEmail("novo@email.com");
        user.setSenha("novaSenha");
        user.setTipo(User.UserType.ADMIN);
        user.setId(1L);

        assertEquals("Novo Nome", user.getNome());
        assertEquals("novo@email.com", user.getEmail());
        assertEquals("novaSenha", user.getSenha());
        assertEquals(User.UserType.ADMIN, user.getTipo());
        assertEquals(1L, user.getId());
    }

    @Test
    void deveTerConstrutorVazio() {
        User user = new User();

        assertNull(user.getId());
        assertNull(user.getNome());
        assertNull(user.getEmail());
        assertNull(user.getSenha());
        assertNull(user.getTipo());
    }
}
