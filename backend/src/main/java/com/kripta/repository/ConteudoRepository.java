package com.kripta.repository;
import com.kripta.model.ConteudoAcademico;
import java.util.List;
public interface ConteudoRepository extends org.springframework.data.jpa.repository.JpaRepository<ConteudoAcademico,Long> {
 List<ConteudoAcademico> findByStatusOrderByIdDesc(String status);
 List<ConteudoAcademico> findByAuthorIdOrderByIdDesc(Long authorId);
}
