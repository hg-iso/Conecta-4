% ============================================================
%  player.pl   -   PLANTILLA DE ENTREGA
%  Evaluación 2  ·  INF224 Lógica para Ciencias de la Computación
%  UCM 2026
% ------------------------------------------------------------
%  Este archivo es el punto de partida. El jugador que trae
%  elige SIEMPRE la primera columna disponible: es legal, pero
%  es el peor jugador posible. Su trabajo es reemplazarlo.
%
%  NO cambie el nombre del módulo ni la aridad de ai_move/3:
%  el motor del torneo lo carga por ese nombre exacto.
% ============================================================

:- module(player, [ai_move/3]).

% ------------------------------------------------------------
%  ai_move(+Ficha, +Tablero, -Columna)
%
%    Ficha    es  x  o  o  :  la ficha con la que juega usted.
%    Tablero  es una lista de 7 columnas.
%             Cada columna es una lista de fichas ya jugadas,
%             con la MÁS RECIENTE al frente.
%             Las casillas libres no aparecen: una columna
%             vacía es  []  y una llena tiene 6 elementos.
%    Columna  es el número de columna donde suelta la ficha,
%             entre 1 y 7, y debe tener menos de 6 fichas.
%
%  Devolver una columna llena o fuera de 1..7 descalifica.
% ------------------------------------------------------------

ai_move(_Ficha, Tablero, Columna) :-
    columna_disponible(Tablero, Columna),
    !.

% columna_disponible(+Tablero, -Columna)
%   Columna es una columna con espacio. Entrega las disponibles
%   de izquierda a derecha, por backtracking.
columna_disponible(Tablero, Columna) :-
    between(1, 7, Columna),
    nth1(Columna, Tablero, Fichas),
    length(Fichas, N),
    N < 6.
