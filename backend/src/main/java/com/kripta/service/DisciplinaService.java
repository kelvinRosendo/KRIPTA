package com.kripta.service;

import com.kripta.dto.DisciplinaRequest;
import com.kripta.dto.DisciplinaResponse;
import com.kripta.exception.DisciplinaNotFoundException;
import com.kripta.exception.DuplicateDisciplinaException;
import com.kripta.exception.UserNotFoundException;
import com.kripta.model.Disciplina;
import com.kripta.model.User;
import com.kripta.repository.DisciplinaRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.UserPrincipal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DisciplinaService {

    private static final String COR_PADRAO = "#3B82F6";

    private final DisciplinaRepository disciplinaRepository;
    private final UserRepository userRepository;

    public DisciplinaService(DisciplinaRepository disciplinaRepository, UserRepository userRepository) {
        this.disciplinaRepository = disciplinaRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<DisciplinaResponse> listar(UserPrincipal principal) {
        return disciplinaRepository.findByUsuarioIdOrderByNomeAsc(principal.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public DisciplinaResponse buscar(Long id, UserPrincipal principal) {
        return toResponse(buscarDisciplina(id, principal));
    }

    @Transactional
    public DisciplinaResponse criar(UserPrincipal principal, DisciplinaRequest request) {
        String nome = request.getNome().trim();

        if (disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(principal.getId(), nome)) {
            throw new DuplicateDisciplinaException();
        }

        User usuario = findUsuario(principal.getId());

        Disciplina disciplina = new Disciplina(usuario, nome, normalizarCor(request.getCor()));
        return toResponse(disciplinaRepository.save(disciplina));
    }

    @Transactional
    public DisciplinaResponse atualizar(Long id, UserPrincipal principal, DisciplinaRequest request) {
        Disciplina disciplina = buscarDisciplina(id, principal);
        String nome = request.getNome().trim();

        if (disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(principal.getId(), nome)
                && !disciplina.getNome().equalsIgnoreCase(nome)) {
            throw new DuplicateDisciplinaException();
        }

        disciplina.setNome(nome);
        disciplina.setCor(normalizarCor(request.getCor()));

        return toResponse(disciplina);
    }

    @Transactional
    public void excluir(Long id, UserPrincipal principal) {
        Disciplina disciplina = buscarDisciplina(id, principal);
        disciplinaRepository.delete(disciplina);
    }

    private Disciplina buscarDisciplina(Long id, UserPrincipal principal) {
        return disciplinaRepository.findByIdAndUsuarioId(id, principal.getId())
                .orElseThrow(DisciplinaNotFoundException::new);
    }

    private User findUsuario(Long id) {
        return userRepository.findById(id)
                .orElseThrow(UserNotFoundException::new);
    }

    private String normalizarCor(String cor) {
        String value = cor == null ? "" : cor.trim();
        return value.isEmpty() ? COR_PADRAO : value;
    }

    private DisciplinaResponse toResponse(Disciplina disciplina) {
        return new DisciplinaResponse(disciplina.getId(), disciplina.getNome(), disciplina.getCor());
    }
}