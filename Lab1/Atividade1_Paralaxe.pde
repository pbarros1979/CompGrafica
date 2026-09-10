/**
 * Computação Gráfica - Universidade Feevale
 * Atividade Prática 1: Câmera Multiplano e Efeito de Paralaxe 2D
 * 
 * Descrição:
 * Este projeto demonstra a simulação de profundidade através do deslocamento
 * diferencial de camadas (paralaxe), empregando primitivas gráficas, estilização
 * e a pilha de transformações matriciais do Processing (pushMatrix / popMatrix).
 *
 * Controles:
 * - Movimento do Mouse: Deslocar o cursor no eixo X altera a velocidade da câmera.
 * - Tecla ESPAÇO: Alterna entre controle interativo por mouse e velocidade constante automática.
 */

// Configurações de fluxo e controle
boolean controlePorMouse = false;
float velocidadeBase = 3.0;

// Variáveis de deslocamento acumulado (offset) de cada camada
float offsetFundo = 0;
float offsetMedio = 0;
float offsetFrente = 0;

// Variável temporal para animação de ciclo de caminhada/oscilação
float tempoAnimacao = 0;

void setup() {
  size(900, 500);
  frameRate(60);
  noCursor(); // Oculta o cursor para melhor imersão visual
}

void draw() {
  // 1. Limpeza de quadro (Buffer Duplo) com a cor atmosférica do céu
  desenharCeu();
  
  // 2. Atualização das taxas de deslocamento
  atualizarVelocidadeEOffsets();
  
  // 3. Camada 1: Plano Distante (Fundo - k_z = 0.15)
  // Montanhas longínquas e nuvens de alta altitude
  pushMatrix();
    translate(-offsetFundo, 0);
    desenharCamadaFundo();
  popMatrix();
  
  // 4. Camada 2: Plano Intermediário (Médio - k_z = 0.45)
  // Colinas médias, vegetação intermediária e árvores estilizadas
  pushMatrix();
    translate(-offsetMedio, 0);
    desenharCamadaMedia();
  popMatrix();
  
  // 5. Camada 3: Primeiro Plano (Frente - k_z = 1.00)
  // Solo frontal imediato, postes, cercas e folhagens
  pushMatrix();
    translate(-offsetFrente, 0);
    desenharCamadaFrente();
  popMatrix();
  
  // 6. Elemento Focal Central: Personagem/Observador animado no plano da ação
  desenharPersonagem(width * 0.25, height - 90);
  
  // 7. Interface Heurística / HUD Informativo
  desenharHUD();
}

// ----------------------------------------------------------------------------
// ATUALIZAÇÃO CINEMÁTICA DAS CAMADAS
// ----------------------------------------------------------------------------
void atualizarVelocidadeEOffsets() {
  float velAtual = velocidadeBase;
  
  if (controlePorMouse) {
    // Mapeia a posição do mouse: centro da tela = 0, esquerda = ré, direita = frente
    velAtual = map(mouseX, 0, width, -6.0, 6.0);
  }
  
  // Fatores de profundidade (k_z): quanto menor k_z, mais distante o plano parece estar
  float kFundo  = 0.15;
  float kMedio  = 0.45;
  float kFrente = 1.00;
  
  offsetFundo  += velAtual * kFundo;
  offsetMedio  += velAtual * kMedio;
  offsetFrente += velAtual * kFrente;
  
  // Algoritmo de wrap-around modular: garante que o offset permaneça cíclico
  // O valor 1800 corresponde ao dobro da largura da tela (largura do padrão replicado)
  float periodoRepeticao = width * 2.0;
  if (offsetFundo > periodoRepeticao)  offsetFundo -= periodoRepeticao;
  if (offsetFundo < 0)                 offsetFundo += periodoRepeticao;
  
  if (offsetMedio > periodoRepeticao)  offsetMedio -= periodoRepeticao;
  if (offsetMedio < 0)                 offsetMedio += periodoRepeticao;
  
  if (offsetFrente > periodoRepeticao) offsetFrente -= periodoRepeticao;
  if (offsetFrente < 0)                offsetFrente += periodoRepeticao;
  
  // Incremento do tempo de animação proporcional à velocidade do deslocamento
  tempoAnimacao += abs(velAtual) * 0.05;
}

