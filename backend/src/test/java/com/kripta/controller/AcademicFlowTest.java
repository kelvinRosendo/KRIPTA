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
@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional
class AcademicFlowTest {
 @Autowired MockMvc mvc; @Autowired UserRepository users; @Autowired JwtService jwt;
 String token(String email,User.UserType type,boolean approve){var u=new User("Teste",email,"hash",type);u.setPodeAprovar(approve);return jwt.generateToken(users.save(u));}
 long id(String path,String token,String body)throws Exception {var r=mvc.perform(post(path).header("Authorization","Bearer "+token).contentType("application/json").content(body)).andExpect(status().isCreated()).andReturn();return new com.fasterxml.jackson.databind.ObjectMapper().readTree(r.getResponse().getContentAsString()).get("id").asLong();}
 @Test void publicacaoEAprovacaoProtegemConteudo()throws Exception {
  String teacher=token("teacher@a.com",User.UserType.PROFESSOR,false), reviewer=token("reviewer@a.com",User.UserType.PROFESSOR,true),student=token("student@a.com",User.UserType.USUARIO,false);
  long component=id("/api/componentes",teacher,"{\"name\":\"Matemática\"}");
  String body="{\"subjectId\":"+component+",\"title\":\"Aula\",\"type\":\"PDF\"}";
  mvc.perform(post("/api/conteudos").header("Authorization","Bearer "+student).contentType("application/json").content(body)).andExpect(status().isForbidden());
  long content=id("/api/conteudos",teacher,body);
  mvc.perform(get("/api/conteudos/"+content).header("Authorization","Bearer "+student)).andExpect(status().isNotFound());
  mvc.perform(patch("/api/conteudos/"+content+"/aprovar").header("Authorization","Bearer "+teacher)).andExpect(status().isForbidden());
  mvc.perform(patch("/api/conteudos/"+content+"/aprovar").header("Authorization","Bearer "+reviewer)).andExpect(status().isOk()).andExpect(jsonPath("$.status").value("APROVADO"));
  mvc.perform(get("/api/conteudos/"+content).header("Authorization","Bearer "+student)).andExpect(status().isOk());
  mvc.perform(patch("/api/conteudos/"+content+"/aprovar").header("Authorization","Bearer "+reviewer)).andExpect(status().isConflict());
  long rejected=id("/api/conteudos",teacher,body);
  mvc.perform(patch("/api/conteudos/"+rejected+"/rejeitar").header("Authorization","Bearer "+reviewer).contentType("application/json").content("{\"reason\":\"Revisar\"}")).andExpect(status().isOk());
  mvc.perform(get("/api/conteudos/"+rejected).header("Authorization","Bearer "+student)).andExpect(status().isNotFound());
 }
 @Test void tarefasEUnidadesSaoPrivadas()throws Exception {
  String a=token("a@a.com",User.UserType.USUARIO,false), b=token("b@a.com",User.UserType.USUARIO,false);
  long subject=id("/api/disciplinas",a,"{\"nome\":\"Matemática\"}");
  long unit=id("/api/disciplinas/"+subject+"/unidades",a,"{\"name\":\"Unidade\"}");
  long material=id("/api/unidades/"+unit+"/materiais",a,"{\"title\":\"Nota\"}");
  mvc.perform(get("/api/unidades/"+unit+"/materiais").header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
  mvc.perform(patch("/api/materiais/"+material+"/concluir").header("Authorization","Bearer "+a)).andExpect(status().isOk()).andExpect(jsonPath("$.completed").value(true));
  long task=id("/api/tarefas",a,"{\"title\":\"Revisar\",\"priority\":\"HIGH\"}");
  mvc.perform(patch("/api/tarefas/"+task+"/concluir").header("Authorization","Bearer "+b)).andExpect(status().isNotFound());
  for(int i=0;i<2;i++)mvc.perform(patch("/api/tarefas/"+task+"/concluir").header("Authorization","Bearer "+a)).andExpect(status().isOk()).andExpect(jsonPath("$.completed").value(true));
 }
}
