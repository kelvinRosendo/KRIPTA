package com.kripta.repository;
import com.kripta.model.LeituraNotificacao;
public interface LeituraRepository extends org.springframework.data.jpa.repository.JpaRepository<LeituraNotificacao,Long> {
 boolean existsByEventIdAndUserId(Long eventId,Long userId);
 void deleteByEventId(Long eventId);
}
