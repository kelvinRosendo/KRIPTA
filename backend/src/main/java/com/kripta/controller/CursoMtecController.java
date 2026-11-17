package com.kripta.controller;

import com.kripta.security.UserPrincipal;
import com.kripta.service.CursoMtecService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/curso-mtec")
public class CursoMtecController {
    private final CursoMtecService service;

    public CursoMtecController(CursoMtecService service) {
        this.service = service;
    }

    public record Selecionar(@NotBlank @Size(max = 32) String curso,
                             @NotNull @Min(1) @Max(3) Integer serie) {}

    @GetMapping("/opcoes")
    public List<CursoMtecService.Curso> listarCursos() {
        return service.listarCursos();
    }

    @GetMapping
    public CursoMtecService.Catalogo consultar(@AuthenticationPrincipal UserPrincipal principal) {
        return service.consultar(principal);
    }

    @PutMapping
    public CursoMtecService.Catalogo selecionar(@AuthenticationPrincipal UserPrincipal principal,
                                               @Valid @RequestBody Selecionar request) {
        return service.selecionar(principal, request.curso(), request.serie());
    }
}
