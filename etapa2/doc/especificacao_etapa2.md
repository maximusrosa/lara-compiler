---
title: "Etapa 2 — Geração de TAC Básico"
subtitle: "INF01083 — Linguagens de Programação II / Compiladores — 2026/2"
author: Nicolas Maillard (INF/UFRGS) - Adaptado por Leandro Wives (INF/UFRGS)
lang: pt-BR
---

# Especificação da Etapa 2 — Geração de TAC Básico

> **Atenção (ambiente de desenvolvimento obrigatório):** Todo o desenvolvimento e teste do projeto deve ser realizado em **Linux** (Ubuntu 22.04 LTS ou equivalente). O compilador `lara` é gerado com GCC, flex e bison para a arquitetura x86-64 Linux. Submissões que funcionem apenas em macOS ou Windows **não** serão aceitas.

---

## 1. Objetivo

Nesta etapa os grupos deverão implementar a **geração de código de três endereços (TAC)** para as construções mais simples da linguagem LARA: expressões aritméticas e relacionais, declarações de variáveis (com cálculo de _offset_ na tabela de símbolos), e atribuições simples.

De forma direta, como resultado da etapa, o compilador LARA recebe um programa-fonte pela entrada padrão e **imprime o TAC gerado na saída padrão**, uma instrução por linha.

---

## 2. Ponto de Partida

Esta etapa **começa a partir da solução completa da Etapa 1** (ou da versão fornecida pelo professor como referência). O diretório `src/` já contém:

| Arquivo                 | Status               | O que é                                        |
| ----------------------- | -------------------- | ---------------------------------------------- |
| `scanner.l`             | Completo             | Scanner da Etapa 1 (com TODOs já resolvidos)   |
| `parser.y`              | Completo             | Gramática da Etapa 1 (com TODOs já resolvidos) |
| `ast.h / ast.c`         | Completo             | AST da Etapa 1                                 |
| `symtab.h / symtab.c`   | **Estendido**        | Tabela de símbolos com*offset* e escopo        |
| `tac.h / tac.c`         | **Novo (esqueleto)** | Estrutura e funções de TAC                     |
| `codegen.h / codegen.c` | **Novo (esqueleto)** | Gerador de código TAC                          |
| `main.c`                | Atualizado           | Chama gerador de código após o parse           |

---

## 3. Representação TAC

O TAC (_Three-Address Code_) da linguagem LARA usa o formato de **quádrupla**:

```
(op, arg1, arg2, result)
```

Impressa como texto no formato:

```
result = arg1 op arg2       (operação binária)
result = op arg1            (operação unária)
result = arg1               (cópia simples)
result = arg1[arg2]         (leitura de array)
arg1[arg2] = result         (escrita em array)
```

### 3.1 Operações suportadas nesta etapa

| Enum (`tac_op_t`) | Texto impresso    | Descrição                     |
| ----------------- | ----------------- | ----------------------------- |
| `TAC_COPY`        | `t = a`           | Cópia simples                 |
| `TAC_ADD`         | `t = a + b`       | Adição                        |
| `TAC_SUB`         | `t = a - b`       | Subtração                     |
| `TAC_MUL`         | `t = a * b`       | Multiplicação                 |
| `TAC_DIV`         | `t = a / b`       | Divisão                       |
| `TAC_MOD`         | `t = a % b`       | Módulo                        |
| `TAC_NEG`         | `t = -a`          | Negação aritmética            |
| `TAC_LT`          | `t = a < b`       | Menor que (resultado 0 ou 1)  |
| `TAC_GT`          | `t = a > b`       | Maior que                     |
| `TAC_LE`          | `t = a <= b`      | Menor ou igual                |
| `TAC_GE`          | `t = a >= b`      | Maior ou igual                |
| `TAC_EQ`          | `t = a == b`      | Igualdade                     |
| `TAC_NE`          | `t = a != b`      | Diferença                     |
| `TAC_LOAD`        | `t = v[i]`        | Leitura de array              |
| `TAC_STORE`       | `v[i] = t`        | Escrita em array              |
| `TAC_DECL_GLOBAL` | `global v, size`  | Declaração de variável global |
| `TAC_DECL_LOCAL`  | `local v, offset` | Declaração de variável local  |

### 3.2 Temporários e nomes

