package com.kripta.model;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="historico_xp",uniqueConstraints=@UniqueConstraint(columnNames={"user_id","task_id"})) public class HistoricoXP {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(name="user_id",nullable=false) public Long userId;
 @Column(name="task_id",nullable=false) public Long taskId;
 public int amount;
 public Instant earnedAt;
}
