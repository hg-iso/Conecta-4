================================================================
  EVALUACIÓN 2 — ESTUDIO DE CASO
  Un jugador de Conecta 4 en Prolog
  INF224  Lógica para Ciencias de la Computación  ·  UCM 2026
================================================================

  Lea este archivo completo antes de escribir una sola línea.
  Los pasos 1 a 3 no requieren programar nada y confirman que
  el entorno funciona.


----------------------------------------------------------------
 0.  QUÉ HAY EN ESTA CARPETA
----------------------------------------------------------------

  connect4.pl    El motor del juego: tablero, turnos, detección
                 de victoria, medición. NO lo modifique, salvo
                 las tres líneas que se indican en el paso 4.

  rndplay.pl     La máquina aleatoria contra la que se mide su
                 desempeño. NO la modifique.

  player.pl      SU JUGADOR. Es el archivo que usted entrega.
                 Viene con un jugador que funciona pero juega
                 pésimo: su trabajo es reemplazarlo.

  README.txt     Este archivo.

  Los cuatro deben estar en la misma carpeta. El motor carga
  los otros dos por nombre, desde el directorio actual.


----------------------------------------------------------------
 1.  REQUISITOS
----------------------------------------------------------------

  SWI-Prolog instalado.  https://www.swi-prolog.org/Download.html

  Para comprobarlo, abra una terminal en la carpeta y escriba:

      swipl --version

  Debería responder con un número de versión. Si dice que la
  orden no existe, SWI-Prolog no está instalado o no está en
  el PATH.


----------------------------------------------------------------
 2.  PRIMERA PRUEBA, SIN TOCAR NADA
----------------------------------------------------------------

  Tal como vienen, los archivos ya corren: dos máquinas
  aleatorias juegan entre sí. Sirve para confirmar que todo
  está en orden antes de meter su código.

      swipl connect4.pl
      ?- play.

  Debería ver el tablero dibujado turno a turno, la columna
  elegida y el tiempo de cada jugada, y al final el ganador.

  Para salir de SWI-Prolog:

      ?- halt.

  NOTA: el comentario al principio de connect4.pl menciona un
  archivo llamado jugar.pl. Es un nombre antiguo. El archivo
  correcto es connect4.pl.


----------------------------------------------------------------
 3.  CÓMO VIENE EL TABLERO
----------------------------------------------------------------

  Esto es lo más importante del README. Si lo entiende mal,
  todo lo demás se construye sobre una base equivocada.

  El tablero es una LISTA DE SIETE COLUMNAS:

      [[], [], [], [x,o,x], [], [o], []]

  * Cada columna es la lista de las fichas YA JUGADAS en ella.

  * La ficha MÁS RECIENTE va al FRENTE de la lista.
    En la columna 4 del ejemplo, la x del frente es la última
    que se jugó; la x del final es la primera, la de más abajo.

  * NO existe ningún átomo para "casilla vacía".
    No hay vacio, ni v, ni 0, ni nada.
    Una columna vacía es simplemente  []  y una columna llena
    tiene 6 elementos. Las columnas tienen largos distintos
    entre sí, y su código tiene que tolerarlo.

  * Tablero inicial:   [[],[],[],[],[],[],[]]
    Tablero lleno:     siete listas de seis elementos, 42 fichas.

  Las COORDENADAS, si decide usarlas, se cuentan así:

      columna 4 = [x, o, x]       (tres fichas apiladas)

          fila 3  ->  x      la de más arriba, la última jugada
          fila 2  ->  o
          fila 1  ->  x      la de más abajo, la primera jugada
          fila 4  ->  falla  esa casilla está libre

  La fila 1 es la de ABAJO. La fila de más arriba de una
  columna coincide con su cantidad de fichas. Pedir una casilla
  libre no devuelve un valor especial: el objetivo FALLA.


----------------------------------------------------------------
 4.  ENGANCHAR SU JUGADOR AL MOTOR
