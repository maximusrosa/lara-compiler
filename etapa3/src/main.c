/*
 * main.c — Ponto de entrada do compilador LARA (Etapa 3 — TAC Completo)
 *
 * INF01083 — Linguagens de Programação II / Compiladores — 2026/2
 * UFRGS / INF — Prof. Leandro Krug Wives (adaptado de Prof. Nicolas Maillard)
 *
 * Pipeline desta etapa:
 *   programa LARA  →  AST  →  TAC com controle de fluxo (stdout)
 *
 * USO:
 *   ./lara < programa.lc                     # imprime TAC na stdout
 *   ./lara < programa.lc 2>/dev/null         # suprime mensagens de depuração
 *
 * CÓDIGO DE SAÍDA:
 *   0 — análise e geração bem-sucedidas
 *   1 — erro sintático ou léxico
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtab.h"
#include "codegen.h"

/* Raiz da AST — preenchida por parser.y durante a análise */
extern ast_node_t *ast_root;

/* Tabela de símbolos global */
symtab_t *global_symtab = NULL;

/* Função do parser gerada pelo bison */
extern int yyparse(void);

int main(int argc, char *argv[])
{
    (void)argc; (void)argv;

    /* Inicializa a tabela de símbolos global */
    global_symtab = symtab_new();
    if (!global_symtab) {
        fprintf(stderr, "ERRO FATAL: não foi possível alocar a tabela de símbolos.\n");
        return 1;
    }

    /* Executa análise léxica + sintática + construção da AST */
    int parse_result = yyparse();
    if (parse_result != 0) {
        fprintf(stderr, "[ETAPA 3] Análise FALHOU (código %d).\n", parse_result);
        symtab_free(global_symtab);
        return 1;
    }

    fprintf(stderr, "[ETAPA 3] Análise CONCLUÍDA com SUCESSO.\n");

    /* Geração de código TAC */
    codegen_ctx_t *cg = codegen_new(global_symtab);
    codegen_program(cg, ast_root);

    /* Imprime o código TAC gerado na stdout */
    tac_print(cg->code, stdout);

    /* Limpeza */
    tac_free(cg->code);
    cg->code = NULL;
    codegen_free(cg);

    ast_free(ast_root);
    symtab_free(global_symtab);
    return 0;
}
