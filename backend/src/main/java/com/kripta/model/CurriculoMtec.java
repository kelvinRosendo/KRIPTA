package com.kripta.model;

import jakarta.persistence.*;

@Entity
@Table(name = "curriculo_mtec", uniqueConstraints = @UniqueConstraint(
        columnNames = {"curso", "serie", "componente_id"}))
public class CurriculoMtec {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String curso;

    @Column(nullable = false)
    private int serie;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "componente_id", nullable = false)
    private ComponenteCurricular componente;

    protected CurriculoMtec() {
    }

    public CurriculoMtec(String curso, int serie, ComponenteCurricular componente) {
        this.curso = curso;
        this.serie = serie;
        this.componente = componente;
    }

    public ComponenteCurricular getComponente() {
        return componente;
    }
}
