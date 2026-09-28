package com.kripta.dto;

public class DisciplinaResponse {

    private Long id;
    private String nome;
    private String cor;

    public DisciplinaResponse(Long id, String nome, String cor) {
        this.id = id;
        this.nome = nome;
        this.cor = cor;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getCor() {
        return cor;
    }

    public void setCor(String cor) {
        this.cor = cor;
    }
}