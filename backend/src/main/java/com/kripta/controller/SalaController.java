package com.kripta.controller;

import com.kripta.model.SalaAtividade;
import com.kripta.security.UserPrincipal;
import com.kripta.service.SalaService;
import com.kripta.service.SalaService.SalaView;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/salas")
public class SalaController {
    private final SalaService salas;

    public SalaController(SalaService salas) {
        this.salas = salas;
    }

    public record Criar(@NotBlank @Size(max = 80) String nome) {}
    public record Entrar(@NotBlank @Pattern(regexp = "(?i)[a-f0-9]{12}") String codigo) {}
    public record Publicar(@NotBlank @Size(max = 200) String titulo,
                           @Size(max = 4000) String descricao, @NotNull Instant prazo) {}

    @GetMapping
    public List<SalaView> listar(@AuthenticationPrincipal UserPrincipal usuario) {
        return salas.listar(usuario);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public SalaView criar(@AuthenticationPrincipal UserPrincipal usuario, @Valid @RequestBody Criar input) {
        return salas.criar(usuario, input.nome());
    }

    @PostMapping("/entrar")
    public SalaView entrar(@AuthenticationPrincipal UserPrincipal usuario, @Valid @RequestBody Entrar input) {
        return salas.entrar(usuario, input.codigo());
    }

    @PostMapping("/{id}/atividades")
    @ResponseStatus(HttpStatus.CREATED)
    public SalaAtividade publicar(@AuthenticationPrincipal UserPrincipal usuario, @PathVariable Long id,
                                  @Valid @RequestBody Publicar input) {
        return salas.publicar(usuario, id, input.titulo(), input.descricao(), input.prazo());
    }
}
