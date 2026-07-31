package com.bionova.config;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Stack;

public class SQLParenCheck {
    public static void main(String[] args) throws Exception {
        String sql = new String(Files.readAllBytes(Paths.get("sql_check.sql")));
        System.out.println("SQL Length: " + sql.length());
        
        Stack<Integer> parenStack = new Stack<>();
        Stack<Integer> dollarStack = new Stack<>();
        
        boolean inSingleQuote = false;
        int singleQuoteStart = -1;
        
        for (int i = 0; i < sql.length(); i++) {
            char c = sql.charAt(i);
            
            // Handle single quotes
            if (c == '\'') {
                if (inSingleQuote) {
                    // Check if it's an escaped single quote (e.g. '')
                    if (i + 1 < sql.length() && sql.charAt(i + 1) == '\'') {
                        i++; // skip next quote
                    } else {
                        inSingleQuote = false;
                    }
                } else {
                    inSingleQuote = true;
                    singleQuoteStart = i;
                }
                continue;
            }
            
            if (inSingleQuote) {
                continue;
            }
            
            // Check for dollar-quoted string $$
            if (c == '$' && i + 1 < sql.length() && sql.charAt(i + 1) == '$') {
                if (!dollarStack.isEmpty()) {
                    dollarStack.pop();
                } else {
                    dollarStack.push(i);
                }
                i++; // skip next $
                continue;
            }
            
            if (!dollarStack.isEmpty()) {
                // Inside $$ ... $$ we don't check parentheses unless they are the outer ones?
                // Actually, the outer $$ bounds the PL/pgSQL function body, but PostgreSQL parses inside it.
                // But let's check parenthesis balance inside it anyway.
            }
            
            if (c == '(') {
                parenStack.push(i);
            } else if (c == ')') {
                if (parenStack.isEmpty()) {
                    System.err.println("Mismatched closing parenthesis ')' at index " + i + " around: " + sql.substring(Math.max(0, i-20), Math.min(sql.length(), i+20)));
                } else {
                    parenStack.pop();
                }
            }
        }
        
        if (inSingleQuote) {
            System.err.println("Unclosed single quote starting at index " + singleQuoteStart + " around: " + sql.substring(singleQuoteStart, Math.min(sql.length(), singleQuoteStart + 50)));
        }
        
        while (!parenStack.isEmpty()) {
            int openIdx = parenStack.pop();
            System.err.println("Unclosed open parenthesis '(' at index " + openIdx + " around: " + sql.substring(openIdx, Math.min(sql.length(), openIdx + 50)));
        }
        
        if (!dollarStack.isEmpty()) {
            System.err.println("Unclosed dollar quote starting at index " + dollarStack.peek());
        }
        
        System.out.println("Checks finished.");
    }
}
