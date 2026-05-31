# Tarefas & Mesada Inteligente

App de gamificacao para criancas gerenciarem tarefas e mesada, com visao separada para pais e filhos.

## Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage)
- **Deploy**: Coolify (Docker)

## Estrutura do Projeto
```
lib/
  core/          # Theme, constants, utils
  models/        # Data models
  services/      # Supabase client, auth, notifications
  providers/     # State management
  screens/       # Telas do app
    auth/        # Login, cadastro
    parent/      # Dashboard, aprovar, relatorios, config
    child/       # Home, tarefas, loja, cartas, insignias
  widgets/       # Componentes reutilizaveis
```

## Ambientes
- **dev**: tarefas-mesada-dev.vinculodigital.com.br
- **prd**: (dominio final a definir)
