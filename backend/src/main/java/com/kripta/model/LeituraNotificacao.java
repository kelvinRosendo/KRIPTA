package com.kripta.model;
import jakarta.persistence.*;
@Entity @Table(name="leituras_notificacao",uniqueConstraints=@UniqueConstraint(columnNames={"event_id","user_id"})) public class LeituraNotificacao {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(name="event_id",nullable=false) public Long eventId;
 @Column(name="user_id",nullable=false) public Long userId;
}