----------------------------------------------------------------

  Son tres cambios en connect4.pl, y nada más.

  --- CAMBIO 1 ---------------------------------------------

  Al principio del archivo dice:

      :- use_module('rndplay.pl', [ rnjesus/3 ]).
      %   use_module('player.pl', [ ai_move/3 as player1_move ]),
      %   use_module('player.pl', [ ai_move/3 as player2_move ]).

  Déjelo así:

      :- use_module('rndplay.pl', [ rnjesus/3 ]),
         use_module('player.pl', [ ai_move/3 as player1_move ]),
         use_module('player.pl', [ ai_move/3 as player2_move ]).

  ATENCIÓN: además de quitar los dos signos % , el PUNTO del
  final de la primera línea pasa a ser una COMA. Si no lo
  cambia, el archivo no carga. Este es el error más frecuente.

  --- CAMBIOS 2 y 3 ----------------------------------------

  Más abajo, en la sección de parámetros, están estas líneas:

      dconf(p_mode(x, rand)).
      dconf(p_mode(o, rand)).

  Los valores posibles son:

      rand   juega la máquina aleatoria
      auto   juega su ai_move/3
      user   juega una persona, por teclado

  Qué poner depende de lo que quiera hacer. Vea el paso 5 y
  el paso 6: NO es el mismo valor en los dos casos.


----------------------------------------------------------------
 5.  JUGAR UNA PARTIDA Y MIRARLA
----------------------------------------------------------------

  Para que SU jugador enfrente a la máquina aleatoria:

      dconf(p_mode(x, auto)).      <- usted juega de X
      dconf(p_mode(o, rand)).      <- la máquina juega de O

  Después:

      swipl connect4.pl
      ?- play.

  Si quiere jugar usted mismo contra su propio jugador, ponga
  user en uno de los dos y le pedirá la columna por teclado.

  Si pone auto en los dos, su jugador juega contra sí mismo.
  Es un test válido, pero no mide nada contra la máquina.


----------------------------------------------------------------
 6.  MEDIR LA TASA DE VICTORIAS
----------------------------------------------------------------

  Este es el número que evalúa el criterio 4 de la rúbrica.

  *** PARA MEDIR, LOS DOS PARÁMETROS VAN EN auto ***

      dconf(p_mode(x, auto)).
      dconf(p_mode(o, auto)).

  Parece contradictorio, pero no lo es: run_play fuerza
  internamente a uno de los dos lados a jugar aleatorio, y
  alterna cuál. Con los dos en auto, su jugador participa en
  los dos lotes: uno como O y otro como X.

  Si deja  o  en rand, el primer lote termina siendo aleatorio
  contra aleatorio y su jugador no juega. La mitad de la
  medición se pierde.

  Antes de medir, baje la cantidad de partidas mientras depura:

      dconf(ntest(1000)).    ->    dconf(ntest(50)).

  Después:

      swipl connect4.pl
      ?- run_play.

  Juega ntest partidas con su jugador de un lado y otras tantas
  del otro, e informa el tiempo total de cada lote. Cada partida
  agrega una línea al archivo match.csv con este formato:

      "ganador","tipo de final",tiempo_x,tiempo_o

  El tipo de final puede ser:

      normal     alguien hizo cuatro en línea
      error      JUGADA INVÁLIDA: alguien devolvió una columna
                 llena o fuera de rango y perdió en el acto
      tie        tablero lleno, empate completo
      tiebreak   tablero lleno, ganó el más rápido

  Para contar, desde la terminal (no desde SWI-Prolog):

      grep -c '^"x"'     match.csv      victorias de X
      grep -c '^"o"'     match.csv      victorias de O
      grep -c '"error"'  match.csv      partidas perdidas por
                                        jugada inválida

  En Windows, con PowerShell:

      (Select-String -Path match.csv -Pattern '^"x"').Count

  IMPORTANTE: match.csv se escribe AGREGANDO al final, nunca se
  borra solo. Bórrelo entre una medición y otra, o va a estar
  contando resultados viejos mezclados con nuevos.

  Si ve aunque sea un solo final de tipo error, ese es el
  primer problema que debe resolver: es una partida perdida
  sin haber jugado.


----------------------------------------------------------------
 7.  PROBAR CON INICIO ALEATORIO
----------------------------------------------------------------

  La rúbrica evalúa el desempeño con y sin inicio aleatorio.

      dconf(start(0)).    ->    dconf(start(2)).

  Juega 2 rondas aleatorias antes de que empiece la partida, de
  modo que su jugador reciba un tablero ya empezado. El valor
  debe ser MENOR QUE 4; con 4 o más, play. simplemente falla.

  Si su tasa cae mucho con inicio aleatorio, lo más probable es
  que su jugador esté suponiendo algo sobre el tablero vacío.

  Mida y anote CUATRO números: como X y como O, con y sin
  inicio aleatorio. Van en el informe.


----------------------------------------------------------------
 8.  TODOS LOS PARÁMETROS
