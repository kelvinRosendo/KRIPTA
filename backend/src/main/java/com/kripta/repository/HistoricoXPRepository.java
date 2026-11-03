package com.kripta.repository;
public interface HistoricoXPRepository extends org.springframework.data.jpa.repository.JpaRepository<com.kripta.model.HistoricoXP,Long> {
 boolean existsByUserIdAndTaskId(Long userId,Long taskId);
 long countByUserId(Long userId);
}
