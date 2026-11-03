package com.kripta.repository;
public interface StudyItemRepository extends org.springframework.data.jpa.repository.JpaRepository<com.kripta.model.StudyItem,Long> {
 java.util.List<com.kripta.model.StudyItem> findByOwnerIdAndKindAndParentIdOrderByIdAsc(Long owner,String kind,Long parent);
 java.util.Optional<com.kripta.model.StudyItem> findByIdAndOwnerIdAndKind(Long id,Long owner,String kind);
}
