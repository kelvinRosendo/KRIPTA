package com.kripta.dto;

import com.kripta.model.User.UserType;

public class LoginResponse {

    private String token;
    private String tokenType = "Bearer";
    private Long expiresIn;
    private String rm;
    private boolean podeAprovar;
    public String getRm() { return rm; }
    public void setRm(String rm) { this.rm = rm; }
    public boolean isPodeAprovar() { return podeAprovar; }
    public void setPodeAprovar(boolean value) { this.podeAprovar = value; }
    private Long id;
    private String nome;
    private String email;
    private UserType tipo;

    public LoginResponse(String token, long expirationMs, Long id, String nome, String email, UserType tipo) {
        this.token = token;
        this.expiresIn = expirationMs / 1000;
        this.id = id;
        this.nome = nome;
        this.email = email;
        this.tipo = tipo;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getTokenType() {
        return tokenType;
    }

    public void setTokenType(String tokenType) {
        this.tokenType = tokenType;
    }

    public Long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(Long expiresIn) {
        this.expiresIn = expiresIn;
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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public UserType getTipo() {
        return tipo;
    }

    public void setTipo(UserType tipo) {
        this.tipo = tipo;
    }
}
