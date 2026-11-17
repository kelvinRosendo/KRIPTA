package com.kripta.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "sala_atividades")
public class SalaAtividade {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;
    @Column(nullable = false)
    public Long salaId;
    @Column(nullable = false, length = 200)
    public String titulo;
    @Column(length = 4000)
    public String descricao;
    @Column(nullable = false)
    public Instant prazo;
}
