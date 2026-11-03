package com.kripta.ai;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.*;
@Service public class KaiService implements AutoCloseable {
 private final Map<String,AiProvider> providers;
 private final String selected;
 private final Duration timeout;
 private final ThreadPoolExecutor executor = new ThreadPoolExecutor(2,4,30,TimeUnit.SECONDS,new ArrayBlockingQueue<>(8),r->{var t=new Thread(r,"kai-provider");t.setDaemon(true);return t;},new ThreadPoolExecutor.AbortPolicy());
 private static final String INSTRUCTIONS="Você é Kai, tutor de estudos do KRIPTA. Responda em português com clareza. Ajude o aluno a aprender, explicar conteúdos e planejar revisões. Você não tem acesso a tarefas, materiais ou dados pessoais do sistema; não invente esse acesso.";
 public KaiService(List<AiProvider> adapters,@Value("${app.ai.provider:disabled}") String selected,@Value("${app.ai.timeout-seconds:20}") int seconds){
  var registry=new HashMap<String,AiProvider>();for(var adapter:adapters){if(registry.putIfAbsent(adapter.id(),adapter)!=null)throw new IllegalArgumentException("Duplicate AI provider id");}this.providers=Map.copyOf(registry);this.selected=selected;this.timeout=Duration.ofSeconds(Math.max(1,Math.min(seconds,60)));
 }
 public String chat(String message){var provider=providers.get(selected);if(provider==null)throw new KaiException();Future<String> task=null;try{task=executor.submit(()->provider.reply(INSTRUCTIONS,message,timeout));String reply=task.get(timeout.toMillis(),TimeUnit.MILLISECONDS);if(reply==null||reply.isBlank())throw new KaiException();if(reply.length()>16000)throw new KaiException();return reply.trim();}catch(InterruptedException ex){Thread.currentThread().interrupt();throw new KaiException();}catch(ExecutionException|TimeoutException|RejectedExecutionException ex){throw new KaiException();}finally{if(task!=null&&!task.isDone())task.cancel(true);}}
 @Override @jakarta.annotation.PreDestroy public void close(){executor.shutdownNow();}
}
