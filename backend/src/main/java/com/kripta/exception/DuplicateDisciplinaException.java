package com.kripta.exception;

public class DuplicateDisciplinaException extends RuntimeException {

    public DuplicateDisciplinaException() {
        super("Já existe uma disciplina com esse nome");
    }
}