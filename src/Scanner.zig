const Scanner = @This();
const std = @import("std");
const Token = @import("Token.zig");

source_code: []const u8,
index: usize,
line: usize,

pub const Error = error{
    UnterminatedString,
    UnrecognizedCharacter,
};

pub fn new(source_code: []const u8) Scanner {
    return Scanner{
        .source_code = source_code,
        .index = 0,
        .line = 1,
    };
}

pub fn scan(this: *Scanner) Error!?Token {
    this.skipWhitespace();

    this.index = 0;

    if (this.isAtEnd()) return null;

    return switch (this.advance()) {
        '(' => this.makeToken(.left_paren),
        ')' => this.makeToken(.right_paren),
        '{' => this.makeToken(.left_brace),
        '}' => this.makeToken(.right_brace),
        ';' => this.makeToken(.semicolon),
        ',' => this.makeToken(.comma),
        '.' => this.makeToken(.dot),
        '-' => this.makeToken(.minus),
        '+' => this.makeToken(.plus),
        '/' => this.makeToken(.slash),
        '*' => this.makeToken(.asterisk),
        '!' => this.makeToken(if (this.match('=')) .bang_equal else .bang),
        '=' => this.makeToken(if (this.match('=')) .equal_equal else .equal),
        '<' => this.makeToken(if (this.match('=')) .less_equal else .less),
        '>' => this.makeToken(if (this.match('=')) .greater_equal else .greater),
        '"' => this.string(),
        '0'...'9' => this.number(),
        'a'...'z', 'A'...'Z', '_' => this.identifier(),
        else => Error.UnrecognizedCharacter,
    };
}

fn string(this: *Scanner) Error!?Token {
    while (this.peek() != '"' and !this.isAtEnd()) {
        if (this.peek() == '\n') this.line += 1;
        this.skip();
    }

    if (this.isAtEnd()) return Error.UnterminatedString;

    this.skip(); // the closing quote.
    return this.makeToken(.string);
}

fn number(this: *Scanner) Token {
    while (isDigit(this.peek())) this.skip();

    if (this.peek() == '.' and isDigit(this.peekNext())) {
        this.skip(); // the “.”.

        while (isDigit(this.peek())) this.skip();
    }

    return this.makeToken(.number);
}

fn identifier(this: *Scanner) Token {
    while (isLetter(this.peek()) or isDigit(this.peek()) or this.peek() == '_') this.skip();

    return this.makeToken(this.identifierType());
}

fn identifierType(this: Scanner) Token.Type {
    if (this.current().len == 0) unreachable;
    if (this.current().len == 1) return Token.Type.identifier;

    switch (this.current()[0]) {
        'a' => if (std.mem.eql(u8, this.current()[1..], "and"[1..])) return Token.Type.@"and",
        'c' => if (std.mem.eql(u8, this.current()[1..], "class"[1..])) return Token.Type.class,
        'e' => if (std.mem.eql(u8, this.current()[1..], "else"[1..])) return Token.Type.@"else",
        'f' => {
            if (this.current().len >= 2) switch (this.current()[1]) {
                'a' => if (std.mem.eql(u8, this.current()[2..], "false"[2..])) return Token.Type.false,
                'o' => if (std.mem.eql(u8, this.current()[2..], "for"[2..])) return Token.Type.@"for",
                'u' => if (std.mem.eql(u8, this.current()[2..], "fun"[2..])) return Token.Type.fun,
                else => {},
            };
        },
        'i' => if (std.mem.eql(u8, this.current()[1..], "if"[1..])) return Token.Type.@"if",
        'n' => if (std.mem.eql(u8, this.current()[1..], "nil"[1..])) return Token.Type.nil,
        'o' => if (std.mem.eql(u8, this.current()[1..], "or"[1..])) return Token.Type.@"or",
        'p' => if (std.mem.eql(u8, this.current()[1..], "print"[1..])) return Token.Type.print,
        'r' => if (std.mem.eql(u8, this.current()[1..], "return"[1..])) return Token.Type.@"return",
        's' => if (std.mem.eql(u8, this.current()[1..], "super"[1..])) return Token.Type.super,
        't' => {
            if (this.current().len >= 2) switch (this.current()[1]) {
                'h' => if (std.mem.eql(u8, this.current()[2..], "this"[2..])) return Token.Type.this,
                'r' => if (std.mem.eql(u8, this.current()[2..], "true"[2..])) return Token.Type.true,
                else => {},
            };
        },
        'v' => if (std.mem.eql(u8, this.current()[1..], "var"[1..])) return Token.Type.@"var",
        'w' => if (std.mem.eql(u8, this.current()[1..], "while"[1..])) return Token.Type.@"while",
        else => return Token.Type.identifier,
    }

    return Token.Type.identifier;
}

fn current(this: Scanner) []const u8 {
    return this.source_code[0..this.index];
}

fn isAtEnd(this: Scanner) bool {
    return this.index >= this.source_code.len;
}

fn skip(this: *Scanner) void {
    this.index += 1;
}

fn advance(this: *Scanner) u8 {
    defer this.skip();
    return this.source_code[this.index];
}

fn match(this: *Scanner, char: u8) bool {
    if (this.isAtEnd()) return false;
    if (this.source_code[this.index] != char) return false;

    this.index += 1;
    return true;
}

fn peek(this: Scanner) u8 {
    if (this.isAtEnd()) return 0;
    return this.source_code[this.index];
}

fn peekNext(this: Scanner) u8 {
    if (this.isAtEnd()) return 0;
    return this.source_code[this.index + 1];
}

fn skipWhitespace(this: *Scanner) void {
    var c = this.peek();
    while (true) : (c = this.peek()) switch (c) {
        ' ', '\r', '\t' => this.skip(),
        '\n' => {
            this.line += 1;
            this.skip();
        },
        '/' => {
            if (this.peekNext() != '/') break;

            while (this.peek() != '\n' and !this.isAtEnd()) this.skip();
        },
        else => break,
    };
}

fn makeToken(this: Scanner, @"type": Token.Type) Token {
    return Token{
        .type = @"type",
        .text = this.current(),
        .line = this.line,
    };
}

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn isLetter(char: u8) bool {
    return char >= 'a' and char <= 'z' or char >= 'A' and char <= 'Z';
}
