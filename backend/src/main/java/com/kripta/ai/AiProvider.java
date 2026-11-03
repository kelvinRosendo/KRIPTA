package com.kripta.ai;
import java.time.Duration;
/** Implemented by each server-side provider adapter. Never expose credentials to clients. */
public interface AiProvider {
 String id();
 String reply(String systemInstructions, String message, Duration timeout) throws Exception;
}
