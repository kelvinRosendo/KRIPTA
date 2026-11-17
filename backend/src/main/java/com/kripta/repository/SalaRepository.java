package com.kripta.repository;

import com.kripta.model.Sala;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import java.util.List;
import java.util.Optional;

public interface SalaRepository extends JpaRepository<Sala, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<Sala> findByCodigo(String codigo);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<Sala> findByIdAndProfessorId(Long id, Long professorId);

    List<Sala> findByProfessorIdOrderByIdDesc(Long professorId);
}
