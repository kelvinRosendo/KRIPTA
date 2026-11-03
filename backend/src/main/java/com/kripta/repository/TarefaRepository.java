package com.kripta.repository;
public interface TarefaRepository extends org.springframework.data.jpa.repository.JpaRepository<com.kripta.model.Tarefa,Long> {
 java.util.List<com.kripta.model.Tarefa> findByOwnerIdOrderByIdDesc(Long id);
 java.util.Optional<com.kripta.model.Tarefa> findByIdAndOwnerId(Long id,Long ownerId);
}
