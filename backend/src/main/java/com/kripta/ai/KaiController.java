package com.kripta.ai;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/ai") public class KaiController {
 private final KaiService kai;
 public KaiController(KaiService kai){this.kai=kai;}
 public record Input(@NotBlank @Size(max=4000) String message){}
 public record Output(String reply){}
 @PostMapping("/chat") public Output chat(@Valid @RequestBody Input input){return new Output(kai.chat(input.message()));}
}
