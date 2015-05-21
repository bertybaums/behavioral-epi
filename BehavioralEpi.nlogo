

extensions [matrix]

breed [ flies fly]

globals [
 inf-opts-matrix ;; infection opportunities, columns names: A, B, AB, NI (Note: index starts with 0)
 A-infection-rates
 ;B-infection-rates
 ;co-infection-rates
 ;infection-rates
 ;infection-time-checks
 ;coinf10 coinf20 coinf30 coinf40 coinf50 coinf60 coinf70 
 ;ainf10 ainf20 ainf30 ainf40 ainf50 ainf60 ainf70
 ;binf10 binf20 binf30 binf40 binf50 binf60 binf70
 infs-by-A-flies
 ;infs-by-B-flies
 ;infs-by-AB-flies
 infs-by-A-cont
 ;infs-by-B-cont
 ;infs-by-AB-cont
 global-pinf ; probability of getting infect given any behavior
 global-pinfb1 ; probabilty of getting infected given beahvior 1
 global-pinfb2 ; probabilty of getting infected given beahvior 1
]

turtles-own [
 obsb1
 obsb2
 obs
 pinfb1 ; estimated probability of getting infected given behavior 1
 pinfb2 ; estimated probability of getting infected given behavior 2
 p-type ; personality type. Options are 1 or 2
 behave
 A-infection?
 new-A-infection?
 B-infection? 
 new-B-infection?
 A-immune?
 B-immune?
 my-move-angle
 my-move-size
 A-recov
 B-recov
 counting
]

patches-own [
 A-cont
 B-cont 
]

to setup
  clear-all
  ;set infection-time-checks [ 10 20 30 40 50 60 70 80 90 100]
  create-flies N [
    ifelse random 2 = 1 [set p-type 1][set p-type 2]
    ifelse random 2 = 1 [set behave 1][set behave 2]
    set obsb1 [] set obsb2 [] set obs []
    repeat memory [
      set obsb1 lput 0 obsb1
      set obsb2 lput 0 obsb2
      set obs lput 0 obs
    ]
;    set pinfb1 ((count other turtles in-radius learn-radius with [A-infection? = true and behave = 1] ) / (count other turtles in-radius learn-radius ) )
 ;   set pinfb2 ((count other turtles in-radius learn-radius with [A-infection? = true and behave = 2] ) / (count other turtles in-radius learn-radius ) )
    set color black
    set shape "butterfly"
    setxy random-xcor random-ycor
    set A-infection? false
    set new-A-infection? false
    set B-infection? false
    set new-B-infection? false
    set A-recov 0
    set B-recov 0
    set A-immune? false
    set B-immune? false
    set my-move-angle move-angle
    set my-move-size move-size
    set counting 0
  ]
  initial-infections
  initial-statistics
  set inf-opts-matrix matrix:from-row-list [ [0 0 0 0] [0 0 0 0] [0 0 0 0] [0 0 0 0] ]
  ask patches [
    set pcolor 8
    if pxcor mod 2 = 1 and pycor mod 2 = 0 [set pcolor 9.9] if pxcor mod 2 = 0 and pycor mod 2 = 1 [set pcolor 9.9]] 
  ask patches [ 
    set A-cont 0
    set B-cont 0 ]
  ask turtles [ set pen-mode "up"]  
  reset-ticks
end


to go
  infection-transmission
  ask turtles [
    ;we calculate the local conditional probabilities of getting infected given behavior types
    let ob1 (count other turtles in-radius learn-radius with [A-infection? = true and behave = 1])
    let ob2 (count other turtles in-radius learn-radius with [A-infection? = true and behave = 2])
    ifelse ob1 = 0 [set obsb1 replace-item (ticks mod memory) obsb1 0] [set obsb1 replace-item (ticks mod memory) obsb1 ( ob1 / (count other turtles in-radius learn-radius with [A-immune? = false and behave = 1]))]
    ifelse ob2 = 0 [set obsb2 replace-item (ticks mod memory) obsb2 0] [set obsb2 replace-item (ticks mod memory) obsb2 ( ob2 / (count other turtles in-radius learn-radius with [A-immune? = false and behave = 2]))]
    ;set obs replace-item (ticks mod memory) obs count other turtles in-radius learn-radius
    ;set pinfb1 ((count other turtles in-radius learn-radius with [A-infection? = true and behave = 1] ) / (count other turtles in-radius learn-radius + 1) )
    ;set pinfb2 ((count other turtles in-radius learn-radius with [A-infection? = true and behave = 2] ) / (count other turtles in-radius learn-radius + 1 ) )
  ]
  calc-globals 
  ;if empty? infection-time-checks [ 
   ; final-stats
    ; ;stop 
    ;]
  recovery
  ask flies [ move ]
  if personalities? [update-behaviors]
  statistics
  update-plots
  tick-advance 1
