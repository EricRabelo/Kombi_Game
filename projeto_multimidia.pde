import processing.sound.*;
import java.util.Random;

//controle da Kombi
PImage placa;
float PosX = PI;
float PosY = -PI/8;
float zoom=700;
float velocidade=PI/(20*width);
int  chaveLimparParabrisa = 1, chaveRetrairRetrovisores = 0, chaveAcenderFarois = 1, chavePiscaEsquerdo = 0, chavePiscaDireito = 0, chavePiscaAlerta = 0;
int rotacaoLimpadores = 0, limpadoresDescendo = 0, tempoLimpadores = 0, rotacaoRetrovisores = 0, retrovisoresRetraidos = 0;
class coord
{
  float x, y, z;
  coord(float a, float b, float c)
  {
    x = a;
    y = b;
    z = c;
  }
}
//fim

//controle do desenho da pista
int nFaixas = 6, larguraFaixa = 800, comprimentoFaixa = 5000, iFaixa = 0;
//fim

//controle de som
SoundFile motorPartida;
SoundFile motor;
SoundFile bateu;
SoundFile musica;
int chaveAudio = 0, chaveAudio2 = 0, chaveMusica = 1;
//fim

//controle obstaculos e pontuação
PShape cone;
ArrayList<IntList> obstaculosFaixa;
Random rand;
int aux, controle = 2, score = 0, recorde = 0;
//fim

void setup(){
  //configurando variaveis de ambiente e utilitários
  size(1024,768,P3D);
  rand = new Random();
  
  //importando arquivos
  placa = loadImage("Placa.jpg");
  motorPartida = new SoundFile(this, "partida.mp3");
  motor = new SoundFile(this, "motor.mp3");
  bateu = new SoundFile(this, "bateu.mp3");
  musica = new SoundFile(this, "musicas.mp3");
  cone = loadShape("conecolorido.obj");
  
  //configurando audio
  musica.amp(0.2);
  bateu.amp(1);
  motor.amp(1);
  motorPartida.amp(1);
  musica.loop();
  
  //preparando vetor obstaculos
  obstaculosFaixa = new ArrayList<IntList>(nFaixas);
  for(int i = 0; i < nFaixas; i++)
    obstaculosFaixa.add(new IntList());
  
  //configurando obstaculos
  cone.setFill(color(200, 50, 50));
  cone.scale(5);
  cone.rotateX(PI);
}

void keyPressed(){
  //controles da kombi
  if(key == 'L' || key == 'l')//ativa / desativa o movimento dos limpadores de parabrisas
    chaveLimparParabrisa = (chaveLimparParabrisa == 0) ? 1 : 0;
  if(key == 'R' || key == 'r')//recolhe / extende os retrovisores
    chaveRetrairRetrovisores = (chaveRetrairRetrovisores == 0)? 1 : 0;
  if(key == 'F' || key == 'f')//recolhe / extende os retrovisores
    chaveAcenderFarois = (chaveAcenderFarois == 0)? 1 : 0;
  if(key == '6')//ativa o pisca esquerdo
  {//ta bugado o esquerdo é o direito na vdd
    chavePiscaEsquerdo = (chavePiscaEsquerdo == 0)? 1 : 0;
    chavePiscaDireito = 0;//desativa o direito
  }
  if(key == '4')//ativa o pisca direito
  {
    chavePiscaDireito = (chavePiscaDireito == 0)? 1 : 0;
    chavePiscaEsquerdo = 0;//desativa o esquerdo
  }
  if(key == 'A' || key == 'a')//ativa o pisca-alerta
  {
    chavePiscaAlerta = (chavePiscaAlerta == 0)? 1 : 0;
    chavePiscaEsquerdo = chavePiscaDireito = 0;
  }
  //fim 
  
  //controle de audio
  if(key == 'M' || key == 'm')//ativa/desativa musica
  {
    chaveMusica = (chaveMusica == 0) ? 1 : 0;
    if(chaveMusica == 1)
      musica.loop();
    else
      musica.stop();
  }
  //fim
  
  //controles de jogabilidade
  if(key == 'z' || key == 'Z')//reseta os pontos e os obstaculos
  {
    chavePiscaAlerta = 0;
    chaveAudio2 = 0;
    score = 0;
    chaveAudio = 1;
    if(motor.isPlaying())
      motor.stop();
    for(int i = 0; i < nFaixas; i++)
      while(obstaculosFaixa.get(i).size() > 0)
        obstaculosFaixa.get(i).remove(0);
  }
  
  if(keyCode == LEFT && controle == 0)
    iFaixa = (iFaixa > 0)? iFaixa-1 : iFaixa;
  if(keyCode == RIGHT && controle == 0)
    iFaixa = (iFaixa+1 < nFaixas)? iFaixa+1 : iFaixa;
  //fim
}
void mouseWheel(MouseEvent event){
  //controle de visualização
  zoom+=event.getCount()*50;
}
void draw(){
  //processando a camera e o framerate
  controleCamera();
  
  //controle das flags de estado de jogo
  controleEstado();
  
  //desenha a kombi
  desenharKombi();

  //desenha as n faixas
  desenharFaixas();
  
  //controle de output para o  usuário
  controleMensagens();
}

