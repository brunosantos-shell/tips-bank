## Justificativa técnica — uso de Distroless

As APIs Python foram empacotadas com Dockerfile multi-stage.

No primeiro estágio, foi usada a imagem `python:3.11-slim-bookworm` como builder, contendo pip, compiladores e dependências necessárias para instalar os pacotes da aplicação.

No segundo estágio, foi usada a imagem `gcr.io/distroless/python3-debian12:nonroot`, que não possui shell, gerenciador de pacotes ou ferramentas administrativas. Isso reduz a superfície de ataque, diminui o tamanho da imagem final e evita que binários desnecessários estejam disponíveis em produção.

As dependências Python foram instaladas com `pip install --target=/packages` em vez de virtualenv. Essa abordagem foi usada porque, em imagens Distroless, o binário Python pode estar em caminho diferente do ambiente builder, fazendo com que um virtualenv criado no builder quebre no runtime.

Para resolver isso, as dependências foram copiadas para `/packages` e a aplicação define:

- `PYTHONPATH=/packages`
- `PATH=/packages/bin:$PATH`

Dessa forma, a aplicação consegue importar e executar as dependências corretamente dentro do runtime Distroless.

O container final roda com usuário non-root `65532:65532`, reduzindo o risco caso a aplicação seja comprometida.