end

to calc-globals
  set global-pinf (count turtles with [A-infection? = true] / ((count turtles) - (count turtles with [A-immune? = true])))
  let imb1 (count turtles with [A-immune? = false and behave = 1])
  let imb2 (count turtles with [A-immune? = false and behave = 2])
  ifelse imb1 = 0 [set global-pinfb1 0][ set global-pinfb1 ( (count turtles with [A-infection? = true and behave = 1]) / imb1 )]
  ifelse imb2 = 0 [set global-pinfb2 0][ set global-pinfb2 ( (count turtles with [A-infection? = true and behave = 2]) / imb2 )]
end

to recovery
  ask flies [
    if (random-float 1) < A-recovery [if A-infection? = true [set A-immune? true
        set A-infection? false]]
    update-color
  ]

end

to get-A-infection
  set A-infection? true
  set new-A-infection? false
  set A-recov 1
  update-color
  update-move-angle
end

to get-B-infection
  set B-infection? true
  set new-B-infection? false
  set B-recov 1
  update-color
  update-move-angle
end

to infection-transmission
  ask flies with [A-infection? = false and A-immune? = false] [
   let get-new-A-infection? false
   let get-new-B-infection? false
   let locN count other turtles in-radius infection-radius
   let I count other turtles in-radius infection-radius with [A-infection? = true]
   let locFI 0
   if locN != 0 [set locFI I / locN] 
   ;let Ib1 other turtles in-radius infection-radius with [A-infection? = true and behave = 1]
   ;let Ib2 other turtles in-radius infection-radius with [A-infection? = true and behave = 2]
   if ( random-float 1 < (A-inf-prob-given-b behave * locFI) ) [
     set new-A-infection? true
     set infs-by-A-flies infs-by-A-flies + 1
   ]   
   if pcolor = red [
     if random-float 1 < A-cont [set get-new-A-infection? true set infs-by-A-cont infs-by-A-cont + 1]]
   if get-new-A-infection? = true [ set new-A-infection? true ]
   if get-new-B-infection? = true [ set new-B-infection? true ]
  ]
  ask flies with [new-A-infection?] [ get-A-infection]
  ;ask flies with [new-B-infection?] [ get-B-infection] 
end

to update-behaviors
  ask turtles with [color = black] [ ;black turtles are the susceptibles
   if EU p-type 1 > EU p-type 2 [set behave 1]
   if EU p-type 1 < EU p-type 2 [set behave 2]
   if EU p-type 1 = EU p-type 2 [set behave behave]
  ]
end

to-report EU [t b]
  let pb1 mean obsb1
  let pb2 mean obsb2
  let pb1a (pb1 + ((1 - pb1) * amp-local))
  let pb2a (pb2 + ((1 - pb2) * amp-local))
  ;if t = 1 and b = 1 [report (((1 - local-over-global) * global-pinfb1)) ]
  ;if t = 1 and b = 2 [report (((1 - local-over-global) * global-pinfb2)) ]
  ;if t = 2 and b = 1 [report (((1 - local-over-global) * global-pinfb1)) ]
  ;if t = 2 and b = 2 [report (((1 - local-over-global) * global-pinfb2)) ]
  if t = 1 and b = 1 [report ((local-over-global) * ((pb1a * x1) + ((1 - pb1a) * y1))) + ((1 - local-over-global) * (global-pinfb1 + ((1 - global-pinfb1) * amp-global))) ]
  if t = 1 and b = 2 [report ((local-over-global) * ((pb2a * z1) + ((1 - pb2a) * w1))) + ((1 - local-over-global) * (global-pinfb2 + ((1 - global-pinfb2) * amp-global))) ]
  if t = 2 and b = 1 [report ((local-over-global) * ((pb1a * x2) + ((1 - pb1a) * y2))) + ((1 - local-over-global) * (global-pinfb1 + ((1 - global-pinfb1) * amp-global))) ]
  if t = 2 and b = 2 [report ((local-over-global) * ((pb2a * z2) + ((1 - pb2a) * w2))) + ((1 - local-over-global) * (global-pinfb2 + ((1 - global-pinfb2) * amp-global))) ]
end

to-report A-inf-prob-given-b [beh]
  if beh = 1 [report A-inf-prob-b1]
  if beh = 2 [report A-inf-prob-b2]
end

to initial-infections
  ask n-of A-infections flies [ get-A-infection ]
end

