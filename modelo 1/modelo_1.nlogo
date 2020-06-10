globals
[
  casos                                            ;; número de casos confirmados en la enfermedad
  recuperados                                      ;; número de individuos recuperados de la enfermedad
  muertos                                          ;; número de individuos que no pasan la enfermedad
  porcentaje-infectados                            ;; porcentaje de infectados de la población en un instante
  porcentaje-curados                               ;; porcentaje de curados de la población en un instante
  porcentaje-muertos                               ;; porcentaje de muertos de la población en un instante
  porcentaje-susceptibles                          ;; porcentaje de susceptibles de la población en un instante
  calculo-tasa-recuperacion                        ;; número que indica el porcentaje de recuperación de la enfermedad según los datos introducidos
  calculo-tasa-letalidad                           ;; número que indica el porcentaje de letalidad de la enfermedad según los datos introducidos
  calculo-casos                                    ;; indica el número de casos según los datos introducidos
  calculo-recuperados                              ;; indica el número de recuperados según los datos introducidos
  calculo-muertos                                  ;; indica el número de muertos según los datos introducidos
  infectados-anterior                              ;; número de infectados en el instante anterior
  r0                                               ;; tasa r0
  mu                                               ;; tasa de nuevos recuperados por instante
  lambda                                           ;; tasa de nuevos infectados por instante
]

turtles-own
[
  infectado?                                       ;; atributo que indica si el agente presenta la enfermedad
  curado?                                          ;; atributo que indica si el agente ha pasado la enfermedad
  susceptible?                                     ;; atributo que indica si el agente puede pasar la enfermedad
  tiempo_recup                                     ;; tiempo que tarda en recuperarse el agente de la enfermedad
  tiempo_infectado                                 ;; tiempo que lleva infectado el agente

  ;; los siguientes atributos son booleanos que indican si el agente presenta o no un determinado síntoma
  fiebre?
  tos?
  dificultad_respiratoria?
  fatiga?
  dolor_articular?
  neumonia?
  vomitos?
  diarrea?
  malestar?
  dolor_muscular?
  dolor_garganta?
  falta_apetito?
  nausea?

  tiene_mascarilla?                                 ;; indica si el agente tiene mascarilla para reducir la posibilidad de contagio
]



;; ------------------------
;; | PROCEDIMIENTOS SETUP |
;; ------------------------

;; procedimiento para inicializar los agentes (humanos)
to setup
  clear-all                                        ;; se limpia la pantalla del modelo
  setup-people                                     ;; se muestran tantos individuos como se hayan introducido en el panel
  reset-ticks
end

;; permite generar un archivo imagen de la interfaz
to exportar-interfaz                               ;; permite exportar una imagen de la interfaz entera en un momento cualquier
  let file user-new-file                           ;; se le permite al usuario crear un archivo donde guardar la imagen
  export-interface file                            ;; se guarda la imagen actual de la interfaz en el archivo seleccionado
end

;; procedimiento para inicializar los individuos
to setup-people
  create-turtles numero-personas
    [
      setxy random-xcor random-ycor                  ;; se le dan unas coordenadas (x,y) aleatorias
      set infectado? false
      set curado? false
      set susceptible? true
      set tiempo_recup random-float 2 * tiempo-recuperacion   ;; se crea el tiempo de recuperación del agente

      set size 1.5                                   ;; se le asigna un tamaño mayor para verlo mejor
      set shape forma                                ;; se le indica la forma escogida en el desplegable
      set color white                                ;; se le asigna el color blanco puesto que no han sido curados, infectados o han muerto
      infeccion-inicial                              ;; se infecta un porcentaje inicial de la población
      cambia-color                                   ;; se colorea el agente según sus características
    ]
end

;; procedimiento para cargar los datos en un fichero .txt que incluya nºcasos, nºrecuperados y nºmuertos, ej: 2887 2331 556
to cargar-datos-letalidad-contagios
 let file user-file                               ;; el usuario elige el archivo que quiera leer

  if (file != false)                             ;; el botón no funcionará en el caso de no haberse escogido ningún archivo
  [
    file-open file                                 ;; se abre el archivo
    set calculo-casos file-read                            ;; se asigna el nºcasos a la variable casos
    set calculo-recuperados file-read                      ;; se asigna el nºrecuperados a la variable recuperados
    set calculo-muertos file-read                          ;; se asigna el nºmuertos a la variable muertos
    user-message "¡Archivo leído con éxito!"       ;; se muestra un mensaje donde se indica el éxito en leer los datos
    file-close                                     ;; se cierra el archivo
  ]
end

;; procedimiento que calcula la letalidad de los datos introducidos y se muestra en el monitor correspondiente, así como la tasa de recuperación
to mostrar-letalidad-y-tasa-recuperacion
  set calculo-tasa-letalidad calculo-muertos / calculo-casos * 100
  set calculo-tasa-recuperacion calculo-recuperados / calculo-casos * 100
