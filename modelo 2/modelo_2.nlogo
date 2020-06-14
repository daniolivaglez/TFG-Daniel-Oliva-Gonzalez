globals
[
  casos                                            ;; número de casos confirmados en la enfermedad
  recuperados                                      ;; número de individuos recuperados de la enfermedad
  muertos                                          ;; número de individuos que no pasan la enfermedad
  vacunados                                        ;; número de personas vacunadas en la simulación
  porcentaje-infectados                            ;; porcentaje de infectados de la población en un instante
  porcentaje-curados                               ;; porcentaje de curados de la población en un instante
  porcentaje-muertos                               ;; porcentaje de muertos de la población en un instante
  porcentaje-vacunados                             ;; porcentaje de personas vacunadas de la enfermedad en un instante
  porcentaje-susceptibles                          ;; porcentaje de personas susceptibles de contraer la enfermedad
  calculo-tasa-recuperacion                        ;; número que indica el porcentaje de recuperación de la enfermedad según los datos introducidos
  calculo-tasa-letalidad                           ;; número que indica el porcentaje de letalidad de la enfermedad según los datos introducidos
  calculo-casos                                    ;; indica el número de casos según los datos introducidos
  calculo-recuperados                              ;; indica el número de recuperados según los datos introducidos
  calculo-muertos                                  ;; indica el número de muertos según los datos introducidos
  infectados-anterior                              ;; número de infectados en el instante anterior
  r0                                               ;; tasa r0
  mu                                               ;; tasa de nuevos recuperados por instante
  lambda                                           ;; tasa de nuevos infectados por instante
  bordery                                          ;; "frontera" en el eje y
  borderx                                          ;; "frontera" en el eje x
  angulo                                           ;; grado de giro en el movimiento del agente
]

turtles-own
[
  infectado?                                       ;; atributo que indica si el agente presenta la enfermedad
  curado?                                          ;; atributo que indica si el agente ha pasado la enfermedad
  susceptible?                                     ;; atributo que indica si el agente puede pasar la enfermedad
  muerto?                                          ;; atributo que indica si el agente ha muerto debido a la enfermedad
  vacunado?                                        ;; atributo que indica si el agente ha sido vacunado
  confinado?                                       ;; atributo que indica si el agente se encuentra confinado
  hospitalizado?                                   ;; atributo que indica si el agente está en el hospital
  patologias_previas?                              ;; atributo que indica si el agente presentaba patologías previas
  edad                                             ;; atributo que indica la edad del agente

  probabilidad-ser-confinado                       ;; probabilidad del agente a ser confinado
  tiempo_recup                                     ;; tiempo que tarda en recuperarse el agente de la enfermedad
  tiempo_infectado                                 ;; tiempo que lleva infectado el agente
  pais                                             ;; número del país del que proviene el agente
  pais_actual                                      ;; número del país en el que se encuentra el agente

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
  es_animal?                                        ;; indica si es un animal o no
]

;; ------------------------
;; | PROCEDIMIENTOS SETUP |
;; ------------------------

;; procedimiento para inicializar los agentes (humanos, fronteras y hospitales y los animales)
to setup
  clear-all                                        ;; se limpia la pantalla del modelo
  setup-people                                     ;; se muestran tantos individuos como se hayan introducido en el panel
  setup-patch-borders                              ;; se crean las fronteras y los hospitales
  setup-animales                                   ;; se crean los animales
  reset-ticks
end

