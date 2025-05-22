# tiny_db vs. Other Storage Solutions

This document compares tiny_db with other popular storage solutions for Flutter and Dart applications to help you choose the right tool for your needs.

## Table of Contents

- [Quick Comparison Table](#quick-comparison-table)
- [tiny_db vs. SharedPreferences](#tiny_db-vs-sharedpreferences)
- [tiny_db vs. Isar](#tiny_db-vs-isar)
- [tiny_db vs. Hive](#tiny_db-vs-hive)
- [tiny_db vs. SQLite (via sqflite)](#tiny_db-vs-sqlite-via-sqflite)
- [When to Choose tiny_db](#when-to-choose-tiny_db)

## Quick Comparison Table

| Feature | tiny_db | SharedPreferences | Isar | Hive | SQLite (sqflite) |
|---------|----------------|-------------------|------|------|------------------|
| **Type** | Document DB | Key-Value Store | NoSQL DB | Key-Value Box | Relational DB |
| **Schema** | Schema-free | Key-value only | Schema required | Optional schemas | Schema required |
| **Query Capabilities** | Good | None | Excellent | Basic | Excellent (SQL) |
| **Nested Data** | ✅ | ❌ | ✅ | ✅ | Limited |
| **Code Generation** | ❌ (not needed) | ❌ | ✅ (required) | Optional | ❌ |
| **Pure Dart Option** | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Native Dependencies** | Optional | ✅ | ✅ | Optional | ✅ |
| **Learning Curve** | Low | Very Low | Medium-High | Low-Medium | Medium-High |
| **Performance (Large Data)** | Moderate | N/A | Excellent | Good | Good |
| **Best For** | Small-medium document collections | Simple app settings | High-performance data-intensive apps | Structured object storage | Relational data |

## tiny_db vs. SharedPreferences

### SharedPreferences

**Purpose**: Simple key-value storage for application preferences and settings.

**Strengths**:
- Very simple API
- Built into Flutter
- Fast for simple values

**Limitations**:
- Only stores primitives (strings, numbers, booleans, string lists)
- No query capabilities
- Flat structure (no nesting)
- No table/collection organization

### How tiny_db Compares

tiny_db offers significantly more power and flexibility while maintaining simplicity:

- **Rich Data Types**: Store complex nested objects and arrays
- **Document Organization**: Group related documents in tables
- **Query Capabilities**: Search by field values with logical operators
- **Update Operations**: Specialized operations for lists and nested fields

**Choose tiny_db over SharedPreferences when**:
- You need to store structured data beyond simple preferences
- You need to query your data, not just retrieve by key
- You need to store lists of objects or nested data
- You want a consistent API for both simple and complex data

## tiny_db vs. Isar

### Isar

**Purpose**: High-performance, feature-rich NoSQL database.

**Strengths**:
- Extremely fast (native implementation)
- Advanced indexing and query capabilities
- Full-text search
- ACID compliance
- Reactive queries (streams)

**Limitations**:
- Requires code generation and schema definition
- Steeper learning curve
- Larger footprint with native dependencies
- More setup required

### How tiny_db Compares

tiny_db positions itself as a simpler, more lightweight alternative:

- **Zero Setup**: No code generation or schema definition needed
- **Schema-Free**: Add fields and change structure without migrations
- **Pure Dart Option**: Works without native dependencies
- **Familiar API**: Inspired by Python's TinyDB with a simple, intuitive interface
- **Lower Learning Curve**: Get started in minutes with minimal boilerplate

**Choose tiny_db over Isar when**:
- You prioritize simplicity and rapid development over maximum performance
- You have small to medium-sized datasets
- You prefer schema-free development
- You need a pure Dart solution without native dependencies
- You don't need advanced features like full-text search or reactive queries

## tiny_db vs. Hive

### Hive

**Purpose**: Fast key-value database with box organization.

**Strengths**:
- Very fast for its category
- Type adapters for custom objects
- Lazy loading capabilities
- Encryption support

**Limitations**:
- Limited query capabilities
- Box-based organization (less flexible than collections)
- Less intuitive for document-style data

### How tiny_db Compares

tiny_db offers a more document-oriented approach:

- **Document-Centric**: Designed for document collections, not just key-value pairs
- **Better Querying**: More powerful query capabilities with logical operators
- **Deep Updates**: Specialized operations for nested fields and lists
- **Multi-Table**: Better organization for different types of data

**Choose tiny_db over Hive when**:
- You need more powerful query capabilities
- You prefer a document database model over key-value boxes
- You need specialized operations for lists and nested objects
- You want a simpler API without type adapters

## tiny_db vs. SQLite (via sqflite)

### SQLite (sqflite)

**Purpose**: Full relational database with SQL support.

**Strengths**:
- Mature, proven technology
- Powerful SQL query language
- Excellent for relational data
- Transactions and constraints

**Limitations**:
- Requires schema definition and migrations
- Less natural for nested/document data
- Steeper learning curve with SQL
- More verbose for simple operations

### How tiny_db Compares

tiny_db offers a more approachable, document-oriented alternative:

- **No SQL Required**: Simple method-based API instead of SQL strings
- **Schema-Free**: No tables to define or migrations to manage
- **Nested Data**: Native support for nested objects and arrays
- **Simpler API**: Less boilerplate for common operations

**Choose tiny_db over SQLite when**:
- Your data is document-oriented rather than relational
- You want to avoid SQL and prefer a method-based API
- You need flexibility with changing data structures
- You want to minimize boilerplate code

## When to Choose tiny_db

tiny_db is ideal when:

1. **You're in the middle ground**: Your needs exceed simple key-value storage but don't require a full-featured database
2. **You value simplicity**: You want a clean, intuitive API with minimal setup
3. **Your data is document-oriented**: You work with JSON-like data structures
4. **Schema flexibility matters**: You need to evolve your data structure without migrations
5. **You need portability**: You want code that works across all Dart platforms
6. **You're prototyping**: You need to get something working quickly
7. **You have small-to-medium datasets**: Performance is good but not optimized for very large datasets

tiny_db positions itself as the "just right" option - powerful enough for real applications but simple enough to learn in minutes.
