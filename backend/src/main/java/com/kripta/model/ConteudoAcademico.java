package com.kripta.model;
import jakarta.persistence.*;
@Entity @Table(name="conteudos_academicos")
public class ConteudoAcademico {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Version public long version;
 @Column(nullable=false) public Long authorId;
 @Column(nullable=false) public Long subjectId;
 @Column(nullable=false,length=200) public String title;
 @Column(length=4000) public String description;
 @Column(length=2000) public String url;
 @Column(nullable=false,length=30) public String type;
 @Column(nullable=false,length=30) public String status = "AGUARDANDO_APROVACAO";
 public Long reviewerId;
 @Column(length=1000) public String rejectReason;
}
