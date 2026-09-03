package com.kripta.repository;

import com.kripta.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void deveSalvarEBuscarUser() {
        User user = new User("Joao Silva", "joao@email.com", "senha123", User.UserType.USUARIO);
        User salvo = userRepository.save(user);

        assertNotNull(salvo.getId());
        assertEquals("Joao Silva", salvo.getNome());
        assertEquals("joao@email.com", salvo.getEmail());
    }

    @Test
    void deveSalvarUserAdmin() {
        User admin = new User("Admin", "admin@email.com", "admin123", User.UserType.ADMIN);
        User salvo = userRepository.save(admin);

        assertEquals(User.UserType.ADMIN, salvo.getTipo());
    }

    @Test
    void deveBuscarUserPorEmail() {
        User user = new User("Maria", "maria@email.com", "senha456", User.UserType.USUARIO);
        userRepository.save(user);

        Optional<User> encontrado = userRepository.findByEmail("maria@email.com");

        assertTrue(encontrado.isPresent());
        assertEquals("Maria", encontrado.get().getNome());
    }

    @Test
    void deveRetornarVazioParaEmailInexistente() {
        Optional<User> encontrado = userRepository.findByEmail("naoexiste@email.com");

        assertTrue(encontrado.isEmpty());
    }

    @Test
    void deveVerificarExistenciaDeEmail() {
        User user = new User("Pedro", "pedro@email.com", "senha789", User.UserType.USUARIO);
        userRepository.save(user);

        assertTrue(userRepository.existsByEmail("pedro@email.com"));
        assertFalse(userRepository.existsByEmail("outro@email.com"));
    }

    @Test
    void deveListarTodosUsers() {
        userRepository.save(new User("User1", "u1@email.com", "s1", User.UserType.USUARIO));
        userRepository.save(new User("User2", "u2@email.com", "s2", User.UserType.ADMIN));

        List<User> users = userRepository.findAll();

        assertEquals(2, users.size());
    }

    @Test
    void deveDeletarUser() {
        User user = new User("Deletar", "deletar@email.com", "senha", User.UserType.USUARIO);
        User salvo = userRepository.save(user);

        userRepository.deleteById(salvo.getId());

        assertFalse(userRepository.existsById(salvo.getId()));
    }

    @Test
    void deveLancarExcecaoAoSalvarEmailDuplicado() {
        userRepository.save(new User("User1", "duplicado@email.com", "s1", User.UserType.USUARIO));

        assertThrows(Exception.class, () -> {
            userRepository.save(new User("User2", "duplicado@email.com", "s2", User.UserType.USUARIO));
            userRepository.flush();
        });
    }
}
