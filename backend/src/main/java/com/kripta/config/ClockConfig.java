package com.kripta.config;
@org.springframework.context.annotation.Configuration public class ClockConfig {
 @org.springframework.context.annotation.Bean public java.time.Clock appClock(){return java.time.Clock.systemUTC();}
}
