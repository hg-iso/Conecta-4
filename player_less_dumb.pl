% ============================================================
%  player.pl  -  Jugador Conecta 4: Minimax (negamax) con poda alfa-beta
%  INF224 Logica para Ciencias de la Computacion - UCM 2026
% ------------------------------------------------------------
%  Estrategia:
%   * Negamax con poda alfa-beta y profundidad limitada.
%   * Orden de exploracion centro-primero (mejora la poda).
%   * Victorias mas rapidas valen mas; derrotas mas lentas
%     duelen menos (el valor de victoria incluye la profundidad).
%   * Heuristica en las hojas: ventanas de 4 casillas (filas,
%     columnas y ambas diagonales) + bonus por la columna central.
%   * Sin assert ni retract. Siempre entrega una columna valida.
% ============================================================

:- module(player_less_dumb, [ai_move/3]).

% ------------------------------------------------------------
%  ai_move(+Ficha, +Tablero, -Columna)
% ------------------------------------------------------------
ai_move(Ficha, Tablero, Columna) :-
    movimientos(Tablero, Ms),
    Ms = [_|_],
    profundidad(Tablero, D),
    alfa_beta_inicial(L), Beta is -L,
    mejor(Ms, Tablero, Ficha, D, L, Beta, none, L, Columna, _),
    Columna \== none,
    !.
% Respaldo: cualquier columna con espacio.
ai_move(_Ficha, Tablero, Columna) :-
    columna_disponible(Tablero, Columna),
    !.

alfa_beta_inicial(-1000000).

% columna_disponible(+Tablero, -Columna)
columna_disponible(Tablero, Columna) :-
    between(1, 7, Columna),
    nth1(Columna, Tablero, Fichas),
    length(Fichas, N),
    N < 6.

% ------------------------------------------------------------
%  Profundidad adaptativa: mas fichas puestas => menos ramas
%  => se puede mirar mas lejos con el mismo costo.
% ------------------------------------------------------------
profundidad(Tablero, D) :-
    foldl([C, A0, A]>>(length(C, N), A is A0 + N), Tablero, 0, Total),
    (   Total < 20 -> D = 5
    ;   Total < 30 -> D = 6
    ;   D = 8
    ).

% ------------------------------------------------------------
%  Movimientos legales ordenados centro-primero
% ------------------------------------------------------------
movimientos(Tablero, Ms) :-
    include(tiene_espacio(Tablero), [4,3,5,2,6,1,7], Ms).

tiene_espacio(Tablero, Col) :-
    nth1(Col, Tablero, Fichas),
    length(Fichas, N),
    N < 6.

jugar(Tablero, Col, Ficha, Nuevo) :-
    nth1(Col, Tablero, Vieja, Resto),
    nth1(Col, Nuevo, [Ficha|Vieja], Resto).

contrario(x, o).
contrario(o, x).

% ------------------------------------------------------------
%  negamax(+Tablero, +Turno, +Prof, +Alfa, +Beta, -Valor)
%  Valor desde el punto de vista de quien mueve (Turno).
% ------------------------------------------------------------
negamax(Tablero, Turno, Prof, Alfa, Beta, Valor) :-
    movimientos(Tablero, Ms),
    (   Ms = []     -> Valor = 0                       % empate
    ;   Prof =:= 0  -> evaluar(Tablero, Turno, Valor)  % hoja
    ;   alfa_beta_inicial(L),
        mejor(Ms, Tablero, Turno, Prof, Alfa, Beta, none, L, _, Valor)
    ).

% mejor(+Ms, +Tab, +Turno, +Prof, +Alfa, +Beta,
%       +MejorM0, +MejorV0, -MejorM, -MejorV)
mejor([], _, _, _, _, _, M, V, M, V).
mejor([Col|Ms], Tab, Turno, Prof, Alfa, Beta, M0, V0, M, V) :-
    jugar(Tab, Col, Turno, Nuevo),
    (   gana(Nuevo, Col, Turno)
    ->  Val is 10000 + Prof
    ;   contrario(Turno, Rival),
        P1 is Prof - 1,
        NA is -Beta, NB is -Alfa,
        negamax(Nuevo, Rival, P1, NA, NB, V1),
        Val is -V1
    ),
    (   Val > V0 -> M1 = Col, V1b = Val ; M1 = M0, V1b = V0 ),
    A1 is max(Alfa, V1b),
    (   A1 >= Beta                       % poda beta
    ->  M = M1, V = V1b
    ;   mejor(Ms, Tab, Turno, Prof, A1, Beta, M1, V1b, M, V)
    ).