;; procedimiento que se encarga de originar según el número de países las fronteras y los hospitales. En el caso de un país no habrá fronteras y solo existirá un hospital. En el
;; caso de dos países habrá una frontera y dos hospitales. En el caso de cuatro países habrá dos fronteras y cuatro hospitales.
;; las fronteras están pintadas en amarillo y los hospitales en rosa
to setup-patch-borders
  if numero-paises = 1
  [
    set bordery patches with [(abs(pxcor) >=  0 and abs (pycor) >= 0)]
    ask patch 0 0 [set pcolor pink]
  ]
  if numero-paises  = 2
  [
    ask patch (max-pxcor / 2 ) 0 [set pcolor pink]
    ask patch (- max-pxcor / 2 ) 0 [set pcolor pink]

    set bordery patches with [(pxcor =  0 and abs (pycor) >= 0)]
    ask bordery [set pcolor yellow]
  ]

  if numero-paises  = 4
  [
    ask patch (max-pxcor / 2 ) (- max-pycor / 2) [set pcolor pink]
    ask patch (- max-pxcor / 2 ) (- max-pycor / 2) [set pcolor pink]
    ask patch (max-pxcor / 2 ) ( max-pycor / 2) [set pcolor pink]
    ask patch (- max-pxcor / 2 ) ( max-pycor / 2) [set pcolor pink]

    set bordery patches with [(pxcor =  0 and abs (pycor) >= 0)]
    ask bordery [set pcolor yellow]
    set borderx patches with [(pycor =  0 and abs (pxcor) >= 0)]
    ask borderx [set pcolor yellow]
  ]
end


;; procedimiento para inicializar los agentes humanos
to setup-people
  create-turtles numero-personas
    [
      setxy random-xcor random-ycor                  ;; se le dan unas coordenadas (x,y) aleatorias

      ;; atributos
      set infectado? false
      set curado? false
      set muerto? false
      set vacunado? false
      set susceptible? true
      set confinado? false
      set hospitalizado? false

      set edad random 100                            ;; se genera una edad aleatoria

      set tiempo_recup random-float 2 * tiempo-recuperacion                              ;; se crea el tiempo de recuperación del agente
      set probabilidad-ser-confinado random-float 2 * %-confinamiento                    ;; se crea la probabilidad de cumplir el confinamiento del agente

      ;; según el porcentaje introducido de poseer patologías previas, el agente tendrá o no.
      ifelse random-float 100 < %-tener-patologias-previas
      [
        set patologias_previas? true
      ]
      [
        set patologias_previas? false
      ]

      set color white                                ;; se le asigna el color blanco puesto que no han sido curados, infectados o han muerto
      asignar-pais                                   ;; se asigna el país del agente según las coordenadas de inicio
      asignar-pais-actual                            ;; se asigna el país actual del agente
      set size 0.75                                  ;; tamaño del agente

      infeccion-inicial                              ;; se infecta un porcentaje inicial de la población
      cambia-color                                   ;; se colorea el agente según sus características

      set es_animal? false                           ;; al crearse los humanos, este atributo será false
      set tiene_mascarilla? false                   ;; al inicio nadie tiene mascarillas

    ]
end

;; procedimiento para inicializar los agentes animales
to setup-animales
  create-turtles numero-animales
    [
      setxy random-xcor random-ycor                  ;; se le dan unas coordenadas (x,y) aleatorias

      set infectado? false
      set curado? false
      set muerto? false
      set vacunado? false
      set susceptible? true
      set confinado? false
      set hospitalizado? false
      set patologias_previas? false

      set tiempo_recup random-float 2 * tiempo-recuperacion   ;; se crea el tiempo de recuperación del agente
      set probabilidad-ser-confinado 0                        ;; un animal no va a ser confinado, por lo que su probabilidad es 0

      set color white                                ;; se le asigna el color blanco puesto que no han sido curados, infectados o han muerto
      asignar-pais                                   ;; se le asigna un país al animal según las coordenadas
      asignar-pais-actual                            ;; se asigna el país actual del agente

      set es_animal? true                            ;; al ser un animal se añade un atributo que lo especifica
      set shape "turtle"                             ;; se le da forma de tortuga al animal para hacer mejor la distinción
      set size 1                                     ;; tamaño de los animales
     ]
end

;; permite generar un archivo imagen de la interfaz. Se recomienda usar la extensión de archivo .png
to exportar-interfaz                               ;; permite exportar una imagen de la interfaz entera en un momento cualquier
  let file user-new-file                           ;; se le permite al usuario crear un archivo donde guardar la imagen
  export-interface file                            ;; se guarda la imagen actual de la interfaz en el archivo seleccionado
end

