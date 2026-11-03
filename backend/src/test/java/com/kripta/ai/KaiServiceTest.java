package com.kripta.ai;
import org.junit.jupiter.api.Test;
import java.time.Duration;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
class KaiServiceTest {
 AiProvider adapter(String id,String reply){return new AiProvider(){public String id(){return id;}public String reply(String system,String message,Duration timeout){assertFalse(system.isBlank());assertEquals("Pergunta",message);return reply;}};}
 @Test void selecionaProvedorSemMudarContrato(){var adapters=List.of(adapter("a","Resposta A"),adapter("b","Resposta B"));try(var a=new KaiService(adapters,"a",20);var b=new KaiService(adapters,"b",20)){assertEquals("Resposta A",a.chat("Pergunta"));assertEquals("Resposta B",b.chat("Pergunta"));}}
 @Test void semProvedorNaoSimulaResposta(){try(var service=new KaiService(List.of(),"disabled",20)){assertThrows(KaiException.class,()->service.chat("Pergunta"));}}
 @Test void rejeitaIdsDuplicados(){assertThrows(IllegalArgumentException.class,()->new KaiService(List.of(adapter("a","x"),adapter("a","y")),"a",20));}
 @Test void respostaVaziaViraIndisponibilidade(){try(var service=new KaiService(List.of(adapter("a"," ")),"a",20)){assertThrows(KaiException.class,()->service.chat("Pergunta"));}}
 @Test void errosDoProvedorNaoExpoemSegredos(){AiProvider provider=new AiProvider(){public String id(){return "a";}public String reply(String s,String m,Duration d){throw new IllegalStateException("secret-provider-token");}};try(var service=new KaiService(List.of(provider),"a",20)){var error=assertThrows(KaiException.class,()->service.chat("Pergunta"));assertFalse(error.getMessage().contains("secret"));assertNull(error.getCause());}}
 @Test void aplicaTimeout(){AiProvider provider=new AiProvider(){public String id(){return "a";}public String reply(String s,String m,Duration d)throws Exception{Thread.sleep(10000);return "late";}};try(var service=new KaiService(List.of(provider),"a",1)){assertThrows(KaiException.class,()->service.chat("Pergunta"));}}
}