// ----------------------------------------------------------------------------
// CAMADA 0: CÉU E SOL
// ----------------------------------------------------------------------------
void desenharCeu() {
  background(28, 38, 62); // Azul escuro crepuscular
  
  // Gradiente vertical do horizonte (linhas interpoladas)
  for (int y = 0; y < height - 120; y += 4) {
    float inter = map(y, 0, height - 120, 0, 1);
    stroke(lerpColor(color(28, 38, 62), color(88, 72, 105), inter));
    strokeWeight(4);
    line(0, y, width, y);
  }
  
  // Sol/Lua estático na linha de visada do infinito
  noStroke();
  fill(255, 235, 180, 220);
  ellipse(width * 0.75, 120, 70, 70);
  fill(255, 235, 180, 40);
  ellipse(width * 0.75, 120, 110, 110); // Halo luminoso
}

// ----------------------------------------------------------------------------
// CAMADA 1: FUNDO (MONTANHAS POLIGONAIS DISTANTES)
// ----------------------------------------------------------------------------
void desenharCamadaFundo() {
  // Desenhamos três blocos contíguos para cobrir tela e transições contínuas
  for (int bloco = -1; bloco <= 2; bloco++) {
    float baseX = bloco * width;
    
    // Cadeia montanhosa distante com vértices customizados (beginShape)
    fill(55, 52, 85);
    noStroke();
    beginShape();
    vertex(baseX + 0,   height);
    vertex(baseX + 0,   height - 180);
    vertex(baseX + 160, height - 290); // Cume 1
    vertex(baseX + 320, height - 200);
    vertex(baseX + 480, height - 320); // Cume 2 (mais alto)
    vertex(baseX + 640, height - 210);
    vertex(baseX + 800, height - 270); // Cume 3
    vertex(baseX + 900, height - 190);
    vertex(baseX + 900, height);
    endShape(CLOSE);
    
    // Pico nevado com triângulos nos cumes
    fill(190, 195, 215, 180);
    triangle(baseX + 480, height - 320, baseX + 440, height - 260, baseX + 520, height - 260);
    triangle(baseX + 160, height - 290, baseX + 130, height - 240, baseX + 190, height - 240);
  }
}

// ----------------------------------------------------------------------------
// CAMADA 2: MÉDIO (COLINAS VERDES E PINHEIROS)
// ----------------------------------------------------------------------------
void desenharCamadaMedia() {
  for (int bloco = -1; bloco <= 2; bloco++) {
    float baseX = bloco * width;
    
    // Colinas intermediárias suaves
    fill(42, 75, 78);
    noStroke();
    beginShape();
    vertex(baseX + 0,   height);
    vertex(baseX + 0,   height - 150);
    bezierVertex(baseX + 250, height - 210, baseX + 450, height - 120, baseX + 650, height - 170);
    bezierVertex(baseX + 780, height - 200, baseX + 850, height - 140, baseX + 900, height - 150);
    vertex(baseX + 900, height);
    endShape(CLOSE);
    
    // Floresta de pinheiros intermediários estilizados
    for (int i = 50; i < 900; i += 110) {
      desenharPinheiro(baseX + i, height - 145, 0.7);
    }
  }
}

void desenharPinheiro(float px, float py, float esc) {
  pushMatrix();
    translate(px, py);
    scale(esc);
    
    // Tronco
    fill(35, 25, 20);
    rect(-5, 0, 10, 25);
    
    // Três camadas da copa em triângulos sobrepostos
    fill(24, 58, 55);
    triangle(0, -55, -25, -20, 25, -20);
    triangle(0, -40, -30, -5,  30, -5);
    triangle(0, -25, -35, 10,  35, 10);
  popMatrix();
}

