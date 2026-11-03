package com.kripta.model;
import jakarta.persistence.*;
import java.time.*;
@Entity @Table(name="progresso_aluno") public class ProgressoAluno {
 @Id public Long userId;
 public long xp;
 public int streak;
 public int seconds;
 public LocalDate usageDay;
 public LocalDate qualifiedDay;
 public Instant lastBeat;
}
