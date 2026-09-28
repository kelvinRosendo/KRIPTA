package com.kripta.service;

import com.kripta.dto.DisciplinaRequest;
import com.kripta.dto.DisciplinaResponse;
import com.kripta.exception.DisciplinaNotFoundException;
import com.kripta.exception.DuplicateDisciplinaException;
import com.kripta.model.Disciplina;
import com.kripta.model.User;
import com.kripta.repository.DisciplinaRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DisciplinaServiceTest {

    @Mock
    private DisciplinaRepository disciplinaRepository;

    @Mock
    private UserRepository userRepository;

    private DisciplinaService disciplinaService;

    private User usuario;
    private UserPrincipal principal;
    private Disciplina disciplina;

    @BeforeEach
    void setUp() {
        disciplinaService = new DisciplinaService(disciplinaRepository, userRepository);

        usuario = new User("Joao Silva", "joao@email.com", "senha", User.UserType.USUARIO);
        usuario.setId(1L);
        principal = new UserPrincipal(usuario);

        disciplina = new Disciplina(usuario, "Matematica", "#FF5733");
        disciplina.setId(10L);
    }

    @Test
    void deveListarDisciplinasDoUsuarioEmOrdemAlfabetica() {
        Disciplina segunda = new Disciplina(usuario, "Portugues", "#3B82F6");
        when(disciplinaRepository.findByUsuarioIdOrderByNomeAsc(1L))
                .thenReturn(List.of(disciplina, segunda));

        var response = disciplinaService.listar(principal);

        assertEquals(2, response.size());
        assertEquals("Matematica", response.get(0).getNome());
        assertEquals("Portugues", response.get(1).getNome());
    }

    @Test
    void deveBuscarDisciplinaPertenceAoUsuario() {
        when(disciplinaRepository.findByIdAndUsuarioId(10L, 1L)).thenReturn(Optional.of(disciplina));

        DisciplinaResponse response = disciplinaService.buscar(10L, principal);

        assertEquals(10L, response.getId());
        assertEquals("Matematica", response.getNome());
        assertEquals("#FF5733", response.getCor());
    }

    @Test
    void deveLancarExcecaoQuandoDisciplinaNaoPertenceAoUsuario() {
        when(disciplinaRepository.findByIdAndUsuarioId(10L, 1L)).thenReturn(Optional.empty());

        assertThrows(DisciplinaNotFoundException.class, () -> disciplinaService.buscar(10L, principal));
    }

    @Test
    void deveCriarDisciplinaComCorPadraoQuandoCorVazia() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(1L, "Matematica")).thenReturn(false);
        when(disciplinaRepository.save(any(Disciplina.class))).thenAnswer(inv -> {
            Disciplina d = inv.getArgument(0);
            d.setId(30L);
            return d;
        });

        DisciplinaRequest request = new DisciplinaRequest(" Matematica ", "");

        DisciplinaResponse response = disciplinaService.criar(principal, request);

        assertEquals(30L, response.getId());
        assertEquals("Matematica", response.getNome());
        assertEquals("#3B82F6", response.getCor());
    }

    @Test
    void deveCriarDisciplinaComCorInformada() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(1L, "Portugues")).thenReturn(false);
        when(disciplinaRepository.save(any(Disciplina.class))).thenAnswer(inv -> {
            Disciplina d = inv.getArgument(0);
            d.setId(31L);
            return d;
        });

        DisciplinaRequest request = new DisciplinaRequest("Portugues", "#FF5733");

        DisciplinaResponse response = disciplinaService.criar(principal, request);

        assertEquals("#FF5733", response.getCor());
    }

    @Test
    void deveLancarExcecaoQuandoNomeJaExiste() {
        when(disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(1L, "Matematica")).thenReturn(true);

        DisciplinaRequest request = new DisciplinaRequest("Matematica", "#FF5733");

        assertThrows(DuplicateDisciplinaException.class, () -> disciplinaService.criar(principal, request));
        verify(disciplinaRepository, never()).save(any());
    }

    @Test
    void deveAtualizarDisciplina() {
        when(disciplinaRepository.findByIdAndUsuarioId(10L, 1L)).thenReturn(Optional.of(disciplina));
        when(disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(1L, "Calculo")).thenReturn(false);

        DisciplinaRequest request = new DisciplinaRequest("Calculo", "#22C55E");

        DisciplinaResponse response = disciplinaService.atualizar(10L, principal, request);

        assertEquals("Calculo", response.getNome());
        assertEquals("#22C55E", response.getCor());
        verify(disciplinaRepository, never()).save(any());
    }

    @Test
    void deveLancarExcecaoQuandoAtualizarParaNomeExistenteDeOutraDisciplina() {
        when(disciplinaRepository.findByIdAndUsuarioId(10L, 1L)).thenReturn(Optional.of(disciplina));
        when(disciplinaRepository.existsByUsuarioIdAndNomeIgnoreCase(1L, "Portugues")).thenReturn(true);

        DisciplinaRequest request = new DisciplinaRequest("Portugues", "#3B82F6");

        assertThrows(DuplicateDisciplinaException.class, () -> disciplinaService.atualizar(10L, principal, request));
    }

    @Test
    void deveExcluirDisciplina() {
        when(disciplinaRepository.findByIdAndUsuarioId(10L, 1L)).thenReturn(Optional.of(disciplina));

        disciplinaService.excluir(10L, principal);

        verify(disciplinaRepository).delete(disciplina);
    }

    @Test
    void deveLancarExcecaoAoExcluirDisciplinaInexistente() {
        when(disciplinaRepository.findByIdAndUsuarioId(99L, 1L)).thenReturn(Optional.empty());

        assertThrows(DisciplinaNotFoundException.class, () -> disciplinaService.excluir(99L, principal));
    }
}