void desenharObstaculos(int faixa)
{
  for(int i = 0; i < obstaculosFaixa.get(faixa).size(); i++)
  {
    translate(0, 0, obstaculosFaixa.get(faixa).get(i));
    shape(cone);
    translate(0, 0, -1*obstaculosFaixa.get(faixa).get(i));
  }
}

void atualizarObstaculos()
{
  if(frameCount % 5 == 0)//criando novos obstaculos
  {
    aux = rand.nextInt(nFaixas);
    if(obstaculosFaixa.get(aux).size() == 0)//ta vazia?
      obstaculosFaixa.get(aux).append(comprimentoFaixa);
    else if(obstaculosFaixa.get(aux).get(obstaculosFaixa.get(aux).size()-1) < comprimentoFaixa * 0.5)//o elemento que existe esta antes da metade do caminho?
      obstaculosFaixa.get(aux).append(comprimentoFaixa);
  }
  
  for(int i = 0; i < nFaixas; i++)//atualizando os obstaculos atuais
  {
    if(obstaculosFaixa.get(i).size() > 0)
    {
      for(int j = 0; j < obstaculosFaixa.get(i).size(); j++)
        if(obstaculosFaixa.get(i).get(j) < -1*comprimentoFaixa)//ja atingiu o fim?
          obstaculosFaixa.get(i).remove(j);
        else
          obstaculosFaixa.get(i).sub(j, 150);//150 é o comprimento do seguimento branco!
    }
  }
}

void verificaObstaculos()
{
   int min = -3200, max = -1990;
   for(int i = 0; i < obstaculosFaixa.get(iFaixa).size(); i++){
     if(obstaculosFaixa.get(iFaixa).get(i) > min)
     {
       if(obstaculosFaixa.get(iFaixa).get(i) < max)
       {
         if(score > recorde) recorde=score+1;
         chavePiscaAlerta = 1;
         motor.stop();
         bateu.play();
         controle = 1;
       }
       break;
     }
   }
}

void controleCamera()
{
  frameRate(30);
  ambientLight(140, 140, 140);
  pointLight(255, 255, 255, 0, 0, 500);
  background(135);
  translate(512,150,-zoom);
  if (mousePressed){
     PosX += (pmouseX-mouseX)*velocidade;
     PosY += (pmouseY-mouseY)*velocidade;
     rotateX(PosY);
     rotateY(-PosX);
  }else{
    rotateX(PosY);
    rotateY(-PosX);
  }
}