- Temporários gerados internamente: `_t1`, `_t2`, `_t3`, ...
- Variáveis do programa: usam seu nome original do programa-fonte
- Literais inteiros e floats: representados diretamente como strings (`"42"`, `"3.14"`)

---

## 4. Tabela de Símbolos Estendida

A tabela de símbolos da Etapa 1 é estendida com:

- `nature` (já existia): `SYM_VAR`, `SYM_ARRAY`, `SYM_FUNCTION`
- `datatype` (já existia): `SYM_TYPE_INT`, `SYM_TYPE_FLOAT`, etc.
- `scope` (**novo**): `SYM_SCOPE_GLOBAL` ou `SYM_SCOPE_LOCAL`
- `offset` (**novo**): deslocamento em bytes no segmento de dados (global) ou no frame (local)
- `array_size` (**novo**): número de elementos (apenas para arrays)

**Cálculo de _offsets_:**

- Variáveis globais: alocadas sequencialmente a partir do offset 0 no segmento `.bss`
- Variáveis locais: alocadas sequencialmente a partir do offset 0 no _frame_ da função
- Tamanho de cada tipo: `int`=4, `float`=8, `char`=1, `bool`=1

---

## 5. Tarefas dos Alunos

### TODO-E2-A: Extensão da tabela de símbolos (`symtab.c`)

Complete a função `symtab_set_offset()` que percorre todas as declarações
de um escopo e atribui offsets consecutivos. A função `symtab_enter_scope()`
e `symtab_exit_scope()` já estão implementadas.

### TODO-E2-B: Geração de TAC para expressões (`codegen.c`)

Complete a função `codegen_expr(ast_node_t *node)` para os nós:

- `AST_EXPR_BINARY` com operadores `+`, `-`, `*`, `/`, `%`
- `AST_EXPR_UNARY` com operador `-`
- `AST_SYMBOL` (variável) e literais (`AST_LIT_INT`, `AST_LIT_FLOAT`)

A função deve retornar o nome do temporário ou variável que contém o resultado.

### TODO-E2-C: Geração de TAC para operadores relacionais (`codegen.c`)

Estenda `codegen_expr()` para também cobrir:

- `AST_EXPR_BINARY` com operadores `<`, `>`, `<=`, `>=`, `==`, `!=`

### TODO-E2-D: Geração de TAC para atribuição simples (`codegen.c`)

Complete a função `codegen_stmt()` para o nó `AST_ASSIGN` com `:=`.
Deve gerar um `TAC_COPY` com o resultado da expressão no lado direito.

---

## 6. Exemplo

### Entrada (`tests/valid/02_expr.lc` da Etapa 1)

```c
fun void main() {
    let x := 10 ;
    let y := 20 ;
    x := x + y * 2 ;
    print x ;
}
```

### Saída esperada

```
local x, 0
local y, 4
_t1 = 2
_t2 = y * _t1
_t3 = x + _t2
x = _t3
print x
```

---

## 7. Entrega e Avaliação

### Sessão de laboratório (30/09/2026)

No encontro, cada grupo demonstra ao professor a compilação do projeto (`make`) e a execução de pelo menos 3 programas de teste (`bash tests/run_tests.sh`).

O professor pode fazer perguntas a qualquer integrante do grupo sobre o código escrito; grupos que não souberem explicar perdem a nota proporcional ao TODO.

### Prazo de entrega no Moodle: lab + 48 horas

Após o laboratório, os grupos têm **48 horas** para incorporar correções e submeter a versão final.

- **Deadline:** sexta-feira, 2 de outubro de 2026 (18h)
- **Formato:** `etapa2-grupo-NOME.tar.gz` gerado a partir do repositório GitHub

```bash
tar czf etapa2-grupo-NOME.tar.gz \
    --exclude='src/*.o'          \
    --exclude='src/lex.yy.c'     \
    --exclude='src/parser.tab.*' \
    --exclude='lara'             \
    src/ tests/ Makefile
```

## 8. Critérios de Avaliação

| Critério                                   | Peso |
| ------------------------------------------ | ---- |
| TODO-E2-A: offsets na tabela de símbolos   | 20%  |
| TODO-E2-B: TAC para expressões aritméticas | 30%  |
| TODO-E2-C: TAC para operadores relacionais | 20%  |
| TODO-E2-D: TAC para atribuição simples     | 30%  |
