/*-----------------------------------------------------------------------------------------
 LIBRARY: STERILIZER
 FILE: Ports
 CREATION DATE: 24/02/2020
-----------------------------------------------------------------------------------------*/
---------------------------------------------------------------------------------
--- Nombre del Puerto: analog_signal.
--- Descripción: Puerto de señal analógica.
--- Autor Alejandro Merino Gómez
----------------------------------------------------------------------------------

USE MATH
//USE FUNCIONES_MATEMATICAS

----------------------------------------------------------------------------------
-- Puerto analógico escalar

PORT analog_signal SINGLE IN
	EQUAL OUT REAL signal
END PORT

PORT analog_signal_n  (SET_OF(products) prod                  "Number of outputs (-)"
   ) SINGLE IN

   EQUAL OUT REAL signal[prod]       "Real variable array (-)"

END PORT

PORT vapor (BOOLEAN saturado)

	EQUAL		REAL	P		"Presión (bar)"
			REAL 	T	RANGE -273,Inf	"Temperatura (ºC)"
	EQUAL OUT 	REAL 	H		"Entalpía del vapor saturado (J/kg)"
	SUM		REAL	W		"Flujo másico de vapor (kg/s)"
	SUM	IN	REAL	f_energ	"Flujo de energía (KJ/s)"
			REAL	F		"Flujo volumétrico de vapor (m3/s)"
			REAL 	Rho		"Densidad del vapor (kg/m3)"

CONTINUOUS

EXPAND(saturado==TRUE)		Rho=linearInterp1D(dens_vsat,P)	
EXPAND(saturado==FALSE)		Rho=dvapor(T,P)	

EXPAND(saturado==TRUE)		H=entalp_vsat_T(T)
					INVERSE (T) T = T_vsat_H (H,P)

EXPAND(saturado==FALSE)		H=hvapor(T,P)

	f_energ = W * H
	
	W = F * Rho			

END PORT
