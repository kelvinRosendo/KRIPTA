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
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
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

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        authenticate(email, request.getSenha());
        User user = buscarUsuario(email);

        String token = jwtService.generateToken(user);

        return new LoginResponse(token, jwtService.getExpirationMs(),
                user.getId(), user.getNome(), user.getEmail(), user.getTipo());
    }

    private void authenticate(String email, String senha) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, senha));
        } catch (AuthenticationException ex) {
            throw new InvalidCredentialsException();
        }
    }

    private User buscarUsuario(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(InvalidCredentialsException::new);
    }
}
