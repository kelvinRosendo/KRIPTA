package com.kripta.model;
import jakarta.persistence.*;
@Entity @Table(name="study_items") public class StudyItem {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
 @Column(nullable=false) public Long ownerId;
 @Column(nullable=false) public Long parentId;
 @Column(nullable=false) public String kind;
 @Column(nullable=false,length=200) public String name;
 @Column(length=4000) public String description;
 @Column(length=2000) public String url;
 public String type;
 public boolean completed;
}