;; procedimiento para cargar los datos en un fichero .txt que incluya nºcasos, nºrecuperados y nºmuertos, ej: 2887 2331 556
to cargar-datos-letalidad-contagios
 let file user-file                               ;; el usuario elige el archivo que quiera leer

  if ( file != false )                             ;; el botón no funcionará en el caso de no haberse escogido ningún archivo
  [
    file-open file                                 ;; se abre el archivo
    set calculo-casos file-read                    ;; se asigna el nºcasos a la variable casos
    set calculo-recuperados file-read              ;; se asigna el nºrecuperados a la variable recuperados
    set calculo-muertos file-read                  ;; se asigna el nºmuertos a la variable muertos
    user-message "¡Archivo leído con éxito!"       ;; se muestra un mensaje donde se indica el éxito en leer los datos
    file-close                                     ;; se cierra el archivo
  ]
end

;; procedimiento que calcula la letalidad de los datos introducidos y se muestra en el monitor correspondiente, así como la tasa de recuperación
to mostrar-letalidad-y-tasa-recuperacion
  set calculo-tasa-letalidad calculo-muertos / calculo-casos * 100
  set calculo-tasa-recuperacion calculo-recuperados / calculo-casos * 100
end

;; -----------------------------------------------------
;; | PROCEDIMIENTOS PARA LAS AGENTES Y SUS MOVIMIENTOS |
;; -----------------------------------------------------

;; este procedimiento le da a los agentes un país según las coordenadas de éste y el número de países seleccionados
;; además, si hay más de un país se les da una forma diferente para que sean reconocibles el país de inicio
to asignar-pais
  if numero-paises = 1
  [
    set pais 1
    set shape "circle"
  ]

  if numero-paises = 2
  [
    if xcor <= 0
    [
      set pais 1
      set shape "x"
    ]
    if xcor >= 0
    [
      set pais 2
      set shape "square"
    ]
  ]

  if numero-paises = 4
  [
    if xcor >= 0 and ycor >= 0
    [
      set pais 1
      set shape "x"
    ]
    if xcor <= 0 and ycor >= 0
    [
      set pais 2
      set shape "square"
    ]
    if xcor <= 0 and ycor <= 0
    [
      set pais 3
      set shape "triangle"
    ]
    if xcor >= 0  and ycor <= 0
    [
      set pais 4
      set shape "circle"
    ]
  ]
end

;; este procedimiento actualiza el país en el que se encuentra el agente un instante concreto
to asignar-pais-actual
  if numero-paises = 1
  [
    set pais_actual 1
  ]

  if numero-paises = 2
  [
    if xcor <= 0
    [
      set pais_actual 1
    ]
    if xcor >= 0
    [
      set pais_actual 2
    ]
  ]

  if numero-paises = 4
  [
    if xcor >= 0 and ycor >= 0
    [
      set pais_actual 1
    ]
    if xcor <= 0 and ycor >= 0
    [
      set pais_actual 2
    ]
    if xcor <= 0 and ycor <= 0
    [
      set pais_actual 3
    ]
    if xcor >= 0  and ycor <= 0
    [
      set pais_actual 4
    ]
  ]
end

