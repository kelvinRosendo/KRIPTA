package com.kripta.repository;

import com.kripta.model.CurriculoMtec;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CurriculoMtecRepository extends JpaRepository<CurriculoMtec, Long> {
    @EntityGraph(attributePaths = "componente")
    List<CurriculoMtec> findByCursoAndSerieOrderByComponenteNameAsc(String curso, int serie);
}