% ------------------------------------------------------------
%  Deteccion de victoria tras soltar ficha en Col
% ------------------------------------------------------------
gana(Tab, Col, Ficha) :-
    nth1(Col, Tab, Columna),
    length(Columna, Fila),
    member(DC-DF, [1-0, 0-1, 1-1, 1-(-1)]),
    contar(Tab, Col, Fila, DC, DF, Ficha, A),
    DC2 is -DC, DF2 is -DF,
    contar(Tab, Col, Fila, DC2, DF2, Ficha, B),
    A + B >= 3,
    !.

contar(Tab, C, F, DC, DF, Ficha, N) :-
    C1 is C + DC, F1 is F + DF,
    (   celda(Tab, C1, F1, V), V == Ficha
    ->  contar(Tab, C1, F1, DC, DF, Ficha, N0),
        N is N0 + 1
    ;   N = 0
    ).

% celda(+Tab, +Col, +Fila, -Ficha): falla si esta libre o fuera
celda(Tab, C, F, V) :-
    C >= 1, C =< 7, F >= 1,
    nth1(C, Tab, Columna),
    length(Columna, N),
    F =< N,
    I is N - F,
    nth0(I, Columna, V).

% ------------------------------------------------------------
%  Heuristica: puntaje desde el punto de vista de Turno
% ------------------------------------------------------------
evaluar(Tab, Turno, Valor) :-
    contrario(Turno, Rival),
    maplist(rellenar, Tab, Cols),               % 7 listas de 6 (abajo primero)
    numlist(1, 6, Fs),
    maplist(fila(Cols), Fs, Filas),
    maplist(desplazar(sube), [1,2,3,4,5,6,7], Cols, Dsube),
    maplist(desplazar(baja), [1,2,3,4,5,6,7], Cols, Dbaja),
    numlist(1, 12, Fs12),
    maplist(fila(Dsube), Fs12, Diag1),
    maplist(fila(Dbaja), Fs12, Diag2),
    append([Cols, Filas, Diag1, Diag2], Lineas),
    foldl(puntuar_linea(Turno, Rival), Lineas, 0, S0),
    nth1(4, Tab, Centro),
    include(==(Turno), Centro, Mios),  length(Mios, NM),
    include(==(Rival), Centro, Suyos), length(Suyos, NS),
    Valor is S0 + 3 * (NM - NS).

% rellenar(+ColumnaOriginal, -Columna6): abajo primero, 'e' = libre
rellenar(Col, Rell) :-
    reverse(Col, Abajo),
    length(Abajo, N), K is 6 - N,
    length(Pad, K), maplist(=(e), Pad),
    append(Abajo, Pad, Rell).

fila(Cols, F, Fila) :- maplist(nth1(F), Cols, Fila).

% desplazar(+Modo, +I, +Col, -ColDesp): meter paredes 'w' para que
% las filas de la rejilla desplazada sean las diagonales.
desplazar(baja, I, Col, Out) :- Pre is I - 1, Suf is 7 - I, rodear(Pre, Suf, Col, Out).
desplazar(sube, I, Col, Out) :- Pre is 7 - I, Suf is I - 1, rodear(Pre, Suf, Col, Out).

rodear(Pre, Suf, Col, Out) :-
    length(P, Pre), maplist(=(w), P),
    length(S, Suf), maplist(=(w), S),
    append([P, Col, S], Out).

puntuar_linea(T, R, Linea, S0, S) :-
    ventanas(Linea, T, R, S0, S).

ventanas([A,B,C,D|Resto], T, R, S0, S) :-
    !,
    ventana([A,B,C,D], T, R, V),
    S1 is S0 + V,
    ventanas([B,C,D|Resto], T, R, S1, S).
ventanas(_, _, _, S, S).

ventana(W, T, R, V) :-
    cuenta(W, T, P),
    cuenta(W, R, Q),
    cuenta(W, e, E),
    (   P + E =:= 4 -> peso_propio(P, V)
    ;   Q + E =:= 4 -> peso_rival(Q, V0), V is -V0
    ;   V = 0
    ).

cuenta([], _, 0).
cuenta([H|T], X, N) :-
    cuenta(T, X, N0),
    (   H == X -> N is N0 + 1 ; N = N0 ).

peso_propio(0, 0).
peso_propio(1, 1).
peso_propio(2, 4).
peso_propio(3, 12).
peso_propio(4, 0).    % no ocurre: las victorias se detectan antes

peso_rival(0, 0).
peso_rival(1, 1).
peso_rival(2, 4).
peso_rival(3, 14).
peso_rival(4, 0).
