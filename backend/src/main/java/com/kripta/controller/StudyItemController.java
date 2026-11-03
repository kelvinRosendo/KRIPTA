package com.kripta.controller;
import com.kripta.model.StudyItem;
import com.kripta.repository.*;
import com.kripta.security.UserPrincipal;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;
@RestController @RequestMapping("/api") @Transactional public class StudyItemController {
 private final StudyItemRepository items; private final DisciplinaRepository subjects;
 public StudyItemController(StudyItemRepository i,DisciplinaRepository s){items=i;subjects=s;}
 public record Input(@Size(max=200) String name,@Size(max=200) String title,@Size(max=4000) String description,@Size(max=2000) @Pattern(regexp="https?://[^\\s]+") String url,@Pattern(regexp="PDF|LINK|VIDEO|DOCUMENT|NOTE|OTHER") String type){}
 private StudyItem find(Long id,UserPrincipal p,String kind){return items.findByIdAndOwnerIdAndKind(id,p.getId(),kind).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));}
 private Map<String,Object> view(StudyItem i){var m=new LinkedHashMap<String,Object>();m.put("id",i.id);m.put("name",i.name);m.put("title",i.name);m.put("description",i.description);m.put("url",i.url);m.put("type",i.type);m.put("completed",i.completed);return m;}
 private void apply(StudyItem i,Input b){String name=i.kind.equals("UNIT")?b.name():b.title();if(name==null||name.isBlank())throw new ResponseStatusException(HttpStatus.BAD_REQUEST);i.name=name.trim();i.description=b.description();i.url=b.url();i.type=b.type()==null?"NOTE":b.type();}
 @GetMapping("/disciplinas/{id}/unidades") public List<Map<String,Object>> units(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){if(subjects.findByIdAndUsuarioId(id,p.getId()).isEmpty())throw new ResponseStatusException(HttpStatus.NOT_FOUND);return items.findByOwnerIdAndKindAndParentIdOrderByIdAsc(p.getId(),"UNIT",id).stream().map(this::view).toList();}
 @PostMapping("/disciplinas/{id}/unidades") @ResponseStatus(HttpStatus.CREATED) public Map<String,Object> unit(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input b){units(id,p);var i=new StudyItem();i.ownerId=p.getId();i.parentId=id;i.kind="UNIT";apply(i,b);return view(items.save(i));}
 @GetMapping("/unidades/{id}/materiais") public List<Map<String,Object>> materials(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){find(id,p,"UNIT");return items.findByOwnerIdAndKindAndParentIdOrderByIdAsc(p.getId(),"MATERIAL",id).stream().map(this::view).toList();}
 @PostMapping("/unidades/{id}/materiais") @ResponseStatus(HttpStatus.CREATED) public Map<String,Object> material(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input b){find(id,p,"UNIT");var i=new StudyItem();i.ownerId=p.getId();i.parentId=id;i.kind="MATERIAL";apply(i,b);return view(items.save(i));}
 @PutMapping("/unidades/{id}") public Map<String,Object> updateUnit(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input b){var i=find(id,p,"UNIT");apply(i,b);return view(i);}
 @PutMapping("/materiais/{id}") public Map<String,Object> updateMaterial(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input b){var i=find(id,p,"MATERIAL");apply(i,b);return view(i);}
 @DeleteMapping("/unidades/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteUnit(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){var i=find(id,p,"UNIT");items.deleteAll(items.findByOwnerIdAndKindAndParentIdOrderByIdAsc(p.getId(),"MATERIAL",id));items.delete(i);}
 @DeleteMapping("/materiais/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void deleteMaterial(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){items.delete(find(id,p,"MATERIAL"));}
 @PatchMapping("/materiais/{id}/concluir") public Map<String,Object> complete(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){var i=find(id,p,"MATERIAL");i.completed=true;return view(i);}
}