end


to mover
  rt random-float 360
  fd 1
end

;; procedimiento para simular el movimiento de los agentes
to go                                              ;; se realiza el movimiento de los individuos
  if all? turtles [not infectado?]
  [
    stop
  ]
  ask turtles
  [
    mover
  ]
  ask turtles with [susceptible?]
  [
    poder-conseguir-mascarillas
  ]
  ask turtles with [infectado?]
  [
    infectar
    poder-recuperarse
    poder-morir
  ]
  ask turtles
  [
    cambia-color
    tasa-r0
    set porcentaje-infectados (count turtles with [infectado?] / numero-personas * 100)
    set porcentaje-curados (count turtles with [curado?] / numero-personas * 100)
    set porcentaje-muertos ((muertos) / numero-personas * 100)
    set porcentaje-susceptibles 100 - porcentaje-infectados - porcentaje-curados - porcentaje-muertos
  ]
 tick
end

;; procedimiento que puede provocar la muerte del agente si ya ha pasado el tiempo de recuperación
to poder-morir
  if tiempo_infectado > tiempo_recup
  [
    if random-float 100 < %-probabilidad-muerte
    [
      set muertos (muertos + 1)
      die
    ]
  ]
end


;; procedimiento para la obtención de una mascarilla y disminuir la posibilidad de contagio del agente
to poder-conseguir-mascarillas
  if susceptible? = true
  [
    if random-float 100 < %-conseguir-mascarilla
    [
      set tiene_mascarilla? true
    ]
  ]
end


;; este procedimiento permite infectar a los agentes cercanos a aquellos que se encuentran infectados
;; si el agente cercano presenta una mascarilla, la probabilidad de contagio disminuye
to infectar
  let no-infectados-cercanos (turtles-on neighbors) with [not infectado? and not curado? and susceptible?]
  if no-infectados-cercanos != nobody
  [
    ask no-infectados-cercanos
    [
      if tiene_mascarilla? = true
      [
        if random-float 100 < (%-probabilidad-contagio - %-proteccion-mascarilla)
        [
          set infectado? true
          set casos (casos + 1)
          crear-sintomas
        ]
      ]
      if random-float 100 < %-probabilidad-contagio
        [
          set infectado? true
          set casos (casos + 1)
          crear-sintomas
        ]
    ]
  ]
end


;; este procedimiento otorga al agente una oportunidad de recuperarse si el tiempo de infección supera el tiempo de recuperación del individuo
to poder-recuperarse
  set tiempo_infectado (tiempo_infectado + 1)
  if tiempo_infectado > tiempo_recup
  [
    if random-float 100 < %-probabilidad-recuperacion
    [
      set infectado? false
      set curado? true
      set recuperados (recuperados + 1)
    ]
  ]
end


;; este procedimiento infecta a un porcentaje de la población inicial. Tanto el número de agentes inicial como el porcentaje de infeccion inicial son introducidos por pantalla
to infeccion-inicial
  if random-float 100 < %-infeccion-inicial
  [
    set infectado? true
    set susceptible? false
    set tiempo_infectado random tiempo-recuperacion
    crear-sintomas

  ]
end


;; el siguiente procedimiento genera los síntomas para los agentes cuando son infectados
;; según un número aleatorio generado y el porcentaje introducido por pantalla
to crear-sintomas
  if infectado? = true
  [
    ifelse random-float 100 < %-fiebre
    [set fiebre? true][set fiebre? false]
    ifelse random-float 100 < %-tos
    [set tos? true][set tos? false]
    ifelse random-float 100 < %-dificultad-respirar
    [set dificultad_respiratoria? true][set dificultad_respiratoria? false]
    ifelse random-float 100 < %-fatiga
    [set fatiga? true][set fatiga? false]
    ifelse random-float 100 < %-dolor-articular
    [set dolor_articular? true][set dolor_articular? false]
    ifelse random-float 100 < %-neumonia
    [set neumonia? true][set neumonia? false]
    ifelse random-float 100 < %-vomitos
    [set vomitos? true][set vomitos? false]
    ifelse random-float 100 < %-diarrea
    [set diarrea? true][set diarrea? false]
    ifelse random-float 100 < %-malestar
    [set malestar? true][set malestar? false]
    ifelse random-float 100 < %-dolor-muscular
    [set dolor_muscular? true][set dolor_muscular? false]
    ifelse random-float 100 < %-dolor-garganta
    [set dolor_garganta? true][set dolor_garganta? false]
    ifelse random-float 100 < %-falta-apetito
    [set falta_apetito? true][set falta_apetito? false]
    ifelse random-float 100 < %-nausea
    [set nausea? true][set nausea? false]
  ]
end

