package com.kripta.model;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="tarefas") public class Tarefa {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(nullable=false) public Long ownerId;
 public Long subjectId;
 @Column(nullable=false,length=200) public String title;
 @Column(length=4000) public String description;
 public Instant dueDate;
 @Column(nullable=false) public String priority;
 public boolean completed;
}
