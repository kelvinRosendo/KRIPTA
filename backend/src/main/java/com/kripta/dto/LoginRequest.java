package com.kripta.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;

public class LoginRequest {

    @NotBlank(message = "Email é obrigatório")
    @Email(message = "Email deve ser válido")
    private String email;

    @NotBlank(message = "Senha é obrigatória")
    private String senha;
    @Size(max = 32)
    private String cursoMtec;
    @Min(1)
    @Max(3)
    private Integer serieMtec;
    @Pattern(regexp = "(?i)[a-f0-9]{12}", message = "Informe o código de 12 caracteres da sala")
    private String codigoSala;

    public String getCodigoSala() { return codigoSala; }
    public void setCodigoSala(String codigoSala) { this.codigoSala = codigoSala; }

    public String getCursoMtec() { return cursoMtec; }
    public void setCursoMtec(String cursoMtec) { this.cursoMtec = cursoMtec; }
    public Integer getSerieMtec() { return serieMtec; }
    public void setSerieMtec(Integer serieMtec) { this.serieMtec = serieMtec; }

    @AssertTrue(message = "Selecione o curso e a série juntos")
    public boolean isTurmaValida() {
        return (cursoMtec == null && serieMtec == null)
                || (cursoMtec != null && !cursoMtec.isBlank() && serieMtec != null);
    }

    protected LoginRequest() {
    }

    public LoginRequest(String email, String senha) {
        this.email = email;
        this.senha = senha;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }
}
