package com.kripta.model;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="conquistas_aluno",uniqueConstraints=@UniqueConstraint(columnNames={"user_id","code"})) public class ConquistaAluno {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(name="user_id",nullable=false) public Long userId;
 @Column(nullable=false) public String code;
 public Instant earnedAt;
}
