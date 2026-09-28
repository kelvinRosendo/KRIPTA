package com.kripta.exception;

public class DisciplinaNotFoundException extends RuntimeException {

    public DisciplinaNotFoundException() {
        super("Disciplina não encontrada");
    }
}