to update-color
  if (A-infection? = true) and (B-infection? = true) [ set color green ]
  if A-infection? = true and B-infection? = false [set color red]
  if B-infection? = true and A-infection? = false [set color blue]
  if A-infection? = false and B-infection? = false and A-immune? = false and B-immune? = false [set color black]
  if A-infection? = false and B-infection? = false and (A-immune? = true or B-immune? = true) [set color gray]
end

to update-move-angle
  if infection-behaviour = true [
    if color = red [
      set my-move-angle A-move-angle
      set my-move-size A-move-size]
  ]
end

to move
    right (random-float 2 * my-move-angle ) - my-move-angle
    fd my-move-size
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;STATISTICS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to initial-statistics
  ;set infection-rates [ ]
  ;set co-infection-rates [ ]
  set A-infection-rates [ ]
  ;set B-infection-rates [ ]
end

to statistics
  set A-infection-rates lput count turtles with [color = red] A-infection-rates
  ;measure-infection-rates
end

;to measure-infection-rates
;  if not empty? infection-time-checks [
;    if ( ( (N - count turtles with [color = black])/ N) >= (first infection-time-checks / 100)) [
;      set infection-rates lput ticks infection-rates
;      set A-infection-rates lput count turtles with [color = red] A-infection-rates
;      set B-infection-rates lput count turtles with [color = blue] B-infection-rates
;      set co-infection-rates lput count turtles with [color = green] co-infection-rates
;      set infection-time-checks remove-item 0 infection-time-checks
;    ]
;  ]
;end

;to final-stats
;  set coinf10 item 0 co-infection-rates
;  set coinf20 item 1 co-infection-rates
;  set coinf30 item 2 co-infection-rates
;  set coinf40 item 3 co-infection-rates 
;  set coinf50 item 4 co-infection-rates
;  set coinf60 item 5 co-infection-rates
;  set coinf70 item 6 co-infection-rates
;  set ainf10 item 0 A-infection-rates
;  set ainf20 item 1 A-infection-rates
;  set ainf30 item 2 A-infection-rates
;  set ainf40 item 3 A-infection-rates 
;  set ainf50 item 4 A-infection-rates
;  set ainf60 item 5 A-infection-rates
;  set ainf70 item 6 A-infection-rates
;  set binf10 item 0 B-infection-rates
;  set binf20 item 1 B-infection-rates
;  set binf30 item 2 B-infection-rates
;  set binf40 item 3 B-infection-rates 
;  set binf50 item 4 B-infection-rates
;  set binf60 item 5 B-infection-rates
;  set binf70 item 6 B-infection-rates
;end


;to-report co-infection-time
 ; report ticks
;end
@#$#@#$#@
GRAPHICS-WINDOW
853
26
1173
367
15
15
10.0
1
10
1
1
1
0
1
1
1
-15
15
-15
15
0
0
1
ticks
30.0

SLIDER
21
692
193
725
move-angle
move-angle
0
360
45
1
1
NIL
HORIZONTAL

SLIDER
22
742
194
775
move-size
move-size
0
3
1
.25
1
NIL
HORIZONTAL

SLIDER
9
68
181
101
N
N
0
10000
850
50
1
NIL
HORIZONTAL

BUTTON
93
19
159
52
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
176
20
239
53
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
152
182
185
infection-radius
infection-radius
0
2
0.5
.05
1
NIL
HORIZONTAL

SLIDER
10
192
182
225
A-inf-prob-b1
A-inf-prob-b1
0
.5
0.2
.01
1
NIL
HORIZONTAL

SLIDER
10
104
182
137
A-infections
A-infections
0
N
10
1
1
NIL
HORIZONTAL

PLOT
408
24
838
214
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A-infections only" 1.0 0 -2674135 true "" "plot count turtles with [color = red]"
"non-infected" 1.0 0 -16777216 true "" "plot count turtles with [color = black]"
"Ab1" 1.0 0 -13345367 true "" "plot count turtles with [color = black and behave = 1]"
"Ab2" 1.0 0 -13840069 true "" "plot count turtles with [color = black and behave = 2]"

SWITCH
20
647
200
680
infection-behaviour
infection-behaviour
1
1
-1000

BUTTON
257
21
320
54
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
22
789
194
822
A-move-angle
A-move-angle
0
360
360
5
1
NIL
HORIZONTAL

SLIDER
22
834
194
867
A-move-size
A-move-size
0
1
0.1
.1
1
NIL
HORIZONTAL

PLOT
244
648
643
830
Infection Opportunities by Flies
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A meets B" 1.0 0 -2674135 true "" "plot matrix:get inf-opts-matrix 0 1"
"B meets A" 1.0 0 -13345367 true "" "plot matrix:get inf-opts-matrix 1 0"
"NI meets A" 1.0 0 -955883 true "" "plot matrix:get inf-opts-matrix 3 0"
"NI meets B" 1.0 0 -8630108 true "" "plot matrix:get inf-opts-matrix 3 1"
"NI meets AB" 1.0 0 -13840069 true "" "plot matrix:get inf-opts-matrix 3 2"

