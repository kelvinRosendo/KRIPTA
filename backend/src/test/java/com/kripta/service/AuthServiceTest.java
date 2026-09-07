package com.kripta.service;

import com.kripta.dto.RegisterRequest;
import com.kripta.dto.RegisterResponse;
import com.kripta.exception.DuplicateEmailException;
import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    private AuthService authService;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, encoder);
    }

    @Test
    void deveRegistrarUsuarioComSenhaCriptografada() {
        when(userRepository.existsByEmail("joao@email.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(1L);
            return u;
        });

        RegisterRequest request = new RegisterRequest("Joao", "joao@email.com", "senha123", User.UserType.USUARIO);

        RegisterResponse response = authService.register(request);

        assertNotNull(response.getId());
        assertEquals(1L, response.getId());
        assertEquals("Joao", response.getNome());
        assertEquals("joao@email.com", response.getEmail());
        assertEquals(User.UserType.USUARIO, response.getTipo());

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User salvo = captor.getValue();
        assertNotEquals("senha123", salvo.getSenha());
        assertTrue(encoder.matches("senha123", salvo.getSenha()));
    }

    @Test
    void deveNormalizarEmailAntesDeSalvar() {
        when(userRepository.existsByEmail("maria@email.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(2L);
            return u;
        });

        RegisterRequest request = new RegisterRequest("Maria", "  MARIA@email.com  ", "senha456", User.UserType.ADMIN);

        RegisterResponse response = authService.register(request);

        assertEquals("maria@email.com", response.getEmail());

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        assertEquals("maria@email.com", captor.getValue().getEmail());
    }

    @Test
    void deveLancarExcecaoQuandoEmailJaCadastrado() {
        when(userRepository.existsByEmail("joao@email.com")).thenReturn(true);

        RegisterRequest request = new RegisterRequest("Joao", "joao@email.com", "senha123", User.UserType.USUARIO);

        assertThrows(DuplicateEmailException.class, () -> authService.register(request));
        verify(userRepository, never()).save(any(User.class));
    }
}