;; este procedimiento asigna un color al agente según sus características
to cambia-color
  if infectado? [set color red]
  if curado? [set color green]
end

;; procedimiento para el cálculo de la tasa R0, de un modelo SIR donde la S son los individuos Susceptibles, la I son los infectados y la R son los recuperados, donde también se incluyen los muertos
to tasa-r0
  let nuevos-infectados casos
  let nuevos-recuperados recuperados + muertos

  set infectados-anterior count turtles with [infectado?] + nuevos-recuperados - nuevos-infectados

  let susceptibles-actual numero-personas - count turtles with [infectado?] - count turtles with [curado?]

  let susceptibles-inicial numero-personas - count turtles with [infectado?]

  ifelse infectados-anterior < 5
  [set lambda 0]
  [set lambda (nuevos-infectados / infectados-anterior)]

  ifelse infectados-anterior < 5
  [set mu 0]
  [set mu (nuevos-recuperados / infectados-anterior)]


  if numero-personas - susceptibles-actual > 0 and susceptibles-actual > 0
  [
    set r0 (ln (susceptibles-inicial / susceptibles-actual) / (numero-personas - susceptibles-actual))
    set r0 r0 * susceptibles-inicial
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
953
10
1507
565
-1
-1
16.55
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
días
30.0

BUTTON
30
12
93
45
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
109
13
172
46
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
28
62
183
122
numero-personas
100.0
1
0
Number

CHOOSER
194
13
345
58
forma
forma
"dot" "person" "turtle"
1

SLIDER
360
209
685
242
tiempo-recuperacion
tiempo-recuperacion
0
80
30.0
1
1
NIL
HORIZONTAL

INPUTBOX
188
61
351
121
%-infeccion-inicial
5.0
1
0
Number

INPUTBOX
366
10
421
70
%-fiebre
84.53
1
0
Number

INPUTBOX
426
10
476
70
%-tos
36.98
1
0
Number

INPUTBOX
481
10
586
70
%-dificultad-respirar
8.68
1
0
Number

INPUTBOX
589
10
639
70
%-fatiga
7.55
1
0
Number

INPUTBOX
643
10
735
70
%-dolor-articular
4.91
1
0
Number

INPUTBOX
364
72
439
132
%-neumonia
4.15
1
0
Number

INPUTBOX
443
72
511
132
%-vomitos
3.02
1
0
Number

INPUTBOX
581
73
649
133
%-malestar
19.25
1
0
Number

INPUTBOX
516
71
578
131
%-diarrea
2.26
1
0
Number

INPUTBOX
650
72
743
132
%-dolor-muscular
5.66
1
0
Number

INPUTBOX
364
139
465
199
%-dolor-garganta
10.57
1
0
Number

INPUTBOX
468
139
554
199
%-falta-apetito
1.13
1
0
Number

INPUTBOX
558
140
621
200
%-nausea
1.13
1
0
Number

INPUTBOX
28
128
154
188
%-conseguir-mascarilla
50.0
1
0
Number

INPUTBOX
156
129
286
189
%-proteccion-mascarilla
30.0
1
0
Number

INPUTBOX
27
195
159
255
%-probabilidad-contagio
40.0
1
0
Number

INPUTBOX
163
196
318
256
%-probabilidad-recuperacion
62.67
1
0
Number

PLOT
27
259
577
547
Número Infectados, Curados y Muertos
NIL
NIL
0.0
250.0
0.0
100.0
true
true
"" ""
PENS
"Infectados" 1.0 0 -2674135 true "" "plot count turtles with [infectado?]"
"Curados" 1.0 0 -13840069 true "" "plot count turtles with [curado?]"
"Muertos" 1.0 0 -16777216 true "" "plot muertos"
"Susceptibles" 1.0 0 -1664597 true "" "plot numero-personas - (count turtles with [infectado?] + muertos + count turtles with [curado?])"

MONITOR
593
328
678
373
%-infectados
porcentaje-infectados
2
1
11

MONITOR
593
380
662
425
%-curados
porcentaje-curados
2
1
11

INPUTBOX
630
141
750
201
%-probabilidad-muerte
11.31
1
0
Number

MONITOR
593
431
668
476
%-muertos
porcentaje-muertos
2
1
11

BUTTON
764
16
938
49
NIL
cargar-datos-letalidad-contagios\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
749
59
953
92
NIL
mostrar-letalidad-y-tasa-recuperacion
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
767
104
910
149
%-muerte-según-datos
calculo-tasa-letalidad
2
1
11

MONITOR
768
159
919
204
%-recuperados-según-datos
calculo-tasa-recuperacion
2
1
11

MONITOR
592
480
689
525
%-susceptibles
porcentaje-susceptibles
2
1
11

BUTTON
792
212
919
245
NIL
exportar-interfaz
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
594
279
652
324
Tasa R0
r0
2
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
