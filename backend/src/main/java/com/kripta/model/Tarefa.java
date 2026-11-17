package com.kripta.model;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="tarefas") public class Tarefa {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(nullable=false) public Long ownerId;
 public Long subjectId;
 public Long salaAtividadeId;
 @Column(nullable=false,length=200) public String title;
 @Column(length=4000) public String description;
 public Instant dueDate;
 @Column(nullable=false) public String priority;
 public boolean completed;
 @Transient @com.fasterxml.jackson.annotation.JsonInclude(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL)
 public Gamification gamification;
 public record Gamification(int xpEarned, Long levelUp, java.util.List<String> unlocked) {}
}
