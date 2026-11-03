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
import java.time.*;
import java.util.*;
@RestController @RequestMapping("/api") @Transactional public class CalendarioController {
 private final EventoRepository events; private final LeituraRepository reads;
 public CalendarioController(EventoRepository e,LeituraRepository r){events=e;reads=r;}
 public record Input(@NotBlank @Size(max=200) String title,@Size(max=4000) String note,@NotNull LocalDate date,LocalTime time,
  @Pattern(regexp="PESSOAL|ESCOLAR") String scope,@Pattern(regexp="EVENT|EXAM|TASK") String type){}
 private EventoCalendario find(Long id,UserPrincipal p){var e=events.locked(id).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));if(!e.ownerId.equals(p.getId())&&!e.scope.equals("ESCOLAR"))throw new ResponseStatusException(HttpStatus.NOT_FOUND);return e;}
 private void edit(EventoCalendario e,UserPrincipal p){if(!e.ownerId.equals(p.getId()))throw new ResponseStatusException(HttpStatus.NOT_FOUND);}
 private void apply(EventoCalendario e,Input i,UserPrincipal p){String scope=i.scope()==null?"PESSOAL":i.scope();if(scope.equals("ESCOLAR")&&p.getTipo()!=User.UserType.PROFESSOR)throw new ResponseStatusException(HttpStatus.FORBIDDEN);e.title=i.title().trim();e.note=i.note();e.date=i.date();e.time=i.time();e.scope=scope;e.type=i.type()==null?"EVENT":i.type();}
 @GetMapping("/calendario") public List<EventoCalendario> list(@AuthenticationPrincipal UserPrincipal p,@RequestParam LocalDate inicio,@RequestParam LocalDate fim,@RequestParam(required=false) String scope){if(fim.isBefore(inicio)||java.time.temporal.ChronoUnit.DAYS.between(inicio,fim)>366)throw new ResponseStatusException(HttpStatus.BAD_REQUEST);if(scope!=null&&!List.of("PESSOAL","ESCOLAR","ALL").contains(scope))throw new ResponseStatusException(HttpStatus.BAD_REQUEST);return events.visible(p.getId(),inicio,fim).stream().filter(e->scope==null||scope.equals("ALL")||scope.equals(e.scope)).toList();}
 @GetMapping("/calendario/eventos") public List<EventoCalendario> personal(@AuthenticationPrincipal UserPrincipal p){return events.notifications(p.getId()).stream().filter(e->e.scope.equals("PESSOAL")).toList();}
 @GetMapping("/calendario/eventos/{id}") public EventoCalendario get(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){return find(id,p);}
 @PostMapping("/calendario/eventos") @ResponseStatus(HttpStatus.CREATED) public EventoCalendario create(@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input i){var e=new EventoCalendario();e.ownerId=p.getId();apply(e,i,p);return events.save(e);}
 @PutMapping("/calendario/eventos/{id}") public EventoCalendario update(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input i){var e=find(id,p);edit(e,p);apply(e,i,p);reads.deleteByEventId(id);return e;}
 @DeleteMapping("/calendario/eventos/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void delete(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){var e=find(id,p);edit(e,p);reads.deleteByEventId(id);events.delete(e);}
 @GetMapping("/notificacoes") public List<Map<String,Object>> notifications(@AuthenticationPrincipal UserPrincipal p){return events.notifications(p.getId()).stream().map(e->{Map<String,Object> n=new LinkedHashMap<>();n.put("id",e.id);n.put("eventId",e.id);n.put("title",e.title);n.put("message",e.note);n.put("date",e.date);n.put("type",e.type);n.put("read",reads.existsByEventIdAndUserId(e.id,p.getId()));return n;}).toList();}
 @PatchMapping("/notificacoes/{id}/ler") @ResponseStatus(HttpStatus.NO_CONTENT) public void read(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){find(id,p);if(!reads.existsByEventIdAndUserId(id,p.getId())){var r=new LeituraNotificacao();r.eventId=id;r.userId=p.getId();reads.save(r);}}
}
