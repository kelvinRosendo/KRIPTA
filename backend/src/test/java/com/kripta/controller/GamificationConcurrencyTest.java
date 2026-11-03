package com.kripta.controller;
import com.kripta.model.*;
import com.kripta.repository.*;
import com.kripta.security.UserPrincipal;
import com.kripta.service.GamificacaoService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.annotation.DirtiesContext;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest @ActiveProfiles({"test","concurrency"}) @DirtiesContext(classMode=DirtiesContext.ClassMode.AFTER_CLASS)
class GamificationConcurrencyTest {
 @Autowired GamificacaoService service; @Autowired UserRepository users; @Autowired TarefaRepository tasks; @Autowired HistoricoXPRepository history;
 @Test void conclusoesSimultaneasNaoDuplicamXP()throws Exception {
 var user=users.save(new User("Aluno","concurrent-"+java.util.UUID.randomUUID()+"@example.com","hash",User.UserType.USUARIO));
 var p=new UserPrincipal(user);var t=new Tarefa();t.ownerId=p.getId();t.title="Teste";t.priority="MEDIUM";Long id=tasks.save(t).id;
 var executor=Executors.newFixedThreadPool(4);var start=new CountDownLatch(1);
 try {var jobs=new java.util.ArrayList<Future<?>>();for(int i=0;i<4;i++)jobs.add(executor.submit(()->{try{start.await();service.complete(id,p);}catch(InterruptedException ex){Thread.currentThread().interrupt();throw new RuntimeException(ex);}}));start.countDown();for(var job:jobs)job.get(30,TimeUnit.SECONDS);} finally {executor.shutdownNow();}
 assertEquals(25L,service.stats(p).get("xp"));assertEquals(1L,history.countByUserId(p.getId()));
 }
}
