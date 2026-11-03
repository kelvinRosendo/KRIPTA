package com.kripta.controller;
import com.kripta.model.Tarefa;
import com.kripta.repository.*;
import com.kripta.security.UserPrincipal;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.time.Instant;
import java.util.List;
@RestController @RequestMapping("/api/tarefas") @Transactional
public class TarefaController {
 @org.springframework.beans.factory.annotation.Autowired private com.kripta.service.GamificacaoService gamificacao;
 private final TarefaRepository tasks; private final DisciplinaRepository subjects;
 public TarefaController(TarefaRepository t,DisciplinaRepository s){tasks=t;subjects=s;}
 public record Input(@NotBlank @Size(max=200) String title,@Size(max=4000) String description,Instant dueDate,@NotNull @Pattern(regexp="LOW|MEDIUM|HIGH") String priority,Long subjectId){}
 private Tarefa find(Long id,UserPrincipal p){return tasks.findByIdAndOwnerId(id,p.getId()).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));}
 private void apply(Tarefa t,Input i,UserPrincipal p){if(i.subjectId()!=null&&subjects.findByIdAndUsuarioId(i.subjectId(),p.getId()).isEmpty())throw new ResponseStatusException(HttpStatus.NOT_FOUND);t.title=i.title().trim();t.description=i.description();t.dueDate=i.dueDate();t.priority=i.priority();t.subjectId=i.subjectId();}
 @GetMapping public List<Tarefa> list(@AuthenticationPrincipal UserPrincipal p,@RequestParam(required=false) Long subjectId,@RequestParam(required=false) String status){return tasks.findByOwnerIdOrderByIdDesc(p.getId()).stream().filter(t->subjectId==null||subjectId.equals(t.subjectId)).filter(t->status==null || (status.equals("COMPLETED") && t.completed) || (status.equals("PENDING") && !t.completed)).toList();}
 @GetMapping("/{id}") public Tarefa get(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){return find(id,p);}
 @PostMapping @ResponseStatus(HttpStatus.CREATED) public Tarefa create(@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input i){var t=new Tarefa();t.ownerId=p.getId();apply(t,i,p);return tasks.save(t);}
 @PutMapping("/{id}") public Tarefa update(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p,@Valid @RequestBody Input i){var t=find(id,p);apply(t,i,p);return t;}
 @PatchMapping("/{id}/concluir") public Tarefa complete(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){return gamificacao.complete(id,p);}
 @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void delete(@PathVariable Long id,@AuthenticationPrincipal UserPrincipal p){tasks.delete(find(id,p));}
}
