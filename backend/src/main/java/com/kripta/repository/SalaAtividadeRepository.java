package com.kripta.repository;

import com.kripta.model.SalaAtividade;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SalaAtividadeRepository extends JpaRepository<SalaAtividade, Long> {
    List<SalaAtividade> findBySalaIdOrderByIdDesc(Long salaId);
}
