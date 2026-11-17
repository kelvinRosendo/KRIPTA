package com.kripta.model;

import jakarta.persistence.*;

@Entity
@Table(name = "sala_alunos")
public class SalaAluno {
    @Id
    public Long alunoId;
    @Column(nullable = false)
    public Long salaId;
}
