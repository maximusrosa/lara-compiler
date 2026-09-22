#!/usr/bin/env bash
# run_tests.sh — Suite de testes da Etapa 2
# INF01083 — Linguagens de Programação II / Compiladores — 2026/2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
COMPILER="$ROOT_DIR/lara"
SOL_COMPILER="$ROOT_DIR/solution/lara_ref"

if [ ! -x "$COMPILER" ]; then
    echo "Compilando 'lara'..."
    (cd "$ROOT_DIR" && make >/dev/null 2>&1)
    if [ ! -x "$COMPILER" ]; then
        echo "ERRO: compilador '$COMPILER' não encontrado. Execute 'make' primeiro."
        exit 1
    fi
fi

# Se houver a pasta solution/ com código do professor, garante que lara_ref esteja compilado
HAS_GABARITO=0
if [ -d "$ROOT_DIR/solution" ]; then
    if [ ! -x "$SOL_COMPILER" ] || [ "$ROOT_DIR/solution/codegen_solution.c" -nt "$SOL_COMPILER" ]; then
        (cd "$ROOT_DIR" && make solution >/dev/null 2>&1)
    fi
    if [ -x "$SOL_COMPILER" ]; then
        HAS_GABARITO=1
    fi
fi

passed=0
failed=0

echo "========================================================"
if [ $HAS_GABARITO -eq 1 ]; then
    echo "=== MODO PROFESSOR: Avaliação com Gabarito Dinâmico  ==="
else
    echo "=== MODO ALUNO: Testes de Sanity Check e Sintaxe     ==="
fi
echo "========================================================"
echo ""

echo "--- Testes VÁLIDOS (Geração de TAC) ---"
for f in "$SCRIPT_DIR/valid/"*.lc; do
    base="$(basename "$f")"
    expected_file="${f%.lc}.expected"
    actual_tmp="/tmp/_actual_e2_$$.txt"
    expected_tmp="/tmp/_expected_e2_$$.txt"

    # Executa o compilador do aluno/projeto
    "$COMPILER" < "$f" > "$actual_tmp" 2>/dev/null
    exit_code=$?

    if [ $HAS_GABARITO -eq 1 ]; then
        # Modo Professor: gera a saída esperada dinamicamente via lara_ref
        "$SOL_COMPILER" < "$f" > "$expected_tmp" 2>/dev/null
        if [ $exit_code -eq 0 ] && diff -q "$actual_tmp" "$expected_tmp" > /dev/null 2>&1; then
            echo "  [OK] $base"
            passed=$((passed + 1))
        else
            echo "  [FALHOU] $base"
            if [ $exit_code -ne 0 ]; then
                echo "         Código retornou erro ($exit_code)"
            else
                echo "         Diferença em relação ao gabarito:"
                diff -u "$expected_tmp" "$actual_tmp" | head -15 | sed 's/^/         /'
            fi
            failed=$((failed + 1))
        fi
        rm -f "$expected_tmp"
    else
        # Modo Aluno: usa .expected fixo (sanity check) se existir
        if [ -f "$expected_file" ]; then
            if [ $exit_code -eq 0 ] && diff -q "$actual_tmp" "$expected_file" > /dev/null 2>&1; then
                echo "  [OK - Sanity Check] $base"
                passed=$((passed + 1))
            else
                echo "  [FALHOU - Sanity Check] $base"
                diff -u "$expected_file" "$actual_tmp" | head -15 | sed 's/^/         /'
                failed=$((failed + 1))
            fi
        else
            # Teste sem .expected público: apenas valida se compila sem erro
            if [ $exit_code -eq 0 ]; then
                echo "  [OK - Compilou sem erro] $base"
                passed=$((passed + 1))
            else
                echo "  [FALHOU - Erro de execução] $base"
                failed=$((failed + 1))
            fi
        fi
    fi

    rm -f "$actual_tmp"
done

echo ""
echo "--- Testes INVÁLIDOS (Devem ser rejeitados) ---"
for f in "$SCRIPT_DIR/invalid/"*.lc; do
    base="$(basename "$f")"
    "$COMPILER" < "$f" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "  [OK - Rejeitado com sucesso] $base"
        passed=$((passed + 1))
    else
        echo "  [FALHOU - Deveria ter sido rejeitado] $base"
        failed=$((failed + 1))
    fi
done

echo ""
echo "========================================================"
echo " Resultado: $passed passou(aram), $failed falhou(aram)"
echo "========================================================"

[ $failed -eq 0 ] && exit 0 || exit 1
