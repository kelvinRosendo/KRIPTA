package com.kripta.service;

import com.kripta.dto.RegisterRequest;
import com.kripta.dto.RegisterResponse;
import com.kripta.exception.DuplicateEmailException;
import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        String nome = request.getNome().trim();
        String email = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new DuplicateEmailException("Email já cadastrado");
        }

        User user = new User(
                nome,
                email,
                passwordEncoder.encode(request.getSenha()),
                request.getTipo()
        );

        User salvo = userRepository.save(user);

        return new RegisterResponse(salvo.getId(), salvo.getNome(), salvo.getEmail(), salvo.getTipo());
    }
}