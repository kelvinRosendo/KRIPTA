package com.kripta.service;

import com.kripta.dto.LoginRequest;
import com.kripta.dto.LoginResponse;
import com.kripta.dto.RegisterRequest;
import com.kripta.dto.RegisterResponse;
import com.kripta.exception.DuplicateEmailException;
import com.kripta.exception.InvalidCredentialsException;
import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import com.kripta.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private JwtService jwtService;

    private AuthService authService;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, encoder, authenticationManager, jwtService);
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

    @Test
    void deveRealizarLoginEGerarToken() {
        User user = new User("Joao", "joao@email.com", encoder.encode("senha123"), User.UserType.USUARIO);
        user.setId(1L);

        when(userRepository.findByEmail("joao@email.com")).thenReturn(Optional.of(user));
        when(jwtService.generateToken(user)).thenReturn("token-gerado");
        when(jwtService.getExpirationMs()).thenReturn(86400000L);

        LoginRequest request = new LoginRequest(" Joao@EMAIL.com ", "senha123");

        LoginResponse response = authService.login(request);

        assertEquals("token-gerado", response.getToken());
        assertEquals("Bearer", response.getTokenType());
        assertEquals(86400L, response.getExpiresIn());
        assertEquals(1L, response.getId());
        assertEquals("joao@email.com", response.getEmail());
        assertEquals(User.UserType.USUARIO, response.getTipo());

        ArgumentCaptor<UsernamePasswordAuthenticationToken> captor =
                ArgumentCaptor.forClass(UsernamePasswordAuthenticationToken.class);
        verify(authenticationManager).authenticate(captor.capture());
        assertEquals("joao@email.com", captor.getValue().getPrincipal());
    }

    @Test
    void deveLancarExcecaoQuandoSenhaIncorreta() {
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenThrow(new BadCredentialsException("Senha invalida"));

        LoginRequest request = new LoginRequest("joao@email.com", "senhaErrada");

        assertThrows(InvalidCredentialsException.class, () -> authService.login(request));
        verify(jwtService, never()).generateToken(any(User.class));
    }
}