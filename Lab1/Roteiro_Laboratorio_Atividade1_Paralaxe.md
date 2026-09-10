# Universidade Feevale — Instituto de Ciências Criativas e Tecnológicas
**Curso:** Bacharelado em Ciência da Computação  
**Disciplina:** Computação Gráfica  
**Docente Responsável:** Prof. Paulo Ricardo Muniz Barros
**Atividade Prática Laboratorial:** Roteiro Guiado — Câmera Multiplano e Efeito de Paralaxe 2D em Processing  

---

## 1. Contextualização Histórica e Teórica

Na era de ouro da animação tradicional, os estúdios Walt Disney enfrentavam uma limitação física severa: ao sobrepor desenhos transparentes de acetato sobre uma pintura de fundo estática, a cena parecia artificialmente "achatada". Movimentar a câmera em direção ao cenário ou lateralmente fazia com que todos os elementos mudassem na mesma proporção geométrica, rompendo a percepção humana de profundidade.

Para solucionar essa limitação, William Garity e a equipe da Disney projetaram em 1937 a **Câmera Multiplano** (*Multiplane Camera*). A máquina consistia em uma estrutura vertical de até sete metros de altura com diversos níveis de placas de vidro horizontais iluminadas independentemente. Ao filmar de cima para baixo, a câmera conseguia mover-se através dos níveis, e cada lâmina de vidro podia ser transladada lateralmente em velocidades distintas.

Em **Computação Gráfica 2D**, reproduzimos esse princípio através do **Efeito de Paralaxe (*Parallax Scrolling*)**. A profundidade virtual não é gerada por um eixo $Z$ real renderizado via projeção perspectiva, mas sim pela **defasagem cinemática diferencial** das camadas no espaço de tela (*Screen Space*):

$$\Delta x_i = v_{\text{câmera}} \cdot k_{z, i} \cdot \Delta t$$

Onde:
- $v_{\text{câmera}}$ é a velocidade linear da câmera virtual (ou o vetor de deslocamento do observador);
- $k_{z, i} \in (0.0, 1.0]$ é o coeficiente de proximidade da camada $i$. Quanto mais próximo do zero, mais distante o plano parece estar do olho do observador;
- $\Delta t$ é a variação temporal entre quadros sucessivos.

Neste laboratório, implementaremos esse sistema puramente via código no **Processing**, dominando o ciclo de vida gráfico (`setup`/`draw`), primitivas bidimensionais e a gestão da pilha de matrizes afins (`pushMatrix` e `popMatrix`).

---

## 2. Objetivos de Aprendizagem e Matriz

Ao término deste laboratório, o estudante deverá demonstrar:

- **Conhecimentos (Saber):**
  - Compreensão da arquitetura de estados gráficos e do modelo de buffer duplo (*double-buffering*) do Processing.
  - Distinção clara entre o sistema cartesiano euclidiano convencional e o sistema de coordenadas de tela (origem no canto superior esquerdo e eixo $Y$ positivo orientado para baixo).
  - Fundamentos teóricos da álgebra de transformações matriciais 2D aplicadas à câmera virtual.

- **Habilidades (Saber Fazer):**
  - Sintetizar primitivas geométricas complexas utilizando laços procedurais e polígonos livres (`beginShape`, `vertex`, `bezierVertex`).
  - Isolar estados de transformação gráfica através do empilhamento (`pushMatrix`) e desempilhamento (`popMatrix`).
  - Projetar um algoritmo de reconstrução contínua de borda (*wrap-around* modular), eliminando lacunas de renderização na translação contínua.
  - Sincronizar parâmetros de animação procedural por oscilações harmônicas trigonométricas ($\sin(\omega t)$).

- **Atitudes (Saber Agir):**
  - Rigor analítico na parametrização matemática sem recorrer a ajustes empíricos desconexos ("números mágicos").
  - Sensibilidade estética na escolha da paleta cromática, espessura de traço e composição visual da cena.

---

## 3. Diretrizes Gerais e Ambiente de Execução

- **Ambiente:** Processing IDE (versões 3.x ou 4.x), configurado no modo **Java**.
- **Resolução da Janela:** `900 x 500` pixels (taxa fixa de 60 quadros por segundo).
- **Tempo Estimado:** 3 a 4 horas.


---

## 4. Roteiro Prático Guiado (Passo a Passo)

O desenvolvimento deve seguir rigorosamente a abordagem em espiral: cada etapa deve ser testada e validada visualmente antes do avanço para a etapa seguinte.

