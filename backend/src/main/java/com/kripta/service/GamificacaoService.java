package com.kripta.service;
import com.kripta.model.*;
import com.kripta.repository.*;
import com.kripta.security.UserPrincipal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.time.*;
import java.util.*;
@Service @Transactional public class GamificacaoService {
 private final UserRepository users; private final ProgressoRepository progress; private final HistoricoXPRepository history; private final ConquistaRepository badges; private final TarefaRepository tasks; private final Clock clock;
 private static final ZoneId ZONE=ZoneId.of("America/Sao_Paulo");
 public GamificacaoService(UserRepository u,ProgressoRepository p,HistoricoXPRepository h,ConquistaRepository b,TarefaRepository t,Clock c){users=u;progress=p;history=h;badges=b;tasks=t;clock=c;}
 private ProgressoAluno state(UserPrincipal p){var user=users.locked(p.getId()).orElseThrow();if(user.getTipo()!=User.UserType.ALUNO&&user.getTipo()!=User.UserType.USUARIO)throw new ResponseStatusException(HttpStatus.FORBIDDEN);return progress.findById(p.getId()).orElseGet(()->{var s=new ProgressoAluno();s.userId=p.getId();return progress.save(s);});}
 private LocalDate today(){return clock.instant().atZone(ZONE).toLocalDate();}
 private void unlock(Long user,String code){if(!badges.existsByUserIdAndCode(user,code)){var b=new ConquistaAluno();b.userId=user;b.code=code;b.earnedAt=clock.instant();badges.save(b);}}
 public Tarefa complete(Long id,UserPrincipal p){var s=state(p);var t=tasks.findByIdAndOwnerId(id,p.getId()).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));t.completed=true;if(!history.existsByUserIdAndTaskId(p.getId(),id)){var h=new HistoricoXP();h.userId=p.getId();h.taskId=id;h.amount=25;h.earnedAt=clock.instant();history.save(h);s.xp+=25;unlock(p.getId(),"FIRST_TASK");if(history.countByUserId(p.getId())>=10)unlock(p.getId(),"TEN_TASKS");}return t;}
 public Map<String,Object> heartbeat(UserPrincipal p){var s=state(p);var now=clock.instant();var day=today();if(!day.equals(s.usageDay)){s.usageDay=day;s.seconds=0;}if(s.lastBeat!=null){long gap=Duration.between(s.lastBeat,now).getSeconds();if(gap>0&&gap<=45){Instant from=s.lastBeat.isBefore(day.atStartOfDay(ZONE).toInstant())?day.atStartOfDay(ZONE).toInstant():s.lastBeat;s.seconds=Math.min(600,s.seconds+(int)Math.min(30,Math.max(0,Duration.between(from,now).getSeconds())));}}s.lastBeat=now;if(s.seconds>=600&&!day.equals(s.qualifiedDay)){s.streak=day.minusDays(1).equals(s.qualifiedDay)?s.streak+1:1;s.qualifiedDay=day;unlock(p.getId(),"FIRST_STREAK");if(s.streak>=7)unlock(p.getId(),"WEEK_STREAK");}return view(s);}
 private Map<String,Object> view(ProgressoAluno s){var d=today();int streak=s.qualifiedDay!=null&&!s.qualifiedDay.isBefore(d.minusDays(1))?s.streak:0;int seconds=d.equals(s.usageDay)?s.seconds:0;var m=new LinkedHashMap<String,Object>();m.put("xp",s.xp);m.put("level",s.xp/100+1);m.put("xpToNextLevel",100-s.xp%100);m.put("levelProgress",s.xp%100);m.put("streak",streak);m.put("seconds",seconds);m.put("threshold",600);m.put("progress",seconds*100/600);m.put("advanced",d.equals(s.qualifiedDay));return m;}
 public Map<String,Object> stats(UserPrincipal p){return view(state(p));}
 public List<Map<String,Object>> achievements(UserPrincipal p){state(p);return badges.findByUserId(p.getId()).stream().map(b->{Map<String,Object> m=new LinkedHashMap<>();m.put("code",b.code);m.put("name",switch(b.code){case "FIRST_TASK"->"Primeira tarefa";case "TEN_TASKS"->"Dez tarefas";case "FIRST_STREAK"->"Primeiro dia";default->"Semana de estudos";});m.put("earned",true);m.put("earnedAt",b.earnedAt);m.put("icon","🏅");return m;}).toList();}
}
