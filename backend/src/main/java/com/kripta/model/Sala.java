package com.kripta.model;

import jakarta.persistence.*;

@Entity
@Table(name = "salas")
public class Sala {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;
    @Column(nullable = false, length = 80)
    public String nome;
    @Column(nullable = false, unique = true, length = 12)
    public String codigo;
    @Column(nullable = false)
    public Long professorId;
}