void controleEstado()
{
  if (chaveAudio == 1)
  {
    motorPartida.play();
    chaveAudio = 0;
    chaveAudio2 = 1;
  }
  else if(!motorPartida.isPlaying() && chaveAudio2 == 1)
  {
    controle = 0;
    motorPartida.stop();//redundancia proposital
    motor.loop();
    chaveAudio2 = 0;
  }
}

void desenharKombi()
{
  criarLataria();
  criarRetrovisores();
  criarRodas();
  criarFarois();
  criarDetalhesFrente();
  criarLimpadorParabrisa();
  criarDetalhesCosta();
}

void pintarFaixaTracejada(int larguraSegBranco, int comprimentoSegBranco)
{
  int divisao = 2*comprimentoFaixa / comprimentoSegBranco;//10 000/150
  translate(0, 0, -1*comprimentoFaixa);

  for(int i = 0; i < divisao; i++)
  {
    if(controle != 0){
      if(i % 2 == 0)
        box(0.5*larguraSegBranco, 1.1, comprimentoSegBranco);     //faixa branca
    }
    else if(frameCount % 2 == 0 && i % 2 == 0)
      box(0.5*larguraSegBranco, 1.1, comprimentoSegBranco);     //faixa branca
    else if(frameCount % 2 == 1 && i % 2 == 1)
      box(0.5*larguraSegBranco, 1.1, comprimentoSegBranco);     //faixa branca
    translate(0, 0, comprimentoSegBranco);
  }
  translate(0, 0, -1*divisao*comprimentoSegBranco + comprimentoFaixa);
}

void desenharFaixas()
{
  int comprimentoSegBranco = 150, larguraSegBranco = 30;
  fill(112,112,106);//cor asfalto
  noStroke();//comprimentoFaixa - (720*0.5)
  translate(0, 500 + 72,  0.5*comprimentoFaixa);//chegando na altura das pistas
  for(int i = 0; i < nFaixas; i++)//a direita é negativo X, a frente é negativo Z
  {
    translate((i-iFaixa)*larguraFaixa*-1, 0, 0);//vai pra faixa
    box(larguraFaixa, 1, 2*comprimentoFaixa);//desenha a faixa
    
    //desenha as linhas
    fill(255, 255, 255);//pinta de branco
    if(i == 0)//desenhando a linha branca contínua dos cantos
    {
      translate(0.5*larguraFaixa - 0.5*larguraSegBranco, 0, 0);//indo pro canto esquerdo da faixa
      box(larguraSegBranco, 1.1, 2*comprimentoFaixa);//linha
      translate(-1*0.5*larguraFaixa + 0.5*larguraSegBranco, 0, 0);//voltando do canto esquerdo da faixa
    }
    else
    {
      translate(0.5*larguraFaixa - 0.25*larguraSegBranco, 0, 0);//indo pro canto esquerdo da faixa
      pintarFaixaTracejada(larguraSegBranco, comprimentoSegBranco);
      translate(-1*0.5*larguraFaixa + 0.25*larguraSegBranco, 0, 0);//voltando do canto esquerdo da faixa
    }
    if(i == nFaixas-1)//desenhando a linha branca contínua dos cantos
    {
      translate(-1*0.5*larguraFaixa + 0.5*larguraSegBranco, 0, 0);//indo pro canto direito da faixa
      box(larguraSegBranco, 1.1, 2*comprimentoFaixa);     //linha branca
      translate(0.5*larguraFaixa - 0.5*larguraSegBranco, 0, 0);//voltando do canto direito da faixa
    }
    else
    {
      translate(-1*0.5*larguraFaixa + 0.25*larguraSegBranco, 0, 0);//indo pro canto direito da faixa
      pintarFaixaTracejada(larguraSegBranco, comprimentoSegBranco);
      translate(0.5*larguraFaixa - 0.25*larguraSegBranco, 0, 0);//voltando do canto direito da faixa
    }
    desenharObstaculos(i);
    fill(112,112,106);//retornando a cor alfalto
    //fim faixa tracejada
    translate((i-iFaixa)*larguraFaixa, 0, 0);//volta
  }
  
  translate(0, -500 - 72, -1*0.5*comprimentoFaixa);//voltando pro centro absoluto
  fill(40,40,40);//voltando pra cor pneu
  stroke(40,40,40);
}

