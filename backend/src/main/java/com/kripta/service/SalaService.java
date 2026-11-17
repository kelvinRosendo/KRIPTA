package com.kripta.service;

import com.kripta.model.*;
import com.kripta.repository.*;
import com.kripta.security.UserPrincipal;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;

@Service
@Transactional
public class SalaService {
    private static final int LIMITE = 40;
    private static final SecureRandom RANDOM = new SecureRandom();
    private final SalaRepository salas;
    private final SalaAlunoRepository alunos;
    private final SalaAtividadeRepository atividades;
    private final TarefaRepository tarefas;
    private final UserRepository usuarios;

    public SalaService(SalaRepository salas, SalaAlunoRepository alunos,
                       SalaAtividadeRepository atividades, TarefaRepository tarefas, UserRepository usuarios) {
        this.salas = salas;
        this.alunos = alunos;
        this.atividades = atividades;
        this.tarefas = tarefas;
        this.usuarios = usuarios;
    }

    public record SalaView(Long id, String nome, String codigo, long alunos, int limite,
                           List<SalaAtividade> atividades) {}

    public List<SalaView> listar(UserPrincipal usuario) {
        if (professor(usuario)) {
            return salas.findByProfessorIdOrderByIdDesc(usuario.getId()).stream().map(this::view).toList();
        }
        return alunos.findById(usuario.getId()).flatMap(vinculo -> salas.findById(vinculo.salaId))
                .map(sala -> List.of(view(sala))).orElseGet(List::of);
    }

    public SalaView criar(UserPrincipal usuario, String nome) {
        exigirProfessor(usuario);
        var sala = new Sala();
        sala.nome = nome.trim();
        sala.professorId = usuario.getId();
        byte[] codigo = new byte[6];
        RANDOM.nextBytes(codigo);
        sala.codigo = HexFormat.of().withUpperCase().formatHex(codigo);
        return view(salas.save(sala));
    }

    public SalaView entrar(UserPrincipal usuario, String codigo) {
        if (professor(usuario)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "A entrada por código é exclusiva de alunos.");
        }
        Long id = usuario.getId();
        var sala = salas.findByCodigo(codigo.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Código de sala não encontrado."));
        usuarios.locked(id).orElseThrow();
        var atual = alunos.findById(id);
        if (atual.isPresent()) {
            if (atual.get().salaId.equals(sala.id)) return view(sala);
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Sua conta já está vinculada a outra sala.");
        }
        if (alunos.countBySalaId(sala.id) >= LIMITE) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Esta sala já atingiu o limite de 40 alunos.");
        }
        var vinculo = new SalaAluno();
        vinculo.alunoId = id;
        vinculo.salaId = sala.id;
        alunos.save(vinculo);
        atividades.findBySalaIdOrderByIdDesc(sala.id).forEach(atividade -> entregar(atividade, id));
        return view(sala);
    }

    public SalaAtividade publicar(UserPrincipal usuario, Long id, String titulo, String descricao, Instant prazo) {
        exigirProfessor(usuario);
        var sala = salas.findByIdAndProfessorId(id, usuario.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sala não encontrada."));
        var atividade = new SalaAtividade();
        atividade.salaId = sala.id;
        atividade.titulo = titulo.trim();
        atividade.descricao = descricao;
        atividade.prazo = prazo;
        atividades.save(atividade);
        alunos.findBySalaId(sala.id).forEach(aluno -> entregar(atividade, aluno.alunoId));
        return atividade;
    }

    private void entregar(SalaAtividade atividade, Long alunoId) {
        var tarefa = new Tarefa();
        tarefa.ownerId = alunoId;
        tarefa.salaAtividadeId = atividade.id;
        tarefa.title = atividade.titulo;
        tarefa.description = atividade.descricao;
        tarefa.dueDate = atividade.prazo;
        tarefa.priority = "MEDIUM";
        tarefas.save(tarefa);
    }

    private SalaView view(Sala sala) {
        return new SalaView(sala.id, sala.nome, sala.codigo, alunos.countBySalaId(sala.id),
                LIMITE, atividades.findBySalaIdOrderByIdDesc(sala.id));
    }

    private boolean professor(UserPrincipal usuario) {
        return usuario.getTipo() == User.UserType.PROFESSOR;
    }

    private void exigirProfessor(UserPrincipal usuario) {
        if (!professor(usuario)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Esta ação é exclusiva do professor.");
        }
    }
}