;; procedimiento para simular el movimiento de los agentes
to go
  ;; en el caso de no haber ningún agente infectado se para la simulación
  if all? turtles [not infectado?]
  [
    stop
  ]
  ;; si un agente humano no está confinado ni hospitalizado podrá confinarse o se moverá, además de poder conseguir mascarilla y vacuna
  ask turtles with [susceptible? and not confinado? and not es_animal? and not hospitalizado?]
  [
    ifelse random-float 100 < probabilidad-ser-confinado
    [
      confinar
    ]
    [
      mover
      poder-conseguir-mascarillas
      poder-vacunarse
    ]
  ]
  ;; un agente humano que haya sido curado y no esté confinado podrá moverse con libertad
  ask turtles with [curado? and not confinado?]
  [
    mover
  ]
  ;; por el contrario, un agente animal solo podrá moverse
  ask turtles with [es_animal?]
  [
    mover
  ]
  ;; un agente vacunado se podrá mover libremente
  ask turtles with [vacunado?]
  [
    mover
  ]
    ;; un agente humano infectado y sin estar confinado ni en un hospital podrá contagiar a los agentes de sus alrededores. Un humano puede infectar a otro humano o a un animal, pero no podrá ser infectado
  ;; por un animal
  ask turtles with [infectado? and not confinado? and not es_animal? and not hospitalizado?]
  [
    infectar
  ]
  ;; un agente humano infectado y sin estar confinado ni en un hospital, tendrá una probabilidad de cumplir su confinamiento. Además también
  ;; podrá recuperarse o fallecer
  ask turtles with [not confinado? and infectado? and not es_animal? and not hospitalizado?]
  [
    if random-float 100 < probabilidad-ser-confinado
    [
      confinar
    ]
    poder-recuperarse
    poder-fallecer
  ]
  ;; un agente humano infectado que no esté confinado ni hospitalizado podrá ser hospitalizado. Al hospitalizarse se activa el confinamiento al permanecer en el hospital
  ask turtles with [not confinado? and infectado? and not es_animal? and not hospitalizado?]
  [
    if random-float 100 < tendencia-ir-hospital
    [
      hospitalizar
      set confinado? true
    ]
  ]
  ;; un agente humano infectado y hospitalizado podrá recuperarse o fallecer
  ask turtles with [hospitalizado? and not es_animal? and infectado?]
  [
    poder-recuperarse
    poder-fallecer
  ]
  ;; un agente animal infectado podrá recuperarse o fallecer. Se añade no confinado aunque a priori no debería haber ningún animal confinado
  ask turtles with [not confinado? and infectado? and es_animal?]
  [
    poder-recuperarse
    poder-fallecer
  ]
  ;; un agente humano infectado y confinado podrá recuperarse o fallecer
  ask turtles with [confinado? and infectado? and not es_animal?]
  [
    poder-recuperarse
    poder-fallecer
  ]
  ;; si un agente se vacuna estando confinado, dará por acabado su confinamiento
  ask turtles with [vacunado? and confinado?]
  [
    set confinado? false
    move-to patch-here
    ask (patch-at 0 0) [ set pcolor black ]
    setup-patch-borders
  ]
  ;; un agente humano curado y hospitalizado abandonará el hospital
  ask turtles with [curado? and hospitalizado? and not es_animal?]
  [
    set confinado? false
    set hospitalizado? false
    move-to patch-here
    ask (patch-at 0 0) [ set pcolor black ]
    setup-patch-borders
  ]
  ;; un agente humano curado y confinado dejará de estar confinado
  ask turtles with [curado? and confinado? and not es_animal?]
  [
    set confinado? false
    move-to patch-here
    ask (patch-at 0 0) [ set pcolor black ]
    setup-patch-borders
  ]
  ;; se cambia el color de las tortugas según sus atributos, así como calcular la tasa r0 y los porcentajes de infectados, curados, fallecidos, vacunados y susceptibles
  ask turtles
  [
    cambia-color
    tasa-r0
    asignar-pais-actual
    set porcentaje-infectados (count turtles with [infectado? and not es_animal?] / numero-personas * 100)
    set porcentaje-curados (count turtles with [curado? and not es_animal?] / numero-personas * 100)
    set porcentaje-muertos ((muertos) / numero-personas * 100)
    set porcentaje-vacunados ((vacunados) / numero-personas * 100)
    set porcentaje-susceptibles 100 - porcentaje-infectados - porcentaje-curados - porcentaje-muertos - porcentaje-vacunados
  ]
 tick
end