void controleMensagens()
{
  fill(0,0,0);
  textSize(30);
  rotateY(PosX);
  rotateX(-PosY);
  text("Recorde = " + recorde, 450, -190, 500);
  text("Score = " + score, 450, -230, 500);
  if(controle==0){
    atualizarObstaculos();
    verificaObstaculos();
    score = score +1;
  }
  else if(controle == 1)
  {
    textSize(128);
    text("Game Over", -300, -30,500);
    textSize(30);
    text("Pressione z para jogar novamente", -220, 40, 500);
  }
  else
  {
    textSize(128);
    text("Bem vindo", -300, -30,500);
    textSize(30);
    text("Pressione z para iniciar\nComandos:\n<M> ativa ou desativa a musica\n<4> ou <6> ativa as setas\n<A> ativa o pisca-alerta\n<L> ativa o limpador de parabrisa\n<R> recolhe ou extende os retrovisores\n<F> ativa ou desativa os faróis", -220, 40, 500);
  }
}

void criarLimpadorParabrisa()
{
  //girar limpadores
  if(chaveLimparParabrisa == 1 && tempoLimpadores == 0)
  {
    if(limpadoresDescendo == 0)//parabrisa descendo
     rotacaoLimpadores++;
    else//parabrisa subindo
      rotacaoLimpadores--;
    if(rotacaoLimpadores == 15 || rotacaoLimpadores == 0)
      limpadoresDescendo = (limpadoresDescendo == 0)? 1 : 0;//troca a direção do movimento
    if(rotacaoLimpadores == 0)
      tempoLimpadores = 10;//timer
  }
  else if(chaveLimparParabrisa == 1)
    tempoLimpadores--;
  else 
    tempoLimpadores = 0;
  
  //Limpador Direito
  fill(40,40,40);
  translate(85, 205, 351);
 
  //girando limpador direito
  rotateZ(-1*rotacaoLimpadores*0.145);
  
  sphere(4);//base do limpador de parabrisa direito
  translate(0,0,2);
  float Xfinal, Yfinal, Zfinal;
  Xfinal = 60;
  Yfinal = -30;
  Zfinal = -(0.125*75);
  strokeWeight(2);
  stroke(0);
  line(0, 0, 0, Xfinal, Yfinal, Zfinal);
  strokeWeight(1);
  translate(Xfinal, Yfinal, Zfinal);
  box(60,4,2);
  translate(-Xfinal, -Yfinal, -Zfinal);
  
  //desfazendo rotação usada pro limpador
  rotateZ(rotacaoLimpadores*0.145);
  
  //Limpador Esquerdo
  translate(-170, 0, -2);
  
  //girando limpador esquerdo
  rotateZ(-1*rotacaoLimpadores*0.145);
  
  sphere(4);//base do limpador de parabrisa direito
  translate(0,0,2);
  Xfinal = 60;
  Yfinal = -30;
  Zfinal = -(0.125*75);
  strokeWeight(2);
  stroke(0);
  line(0, 0, 0, Xfinal, Yfinal, Zfinal);
  strokeWeight(1);
  translate(Xfinal, Yfinal, Zfinal);
  box(60,4,2);
  translate(-Xfinal, -Yfinal, -Zfinal);
  
  //desfazendo rotação usada pro limpador
  rotateZ(rotacaoLimpadores*0.145);
  
  //Limpador traseiro
  translate(85, 0, -704);
  
  //girando limpador traseiro
  rotateZ(-1*rotacaoLimpadores*0.145);
  
  sphere(4);//base do limpador de parabrisa traseiro
  translate(0,0,-2);
  Xfinal = 60;
  Yfinal = -30;
  Zfinal = (0.125*75);
  strokeWeight(2);
  stroke(0);
  line(0, 0, 0, Xfinal, Yfinal, Zfinal);
  strokeWeight(1);
  translate(Xfinal, Yfinal, Zfinal);
  box(60,4,2);
  translate(-Xfinal, -Yfinal, -Zfinal);
  
  //desfazendo rotação usada pro limpador
  rotateZ(rotacaoLimpadores*0.145);
  
  translate(0, -205, 353);
  noStroke();
}

