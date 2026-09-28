# Arquitetura do DeGOAT

## Pipeline

```text
raw / base64 / hex / JSON
          |
          v
  normalização de entrada
          |
          v
 parser Luau serializado ──> strings, protos, constantes, tipos e debug info
          |
          v
 detector de opcode ───────> oficial ou Roblox `op * 227 mod 256`
          |
          +──────────────> disassembler (auditoria exata)
          |
          v
 CFG ──> dominadores/back-edges ──> fluxo de dados simbólico
                                          |
                                          v
                         estruturador de regiões e loops
                                          |
                                          v
                         nomes inferidos + Luau válido
```

O parser segue a ordem usada pelo loader oficial do Luau: versões, tabela de
strings, mapeamento de userdata, protos, words de instrução, constantes,
filhos, informação de linha e debug. Leituras são limitadas e verificadas para
que entrada truncada não seja silenciosamente aceita.

## O que foi inferido dos exemplos

Os quatro blobs têm bytecode versão 9, tipos versão 3, opcodes Roblox e um
trailer opaco de 24 bytes. Esse trailer não pertence ao formato serializado
documentado pelo Luau; o loader termina após o id do proto principal. O DeGOAT
o preserva e informa, sem atribuir uma finalidade que os dados não provam.

O encoding dos opcodes é reversível. Se `e = (op * 227) mod 256`, então o
decoder usa `op = (e * inverse(227)) mod 256`. Só o byte baixo do cabeçalho de
cada instrução é alterado; palavras `AUX` permanecem intactas.

## Por que SHA, XXHash e Vector não entram no decoder

`SHA1`, `SHA224`, `SHA256`, `SHA384`, `SHA512`, `XXHash32`, `UTF8Sub`,
`VecMin`, `VecMax`, `VecToColor`, `ScaleUDim2` e módulos parecidos são código
da aplicação dentro de `ReplicatedStorage`. Eles implementam funções chamadas
pelo jogo. Não participam da serialização Luau nem da transformação dos
opcodes observada nos blobs.

O comando `inspect --corpus ReplicatedStorage` cruza strings do bytecode com
nomes de módulos locais. Assim esses módulos aparecem quando houver evidência
de que um script os carrega, sem acoplá-los artificialmente ao cérebro do
decompilador.

## Reconstrução e segurança das transformações

O CFG divide as instruções em basic blocks e calcula predecessores,
sucessores, dominadores e back-edges. O estruturador usa também os pares
`FOR*PREP`/`FOR*LOOP` e regiões de salto para recuperar loops, guards,
`if`/`else` e cadeias booleanas.

O fluxo de dados não trata um texto nem um registrador físico como se fossem um
valor permanente. Cada definição cria uma versão própria, com nome e evidência
semântica próprios. Registradores reciclados pela VM deixam de fazer uma tabela
de tween, um `Character` e um cache de `HumanoidRootPart` compartilharem o mesmo
nome no fonte reconstruído.

Cada expressão também carrega suas dependências. Antes de um registrador ser
reutilizado ou de uma escrita possivelmente aliasada, valores ainda vivos são
materializados. Assim, `oldSize = part.Size; part.Size /= 10` não vira uma
leitura tardia do tamanho já alterado. Antes de um upvalue ser alterado, seu
valor antigo também é salvo quando necessário.

Nomes são propostas por definição, com confiança e motivo. Evidências fortes
incluem `GetService("TweenService")`, loaders com literal, `newSound` seguido de
`Play`, argumento goal de `TweenService:Create` e uso transitivo por upvalues.
Uma cadeia que apenas passa por `game.ReplicatedStorage.SoundModule` não pode
batizar o retorno de `newSound` como `ReplicatedStorage`. Sem evidência forte, o
nome fica deliberadamente genérico (`vN`). Captures são expostos em cada closure
como `(copy)` para `VAL` e `(ref)` para `REF`/`UPVAL`.

`LOADB` com skip, varargs e chamadas/retornos com contagem zero têm tratamento
próprio. `DUPTABLE` recupera valores constantes da template. Como Roblox Luau
não possui `goto`, continuations compartilhadas irreduzíveis são duplicadas de
forma conservadora em vez de emitir sintaxe inexistente.

## Limites honestos

Bytecode não guarda comentários, formatação, a maioria dos nomes locais nem a
forma exata da expressão fonte. Nomes inferidos são legíveis, mas não são
apresentados como nomes originais. As definições são versionadas como em SSA,
mas merges ainda usam células estabilizadas por liveness em vez de nós phi
formais. Em fluxo irredutível, a duplicação conservadora pode produzir mais
linhas que a fonte. O disassembly continua sendo a referência exata para
auditoria byte a byte.

As 18 fixtures atuais foram decompiladas e recompiladas com o compilador
oficial Luau sem erros de sintaxe. Isso prova validade sintática e cobre os
padrões presentes no corpus, não equivalência formal para todo bytecode Luau.

O parser entende as estruturas das versões 3 a 12, mas a suíte fornecida cobre
concretamente a versão 9. Versões 10 a 12 contêm recursos experimentais e
devem ser validadas com fixtures antes de serem consideradas produção.
