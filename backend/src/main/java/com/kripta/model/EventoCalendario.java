package com.kripta.model;
import jakarta.persistence.*;
import java.time.*;
@Entity @Table(name="eventos_calendario") public class EventoCalendario {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(nullable=false) public Long ownerId;
 @Column(nullable=false,length=200) public String title;
 @Column(length=4000) public String note;
 @Column(nullable=false) public LocalDate date;
 public LocalTime time;
 @Column(nullable=false,length=20) public String scope;
 @Column(nullable=false,length=20) public String type;
}