;; procedimiento para el movimiento de los agentes. Si solo hay un país no existe ninguna restricción de movimiento. Si hay dos países, cuando se acercan a la frontera algunos volverán a su país
;; mientras que otros cruzarán la frontera. En el caso de cuatro países ocurre lo mismo que en el de dos solo que con dos fronteras
;; en el caso de haber más de un país, se podrá activar la posibilidad de viajar de un país a otro de forma aleatoria
;; se comprueba el país actual en el que se encuentra un agente y si se encuentra cerca de la frontera se pretende cambiar su posición
;; como es un mapa continuo, es decir, si avanza hacia la derecha, aparecerá en la izquierda, cuando se acerque a estos límites, se cambiará su dirección
to mover
  if numero-paises = 1
  [
    fd 0.5
  ]
  if numero-paises = 2
  [
    ;; si está activado el interruptor de viajar y el número generado es menor que la tendencia, el agente humano cambiará sus coordenadas. No pueden viajar los animales
    if viajar? and random-float 100 < tendencia-viajar and not es_animal?
    [
      setxy random-xcor random-ycor
      asignar-pais-actual
    ]
    if pais_actual = 1
    [
      ifelse xcor > (- 0.5)
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo (-1)
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor < (min-pxcor + 1) or ycor > (max-pycor - 1) or ycor < (min-pycor + 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        rt angulo
      ]
      fd 0.5

    ]
    if pais_actual = 2
    [
      ifelse xcor < 0.5
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo (1)
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor > (max-pxcor - 1) or ycor > (max-pycor - 1) or ycor < (min-pycor + 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        lt angulo
      ]
      fd 0.5
    ]
  ]
  if numero-paises = 4
  [
    ;; si está activado el interruptor de viajar y el número generado es menor que la tendencia, el agente humano cambiará sus coordenadas. No pueden viajar los animales
    if viajar? and random-float 100 < tendencia-viajar and not es_animal?
    [
      setxy random-xcor random-ycor
      asignar-pais-actual
    ]
    if pais_actual = 1
    [
      ifelse xcor < 0.5 or ycor < 0.5
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo (1)
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor > (max-pxcor - 1) or ycor > (max-pycor - 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        rt angulo
      ]
      fd 0.5
    ]

   if pais_actual = 2
    [
      ifelse xcor > (- 0.5) or ycor < 0.5
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo (1)
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor < (min-pxcor + 1) or ycor > (max-pycor - 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        rt angulo
      ]
      fd 0.5
    ]
    if pais_actual = 3
    [
      ifelse xcor > (- 0.5) or ycor > (- 0.5)
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo (1)
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor < (min-pxcor + 1) or ycor < (min-pycor + 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        rt angulo
      ]
      fd 0.5
    ]
    if pais_actual = 4
    [
      ifelse xcor < 0.5 or ycor > (- 0.5)
      [
        set angulo random-float 180
        let nueva_posicion patch-at-heading-and-distance angulo 1
        if nueva_posicion != nobody
        [
          move-to nueva_posicion
        ]
      ]
      [
        ifelse xcor > (max-pxcor - 1) or ycor < (min-pycor + 1)
        [
          set angulo random-float 180
        ]
        [
          set angulo random-float 360
        ]
        rt angulo
      ]
      fd 0.5
    ]
  ]
end

;; procedimiento para realizar el confinamiento de un agente humano, quedándose quieto donde se encuentra una vez es activado
to confinar
  set confinado? true
  move-to patch-here
  ask (patch-at 0 0) [ set pcolor gray - 3 ]
end

