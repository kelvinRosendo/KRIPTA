package com.kripta.controller;
import com.kripta.model.User;
import com.kripta.repository.UserRepository;
import com.kripta.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional class CalendarFlowTest {
 @Autowired MockMvc mvc; @Autowired UserRepository users; @Autowired JwtService jwt;
 String token(String email,User.UserType type){return jwt.generateToken(users.save(new User("Teste",email,"hash",type)));}
 @Test void eventosAvisosELeiturasRespeitamAcesso()throws Exception {
 String a=token("calendar-a@example.com",User.UserType.USUARIO),b=token("calendar-b@example.com",User.UserType.USUARIO),teacher=token("calendar-prof@example.com",User.UserType.PROFESSOR);
 String body="{\"title\":\"Revisão\",\"date\":\"2026-11-03\",\"time\":\"23:30\"}";
 var response=mvc.perform(post("/api/calendario/eventos").header("Authorization","Bearer "+a).contentType("application/json").content(body)).andExpect(status().isCreated()).andReturn();
 long id=new com.fasterxml.jackson.databind.ObjectMapper().readTree(response.getResponse().getContentAsString()).get("id").asLong();
 mvc.perform(get("/api/calendario?inicio=2026-11-03&fim=2026-11-03").header("Authorization","Bearer "+a)).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1));
 mvc.perform(get("/api/calendario?inicio=2026-11-04&fim=2026-11-04").header("Authorization","Bearer "+a)).andExpect(jsonPath("$.length()").value(0));
 mvc.perform(get("/api/calendario?inicio=2026-11-04&fim=2026-11-03").header("Authorization","Bearer "+a)).andExpect(status().isBadRequest());
 mvc.perform(get("/api/calendario/eventos/"+id).header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
 mvc.perform(put("/api/calendario/eventos/"+id).header("Authorization","Bearer "+b).contentType("application/json").content(body)).andExpect(status().isNotFound());
 mvc.perform(patch("/api/notificacoes/"+id+"/ler").header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
 mvc.perform(delete("/api/calendario/eventos/"+id).header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
 for(int i=0;i<2;i++)mvc.perform(patch("/api/notificacoes/"+id+"/ler").header("Authorization","Bearer "+a)).andExpect(status().isNoContent());
 mvc.perform(get("/api/notificacoes").header("Authorization","Bearer "+a)).andExpect(jsonPath("$[0].read").value(true));
 mvc.perform(put("/api/calendario/eventos/"+id).header("Authorization","Bearer "+a).contentType("application/json").content(body.replace("Revisão","Alterado"))).andExpect(status().isOk());
 mvc.perform(get("/api/notificacoes").header("Authorization","Bearer "+a)).andExpect(jsonPath("$[0].read").value(false)).andExpect(jsonPath("$[0].title").value("Alterado"));
 String school=body.substring(0,body.length()-1)+",\"scope\":\"ESCOLAR\"}";
 mvc.perform(post("/api/calendario/eventos").header("Authorization","Bearer "+a).contentType("application/json").content(school)).andExpect(status().isForbidden());
 var result=mvc.perform(post("/api/calendario/eventos").header("Authorization","Bearer "+teacher).contentType("application/json").content(school)).andExpect(status().isCreated()).andReturn();
 long schoolId=new com.fasterxml.jackson.databind.ObjectMapper().readTree(result.getResponse().getContentAsString()).get("id").asLong();
 mvc.perform(get("/api/notificacoes").header("Authorization","Bearer "+b)).andExpect(jsonPath("$.length()").value(1));
 mvc.perform(patch("/api/notificacoes/"+schoolId+"/ler").header("Authorization","Bearer "+b)).andExpect(status().isNoContent());
 mvc.perform(get("/api/notificacoes").header("Authorization","Bearer "+teacher)).andExpect(jsonPath("$[0].read").value(false));
 mvc.perform(delete("/api/calendario/eventos/"+schoolId).header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
 mvc.perform(delete("/api/calendario/eventos/"+id).header("Authorization","Bearer "+a)).andExpect(status().isNoContent());
 mvc.perform(get("/api/notificacoes").header("Authorization","Bearer "+a)).andExpect(jsonPath("$.length()").value(1));
 }
}
