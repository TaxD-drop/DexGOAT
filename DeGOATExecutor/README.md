# Distribuição loadstring

`DeGOAT.bundle.lua` é gerado dos módulos em `DeGOATClient/`. Não edite o
bundle manualmente.

Antes de publicar:

1. Execute `python3 tools/build_executor_bundle.py`.
2. Altere `DEFAULT_BASE_URL` em `Loader.lua` para a pasta raw do repositório.
3. Publique `Loader.lua`, `DeGOATExecutor/DeGOAT.bundle.lua` e as fontes
   modulares de `DeGOATClient/`.

Depois disso, a execução pública usa somente:

```lua
loadstring(game:HttpGet("URL_RAW_DO_SEU_REPOSITORIO/Loader.lua"))()
```

O loader baixa apenas o bundle open source do próprio repositório. O botão
`View Script` usa `getscriptbytecode` quando essa função existe no cliente e
passa os bytes ao parser/decompiler Luau local. Ele não chama `decompile`, não
envia código para serviços externos e não executa Python.

O Explorer mostra somente instâncias que foram replicadas para o cliente.
`ServerStorage` aparece na raiz solicitada, mas normalmente estará vazio porque
seus descendentes são mantidos exclusivamente no servidor.
