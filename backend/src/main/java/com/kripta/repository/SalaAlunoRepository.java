package com.kripta.repository;

import com.kripta.model.SalaAluno;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SalaAlunoRepository extends JpaRepository<SalaAluno, Long> {
    List<SalaAluno> findBySalaId(Long salaId);
    long countBySalaId(Long salaId);
}
