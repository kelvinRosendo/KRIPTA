package com.kripta.model;
import jakarta.persistence.*;
@Entity @Table(name="componentes_curriculares")
public class ComponenteCurricular {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(nullable=false,length=100) public String name;
}
