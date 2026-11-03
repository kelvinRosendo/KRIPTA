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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(UserPrincipal principal) {
        return toResponse(buscarUsuario(principal.getId()));
    }

    @Transactional
    public UserResponse updateProfile(UserPrincipal principal, UpdateProfileRequest request) {
        User user = buscarUsuario(principal.getId());

        String email = request.getEmail().trim().toLowerCase();

        if (!user.getEmail().equals(email) && userRepository.existsByEmail(email)) {
            throw new DuplicateEmailException("Email já cadastrado");
        }

        user.setNome(request.getNome().trim());
        user.setEmail(email);

        return toResponse(user);
    }

    @Transactional
    public void changePassword(UserPrincipal principal, ChangePasswordRequest request) {
        User user = buscarUsuario(principal.getId());

        if (!passwordEncoder.matches(request.getSenhaAtual(), user.getSenha())) {
            throw new InvalidCurrentPasswordException();
        }

        String novaSenha = passwordEncoder.encode(request.getNovaSenha());
        user.setSenha(novaSenha);
    }

    @Transactional
    public void deleteCurrentUser(UserPrincipal principal) {
        User user = buscarUsuario(principal.getId());
        userRepository.delete(user);
    }

    private User buscarUsuario(Long id) {
        return userRepository.findById(id)
                .orElseThrow(UserNotFoundException::new);
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getNome(), user.getEmail(), user.getTipo());
    }
}