;; procedimiento que puede provocar la muerte del agente si ya ha pasado el tiempo de recuperación
;; si presenta patologías previas, el individuo presenta un 10% de probabilidad más fallecer
;; si además de presentar patología previas y ser mayor de 60 años, presenta un 15% adicional de fallecer
to poder-fallecer
  if tiempo_infectado > tiempo_recup
  [
    ;; si tiene patologías...
    if patologias_previas?
    [
      if random-float 100 < %-probabilidad-muerte + 10
      [
        set infectado? false
        set muerto? true
        ;; no se cuenta el número de animales en los muertos
        if not es_animal?
        [
          set muertos (muertos + 1)
        ]
        ;; si muere mientras está confinado, se elimina el lugar de confinamiento
        if muerto? and confinado?
        [
          set confinado? false
          move-to patch-here
          ask (patch-at 0 0) [ set pcolor black ]
          setup-patch-borders
        ]
        ;; por último, si fallece, se elimina el agente
        die
      ]
    ]
    ;; si tiene más de 60 años y patologías previas...
    if edad > 60 and patologias_previas?
    [
      if random-float 100 < %-probabilidad-muerte + 15
      [
        set infectado? false
        set muerto? true
        ;; no se cuenta el número de animales en los muertos
        if not es_animal?
        [
          set muertos (muertos + 1)
        ]
        if muerto? and confinado?
        [
          set confinado? false
          move-to patch-here
          ask (patch-at 0 0) [ set pcolor black ]
          setup-patch-borders
        ]
        die
      ]
    ]
    ;; si no cumple las condiciones anteriores...
    if random-float 100 < %-probabilidad-muerte
    [
      set infectado? false
      set muerto? true
      ;; no se cuenta el número de animales en los muertos
      if not es_animal?
      [
        set muertos (muertos + 1)
      ]
      if muerto? and confinado?
      [
        set confinado? false
        move-to patch-here
        ask (patch-at 0 0) [ set pcolor black ]
        setup-patch-borders
      ]
      die
    ]
  ]
end

;; procedimiento para la obtención de una mascarilla y disminuir la posibilidad de contagio del agente
to poder-conseguir-mascarillas
  if susceptible?
  [
    if random-float 100 < %-conseguir-mascarilla
    [
      set tiene_mascarilla? true
    ]
  ]
end

;; procedimiento para la posibilidad de un agente humano de poder vacunarse y esta vacuna sea efectiva. Estos dos parámetros se incluyen por pantalla
to poder-vacunarse
  if susceptible? and infectado? != true and curado? != true
  [
    if random-float 100 < %-ser-vacunado
    [
      if random-float 100 < %-efectividad-vacuna
      [
        set vacunado? true
        set susceptible? false
        set color blue
        set vacunados (vacunados + 1)
      ]
    ]
  ]
end


;; este procedimiento permite infectar a los agentes cercanos a aquellos que se encuentran infectados
;; si el agente cercano presenta una mascarilla, la probabilidad de contagio disminuye
;; además cuenta el número de casos y le asigna unos síntomas, siempre y cuando no sea un animal
to infectar
  let no-infectados-cercanos (turtles-on neighbors) with [not infectado? and not curado? and not muerto? and not vacunado? and susceptible?]
  if no-infectados-cercanos != nobody
  [
    ask no-infectados-cercanos
    [
      if tiene_mascarilla? != false
      [
        if random-float 100 < (%-probabilidad-contagio - %-proteccion-mascarilla)
        [
          set infectado? true
          if not es_animal?
          [
            set casos (casos + 1)
            crear-sintomas
          ]
        ]
      ]
      if random-float 100 < %-probabilidad-contagio
        [
          set infectado? true
          if not es_animal?
          [
            set casos (casos + 1)
            crear-sintomas
          ]
        ]
    ]
  ]
end

;; este procedimiento otorga al agente una oportunidad de recuperarse si el tiempo de infección supera el tiempo de recuperación del individuo
;; si está hospitalizado, el tiempo de recuperación se reduce a la mitad
to poder-recuperarse
  set tiempo_infectado (tiempo_infectado + 1)
  ifelse not hospitalizado?
  [
    if tiempo_infectado > tiempo_recup
    [
      if random-float 100 < %-probabilidad-recuperacion
      [
        set infectado? false
        set curado? true
        set recuperados (recuperados + 1)
      ]
    ]
  ]
  [
    if tiempo_infectado > (tiempo_recup / 2)
    [
      if random-float 100 < %-probabilidad-recuperacion
      [
        set infectado? false
        set curado? true
        set recuperados (recuperados + 1)
      ]
    ]
  ]
end

