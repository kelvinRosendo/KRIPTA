package com.kripta.service;

import com.kripta.exception.UserNotFoundException;
import com.kripta.model.ComponenteCurricular;
import com.kripta.model.CurriculoMtec;
import com.kripta.model.Disciplina;
import com.kripta.model.User;
import com.kripta.repository.CurriculoMtecRepository;
import com.kripta.repository.DisciplinaRepository;
import com.kripta.repository.UserRepository;
import com.kripta.security.UserPrincipal;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
public class CursoMtecService {
    private static final List<Curso> CURSOS = List.of(
            new Curso("administracao", "Administração"),
            new Curso("desenvolvimento-de-sistemas", "Desenvolvimento de Sistemas"),
            new Curso("marketing", "Marketing"),
            new Curso("meio-ambiente", "Meio Ambiente"),
            new Curso("nutricao-e-dietetica", "Nutrição e Dietética")
    );
    private static final String[] CORES = {"#6366F1", "#0F766E", "#7C3AED", "#B45309", "#2563EB"};

    private final UserRepository usuarios;
    private final DisciplinaRepository disciplinas;
    private final CurriculoMtecRepository curriculos;

    public CursoMtecService(UserRepository usuarios, DisciplinaRepository disciplinas,
                           CurriculoMtecRepository curriculos) {
        this.usuarios = usuarios;
        this.disciplinas = disciplinas;
        this.curriculos = curriculos;
    }

    public record Curso(String id, String nome) {}
    public record Selecao(String curso, int serie, Set<Long> disciplinaIds) {}
    public record Catalogo(List<Curso> cursos, Selecao selecao) {}

    public List<Curso> listarCursos() { return CURSOS; }

    @Transactional(readOnly = true)
    public Catalogo consultar(UserPrincipal principal) {
        exigirAluno(principal);
        User usuario = usuarios.findById(principal.getId()).orElseThrow(UserNotFoundException::new);
        if (usuario.getCursoMtec() == null) return new Catalogo(CURSOS, null);

        var materias = disciplinas.findByUsuarioIdOrderByNomeAsc(usuario.getId());
        var ids = new LinkedHashSet<Long>();
        for (var componente : componentes(usuario.getCursoMtec(), usuario.getSerieMtec())) {
            equivalente(materias, componente).ifPresent(materia -> ids.add(materia.getId()));
        }
        return resultado(usuario, ids);
    }

    @Transactional
    public Catalogo selecionar(UserPrincipal principal, String curso, int serie) {
        exigirAluno(principal);
        var componentes = componentes(curso, serie);
        if (componentes.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Curso ou série indisponível");
        }

        User usuario = usuarios.locked(principal.getId()).orElseThrow(UserNotFoundException::new);
        var materias = disciplinas.findByUsuarioIdOrderByNomeAsc(usuario.getId());
        var ids = new LinkedHashSet<Long>();
        for (int posicao = 0; posicao < componentes.size(); posicao++) {
            var componente = componentes.get(posicao);
            var existente = equivalente(materias, componente);
            if (existente.isPresent()) {
                var materia = existente.get();
                if (materia.getComponenteId() == null) materia.setComponenteId(componente.id);
                ids.add(materia.getId());
            } else {
                var materia = new Disciplina(usuario, componente.name.strip(), CORES[posicao % CORES.length]);
                materia.setComponenteId(componente.id);
                ids.add(disciplinas.save(materia).getId());
            }
        }
        usuario.selecionarCursoMtec(curso, serie);
        return resultado(usuario, ids);
    }

    private List<ComponenteCurricular> componentes(String curso, int serie) {
        return curriculos.findByCursoAndSerieOrderByComponenteNameAsc(curso, serie)
                .stream().map(CurriculoMtec::getComponente).toList();
    }

    private static Optional<Disciplina> equivalente(List<Disciplina> materias, ComponenteCurricular componente) {
        return materias.stream().filter(materia -> componente.id.equals(materia.getComponenteId())).findFirst()
                .or(() -> materias.stream()
                        .filter(materia -> materia.getNome().strip().equalsIgnoreCase(componente.name.strip()))
                        .findFirst());
    }

    private static Catalogo resultado(User usuario, Set<Long> ids) {
        return new Catalogo(CURSOS, new Selecao(usuario.getCursoMtec(), usuario.getSerieMtec(), ids));
    }

    private static void exigirAluno(UserPrincipal principal) {
        if (principal.getTipo() != User.UserType.ALUNO && principal.getTipo() != User.UserType.USUARIO) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }
}
