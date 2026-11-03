package com.kripta.controller;

import com.kripta.dto.DisciplinaRequest;
import com.kripta.dto.DisciplinaResponse;
import com.kripta.security.UserPrincipal;
import com.kripta.service.DisciplinaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/disciplinas")
public class DisciplinaController {

    private final DisciplinaService disciplinaService;

    public DisciplinaController(DisciplinaService disciplinaService) {
        this.disciplinaService = disciplinaService;
    }

    @GetMapping
    public ResponseEntity<List<DisciplinaResponse>> listar(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(disciplinaService.listar(principal));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DisciplinaResponse> buscar(@PathVariable Long id,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(disciplinaService.buscar(id, principal));
    }

    @PostMapping
    public ResponseEntity<DisciplinaResponse> criar(@AuthenticationPrincipal UserPrincipal principal,
                                                    @Valid @RequestBody DisciplinaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(disciplinaService.criar(principal, request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DisciplinaResponse> atualizar(@PathVariable Long id,
                                                        @AuthenticationPrincipal UserPrincipal principal,
                                                        @Valid @RequestBody DisciplinaRequest request) {
        return ResponseEntity.ok(disciplinaService.atualizar(id, principal, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id,
                                        @AuthenticationPrincipal UserPrincipal principal) {
        disciplinaService.excluir(id, principal);
        return ResponseEntity.noContent().build();
    }
}