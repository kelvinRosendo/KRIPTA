package com.kripta.repository;
import com.kripta.model.EventoCalendario;
import org.springframework.data.jpa.repository.*;
import jakarta.persistence.LockModeType;
import java.time.LocalDate;
import java.util.*;
public interface EventoRepository extends JpaRepository<EventoCalendario,Long> {
 @Query("select e from EventoCalendario e where (e.ownerId = :owner or e.scope = 'ESCOLAR') and e.date between :start and :end order by e.date,e.id")
 List<EventoCalendario> visible(Long owner,LocalDate start,LocalDate end);
 @Query("select e from EventoCalendario e where e.ownerId = :owner or e.scope = 'ESCOLAR' order by e.date desc,e.id desc")
 List<EventoCalendario> notifications(Long owner);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select e from EventoCalendario e where e.id = :id") Optional<EventoCalendario> locked(Long id);
}
