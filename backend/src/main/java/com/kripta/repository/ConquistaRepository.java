package com.kripta.repository;
public interface ConquistaRepository extends org.springframework.data.jpa.repository.JpaRepository<com.kripta.model.ConquistaAluno,Long> {
 boolean existsByUserIdAndCode(Long userId,String code);
 java.util.List<com.kripta.model.ConquistaAluno> findByUserId(Long userId);
}
