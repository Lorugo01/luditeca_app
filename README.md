# LudiTeca - Biblioteca Digital

## 📱 Sobre o Projeto
LudiTeca é uma aplicação de biblioteca digital desenvolvida em Flutter, permitindo aos usuários explorar, ler e gerenciar seus livros favoritos.

## 🛠️ Tecnologias Utilizadas
- Flutter
- GetX (Gerenciamento de Estado)
- Supabase (Backend e Banco de Dados)
- Palette Generator (Extração de cores de imagens)

## 📦 Estrutura do Projeto
```
lib/
├── modules/
│   ├── auth/         # Autenticação e gerenciamento de usuários
│   ├── book/         # Funcionalidades relacionadas a livros
│   ├── library/      # Biblioteca do usuário
│   ├── profile/      # Perfil do usuário
│   └── reader/       # Leitor de livros
├── shared/           # Componentes e utilitários compartilhados
└── main.dart         # Ponto de entrada da aplicação
```

## 🔄 Conexão com o Banco de Dados

### Supabase
O aplicativo utiliza o Supabase como backend, oferecendo:
- Autenticação de usuários
- Armazenamento de dados
- Armazenamento de arquivos (covers dos livros)

### Tabelas Principais
1. **users**
   - id (UUID)
   - email
   - name
   - created_at
   - updated_at

2. **books**
   - id (UUID)
   - title
   - description
   - cover_image
   - author_id
   - created_at
   - updated_at

3. **authors**
   - id (UUID)
   - name
   - biography
   - created_at
   - updated_at

4. **user_books**
   - id (UUID)
   - user_id
   - book_id
   - status (reading, completed, wishlist)
   - created_at
   - updated_at

## 🎨 Funcionalidades Implementadas

### Autenticação
- Login com email/senha
- Registro de novos usuários
- Recuperação de senha

### Biblioteca
- Listagem de livros
- Detalhes do livro com:
  - Capa dinâmica
  - Cor de fundo baseada na capa
  - Sinopse
  - Informações do autor
  - Botões de ação (Ler/Favoritar)

### Perfil
- Visualização de dados do usuário
- Histórico de leitura
- Livros favoritos

## 🔒 Segurança
- Autenticação JWT
- Proteção de rotas
- Validação de dados
- Sanitização de inputs

## 🚀 Como Executar

1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/LudiTeca.git
```

2. Instale as dependências
```bash
flutter pub get
```

3. Configure as variáveis de ambiente
```bash
cp .env.example .env
```

4. Execute o aplicativo
```bash
flutter run
```

## 📝 Próximos Passos
- [ ] Implementar sistema de busca
- [ ] Adicionar suporte offline
- [ ] Implementar sistema de anotações
- [ ] Adicionar suporte a diferentes formatos de livro
- [ ] Implementar sistema de progresso de leitura

## 🤝 Contribuição
1. Faça um Fork do projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/AmazingFeature`)
3. Faça o Commit das suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Faça o Push para a Branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença
Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