----------------------------------------------------------------

  Están juntos al principio de connect4.pl, en las líneas dconf.

      start(N)          N rondas aleatorias antes de empezar.
                        Debe ser menor que 4.

      delay(F)          Alarga artificialmente la espera entre
                        jugadas, multiplicando el tiempo de
                        cómputo por F. Útil solo para mirar.

      difficulty(D)     Dificultad de la máquina aleatoria:
                          e  fácil   (solo columnas 1,2,6,7)
                          n  normal  (las siete columnas)
                          h  difícil (solo columnas 3,4,5)
                        h es más difícil porque el centro del
                        tablero es la zona que más sirve.

      p_mode(F, M)      Quién juega con la ficha F.
                        Vea los pasos 5 y 6.

      manual_check(S)   y / n : validar o no las jugadas que
                        escribe una persona por teclado.

      pout(S)           y / n : guardar o no los resultados en
                        match.csv.

      show(S)           y / n : mostrar o no el tablero y los
                        mensajes. run_play lo apaga solo.

      ntest(N)          Cantidad de partidas por lote en
                        run_play.

  Si prefiere no editar el archivo para una prueba rápida,
  puede cambiar un parámetro desde la consola:

      ?- asserta(config(ntest(20))).

  Queda vigente hasta que cierre SWI-Prolog.


----------------------------------------------------------------
 9.  LAS DOS REGLAS DEL MOTOR QUE CUESTAN PARTIDAS
----------------------------------------------------------------

  1. UNA COLUMNA LLENA DESCALIFICA

     Si ai_move/3 devuelve una columna que ya tiene 6 fichas,
     o un número fuera del rango 1 a 7, el motor lo trata como
     jugada inválida y usted PIERDE LA PARTIDA EN EL ACTO.
     No hay segunda oportunidad ni reintento.

     Comprobar que la columna elegida tenga espacio debería ser
     lo último que hace su predicado antes de responder.

     Y asegúrese de que ai_move/3 nunca falle: si no encuentra
     jugada, el motor se queda sin respuesta. Conviene una
     cláusula final de respaldo que entregue cualquier columna
     con espacio.

  2. LOS EMPATES SE DECIDEN POR TIEMPO

     El motor acumula el tiempo de cómputo de cada jugador
     durante toda la partida. Si el tablero se llena sin que
     nadie haga cuatro en línea, gana quien haya gastado MENOS
     tiempo.

     Por eso el enunciado prohíbe la fuerza bruta: no es solo
     una exigencia de estilo, es literalmente el criterio de
     desempate del torneo.


----------------------------------------------------------------
 10.  PROBLEMAS FRECUENTES
----------------------------------------------------------------

  "Syntax error: Operator expected" al cargar connect4.pl
      Olvidó cambiar el punto por una coma en el cambio 1.

  "Unknown procedure: player1_move/3"
      Las líneas del use_module siguen comentadas, o player.pl
      no está en la misma carpeta.

  "No permission to modify static procedure"
      Está intentando usar assert o retract sobre un predicado
      que definió en el archivo. Recuerde que el enunciado pide
      que su programa funcione SIN assert ni retract.

  "Arguments are not sufficiently instantiated"
      Un objetivo necesitaba un valor que todavía no existía.
      Casi siempre: una comparación o un cálculo colocado antes
      del objetivo que le daba valor a la variable.

  El jugador funciona de X pero falla de O
      Dejó la ficha del rival escrita como constante. La ficha
      del rival es la contraria a la que recibe ai_move/3, y el
      motor lo hace jugar con las dos.

  La partida se queda colgada
      Ctrl+C y después la tecla  a  para abortar.
      Revise si tiene una recursión que no reduce el problema.

  run_play tarda muchísimo
      Baje ntest. Con 1000 son 2000 partidas en total.


----------------------------------------------------------------
 11.  QUÉ SE ENTREGA
----------------------------------------------------------------

  * player.pl   con su jugador.

      - El módulo debe declararse exactamente así:

            :- module(player, [ai_move/3]).

        El nombre del módulo, el nombre del predicado y la
        aridad son los que carga el motor del torneo. Si no
        calzan, su trabajo no se puede ejecutar ni evaluar.

      - No entregue connect4.pl ni rndplay.pl modificados:
        los cambios de los pasos 4 a 7 son solo para que usted
        pueda probar en su computador.

  * El informe, según la estructura del enunciado:
    introducción de máximo 500 palabras, desarrollo con la
    fundamentación de cada predicado, y anexos para los
    predicados auxiliares.

  Todo se sube a la plataforma LMS dentro del plazo. La entrega
  atrasada tiene 10 % de descuento por cada hora o fracción.