SLIDER
9
275
181
308
A-recovery
A-recovery
0
.1
0.023
.001
1
NIL
HORIZONTAL

SLIDER
10
233
182
266
A-inf-prob-b2
A-inf-prob-b2
0
.5
0.02
.01
1
NIL
HORIZONTAL

SWITCH
23
327
165
360
personalities?
personalities?
0
1
-1000

INPUTBOX
68
399
130
459
x1
0.5
1
0
Number

INPUTBOX
143
400
201
460
y1
1
1
0
Number

INPUTBOX
65
472
129
532
z1
0.49
1
0
Number

INPUTBOX
144
471
199
531
w1
0.99
1
0
Number

TEXTBOX
60
373
210
391
Payoffs for Type 1
11
0.0
1

INPUTBOX
247
401
305
461
x2
0.5
1
0
Number

INPUTBOX
315
404
377
464
y2
1
1
0
Number

INPUTBOX
245
474
302
534
z2
0.49
1
0
Number

INPUTBOX
317
474
376
534
w2
0.99
1
0
Number

TEXTBOX
250
371
400
389
Payoffs for Type 2
11
0.0
1

TEXTBOX
14
423
164
441
Beh1
11
0.0
1

TEXTBOX
13
495
163
513
Beh2
11
0.0
1

PLOT
409
253
792
403
Behaviors
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"frac of b1 S's" 1.0 0 -2674135 true "" "plot count turtles with [behave = 1 and color = black] / count turtles with [color = black]"
"frac of b1 in N" 1.0 0 -7500403 true "" "plot count turtles with [behave = 1 ] / count turtles"

SLIDER
210
71
382
104
learn-radius
learn-radius
0
10
1
.5
1
NIL
HORIZONTAL

SLIDER
210
149
382
182
amp-local
amp-local
-1
1
0
.01
1
NIL
HORIZONTAL

SLIDER
211
189
383
222
amp-global
amp-global
-1
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
210
110
382
143
memory
memory
0
10
1
1
1
NIL
HORIZONTAL

SLIDER
209
231
381
264
local-over-global
local-over-global
0
1
1
.05
1
NIL
HORIZONTAL

PLOT
409
424
785
574
Globals
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"pinf" 1.0 0 -16777216 true "" "plot global-pinf"
"pinf given b1" 1.0 0 -2674135 true "" "plot global-pinfb1"
"pinf given b2" 1.0 0 -13345367 true "" "plot global-pinfb2"

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="coinfectiondualpriming" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>coinf10</metric>
    <metric>coinf20</metric>
    <metric>coinf30</metric>
    <metric>coinf40</metric>
    <metric>coinf50</metric>
    <metric>coinf60</metric>
    <metric>coinf70</metric>
    <metric>ainf10</metric>
    <metric>ainf20</metric>
    <metric>ainf30</metric>
    <metric>ainf40</metric>
    <metric>ainf50</metric>
    <metric>ainf60</metric>
    <metric>ainf70</metric>
    <metric>binf10</metric>
    <metric>binf20</metric>
    <metric>binf30</metric>
    <metric>binf40</metric>
    <metric>binf50</metric>
    <metric>binf60</metric>
    <metric>binf70</metric>
    <enumeratedValueSet variable="B-infections">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.05"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.05"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>count turtles with [color = gray]</metric>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="infpriming" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="conpriming" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="infpriming2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="envpriming" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="behadapt" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="behaveresponse" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <metric>count turtles with [color = green]</metric>
    <metric>count turtles with [color = gray]</metric>
    <metric>matrix:get inf-opts-matrix 0 1</metric>
    <metric>matrix:get inf-opts-matrix 1 0</metric>
    <metric>matrix:get inf-opts-matrix 3 0</metric>
    <metric>matrix:get inf-opts-matrix 3 1</metric>
    <metric>matrix:get inf-opts-matrix 3 2</metric>
    <metric>infs-by-A-flies</metric>
    <metric>infs-by-B-flies</metric>
    <metric>infs-by-AB-flies</metric>
    <metric>infs-by-A-cont</metric>
    <metric>infs-by-B-cont</metric>
    <metric>infs-by-AB-cont</metric>
    <enumeratedValueSet variable="A-move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-size">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-behaviour">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contamination?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-radius">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-primes-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infection-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-size">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-move-angle">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-infections">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-primes-A">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B-decay">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AB-primes-A-potency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-move-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="co-move-size">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A-potency">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