```
[Etapa 1: Canvas e Céu] ➔ [Etapa 2: Camada Distante] ➔ [Etapa 3: Camada Média]
           ➔ [Etapa 4: Camada Frontal] ➔ [Etapa 5: Pilha Matricial e Paralaxe]
           ➔ [Etapa 6: Personagem Animado] ➔ [Etapa 7: Interatividade HUD]
```

---

### Etapa 1: Espaço de Tela, Ciclo de Vida e Atmosfera de Céu

1. **Estrutura básica:** Crie as funções canônicas `setup()` e `draw()`. No `setup()`, defina a resolução para `size(900, 500)` e garanta a cadência de 60 fps com `frameRate(60)`.
2. **Buffer Duplo e Limpeza:** No `draw()`, a primeira instrução deve ser a renderização do fundo. Se esquecermos de limpar o quadro, as posições dos quadros anteriores persistirão, gerando borrões.
3. **Gradiente Atmosférico:** Em vez de uma cor lisa, simule a densidade do ar ao entardecer interpolando duas cores no eixo vertical via laço `for` e a função nativa `lerpColor()`:

```java
void desenharCeu() {
  background(28, 38, 62); // Azul noturno profundo
  
  for (int y = 0; y < height - 120; y += 4) {
    float inter = map(y, 0, height - 120, 0.0, 1.0);
    // Interpolação linear de cor entre o azul profundo e um púrpura crepuscular
    color c = lerpColor(color(28, 38, 62), color(88, 72, 105), inter);
    stroke(c);
    strokeWeight(4);
    line(0, y, width, y);
  }
  
  // Corpo celeste no infinito (sol/lua)
  noStroke();
  fill(255, 235, 180, 220);
  ellipse(width * 0.75, 120, 70, 70);
  fill(255, 235, 180, 40);
  ellipse(width * 0.75, 120, 110, 110); // Halo difuso
}
```

> **Checklist da Etapa 1:** Execute o sketch. A janela deve exibir um gradiente suave terminando acima da linha do solo, com um astro iluminado e sem linhas piscantes (*flickering*).

---

### Etapa 2: A Camada de Fundo (Montanhas Poligonais)

A camada mais distante representa formações geológicas a quilômetros de distância. Devido à dispersão atmosférica, suas cores devem ser menos saturadas e com tons azulados/acinzentados.

1. **Uso de Malhas Fechadas:** Construa a silhueta das montanhas utilizando `beginShape()` e `vertex(x, y)`.
2. **Problema do Telhado Infinito:** Uma única tela de montanhas não basta. Para que a paisagem se desloque sem deixar espaços vazios, desenhamos blocos repetidos em um laço de `bloco = -1` até `bloco = 2`, cobrindo de $-900$ até $+1800$ pixels:

```java
void desenharCamadaFundo() {
  for (int bloco = -1; bloco <= 2; bloco++) {
    float baseX = bloco * width;
    
    fill(55, 52, 85);
    noStroke();
    beginShape();
    vertex(baseX + 0,   height);
    vertex(baseX + 0,   height - 180);
    vertex(baseX + 160, height - 290); // Cume 1
    vertex(baseX + 320, height - 200);
    vertex(baseX + 480, height - 320); // Cume mais alto
    vertex(baseX + 640, height - 210);
    vertex(baseX + 800, height - 270); // Cume 3
    vertex(baseX + 900, height - 190);
    vertex(baseX + 900, height);
    endShape(CLOSE);
    
    // Adicione os picos nevados nos cumes
    fill(190, 195, 215, 180);
    triangle(baseX + 480, height - 320, baseX + 440, height - 260, baseX + 520, height - 260);
  }
}
```

> **Checklist da Etapa 2:** As montanhas devem aparecer sólidas, com bases que coincidem com a parte inferior da tela e picos pontiagudos realçados por triângulos brancos.

---

### Etapa 3: A Camada Intermediária (Colinas e Pinheiros Paramétricos)

Nesta etapa, o estudante aplicará curvas e funções modulares com escala.

1. **Curvas Bézier:** Modele colinas arredondadas com a instrução `bezierVertex(cx1, cy1, cx2, cy2, x, y)`.
2. **Modularização Paramétrica:** Crie uma função auxiliar para gerar árvores de maneira flexível. A função deve receber a posição $(px, py)$ e um fator de escala $esc$, isolando sua própria matriz com `pushMatrix` e `popMatrix`:

```java
void desenharPinheiro(float px, float py, float esc) {
  pushMatrix();
    translate(px, py);
    scale(esc);
    
    // Tronco
    fill(35, 25, 20);
    rect(-5, 0, 10, 25);
    
    // Três níveis de copas triangulares sobrepostas
    fill(24, 58, 55);
    triangle(0, -55, -25, -20,  25, -20);
    triangle(0, -40, -30, -5,   30, -5);
    triangle(0, -25, -35,  10,  35, 10);
  popMatrix();
}
```