// ----------------------------------------------------------------------------
// CAMADA 3: FRENTE (SOLO IMEDIATO, CERCAS E POSTES)
// ----------------------------------------------------------------------------
void desenharCamadaFrente() {
  for (int bloco = -1; bloco <= 2; bloco++) {
    float baseX = bloco * width;
    
    // Solo frontal imediato
    fill(22, 38, 30);
    rect(baseX, height - 70, width + 1, 70);
    
    // Faixa de grama superior
    fill(40, 70, 45);
    rect(baseX, height - 75, width + 1, 8);
    
    // Cercas em primeiro plano
    stroke(15, 25, 18);
    strokeWeight(3);
    // Trave horizontal da cerca
    line(baseX, height - 52, baseX + width, height - 52);
    line(baseX, height - 38, baseX + width, height - 38);
    
    // Mourões verticais
    for (int x = 10; x < width; x += 75) {
      line(baseX + x, height - 60, baseX + x, height - 25);
      // Detalhe de ponta afiada do mourão
      line(baseX + x - 3, height - 57, baseX + x, height - 63);
      line(baseX + x, height - 63, baseX + x + 3, height - 57);
    }
  }
}

// ----------------------------------------------------------------------------
// ELEMENTO FOCAL: PERSONAGEM PARAMÉTRICO ANIMADO
// ----------------------------------------------------------------------------
void desenharPersonagem(float cx, float cy) {
  pushMatrix();
    translate(cx, cy);
    
    // Efeito de bobbing (oscilação vertical suave ao andar)
    float saltoVertical = abs(sin(tempoAnimacao * 2.0)) * 6.0;
    translate(0, -saltoVertical);
    
    // Pernas / Membros inferiores oscilando em oposição de fase
    float angPerna1 = sin(tempoAnimacao) * radians(30);
    float angPerna2 = sin(tempoAnimacao + PI) * radians(30);
    
    stroke(20);
    strokeWeight(4);
    
    // Perna 1 (Fundo)
    pushMatrix();
      translate(-5, 15);
      rotate(angPerna1);
      line(0, 0, 0, 20);
    popMatrix();
    
    // Perna 2 (Frente)
    pushMatrix();
      translate(5, 15);
      rotate(angPerna2);
      line(0, 0, 0, 20);
    popMatrix();
    
    // Tronco / Corpo
    noStroke();
    fill(220, 90, 60);
    rectMode(CENTER);
    rect(0, 0, 24, 30, 4);
    
    // Cabeça
    fill(240, 210, 180);
    ellipse(0, -24, 22, 22);
    
    // Olho estilizado (direção da caminhada para a direita)
    fill(20);
    ellipse(4, -25, 4, 4);
    
    // Mochila / Acessório
    fill(90, 60, 45);
    rect(-12, -2, 8, 18, 2);
    
    rectMode(CORNER); // Restaura o modo padrão de ancoragem
  popMatrix();
}

// ----------------------------------------------------------------------------
// INTERFACE DE USUÁRIO / HUD
// ----------------------------------------------------------------------------
void desenharHUD() {
  fill(0, 160);
  noStroke();
  rect(15, 15, 340, 75, 8);
  
  fill(255);
  textSize(12);
  text("PRÁTICA 1: CÂMERA MULTIPLANO & PARALAXE 2D", 25, 33);
  fill(180, 230, 255);
  text("Modo: " + (controlePorMouse ? "Mouse Interativo (X)" : "Velocidade Contínua Fixa"), 25, 52);
  fill(200);
  text("Pressione [ESPAÇO] para alternar modo de controle", 25, 72);
}

void keyPressed() {
  if (key == ' ') {
    controlePorMouse = !controlePorMouse;
  }
}
