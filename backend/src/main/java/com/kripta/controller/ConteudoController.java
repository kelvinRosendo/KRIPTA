package com.kripta.controller;
import com.kripta.model.*;
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

@RestController @RequestMapping("/api") @Transactional
public class ConteudoController {
 private final ConteudoRepository contents;
 private final ComponenteRepository components;
 private final UserRepository users;
 public ConteudoController(ConteudoRepository c, ComponenteRepository s, UserRepository u) {contents=c;components=s;users=u;}
 public record ComponentInput(@NotBlank @Size(max=100) String name) {}
 public record Input(@NotNull Long subjectId, @NotBlank @Size(max=200) String title,
  @Size(max=4000) String description, @Size(max=2000) @Pattern(regexp="https?://[^\\s]+") String url,
  @NotBlank @Pattern(regexp="PDF|VIDEO|LINK|DOCUMENT|SLIDE|OTHER") String type) {}
 public record Review(@Size(max=1000) String reason) {}
 private void teacher(UserPrincipal p) {if(p.getTipo()!=User.UserType.PROFESSOR) throw new ResponseStatusException(HttpStatus.FORBIDDEN);}
 private void reviewer(UserPrincipal p) {if(!users.findById(p.getId()).orElseThrow().isPodeAprovar()) throw new ResponseStatusException(HttpStatus.FORBIDDEN);}
 private ConteudoAcademico find(Long id) {return contents.findById(id).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));}
 private Map<String,Object> view(ConteudoAcademico c) {
  var m=new LinkedHashMap<String,Object>();m.put("id",c.id);m.put("subjectId",c.subjectId);m.put("subjectName",components.findById(c.subjectId).orElseThrow().name);
  m.put("title",c.title);m.put("description",c.description);m.put("url",c.url);m.put("type",c.type);m.put("status",c.status);m.put("rejectReason",c.rejectReason);
  m.put("authorName",users.findById(c.authorId).orElseThrow().getNome());return m;
 }
 @GetMapping("/componentes") public List<ComponenteCurricular> components(){return components.findAll();}
 @PostMapping("/componentes") @ResponseStatus(HttpStatus.CREATED)
 public ComponenteCurricular component(@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody ComponentInput input){teacher(p);var c=new ComponenteCurricular();c.name=input.name().trim();return components.save(c);}
 @PostMapping("/conteudos") @ResponseStatus(HttpStatus.CREATED)
 public Map<String,Object> create(@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input input){teacher(p);if(!components.existsById(input.subjectId()))throw new ResponseStatusException(HttpStatus.NOT_FOUND);var c=new ConteudoAcademico();c.authorId=p.getId();c.subjectId=input.subjectId();c.title=input.title().trim();c.description=input.description();c.url=input.url();c.type=input.type();return view(contents.save(c));}
 @GetMapping("/conteudos/meus") public List<Map<String,Object>> mine(@AuthenticationPrincipal UserPrincipal p){teacher(p);return contents.findByAuthorIdOrderByIdDesc(p.getId()).stream().map(this::view).toList();}
 @GetMapping("/conteudos/pendentes") public List<Map<String,Object>> pending(@AuthenticationPrincipal UserPrincipal p){reviewer(p);return contents.findByStatusOrderByIdDesc("AGUARDANDO_APROVACAO").stream().map(this::view).toList();}
 @GetMapping("/conteudos") public List<Map<String,Object>> approved(@RequestParam(required=false) Long subjectId){return contents.findByStatusOrderByIdDesc("APROVADO").stream().filter(c->subjectId==null||subjectId.equals(c.subjectId)).map(this::view).toList();}
 @GetMapping("/conteudos/{id}") public Map<String,Object> get(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){var c=find(id);if(!c.status.equals("APROVADO")&&!c.authorId.equals(p.getId())&&!users.findById(p.getId()).orElseThrow().isPodeAprovar())throw new ResponseStatusException(HttpStatus.NOT_FOUND);return view(c);}
 private Map<String,Object> review(Long id,UserPrincipal p,String status,String reason){reviewer(p);var c=find(id);if(!c.status.equals("AGUARDANDO_APROVACAO"))throw new ResponseStatusException(HttpStatus.CONFLICT);c.status=status;c.reviewerId=p.getId();c.rejectReason=reason;return view(c);}
 @PatchMapping("/conteudos/{id}/aprovar") public Map<String,Object> approve(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){return review(id,p,"APROVADO",null);}
 @PatchMapping("/conteudos/{id}/rejeitar") public Map<String,Object> reject(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Review input){return review(id,p,"REJEITADO",input.reason());}
}
