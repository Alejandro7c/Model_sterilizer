/*-----------------------------------------------------------------------------------------
 LIBRARY: STERILIZER
 FILE: Sources
 CREATION DATE: 24/02/2020
-----------------------------------------------------------------------------------------*/
USE MATH 
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Tipo de función generada en el componente "Fuente"
ENUM tipo_fuente = {constante, escalon,  pulso, pulso_cuadrado, seno, sierra,\
			 escalon_tabla, interp_tabla}

-- Variable en la que puede introducirse variación según los tipos de función definidos en "Fuente"
ENUM variable_fuente = {presion, temperatura, flujo, composicion}

----------------------------------------------------------------------------------
-- Componente Fuente_analogica
----------------------------------------------------------------------------------
-- Define un componente para modificar las fuentes de corriente y señal pudiendo
-- utilizarse diferentes tipos de formas para la salida de dichas fuentes.
-- Las opciones de salida son: constante, escalón, pulso, pulso_cuadrado,seno,
-- sierra, escalon_tabla (escalon a partir de datos de una tabla) e interp_tabla
-- (interpolación de los datos de una tabla)
-- Se puede especificar, según convenga: El tiempo de comienzo del cambio (Tstart); 
-- la amplitud (Amp) del salto, del pulso o de la onda; el periodo de la onda; la 
-- fase de la onda sinusoidal; el ancho del pulso, y la tabla de la que se sacan 
-- los valores.
----------------------------------------------------------------------------------
ABSTRACT COMPONENT Fuente 
	(ENUM tipo_fuente fuente=constante  "Tipo de fuente: constante, escalon, pulso, tabla, etc.")

"Fuente analógica, con salida siguiendo función deseada: constante, escalón, pulso, tabla, etc."

DATA
	REAL Tstart=0		"Tiempo de comienzo del cambio en la salida (s)"

	   -- Salida Escalón, Sinusoidal, Pulso, Pulso Cuadrado, Sierra o valores de tabla
	REAL Amp=1.			"Amplitud o altura del cambio, en las unidades correspondientes al valor modificado"

	   -- Salida Sinusoidal, Pulso, Pulso Cuadrado o Sierra
	REAL periodo=10		"Periodo de la función Sinusoidal, Pulso, Pulso Cuadrado o Sierra (s)"
	
	   -- Salida Sinusoidal
	REAL fase=0.			"Fase de la función sinusoidal (rad)"

         -- Salida pulso
      REAL ancho_pulso=0.001	"Ancho de la función pulso (s)"

         -- Salida con valores procedentes de tabla
      TABLE_1D tabla = {{0., 10.},{0.,  0.}}	"Tabla para fuente con valores a partir de ella (-)"

DECLS
	REAL valor			"Salida de la función escogida, en las unidades correspondientes"

CONTINUOUS

	EXPAND(fuente == constante) 
		valor = 0.

	EXPAND(fuente == escalon) 
		valor = Amp*step(TIME, Tstart)
		
	EXPAND(fuente == pulso)  
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*pulse(TIME-Tstart,periodo,ancho_pulso)

	EXPAND(fuente == pulso_cuadrado) 
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*square(TIME-Tstart,periodo)

	EXPAND(fuente == seno)  
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*sin(2*MATH.PI/periodo*(TIME-Tstart)+fase)

	EXPAND(fuente == sierra)  
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*ramp(TIME-Tstart,periodo)/periodo

	EXPAND(fuente == escalon_tabla) 
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*timeTableStep(TIME-Tstart,tabla)

	EXPAND(fuente == interp_tabla) 
		valor = ZONE(TIME < Tstart) 0.
			  OTHERS Amp*timeTableInterp(TIME-Tstart,tabla)

END COMPONENT
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Nombre del componente: fuente_vapor
-- Descripción: fuente de vapor de agua
---- Datos necesarios: presión y temperatura,tipo de vapor
--------------------------------------------------------------------
COMPONENT Fuente_vapor IS_A Fuente
	(BOOLEAN saturado = TRUE 		"TRUE: saturado; FALSE: no saturado. Si (saturado=TRUE) entonces (P_fuente AND T_fuente)=FALSE",
	 BOOLEAN P_fuente = TRUE 		"Fuente de presión",
	 BOOLEAN T_fuente = FALSE		"Fuente de temperatura",
	 BOOLEAN W_fuente = FALSE		"Fuente de flujo másico. (W_fuente AND F_fuente)=FALSE",
	 BOOLEAN F_fuente = FALSE		"Fuente de flujo volumétrico. (W_fuente AND F_fuente)=FALSE",
	 ENUM variable_fuente vble= flujo 	"Variable en la que puede introducirse variación según función deseada")

"Fuente de vapor: P,T,W. Saturado (bien P_fuente ó T_fuente, no ambas simultáneamente) o no saturado"

PORTS
	OUT	vapor	(saturado=saturado)	f_out
DATA
	REAL T = 100.				"Temperatura (ºC); puede introducirse variación según función deseada"
	REAL P = 1.					"Presión (bar); puede introducirse variación según función deseada"
	REAL W = 0					"Flujo másico (kg/s); puede introducirse variación según función deseada"
	REAL F = 0					"Flujo volumétrico (m3/s); puede introducirse variación según función deseada"
TOPOLOGY
	PATH f_out TO f_out
DISCRETE
	ASSERT ((P_fuente AND T_fuente AND saturado) == FALSE) ERROR "ERROR:sólo puede especificarse bien P o bien T tratándose de vapor saturado"		
	ASSERT ((W_fuente AND F_fuente) == FALSE) ERROR "ERROR:sólo puede especificarse bien flujo másico W o bien flujo volumétrico F"		
CONTINUOUS

<eq1>	EXPAND((P_fuente == TRUE) AND (vble == presion) AND (saturado==FALSE))		f_out.P = P + valor
<eq2>	EXPAND((P_fuente == TRUE) AND (vble != presion) AND (saturado==FALSE))		f_out.P = P
<eq3>	EXPAND((P_fuente==TRUE) AND (saturado==TRUE))			f_out.T = temp_sat_w(f_out.P)
	EXPAND((P_fuente==TRUE) AND (saturado==TRUE))			f_out.P = P

<eq4>	EXPAND((T_fuente == TRUE) AND (vble == temperatura) AND (saturado==FALSE))		f_out.T = T + valor
<eq5>	EXPAND((T_fuente == TRUE) AND (vble != temperatura) AND (saturado==FALSE))		f_out.T = T
	EXPAND((T_fuente==TRUE) AND (saturado==TRUE))			f_out.P = pres_sat_w(f_out.T)
	EXPAND((T_fuente==TRUE) AND (saturado==TRUE))			f_out.T = T

<eq6>	EXPAND((W_fuente == TRUE) AND (vble == flujo))			f_out.W = W + valor
<eq7>	EXPAND((W_fuente == TRUE) AND (vble != flujo))			f_out.W = W

<eq8>	EXPAND((F_fuente == TRUE) AND (vble == flujo))			f_out.F = F + valor
<eq9>	EXPAND((F_fuente == TRUE) AND (vble != flujo))			f_out.F = F

END COMPONENT
