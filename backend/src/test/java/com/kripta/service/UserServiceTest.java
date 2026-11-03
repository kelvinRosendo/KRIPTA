package com.kripta.service;

import com.kripta.dto.ChangePasswordRequest;
import com.kripta.dto.UpdateProfileRequest;
import com.kripta.dto.UserResponse;
import com.kripta.exception.DuplicateEmailException;
import com.kripta.exception.InvalidCurrentPasswordException;
import com.kripta.exception.UserNotFoundException;
import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import com.kripta.security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    private final PasswordEncoder encoder = new BCryptPasswordEncoder();

    private UserService userService;

    private User usuario;
    private UserPrincipal principal;

    @BeforeEach
    void setUp() {
        userService = new UserService(userRepository, encoder);

        usuario = new User("Joao Silva", "joao@email.com", encoder.encode("senha123"), User.UserType.USUARIO);
        usuario.setId(1L);
        principal = new UserPrincipal(usuario);
    }

    @Test
    void deveRetornarDadosDoUsuarioAtual() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));

        UserResponse response = userService.getCurrentUser(principal);

        assertEquals(1L, response.getId());
        assertEquals("Joao Silva", response.getNome());
        assertEquals("joao@email.com", response.getEmail());
        assertEquals(User.UserType.USUARIO, response.getTipo());
    }

    @Test
    void deveLancarExcecaoQuandoUsuarioNaoExiste() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(UserNotFoundException.class, () -> userService.getCurrentUser(principal));
    }

    @Test
    void deveAtualizarPerfilNormalizandoEmail() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));

        UpdateProfileRequest request = new UpdateProfileRequest("Joao Atualizado", "  JOAO@email.com  ");

        UserResponse response = userService.updateProfile(principal, request);

        assertEquals("Joao Atualizado", response.getNome());
        assertEquals("joao@email.com", response.getEmail());
        assertEquals("Joao Atualizado", usuario.getNome());
        assertEquals("joao@email.com", usuario.getEmail());
        verify(userRepository, never()).existsByEmail(anyString());
    }

    @Test
    void deveLancarExcecaoQuandoEmailJaEstaEmUso() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(userRepository.existsByEmail("outro@email.com")).thenReturn(true);

        UpdateProfileRequest request = new UpdateProfileRequest("Joao", "outro@email.com");

        assertThrows(DuplicateEmailException.class, () -> userService.updateProfile(principal, request));
        assertEquals("joao@email.com", usuario.getEmail());
    }

    @Test
    void deveTrocarSenhaQuandoSenhaAtualCorreta() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));

        ChangePasswordRequest request = new ChangePasswordRequest("senha123", "novaSenha456");

        userService.changePassword(principal, request);

        assertNotEquals("novaSenha456", usuario.getSenha());
        assertTrue(encoder.matches("novaSenha456", usuario.getSenha()));
    }

    @Test
    void deveLancarExcecaoQuandoSenhaAtualIncorreta() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));

        String senhaOriginal = usuario.getSenha();
        ChangePasswordRequest request = new ChangePasswordRequest("senhaErrada", "novaSenha456");

        assertThrows(InvalidCurrentPasswordException.class, () -> userService.changePassword(principal, request));
        assertEquals(senhaOriginal, usuario.getSenha());
    }

    @Test
    void deveDeletarUsuarioAtual() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));

        userService.deleteCurrentUser(principal);

        verify(userRepository).delete(usuario);
    }
}