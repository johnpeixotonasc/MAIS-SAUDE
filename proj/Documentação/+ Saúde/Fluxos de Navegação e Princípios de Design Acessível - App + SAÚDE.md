# Fluxos de Navegação e Princípios de Design Acessível - App + SAÚDE

Este documento detalha os fluxos de navegação propostos e os princípios de design acessível a serem seguidos no desenvolvimento do aplicativo "+ SAÚDE", com base nas funcionalidades definidas e nas melhores práticas para o público idoso.

## 1. Estrutura de Navegação Principal

Propõe-se uma **barra de navegação inferior (Bottom Navigation Bar)** como método principal de navegação. Esta abordagem é familiar para usuários de smartphones e permite acesso rápido às seções principais com um único toque.

*   **Ícones:** Grandes, claros, com alto contraste e universalmente reconhecíveis (ex: pílula para Medicamentos, calendário para Agenda, coração/gráfico para Diário, telefone/sirene para Emergência, livro/play para Educação).
*   **Rótulos:** Texto claro e legível abaixo de cada ícone, descrevendo a seção (ex: "Remédios", "Agenda", "Diário", "Emergência", "Educar").
*   **Número de Itens:** Idealmente 4-5 itens principais para evitar sobrecarga. Seções como "Perfil", "Configurações" e "Familiares" podem ser agrupadas em um item "Mais" ou "Perfil" na barra de navegação ou acessadas por um ícone de engrenagem/pessoa no cabeçalho da tela.
*   **Feedback Visual:** O item ativo na barra de navegação deve ser claramente destacado (cor diferente, negrito no rótulo).

**Alternativa:** Para extrema simplicidade, uma navegação baseada em lista na tela inicial com botões grandes para cada seção também pode ser considerada e testada com usuários.

## 2. Fluxos de Usuário Chave (Exemplos Descritivos)

**a) Adicionar Medicamento e Lembrete:**

1.  **Tela Inicial -> Barra de Navegação:** Tocar em "Remédios".
2.  **Tela de Medicamentos:** Tocar no botão grande "Adicionar Remédio" (com ícone de '+').
3.  **Tela Adicionar Remédio:**
    *   Campo "Nome do Remédio" (fonte grande, opção de foto).
    *   Seleção de "Dosagem" (botões grandes ou lista simples).
    *   Seleção de "Frequência" (opções claras: "Diário", "Semanal", etc., com botões grandes).
    *   Seleção de "Horário(s)" (interface de relógio simplificada ou lista de horários comuns).
    *   Botão "Salvar" grande e claro.
4.  **Confirmação:** Mensagem simples ("Remédio adicionado com sucesso!") com botão "OK".

**b) Marcar Medicamento como Tomado (via Notificação):**

1.  **Notificação:** Receber notificação (som, vibração, visual claro).
2.  **Ações na Notificação:** Botões grandes "Tomei" e "Adiar".
3.  **Tocar em "Tomei":** Notificação desaparece, registro é feito no app. Feedback opcional (som curto de confirmação).
4.  **Tocar em "Adiar":** Opções simples de tempo para adiar (ex: "15 min", "30 min", "1 hora") com botões grandes.

**c) Adicionar Consulta:**

1.  **Tela Inicial -> Barra de Navegação:** Tocar em "Agenda".
2.  **Tela da Agenda:** Tocar no botão grande "Adicionar Consulta/Exame" (com ícone de '+').
3.  **Tela Adicionar Evento:**
    *   Campo "Médico/Exame" (fonte grande).
    *   Seleção de "Data" (calendário simplificado, dias grandes).
    *   Seleção de "Hora" (interface de relógio simplificada).
    *   Campo "Local" (opcional, fonte grande).
    *   Opção "Adicionar Lembrete" (sim/não com botões grandes).
    *   Opção "Anexar Pedido/Receita" (botão para câmera/galeria).
    *   Botão "Salvar" grande e claro.
4.  **Confirmação:** Mensagem simples ("Consulta agendada!").

**d) Registrar Sintoma:**