3. Na função `desenharCamadaMedia()`, utilize um laço `for (int i = 50; i < 900; i += 110)` para distribuir os pinheiros sobre as colinas.

> **Checklist da Etapa 3:** Ao rodar, as colinas verdes devem se sobrepor suavemente à base das montanhas distantes, com árvores distribuídas ritmicamente.

---

### Etapa 4: O Primeiro Plano (Solo, Cercas e Detalhes Imediatos)

Esta camada passa muito perto do observador e deve ser a mais rápida e nítida.

1. Crie o solo frontal com `rect(baseX, height - 70, width + 1, 70)`.
2. Adicione detalhes de textura linear: desenhe mourões verticais e fios de arame horizontal com `strokeWeight(3)` e `line()`.

---

### Etapa 5: Gestão Matricial, Cinemática e Wrap-Around Infinito

Este é o **coração conceitual da atividade**. Os estudantes devem entender que **os objetos não se movem individualmente; é a grade do sistema que é transladada**.

1. **Variáveis de Estado Globais:**
   ```java
   float offsetFundo = 0;
   float offsetMedio = 0;
   float offsetFrente = 0;
   float velocidadeBase = 3.0;
   ```
2. **Taxa de Deslocamento e Coeficientes de Profundidade:**
   No método de atualização, aplique os coeficientes $k_z$:
   ```java
   offsetFundo  += velAtual * 0.15; // Distante: move-se apenas 15% da velocidade base
   offsetMedio  += velAtual * 0.45; // Médio: move-se a 45%
   offsetFrente += velAtual * 1.00; // Frente: move-se a 100%
   ```
3. **Equação do Wrap-Around:**
   Como a largura desenhada nos blocos equivale a $2 \times \text{width} = 1800$, aplicamos a recomposição cíclica:
   ```java
   float periodo = width * 2.0;
   if (offsetFundo > periodo) offsetFundo -= periodo;
   if (offsetFundo < 0)        offsetFundo += periodo;
   // (Repetir a lógica para as outras camadas)
   ```
4. **Isolamento na Renderização (`draw`):**
   ```java
   pushMatrix();
     translate(-offsetFundo, 0);
     desenharCamadaFundo();
   popMatrix();

   pushMatrix();
     translate(-offsetMedio, 0);
     desenharCamadaMedia();
   popMatrix();

   pushMatrix();
     translate(-offsetFrente, 0);
     desenharCamadaFrente();
   popMatrix();
   ```

> **Atenção — Erro Comum de Laboratório:** O que acontece se removermos os comandos `popMatrix()`? As translações se somarão recursivamente! A camada média sofrerá a sua translação somada à translação da camada de fundo, quebrando completamente as relações matemáticas de velocidade.

---

### Etapa 6: O Elemento Focal — Personagem Paramétrico Animado

Para que o observador tenha uma âncora visual, introduzimos um personagem que caminha no primeiro plano, cuja animação responde ao tempo:

1. **Oscilação Vertical (Bobbing):** Ao caminhar, o corpo humano oscila suavemente para cima e para baixo. Usamos o valor absoluto de uma onda senoidal:
   ```java
   float saltoVertical = abs(sin(tempoAnimacao * 2.0)) * 6.0;
   ```
2. **Pernas Articuladas com Defasagem de Fase:** As duas pernas devem oscilar em oposição de fase ($\pi$ radianos):
   ```java
   float angPerna1 = sin(tempoAnimacao) * radians(30);
   float angPerna2 = sin(tempoAnimacao + PI) * radians(30);
   ```
3. O personagem deve ser desenhado utilizando `rectMode(CENTER)`, facilitando a rotação dos membros inferiores a partir dos quadris.

---

### Etapa 7: Interatividade e Painel Informativo (HUD)

1. Permita ao usuário controlar a velocidade com o cursor do mouse (`mouseX` mapeado entre $-6.0$ e $+6.0$).
2. Implemente na tecla `ESPAÇO` a alternância entre a velocidade contínua automática e o controle por mouse.
3. Renderize no canto superior esquerdo uma pequena caixa semitransparente (`fill(0, 160)`) indicando o estado atual do sketch.

---

## 5. Código de Referência Integral

O código funcional completo com todas as etapas integradas está disponível para consulta e validação no arquivo [Atividade1_Paralaxe.pde](file:///Atividade1_Paralaxe.pde).

---