void criarDetalhesFrente()
{
  noStroke();
  //Adicionando radiador da frente da kombi
  translate(0,410,352);
  fill(40,40,40);
  box(170,150,4);
  translate(0,-410,-352); //voltando ao ponto (500, 500, 0)

  //Adicionando retangulo de cima da kombi
  translate(0,300,352);
  fill(40,40,40);
  box(320,40,4);
  
  //definindo Cor do pisca alerta direito
  if((chavePiscaDireito == 0 && chavePiscaAlerta == 0) || frameCount % 3 == 0)
    fill(#FF7200,100); //Cor Laranja com fator de transparência
  else
    fill(#FF7200); //Cor Laranja sem fator de transparência
  
  //Adicionando pisca alerta Direito
  translate(130,0,4);
  box(50,30,2);
  
  //definindo Cor do pisca alerta esquerdo
  if((chavePiscaEsquerdo == 0 && chavePiscaAlerta == 0) || frameCount % 3 == 0)
    fill(#FF7200,100); //Cor Laranja com fator de transparência
  else
    fill(#FF7200); //Cor Laranja sem fator de transparência
  
  //Adicionando pisca alerta Esquerdo
  translate(-260,0,0);
  box(50,30,2);
  //voltando ao ponto (500, 500, 0)
  translate(130,-300,-356);
}

void criarDetalhesCosta()
{
  fill(40, 40, 40);
  translate(-150, 400, -350);
  box(30, 90, 2);
  fill(100, 10, 10);
  box(28, 28, 4);//vermelho central esq
  translate(0, -30, 0);
  //definindo Cor do pisca alerta esquerdo traseiro
  if((chavePiscaEsquerdo == 0 && chavePiscaAlerta == 0) || frameCount % 3 == 0)
    fill(#FF7200,100); //Cor Laranja com fator de transparência
  else
    fill(#FF7200); //Cor Laranja sem fator de transparência
  box(28, 28, 4);//amarelo superior esq
  translate(0, 60, 0);
  if(chaveAcenderFarois == 1)
    fill(255, 255, 255);
  else
    fill(255, 255, 255, 100);
  box(28, 28, 4);//branco inferior esq
  
  fill(40, 40, 40);
  translate(300, -30, 0);
  box(30, 90, 2);
  fill(100, 10, 10);
  box(28, 28, 4);//vermelho central dir
  translate(0, -30, 0);
  //definindo Cor do pisca alerta direito traseiro
  if((chavePiscaDireito == 0 && chavePiscaAlerta == 0) || frameCount % 3 == 0)
    fill(#FF7200,100); //Cor Laranja com fator de transparência
  else
    fill(#FF7200); //Cor Laranja sem fator de transparência
  box(28, 28, 4);//amarelo superior dir
  translate(0, 60, 0);
  if(chaveAcenderFarois == 1)
    fill(255, 255, 255);
  else
    fill(255, 255, 255, 100);
  box(28, 28, 4);//branco inferior dir
  
  translate(-150, -430, 350);
}

void criarFarois()
{
  translate(150, 400, 350);
  int raio = 30;
  //acender/apagar farois
  strokeWeight(0.5);
  if(chaveAcenderFarois == 1)
  {
    fill(#ff7200);
    stroke(180, 180, 180, 90);
  }
  else
  {
    fill(#ff7200, 100);
    stroke(180, 180, 180);
  }
  beginShape();//Desenha o farol esquerdo
  for(float j = 0; j < PI; j += PI/90)
    for(float i = 0; i < 2*PI; i += PI/45)
      vertex(raio*cos(j)*sin(i),raio*cos(j)*cos(i), raio*sin(j)/3);
  endShape(CLOSE);
  translate(-300, 0, 0);
  beginShape();//Desenha o farol esquerdo
  for(float j = 0; j < PI; j += PI/90)
    for(float i = 0; i < 2*PI; i += PI/45)
      vertex(raio*cos(j)*sin(i),raio*cos(j)*cos(i), raio*sin(j)/3);
  endShape(CLOSE);
  translate(150, -400, -350);
  strokeWeight(1);
}

void criarRodas()
{
  float raio = 70;
  float largura = 50;
  fill(40,40,40);
  stroke(40,40,40);
  for(float i = 0; i < largura; i+=1)
  {
    beginShape();//roda dianteira esquerda
    for(float j = 0; j < PI*2; j+= PI/180)
      vertex(160+i, 500 + raio*sin(j), 250 + raio*cos(j));
    endShape(CLOSE);
  }
  for(float i = 0; i < largura; i+=1)
  {
    beginShape();//roda dianteira direita
    for(float j = 0; j < PI*2; j+= PI/180)
      vertex(-160-i, 500 + raio*sin(j), 250 + raio*cos(j));
    endShape(CLOSE);
  }
  for(float i = 0; i < largura; i+=1)
  {
    beginShape();//roda traseira esquerda
    for(float j = 0; j < PI*2; j+= PI/180)
      vertex(-160-i, 500 + raio*sin(j), -250 + raio*cos(j));
    endShape(CLOSE);
  }
  for(float i = 0; i < largura; i+=1)
  {
    beginShape();//roda traseira direita
    for(float j = 0; j < PI*2; j+= PI/180)
      vertex(160+i, 500 + raio*sin(j), -250 + raio*cos(j));
    endShape(CLOSE);
  }
  for(float i = 0; i < largura; i+=1)
  {
    beginShape();//strepe traseiro
    for(float j = 0; j < PI*2; j+= PI/180)
      vertex(raio*sin(j), 380 + raio*cos(j), -350 - i);
    endShape(CLOSE);
  }
}

void criarRetrovisores()
{
  int raio = 20;
  float x, y, z, Xfinal, Yfinal, Zfinal;
  coord aux;
  fill(40,40,40);
  stroke(40,40,40);
  
  //retrair Retrovisor direito
  if(chaveRetrairRetrovisores == 1)
  {
    if(retrovisoresRetraidos == 1)
        rotacaoRetrovisores--;
    else
        rotacaoRetrovisores++;
    if(rotacaoRetrovisores > 4 || rotacaoRetrovisores < 0)
    {
        retrovisoresRetraidos = (retrovisoresRetraidos == 0)? 1 : 0;
        chaveRetrairRetrovisores = 0;
    }
  }
  
  //retrovisor direito
  translate(192, 200, 340);
  
  //rotacionando
  rotateY(rotacaoRetrovisores*0.145);
  
  //carcaça direita
  translate(28, -25, -17);
  
  //rotacionando dnv
  rotateY(rotacaoRetrovisores*0.0725);
  
  box(25, 50, 5);
  
  //espelho direito
  translate(0, 0, -3);
  fill(255, 255, 255, 90);
  box(23, 48, 1);
  translate(0, 0, 3);
  
  //desrotacionando
  rotateY(-1*rotacaoRetrovisores*0.0725);
  
  translate(-28, 25, 17);
  
  //haste direita
  fill(40,40,40);
  Xfinal = 28;
  Yfinal = -25;
  Zfinal = -17;
  strokeWeight(3);
  line(0, 0, 0, Xfinal, Yfinal, Zfinal);
  
  //desrotacionando
  rotateY(-1*rotacaoRetrovisores*0.145);
  
  //retrovisor esquerdo
  translate(-192 * 2, 0, 0);
  
  //rotacionando
  rotateY(-1*rotacaoRetrovisores*0.145);
  strokeWeight(1);
    
  //carcaça esquerda
  translate(-28, -25, -17);
  
  //rotacionando dnv
  rotateY(-1*rotacaoRetrovisores*0.0725);
  box(25, 50, 5);
  
  //espelho esquerdo
  translate(0, 0, -3);
  fill(255, 255, 255, 90);
  box(23, 48, 1);
  translate(0, 0, 3);
    
  //desrotacionando
  rotateY(rotacaoRetrovisores*0.0725);
  
  //haste esquerda
  translate(28, 25, 17);
  Xfinal = -28;
  strokeWeight(3);
  line(0, 0, 0, Xfinal, Yfinal, Zfinal);
  strokeWeight(1);
  
  //desrotacionando
  rotateY(rotacaoRetrovisores*0.145);
  
  //retornando à origem
  translate(192, -200, -340);
  noStroke();
}

void criarLataria(){
  //parte 1
  noStroke();
  float espessura = 10;
  for (int i = 0; i < 50; i = i+1) {
    if(i>=40){
      fill(255);
    }else{
      fill(0,127,255);
    }
    box(291.3 + 17*log(i), 1, 532.6 + 35*log(i));
    translate(0,1,0);
  }
  for (int i = 0; i < 150; i = i+1) {
    fill(255,255,255, 100);
    box(350+(0.25*i), 1, 650+(0.25*i));
    fill(255);
    translate(175+(0.125*i), 0, 325 + (0.125*i));
    box(espessura, 1, espessura);// aste dianteira direita
    translate(-175-(0.125*i), 0, -325 - (0.125*i));

    translate(-175-(0.125*i), 0, -325 - (0.125*i));
    box(espessura, 1, espessura);//aste traseira esquerda
    translate(175+(0.125*i), 0, 325 + (0.125*i));

    translate(-175-(0.125*i), 0, 325 + (0.125*i));
    box(espessura, 1, espessura);//aste dianteira esquerda
    translate(175+(0.125*i), 0, -325 - (0.125*i));
    
    translate(175+(0.125*i), 0, -325 - (0.125*i));
    box(espessura, 1, espessura);//aste traseira direita
    translate(-175-(0.125*i), 0, 325 + (0.125*i));
    
    translate(175+(0.125*i), 0, 110);
    box(espessura, 1, espessura);// aste mediana frontal direita
    translate(-175-(0.125*i), 0, -110);
    
    translate(175+(0.125*i), 0, -110);
    box(espessura, 1, espessura);// aste mediana traseira direita
    translate(-175-(0.125*i), 0, 110);
    
    translate(-175-(0.125*i), 0, 110);
    box(espessura, 1, espessura);// aste mediana frontal esquerda
    translate(+175+(0.125*i), 0, -110);
    
    translate(-175-(0.125*i), 0, -110);
    box(espessura, 1, espessura);// aste mediana traseira esquerda
    translate(+175+(0.125*i), 0, 110);
    translate(0,1,0);
  }
  for (int i = 0; i < 300; i = i+1) {
    if (i<=10){
      fill(255);
      box(400, 1, 700);
    }else if(i>=280){
      fill(255);
      box(410, 1, 710);
    }else{
      fill(0,127,255);
      box(400, 1, 700);
    }
    translate(0,1,0);
  }
  translate(-60, -25, 360);
  image(placa, 0, 0, 120, 39);
  translate(120, 0, -720);
  rotateY(PI);
  image(placa, 0, 0, 120, 39);
  rotateY(PI);
  translate(-60, -475, 360);//voltando ao ponto (500, 500, 0)
}