1.  **Tela Inicial -> Barra de Navegação:** Tocar em "Diário".
2.  **Tela do Diário:** Tocar no botão grande "Registrar Sintoma/Medição".
3.  **Tela de Registro:**
    *   Opção "Registrar Sintoma": Lista de sintomas comuns com ícones e botões grandes. Campo de texto opcional "Observações".
    *   Opção "Registrar Medição": Botões para "Pressão", "Glicemia", etc. Interface numérica grande para inserir valores.
    *   Botão "Salvar" grande e claro.
4.  **Confirmação:** Mensagem simples ("Registro salvo!").

**e) Acionar Emergência:**

1.  **Qualquer Tela Principal:** Tocar no botão fixo "Emergência" (vermelho, grande).
2.  **Tela de Confirmação:** Mensagem grande "ACIONAR EMERGÊNCIA?". Botões grandes "SIM, ACIONAR" e "NÃO, CANCELAR". (Pode exigir segurar o botão "SIM" por 3s).
3.  **Tocar em "SIM, ACIONAR":** Feedback visual (tela pisca/muda cor), sonoro e vibratório. Mensagem "Emergência acionada. Contatos avisados.". Exibe status do envio.
4.  **Opção de Cancelar (pós-acionamento):** Botão "Cancelar Alerta" (se acionado por engano, disponível por alguns segundos).

## 3. Princípios de Design Acessível Aplicados

*   **Tipografia:**
    *   **Fonte:** Sans-serif clara e legível (ex: Roboto, Open Sans, Lato).
    *   **Tamanho Padrão:** Mínimo 16sp (Android) / 17pt (iOS), idealmente maior (18-20sp/pt). Permitir aumento nas configurações do app (até 200%).
    *   **Peso:** Usar pesos diferentes (Regular, Bold) para hierarquia, mas evitar fontes muito finas.
    *   **Espaçamento:** Bom espaçamento entre linhas (1.4x a 1.6x o tamanho da fonte) e entre letras.
*   **Cores e Contraste:**
    *   **Relação de Contraste:** Mínimo 4.5:1 para texto normal e 3:1 para texto grande e elementos gráficos (WCAG AA). Buscar 7:1 (AAA) sempre que possível.
    *   **Paleta:** Cores primárias claras e distintas. Evitar depender apenas da cor para transmitir informação (usar ícones, texto, sublinhado).
    *   **Modo Escuro/Alto Contraste:** Oferecer temas opcionais nas configurações.
*   **Layout e Elementos:**
    *   **Simplicidade:** Interfaces limpas, sem desordem visual. Amplo uso de espaço em branco.
    *   **Tamanho dos Alvos:** Botões e elementos interativos com no mínimo 48x48dp (Android) / 44x44pt (iOS).
    *   **Espaçamento:** Espaço generoso entre elementos clicáveis.
    *   **Estrutura:** Layouts baseados em grade ou lista são preferíveis. Consistência na disposição dos elementos entre as telas.
*   **Interação e Feedback:**
    *   **Feedback Imediato:** Confirmação visual (mudança de cor, animação sutil), sonora (opcional, sons claros) e/ou tátil (vibração) para ações importantes.
    *   **Gestos:** Priorizar toques simples. Evitar gestos complexos (arrastar, pinçar) ou oferecer alternativas.
    *   **Navegação Clara:** Botão "Voltar" sempre visível e funcional. Caminho claro para retornar à tela anterior ou inicial.
*   **Linguagem e Conteúdo:**
    *   **Clareza:** Usar linguagem simples, direta e objetiva. Evitar jargões, siglas ou termos técnicos.
    *   **Instruções:** Fornecer instruções claras e concisas para tarefas complexas.
    *   **Ícones:** Usar ícones universalmente compreendidos e sempre acompanhados de rótulos textuais.

Estes fluxos e princípios devem ser validados através de testes de usabilidade com o público-alvo (idosos e cuidadores) durante o desenvolvimento, conforme planejado na metodologia do projeto.

---
**Referências:**
*   Documento: `Modelo-PropostadeProjetodeExtensão-1.pdf`
*   Pesquisa UI/UX: `/home/ubuntu/pesquisa_ui_ux_idosos.md`
*   Sugestões Arquitetura/Funcionalidades: `/home/ubuntu/arquitetura_funcionalidades_sugeridas.md`