;; procedimiento para ingresar en un hospital según el país en el que se encuentre el agente
to hospitalizar
  set hospitalizado? true
  set pcolor black
  if numero-paises = 1
  [
    move-to patch 0 0
  ]
  if numero-paises = 2
  [
    if pais_actual = 1
    [
      move-to patch (max-pxcor / 2 ) 0
    ]
    if pais_actual = 2
    [
      move-to patch (- max-pxcor / 2 ) 0
    ]
  ]
  if numero-paises = 4
  [
    if pais_actual = 1
    [
      move-to patch (max-pxcor / 2 ) (max-pycor / 2)
    ]
    if pais_actual = 2
    [
      move-to patch (- max-pxcor / 2 ) (max-pycor / 2)
    ]
    if pais_actual = 3
    [
      move-to patch (- max-pxcor / 2 ) (- max-pycor / 2)
    ]
    if pais_actual = 4
    [
      move-to patch (max-pxcor / 2 ) (- max-pycor / 2)
    ]
  ]
  set pcolor white
end

;; este procedimiento infecta a un porcentaje de la población inicial. Tanto el número de agentes inicial como el porcentaje de infeccion inicial son introducidos por pantalla
;; además se crean los síntomas de los agentes humanos
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
  if infectado? != false
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

  let susceptibles-actual numero-personas - count turtles with [infectado?] - count turtles with [curado?] - muertos

  let susceptibles-inicial count turtles with [susceptible?]

  ;; si el número de infectados en el día anterior es menor que 5, se considerará nulo
  ifelse infectados-anterior < 5
  [set lambda 0]
  ;; por el contrario, se actualizará la tasa de nuevos infectados
  [set lambda (nuevos-infectados / infectados-anterior)]

  ;; si el número de infectados en el día anterior es menor que 5, se considerará nulo
  ifelse infectados-anterior < 5
  [set mu 0]
  ;; por el contrario se actualizará la tasa de nuevos recuperados
  [set mu (nuevos-recuperados / infectados-anterior)]

  ;; (numero-personas - susceptibles-actual) tiene que ser mayor que 0 para no causar problemas con el logaritmo, así como susceptibles-actual
  if numero-personas - susceptibles-actual > 0 and susceptibles-actual > 0
  [
    set r0 (ln (susceptibles-inicial / susceptibles-actual) / (numero-personas - susceptibles-actual))
    set r0 r0 * susceptibles-inicial
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
974
10
1504
541
-1
-1
15.82
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
29
12
90
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
150.0
1
0
Number

SLIDER
651
208
955
241
tiempo-recuperacion
tiempo-recuperacion
0
80
40.0
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
15.0
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
10.0
1
0
Number

INPUTBOX
156
129
286
189
%-proteccion-mascarilla
10.0
1
0
Number

INPUTBOX
522
482
654
542
%-probabilidad-contagio
60.0
1
0
Number

INPUTBOX
665
482
820
542
%-probabilidad-recuperacion
64.81
1
0
Number

PLOT
7
257
501
553
Número Infectados, Curados y Muertos
NIL
NIL
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Infectados" 1.0 0 -2674135 true "" "plot count turtles with [infectado? and not es_animal?]"
"Curados" 1.0 0 -13840069 true "" "plot count turtles with [curado? and not es_animal?]"
"Muertos" 1.0 0 -16777216 true "" "plot muertos"
"Susceptibles" 1.0 0 -2064490 true "" "plot numero-personas - muertos - vacunados - count turtles with [curado? and not es_animal?] - count turtles with [infectado? and not es_animal?]"
"Vacunados" 1.0 0 -13345367 true "" "plot vacunados"

MONITOR
76
202
152
247
%-infectados
porcentaje-infectados
2
1
11

MONITOR
231
202
297
247
%-curados
porcentaje-curados
2
1
11

INPUTBOX
832
482
952
542
%-probabilidad-muerte
11.97
1
0
Number

MONITOR
157
203
225
248
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

BUTTON
203
16
330
49
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
12
201
70
246
Tasa R0
r0
2
1
11

INPUTBOX
656
339
750
399
%-ser-vacunado
10.0
1
0
Number

INPUTBOX
521
338
641
398
%-efectividad-vacuna
2.0
1
0
Number

MONITOR
307
203
388
248
%-vacunados
porcentaje-vacunados
2
1
11

MONITOR
404
205
488
250
%-susceptibles
porcentaje-susceptibles
2
1
11

INPUTBOX
773
339
889
399
%-confinamiento
1.0
1
0
Number

INPUTBOX
675
409
773
469
numero-animales
5.0
1
0
Number

INPUTBOX
520
409
662
469
%-tener-patologias-previas
15.0
1
0
Number

CHOOSER
505
207
643
252
numero-paises
numero-paises
1 2 4
0

SWITCH
527
290
630
323
viajar?
viajar?
0
1
-1000

SLIDER
647
288
952
321
tendencia-viajar
tendencia-viajar
0
15
8.0
0.2
1
NIL
HORIZONTAL

SLIDER
648
247
952
280
tendencia-ir-hospital
tendencia-ir-hospital
0
15
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
# Modelo 2

## ¿Cómo funciona?

Este modelo trata de simular una epidemia (centrándose en la de COVID19 al incluir los síntomas de dicha enfermedad, aunque si bien podrían simularse diferentes enfermedades cambiando ciertos parámetros) de una forma más compleja. Además de incluir los parámetros del modelo 1, se puede escoger entre un, dos y cuatros países de tal forma que se genere una frontera por cada dos países y un hospital por cada país. Al añadirse hospitales, se incluye la tendencia de los agentes a ir al hospital. También se incluyen las vacunas con un porcentaje de conseguirla y otro porcentaje de efectividad de la vacuna. Además se incluyen animales, que no pueden infectar a los humanos pero sí pueden ser infectados por ellos. Otros parámetros incluidos son el porcentaje de cumplir el confinamiento y de presentar patologías previas, lo que influye a la hora de la probabilidad de fallecer del agente humano. A los humanos se les añade la edad. Por último, otro parámetro importante añadido es el interruptor de viajar y la tendencia a viajar. 

## ¿Cómo usarlo?

Para usarlo, lo primero que se debe hacer es abrir el archivo "covid19_españa_20_05.txt" o el archivo "covid19_españa_20_05.txt" usando cargar-datos-letalidad-contagios. Pulsando mostrar-letalidad-y-tasa-recuperación se muestra la tasa de letalidad y de recuperación según los datos introducidos, que puede ser de ayuda para la simulación (completar entradas de %-probabilidad-recuperacion y %-probabilidad-muerte). También quedaría por añadir el %-probabilidad-contagio.
Para empezar se rellena las entradas numero-personas y %-infeccion-inicial. También se completan los procentajes referidos a las mascarillas. 
El siguiente paso sería establecer los porcentajes de los síntomas. Éstos serán los sacados del análisis de datos de los pacientes.
A continuación, se escogerá el número de países que se querrán implementar. Si se escoge un país se recomienda no activar la opción de viajar.
También ha de establecerse el tiempo-recuperacion, la tendencia-ir-hospital, los parámetros referidos a las vacunas con la probabilidad %-ser-vacunado y la probabilidad %-efectividad-vacuna y la probabilidad %-confinamiento.
Por último, se completa la probabilidad de tener patologías previas y el número de animales de la simulación. 
Finalmente, se pulsa el botón setup para establecer la simulación y se pulsa el botón go para que comience la simulación.

## Pruebas a realizar

Se sugiere escoger el número de personas (unas 100) en función de los países escogidos. Además, variar la activación del interruptor viaje o no, así como las diferentes probabilidades.

## Futuras mejoras

Algunas posibles mejoras a añadir son:
-	Inclusión de más de una enfermedad a la simulación, con tal de conseguir un mayor realismo.
-	Inclusión de estaciones del año. Las enfermedades no se expanden igual en invierno que en verano. Normalmente, los virus suelen morir con el calor, por lo que podría ser un factor determinante en su expansión.
-	Inclusión de diferentes sitios de reunión de agentes humanos, tales como supermercados.
-	Inclusión de ambulancias para aumentar la tendencia de los agentes humanos a ir al hospital.
-	Otra mejora podría ser el establecimiento de un número máximo de personas por hospital, con el fin de convertirlo en más realista.
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
