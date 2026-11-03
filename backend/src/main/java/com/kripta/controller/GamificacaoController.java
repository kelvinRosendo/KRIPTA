package com.kripta.controller;
import com.kripta.service.GamificacaoService;
import com.kripta.security.UserPrincipal;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
@RestController @RequestMapping("/api") public class GamificacaoController {
 private final GamificacaoService service;
 public GamificacaoController(GamificacaoService s){service=s;}
 @PostMapping("/usage/heartbeat") public Map<String,Object> heartbeat(@AuthenticationPrincipal UserPrincipal p){return service.heartbeat(p);}
 @GetMapping({"/progresso","/gamificacao/estatisticas"}) public Map<String,Object> stats(@AuthenticationPrincipal UserPrincipal p){return service.stats(p);}
 @GetMapping("/gamificacao/conquistas") public List<Map<String,Object>> achievements(@AuthenticationPrincipal UserPrincipal p){return service.achievements(p);}
}
