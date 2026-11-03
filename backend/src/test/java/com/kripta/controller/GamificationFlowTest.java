package com.kripta.controller;
import com.kripta.model.*;
import com.kripta.repository.*;
import com.kripta.security.*;
import com.kripta.service.GamificacaoService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;
@SpringBootTest @ActiveProfiles("test") @Transactional class GamificationFlowTest {
 @Autowired GamificacaoService service; @Autowired UserRepository users; @Autowired TarefaRepository tasks; @Autowired HistoricoXPRepository history;
 @MockitoBean Clock clock;
 UserPrincipal student; Instant now;
 @BeforeEach void setup(){student=new UserPrincipal(users.save(new User("Aluno","gamification@example.com","hash",User.UserType.USUARIO)));now=Instant.parse("2026-11-03T15:00:00Z");when(clock.instant()).thenAnswer(i->now);}
 void beat(int seconds){now=now.plusSeconds(seconds);service.heartbeat(student);}
 @Test void xpUmaVezENiveis(){for(int i=0;i<4;i++){var t=new Tarefa();t.ownerId=student.getId();t.title="Teste";t.priority="MEDIUM";t=tasks.save(t);service.complete(t.id,student);service.complete(t.id,student);}assertEquals(100L,service.stats(student).get("xp"));assertEquals(2L,service.stats(student).get("level"));assertEquals(4,history.countByUserId(student.getId()));assertEquals(1,service.achievements(student).size());}
 @Test void tempoRealUmaVezPorDiaEPausaNaoConta(){service.heartbeat(student);for(int i=0;i<39;i++)beat(15);assertEquals(0,service.stats(student).get("streak"));beat(15);assertEquals(1,service.stats(student).get("streak"));for(int i=0;i<100;i++)service.heartbeat(student);assertEquals(1,service.stats(student).get("streak"));beat(3600);assertEquals(600,service.stats(student).get("seconds"));now=now.plus(Duration.ofDays(1));service.heartbeat(student);for(int i=0;i<40;i++)beat(15);assertEquals(2,service.stats(student).get("streak"));now=now.plus(Duration.ofDays(2));assertEquals(0,service.stats(student).get("streak"));service.heartbeat(student);for(int i=0;i<40;i++)beat(15);assertEquals(1,service.stats(student).get("streak"));}
 @Test void viradaDoDiaSoCreditaTempoDoNovoDia(){now=Instant.parse("2026-11-04T02:59:50Z");service.heartbeat(student);beat(15);assertEquals(5,service.stats(student).get("seconds"));}
 @Test void professorNaoParticipa(){var p=new UserPrincipal(users.save(new User("Professor","prof-g@example.com","hash",User.UserType.PROFESSOR)));assertThrows(org.springframework.web.server.ResponseStatusException.class,()->service.stats(p));}
}
